% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/database.R
\name{upload_comments}
\alias{upload_comments}
\title{Upload Comments}
\usage{
upload_comments(
  uri_fun,
  user,
  password,
  host,
  replica_set,
  port,
  database,
  patient_ids,
  comments
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

\item{patient_ids}{Vector of patient ID's.}

\item{comments}{Vector of patient comments.}
}
\value{
{
Objects of class character, reporting on completed event uploads.
}
}
\description{
Uploads patient comments for patients already in the patient list. Useful when some comments have already been documented before running CEDARS. Only comments for existing records are altered, missing patient records are not added!
}
\examples{
\dontrun{
upload_comments(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
host = 'server1234', port = NA, database = 'TEST_PROJECT', patient_ids = ids,
comments = comment_text)
}
}
