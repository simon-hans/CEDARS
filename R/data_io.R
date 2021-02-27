

# Functions to mediate data entry and retrieval with GUI The main interface to the outside world


#' Wrap the get_data() Function
#'
#' Obtain one sentence and related info from MongoDB. Uses DB credentials pre-loaded in the main environment. For use with Shiny or REST GET (latter yet to be implemented).
#' @param database MongoDB database.
#' @param end_user CEDARS end user name..
#' @param end_user_password CEDARS end user password.
#' @param html Should output keywords/concepts be highlighted with HTML markup? Default is TRUE.
#' @param position Sentence position within the sequence of selected sentences for a given patient.
#' @param patient_id Used if a specific patient record is requested, instead of a search for next record to annotate.
#' @param ldap Is LDAP authentication being used? If so, password will not be checked and access will be granted automatically.
#' @return A list with patient-specific information and a dataframe with selected sentences along with sentence-specific data.
#' @examples
#' \dontrun{
#' get_wrapper(database = 'TEST_PROJECT', end_user = 'John', end_user_password = 'db_password_1234',
#' html = TRUE, position = NA)
#' }
#' @export

get_wrapper <- function(database, end_user, end_user_password, html = TRUE, position, patient_id = NA, ldap = FALSE) {

    get_data(cedars.env$g_mongodb_uri_fun, cedars.env$g_user, cedars.env$g_password, cedars.env$g_host, cedars.env$g_replica_set, cedars.env$g_port, database, end_user, end_user_password, html, position,
        patient_id, ldap)

}


#' Wrap the post_data() Function
#'
#' Posts results of human reviewer annotation to MongoDB. Uses DB credentials pre-loaded in the main environment. For use with Shiny or REST POST (latter yet to be implemented).
#' @param database MongoDB database.
#' @param end_user CEDARS end user name.
#' @param end_user_password CEDARS end user password.
#' @param position Sentence position within the sequence of selected sentences for a given patient.
#' @param event_date Date of clinical event as determined by human reviewer.
#' @param pt_comments Patient-specific comments from the reviewer.
#' @param ldap Is LDAP authentication being used? If so, password will not be checked and access will be granted automatically.
#' @return {
#' No return value, called to post data.
#' }
#' @examples
#' \dontrun{
#' post_wrapper(database = 'TEST_PROJECT', end_user = 'John', end_user_password = 'db_password_1234',
#' position = NA, event_date = NA, pt_comments = 'This is a comment')
#' }
#' @export

post_wrapper <- function(database, end_user, end_user_password, position, event_date, pt_comments, ldap = FALSE) {

    post_data(cedars.env$g_mongodb_uri_fun, cedars.env$g_user, cedars.env$g_password, cedars.env$g_host, cedars.env$g_replica_set, cedars.env$g_port, database, end_user, end_user_password, position, event_date,
        pt_comments, ldap)

}


#' Get one Sentence for Review
#'
#' Gets one sentence, one note and date of note for one patient. Main way for an end user to query CEDARS.
#' @param uri_fun  Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB server host.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param end_user_password CEDARS end user password.
#' @param html Should output keywords/concepts be highlighted with HTML markup? Default is TRUE.
#' @param position Sentence position within the sequence of selected sentences for a given patient.
#' @param patient_id Used if a specific patient record is requested, instead of a search for next record to annotate.
#' @param ldap Is LDAP authentication being used? If so, password will not be checked and access will be granted automatically.
#' @return A list with patient-specific information and a dataframe with selected sentences along with sentence-specific data.
#' @keywords internal

get_data <- function(uri_fun, user, password, host, replica_set, port, database, end_user, end_user_password, html = TRUE, position,
    patient_id = NA, ldap = FALSE) {

    if (ldap == TRUE | password_verification(uri_fun, user, password, host, replica_set, port, database, end_user, end_user_password) ==
        TRUE) {

        patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

        # If user clicked SEARCH patient_id will be 0, in which case we unlock user which will trigger search for next available patient
        if (!is.na(patient_id) & patient_id == 0) {

            unlock_user(uri_fun, user, password, host, replica_set, port, database, end_user)
            patient_id <- NA

        }

        # If end user specified a desired patient record, we try to commit to it, if not found or locked we return an
        # error.

        if (!is.na(patient_id)) {

            # Finding previously saved keyword/CUI search query and option for use of negation
            query_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "QUERY")
            db_results <- query_con$find("{}")
            search_query <- db_results$query[1]
            use_negation <- db_results$exclude_negated[1]
            hide_duplicates <- db_results$hide_duplicates[1]

            # Finding out if patient ID exists
            # Only numeric patient ID's are accepted, anything else will result in no patient found
            if (!is.na(as.numeric(patient_id))) patient <- patients_con$find(paste("{ \"patient_id\" : ", patient_id, "}", sep = "")) else patient <- data.frame(a=NULL, b=NULL)
            # patient <- patients_con$find(paste("{ \"patient_id\" : ", patient_id, "}", sep = ""))

            if (dim(patient)[1] > 0) {

                commit_result <- commit_patient(uri_fun, user, password, host, replica_set, port, database, end_user, search_query,
                  use_negation, hide_duplicates, patient_id)
                committed <- commit_result$committed

                if (committed == TRUE) {

                  query <- paste("{ \"end_user\" : ", "\"", end_user, "\", ", " \"locked\" : true}", sep = "")
                  selected <- patients_con$find(query)
                  sentences_df <- as.data.frame(selected$sentences[1])
                  sentences_df$text_date <- as.character(as.Date(sentences_df$text_date))
                  max_unique_id <- max(sentences_df$unique_id)

                  out <- list()
                  out$patient_id <- selected$patient_id
                  out$event_date <- selected$event_date
                  if (!is.null(out$event_date[1])) out$event_date <- strftime(out$event_date, format = "%Y-%m-%d", tz = "UTC")
                  out$max_unique_id <- max_unique_id
                  out$pt_comments <- selected$pt_comments
                  out <- append(out, as.list(sentences_df[1, ]))

                  # error_3 = patient locked by another user error_4 = no sentences to evaluate
                } else if (patient$locked[1] == TRUE)
                  out <- "error_3" else out <- "error_4"

                # error_2 = no patient found
                # prior accessed record is unlocked
            } else {

                unlock_user(uri_fun, user, password, host, replica_set, port, database, end_user)
                out <- "error_2"

                }

        } else {

            # Assess if there is already a commited, unreviewed patient for this end user
            query <- paste("{ \"end_user\" : ", "\"", end_user, "\", ", " \"locked\" : true }", sep = "")

            previously_selected <- patients_con$find(query)

            # If no commited patient, one is assigned
            if (length(previously_selected) == 0) {

                previous_exists <- FALSE

                # Finding previously saved keyword/CUI search query and option for use of negation
                query_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "QUERY")
                db_results <- query_con$find("{}")
                search_query <- db_results$query[1]
                use_negation <- db_results$exclude_negated[1]
                hide_duplicates <- db_results$hide_duplicates[1]

                # We try to commit to a patient until we find one with sentences left to evaluate
                committed <- FALSE
                no_patient_left <- FALSE
                while (committed == FALSE & no_patient_left == FALSE) {
                  commit_result <- commit_patient(uri_fun, user, password, host, replica_set, port, database, end_user, search_query,
                    use_negation, hide_duplicates)
                  committed <- commit_result$committed
                  no_patient_left <- commit_result$no_patient_left
                }

                # Assessment is repeated
                query <- paste("{ \"end_user\" : ", "\"", end_user, "\", ", " \"locked\" : true}", sep = "")
                previously_selected <- patients_con$find(query)

            } else previous_exists <- TRUE

            # If we finally have a commited patient, we go ahead with data transfer
            if (length(previously_selected) != 0) {

                sentences_df_ori <- as.data.frame(previously_selected$sentences[1])
                sentences_df_ori$text_date <- as.character(as.Date(sentences_df_ori$text_date))
                max_unique_id <- max(sentences_df_ori$unique_id)
                sentences_df <- subset(sentences_df_ori, reviewed == FALSE)
                sentences_df$reviewed <- NULL

                pre_out <- list()
                pre_out$patient_id <- previously_selected$patient_id
                pre_out$event_date <- previously_selected$event_date
                if (!is.null(pre_out$event_date[1])) pre_out$event_date <- strftime(pre_out$event_date, format = "%Y-%m-%d", tz = "UTC")
                pre_out$max_unique_id <- max_unique_id
                pre_out$pt_comments <- previously_selected$pt_comments

                # If end user already had locked record and requested position provided, corresponding sentence resulted,
                # otherwise first unreviewed sentence in (newly or not) locked record is resulted

                if (previous_exists == TRUE & !is.na(position))
                  out <- append(pre_out, as.list(subset(sentences_df_ori, unique_id == position))) else out <- append(pre_out, as.list(sentences_df[1, ]))

                if (is.na(out$selected))
                  out <- append(pre_out, as.list(sentences_df_ori[1, ]))

                # error_1 = no record left
            } else out <- "error_1"

        }

        # error_0 = end user ID/password incorrect
    } else out <- "error_0"

    if (!(out[1] %in% c("error_0", "error_1", "error_2", "error_3", "error_4")) & html == TRUE)
        out <- colorize(out)

    out

}


#' Save Reviewer Annotations
#'
#' Saves sentence review status and event time about an individual for whom the electronic health record text was reviewed. Main way for end user to enter data into CEDARS.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param end_user_password CEDARS end user password.
#' @param position Sentence position within the sequence of selected sentences for a given patient.
#' @param event_date Date of clinical event as determined by human reviewer.
#' @param pt_comments Patient-specific comments from the reviewer.
#' @param ldap Is LDAP authentication being used? If so, password will not be checked and access will be granted automatically.
#' @keywords internal

post_data <- function(uri_fun, user, password, host, replica_set, port, database, end_user, end_user_password, position, event_date,
    pt_comments, ldap = FALSE) {

    # Turning off scientific notation temporarily, otherwise JSON objects can be corrupted
    sci_opt <- getOption("scipen")
    on.exit(options(scipen = sci_opt))
    options(scipen = 999)

    if (ldap == TRUE | password_verification(uri_fun, user, password, host, replica_set, port, database, end_user, end_user_password) ==
        TRUE) {

        pt_comments <- sanitize(pt_comments)

        query_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "QUERY")
        db_results <- query_con$find("{}")
        skip_after_event <- db_results$skip_after_event[1]

        patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

        # Finding patient ID locked by user CEDARS will only post information on a record already locked by the user

        query <- paste("{ \"end_user\" : ", "\"", end_user, "\"", " , \"locked\" : true }", sep = "")
        selected_patient <- patients_con$find(query = query, fields = "{ \"patient_id\" : true , \"_id\" : false}")

        if (length(selected_patient) > 0) {

            # updating 'reviewed' status for sentences and event date, if needed

            query <- paste("{ \"end_user\" : ", "\"", end_user, "\"", " , \"locked\" : true, \"patient_id\" : ",
                selected_patient, "}", sep = "")
            data <- patients_con$find(query)
            if (!("event_date" %in% colnames(data)))
                data$event_date <- NA

            sentences <- as.data.frame(data$sentences)

            # edit 2-27
            # For consistency of data field type with results of annotations
            sentences$text_id <- as.character(sentences$text_id)
            # edit 2-27
            # sentences$patient_id <- as.double(as.character(sentences$patient_id))

            old_event_date <- as.Date(data$event_date)
            if (is.na(event_date))
                sentences$reviewed[sentences$unique_id == position] <- TRUE else {
                if (!is.na(event_date) & event_date != "DELETE")
                  sentences$reviewed[sentences$unique_id == position] <- TRUE
            }

            if (is.na(event_date))
                update_value <- paste("{\"$set\":{\"sentences\": ", jsonlite::toJSON(sentences, POSIXt = "mongo"), " , \"pt_comments\" : ",
                  "\"", pt_comments, "\" }}", sep = "") else {

                if (event_date != "DELETE")
                  update_value <- paste("{\"$set\":{\"sentences\": ", jsonlite::toJSON(sentences, POSIXt = "mongo"), ", \"event_date\" : { \"$date\" : ", as.numeric(strptime(event_date, "%Y-%m-%d", 'UTC'))*1000, " }, \"pt_comments\" : ", "\"", pt_comments, "\" }}", sep = "") else {

                        update_value <- paste("{\"$unset\":{\"event_date\" : null }}", sep = "")

                }

            }

            patients_con$update(query, update_value)


            # If there are no more sentences left to evaluate before an event, case is closed

            if (!is.na(event_date) & event_date == "DELETE")
                event_date <- NA

            event_date <- as.Date(event_date)

            if (is.na(event_date))
                event_date <- old_event_date

            sentences$text_date <- as.Date(sentences$text_date)

            # Accounting for skip-after-event-date option
            if (is.na(event_date) | skip_after_event == FALSE)
                sentences <- subset(sentences, reviewed == FALSE) else sentences <- subset(sentences, text_date < event_date & reviewed == FALSE)

            if (length(sentences[, 1]) == 0)
                complete_case(uri_fun, user, password, host, replica_set, port, database, selected_patient)

        }

    }

}


#' Verify CEDARS End User Credentials
#'
#' Verifies CEDARS end user name and password against information stored in MongoDB. Each CEDARS project is independent and occupies a different DB with its own user credentials collection.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param end_user_password CEDARS end user password.
#' @return TRUE for correct credentials, FALSE for incorrect.
#' @keywords internal

password_verification <- function(uri_fun, user, password, host, replica_set, port, database, end_user, end_user_password) {

    users_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "USERS")

    query_value <- paste("{ \"user\" : ", "\"", end_user, "\" , \"password\" : ", "\"", end_user_password, "\" }",
        sep = "")
    pw_verification <- users_con$find(query_value)

    if (length(pw_verification) > 0)
        out <- TRUE else out <- FALSE

    out

}


#' Select and Lock Patient Record
#'
#' Selects yet to be assessed patient with at least one positive sentence and locks record in DB for the CEDARS end user.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param search_query Medical corpus query containg keywords/CUI's, boolean elements and other operators ('AND', 'OR', '!', '(', or ')').
#' @param use_negation Should negated items be ignored in the keyword/concept search?
#' @param hide_duplicates Should duplicated sentences be removed for search results?
#' @param patient_id Used if a specific patient record is requested, instead of a search for next record to annotate.
#' @keywords internal

commit_patient <- function(uri_fun, user, password, host, replica_set, port, database, end_user, search_query, use_negation, hide_duplicates,
    patient_id = NA) {

    # Turning off scientific notation temporarily, otherwise JSON objects can be corrupted
    sci_opt <- getOption("scipen")
    on.exit(options(scipen = sci_opt))
    options(scipen = 999)

    committed <- TRUE

    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    sentences_result <- get_patient(uri_fun, user, password, host, replica_set, port, database, end_user, search_query, use_negation,
        hide_duplicates, patient_id)
    sentences <- sentences_result$sentences
    no_patient_left <- sentences_result$no_patient_left
    # edit 2-27
    found_patient_id <- sentences_result$patient_id

    # If there are no sentences after inital search, we keep looking.  This does not apply if patient ID for search
    # was specified.

    if (is.na(patient_id)) {

        while (if (!is.null(dim(sentences)))
            (length(sentences[, 1])) == 0 else FALSE) {

            sentences <- get_patient(uri_fun, user, password, host, replica_set, port, database, end_user, search_query, use_negation,
                hide_duplicates)

        }

    }

    if (is.null(dim(sentences)))
        committed <- FALSE

    if (is.data.frame(sentences)) {

        if (length(sentences[, 1]) > 0) {

            # edit 2-27
            retained_fields <- c("doc_id", "text_id", "paragraph_id", "sentence_id", "text_date",
                "selected", "note_text", "text_tag_1", "text_tag_2", "text_tag_3", "text_tag_4", "text_tag_5",
                "text_tag_6", "text_tag_7", "text_tag_8", "text_tag_9", "text_tag_10")
            retained_fields <- retained_fields[retained_fields %in% colnames(sentences)]

            # edit 2-27
            # new_patient_id <- sentences$patient_id[1]
            new_patient_id <- found_patient_id
            if (!("reviewed" %in% colnames(sentences)))
                sentences$reviewed <- rep(FALSE, length(sentences[, 1]))
            sentences$text_date <- as.Date(sentences$text_date)
            # edit 2-27
            sentences <- sentences[order(sentences$text_date, sentences$doc_id, sentences$text_id, sentences$paragraph_id,
                sentences$sentence_id, decreasing = FALSE, method = "radix"), ]
            sentences$unique_id <- 1:length(sentences[, 1])
            sentences <- subset(sentences, select = c("unique_id", "reviewed", retained_fields))
            sentences$selected <- as.character(sentences$selected)

            # This inserts one table in JSON format, nested into the patient record Also turns off the 'updated' marker
            sentences <- sentences[order(sentences$unique_id, decreasing = FALSE, method = "radix"), ]
            sentences_for_upload <- sentences
            sentences_for_upload$text_date <- strptime(sentences_for_upload$text_date, "%Y-%m-%d", "UTC")

            # edit 2-27
            # For consistency of data field type with results of annotations
            sentences_for_upload$text_id <- as.character(sentences_for_upload$text_id)
            # edit 2-27
            # sentences_for_upload$patient_id <- as.double(as.character(sentences_for_upload$patient_id))

            query <- paste("{ \"patient_id\" : ", new_patient_id, "}", sep = "")
            update_value <- paste("{\"$set\":{\"sentences\": ", jsonlite::toJSON(sentences_for_upload, POSIXt = "mongo"), ", \"updated\" : false }}",
                sep = "")
            patients_con$update(query, update_value)

            # If all dates for sentences left to evaluate are after previously reviewed sentences, we close the case and
            # commit to another patient.  This does not apply if patient record was subject of a direct search!

            event_date <- patients_con$find(query = query, fields = "{ \"event_date\" : 1 , \"_id\" : 0 }")$event_date

            if (is.na(patient_id)) {

                if (!is.null(event_date)) {

                  event_date <- as.Date(event_date)
                  sentences$text_date <- as.Date(sentences$text_date)
                  sentences_to_eval <- subset(sentences, text_date < event_date & reviewed == FALSE)

                } else sentences_to_eval <- subset(sentences, reviewed == FALSE)

                if (length(sentences_to_eval[, 1]) == 0) {

                  complete_case(uri_fun, user, password, host, replica_set, port, database, new_patient_id)

                  committed <- FALSE

                }

            }

        } else {

            complete_case(uri_fun, user, password, host, replica_set, port, database, patient_id)

            committed <- FALSE

        }

    }

    out <- list()
    out$committed <- committed
    out$no_patient_left <- no_patient_left

    out

}


#' Retrieve Patient Data
#'
#' Retrieves annotated electronic health record sentences for one patient. Returns basic info, along with a dataframe containing sentences and corresponding notes.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param search_query Medical corpus query containg keywords/CUI's, boolean elements and other operators ('AND', 'OR', '!', '(', or ')').
#' @param use_negation Should negated items be ignored in the keyword/concept search?
#' @param hide_duplicates Should duplicated sentences be removed for search results?
#' @param patient_id Used if a specific patient record is requested, instead of a search for next record to annotate.
#' @keywords internal

get_patient <- function(uri_fun, user, password, host, replica_set, port, database, end_user, search_query, use_negation, hide_duplicates,
    patient_id = NA) {

    selection_result <- select_patient(uri_fun, user, password, host, replica_set, port, database, end_user, patient_id)
    selected_patient <- selection_result$selected_patient
    no_patient_left <- selection_result$no_patient_left

    if (is.na(selected_patient))
        sentences <- NA else {

        annotations_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "ANNOTATIONS")
        query <- paste("{ \"patient_id\" : ", selected_patient, "}", sep = "")

        patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

        # If there are no prior sentences, we compute them; else, if NLP annotations were not updated and there are
        # already sentences, we use them If NLP annotations were updated and there are prior sentences, we get the old
        # ones and merge with the new
        patient_info <- patients_con$find(query)

        if (length(patient_info$sentences[[1]][, 1]) == 0) {

            # Ideally we would query DB directly with search terms, for now we download everything
            annotations <- annotations_con$find(query)

            # Maintaining POSIX format with UTC zone
            annotations$text_date <- strptime(strftime(annotations$text_date, tz = "UTC"), "%Y-%m-%d", 'UTC')

            parse_result <- parse_query(search_query)
            search_results <- sentence_search(parse_result, annotations, use_negation, hide_duplicates)
            sentences <- search_results$unique_sentences
            annotations <- search_results$annotations
            # If still no sentences, we close
            if (length(sentences[, 1]) > 0)
                sentences$note_text <- sapply(sentences$doc_id, aggregate_note, annotations, parse_result$cui_elements) else {
                complete_case(uri_fun, user, password, host, replica_set, port, database, selected_patient)
            }

        } else {

            sentences <- patient_info$sentences[[1]]

            if (patient_info$updated == TRUE) {

                # If there is an existing sentences dataframe it is merged into the new one, so as to keep any human-entered
                # annotations Updated sets always include the older ones, so it might have earlier versions of one sentence but
                # not vice versa, and we always keep the extra info from the update, so some identical sentences might exist
                # with different dates

                annotations <- annotations_con$find(query)

                # Maintaining POSIX format with UTC zone
                annotations$text_date <- strptime(strftime(annotations$text_date, tz = "UTC"), "%Y-%m-%d", 'UTC')

                parse_result <- parse_query(search_query)
                new_sentences <- sentence_search(parse_result, annotations, use_negation, hide_duplicates)
                # Normally we would expect to have sentences here, not sure if any is new
                if (length(new_sentences[, 1] > 0)) {

                  new_sentences$note_text <- sapply(new_sentences$doc_id, aggregate_note, annotations, parse_result$cui_elements)
                  sentences$selected <- as.character(sentences$selected)
                  new_sentences$reviewed <- NULL
                  new_sentences$unique_id <- NULL
                  new_sentences$patient_id <- NULL
                  # edit 2-27
                  sentences <- merge(new_sentences, sentences, by = c("doc_id", "text_id", "paragraph_id",
                    "sentence_id", "text_date", "selected", "note_text"), all.x = TRUE, all.y = TRUE)
                  sentences$reviewed[is.na(sentences$reviewed)] <- FALSE
                  sentences$text_tag_1[!is.na(sentences$text_tag_1.x)] <- sentences$text_tag_1.x[!is.na(sentences$text_tag_1.x)]
                  sentences$text_tag_1[!is.na(sentences$text_tag_1.y)] <- sentences$text_tag_1.y[!is.na(sentences$text_tag_1.y)]
                  sentences$text_tag_2[!is.na(sentences$text_tag_2.x)] <- sentences$text_tag_2.x[!is.na(sentences$text_tag_2.x)]
                  sentences$text_tag_2[!is.na(sentences$text_tag_2.y)] <- sentences$text_tag_2.y[!is.na(sentences$text_tag_2.y)]
                  sentences$text_tag_3[!is.na(sentences$text_tag_3.x)] <- sentences$text_tag_3.x[!is.na(sentences$text_tag_3.x)]
                  sentences$text_tag_3[!is.na(sentences$text_tag_3.y)] <- sentences$text_tag_3.y[!is.na(sentences$text_tag_3.y)]
                  sentences$text_tag_4[!is.na(sentences$text_tag_4.x)] <- sentences$text_tag_4.x[!is.na(sentences$text_tag_4.x)]
                  sentences$text_tag_4[!is.na(sentences$text_tag_4.y)] <- sentences$text_tag_4.y[!is.na(sentences$text_tag_4.y)]
                  sentences$text_tag_5[!is.na(sentences$text_tag_5.x)] <- sentences$text_tag_5.x[!is.na(sentences$text_tag_5.x)]
                  sentences$text_tag_5[!is.na(sentences$text_tag_5.y)] <- sentences$text_tag_5.y[!is.na(sentences$text_tag_5.y)]
                  sentences$text_tag_6[!is.na(sentences$text_tag_6.x)] <- sentences$text_tag_6.x[!is.na(sentences$text_tag_6.x)]
                  sentences$text_tag_6[!is.na(sentences$text_tag_6.y)] <- sentences$text_tag_6.y[!is.na(sentences$text_tag_6.y)]
                  sentences$text_tag_7[!is.na(sentences$text_tag_7.x)] <- sentences$text_tag_7.x[!is.na(sentences$text_tag_7.x)]
                  sentences$text_tag_7[!is.na(sentences$text_tag_7.y)] <- sentences$text_tag_7.y[!is.na(sentences$text_tag_7.y)]
                  sentences$text_tag_8[!is.na(sentences$text_tag_8.x)] <- sentences$text_tag_8.x[!is.na(sentences$text_tag_8.x)]
                  sentences$text_tag_8[!is.na(sentences$text_tag_8.y)] <- sentences$text_tag_8.y[!is.na(sentences$text_tag_8.y)]
                  sentences$text_tag_9[!is.na(sentences$text_tag_9.x)] <- sentences$text_tag_9.x[!is.na(sentences$text_tag_9.x)]
                  sentences$text_tag_9[!is.na(sentences$text_tag_9.y)] <- sentences$text_tag_9.y[!is.na(sentences$text_tag_9.y)]
                  sentences$text_tag_10[!is.na(sentences$text_tag_10.x)] <- sentences$text_tag_10.x[!is.na(sentences$text_tag_10.x)]
                  sentences$text_tag_10[!is.na(sentences$text_tag_10.y)] <- sentences$text_tag_10.y[!is.na(sentences$text_tag_10.y)]
                  sentences$text_date <- as.Date(sentences$text_date)
                  # edit 2-27
                  sentences <- sentences[order(sentences$text_date, sentences$doc_id, sentences$text_id,
                    sentences$paragraph_id, sentences$sentence_id, decreasing = FALSE, method = "radix"), ]
                  sentences$unique_id <- 1:length(sentences[, 1])

                }

            }

        }

    }

    out <- list()
    out$sentences <- sentences
    out$no_patient_left <- no_patient_left
    # edit 2-27
    out$patient_id <- selected_patient

    out

}


#' Aggregate Contents of a Note
#'
#' When using atomized notes, this function 'pastes' back the different sections together in the intended order. Preselected lemmas are marked, along with those for which thr CUI is
#' in the list of interest.
#' @param selected_doc_id Document ID for the note to which the sentence belongs.
#' @param annotations NLP annotations dataframe.
#' @param cui_elements Vector of UMLS concept unique identifier (CUI) elements derived from the search query.
#' @return Aggregated note in one text string.
#' @keywords internal

aggregate_note <- function(selected_doc_id, annotations, cui_elements) {

    note_df <- subset(annotations, doc_id == selected_doc_id)

    note_df <- mark(note_df, cui_elements)

    note_df$text_sequence <- as.numeric(as.character(note_df$text_sequence))

    note_df <- note_df[order(note_df$text_sequence, note_df$text_id, note_df$paragraph_id, note_df$sentence_id,
        note_df$token_id, decreasing = FALSE, method = "radix"), ]

    note_list <- split(note_df, note_df$text_sequence)

    pasted_sections <- sapply(1:length(note_list), paste_sections, note_list)

    out <- paste(pasted_sections, collapse = "\n\n")

    out

}


#' Paste Individual Note Sections
#'
#' Pastes the notes sections within a list.
#' @param section_index Index number for the section within the note.
#' @param note_list List of dataframes, each one containing NLP annotations for a note section.
#' @return Vector of pasted sections.
#' @keywords internal

paste_sections <- function(section_index, note_list) {

    note_section <- note_list[[section_index]]

    out <- paste(note_section$token, sep = " ", collapse = " ")

    out <- gsub(" \\.", "\\.", out)
    out <- gsub(" ,", ",", out)
    out <- gsub(" !", "!", out)
    out <- gsub(" \\?", "\\?", out)
    out <- gsub(" :", ":", out)
    out <- gsub(" ;", ";", out)

    out

}


#' Select Next Patient to Review
#'
#' Selects next available patient to review by CEDARS end user. If a patient record is already locked it will be used, otherwise next in line is choosen. If a specific patinet ID was requested, record will be locked and selected.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param patient_id Used if a specific patient record is requested, instead of a search for next record to annotate.
#' @return Selected patient_id.
#' @keywords internal

select_patient <- function(uri_fun, user, password, host, replica_set, port, database, end_user, patient_id = NA) {

    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    # If specific patient ID is provided, we unlock any other prior locked record and attempt to lock the desired
    # record
    if (!is.na(patient_id)) {

        unlock_user(uri_fun, user, password, host, replica_set, port, database, end_user)
        lock_records(uri_fun, user, password, host, replica_set, port, database, end_user, patient_id)
        query <- paste("{ \"end_user\" : ", "\"", end_user, "\", ", " \"locked\" : true}", sep = "")
        previously_selected <- patients_con$find(query)
        if (nrow(previously_selected) > 0)
            selected_patient <- patient_id else selected_patient <- NA
        no_patient_left <- FALSE

    } else {

        # If end user already had selected a patient but did not finish the case, the lock date will be reset and same
        # patient returned

        query <- paste("{ \"end_user\" : ", "\"", end_user, "\", ", " \"locked\" : true}", sep = "")
        update_value <- paste("{\"$set\":{\"time_locked\": {\"$date\" : ", "\"", strftime(Sys.time(), "%Y-%m-%dT%H:%M:%SZ",
            "UTC"), "\"", "}}}", sep = "")
        patients_con$update(query, update_value)
        previously_selected <- patients_con$find(query)

        if (nrow(previously_selected) > 0)
            selected_patient <- previously_selected$patient_id[1] else {

            # Unlock records as needed
            unlock_records(uri_fun, user, password, host, replica_set, port, database)

            lock_records(uri_fun, user, password, host, replica_set, port, database, end_user)

            # Find which patient was selected
            query <- paste("{ \"end_user\" : ", "\"", end_user, "\"", " , \"locked\" : true }", sep = "")
            selected_patient <- patients_con$find(query = query, fields = "{ \"patient_id\" : true , \"_id\" : false}")

        }

        if (length(selected_patient) == 0) {

            selected_patient <- NA
            no_patient_left <- TRUE

        } else no_patient_left <- FALSE

    }

    out <- list()
    out$selected_patient <- selected_patient
    out$no_patient_left <- no_patient_left

    out

}


#' Lock Record for one Patient
#'
#' Locks record for selected patient. The first available unreviewed, unlocked record is locked for the CEDARS end user.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user name.
#' @param patient_id Used if a specific patient record is requested, instead of a search for next record to annotate.
#' @keywords internal

lock_records <- function(uri_fun, user, password, host, replica_set, port, database, end_user, patient_id = NA) {

    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    if (is.na(patient_id))
        query <- paste("{ \"$and\": [ {\"$or\": [{ \"reviewed\" : false }, { \"updated\" : true }] } , {\"locked\" : false }, {\"admin_locked\" : false }] }",
            sep = "") else query <- paste("{ \"$and\": [{\"locked\" : false }, {\"admin_locked\" : false }, {\"patient_id\" : ",
        patient_id, "}] }", sep = "")

    update_value <- paste("{\"$set\" : {\"locked\": true , \"end_user\" : ", "\"", end_user, "\"", ", \"time_locked\": { \"$date\" : ",
        "\"", strftime(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", "UTC"), "\"", "}}}", sep = "")

    # mongolite will only update one record unless indicated otherwise
    patients_con$update(query, update_value, multiple = FALSE)

}


#' Lock Record for Admin Work
#' When tasks need to be performed by the CEDARS server, this functions locks one patient record at a time. The record is locked only if not already locked by a CEDARS end user. Admin lock and end user lock do not coexist.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param patient_id Patient ID being locked.
#' @keywords internal

lock_records_admin <- function(uri_fun, user, password, host, replica_set, port, database, patient_id) {

    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    query_value <- paste("{ \"locked\" : false , \"patient_id\" : ", patient_id, "}", sep = "")

    update_value <- paste("{\"$set\" : {\"admin_locked\": true }}", sep = "")

    # mongolite will only update one record unless indicated otherwise
    patients_con$update(query_value, update_value, multiple = FALSE)

    # Getting confirmation

    query_value <- paste("{ \"patient_id\" : ", patient_id, "}", sep = "")
    fields_value <- "{ \"admin_locked\" : 1 , \"_id\" : 0 }"
    result <- patients_con$find(query = query_value, field = fields_value)$admin_locked[1]

    # If the record locked for admin or patient does not exist, output is true If record exists AND could not be
    # locked for admin, output is false
    if (length(result) > 0)
        output <- (result == TRUE) else output <- TRUE

    output

}


#' Remove Admin Lock
#'
#' Once the CEDARS server has completed work on a given patient, admin lock is removed so end users can lock and access the record.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param patient_id ID of patient record being unlocked.
#' @keywords internal

unlock_records_admin <- function(uri_fun, user, password, host, replica_set, port, database, patient_id) {

    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    query_value <- paste("{ \"admin_locked\" : true, \"patient_id\" : ", patient_id, "}", sep = "")

    update_value <- paste("{\"$set\" : {\"admin_locked\": false }}")

    # mongolite will only update one record unless indicated otherwise
    patients_con$update(query_value, update_value, multiple = FALSE)

}


#' Unlock Old Locked Records
#' Occasionally a CEDARS end user will lock a patient record but not complete the annotation task. The end user lock will be respected for 24 hours after entry, however after this time period running this function will unlock the record. Called when another user sends a GET request and the server looks for a new patient to annotate. Prevents permanent locking of records by end users.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @keywords internal

unlock_records <- function(uri_fun, user, password, host, replica_set, port, database) {

    mongo_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    query <- paste("{ \"time_locked\" : { \"$lt\" : { \"$date\" : ", "\"", strftime(Sys.time() - 86400, "%Y-%m-%dT%H:%M:%SZ",
        "UTC"), "\"", "}}}", sep = "")
    mongo_con$update(query, "{\"$set\":{\"locked\": false}}", multiple = TRUE)

}


#' Unlock User-Specific Records
#' Removes any pending lock(s) for a specific user. Normally there should not be more than one record locked per user at any given time, but if there were more than one, i.e. DB corruption, all locks would be lifted at once.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param end_user CEDARS end user.
#' @return {
#' No return value, unlocks alls records for a specific user in the database.
#' }
#' @examples
#' \dontrun{
#' unlock_user(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port= NA, database = 'TEST_PROJECT', end_user = 'Mike')
#' }
#' @export

unlock_user <- function(uri_fun, user, password, host, replica_set, port, database, end_user) {

    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    query <- paste("{ \"end_user\" : ", "\"", end_user, "\" }", sep = "")
    patients_con$update(query, "{\"$set\":{\"locked\": false}}", multiple = TRUE)

}

#' Mark a Case as Completed
#'
#' Once all sentences before a recorded event have been annotated by the end user, this functions marks patient record as 'reviewed'.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param selected_patient Selected patient.
#' @keywords internal

complete_case <- function(uri_fun, user, password, host, replica_set, port, database, selected_patient) {

    mongo_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    query <- paste("{ \"patient_id\" : ", selected_patient, "}", sep = "")

    update_value <- paste("{\"$set\":{\"locked\": false , \"reviewed\" : true , \"updated\": false }}", sep = "")

    mongo_con$update(query, update_value)

}


