# rsconnect 0.8.30 (development version)

* Non-libcurl `rsconnect.http` options have been deprecated. This allows us to 
  focus our efforts on a single backend, rather than spreading development
  efforts across five. The old backends will remain available for at least 2
  years, but if you are using them because libcurl doesn't work for you, please
  report the problem ASAP so we can fix it.

* Uploading large files to rpubs works once more (#450).

* `deployApp()` includes some new conveniences for large uploads including
  reporting the size of the bundle you're uploading and (if interative) a
  progress bar (#754).

* rsconnect now follows redirects, which should make it more robust to your
  server moving to a new url (#674).

* `appDependencies()` includes implicit dependencies.

* New `listDeploymentFiles()`, which supsersedes `listBundleFiles()`.

* `addConnectServer()` has been deprecated because it does the same
  thing as `addServer()`.

* `serverInfo()` and `removeServer()` no longer require a `server` when 
  called interactively.

* `connectApiUser()` now clearly requires an `apiKey` (#741).

* `deployApp()` now generates an interactive prompt to select 
  `account`/`server` (if no previous deployments) or 
  `appName`/`account`/`server` (if multiple previous deployments) (#691). 

* `discoverServer()` has been deprecated; it never worked.

* `deployDoc()` includes a `.Rprofile` in the bundle, if one is found in the 
  same directory as the document.

* Removed Rmd generation code (`writeRmdIndex()`) which had not worked, or
  been necessary, for quite some time (#106, #109).

* `deployApp()` now advertises which startup scripts are run at the normal
  `logLevel`, and it evaluates each script in its own environment (#542).

* `deployments()` now formats `when` and `lastSyncTime` as date-times (#714).

* `deployApp()` now derives `appName` from `appDir` and `appPrimaryDoc`, 
  never using the title (#538). It now only simplifies the path if you are 
  publishing to shinyapps.io, since its restrictions on application names are 
  much tighter than those of Posit Connect.

* `deployApp()` output has been thorougly reviewed and tweaked. As well as 
  general polish it now gives you more information about what it has discovered
  about the deployment, like the app name, account & server, and which files
  are included in the bundle (#669).

* Locale detection has been improved on windows (#233).

* `deployApp()` will now warn if `appFiles` or `appManifestFiles` contain
  files that don't exist, rather than silently ignoring them (#706).

* `deployApp()` excludes temporary backup files (names starting or ending 
  with `~`) when automatically determining files to bundle (#111) and 
  excludes directories that are likely to be python virtual environments 
  (#632). Additionally, ignore rules are always now applied to all directories;
  previously some (like `.Rproj.user` and `"manifest.json"`) were only applied
  to the root directory.

* `deployApp()` is more aggressive about saving deployment data, which should
  make it less likely that you need to repeat yourself after a failed 
  deployment. In particular, it now saves both before and after uploading the
  contents (#677) and it saves when you're updating content originally created
  by someone else (#270).
  
* `deployApp("foo.Rmd")` has been deprecated. It was never documented, and
  it does the same job as `deployDoc()` (#698).

* `deployApp(appPrimaryDoc)` has been deprecated; it did the same job as 
  `recordDir`.

* `appDependencies()` now returns an additional column giving the Repository 
  (#670)

* The `rsconnect.pre.deploy` and `rsconnect.post.deploy` hooks are now always
  called with the content directory, not sometimes the path to a specific file
  (#696).

* `showMetrics()` once again returns a correctly named data frame (#528).

* `listBundleFiles()` and hence `deployApp()` now correctly handles `.rscignore` 
  files (i.e. as documented) (#568). 

* `listBundleFiles()` now errors when if the bundle is either too large 
  or contains too many files, rather than silently truncating as previously 
  (#684).

* `applications()` now returns the application title, if available (#484).

* `addConnectServer()` is slightly more robust to incorrect specification 
  (#603).

* `accounts()` now returns a zero-row data frame if no accounts registered.

* `accountInfo()` and `servers()` now redacts sensitive information (secrets,
  private keys, and certificates) to make it hard to accidentally reveal
  such information in logs (#675).

* The logic used by `deployApp()` for determining whether you publish a 
  new update or update an existing app has been simplified. Now `appName`,
  `account`, and `server` are used to find existing deployments. If none
  are found, it will create a new deployment; if one is found, it'll be 
  updated; if more than one are found, it will error (#666).

* Account resolution from `account` and `server` arguments now gives specific
  recommendations on the values that you might use in the case of ambiguity
  or lack of matches (#666). Additionally, you'll now recieve a clear error
  message if you accidentally provide something other than a string or `NULL`
  to these arguments.

* `accountInfo()` and `removeAccount()` no longer require `account` be 
  supplied (#666).

* When needed packages are not installed, and you're in an interactive
  environment, rsconnect will now prompt you to install them (#665).

* The confirmation prompt presented upon lint failures indicates "no" as its
  default. (#652)

# rsconnect 0.8.29

* Introduced support for publishing to Posit Cloud. This feature is currently
  in closed beta and requires access to an enabled account on Posit Cloud.
  See [Posit Cloud's Announcement](https://posit.cloud/learn/whats-new#publishing)
  for more information and to request access.

* Update company and product names for rebranding to Posit.

# rsconnect 0.8.28

* Shiny applications and Shiny documents no longer include an implicit
  dependency on [`ragg`](https://ragg.r-lib.org) when that package is present
  in the local environment. This reverts a change introduced in 0.8.27.
  
  Shiny applications should add an explicit dependency on `ragg` (usually with
  a `library("ragg")` statement) to see it used by `shiny::renderPlot` (via
  `shiny::plotPNG`).
  
  The documentation for `shiny::plotPNG` explains the use of `ragg`. (#598)

* Fix bug that prevented publishing or writing manifests for non-Quarto content
  when a Quarto path was provided to the `quarto` argument of `writeManifest()`,
  `deployApp()`, and related functions.

* Escape account names when performing a directory search to determine an
  appropriate server. (#620)

# rsconnect 0.8.27

* Quarto content will no longer silently deploy as R Markdown content when
  Quarto metadata is missing or cannot be gathered. Functions will error,
  requesting the path to a Quarto binary in the `quarto` argument. (#594)
* Fix typo for `.rscignore`. (#599)
* Quarto deployments specifying only an `appDir` and `quarto` binary but not an
  `appPrimaryDoc` work more consistently. A directory containing a `.qmd` file
  will deploy as Quarto content instead of failing, and a directory containing
  an `.Rmd` file will successfully deploy as Quarto content instead of falling
  back to R Markdown. (#601)
* If the `ragg` package is installed locally, it is now added as an implicit
  dependency to `shiny` apps since `shiny::renderPlot()` now uses it by default 
  (when available). This way, `shiny` apps won't have to add `library(ragg)` to 
  get consistent (higher-quality) PNG images when deployed. (#598)

# rsconnect 0.8.26

* Add ability to resend shinyapps.io application invitations (#543)
* Show expiration status in shinyapps.io for invitations (#543)
* Allow shinyapps.io deployments to be private at creation time (#403)
* Update the minimum `openssl` version to 2.0.0 to enable publishing for users
  on FIPS-compliant systems without the need for API keys. (#452)
* Added Quarto support to `writeManifest`, which requires passing the absolute
  path to a Quarto executable to its new `quarto` parameter
* Added `quarto` parameter to `deployApp` to enable deploying Quarto documents
  and websites by supplying the path to a Quarto executable
* Added support for deploying Quarto content that uses only the `jupyter` runtime
* Added support for selecting a target `image` in the bundle manifest
* The `showLogs` function takes a `server` parameter. (#57)
* Added the `rsconnect.tar` option, which can be used to specify the path to a
  `tar` implementation instead of R's internal implementation. The previous
  method, using the `RSCONNECT_TAR` environment variable, still works, but the
  new option will take precedence if both are set.

# rsconnect 0.8.25

* Use the `curl` option `-T` when uploading files to avoid out of memory
  errors with large files. (#544)
* The `rsconnect.max.bundle.size` and `rsconnect.max.bundle.files` options are
  enforced when processing an enumerated set of files. Previously, these
  limits were enforced only when bundling an entire content directory. (#542)
* Preserve file time stamps when copying files into the bundle staging
  directory, which then propagates into the created tar file. (#540)
* Configuration directories align with CRAN policy and use the location named
  by `tools::R_user_dir`. Configuration created by earlier versions of this
  package is automatically migrated to the new location. (#550)

# rsconnect 0.8.24

* Added support for publishing Quarto documents and websites
* Added support for `.rscignore` file to exclude files or directories from publishing (#368)
* Fixed issue causing missing value errors when publishing content containing filenames with extended characters (#514)
* Fixed issue preventing error tracebacks from displaying (#518)

# rsconnect 0.8.18

* Fixed issue causing configuration directory to be left behind after `R CMD CHECK`
* Fixed incorrect subdirectory nesting when storing configuration in `R_USER_CONFIG_DIR`
* Added linter for different-case Markdown links (#388)
* Use new Packrat release on CRAN, 0.6.0 (#501)
* Fix incorrect linter messages referring to `shiny.R` instead of `server.R` (#509)
* Warn, rather than err, when the repository URL for a package dependency
  cannot be validated. This allows deployment when using archived CRAN
  packages, or when using packages installed from source that are available on
  the server. (#508)
* Err when the app-mode cannot be inferred; seen with empty directories/file-sets (#512)
* Add `verbose` option to `writeManifest` utility (#468)

# rsconnect 0.8.17

* Fixed issue where setting `options(rsconnect.http.trace.json = TRUE)` could cause deployment errors with some HTTP transports (#490)
* Improve how large bundles (file size and count) are detected (#464)
* The `RSCONNECT_TAR` environment variable can be used to select the tar implementation used to create bundles (#446)
* Warn when files are owned by users or groups with long names, as this can cause the internal R tar implementation to produce invalid archives (#446)
* Add support for syncing the deployment metadata with the server (#396)
* Insist on ShinyApps accounts in `showUsers()` (#398)
* Improve the regex used for the browser and browseURL lints to include a word boundary (#400)
* Fixed bug where `connectApiUser()` did not set a user id (#407)
* New arguments to `deployApp` to force the generation of a Python environment file or a `requirements.txt` file (#409)
* Fail when no repository URL is available for a dependent package (#410)
* Fix error when an old version of a package is installed and a current version isn't available (#431, #436)
* Fix error where packages couldn't be found with nonstandard contrib URLs. (#451, #457)
* Improve detection of Shiny R Markdown files when `server.R` is present (#461)
* Fix failure to write manifest when package requires a newer R version than the active version (#467)
* Increase default HTTP timeout on non-Windows platforms (#476)
* Require `packrat` 0.5 or later (#434)
* Fix error when handling empty application / content lists (#417, #395)
* Calls to `writeManifest()` no longer reference `packrat` files in the generated `manifest.json`. The `packrat` entries were transient and only existed while computing dependencies. (#472)
* Fix `applications` when ShinyApps does not return `size` details (#496)
* GitLab is seen as a valid SCM source (#491)

# rsconnect 0.8.16

* Prevent attempts to deploy Connect applications without uploading (#145)
* Flag usage of `browser()` debugging calls when deploying (#196)
* Prevent accidental deployment of Plumber APIs to shinyapps.io (#204)
* Allow `appId` and other global deployment parameters to `deploySite` (#231)
* Fix error when running `deployments()` without any registered accounts (#261)
* Omit `renv` files from deployment bundle (#367)
* Fix failure to deploy in Packrat projects (#370)
* Fix issue deploying when a package exists in multiple repos (#372)
* Honor `RETICULATE_PYTHON` when writing manifests (#374)
* Add `on.failure` user hook to run a function when `deployApp()` fails (#375)
* Fix error when showing non-streaming logs (#377)
* Use internally computed MD5 sums when MD5 is disabled in FIPS mode (#378, #382)
* Make it clearer which log entries are emitted by RStudio Connect (#385)
* Add support for `requirements.txt` for Python, if it exists (#386)
* Restore compatibility with R < 3.5 (#394)
* Add support for authenticating with Connect via an API key rather than a token (#393)

# rsconnect 0.8.15

* Switch from **RCurl** to **curl** as the default HTTP backend (#325)
* Add `purgeApp()` function to purge previously deployed shinyapps.io applications (#352)
