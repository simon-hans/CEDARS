% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/database.R
\name{download_events}
\alias{download_events}
\title{Download Event Data}
\usage{
download_events(
  uri_fun,
  user,
  password,
  host,
  replica_set,
  port,
  database,
  dates = FALSE,
  sentences_only = FALSE
)
}
\arguments{
\item{uri_fun}{Uniform resource identifier (URI) string generating function for MongoDB credentials.}

\item{user}{MongoDB user name.}

\item{password}{MongoDB user password.}

\item{host}{MongoDB host server.}

\item{replica_set}{MongoDB replica set, if indicated.}

\item{port}{MongoDB port.}

\item{database}{MongoDB database name.}

\item{dates}{Provide dates of first and last note for each patient; this is needed to assess
duration of follow-up, however can take a long time with large cohorts.}

\item{sentences_only}{Should only a list of sentences be provided?}
}
\value{
{
Object of class data.frame containing patient ID for all cohort members, date of recorded event if any,
abstractor comments, sentences reviewed along with statistics about review process.
}
}
\description{
Downloads patient event data. Typically done after all records have been annotated and the project is complete.
}
\examples{
\dontrun{
download_events(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
host = 'server1234', port = NA)
}
}
