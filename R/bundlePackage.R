bundlePackages <- function(bundleDir,
                           appMode,
                           extraPackages = character(),
                           verbose = FALSE,
                           error_call = caller_env()) {
  deps <- snapshotRDependencies(bundleDir, extraPackages, verbose = verbose)
  if (nrow(deps) == 0) {
    return(list())
  }
  checkBundlePackages(deps, call = error_call)

  copyPackageDescriptions(bundleDir, deps$Package)
  deps$description <- lapply(deps$Package, function(nm) {
    # Remove packageDescription S3 class so jsonlite can serialize
    unclass(utils::packageDescription(nm))
  })

  # Connect prefers that packrat/packrat.lock file, but will use the manifest
  # if needed. shinyapps.io only uses the manifest, and only supports Github
  # remotes, not Bitbucket or Gitlab.
  github_cols <- grep("Github", colnames(deps), perl = TRUE, value = TRUE)
  packages <- deps[c("Source", "Repository", github_cols, "description")]
  packages_list <- lapply(seq_len(nrow(packages)), function(i) {
    out <- as.list(packages[i, , drop = FALSE])
    out$description <- out$description[[1]]
    out
  })
  names(packages_list) <- deps$Package
  packages_list
}

checkBundlePackages <- function(deps, call = caller_env()) {
  not_installed <- !vapply(deps$Package, is_installed, logical(1))
  if (any(not_installed)) {
    pkgs <- deps$Package[not_installed]
    cli::cli_abort(
      c(
        "All packages used by the asset must be installed.",
        x = "Missing packages: {.pkg {pkgs}}."
      ),
      call = call
    )
  }

  unknown_source <- is.na(deps$Source)
  if (any(unknown_source)) {
    pkgs <- deps$Package[unknown_source]
    cli::cli_warn(
      c(
        "Local packages must be installed from a supported source.",
        x = "Unsupported packages: {.pkg {pkgs}}.",
        i = "Supported sources are CRAN and CRAN-like repositories, BioConductor, GitHub, GitLab, and Bitbucket.",
        i = "See {.fun rsconnect::appDependencies} for more details."
      ),
      call = call
    )
  }
}

# Copy all the DESCRIPTION files we're relying on into packrat/desc.
# That directory will contain one file for each package, e.g.
# packrat/desc/shiny will be the shiny package's DESCRIPTION.
copyPackageDescriptions <- function(bundleDir, packages) {
  descDir <- file.path(bundleDir, "packrat", "desc")
  dir.create(descDir, showWarnings = FALSE, recursive = TRUE)

  descPaths <- file.path(find.package(packages), "DESCRIPTION")
  file.copy(descPaths, file.path(descDir, packages))
  invisible()
}

snapshotRDependencies <- function(appDir,
                                  implicit_dependencies = c(),
                                  verbose = FALSE) {

  # create a packrat "snapshot"
  addPackratSnapshot(appDir, implicit_dependencies, verbose = verbose)

  # TODO: should we care about lockfile version or packrat version?
  lockFilePath <- snapshotLockFile(appDir)
  df <- as.data.frame(read.dcf(lockFilePath), stringsAsFactors = FALSE)

  # get repos defined in the lockfile
  repos <- gsub("[\r\n]", " ", df[1, "Repos"])
  repos <- strsplit(unlist(strsplit(repos, "\\s*,\\s*", perl = TRUE)), "=", fixed = TRUE)
  repos <- setNames(
    sapply(repos, "[[", 2),
    sapply(repos, "[[", 1)
  )

  # get packages records defined in the lockfile
  records <- utils::tail(df, -1)
  records[c("Source", "Repository")] <- findPackageRepoAndSource(records, repos)
  records
}

findPackageRepoAndSource <- function(records, repos) {
  # read available.packages filters (allow user to override if necessary;
  # this is primarily to allow debugging)
  #
  # note that we explicitly exclude the "R_version" filter as we want to ensure
  # that packages which require newer versions of R than the one currently
  # in use can still be marked as available on CRAN -- for example, currently
  # the package "foreign" requires "R (>= 4.0.0)" but older versions of R
  # can still successfully install older versions from the CRAN archive
  filters <- getOption("available_packages_filters", default = "duplicates")

  # get Bioconductor repos if any
  biocRepos <- repos[grep("BioC", names(repos), perl = TRUE, value = TRUE)]
  biocPackages <- if (length(biocRepos) > 0) {
    available.packages(
      contriburl = contrib.url(biocRepos, type = "source"),
      type = "source",
      filters = filters
    )
  }

  # read available packages
  repo.packages <- available.packages(
    contriburl = contrib.url(repos, type = "source"),
    type = "source",
    filters = filters
  )

  named.repos <- name.all.repos(repos)
  repo.lookup <- data.frame(
    name = names(named.repos),
    url = as.character(named.repos),
    contrib.url = contrib.url(named.repos, type = "source"),
    stringsAsFactors = FALSE
  )

  # Sources are created by packrat:
  # https://github.com/rstudio/packrat/blob/v0.9.0/R/pkg.R#L328
  # if the package is in a named CRAN-like repository capture it
  tmp <- lapply(seq_len(nrow(records)), function(i) {

    pkg <- records[i, "Package"]
    source <- records[i, "Source"]
    repository <- NA
    # capture Bioconcutor repository
    if (identical(source, "Bioconductor")) {
      if (pkg %in% biocPackages) {
        repository <- biocPackages[pkg, "Repository"]
      }
    } else if (isSCMSource(source)) {
      # leave source+SCM packages alone.
    } else if (pkg %in% rownames(repo.packages)) {
      # capture CRAN-like repository

      # Find this package in the set of available packages then use its
      # contrib.url to map back to the configured repositories.
      package.contrib <- repo.packages[pkg, "Repository"]
      package.repo.index <- vapply(repo.lookup$contrib.url,
                                   function(url) grepl(url, package.contrib, fixed = TRUE), logical(1))
      package.repo <- repo.lookup[package.repo.index, ][1, ]
      # If the incoming package comes from CRAN, keep the CRAN name in place
      # even if that means using a different name than the repos list.
      #
      # The "cran" source is a well-known location for shinyapps.io.
      #
      # shinyapps.io isn't going to use the manifest-provided CRAN URL,
      # but other consumers (Connect) will.
      if (tolower(source) != "cran") {
        source <- package.repo$name
      }
      repository <- package.repo$url
    }
    # validatePackageSource will emit a warning for packages with NA repository.
    data.frame(Source = source, Repository = repository, stringsAsFactors = FALSE)
  })
  do.call("rbind", tmp)
}

addPackratSnapshot <- function(bundleDir,
                               implicit_dependencies = character(),
                               verbose = FALSE) {
  logger <- verboseLogger(verbose)

  # if we discovered any extra dependencies, write them to a file for packrat to
  # discover when it creates the snapshot
  if (length(implicit_dependencies) > 0) {
    tempDependencyFile <- file.path(bundleDir, "__rsconnect_deps.R")
    # emit dependencies to file
    extraPkgDeps <- paste0("library(", implicit_dependencies, ")\n")
    writeLines(extraPkgDeps, tempDependencyFile)

    # ensure temp file is cleaned up even if there's an error
    on.exit(unlink(tempDependencyFile), add = TRUE)
  }

  # generate the packrat snapshot
  logger("Starting to perform packrat snapshot")
  withCallingHandlers(
    performPackratSnapshot(bundleDir, verbose = verbose),
    error = function(err) {
      abort("Failed to snapshot dependencies", parent = err)
    }
  )
  logger("Completed performing packrat snapshot")

  invisible()
}

performPackratSnapshot <- function(bundleDir, verbose = FALSE) {
  # ensure we snapshot recommended packages
  srp <- packrat::opts$snapshot.recommended.packages()
  packrat::opts$snapshot.recommended.packages(TRUE, persist = FALSE)
  on.exit(
    packrat::opts$snapshot.recommended.packages(srp, persist = FALSE),
    add = TRUE
  )

  # Force renv dependency scanning within packrat unless the option has been
  # explicitly configured. This is a no-op for older versions of packrat.
  renvDiscovery <- getOption("packrat.dependency.discovery.renv")
  if (is.null(renvDiscovery)) {
    old <- options("packrat.dependency.discovery.renv" = TRUE)
    on.exit(options(old), add = TRUE)
  }

  # attempt to eagerly load the BiocInstaller or BiocManaager package if
  # installed, to work around an issue where attempts to load the package could
  # fail within a 'suppressMessages()' context
  packages <- c("BiocManager", "BiocInstaller")
  for (package in packages) {
    if (is_installed(package)) {
      requireNamespace(package, quietly = TRUE)
      break
    }
  }

  suppressMessages(
    packrat::.snapshotImpl(
      project = bundleDir,
      snapshot.sources = FALSE,
      fallback.ok = TRUE,
      verbose = verbose,
      implicit.packrat.dependency = FALSE
    )
  )

  invisible()
}

snapshotLockFile <- function(appDir) {
  file.path(appDir, "packrat", "packrat.lock")
}

# Return TRUE when the source indicates that a package was installed from
# source or comes from a source control system. This indicates that we will
# not have a repostory URL; location is recorded elsewhere.
isSCMSource <- function(source) {
  tolower(source) %in% c("github", "gitlab", "bitbucket", "source")
}

# generate a random name prefixed with "repo_".
random.repo.name <- function() {
  paste("repo_", paste(sample(LETTERS, 8, replace = TRUE), collapse = ""), sep = "")
}

# Given a list of optionally named repository URLs, return a list of
# repository URLs where each element is named. Incoming names are preserved.
# Un-named repositories are given random names.
name.all.repos <- function(repos) {
  repo.names <- names(repos)
  if (is.null(repo.names)) {
    # names(X) return NULL when nothing is named. Build a same-sized vector of
    # empty-string names, which is the "no name here" placeholder value
    # produced when its input has a mix of named and un-named items.
    repo.names <- rep("", length(repos))
  }
  names(repos) <- sapply(repo.names, function(name) {
    if (name == "") {
      # Assumption: Random names are not repeated across a repo list.
      random.repo.name()
    } else {
      name
    }
  }, USE.NAMES = FALSE)
  repos
}
