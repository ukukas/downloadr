# DownloadR - Download R Packages for Offline Install
#
# downloads all packages from specified CRAN Task Views plus any additional
# specified packages and all dependencies of any downloaded packages
#
# see README for details


## CONSTANTS

# directory into witch packages will be downloaded
DESTDIR <- './downloads'

# csv of downloaded files and corresponding package names
DOWNLOADS_CSV  <- './packagelist.csv'

# type of package to download (see install.packages for details)
# "source" - requires compilation when installing
# "binary" - will attempt to select appropriate binary type based on system
# system specific: "win.binary", "mac.binary", or "mac.binary.el-capitan"
# WARN: do not use "both" as it will revert to "source"
PKGTYPE <- 'win.binary'

# types of dependencies to check for
# subset of c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")
DEPTYPES = c('Depends', 'Imports', 'LinkingTo')

# URLs of the repositories to use
REPOS <- c('https://cloud.r-project.org/')

# CSV of CRAN Task Views to download
TASKVIEWS_CSV <- './taskviews.csv'

# CSV of packages to download
PACKAGES_CSV <- './packages.csv'


## SETUP

# ensure required packages are installed and loaded

deps = c('readr', 'dplyr', 'purrr', 'ctv', 'tools')

checkDep <- function(dep) {
    if(!require(dep, character.only = TRUE)){
        install.packages(dep)
        library(dep, character.only = TRUE)
    }
}

invisible(lapply(deps, checkDep))


## MAIN

# get package list from task views

tv_status <- read_csv(TASKVIEWS_CSV)
tv_list <- available.views()

processTV <- function(tv) {
    status <- tv_status %>% filter(name == tv$name) %>% pull(status) %>% first()
    if (status == 1) {
        return(tv$packagelist %>% filter(core == TRUE) %>% pull(name))
    } else if (status == 2) {
        return(tv$packagelist$name)
    } else {
        return(NULL)
    }
}

tv_packages <- lapply(tv_list, processTV) %>% flatten() %>% unique()


# add packages from specified package list if needed

desired_packages <- read_csv(PACKAGES_CSV) %>%
    filter(status == 1) %>%
    pull(name) %>%
    c(tv_packages) %>%
    unique()


# get dependencies and add to download list if needed

all_pacakges <- package_dependencies(desired_packages, recursive = TRUE,
                                       db = available.packages(repos = REPOS),
                                       which = DEPTYPES) %>%
    flatten() %>%
    unique() %>%
    c(desired_packages) %>%
    unique()


# remove packages included in base R

base_packages <- rownames(installed.packages(priority="base"))
final_pacakges <- discard(all_pacakges, function(x) x %in% base_packages)


# check if download directory exists, create if needed

if (!dir.exists(DESTDIR)) {
    dir.create(DESTDIR)
}

# download required packages and output list of downloaded packages

packagelist <- download.packages(final_pacakges, DESTDIR, repos = REPOS,
                                 type = PKGTYPE) %>% data.frame()
colnames(packagelist) <- c('package', 'file')
write_csv(packagelist, DOWNLOADS_CSV)
