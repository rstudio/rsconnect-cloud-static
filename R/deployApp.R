#' Deploy an Application
#'
#' Deploy a [shiny][shiny::shiny-package] application, an
#' [RMarkdown][rmarkdown::rmarkdown-package] document, a plumber API, or HTML
#' content to a server.
#'
#' ## Deployment records
#'
#' When deploying an app, `deployApp()` will save a deployment record that
#' makes it easy to update the app on server from your local source code. This
#' generally means that you need to only need to supply important arguments
#' (e.g. `appName`, `appTitle`, `server`/`account`) on the first deploy, and
#' rsconnect will reuse the same settings on subsequent deploys.
#'
#' The metadata needs to make this work is stored in `{appDir}/rsconnect/`.
#' You should generally check these files into version control to ensure that
#' future you and other collaborators will publish to the same location.
#'
#' If you have lost this directory, all is not lost, as `deployApp()` will
#' attempt to rediscover existing deployments. This is easiest if you are
#' updating an app that you created, as you can just supply the `appName`
#' (and `server`/`account` if you have multiple accounts) and `deployApp()`
#' will find the existing application account. If you need to update an app
#' that was created by someone else (that you have write permission) for, you'll
#' instead need to supply the `appId`.
#'
#' @param appDir A directory containing an application (e.g. a Shiny app
#'   or plumber API). Defaults to the current directory.
#' @param appFiles,appFileManifest Use `appFiles` to specify a
#'   character vector of files to bundle in the app or `appManifestFiles`
#'   to provide a path to a file containing a list of such files. If neither
#'   are supplied, will bundle all files in `appDir`, apart from standard
#'   exclusions and files listed in a `.rscignore` file. See
#'   [listDeploymentFiles()] for more details.
#' @param appPrimaryDoc If the application contains more than one document, this
#'   parameter indicates the primary one, as a path relative to `appDir`. Can be
#'   `NULL`, in which case the primary document is inferred from the contents
#'   being deployed.
#' @param appSourceDoc `r lifecycle::badge("deprecated")` Please use
#'   `recordDir` instead.
#' @param appName Application name, a string consisting of letters, numbers,
#'   `_` and `-`. The application name is used to identify applications on a
#'   server, so much be unique.
#'
#'   If not specified, the first deployment will be automatically it from the
#'   `appDir` for directory and website, and from the `appPrimaryDoc` for
#'   document. On subsequent deploys, it will use the previously stored value.
#' @param appTitle Free-form descriptive title of application. Optional; if
#'   supplied, will often be displayed in favor of the name. If ommitted,
#'   on second and subsequent deploys, the title will be unchanged.
#' @param appId Use this to deploy to an exact known application, ignoring all
#'   existing deployment records and `appName`.
#'
#'   You can use this to update an existing application that is missing a
#'   deployment record. If you're re-deploying an application that you
#'   created it's generally easier to use `appName`; `appId` is best reserved
#'   for re-deploying apps created by someone else.
#'
#'   You can find the `appId` in the following places:
#'   * On shinyapps.io, it's the `id` listed on the applications page.
#'   * For Posit Connect, it's `guid` from the info tab on the content page.
#' @param contentCategory Optional; the kind of content being deployed (e.g.
#'   `"plot"` or `"site"`).
#' @param account,server Uniquely identify a remote server with either your
#'   user `account`, the `server` name, or both. If neither are supplied, and
#'   there are multiple options, you'll be prompted to pick one.
#'
#'   Use [accounts()] to see the full list of available options.
#' @param upload If `TRUE` (the default) then the application is uploaded from
#'   the local system prior to deployment. If `FALSE` then it is re-deployed
#'   using the last version that was uploaded. `FALSE` is only supported on
#'   shinyapps.io; `TRUE` is required on Posit Connect.
#' @param recordDir Directory where deployment record is written. The default,
#'   `NULL`, uses `appDir`, since this is usually where you want the deployment
#'   data to be stored. This argument is typically only needed when deploying
#'   a directory of static files since you want to store the record with the
#'   code that generated those files, not the files themselves.
#' @param launch.browser If true, the system's default web browser will be
#'   launched automatically after the app is started. Defaults to `TRUE` in
#'   interactive sessions only. If a function is passed, it will be called
#'   after the app is started, with the app URL as a paramter.
#' @param on.failure Function to be called if the deployment fails. If a
#'   deployment log URL is available, it's passed as a parameter.
#' @param logLevel One of `"quiet"`, `"normal"` or `"verbose"`; indicates how
#'   much logging to the console is to be performed. At `"quiet"` reports no
#'   information; at `"verbose"`, a full diagnostic log is captured.
#' @param lint Lint the project before initiating deployment, to identify
#'   potentially problematic code?
#' @param metadata Additional metadata fields to save with the deployment
#'   record. These fields will be returned on subsequent calls to
#'   [deployments()].
#' @param forceUpdate What should happen if there's no deployment record for
#'   the app, but there's an app with the same name on the server? If `TRUE`,
#'   will always update the previously-deployed app. If `FALSE`, will ask
#'   the user what to do, or fail if not in an interactive context.
#'
#'   Defaults to the value of `getOption("rsconnect.force.update.apps", FALSE)`.
#' @param python Full path to a python binary for use by `reticulate`.
#'   Required if `reticulate` is a dependency of the app being deployed.
#'   If python = NULL, and RETICULATE_PYTHON or RETICULATE_PYTHON_FALLBACK is
#'   set in the environment, its value will be used. The specified python binary
#'   will be invoked to determine its version and to list the python packages
#'   installed in the environment.
#' @param forceGeneratePythonEnvironment Optional. If an existing
#'   `requirements.txt` file is found, it will be overwritten when this argument
#'   is `TRUE`.
#' @param quarto Optional. Full path to a Quarto binary for use deploying Quarto
#'   content. The provided Quarto binary will be used to run `quarto inspect`
#'   to gather information about the content.
#' @param appVisibility One of `NULL`, `"private"`, or `"public"`; the
#'   visibility of the deployment. When `NULL`, no change to visibility is
#'   made. Currently has an effect only on deployments to shinyapps.io.
#' @param image Optional. The name of the image to use when building and
#'   executing this content. If none is provided, Posit Connect will
#'   attempt to choose an image based on the content requirements.
#' @examples
#' \dontrun{
#'
#' # deploy the application in the current working dir
#' deployApp()
#'
#' # deploy an application in another directory
#' deployApp("~/projects/shiny/app1")
#'
#' # deploy using an alternative application name and title
#' deployApp("~/projects/shiny/app1", appName = "myapp",
#'           appTitle = "My Application")
#'
#' # deploy specifying an explicit account name, then
#' # redeploy with no arguments (will automatically use
#' # the previously specified account)
#' deployApp(account = "jsmith")
#' deployApp()
#'
#' # deploy but don't launch a browser when completed
#' deployApp(launch.browser = FALSE)
#'
#' # deploy a Quarto website, using the quarto package to
#' # find the Quarto binary
#' deployApp("~/projects/quarto/site1", quarto = quarto::quarto_path())
#' }
#' @seealso [applications()], [terminateApp()], and [restartApp()]
#' @family Deployment functions
#' @export
deployApp <- function(appDir = getwd(),
                      appFiles = NULL,
                      appFileManifest = NULL,
                      appPrimaryDoc = NULL,
                      appSourceDoc = NULL,
                      appName = NULL,
                      appTitle = NULL,
                      appId = NULL,
                      contentCategory = NULL,
                      account = NULL,
                      server = NULL,
                      upload = TRUE,
                      recordDir = NULL,
                      launch.browser = getOption("rsconnect.launch.browser",
                                                 interactive()),
                      on.failure = NULL,
                      logLevel = c("normal", "quiet", "verbose"),
                      lint = TRUE,
                      metadata = list(),
                      forceUpdate = getOption("rsconnect.force.update.apps", FALSE),
                      python = NULL,
                      forceGeneratePythonEnvironment = FALSE,
                      quarto = NULL,
                      appVisibility = NULL,
                      image = NULL
                      ) {

  check_string(appDir)
  if (isStaticFile(appDir) && !dirExists(appDir)) {
    lifecycle::deprecate_warn(
      when = "0.9.0",
      what = "deployApp(appDir = 'takes a directory, not a document,')",
      with = "deployDoc()"
    )
    return(deployDoc(
      appDir,
      appName = appName,
      appTitle = appTitle,
      account = account,
      server = server,
      upload = upload,
      recordDir = recordDir,
      launch.browser = launch.browser,
      logLevel = logLevel,
      lint = lint
    ))
  }
  check_directory(appDir)
  appDir <- normalizePath(appDir)

  check_string(appName, allow_null = TRUE)

  if (!is.null(appPrimaryDoc)) {
    check_string(appPrimaryDoc)
    if (!file.exists(file.path(appDir, appPrimaryDoc))) {
      cli::cli_abort("`appPrimaryDoc` not found inside `appDir`")
    }
  }

  if (!is.null(appSourceDoc)) {
    # Used by IDE so can't deprecate
    recordDir <- appSourceDoc
  } else if (!is.null(recordDir)) {
    check_file(recordDir)
  }

  # set up logging helpers
  logLevel <- match.arg(logLevel)
  quiet <- identical(logLevel, "quiet")
  verbose <- identical(logLevel, "verbose")
  logger <- verboseLogger(verbose)
  displayStatus <- displayStatus(quiet)

  # run startup scripts to pick up any user options and establish pre/post deploy hooks
  runStartupScripts(appDir, quiet = quiet, verbose = verbose)

  # at verbose log level, turn on all tracing options implicitly for the
  # duration of the call
  if (verbose) {
    old_verbose <- options(
      rsconnect.http.trace = TRUE,
      rsconnect.http.trace.json = TRUE,
      rsconnect.error.trace = TRUE
    )
    on.exit(options(old_verbose), add = TRUE)
  }

  # install error handler if requested
  if (isTRUE(getOption("rsconnect.error.trace"))) {
    old_error <- options(error = function(e) {
      cat("----- Deployment error -----\n")
      cat(geterrmessage(), "\n")
      cat("----- Error stack trace -----\n")
      traceback(x = sys.calls(), max.lines = 3)
    })
    on.exit(options(old_error), add = TRUE)
  }

  # at verbose log level, generate header
  if (verbose) {
    logger("Deployment log started")
    cat("Deploy command:", "\n", deparse(sys.call(1)), "\n\n")
    cat("Session information: \n")
    print(utils::sessionInfo())
  }

  # invoke pre-deploy hook if we have one
  runDeploymentHook(appDir, "rsconnect.pre.deploy", verbose = verbose)

  appFiles <- listDeploymentFiles(appDir, appFiles, appFileManifest)

  if (isTRUE(lint)) {
    lintResults <- lint(appDir, appFiles, appPrimaryDoc)
    showLintResults(appDir, lintResults)
  }

  if (!quiet) {
    cli::cli_rule("Preparing for deployment")
  }

  # determine the deployment target and target account info
  recordPath <- findRecordPath(appDir, recordDir, appPrimaryDoc)
  if (is.null(appId)) {
    target <- deploymentTarget(
      recordPath = recordPath,
      appName = appName,
      appTitle = appTitle,
      account = account,
      server = server,
      forceUpdate = forceUpdate
    )
  } else {
    if (!is.null(appName)) {
      cli::cli_warn("{.arg appName} is ignored when {.arg appId} is set")
    }

    target <- deploymentTargetForApp(
      appId = appId,
      appTitle = appTitle,
      account = account,
      server = server
    )
  }
  if (is.null(target$appId)) {
    dest <- accountId(target$username, target$server)
    taskComplete(quiet, "Deploying {.val {target$appName}} to {.val {dest}}")
  } else {
    dest <- accountId(target$username, target$server)
    taskComplete(quiet, "Re-deploying {.val {target$appName}} to {.val {dest}}")
  }

  isCloudServer <- isCloudServer(target$server)
  # test for compatibility between account type and publish intent
  if (!isCloudServer && identical(upload, FALSE)) {
    # it is not possible to deploy to Connect without uploading
    stop("Posit Connect does not support deploying without uploading. ",
         "Specify upload=TRUE to upload and re-deploy your application.")
  }

  accountDetails <- accountInfo(target$account, target$server)
  client <- clientForAccount(accountDetails)
  if (verbose) {
    showCookies(serverInfo(accountDetails$server)$url)
  }

  if (is.null(target$appId)) {
    taskStart(quiet, "Creating application on server...")
    application <- client$createApplication(
      target$appName,
      target$appTitle,
      "shiny",
      accountDetails$accountId
    )
    taskComplete(quiet, "Created application with id {.val {application$id}}")
  } else {
    application <- taskStart(quiet, "Looking up application with id {.val {target$appId}}...")
    application <- client$getApplication(target$appId)
    taskComplete(quiet, "Found application")
  }
  saveDeployment(
    recordPath,
    target = target,
    application = application,
    metadata = metadata
  )

  # Change _visibility_ before uploading data
  if (needsVisibilityChange(accountDetails$server, application, appVisibility)) {
    taskStart(quiet, "Setting visibility to {appVisibility}...")
    client$setApplicationProperty(
      application$id,
      "application.visibility",
      appVisibility
    )
    taskComplete(quiet, "Visibility updated")
  }

  if (upload) {
    python <- getPythonForTarget(python, accountDetails)
    pythonConfig <- pythonConfigurator(python, forceGeneratePythonEnvironment)

    logger("Inferring App mode and parameters")
    appMetadata <- appMetadata(
      appDir = appDir,
      appFiles = appFiles,
      appPrimaryDoc = appPrimaryDoc,
      quarto = quarto,
      contentCategory = contentCategory,
      isCloudServer = isCloudServer,
      metadata = metadata
    )

    taskStart(quiet, "Bundling {length(appFiles)} file{?s}: {.file {appFiles}}")
    bundlePath <- bundleApp(
      appName = target$appName,
      appDir = appDir,
      appFiles = appFiles,
      appMetadata = appMetadata,
      verbose = verbose,
      pythonConfig = pythonConfig,
      isCloudServer = isCloudServer,
      image = image
    )
    size <- format(file_size(bundlePath), big.mark = ",")
    taskComplete(quiet, "Created {size}b bundle")

    # create, and upload the bundle
    taskStart(quiet, "Uploading bundle...")
    if (isCloudServer(accountDetails$server)) {
      bundle <- uploadCloudBundle(client, application$id, bundlePath)
    } else {
      bundle <- client$uploadApplication(application$id, bundlePath)
    }
    taskComplete(quiet, "Uploaded bundle with id {.val {bundle$id}}")

    saveDeployment(
      recordPath,
      target = target,
      application = application,
      bundleId = bundle$id,
      metadata = metadata
    )
  } else {
    # redeploy current bundle
    bundle <- application$deployment$bundle
  }

  if (!quiet) {
    cli::cli_rule("Deploying to server")
  }
  task <- client$deployApplication(application$id, bundle$id)
  taskId <- if (is.null(task$task_id)) task$id else task$task_id
  # wait for the deployment to complete (will raise an error if it can't)
  response <- client$waitForTask(taskId, quiet)
  if (!quiet) {
    cli::cli_rule("Deployment complete")
  }

  # wait 1/10th of a second for any queued output get picked by RStudio
  # before emitting the final status, to ensure it's the last line the user sees
  Sys.sleep(0.10)

  deploymentSucceeded <- is.null(response$code) || response$code == 0
  if (deploymentSucceeded) {
    cli::cli_alert_success("Successfully deployed to {.url {application$url}}")
  } else {
    cli::cli_alert_danger("Deployment failed with error: {response$error}")
  }

  if (!quiet)
    openURL(client, application, launch.browser, on.failure, deploymentSucceeded)

  # invoke post-deploy hook if we have one
  if (deploymentSucceeded) {
    runDeploymentHook(appDir, "rsconnect.post.deploy", verbose = verbose)
  }

  logger("Deployment log finished")

  invisible(deploymentSucceeded)
}

taskStart <- function(quiet, message, .envir = caller_env()) {
  if (quiet) return()
  cli::cli_alert_info(message, .envir = .envir)
}
taskComplete <- function(quiet, message, .envir = caller_env()) {
  if (quiet) return()
  cli::cli_alert_success(message, .envir = .envir)
}

findRecordPath <- function(appDir,
                           recordDir = NULL,
                           appPrimaryDoc = NULL) {
  if (!is.null(recordDir)) {
    recordDir
  } else if (!is.null(appPrimaryDoc)) {
    file.path(appDir, appPrimaryDoc)
  } else {
    appDir
  }
}

# Shinyapps defaults to public visibility.
# Other values should be set before data is deployed.
needsVisibilityChange <- function(server, application, appVisibility = NULL) {
  if (!isCloudServer(server)) {
    return(FALSE)
  }
  if (is.null(appVisibility)) {
    return(FALSE)
  }

  cur <- application$deployment$properties$application.visibility
  if (is.null(cur)) {
    cur <- "public"
  }
  cur != appVisibility
}

runDeploymentHook <- function(appDir, option, verbose = FALSE) {
  hook <- getOption(option)
  if (!is.function(hook)) {
    return()
  }

  if (verbose) {
    cat("Invoking `", option, "` hook\n", sep = "")
  }
  hook(appDir)
}


# Does almost exactly the same work as writeManifest(), but called within
# deployApp() instead of being exposed to the user. Returns the path to the
# bundle directory, whereas writeManifest() returns nothing and deletes the
# bundle directory after writing the manifest.
bundleApp <- function(appName,
                      appDir,
                      appFiles,
                      appMetadata,
                      verbose = FALSE,
                      pythonConfig = NULL,
                      isCloudServer = FALSE,
                      image = NULL) {
  logger <- verboseLogger(verbose)

  # get application users (for non-document deployments)
  users <- NULL
  if (is.null(appMetadata$appPrimaryDoc)) {
    users <- suppressWarnings(authorizedUsers(appDir))
  }

  # copy files to bundle dir to stage
  logger("Bundling app dir")
  bundleDir <- bundleAppDir(
      appDir = appDir,
      appFiles = appFiles,
      appPrimaryDoc = appMetadata$appPrimaryDoc)
  on.exit(unlink(bundleDir, recursive = TRUE), add = TRUE)

  # generate the manifest and write it into the bundle dir
  logger("Generate manifest.json")
  manifest <- createAppManifest(
    appDir = bundleDir,
    appMetadata = appMetadata,
    users = users,
    pythonConfig = pythonConfig,
    retainPackratDirectory = TRUE,
    isCloudServer = isCloudServer,
    image = image,
    verbose = verbose
  )
  manifestJson <- enc2utf8(toJSON(manifest, pretty = TRUE))
  manifestPath <- file.path(bundleDir, "manifest.json")
  writeLines(manifestJson, manifestPath, useBytes = TRUE)

  # create the bundle and return its path
  logger("Compressing the bundle")
  bundlePath <- tempfile("rsconnect-bundle", fileext = ".tar.gz")
  writeBundle(bundleDir, bundlePath)
  bundlePath
}

getAppByName <- function(client, accountInfo, name) {
  # NOTE: returns a list with 0 or 1 elements
  app <- client$listApplications(accountInfo$accountId, filters = list(name = name))
  if (length(app)) app[[1]] else NULL
}

validURL <- function(url) {
  !(is.null(url) || url == "")
}

openURL <- function(client, application, launch.browser, on.failure, deploymentSucceeded) {

  # function to browse to a URL using user-supplied browser (config or final)
  showURL <- function(url) {
    if (isTRUE(launch.browser))
      utils::browseURL(url)
    else if (is.function(launch.browser))
      launch.browser(url)
  }

  # Check to see if we should open config url or app url
  if (!is.null(client$configureApplication)) {
    config <- client$configureApplication(application$id)
    url <- config$config_url
    if (!deploymentSucceeded && validURL(config$logs_url)) {
      # With 1.5.5+, Connect application configuration includes
      # a logs URL to be shown on unsuccessful deployment.
      url <- config$logs_url
    }
    if (validURL(url)) {
      # Connect should always end up here, even on deployment failures
      if (deploymentSucceeded) {
        showURL(url)
      } else if (is.function(on.failure)) {
        on.failure(url)
      }
    }
  } else if (deploymentSucceeded) {
    # shinyapps.io should land here if things succeeded
    showURL(application$url)
  } else if (is.function(on.failure)) {
    on.failure(NULL)
  }
    # or open no url if things failed
}

runStartupScripts <- function(appDir, quiet = FALSE, verbose = FALSE) {
  scripts <- c(
    # the site-wide startup script
    file.path(R.home("etc"), "rsconnect.site"),
    # the user startup script
    path.expand("~/.rsconnect_profile"),
    # a startup script specific to this application
    file.path(appDir, ".rsconnect_profile")
  )
  scripts <- scripts[file.exists(scripts)]

  # iterate over the startup scripts
  for (script in scripts) {
    taskStart(quiet, "Running {script}")

    env <- new_environment(parent = globalenv())
    source(script, verbose = verbose, local = env)
  }
}
