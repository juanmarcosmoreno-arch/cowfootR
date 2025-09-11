## Resubmission

This is a resubmission. In this version I have:

* Removed redundant "Provides functions to" from the Description field
* Added proper references to IDF (2022) and IPCC (2019) methodologies in Description field using the format: authors (year) "Title" <doi:...> and <https:...>
* Added missing \value tags to all print methods: print.cf_area_intensity, print.cf_intensity, and print.cf_total
* Replaced all \dontrun{} with \donttest{} in function examples
* Fixed file timestamp issues that were causing NOTEs

## Test environments

* local macOS install, R 4.5.1
* ubuntu-latest (on GitHub Actions), R devel, release
* windows-latest (on GitHub Actions), R release
* macOS-latest (on GitHub Actions), R release

## R CMD check results

0 errors | 0 warnings | 0 notes

## Downstream dependencies

There are currently no downstream dependencies for this package.
