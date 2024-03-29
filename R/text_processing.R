

#' Functions to process documents with NLP engine


#' Process a Document
#'
#' Processes one EHR document with NLP pipeline and applies NegEx.
#' @param text_df Dataframe of 1 row, containing all text metadata, including: text_id, text_date, text_sequence, doc_section_name, doc_id, text_tag_1, text_tag_2, text_tag_3, text_tag_4, text_tag_5, text_tag_6, text_tag_7, text_tag_8, text_tag_9 and text_tag_10.
#' @param text_format Text format.
#' @param nlp_engine NLP engine, UDPipe only for now.
#' @param negex_simp Simplified negex.
#' @param negex_depth Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
#' @param single_core_model NLP model in case parallel processing is not used.
#' @return NLP annotations dataframe.
#' @keywords internal

document_processor <- function(text_df, text_format, nlp_engine, negex_simp, negex_depth, single_core_model = NA) {

    if (!is.na(single_core_model[1]))
        nlp_model <- single_core_model

    text <- as.character(text_df$text[1])
    text_id <- text_df$text_id[1]
    if ("text_date" %in% colnames(text_df))
        text_date <- text_df$text_date[1] else text_date <- NA
    if ("text_sequence" %in% colnames(text_df))
        text_sequence <- text_df$text_sequence[1] else text_sequence <- NA
    if ("doc_section_name" %in% colnames(text_df))
        doc_section_name <- text_df$doc_section_name[1] else doc_section_name <- NA
    if ("doc_id" %in% colnames(text_df))
        doc_id <- text_df$doc_id[1] else doc_id <- NA
    if ("text_tag_1" %in% colnames(text_df))
        text_tag_1 <- text_df$text_tag_1[1] else text_tag_1 <- NA
    if ("text_tag_2" %in% colnames(text_df))
        text_tag_2 <- text_df$text_tag_2[1] else text_tag_2 <- NA
    if ("text_tag_3" %in% colnames(text_df))
        text_tag_3 <- text_df$text_tag_3[1] else text_tag_3 <- NA
    if ("text_tag_4" %in% colnames(text_df))
        text_tag_4 <- text_df$text_tag_4[1] else text_tag_4 <- NA
    if ("text_tag_5" %in% colnames(text_df))
        text_tag_5 <- text_df$text_tag_5[1] else text_tag_5 <- NA
    if ("text_tag_6" %in% colnames(text_df))
        text_tag_6 <- text_df$text_tag_6[1] else text_tag_6 <- NA
    if ("text_tag_7" %in% colnames(text_df))
        text_tag_7 <- text_df$text_tag_7[1] else text_tag_7 <- NA
    if ("text_tag_8" %in% colnames(text_df))
        text_tag_8 <- text_df$text_tag_8[1] else text_tag_8 <- NA
    if ("text_tag_9" %in% colnames(text_df))
        text_tag_9 <- text_df$text_tag_9[1] else text_tag_9 <- NA
    if ("text_tag_10" %in% colnames(text_df))
        text_tag_10 <- text_df$text_tag_10[1] else text_tag_10 <- NA

    # Right now we only offer udpipe
    if (!(nlp_engine %in% c("udpipe")))
        (return(print("No available NLP engine selected.")))

    # Running the NLP engine chosen by the user
    if (nlp_engine == "udpipe") {
        annotated_text <- udpipe::udpipe_annotate(nlp_model, text, doc_id = text_id, tokenizer = "tokenizer", tagger = "default",
            parser = "default")
        annotated_text <- as.data.frame(annotated_text, detailed = TRUE)
    }

    # We standardize the output matrix, as it varies by NLP software
    annotated_text <- standardize_nlp(annotated_text, nlp_engine)

    # Entering NegEx annotations
    if (negex_depth > 0)
        annotated_text <- negex_processor(annotated_text, negex_simp, negex_depth)

    # Adding back tags
    nr = nrow(annotated_text)
    tags <- data.frame("text_date" = rep(text_date, nr),  "text_sequence" = rep(text_sequence, nr),
                       "doc_section_name" = rep(doc_section_name, nr), "doc_id" = rep(doc_id, nr),
                       "text_tag_1" = rep(text_tag_1, nr), "text_tag_2" = rep(text_tag_2, nr),
                       "text_tag_3" = rep(text_tag_3, nr), "text_tag_4" = rep(text_tag_4, nr),
                       "text_tag_5" = rep(text_tag_5, nr), "text_tag_6" = rep(text_tag_6, nr),
                       "text_tag_7" = rep(text_tag_7, nr), "text_tag_8" = rep(text_tag_8, nr),
                       "text_tag_9" = rep(text_tag_9, nr), "text_tag_10" = rep(text_tag_10, nr),
                       stringsAsFactors = FALSE)

    annotated_text <- cbind(annotated_text, tags)

    annotated_text

}


#' Process All Documents for One Patient
#'
#' Performs NLP annotations on all documents using previously established cluster, including NegEx and UMLS CUI tags.
#' @param select_cores Desired number of cores.
#' @param cl Computing cluster.
#' @param sub_corpus Data frame of text to annotate.
#' @param text_format Text format.
#' @param nlp_engine NLP engine, UDPipe only for now.
#' @param negex_simp Simplifed negex.
#' @param umls_selected Processed UMLS table.
#' @param max_n_grams_length Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If ) is chosen, UMLS CUI tags will not be provided.
#' @param negex_depth Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
#' @param single_core_model NLP model in case parallel processing is not used.
#' @return NLP annotations dataframe.
#' @keywords internal

patient_processor_par <- function(select_cores, cl, sub_corpus, text_format, nlp_engine, negex_simp, umls_selected, max_n_grams_length,
                                  negex_depth, single_core_model) {

  sub_corpus_short <- subset(sub_corpus, select = c("text", "text_id", "text_date", "text_sequence", "doc_section_name",
                                                    "doc_id", "text_tag_1", "text_tag_2", "text_tag_3", "text_tag_4", "text_tag_5", "text_tag_6", "text_tag_7",
                                                    "text_tag_8", "text_tag_9", "text_tag_10"))

  # Convert text to ASCII
  sub_corpus_short$text <- sanitize(sub_corpus_short$text)

  # Only keeping rows with at least one non-white space character
  sub_corpus_short <- sub_corpus_short[grepl("\\S+", sub_corpus_short$text), ]

  if (length(sub_corpus_short[, 1]) > 0) {

    sub_corpus_short <- split.data.frame(sub_corpus_short, row(sub_corpus_short)[, 1])

    if (!is.na(cl[1])) {

      annotations <- parallel::parLapply(cl, sub_corpus_short, document_processor, text_format, nlp_engine, negex_simp, negex_depth)

    } else if (select_cores !=1 & Sys.info()["sysname"] == "Linux") {

      annotations <- parallel::mclapply(sub_corpus_short, document_processor, text_format, nlp_engine, negex_simp, negex_depth, single_core_model, mc.cores = select_cores)

    } else {

      annotations <- lapply(sub_corpus_short, document_processor, text_format, nlp_engine, negex_simp, negex_depth, single_core_model)

    }

    # output <- do.call("rbind", annotations)
    output <- data.table::rbindlist(annotations, use.names = TRUE)

    # Inserting UMLS tags
    if (max_n_grams_length > 0 & !is.na(umls_selected))
      output <- umls_processor(output, umls_selected, max_n_grams_length)

    output <- output[order(output$doc_id, output$paragraph_id, output$sentence_id, output$token_id, decreasing = FALSE,
                           method = "radix"), ]

  } else output <- NA

  output

}


#' Batch NLP Annotations for a Cohort
#'
#' NLP annotates documents for a cohort of patients, in parallel. Locks each record before proceeding with NLP annotations.
#' @param patient_vect Vector of patient ID's.
#' @param text_format Text format.
#' @param nlp_engine NLP engine, UDPipe only for now.
#' @param URL UDPipe model URL.
#' @param negex_simp Simplifed negex.
#' @param umls_selected Processed UMLS table.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param max_n_grams_length Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If ) is chosen, UMLS CUI tags will not be provided.
#' @param negex_depth Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
#' @param select_cores How many CPU cores should be used for parallel processing? Max allowed is total number of cores minus one. If 1 is entered, parallel processing will not be used.
#' @param tag_query If desired, "include" and "exclude" criteria used to filter documents based on metadata tags.
#' @param unique_missing_texts List of missing text_id's, one vector for each patient.
#' @param date_min Minimum date filter.
#' @param date_max Maximum date filter.
#' @keywords internal

batch_processor_db <- function(patient_vect, text_format, nlp_engine, URL, negex_simp, umls_selected, uri_fun,
    user, password, host, replica_set, port, database, max_n_grams_length, negex_depth, select_cores, tag_query = NA,
    unique_missing_texts = NA, date_min, date_max) {

    # print('Loading NLP model...') nlp_model <- udpipe::udpipe_load_model(URL)

    length_list <- length(patient_vect)

    # We create a computing cluster if OS is Windows
    # If requested # of cores > available minus one, will use available minus one
    # If no specified # of desired cores, will use available minus one

    no_cores <- parallel::detectCores() - 1

    if (is.na(select_cores) | select_cores > no_cores | select_cores < 1) select_cores <- no_cores

    if (select_cores != 1 & Sys.info()["sysname"] == "Windows") {

      cat("Initializing cluster...\n\n")
      cl <- parallel::makeCluster(no_cores)
      parallel::clusterExport(cl, c("sanitize", "standardize_nlp", "negation_tagger", "negex_token_tagger", "id_expander",
                                    "negex_processor", "negex_simp", "negex_depth", "URL"), envir = environment())
      parallel::clusterEvalQ(cl, {nlp_model <- udpipe::udpipe_load_model(URL)})
      single_core_model <- NA

      } else {

        cl <- NA
        single_core_model <- udpipe::udpipe_load_model(URL)

      }

    cat("Performing annotations!\n\n")

    j <- 0

    for (i in 1:length_list) {
        # Records for this patient undergo admin lock during the upload But first, old user-locked records are unlocked
        # A record is considered open for annotation if 1) the patient is not in the roster yet or 2) admin lock was
        # successful
        unlock_records(uri_fun, user, password, host, replica_set, port, database)
        open <- lock_records_admin(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])
        if (open == TRUE) {

            sub_corpus <- db_download(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])
            # Applying metadata tag filter
            if (is.list(tag_query) & length(sub_corpus[, 1]) > 0) sub_corpus <- tag_filter(sub_corpus, tag_query, date_min, date_max)

            if (!is.na(unique_missing_texts[1])) sub_corpus <- subset(sub_corpus, text_id %in% unique_missing_texts[[i]])

            sub_corpus <- sub_corpus[order(sub_corpus$text_date, sub_corpus$doc_id, sub_corpus$text_id, decreasing = c(FALSE, FALSE, FALSE), method = "radix"),]

            if (length(sub_corpus[, 1]) > 0) {

                print(paste("Annotating", length(sub_corpus[, 1]), "documents..."))

                # Convert dates to character, at least this is required for UDPipe
                sub_corpus$text_date <- as.character(sub_corpus$text_date)

                annotations <- patient_processor_par(select_cores, cl, sub_corpus, text_format, nlp_engine, negex_simp, umls_selected,
                  max_n_grams_length, negex_depth, single_core_model)

                if (is.data.frame(annotations)) {

                    # Converting dates back to date
                    annotations$text_date <- as.Date(annotations$text_date)

                    row.names(annotations) <- NULL
                    db_upload(uri_fun, user, password, host, replica_set, port, database, patient_vect[i], annotations)

                }

            }

            unlock_records_admin(uri_fun, user, password, host, replica_set, port, database, patient_vect[i])

            cat(paste(c("Completed annotations for patient ID ", patient_vect[i], ", # ", i, " of ", length_list,
                ".\n"), sep = "", collapse = ""))

        } else j <- j + 1

    }

    cat("\n")

    if (!is.na(cl[1]))
        parallel::stopCluster(cl)

    print(paste("There were ", j, " locked cases encountered.", sep = ""))

}


#' Process NLP Annotations on the Current Patient Cohort
#'
#' Accepts a list of patient ID's or alternatively can perform NLP annotations on all available patients in the database.
#' @param patient_vect Vector of patient ID's. Default is NA, in which case all available patient records will undergo NLP annotation.
#' @param text_format Text format for NLP engine.
#' @param nlp_engine Which NLP engine should be used? UDPipe is the only one supported for now.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param max_n_grams_length Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If 0 is chosen, UMLS CUI tags will not be provided.
#' @param negex_depth Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
#' @param select_cores How many CPU cores should be used for parallel processing? Max allowed is total number of cores minus one. If 1 is entered, parallel processing will not be used.
#' @param URL UDPipe model URL.
#' @return {
#' Confirmation that requested operation was completed, or error message if attempt failed.
#' }
#' @examples
#' \dontrun{
#' automatic_NLP_processor(patient_vect = NA, text_format = 'latin1', nlp_engine = 'udpipe',
#' URL = 'models/english-ewt-ud-2.4-190531.udpipe', uri_fun = mongo_uri_standard, user = 'John',
#' password = 'db_password_1234', host = 'server1234', port = NA, database = 'TEST_PROJECT',
#' max_n_grams_length = 7, negex_depth = 6, select_cores = 1)
#' }
#' @export

automatic_NLP_processor <- function(patient_vect = NA, text_format = "latin1", nlp_engine = "udpipe", uri_fun = mongo_uri_standard,
    user, password, host, replica_set, port, database, max_n_grams_length = 7, negex_depth = 6, select_cores = NA, URL = NA) {

    print("Updating patient roster...")
    patient_roster_update(uri_fun, user, password, host, replica_set, port, database, patient_vect)

    # Finding NLP model to use, if not specified
    URL <- find_model(URL)

    annotations_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "ANNOTATIONS")
    notes_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "NOTES")
    patients_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "PATIENTS")

    # Getting tag query, if it exists we determine if it should apply to NLP pipeline
    query_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "QUERY")
    tag_query <- query_con$find('{}', '{ \"tag_query\" : 1 , \"_id\" : 0 }')

    # Getting min/max date filters
    db_results <- query_con$find("{}")
    date_min <- db_results$date_min
    date_max <- db_results$date_max
    if (!is.na(date_min)) date_min <- strptime(strftime(date_min, tz = "UTC"), "%Y-%m-%d", 'UTC')
    if (!is.na(date_max)) date_max <- strptime(strftime(date_max, tz = "UTC"), "%Y-%m-%d", 'UTC')

    if (!is.null(tag_query$tag_query$exact)) {

        tag_query <- query_con$iterate('{}', '{ \"tag_query\" : 1 , \"_id\" : 0 }')
        tag_query <- jsonlite::fromJSON(tag_query$json())[[1]]
        nlp_apply <- tag_query$nlp_apply
        if (nlp_apply == TRUE) print("Using tag metadata filter for NLP. Only selected documents will be processed!") else tag_query <- NA

    } else tag_query <- NA

    print("Downloading dictionaries...")

    # We do not use NeGex if it has not been installed or if NegEx depth is < 1
    negex_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "NEGEX")
    if (negex_con$count() == 0)
        negex_depth <- 0
    if (negex_depth > 0)
        negex_simp <- negex_con$find("{}") else negex_simp <- NA

    # We do not use UMLS if it has not been installed or if max ngram length is < 1
    umls_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "UMLS_MRCONSO")
    if (umls_con$count() == 0)
        max_n_grams_length <- 0
    if (max_n_grams_length > 0)
        umls_selected <- umls_con$find("{}") else umls_selected <- NA

    print("Finding all patients with notes...")

    # Does not work in current format, results in time-out with very large notes collections
    # all_patients <- notes_con$aggregate('[{ \"$group\" : {\"_id\" : \"$patient_id\"} }]', options = '{"allowDiskUse":true}')
    # all_patients <- all_patients[,1]

    patients_it <- notes_con$iterate('{}', '{ \"patient_id\" : 1 , \"_id\" : 0 }')
    all_patients <- c()

    try(while(!is.null(patients_dl <- patients_it$batch(1000000))){

        all_patients <- unique(c(all_patients, unlist(patients_dl)))
        print(paste("Found", length(all_patients), "unique values..."))

    }, silent = TRUE)

    if (!is.na(patient_vect[1])) all_patients <- all_patients[all_patients %in% patient_vect]
    l_all_patients <- length(all_patients)

    if (l_all_patients>0){

        all_patients <- all_patients[order(all_patients, decreasing = FALSE, method = "radix")]

        print("Finding patients with missing annotations...")

        unique_missing_patients <- list()
        unique_missing_texts <- list()

        for (i in 1:l_all_patients){

            print(paste("checking patient #", i, "of", l_all_patients))

            # All doc_id's available for annotation
            # all_notes <- notes_con$find(query = paste("{\"patient_id\" :", all_patients[i] , "}"), fields = "{ \"doc_id\" : 1, \"_id\" : 0 }")
            all_notes <- notes_con$find(query = paste("{\"patient_id\" :", all_patients[i] , "}"), fields = "{ \"text_id\" : 1, \"_id\" : 0 }")

            # all_notes <- unique(all_notes$doc_id)
            all_notes <- unique(all_notes$text_id)

            # All text_id's with an existing annotation
            # all_annotated <- annotations_con$find(query = paste("{\"patient_id\" :", all_patients[i] , "}"), fields = "{ \"doc_id\" : 1, \"_id\" : 0 }")
            all_annotated <- annotations_con$find(query = paste("{\"patient_id\" :", all_patients[i] , "}"), fields = "{ \"text_id\" : 1, \"_id\" : 0 }")

            # all_annotated <- unique(all_annotated$doc_id)
            all_annotated <- unique(all_annotated$text_id)

            missing_text <- all_notes[!(all_notes %in% all_annotated)]

            if (length(missing_text) > 0) {

                unique_missing_patients[[i]] <- all_patients[i]
                unique_missing_texts[[i]] <- missing_text

            } else {

                unique_missing_patients[[i]] <- NA
                unique_missing_texts[[i]] <- NA

            }

        }

        unique_missing_patients <- unlist(unique_missing_patients)

        if (!is.na(patient_vect[1])){

            unique_missing_texts <- unique_missing_texts[unique_missing_patients %in% patient_vect]
            unique_missing_patients <- unique_missing_patients[unique_missing_patients %in% patient_vect]

        } else {

            unique_missing_texts <- unique_missing_texts[!is.na(unique_missing_patients)]
            unique_missing_patients <- unique_missing_patients[!is.na(unique_missing_patients)]

        }

        if (length(unique_missing_patients)>0) {

            print("Annotating...")

            batch_processor_db(unique_missing_patients, text_format, nlp_engine, URL, negex_simp, umls_selected, uri_fun, user,
                password, host, replica_set, port, database, max_n_grams_length, negex_depth, select_cores, tag_query, unique_missing_texts, date_min, date_max)

        } else print("No records to annotate!")

    } else print("No records to annotate!")

}


#' Upload Notes to Database
#'
#' Allows user to populate notes in database from dataframe; could be easily inserted into wrapper batch function to serially download from other DB etc. Notes dataframe must contain: 'patient_id', 'text_id' (a unique identifier for each text segment), along with 'text', 'text_date', 'doc_id' (designates unique EHR document) and ideally 'text_sequence' which indicates order of text section within document. 'doc_section_name' along 'text_tag_1' to 'text_tag_10' are optional. 'text_date' must be in format '%Y-%m-%d'! Only one patient at a time.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param notes Dataframe of EHR documents with metadata. The documents can consist of full notes or note subsections.
#' @return {
#' Confirmation that requested operation was completed, or error message if attempt failed.
#' }
#' @examples
#' \dontrun{
#' upload_notes(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT', notes = simulated_patients)
#' }
#' @export

upload_notes <- function(uri_fun, user, password, host, replica_set, port, database, notes) {

    # mongo_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "NOTES")
    # Changed 7-20-2022
    notes_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "NOTES")

    patient_id <- unique(notes$patient_id)

    if (anyNA(match(c("patient_id", "text_id", "text", "text_date", "doc_id"), colnames(notes))))
        print("Error: missing field.") else {

            if (is.numeric(notes$patient_id) & length(patient_id)==1) min_val_pt <- min(notes$patient_id) else min_val_pt <- 0
            if ("text_sequence" %in% colnames(notes) & is.numeric(notes$text_sequence)) min_val_seq <- min(notes$text_sequence)
            if ("text_sequence" %in% colnames(notes) & !is.numeric(notes$text_sequence)) min_val_seq <- 0
            # Added 11-08-2022
            if (!("text_sequence" %in% colnames(notes))) min_val_seq <- 1

            if (min_val_pt <=0 | min_val_seq <=0) print("Error: patient ID and text sequence values must be numeric and >0; notes for only 1 patient can be uploaded at a time.") else {

                date_check <- !(as.character(as.Date(notes$text_date, format = "%Y-%m-%d")) == notes$text_date)

                if (anyNA(date_check) | any(date_check)) print("Error: date format incorrect, must use %Y-%m-%d.") else {

                    # Remedy in case there is no text sequence, expected if notes not atomized.

                    if (!("text_sequence" %in% colnames(notes))) {

                        notes$text_sequence <- rep(1, length(notes[,1]))
                        print("Text sequence missing, importing as is.")

                    }

                    # Making sure text and doc ID's are in character form, no whitespace
                    notes$text_id <- trimws(as.character(notes$text_id))
                    notes$doc_id <- trimws(as.character(notes$doc_id))

                    # For consistency of data field type with results of annotations
                    notes$text_sequence <- as.integer(notes$text_sequence)
                    notes$patient_id <- as.double(notes$patient_id)

                    # added "doc_section_name" 6-07-2023
                    standard_fields <- c("patient_id", "text_id", "text", "text_date", "doc_id", "text_sequence", "doc_section_name",
                        "text_tag_1", "text_tag_2", "text_tag_3", "text_tag_4", "text_tag_5", "text_tag_6", "text_tag_7",
                        "text_tag_8", "text_tag_9", "text_tag_10")

                    fields_present <- colnames(notes)[colnames(notes) %in% standard_fields]
                    notes <- subset(notes, select = fields_present)

                    # Converting dates to POSIX

                    notes$text_date <- strptime(notes$text_date, "%Y-%m-%d", 'UTC')

                    # Getting notes already in DB

                    notes_cedars <- notes_con$find(query = paste('{\"patient_id\" :', patient_id[1], '}'), fields =  '{\"text_id\" : 1, \"_id\" : 0}')
                    notes <- subset(notes, !(text_id %in% notes_cedars$text_id))

                    if (length(notes[,1])>0) {

                        suppressWarnings(upload_results <- notes_con$insert(notes, stop_on_error = FALSE))
                        print(paste(upload_results$nInserted, " of ", length(notes[, 1]), " records inserted!", sep = ""))

                    } else print("All notes already in CEDARS! Nothing uploaded.")

                    }

            }

        }

    gc()

}


#' Upload Notes for Multiple Patients to Database
#'
#' Allows user to populate notes in database from dataframe. Notes dataframe must contain: 'patient_id', 'text_id' (a unique identifier for each text segment), along with 'text', 'text_date', 'doc_id' (designates unique EHR document) and ideally 'text_sequence' which indicates order of text section within document. 'doc_section_name' along 'text_tag_1' to 'text_tag_10' are optional. 'text_date' must be in format '%Y-%m-%d'!.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param notes Dataframe of EHR documents with metadata. The documents can consist of full notes or note subsections.
#' @return {
#' Confirmation that requested operation was completed, or error message if attempt failed.
#' }
#' @examples
#' \dontrun{
#' upload_notes(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT', notes = simulated_patients)
#' }
#' @export

batch_upload_notes <- function(uri_fun, user, password, host, replica_set, port, database, notes){

  ids <- unique(notes$patient_id)

  for (i in 1:length(ids)){
    upload_notes(uri_fun, db_user_name, db_user_pw, db_host, db_replica_set, db_port, mongo_database,
                 subset(notes, patient_id == ids[i]))
  }

}
