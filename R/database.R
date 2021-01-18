

# Functions to access MongoDB database.


#' Prepare MongoDB URI string, most commonly used format
#'
#' Formats the MongoDB URI string for use by package mongolite. In this case the 'standard' URI format is used.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @return URI string.
#' @examples
#' \dontrun{
#' mongo_uri_standard(user = 'John', password = 'db_password_1234', host = 'server1234', port = NA)
#' }
#' @export

mongo_uri_standard <- function(user, password, host, port = NA) {

    if (is.na(port)) {

        if (substr(host, nchar(host)-10, nchar(host))!="mongodb.net") {

            URI = sprintf("mongodb://%s:%s@%s/", user, password, host)

        } else {

            # Using DNS seed list format if host on mongodb.net
            URI = sprintf("mongodb+srv://%s:%s@%s/", user, password, host)

        }

    } else {

        URI = sprintf("mongodb://%s:%s@%s:%s/", user, password, host, port)

    }

    URI

}


#' Connect to MongoDB
#'
#' Basic function used by CEDARS to connect to MongoDB instance. Wraps mongo() from mongolite.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param mongo_collection MongoDB collection; if NA, will connect to DB itself.
#' @keywords internal

mongo_connect <- function(uri_fun, user, password, host, port, database, mongo_collection) {

    URI = uri_fun(user, password, host, port)

    if (is.na(mongo_collection)) {

        mongo_con <- mongolite::mongo(db = database, url = URI, verbose = TRUE)

    } else mongo_con <- mongolite::mongo(collection = mongo_collection, db = database, url = URI, verbose = TRUE)

    mongo_con

}


#' Obtain Patient Notes
#'
#' Downloads the notes for one patient. If there are missing fields, those are created with NA values inserted.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param patient_id Patient ID for which notes are being requested.
#' @return Dataframe of full notes and/or note parts with associated metadata.
#' @keywords internal

db_download <- function(uri_fun, user, password, host, port, database, patient_id) {

    # Expected fields
    fields <- c("text", "text_id", "text_date", "text_sequence", "doc_section_name", "doc_id", "text_tag_1", "text_tag_2",
        "text_tag_3", "text_tag_4", "text_tag_5", "text_tag_6", "text_tag_7", "text_tag_8", "text_tag_9", "text_tag_10")

    mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "NOTES")
    query <- paste("{\"patient_id\" :", patient_id, "}", sep = " ")
    notes <- mongo_con$find(query)

    # If all values NA for ma given, MongoDB does not import, so we have to restore missing fields

    missing_fields <- fields[!(fields %in% colnames(notes))]
    missing_frame <- matrix(nrow = length(notes[, 1]), ncol = length(missing_fields))
    missing_frame <- as.data.frame(missing_frame)
    colnames(missing_frame) <- missing_fields
    notes <- cbind(notes, missing_frame)

    notes

}


#' Upload Annotations
#'
#' Uploads NLP annotations for one patient.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param patient_id Patient ID.
#' @param annotations NLP annotations.
#' @keywords internal

db_upload <- function(uri_fun, user, password, host, port, database, patient_id, annotations) {

    annotations <- cbind(rep(patient_id, length(annotations[, 1])), annotations)
    colnames(annotations)[1] <- "patient_id"
    annotations <- annotations[order(annotations$text_id, annotations$paragraph_id, annotations$sentence_id, annotations$token_id,
        decreasing = FALSE, method = "radix"), ]

    # Turning the 'updated' indicator on
    patients_con <- mongo_connect(uri_fun, user, password, host, port, database, "PATIENTS")
    query_value <- paste("{ \"patient_id\" : ", patient_id, "}", sep = "")
    update_value <- "{ \"$set\" : { \"updated\" : true } }"
    patients_con$update(query = query_value, update = update_value)

    # Entering annotations
    annotations_con <- mongo_connect(uri_fun, user, password, host, port, database, "ANNOTATIONS")
    upload_results <- suppressWarnings(annotations_con$insert(annotations, stop_on_error = FALSE))
    print(paste(upload_results$nInserted, " of ", length(annotations[, 1]), " records inserted!", sep = ""))

}


#' Update Patient List
#'
#' Updates the 'PATIENTS' collection with new entries. Used after NLP annotations have been uploaded.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @keywords internal

patient_roster_update <- function(uri_fun, user, password, host, port, database) {

    annotations_con <- mongo_connect(uri_fun, user, password, host, port, database, "ANNOTATIONS")
    unique_patients <- annotations_con$distinct("patient_id")

    patients_con <- mongo_connect(uri_fun, user, password, host, port, database, "PATIENTS")
    active_patients <- patients_con$distinct("patient_id")

    missing_patients <- unique_patients[!(unique_patients %in% active_patients)]
    missing_patients <- data.frame(patient_id = missing_patients, reviewed = rep(FALSE, length(missing_patients)),
        locked = rep(FALSE, length(missing_patients)), updated = rep(FALSE, length(missing_patients)), admin_locked = rep(FALSE,
            length(missing_patients)))

    patients_con$insert(missing_patients)

}


#' Prepare Database for NLP Annotation
#'
#' Creates 'ANNOTATIONS' and 'PATIENTS' collections, assuming main DB collection and notes were already set up.This is necessary before launching the NLP annotation process.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @keywords internal

populate_annotations <- function(uri_fun, user, password, host, port, database) {

    mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)
    # collections <- (mongo_con$run('{'listCollections': 1}')[[1]])$firstBatch

    mongo_con$run("{\"create\": \"ANNOTATIONS\"}")
    mongo_con$run("{\"create\": \"PATIENTS\"}")

    annotations_con <- mongo_connect(uri_fun, user, password, host, port, database, "ANNOTATIONS")
    annotations_con$index(add = "{\"patient_id\" : 1}")
    annotations_con$index(add = "{\"CUI\" : 1}")
    annotations_con$index(add = "{\"lemma\" : 1}")
    annotations_con$index(add = "{\"doc_id\" : 1}")

    # mongolite still does not support creation of unique indexes We enforce that each annotation record should
    # have aunique combination fo text ID, paragraph, sentence and token ID
    annotations_con$run("{\"createIndexes\": \"ANNOTATIONS\", \"indexes\" : [{ \"key\" : { \"text_id\" : 1, \"paragraph_id\" : 1, \"sentence_id\" : 1, \"token_id\" : 1}, \"name\": \"annotations_index\", \"unique\": true}]}")

}


#' Prepare Database for Patient Notes
#'
#' Sets up the 'NOTES' collection which will hold original EHR documents. Those notes can exist as complete documents (one doc per note) or in atomized form (several docs, each a subsection of one note).
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @keywords internal

populate_notes <- function(uri_fun, user, password, host, port, database) {

    mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)

    mongo_con$run("{\"create\": \"NOTES\"}")

    notes_con <- mongo_connect(uri_fun, user, password, host, port, database, "NOTES")

    notes_con$index(add = "{\"patient_id\" : 1}")
    notes_con$index(add = "{\"doc_id\" : 1}")

    # mongolite still does not support creation of unique indexes
    notes_con$run("{\"createIndexes\": \"NOTES\", \"indexes\" : [{ \"key\" : { \"text_id\" : 1}, \"name\": \"text_id\", \"unique\": true}]}")

}


#' Prepare Database for User Credentials
#'
#' Sets up 'USERS' collection where CEDARS end user names and passwords will be retained.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @keywords internal

populate_users <- function(uri_fun, user, password, host, port, database) {

    users_con <- mongo_connect(uri_fun, user, password, host, port, database, "USERS")

    # mongolite still does not support creation of unique indexes
    users_con$run("{\"createIndexes\": \"USERS\", \"indexes\" : [{ \"key\" : { \"user\" : 1}, \"name\": \"user\", \"unique\": true}]}")

}


#' Prepare Database for Dictionary Data Upload
#'
#' Set ups collections for the UMLS MRCONSO/MRREL and NegEx files. MRCONSO consists of a list of UMLS concept unique identifiers (CUI's) with corresponding text strings and NegEx is a simple negation lexicon. The UMLS files are not provided as paer of the CEDARS package and must be dowloaded the NIH web site at https://www.nlm.nih.gov/research/umls/index.html. NegEx is included in CEDARS and its use is governed by the Apache License 2.0.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @keywords internal

populate_dictionaries <- function(uri_fun, user, password, host, port, database) {

    mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)

    mongo_con$run("{\"create\": \"NEGEX\"}")

    mongo_con$run("{\"create\": \"UMLS_MRCONSO\"}")
    mrconso_con <- mongo_connect(uri_fun, user, password, host, port, database, "UMLS_MRCONSO")
    mrconso_con$index(add = "{\"CUI\" : 1}")
    mrconso_con$index(add = "{\"STR\" : 1}")
    mrconso_con$index(add = "{\"grams\" : 1}")

    mongo_con$run("{\"create\": \"UMLS_MRREL\"}")
    mrrel_con <- mongo_connect(uri_fun, user, password, host, port, database, "UMLS_MRREL")
    mrrel_con$index(add = "{\"CUI\" : 1}")

}


#' Prepare Database to Receive the Search Query
#'
#' Sets up the 'QUERY' collection to store the search query and associated information.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @keywords internal

populate_query <- function(uri_fun, user, password, host, port, database) {

    mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)

    mongo_con$run("{\"create\": \"QUERY\"}")

}


#' Save Search Query
#'
#' Saves the search query. The query consists of keywords/UMLS concept unique identifiers (CUI's), boolean elements and other operators ('AND', 'OR', '!', '(', or ')').
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param search_query Medical corpus query containg keywords/CUI's, boolean elements and other operators ('AND', 'OR', '!', '(', or ')').
#' @param use_negation Should negated items be ignored in the keyword/concept search?
#' @param hide_duplicates Should duplicated sentences be removed for search results?
#' @param skip_after_event Should sentences occurring after recorded clinical event be skipped?
#' @examples
#' \dontrun{
#' save_query(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT', search_query = 'thrombosis AND venous',
#' use_negation = TRUE, hide_duplicates = TRUE, skip_after_event = TRUE)
#' }
#' @export

save_query <- function(uri_fun, user, password, host, port, database, search_query, use_negation, hide_duplicates, skip_after_event) {

    search_query <- sanitize_query(search_query)

    query_con <- mongo_connect(uri_fun, user, password, host, port, database, "QUERY")

    if (use_negation == TRUE)
        converted_negation <- "true" else converted_negation <- "false"
    if (hide_duplicates == TRUE)
        converted_hide_duplicates <- "true" else converted_hide_duplicates <- "false"
    if (skip_after_event == TRUE)
        converted_skip_after_event <- "true" else converted_skip_after_event <- "false"

    update_value <- paste("{ \"query\" : \"", search_query, "\", \"exclude_negated\" : ", converted_negation, " , \"hide_duplicates\" : ",
        converted_hide_duplicates, " , \"skip_after_event\" : ", converted_skip_after_event, "}", sep = "")

    query_con$replace(query = "{}", update = update_value, upsert = TRUE)

}


#' Initialize Annotations
#' Deletes all NLP annotations and patient-specific information, including clinical event dates.New, empty 'ANNOTATIONS' and 'PATIENTS' collections are created. Dictionaries and original patient notes are preserved.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @examples
#' \dontrun{
#' initialize_annotations(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @export

initialize_annotations <- function(uri_fun, user, password, host, port, database) {

    first_answer <- readline("Are you sure you want to proceed? All annotations will be irreversibly deleted. (yes/no) ")

    if (first_answer != "yes")
        stop("Deletion cancelled") else {

        second_answer <- readline("Are you absolutely positive you want to permanently delete the annotations? (yes/no) ")

    }

    if (second_answer != "yes")
        stop("Database deletion cancelled") else {

        # Dropping the collections

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "ANNOTATIONS")
        mongo_con$drop()
        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "PATIENTS")
        mongo_con$drop()

        # Verifying deletion

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)
        collections <- (mongo_con$run("{\"listCollections\": 1}")[[1]])$firstBatch
        if ("ANNOTATIONS" %in% collections$name | "PATIENTS" %in% collections$name)
            print("Deletion failed!") else {

            populate_annotations(uri_fun, user, password, host, port, database)
            print("Initialization successful!")

        }

    }

}


#' Initialize Patient List
#'
#' All patient-specific information is deleted, including clinical event dates. Original notes and NLP annotations are preserved.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @examples
#' \dontrun{
#' initialize_patients(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @export

initialize_patients <- function(uri_fun, user, password, host, port, database) {

    first_answer <- readline("Are you sure you want to proceed? Event data will be irreversibly deleted. (yes/no) ")

    if (first_answer != "yes")
        stop("Deletion cancelled") else {

        second_answer <- readline("Are you absolutely positive you want to permanently delete the patient roster? (yes/no) ")

    }

    if (second_answer != "yes")
        stop("Database deletion cancelled") else {

        # Dropping the collection

        patients_con <- mongo_connect(uri_fun, user, password, host, port, database, "PATIENTS")
        patients_con$drop()

        # Verifying deletion

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)
        collections <- (mongo_con$run("{\"listCollections\": 1}")[[1]])$firstBatch
        if ("PATIENTS" %in% collections$name)
            print("Deletion failed!") else {

            patient_roster_update(uri_fun, user, password, host, port, database)
            print("Initialization successful!")

        }

    }

}


#' Initialize End User List
#'
#' Deletes all CEDARS end user credentials information.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @examples
#' \dontrun{
#' initialize_users(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @export

initialize_users <- function(uri_fun, user, password, host, port, database) {

    first_answer <- readline("Are you sure you want to proceed? User data will be irreversibly deleted. (yes/no) ")

    if (first_answer != "yes")
        stop("Deletion cancelled") else {

        second_answer <- readline("Are you absolutely positive you want to permanently delete the CEDARS user information? (yes/no) ")

    }

    if (second_answer != "yes")
        stop("Database deletion cancelled") else {

        # Dropping the collection

        users_con <- mongo_connect(uri_fun, user, password, host, port, database, "USERS")
        users_con$drop()

        # Verifying deletion

        users_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)
        collections <- (users_con$run("{\"listCollections\": 1}")[[1]])$firstBatch
        if ("USERS" %in% collections$name)
            print("Deletion failed!") else {

            print("Initialization successful!")
            populate_users(uri_fun, user, password, host, port, database)

        }

    }

}


#' Initialize EHR Notes
#'
#' Deletes all patient notes from the database.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @examples
#' \dontrun{
#' initialize_notes(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @export

initialize_notes <- function(uri_fun, user, password, host, port, database) {

    first_answer <- readline("Are you sure you want to proceed? Clinical notes will be irreversibly deleted. (yes/no) ")

    if (first_answer != "yes")
        stop("Deletion cancelled") else {

        second_answer <- readline("Are you absolutely positive you want to permanently delete the notes information? (yes/no) ")

    }

    if (second_answer != "yes")
        stop("Database deletion cancelled") else {

        # Dropping the collection

        notes_con <- mongo_connect(uri_fun, user, password, host, port, database, "NOTES")
        notes_con$drop()

        # Verifying deletion

        notes_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)
        collections <- (notes_con$run("{\"listCollections\": 1}")[[1]])$firstBatch
        if ("NOTES" %in% collections$name)
            print("Deletion failed!") else {

            print("Initialization successful!")
            populate_notes(uri_fun, user, password, host, port, database)

        }

    }

}


#' Add a CEDARS End User
#'
#' Adds an end user. Password must be at least 8 characters in length.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param end_user_password CEDARS end user password.
#' @examples
#' \dontrun{
#' add_end_user(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT', end_user = 'Mike',
#' end_user_password = 'user_pw_5678')
#' }
#' @export

add_end_user <- function(uri_fun, user, password, host, port, database, end_user, end_user_password) {

    if (nchar(end_user_password) < 8)
        print("User creation failed, password must be at least 8 characters in length!") else {

        end_user <- as.character(end_user)
        end_user_password <- as.character(end_user_password)

        users_con <- mongo_connect(uri_fun, user, password, host, port, database, "USERS")

        new_user <- data.frame(user = end_user, password = end_user_password, date_created = strftime(Sys.time(),
            "%Y-%m-%dT%H:%M:%SZ", "UTC"))

        users_con$insert(new_user)

        user_query <- paste("{ \"user\" : ", "\"", end_user, "\" }", sep = "")

        users <- users_con$find(user_query)

        if (users$user[1] == end_user)
            print("End user creation successful.") else print("End user creation failed!")

    }

}


#' Delete a CEDARS End USer
#'
#' Deletes one end user and associated password.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @examples
#' \dontrun{
#' delete_end_user(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT', end_user = 'Mike')
#' }
#' @export

delete_end_user <- function(uri_fun, user, password, host, port, database, end_user) {

    end_user <- as.character(end_user)

    users_con <- mongo_connect(uri_fun, user, password, host, port, database, "USERS")

    user_query <- paste("{ \"user\" : ", "\"", end_user, "\" }", sep = "")
    users <- users_con$find(user_query)
    if (length(users$user[1]) == 0)
        print("This end user does not exist!") else {

        query_value <- paste("{ \"user\" : ", "\"", end_user, "\" }", sep = "")

        users_con$remove(query = query_value)
        user_query <- paste("{ \"user\" : ", "\"", end_user, "\" }", sep = "")
        users <- users_con$find(user_query)

        if (length(users$user[1]) == 0)
            print("End user deletion successful.") else print("End user deletion failed!")

    }

}


#' Create a New CEDARS Project
#'
#' Creates a new MongoDB database and collections needed for a CEDARS annotation project. The MongoDB account used must have sufficient privileges.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param project_name Research or QA project name.
#' @param investigator_name Investigator name.
#' @examples
#' # The code below creates an instance of CEDARS project on a public test MongoDB cluster, populated
#' # with fictitious EHR corpora.
#'
#' # MongoDB credentials
#' db_user_name <- "testUser"
#' db_user_pw <- "testPW"
#' db_host <- "cedars.yvjp6.mongodb.net"
#' db_port <- NA
#'
#' # Using standard MongoDB URL format
#' uri_fun <- mongo_uri_standard
#'
#' # Name for MongoDB database which will contain the CEDARS project
#' # In this case we generate a random name
#' mongo_database <- find_project_name()
#'
#' # We create the database and all required collections on a test cluster
#' create_project(uri_fun, db_user_name, db_user_pw, db_host, db_port, mongo_database,
#' "CEDARS Example Project", "Dr Smith")
#'
#'# Adding one CEDARS end user
#' add_end_user(uri_fun, db_user_name, db_user_pw, db_host, db_port, mongo_database, "John",
#' "strongpassword")
#'
#' \dontrun{
#'
#' # Negex is included with CEDARS and required for assessment of negation
#' negex_upload(uri_fun, db_user_name, db_user_pw, db_host, db_port, mongo_database)
#' }
#'
#' # Uploading the small simulated collection of EHR corpora
#' upload_notes(uri_fun, db_user_name, db_user_pw, db_host, db_port, mongo_database,
#' simulated_patients)
#'
#' # This is a simple query which will report all sentences with a word starting in
#' # "bleed" or "hem", or an exact match for "bled"
#' search_query <- "bleed* OR hem* OR bled"
#' use_negation <- TRUE
#' hide_duplicates <- TRUE
#' skip_after_event <- TRUE
#' save_query(uri_fun, db_user_name, db_user_pw, db_host, db_port, mongo_database, search_query,
#' use_negation, hide_duplicates, skip_after_event)
#'
#' \dontrun{
#'
#' # Running the NLP annotations on EHR corpora
#' # We are only using one core, for large datasets parallel processing is faster
#' automatic_NLP_processor(NA, "latin1", "udpipe", uri_fun, db_user_name, db_user_pw,
#' db_host, db_port, mongo_database, max_n_grams_length = 0, negex_depth = 6, select_cores = 1)
#'
#' # Starts the CEDARS GUI locally
#' # Your user name is "John", password is "strongpassword"
#' start_local(db_user_name, db_user_pw, db_host, db_port, mongo_database)
#' }
#'
#' # Remove project from MongoDB
#' terminate_project(uri_fun, db_user_name, db_user_pw, db_host, db_port, mongo_database, fast=TRUE)
#' @export

create_project <- function(uri_fun, user, password, host, port, database, project_name, investigator_name) {

    mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "INFO")

    info <- data.frame(creation_time = Sys.time(), project = project_name, investigator = investigator_name)

    mongo_con$insert(info)

    # Verifying creation

    mongo_con <- mongo_connect(uri_fun, user, password, host, port, "admin", NA)

    databases <- mongo_con$run("{\"listDatabases\": 1}")[[1]]

    if (database %in% databases$name) {

        populate_annotations(uri_fun, user, password, host, port, database)
        populate_notes(uri_fun, user, password, host, port, database)
        populate_users(uri_fun, user, password, host, port, database)
        populate_dictionaries(uri_fun, user, password, host, port, database)
        populate_query(uri_fun, user, password, host, port, database)
        print("Database creation successful!")

    } else print("Database creation failed!")

}


#' Terminate CEDARS Project
#'
#' Everything is removed, including dictionaries. MongoDB account used must have sufficient privileges.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param fast If TRUE, delete everything without asking security questions.
#' @examples
#' \dontrun{
#' terminate_project(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @export

terminate_project <- function(uri_fun, user, password, host, port, database, fast=FALSE) {

    if (fast==FALSE) {

        first_answer <- readline(paste("Are you sure you want to proceed? All contents of database ", database, " will be irreversibly deleted. (yes/no) ",
        sep = ""))

        if (first_answer != "yes") stop("Database deletion cancelled") else {

            second_answer <- readline(paste("Are you absolutely positive you want to permanently delete ", database, "? (yes/no) ", sep = ""))

        }

    }

    if (fast==FALSE & (exists("second_answer") && second_answer != "yes")) stop("Database deletion cancelled") else {

        # Dropping all collections Since there are no collections left the database is deleted Direct deletion of
        # database is not allowed, maybe because it should be done from admin DB?

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "ANNOTATIONS")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "PATIENTS")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "NOTES")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "UMLS_MRCONSO")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "UMLS_MRREL")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "NEGEX")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "USERS")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "QUERY")
        mongo_con$drop()

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, "INFO")
        mongo_con$drop()

        # Verifying deletion

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, "admin", NA)
        databases <- mongo_con$run("{\"listDatabases\": 1}")[[1]]
        if (database %in% databases$name) print("Deletion failed!") else print("Deletion successful!")

    }

}


#' Terminate CEDARS Project - short version
#'
#' Everything is removed, including dictionaries. MongoDB account used must have sufficient privileges.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @examples
#' \dontrun{
#' terminate_project(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @keywords internal

terminate_project_new <- function(uri_fun, user, password, host, port, database) {

    first_answer <- readline(paste("Are you sure you want to proceed? All contents of database ", database, " will be irreversibly deleted. (yes/no) ",
        sep = ""))

    if (first_answer != "yes")
        stop("Database deletion cancelled") else {

        second_answer <- readline(paste("Are you absolutely positive you want to permanently delete ", database,
            "? (yes/no) ", sep = ""))

    }

    if (second_answer != "yes")
        stop("Database deletion cancelled") else {

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, database, NA)

        query <- paste("{\"dropDatabase\" : ", "\"", database, "\"}", sep = "")
        mongo_con$run(query)

        # Verifying deletion

        mongo_con <- mongo_connect(uri_fun, user, password, host, port, "admin", NA)
        databases <- mongo_con$run("{\"listDatabases\": 1}")[[1]]
        if (database %in% databases$name)
            print("Deletion failed!") else print("Deletion successful!")

    }

}


#' Download Event Data
#'
#' Downloads patient event data. Typically done after all records have been annotated and the project is complete.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @examples
#' \dontrun{
#' download_events(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA)
#' }
#' @export

download_events <- function(uri_fun, user, password, host, port, database) {

    patients_con <- mongo_connect(uri_fun, user, password, host, port, database, "PATIENTS")

    out <- patients_con$find(query = "{}", field = "{ \"_id\" : 0 , \"patient_id\" : 1 , \"reviewed\" : 1 , \"end_user\" : 1 , \"event_date\" : 1, \"time_locked\" : 1, \"pt_comments\" : 1, \"sentences\" : 1}")

    # Counting sentences

    out$event_date <- as.Date(out$event_date)

    len_out <- length(out[,1])

    out$sentences_total <- rep(NA, len_out)
    out$sentences_reviewed <- rep(NA, len_out)
    out$sentences_bef_event <- rep(NA, len_out)
    out$case_time <- rep(NA, len_out)
    out$sentence_time <- rep(NA, len_out)
    out$sentences_bef_event_list <- rep(NA, len_out)

    # Computing approximate time spent per case per user

    out <- out[order(out$end_user, out$time_locked, decreasing = TRUE, method = "radix"), ]

    if (sum(!is.na(out$time_locked))>1) {

        delta <- out$time_locked - c(out$time_locked[-1], NA)

        delta <- c(NA, delta[1:(length(delta)-1)])

        out$case_time <- delta

    }

    out$case_time[!duplicated(out$end_user)] <- NA

    for (i in 1:len_out){

        sentence_df <- out$sentences[[i]]

        if (!is.null(sentence_df)) {

            sentence_df$text_date <- as.Date(sentence_df$text_date)

            out$sentences_total[i] <- length(sentence_df[,1])
            out$sentences_reviewed[i] <- sum(sentence_df$reviewed)

            if (is.na(out$event_date[i])) {

                out$sentences_bef_event[i] <- length(sentence_df[,1])

                clean_sentences <- gsub("\\*START\\*", "", sentence_df$selected)
                clean_sentences <- gsub("\\*END\\*", "", clean_sentences)
                sent_dates <- sentence_df$text_date
                out$sentences_bef_event_list[i] <- paste(paste("\"", clean_sentences, "\"", sep=""), sent_dates, sep=": ", collapse="\r")

            } else out$sentences_bef_event[i] <- length(subset(sentence_df, text_date < out$event_date[i])[,1])

            print(paste("assessed patient record", i, "of", len_out))

        }

    }

    out$sentences_total[is.na(out$sentences_total)] <- 0
    out$sentences_reviewed[is.na(out$sentences_reviewed)] <- 0
    out$sentences_bef_event[is.na(out$sentences_bef_event)] <- 0
    out$sentences <- NULL
    out$sentence_time <- round(out$case_time/out$sentences_reviewed, digits=0)

    out <- out[order(out$patient_id, decreasing = FALSE, method = "radix"), ]

    out

}


#' Upload Event Data
#'
#' Uploads event dates for patients already in the patient list. Useful when some events have already been documented before runnning CEDARS, for example as a second-line method to catch events missed with a different approach. Only event dates for existing records are altered, missing patient records are not added!
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param patient_ids Vector of patient ID's.
#' @param event_dates Vector of clinical event dates.
#' @examples
#' \dontrun{
#' upload_events(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT', patient_ids = ids, event_dates = events)
#' }
#' @export

upload_events <- function(uri_fun, user, password, host, port, database, patient_ids, event_dates) {

    if (class(event_dates) != "Date") print("Error: event dates must be of class Date!") else {

        event_dates <- data.frame(patient_id = patient_ids, event_date = event_dates)
        event_dates$event_date <- as.character(event_dates$event_date)
        event_dates$event_date <- paste("\"", event_dates$event_date, "\"", sep = "")
        event_dates$event_date[event_dates$event_date == "\"NA\""] <- "null"

        patients_con <- mongo_connect(uri_fun, user, password, host, port, database, "PATIENTS")

        current_patients <- patients_con$find(query = "{}", field = "{ \"_id\" : 0 , \"patient_id\" : 1 }")

        current_outcomes <- merge(event_dates, current_patients, by = "patient_id", all.x = FALSE, all.y = FALSE)

        len_set <- length(current_outcomes[, 1])

        for (i in 1:len_set) {

            pt_query <- paste("{", paste("\"patient_id\" : ", current_outcomes$patient_id[i], sep = ""), "}")

            if (current_outcomes$event_date[i] == "null") {

                pt_update <- paste("{ \"$unset\" : {\"event_date\" : ", current_outcomes$event_date[i], "}}", sep = "")

            } else pt_update <- paste("{ \"$set\" : {\"event_date\" : ", current_outcomes$event_date[i], "}}", sep = "")

            patients_con$update(pt_query, pt_update)

            print(paste("Updated record", i, "of", len_set))

        }

    }

}


#' Download End User List
#'
#' Downloads list of CEDARS end users along with their passwords.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @examples
#' \dontrun{
#' end_users(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @export

end_users <- function(uri_fun, user, password, host, port, database) {

    users_con <- mongo_connect(uri_fun, user, password, host, port, database, "USERS")

    out <- users_con$find(query = "{}", fields = "{ \"user\" : 1 , \"password\" : 1 , \"_id\" : 0 }")

    out

}


#' Save Document Tags
#'
#' Save name of EHR document metadata tags. Individual notes or parts of notes can be labelled with up to 10 tags, typically the patient's name at the time, the type of note, the note section, the author, etc. Tags are not mandatory.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param tag_vect Character vector of 10 tag names.
#' @examples
#' \dontrun{
#' save_tags(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT',
#' tag_vect = c('note_type', 'note_section', 'author', 'patient_name', NA, NA, NA, NA, NA, NA))
#' }
#' @export

save_tags <- function(uri_fun, user, password, host, port, database, tag_vect) {

    tag_vect <- sanitize(tag_vect)
    tag_vect <- gsub(" ", "_", tag_vect)
    info_con <- mongo_connect(uri_fun, user, password, host, port, database, "INFO")

    info_con$update("{}", paste("{ \"$set\" : { \"tag_1\" : ", "\"", tag_vect[1], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_2\" : ", "\"", tag_vect[2], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_3\" : ", "\"", tag_vect[3], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_4\" : ", "\"", tag_vect[4], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_5\" : ", "\"", tag_vect[5], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_6\" : ", "\"", tag_vect[6], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_7\" : ", "\"", tag_vect[7], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_8\" : ", "\"", tag_vect[8], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_9\" : ", "\"", tag_vect[9], "\"", "}}", sep = ""), upsert = TRUE)
    info_con$update("{}", paste("{ \"$set\" : { \"tag_10\" : ", "\"", tag_vect[10], "\"", "}}", sep = ""), upsert = TRUE)

}
