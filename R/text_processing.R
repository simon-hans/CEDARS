

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
    tag_data <- c(text_date, text_sequence, doc_section_name, doc_id, text_tag_1, text_tag_2, text_tag_3, text_tag_4, 
        text_tag_5, text_tag_6, text_tag_7, text_tag_8, text_tag_9, text_tag_10)
    tags <- t(matrix(rep(tag_data, length(annotated_text[, 1])), nrow = length(tag_data), ncol = length(annotated_text[, 
        1])))
    tags <- as.data.frame(tags)
    colnames(tags) <- c("text_date", "text_sequence", "doc_section_name", "doc_id", "text_tag_1", "text_tag_2", 
        "text_tag_3", "text_tag_4", "text_tag_5", "text_tag_6", "text_tag_7", "text_tag_8", "text_tag_9", "text_tag_10")
    
    annotated_text <- cbind(annotated_text, tags)
    
    annotated_text
    
}


#' Process All Documents for One Patient
#'
#' Performs NLP annotations on all documents using previously established cluster, including NegEx and UMLS CUI tags.
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

patient_processor_par <- function(cl, sub_corpus, text_format, nlp_engine, negex_simp, umls_selected, max_n_grams_length, 
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
        
        if (!is.na(cl[1])) 
            annotations <- parallel::parLapply(cl, sub_corpus_short, document_processor, text_format, nlp_engine, 
                negex_simp, negex_depth) else {
            
            annotations <- lapply(sub_corpus_short, document_processor, text_format, nlp_engine, negex_simp, negex_depth, 
                single_core_model)
            
        }
        
        output <- do.call("rbind", annotations)
        
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
#' @param database MongoDB database name.
#' @param max_n_grams_length Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If ) is chosen, UMLS CUI tags will not be provided.
#' @param negex_depth Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
#' @param select_cores How many CPU cores should be used for parallel processing? Max allowed is total number of cores minus one. If 1 is entered, parallel processing will not be used.

batch_processor_db <- function(patient_vect, text_format, nlp_engine, URL, negex_simp, umls_selected, uri_fun, 
    user, password, host, database, max_n_grams_length, negex_depth, select_cores) {
    
    # print('Loading NLP model...') nlp_model <- udpipe::udpipe_load_model(URL)
    
    length_list <- length(patient_vect)
    
    # We create a computing cluster If requested # of cores > available minus one, will use available minus one If
    # no specified # of desired cores, will use available minus one
    no_cores <- parallel::detectCores() - 1
    if (is.na(select_cores) | select_cores > no_cores | select_cores < 1) {
        
        cat("Initializing cluster...\n\n")
        cl <- parallel::makeCluster(no_cores)
        
    } else {
        
        if (select_cores > 1) {
            
            cat("Initializing cluster...\n\n")
            cl <- parallel::makeCluster(select_cores)
        } else cl <- NA
        
    }
    
    if (!is.na(cl[1])) {
        
        parallel::clusterExport(cl, c("sanitize", "standardize_nlp", "negation_tagger", "negex_token_tagger", "id_expander", 
            "negex_processor", "negex_simp", "negex_depth", "URL"), envir = environment())
        
        parallel::clusterCall(cl, function() {
            nlp_model <- udpipe::udpipe_load_model(URL)
            nlp_model <<- nlp_model
            
        })
        
        single_core_model <- NA
        
    } else single_core_model <- udpipe::udpipe_load_model(URL)
    
    cat("Performing annotations!\n\n")
    
    j <- 0
    
    for (i in 1:length_list) {
        # Records for this patient undergo admin lock during the upload But first, old user-locked records are unlocked
        # A record is considered open for annotation if 1) the patient is not in the roster yet or 2) admin lock was
        # successful
        unlock_records(uri_fun, user, password, host, database)
        open <- lock_records_admin(uri_fun, user, password, host, database, patient_vect[i])
        if (open == TRUE) {
            
            sub_corpus <- db_download(uri_fun, user, password, host, database, patient_vect[i])
            if (length(sub_corpus[, 1]) > 0) {
                annotations <- patient_processor_par(cl, sub_corpus, text_format, nlp_engine, negex_simp, umls_selected, 
                  max_n_grams_length, negex_depth, single_core_model)
                
                if (is.data.frame(annotations)) {
                  
                  row.names(annotations) <- NULL
                  db_upload(uri_fun, user, password, host, database, patient_vect[i], annotations)
                  
                }
                
            }
            
            unlock_records_admin(uri_fun, user, password, host, database, patient_vect[i])
            
            cat(paste(c("Completed annotations for patient ID ", patient_vect[i], ", # ", i, " of ", length_list, 
                ".\n"), sep = "", collapse = ""))
            
        } else j <- j + 1
        
    }
    
    cat("\n")
    
    if (!is.na(cl[1])) 
        parallel::stopCluster(cl)
    
    print(paste("There were ", j, " locked cases encountered.", sep = ""))
    
    patient_roster_update(uri_fun, user, password, host, database)
    
}


#' Process NLP Annotations on the Current Patient Cohort
#'
#' Accepts a list of patient ID's or alternatively can perform NLP annotations on all available patients in the database.
#' @param patient_vect Vector of patient ID's. Default is NA, in which case all available patient records will undergo NLP annotation.
#' @param text_format Text format for NLP engine.
#' @param nlp_engine Which NLP engine should be used? UDPipe is the only one supported for now.
#' @param URL UDPipe model URL.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param database MongoDB database name.
#' @param max_n_grams_length Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If ) is chosen, UMLS CUI tags will not be provided.
#' @param negex_depth Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
#' @param select_cores How many CPU cores should be used for parallel processing? Max allowed is total number of cores minus one. If 1 is entered, parallel processing will not be used.
#' @examples
#' \dontrun{
#' automatic_NLP_processor(patient_vect = NA, text_format = 'latin1', nlp_engine = 'udpipe',
#' URL = 'models/english-ewt-ud-2.4-190531.udpipe', uri_fun = mongo_uri_standard, user = 'John',
#' password = 'db_password_1234', host = 'server1234', database = 'TEST_PROJECT',
#' max_n_grams_length = 7, negex_depth = 6, select_cores = NA)
#' }
#' @export

automatic_NLP_processor <- function(patient_vect = NA, text_format = "latin1", nlp_engine = "udpipe", URL, uri_fun = mongo_uri_standard, 
    user, password, host, database, max_n_grams_length = 7, negex_depth = 6, select_cores = NA) {
    
    annotations_con <- mongo_connect(uri_fun, user, password, host, database, "ANNOTATIONS")
    notes_con <- mongo_connect(uri_fun, user, password, host, database, "NOTES")
    patients_con <- mongo_connect(uri_fun, user, password, host, database, "PATIENTS")
    
    print("Downloading dictionaries...")
    
    # We do not use NeGex if it has not been installed or if NegEx depth is < 1
    negex_con <- mongo_connect(uri_fun, user, password, host, database, "NEGEX")
    if (negex_con$count() == 0) 
        negex_depth <- 0
    if (negex_depth > 0) 
        negex_simp <- negex_con$find("{}") else negex_simp <- NA
    
    # We do not use UMLS if it has not been installed or if max ngram length is < 1
    umls_con <- mongo_connect(uri_fun, user, password, host, database, "UMLS_MRCONSO")
    if (umls_con$count() == 0) 
        max_n_grams_length <- 0
    if (max_n_grams_length > 0) 
        umls_selected <- umls_con$find("{}") else umls_selected <- NA
    
    print("Finding patients with missing annotations...")
    
    # We are using simple code to find which text segments need to be annotated Does all of one patient, not
    # efficient, should go with text_id's Ideally this would be replaced by a MongoDB query (faster)
    
    # All text_id's with an existing annotation
    all_annotated <- unlist(annotations_con$find(query = "{}", fields = "{ \"text_id\" : 1, \"_id\" : 0 }"))
    
    # All text_id's available for annotation
    all_notes <- notes_con$find(query = "{}", fields = "{ \"text_id\" : 1, \"patient_id\" : 1, \"_id\" : 0 }")
    
    # text_id's missing an annotation
    missing <- all_notes[!(all_notes$text_id %in% all_annotated), ]
    if (!is.null(missing)) 
        unique_missing <- unique(missing$patient_id) else unique_missing <- NA
    
    if (is.na(patient_vect[1])) 
        patient_vect <- unique_missing else patient_vect <- patient_vect[patient_vect %in% unique_missing]
    
    patient_vect <- patient_vect[order(patient_vect, decreasing = FALSE, method = "radix")]
    
    rm(all_annotated)
    rm(all_notes)
    rm(missing)
    
    if (!is.na(patient_vect[1])) {
        
        print("Annotating...")
        
        batch_processor_db(patient_vect, text_format, nlp_engine, URL, negex_simp, umls_selected, uri_fun, user, 
            password, host, database, max_n_grams_length, negex_depth, select_cores)
        
    } else print("No records to annotate!")
    
}


#' Upload Notes to Database
#'
#' Allows user to populate notes in database from dataframe; could be easily inserted into wrapper batch function to serially download from other DB etc. Notes dataframe must contain: 'patient_id', 'text_id' (a unique identifier for each text segment), along with 'text', 'text_date', 'doc_id' (designates unique EHR document) and ideally 'text_sequence' which indicates order of text section within document. 'doc_section_name' along 'text_tag_1' to 'text_tag_10' are optional. 'text_date' must be in format '%Y-%m-%d'!
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param database MongoDB database name.
#' @param notes Dataframe of EHR documents with metadata. The documents can consist of full notes or note subsections.
#' @examples
#' \dontrun{
#' upload_notes(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', database = 'TEST_PROJECT', notes = simulated_patients)
#' }
#' @export

upload_notes <- function(uri_fun, user, password, host, database, notes) {
    
    mongo_con <- mongo_connect(uri_fun, user, password, host, database, "NOTES")
    
    if (anyNA(match(c("patient_id", "text_id", "text", "text_date", "doc_id"), colnames(notes)))) 
        print("Error: missing field.") else {
        
        date_check <- !(as.character(as.Date(notes$text_date, format = "%Y-%m-%d")) == notes$text_date)
        
        if (anyNA(date_check) | any(date_check)) 
            print("Error: date format incorrect, must use %Y-%m-%d.") else {
            
            standard_fields <- c("patient_id", "text_id", "text", "text_date", "doc_id", "text_sequence", "text_tag_1", 
                "text_tag_2", "text_tag_3", "text_tag_4", "text_tag_5", "text_tag_6", "text_tag_7", "text_tag_8", 
                "text_tag_9", "text_tag_10")
            
            fields_present <- colnames(notes)[colnames(notes) %in% standard_fields]
            notes <- subset(notes, select = fields_present)
            
            suppressWarnings(upload_results <- mongo_con$insert(notes, stop_on_error = FALSE))
            print(paste(upload_results$nInserted, " of ", length(notes[, 1]), " records inserted!", sep = ""))
            
        }
        
    }
    
    gc()
    
}
