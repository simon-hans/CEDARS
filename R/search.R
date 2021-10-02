

#' Functions which mediate keyword/CUI search on NLP-annotated corpora
#'


#' Execute Search on EHR Notes for One Patient
#'
#' Performs search for queries based on lemmas (i.e. keywords) and UMLS CUI's
#' @param parse_result Results of search query parsing.
#' @param annotations Patient-specific NLP annotations.
#' @param use_negation Should negated items be ignored in the keyword/concept search?
#' @param hide_duplicates Should duplicated sentences be removed for search results?
#' @return All sentences matching the query.
#' @keywords internal

sentence_search <- function(parse_result, annotations, use_negation, hide_duplicates) {

    if (length(annotations[,1]) == 0) {

        # If there are no annotations, we output an empty list

        output <- list()
        output$annotations <- annotations
        output$unique_sentences <- data.frame(patient_id = numeric())

    } else {

        retained_fields <- c("patient_id", "doc_id", "text_id", "paragraph_id", "sentence_id", "text_date", "text_sequence",
            "text_tag_1", "text_tag_2", "text_tag_3", "text_tag_4", "text_tag_5", "text_tag_6", "text_tag_7", "text_tag_8",
            "text_tag_9", "text_tag_10")
        retained_fields <- retained_fields[retained_fields %in% colnames(annotations)]

        query_vect <- parse_result$query_vect
        operator_mask <- parse_result$operator_mask
        cui_mask <- parse_result$cui_mask
        keyword_mask <- parse_result$keyword_mask

        keyword_elements <- parse_result$keyword_elements
        annotations <- lemma_match(annotations, keyword_elements)
        if (use_negation == TRUE & "negated" %in% colnames(annotations))
            keyword_sentences <- unique(subset(annotations, lemma_match == TRUE & negated == FALSE, select = retained_fields)) else keyword_sentences <- unique(subset(annotations, lemma_match == TRUE, select = retained_fields))

        cui_elements <- parse_result$cui_elements

        if ("umls_CUI" %in% colnames(annotations)) {

            if (use_negation == TRUE & "negated" %in% colnames(annotations))
                cui_sentences <- unique(subset(annotations, umls_CUI %in% cui_elements & negated == FALSE, select = retained_fields)) else cui_sentences <- unique(subset(annotations, umls_CUI %in% cui_elements, select = retained_fields))

        }

        # Getting unique sentences

        if ("umls_CUI" %in% colnames(annotations))
            unique_sentences <- unique(rbind(keyword_sentences, cui_sentences)) else unique_sentences <- keyword_sentences

        if (length(unique_sentences[, 1]) > 0) {

            unique_sentences$unique_id <- 1:length(unique_sentences[, 1])
            unique_sentences$selected <- NA

            # Iterating

            unique_sentences$selected <- sapply(unique_sentences$unique_id, sentence_eval, unique_sentences, annotations,
                query_vect, keyword_mask, keyword_elements, cui_mask, cui_elements, use_negation)

            unique_sentences <- unique_sentences[!is.na(unique_sentences$selected), ]

            unique_sentences <- unique_sentences[order(unique_sentences$text_date, decreasing = FALSE, method = "radix"),]

            # Only first mention of any given unique sentence
            if (hide_duplicates == TRUE)
                unique_sentences <- unique_sentences[!duplicated(unique_sentences$selected), ]

            unique_sentences <- subset(unique_sentences, select = c(retained_fields, "selected"))

        }

        output <- list()
        output$annotations <- annotations
        output$unique_sentences <- unique_sentences

    }

    output

}


#' Match Lemmas to Regex Keywords
#'
#' Matches lemmas in NLP annotations to keywords, considering Regex syntax.
#' @param annotations Patient-specific NLP annotations.
#' @param keyword_elements Keywords with Regex syntax.
#' @return Annotations dataframe with one extra column.
#' @keywords internal

lemma_match <- function(annotations, keyword_elements) {

    result <- as.vector(apply(sapply(keyword_elements, grepl, annotations$lemma, ignore.case = TRUE), 1, any))

    annotations$lemma_match <- result

    annotations

}


#' Evaluate One Sentence
#'
#' Assesses if one sentence matches the search query and marks positive tokens/concept unique identifiers (CUI's).
#' @param unique_id Sentence ID, i.e. row number in annotations dataframe.
#' @param unique_sentences Dataframe of unique sentences for the patient.
#' @param annotations NLP annotation dataframe.
#' @param query_vect Vector of search query components.
#' @param keyword_mask Query vector with only keywords.
#' @param keyword_elements Vector of search query keywords.
#' @param cui_mask Query vector with only CUI's.
#' @param cui_elements Vector of search query CUI's.
#' @param use_negation Should negated items be ignored in the keyword/concept search?
#' @return If sentence matches query, returns sentences with marked tokens/CUI's, otherwise NA.
#' @keywords internal

sentence_eval <- function(unique_id, unique_sentences, annotations, query_vect, keyword_mask, keyword_elements,
    cui_mask, cui_elements, use_negation) {

    selected_text_id <- unique_sentences$text_id[unique_sentences$unique_id == unique_id]
    selected_paragraph_id <- unique_sentences$paragraph_id[unique_sentences$unique_id == unique_id]
    selected_sentence_id <- unique_sentences$sentence_id[unique_sentences$unique_id == unique_id]

    if (use_negation == TRUE & "negated" %in% colnames(annotations))
        selected_annotations <- subset(annotations, text_id == selected_text_id & paragraph_id == selected_paragraph_id &
            sentence_id == selected_sentence_id & negated == FALSE) else selected_annotations <- subset(annotations, text_id == selected_text_id & paragraph_id == selected_paragraph_id &
        sentence_id == selected_sentence_id)

    query_construct <- query_vect
    # query_construct[keyword_mask] <- keyword_elements %in% selected_annotations$lemma

    if (length(selected_annotations[, 1]) > 1) {

        query_construct[keyword_mask] <- as.vector(apply(sapply(keyword_elements, grepl, selected_annotations$lemma, ignore.case = TRUE),
            2, any))

    } else query_construct[keyword_mask] <- as.vector(sapply(keyword_elements, grepl, selected_annotations$lemma, ignore.case = TRUE))

    # If there is no CUI data then any CUI invoked in the search is considered absent
    if ("umls_CUI" %in% colnames(annotations))
        query_construct[cui_mask] <- cui_elements %in% selected_annotations$umls_CUI else query_construct[cui_mask] <- FALSE

    query_logical <- paste(query_construct, sep = "", collapse = " ")
    query_logical <- gsub("AND", "&", query_logical)
    query_logical <- gsub("OR", "|", query_logical)
    query_logical <- gsub("NOT", "!", query_logical)
    out_logical <- eval(parse(text = query_logical))

    if (out_logical == TRUE) {

        out <- subset(annotations, text_id == selected_text_id & paragraph_id == selected_paragraph_id & sentence_id ==
            selected_sentence_id)

        out <- mark(out, cui_elements)

        out <- out[order(out$token_id, decreasing = FALSE, method = "radix"), ]

        out <- paste(out$token, sep = " ", collapse = " ")

        out <- gsub(" \\.", "\\.", out)
        out <- gsub(" ,", ",", out)
        out <- gsub(" !", "!", out)
        out <- gsub(" \\?", "\\?", out)
        out <- gsub(" :", ":", out)
        out <- gsub(" ;", ";", out)

    } else out <- NA

    out

}


#' Mark Tokens
#'
#' Marks tokens corresponding to keywords/CUI's so that they can be highlighted later.
#' @param annotations NLP annotation dataframe.
#' @param cui_elements Vector of search query CUI's.
#' @return Full sentence with marked tokens.
#' @keywords internal

mark <- function(annotations, cui_elements) {

    annotations$temp_unique <- 1:length(annotations[, 1])

    annotations$token[annotations$lemma_match == TRUE] <- paste("*START*", annotations$token[annotations$lemma_match ==
        TRUE], "*END*", sep = "")

    if ("umls_CUI" %in% colnames(annotations)) {

        cui_df <- subset(annotations, umls_CUI %in% cui_elements, select = c("text_id", "start", "umls_end"))
        annos_df <- subset(annotations, select = c("temp_unique", "text_id", "start", "end"))
        annos_df <- merge(cui_df, annos_df, by = "text_id", all.y = FALSE)
        annos_df <- subset(annos_df, start.x <= start.y & umls_end >= end)
        annotations$token[annotations$temp_unique %in% annos_df$temp_unique] <- paste("*START*", annotations$token[annotations$temp_unique %in%
            annos_df$temp_unique], "*END*", sep = "")

    }

    annotations

}


#' Parse a Search Query
#'
#' Extracts pertinent elements from search query.
#' @param search_query Medical corpus query containg keywords/CUI's, boolean elements and other operators ('AND', 'OR', '!', '(', or ')').
#' @return List containing the query vector, operator mask, CUI mask, keyword mask, keyword elements and CUI elements.
#' @keywords internal

parse_query <- function(search_query) {

    query_vect <- unlist(strsplit(search_query, " "))

    operator_mask <- query_vect %in% c("AND", "OR", "(", ")", "NOT")
    cui_mask <- grepl("C\\d{7}$", query_vect, perl = TRUE)
    keyword_mask <- !(operator_mask | cui_mask)

    keyword_elements <- query_vect[keyword_mask]
    keyword_elements <- format_keywords(keyword_elements)

    cui_elements <- query_vect[cui_mask]

    out <- list()
    out$query_vect <- query_vect
    out$operator_mask <- operator_mask
    out$cui_mask <- cui_mask
    out$keyword_mask <- keyword_mask
    out$keyword_elements <- keyword_elements
    out$cui_elements <- cui_elements

    out

}


#' Execute Search on a Set of Records
#'
#' Batches a keyword/CUI search for a cohort of patients. Useful to speed up the process by end users, since search results will be pre-populated. Locks each record before proceeding with search on existing NLP annotations. Patient records with no matching sentences or a known event date at or before the earliest matching sentence will be marked as reviewed. The latter assumes the query orders to skip sentences after events.
#' @param patient_vect Vector of patient ID's. Default is NA, in which case all unlocked records will be searched.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @return {
#' No return value, called to execute a query in the database.
#' }
#' @examples
#' \dontrun{
#' pre_search(patient_vect = NA, uri_fun = mongo_uri_standard, user = 'John',
#' password = 'db_password_1234', host = 'server1234', database = 'TEST_PROJECT')
#' }
#' @export

pre_search <- function(patient_vect = NA, uri_fun, user, password, host, replica_set, port, database) {

    query_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "QUERY")
    db_results <- query_con$find("{}")
    search_query <- db_results$query[1]
    use_negation <- db_results$exclude_negated[1]
    hide_duplicates <- db_results$hide_duplicates[1]

    # Getting tag query, if it exists
    tag_query <- db_results$tag_query
    if (!is.null(tag_query$exact)) {

        tag_query <- query_con$iterate('{}', '{ \"tag_query\" : 1 , \"_id\" : 0 }')
        tag_query <- jsonlite::fromJSON(tag_query$json())[[1]]
        nlp_apply <- tag_query$nlp_apply
        if (nlp_apply == FALSE) print("Using tag metadata filter for pre-search!") else tag_query <- NA

    } else tag_query <- NA

    parse_result <- parse_query(search_query)

    # Making sure all patients with annotations are considered
    patient_roster_update(uri_fun, user, password, host, replica_set, port, database)

    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")
    annotations_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "ANNOTATIONS")

    # We find which patients do not have a completed search yet and have not been reviewed either
    pending_patients <- patients_con$find("{ \"sentences\" : null , \"reviewed\" : false }", "{ \"_id\" : 0, \"patient_id\" : 1}")$patient_id

    # If no patient vector is provided, we use all pending patients
    if (is.na(patient_vect[1]))
        patient_vect <- pending_patients else patient_vect <- patient_vect[patient_vect %in% pending_patients]

    length_list <- length(patient_vect)

    cat("Performing searches!\n\n")

    j <- 0

    for (i in 1:length_list) {
        # Records for this patient undergo admin lock during the upload But first, old user-locked records are unlocked
        # A record is considered open for annotation if admin lock was successful
        unlock_records(uri_fun, user, password, host, replica_set, port, database)
        open <- lock_records_admin(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])
        if (open == TRUE) {

            query <- paste("{ \"patient_id\" : ", patient_vect[i], "}", sep = "")

            annotations <- annotations_con$find(query)

            if (nrow(annotations)>0){

                # Maintaining POSIX format with UTC zone
                annotations$text_date <- strptime(strftime(annotations$text_date, tz = "UTC"), "%Y-%m-%d", 'UTC')

                # Filtering based on text metadata, if indicated
                if (!is.na(tag_query[1])) annotations <- tag_filter(annotations, tag_query)

                # Getting event date
                patient_info <- patients_con$find(query)
                if (!is.null(patient_info$event_date)) event_date <- as.Date(patient_info$event_date) else event_date <- NA

                sentences <- sentence_search(parse_result, annotations, use_negation, hide_duplicates)

                unique_sentences <- sentences$unique_sentences

                if (length(unique_sentences[, 1]) > 0) {

                    # edit 2-27
                    # Removed patient_id from desired fields
                    retained_fields <- c("doc_id", "text_id", "paragraph_id", "sentence_id", "text_date",
                        "selected", "note_text", "text_tag_1", "text_tag_2", "text_tag_3", "text_tag_4", "text_tag_5",
                        "text_tag_6", "text_tag_7", "text_tag_8", "text_tag_9", "text_tag_10")
                    retained_fields <- retained_fields[retained_fields %in% colnames(unique_sentences)]

                    # edit 2-27
                    unique_sentences <- unique_sentences[order(unique_sentences$text_date, unique_sentences$doc_id,
                        unique_sentences$text_id, unique_sentences$paragraph_id, unique_sentences$sentence_id,
                        decreasing = FALSE, method = "radix"), ]
                    unique_sentences$unique_id <- 1:length(unique_sentences[, 1])
                    unique_sentences$reviewed <- rep(FALSE, length(unique_sentences[, 1]))
                    unique_sentences <- subset(unique_sentences, select = c("unique_id", "reviewed", retained_fields))

                    unique_sentences$note_text <- sapply(unique_sentences$doc_id, aggregate_note, sentences$annotations, parse_result$cui_elements)

                    # edit 2-27
                    # For consistency of data field type with results of annotations
                    unique_sentences$text_id <- as.character(unique_sentences$text_id)
                    # edit 2-27
                    # unique_sentences$patient_id <- as.double(as.character(unique_sentences$patient_id))

                    update_value <- paste("{\"$set\":{\"sentences\": ", jsonlite::toJSON(unique_sentences, POSIXt = "mongo"), ", \"updated\" : false }}",
                        sep = "")

                    patients_con$update(query, update_value)

                    # If there is an event date and it is at or before all sentences, we mark case as reviewed
                    # This is enforced only if the query orders to skip sentences after events
                    if (db_results$skip_after_event == TRUE & !is.na(event_date) & event_date <= min(as.Date(unique_sentences$text_date))) complete_case(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])

                } else complete_case(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])

            } else complete_case(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])

        } else j <- j + 1

        unlock_records_admin(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])

        cat(paste(c("Completed search for patient ID ", patient_vect[i], ", # ", i, " of ", length_list, ".\n"),
            sep = "", collapse = ""))

    }

    cat("\n")

    print(paste("There were ", j, " locked cases encountered.", sep = ""))

}
