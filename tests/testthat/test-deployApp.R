test_that("appDir must be an existing directory", {
  expect_snapshot(error = TRUE, {
    deployApp(1)
    deployApp("doesntexist")
  })
})

test_that("single document appDir is deprecated", {
  expect_snapshot(error = TRUE, {
    deployApp("foo.Rmd")
  })
})

test_that("appPrimaryDoc must exist, if supplied", {
  dir <- local_temp_app()

  expect_snapshot(error = TRUE, {
    deployApp(dir, appPrimaryDoc = c("foo.Rmd", "bar.Rmd"))
    deployApp(dir, appPrimaryDoc = "foo.Rmd")
  })
})
test_that("recordDoc must exist, if supplied", {
  dir <- local_temp_app()

  expect_snapshot(error = TRUE, {
    deployApp(dir, recordDir = "doesntexist")
  })
})

test_that("startup scripts are logged by default", {
  dir <- local_temp_app()
  withr::local_dir(dir)
  writeLines("1 + 1", file.path(dir, ".rsconnect_profile"))

  expect_snapshot(runStartupScripts("."))
})

# record directory --------------------------------------------------------

test_that("findRecordPath() uses recordDir, then appPrimaryDoc, then appDir", {
  expect_equal(findRecordPath("a"), "a")
  expect_equal(findRecordPath("a", recordDir = "b"), "b")
  expect_equal(findRecordPath("a", appPrimaryDoc = "c"), "a/c")
})

# app visibility ----------------------------------------------------------

test_that("needsVisibilityChange() returns FALSE when no change needed", {

  dummyApp <- function(visibility) {
    list(
      deployment = list(
        properties = list(
          application.visibility = visibility
        )
      )
    )
  }

  expect_false(needsVisibilityChange("connect.com"))
  expect_false(needsVisibilityChange("shinyapps.io", dummyApp("public"), NULL))
  expect_false(needsVisibilityChange("shinyapps.io", dummyApp("public"), "public"))
  expect_true(needsVisibilityChange("shinyapps.io", dummyApp(NULL), "private"))
  expect_true(needsVisibilityChange("shinyapps.io", dummyApp("public"), "private"))
})

test_that("deployHook executes function if set", {
  withr::local_options(rsconnect.pre.deploy = NULL)
  expect_equal(
    runDeploymentHook("PATH", "rsconnect.pre.deploy"),
    NULL
  )

  withr::local_options(rsconnect.pre.deploy = function(path) path)
  expect_equal(
    runDeploymentHook("PATH", "rsconnect.pre.deploy"),
    "PATH"
  )
  expect_snapshot(
    . <- runDeploymentHook("PATH", "rsconnect.pre.deploy", verbose = TRUE)
  )
})
