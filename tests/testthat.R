# Test runner for cowfootR package
library(testthat)
library(cowfootR)

test_check("cowfootR")

if (!requireNamespace("withr", quietly = TRUE)) {
  skip("withr not available for tests")
}
