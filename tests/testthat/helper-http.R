cache <- new_environment()

httpbin_service <- function() {
  app <- env_cache(
    cache,
    "test_app",
    webfakes::new_app_process(webfakes::httpbin_app())
  )

  parseHttpUrl(app$url())
}

# Generic tests of various http methods -----------------------------------

test_http_GET <- function() {
  service <- httpbin_service()

  # Perform the request
  resp <- GET(service, authInfo = NULL, path = "get")
  expect_equal(attr(resp, "httpResponse")$status, 200)
  expect_equal(attr(resp, "httpResponse")$contentType, "application/json")
  expect_equal(resp$path, "/get")
}

test_http_POST_JSON <- function() {
  service <- httpbin_service()

  body <- list(a = 1, b = 2, c = 3)
  resp <- POST_JSON(service, authInfo = NULL, path = "post", json = body)
  expect_equal(attr(resp, "httpResponse")$status, 200)
  expect_equal(resp$json, body)
}

test_http_POST_empty <- function() {
  service <- httpbin_service()

  resp <- POST(service, authInfo = NULL, path = "post")
  expect_equal(attr(resp, "httpResponse")$status, 200)
  expect_equal(resp$json, set_names(list()))
}

test_http_POST_file <- function() {
  service <- httpbin_service()

  path <- withr::local_tempfile()
  con <- file(path, "wb")
  writeLines(c("1", "2", "3"), con = con)
  close(con)

  resp <- POST(
    service,
    authInfo = NULL,
    path = "post",
    contentType = "text/plain",
    file = path
  )
  expect_equal(attr(resp, "httpResponse")$status, 200)
  expect_equal(resp$data, "1\n2\n3\n")
}

test_http_headers <- function() {
  service <- httpbin_service()

  resp <- GET(service, authInfo = list(apiKey = "abc123"), path = "get")
  expect_equal(attr(resp, "httpResponse")$status, 200)
  expect_equal(resp$headers$Authorization, "Key abc123")

  resp <- POST(service, authInfo = list(apiKey = "abc123"), path = "post")
  expect_equal(attr(resp, "httpResponse")$status, 200)
  expect_equal(resp$headers$Authorization, "Key abc123")
}
