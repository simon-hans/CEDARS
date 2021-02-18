

# Prepare dictionaries and upload to MongoDB


#' Upload UMLS Dictionary
#'
#' Prepares and uploads UMLS MRCONSO.RRF file. This file is not included in the CEDARS package and can be obtained on the NIH web site at https://www.nlm.nih.gov/research/umls/index.html.
#' @param path Path to file MRCONSO.RRF.
#' @param language Language of biomedical lexicon, default is English (ENG).
#' @param subsets Character vector of lexicon subsets to retain. UMLS is quite large so most applications can use only a few lexicon subsets.
#' @param max_grams Maximum length of token in grams. Tokens above the thresold length will not be retained. Empirically, a value of 7 suffices for most applications.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @return {
#' Progress report of dictionary processing and upload.
#' }
#' @examples
#' \dontrun{
#' mrconso_upload(path = 'dictionaries/MRCONSO.RRF', language = 'ENG', subsets = c('SNOMEDCT_US',
#' 'MTHICD9', 'ICD9CM', 'ICD10', 'ICD10CM', 'DSM-5', 'MSH', 'RXNORM', 'NCI'), max_grams = 7,
#' user = 'John', password = 'db_password_1234', host = 'server1234', port = NA,
#' database = 'TEST_PROJECT')
#' }
#' @export

mrconso_upload <- function(path, language = "ENG", subsets, max_grams = 7, uri_fun, user, password, host, replica_set, port, database) {

    print("Reading file...")

    mrconso <- readr::read_delim(path, col_names = FALSE, delim = "|", quote = "")

    print("Processing table...")

    colnames(mrconso) <- c("CUI", "LAT", "TS", "LUI", "STT", "SUI", "ISPREF", "AUI", "SAUI", "SCUI", "SDUI", "SAB",
        "TTY", "CODE", "STR", "SRL", "SUPPRESS", "CVF")
    mrconso[, is.na(colnames(mrconso))] <- NULL

    print("Selecting subsets of interest...")

    mrconso <- subset(mrconso, LAT == language & SAB %in% subsets)

    print("Cleaning up tokens and standardizing character set...")

    # Removing empty fields and converting to lower case
    mrconso <- mrconso[!is.na(mrconso$STR), ]
    mrconso$STR <- as.character(mrconso$STR)
    mrconso$STR <- tolower(mrconso$STR)

    # Removing non-standard characters, often found in chemical names
    match.vect <- grepl(",", mrconso$STR) | grepl("\\(", mrconso$STR) | grepl("\\)", mrconso$STR) | grepl("'",
        mrconso$STR) | grepl("\"", mrconso$STR) | grepl("<", mrconso$STR) | grepl(">", mrconso$STR) | grepl("\\[",
        mrconso$STR) | grepl("\\]", mrconso$STR) | grepl("\\{", mrconso$STR) | grepl("\\}", mrconso$STR) | grepl("#",
        mrconso$STR) | grepl("\\^", mrconso$STR) | grepl(":", mrconso$STR) | grepl(";", mrconso$STR)
    mrconso <- mrconso[!match.vect, ]

    # Cleaning up
    mrconso$STR <- gsub("-", " - ", mrconso$STR)
    mrconso$STR <- iconv(mrconso$STR, from = "latin1", to = "UTF-8")
    mrconso <- mrconso[!duplicated(mrconso$STR), ]

    print(paste("Keeping tokens with max length of ", max_grams, " grams...", sep = ""))

    # The last column of the tibble/df contains a list, which is received as an array by MongoDB
    mrconso$grams <- lapply(1:length(mrconso$CUI), token_splitter, mrconso, max_grams)

    mrconso <- mrconso[!is.na(mrconso$grams), ]

    print("Uploading to DB...")

    mongo_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "UMLS_MRCONSO")

    mongo_con$insert(mrconso)

}


#' Upload UMLS Relationships
#'
#' Prepares and uploads UMLS MRREL.RRF file. This file is not included in the CEDARS package and can be obtained on the NIH web site at https://www.nlm.nih.gov/research/umls/index.html. It is very large and not currently used by CEDARS.
#' @param path Path to file MRREL.RRF.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @return {
#' Progress report of UMLS processing and upload.
#' }
#' @examples
#' \dontrun{
#' mrrel_upload(path = 'dictionaries/MRREL.RRF', uri_fun = mongo_uri_standard, user = 'John',
#' password = 'db_password_1234', host = 'server1234', port = NA, database = 'TEST_PROJECT')
#' }
#' @export

mrrel_upload <- function(path, uri_fun, user, password, host, replica_set, port, database) {

    print("Reading file...")

    mrrel_names <- c("CUI1", "AUI1", "STYPE1", "REL", "CUI2", "AUI2", "STYPE2", "RELA", "RUI", "SRUI", "RSAB",
        "VSAB", "SL", "RG", "DIR", "SUPPRESS", "CVF")
    mrrel_types <- cols(CUI1 = col_character(), AUI1 = col_character(), STYPE1 = col_character(), REL = col_character(),
        CUI2 = col_character(), AUI2 = col_character(), STYPE2 = col_character(), RELA = col_character(), RUI = col_character(),
        SRUI = col_character(), RSAB = col_character(), VSAB = col_character(), SL = col_character(), RG = col_character(),
        DIR = col_character(), SUPPRESS = col_character(), CVF = col_character())
    mrrel <- readr::read_delim(path, col_names = mrrel_names, delim = "|", quote = "", col_types = mrrel_types)

    print("Keeping relationships for concepts of interest...")

    mrconso_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "UMLS_MRCONSO")
    selected_cuis <- mrconso_con$distinct("CUI")

    mrrel <- subset(mrrel, CUI1 %in% selected_cuis & CUI2 %in% selected_cuis)

    print("Uploading to DB...")

    mrrel_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "UMLS_MRREL")

    mrrel_con$insert(mrrel)

}


#' Upload NegEx
#'
#' Prepares and uploads NegEx negation lexicon. It is not absolutely required for CEDARS to function but in practice will improve search accuracy for most applications.
#' @param uri_fun Uniform resource identifier (URI) string generating function for MongoDB credentials.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB host server.
#' @param replica_set MongoDB replica set, if indicated.
#' @param port MongoDB port.
#' @param database MongoDB database name.
#' @param selected_model_path Path to NLP model file.
#' @return {
#' Confirmation of upload.
#' }
#' @examples
#' \dontrun{
#' negex_upload(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',
#' host = 'server1234', port = NA, database = 'TEST_PROJECT', NA)
#' }
#' @export

negex_upload <- function(uri_fun, user, password, host, replica_set, port, database, selected_model_path = NA) {

    # Finding NLP model to use, if not specified
    selected_model_path <- find_model(selected_model_path)

    udmodel <- udpipe::udpipe_load_model(selected_model_path)

    negex_original <- negex

    # We only keep terms indicating negation or pseudonegation Making sure there are no duplicates!
    negex_short <- negex_original[grepl("Neg", negex_original$CATEGORY, ignore.case = TRUE), ]
    negex_short <- negex_short[!duplicated(negex_short$ITEM), ]

    # Wrapper for udpipe annotator Makes it easier to use lapply
    annotator <- function(text, model) {

        output <- udpipe::udpipe_annotate(model, text)
        output <- as.data.frame(output, detailed = TRUE)$token

        output

    }

    negex_list <- list()
    negex_list$category <- negex_short$CATEGORY
    negex_list$item <- lapply(negex_short$ITEM, annotator, udmodel)
    negex_list$closure <- negex_short$CLOSURE

    negex_simp <- data.frame(item = negex_short$ITEM, category = negex_short$CATEGORY, closure = negex_short$CLOSURE)
    negex_simp$closure <- as.character(negex_simp$closure)
    negex_simp$closure[is.na(negex_simp$closure)] <- "none"
    negex_simp$item <- as.character(negex_simp$item)

    negex_simp$n_grams_length <- NA
    for (i in 1:length(negex_simp[, 1])) negex_simp$n_grams_length[i] <- length(negex_list$item[[i]])

    print("Uploading to DB...")

    negex_con <- mongo_connect(uri_fun, user, password, host, replica_set, port, database, "NEGEX")

    # mongolite still does not support creation of unique indexes
    negex_con$run("{\"createIndexes\": \"NEGEX\", \"indexes\" : [{ \"key\" : { \"item\" : 1}, \"name\": \"item\", \"unique\": true}]}")

    negex_con$insert(negex_simp)

}


#' Split a Token
#'
#' Splits a token in its different grams and outputs. Processes one row from the UMLS MRCONSO file at a time.
#' @param i Iteration number, i.e. row number withint MRCONSO.
#' @param df MRCONSO dataframe.
#' @param max_grams Maximum length of token in grams.
#' @return A list which includes the original data for one UMLS concept unique identifier (CUI).
#' @keywords internal

token_splitter <- function(i, df, max_grams) {

    df <- df[i, ]

    grams <- unlist(strsplit(df$STR[1], split = " "))
    out <- grams

    if (length(grams) > max_grams)
        out <- NA

    if (i/10000 == round(i/10000, digits = 0))
        cat(paste("\rProcessed ", i, " rows...", sep = ""))

    out

}


#' Get a NLP Model
#'
#' Downloads a NLP model, presently only UDPipe models supported.
#' @param model_name Name of models to download.
#' @param platform Name of NLP platform, currently only UDPipe is supported.
#' @return Saves model in inst/models.
#' @export

get_model <- function(model_name = "english-ewt", platform = "udpipe") {

    models_path <- paste(find.package("CEDARS", lib.loc = NULL, quiet = TRUE), "/inst/models", sep = "")

    if (platform == "udpipe") {

        udpipe::udpipe_download_model(language = model_name, model_dir = models_path)

        } else print("Only UDPipe is supported at this time, exiting.")

}
