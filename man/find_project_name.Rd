% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/accessory_functions.R
\name{find_project_name}
\alias{find_project_name}
\title{Generate unique test project name (i.e. DB name) on MongoDB CEDARS testing cluster}
\usage{
find_project_name()
}
\value{
{
An object of class character, the randomly generated name of a test CEDARS project.
}
}
\description{
Parses existing DB names and randomly generates a unique test project name on MongoDB CEDARS testing cluster. This is used for convenience purposes when the R user does not have an existing MongoDB connection. The corresponding database and collections are PUBLIC so no patient information or any other privileged/confidential data should be used! This is for testing on simulated records only.
}
\details{
{
No parameter; the operation is performed on a preset server with no user input.
}
}
\examples{
\dontrun{
find_project_name()
}
}
