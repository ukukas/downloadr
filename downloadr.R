# DownloadR - Download R Packages for Offline Install
#
# downloads all packages from specified CRAN Task Views plus any additional
# specified packages and all dependencies of any downloaded packages
#
# see README for details


## CONSTANTS

# directory into witch packages will be downloaded
DESTDIR <- "./downloads"

# csv of downloaded files and corresponding package names
DOWNLOADS_CSV <- "./packagelist.csv"

# type of package to download (see install.packages for details)
# "source" - requires compilation when installing
# "binary" - will attempt to select appropriate binary type based on system
# system specific: "win.binary", "mac.binary", or "mac.binary.el-capitan"
# WARN: do not use "both" as it will revert to "source"
PKGTYPE <- "win.binary"

# types of dependencies to check for
# subset of c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")
DEPTYPES <- base::c("Depends", "Imports", "LinkingTo")

# URLs of the repositories to use
REPOS <- base::c("https://cloud.r-project.org/")

# CSV of CRAN Task Views to download
TASKVIEWS_CSV <- "./taskviews.csv"

# CSV of packages to download
PACKAGES_CSV <- "./packages.csv"


## SETUP

# ensure required packages are installed and loaded

base::invisible(base::lapply(
  base::c("readr", "dplyr", "purrr", "ctv", "tools"),
  \(dep) {
    if (!require(dep, character.only = TRUE)) {
      base::install.packages(dep)
      library(dep, character.only = TRUE)
    }
  }
))


## MAIN

# get package list from task views

tv_status <- readr::read_csv(TASKVIEWS_CSV, show_col_types = FALSE)

tv_packages <- ctv::available.views(repos = REPOS) %>%
  base::lapply(\(tv) {
    status <- tv_status %>%
      dplyr::filter(name == tv$name) %>%
      dplyr::pull(status) %>%
      dplyr::first()
    if (status == 1) {
      tv$packagelist %>%
        dplyr::filter(core == TRUE) %>%
        dplyr::pull(name) %>%
        return()
    } else if (status == 2) {
      return(tv$packagelist$name)
    } else {
      return(NULL)
    }
  }) %>%
  purrr::flatten() %>%
  base::unlist() %>%
  base::unique()


# add packages from specified package list if needed

csv_packages <- readr::read_csv(PACKAGES_CSV, show_col_types = FALSE) %>%
  dplyr::filter(status == 1) %>%
  dplyr::pull(name)

desired_packages <- base::union(csv_packages, tv_packages)


# derive dependencies and determine package availability

repo_packages <- utils::available.packages(repos = REPOS)

package_deps <- tools::package_dependencies(
  packages = desired_packages,
  db = repo_packages,
  which = DEPTYPES,
  recursive = TRUE
)

base_packages <- base::rownames(utils::installed.packages(priority = "base"))
repo_packages <- base::rownames(repo_packages)
available_packages <- base::union(repo_packages, base_packages)


# drop any desired package with dependencies not available via REPOS

desired_packages <- base::Filter(\(pkg) {
  closure <- base::c(pkg, package_deps[[pkg]])
  missing <- base::setdiff(closure, available_packages)
  if (length(missing) > 0) {
    warning(base::sprintf(
      "dropping '%s': requires unavailable package(s): %s",
      pkg, base::paste(missing, collapse = ", ")
    ), call. = FALSE)
    return(FALSE)
  }
  TRUE
}, desired_packages)


# check if download directory exists, create if needed

if (!base::dir.exists(DESTDIR)) {
  base::dir.create(DESTDIR)
}

# remove base R packages and download final selection

purrr::flatten(package_deps[desired_packages]) %>%
  base::union(desired_packages) %>%
  base::setdiff(base_packages) %>%
  utils::download.packages(DESTDIR, repos = REPOS, type = PKGTYPE) %>%
  base::data.frame() %>%
  purrr::set_names(c("package", "file")) %>%
  readr::write_csv(DOWNLOADS_CSV)
