DonwloadR - R Package Downloader

Contents:
taskviews.csv - list of CRAN Task Views to download (see specs below)
packages.csv - list of supplemental packages to download (see specs below)
downloadr.R - downloads packages specified by taskviews.csv and packages.csv

Functionality:
1. Downloads either all of the packages or only the core packages of each
    CRAN Task View as specified in taskviews.csv
2. Unless already downloaded, downloads all packages specified in packages.csv
3. Checks for and downloads any dependencies required by downloaded packages

Dependencies: readr, dplyr, purrr, ctv, tools


Input File Specifications:

taskviews.csv
    List of CRAN Task Views and their download status
    Must contain the following columns:
        name - exact spelling of the name of the task view
        status - 0/1/2 as specified below
            0 - do not download
            1 - download core packages only
            2 - download all packages
    Any other columns will be ignored


packages.csv
    List of packages to download
    Use this to supplement packages included in CRAN Task Views or specify
        packages that definitely need to be downloaded regardless of whether
        or not they are included in a downloaded CRAN Task View
    Must contain the following columns:
        name - exact spelling of the package name
        status - 0/1 as specified below
            0 - do not download
            1 - download package
    Any other columns will be ignored
