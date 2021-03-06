% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_io.R
\name{unlock_records}
\alias{unlock_records}
\title{Unlock Old Locked Records
Occasionally a CEDARS end user will lock a patient record but not complete the annotation task. The end user lock will be respected for 24 hours after entry, however after this time period running this function will unlock the record. Called when another user sends a GET request and the server looks for a new patient to annotate. Prevents permanent locking of records by end users.}
\usage{
unlock_records(uri_fun, user, password, host, replica_set, port, database)
}
\arguments{
\item{uri_fun}{Uniform resource identifier (URI) string generating function for MongoDB credentials.}

\item{user}{MongoDB user name.}

\item{password}{MongoDB user password.}

\item{host}{MongoDB host server.}

\item{replica_set}{MongoDB replica set, if indicated.}

\item{port}{MongoDB port.}

\item{database}{MongoDB database name.}
}
\description{
Unlock Old Locked Records
Occasionally a CEDARS end user will lock a patient record but not complete the annotation task. The end user lock will be respected for 24 hours after entry, however after this time period running this function will unlock the record. Called when another user sends a GET request and the server looks for a new patient to annotate. Prevents permanent locking of records by end users.
}
\keyword{internal}
