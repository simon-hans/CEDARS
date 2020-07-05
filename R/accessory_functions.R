

# Sundry functions


#' Sanitize Text
#'
#' Removes non-ASCII characters and '*' from clinical corpora or user input.
#' @param text Raw text from the EHR.
#' @return Cleaned text in ASCII format stripped of '*' characters.

sanitize <- function(text) {
    
    text <- gsub("[^\\x00-\\x7F]", " ", text, perl = TRUE)
    text <- gsub("\\*", " ", text)
    text
    
}


#' Sanitize Query
#'
#' Removes non-ASCII characters from search query and attempts to correct formulation errors.
#' @param query Raw text from the query.
#' @return Cleaned query.

sanitize_query <- function(query) {
    
    query <- gsub("[^\\x00-\\x7F]", " ", query, perl = TRUE)
    query <- gsub("\\*+", "*", query)
    query <- gsub("\\(+", "(", query)
    query <- gsub("\\)+", ")", query)
    query
    
}


#' Format Keyword Elements
#'
#' Prepares keyword element vector, converting wildcards to Regex syntax. Wildcards include '?' for any single character and '*' for any number of characters including zero.
#' @param keyword_elements Keywords.
#' @return Formatted keywords.

format_keywords <- function(keyword_elements) {
    
    keyword_elements <- tolower(keyword_elements)
    keyword_elements <- utils::glob2rx(keyword_elements, trim.head = TRUE, trim.tail = TRUE)
    keyword_elements
    
}


#' Standardize Output From NLP Engine
#'
#' Converts output of NLP engine to a dataframe with entries recognized by CEDARS.
#' @param input_df Data frame produced by the NLP engine.
#' @param engine NLP engine. At this time only UDPipe is supported.
#' @return A dataframe with NLP annotations.

standardize_nlp <- function(input_df, engine) {
    
    if (engine == "udpipe") {
        
        output_df <- data.frame(text_id = input_df$doc_id, paragraph_id = input_df$paragraph_id, sentence_id = input_df$sentence_id, 
            start = input_df$start, end = input_df$end, token = input_df$token, lemma = input_df$lemma, token_id = input_df$token_id, 
            upos = input_df$upos, xpos = input_df$xpos, head_token_id = input_df$head_token_id, dependency = input_df$dep_rel, 
            features = input_df$feats)
    }
    
    output_df$upos <- as.character(output_df$upos)
    output_df$token_id <- as.character(output_df$token_id)
    output_df$token_id <- as.numeric(output_df$token_id)
    output_df$head_token_id <- as.character(output_df$head_token_id)
    output_df$head_token_id <- as.numeric(output_df$head_token_id)
    
    output_df
    
}


#' Highlight Keywords and Concepts
#'
#' Adds color and changes font to bold for selected strings of sentences and notes. The current method uses HTML.
#' @param get_output Dataframe with field 'selected', the latter containing text string corresponding to selected sentences.
#' @return Text string with HTML markup.

colorize <- function(get_output) {
    
    get_output$selected <- gsub("\\*START\\*", "<span style=\"color:red;font-weight:bold\">", get_output$selected)
    get_output$selected <- gsub("\\*END\\*", "</span>", get_output$selected)
    
    get_output$note_text <- gsub("\\*START\\*", "<span style=\"color:red;font-weight:bold\">", get_output$note_text)
    get_output$note_text <- gsub("\\*END\\*", "</span>", get_output$note_text)
    
    get_output$note_text <- gsub("\\n", "<br>", get_output$note_text)
    
    get_output
    
}


#' Start CEDARS Locally
#'
#' Starts CEDARS locally from RStudio. This is a functional approach and is easier to implement than a full-fledged Shiny Server. Multiple users can access the same CEDARS project on the MongoDB server using separate local R sessions, however in that case MongoDB credentials would have to be shared to all. The best option for multi-user implementations is to use Shiny Server.
#' @param user DB user name.
#' @param password DB password.
#' @param host Host server.
#' @examples
#' \dontrun{
#' start_local(user = 'John', password = 'db_password_1234', host = 'server1234')
#' }
#' @export

start_local <- function(user, password, host) {
    
    g_user <- user
    g_password <- password
    g_host <- host
    
    g_user <<- g_user
    g_password <<- g_password
    g_host <<- g_host
    
    shiny::runApp(appDir = paste(find.package("CEDARS", lib.loc = NULL, quiet = TRUE), "/shiny", sep = ""))
    
}


#' Save MongoDB Credentials
#'
#' Saves MongoDB credentials as 'db_credentials.Rdata' and Shiny app file as 'app.R'. Those two files should be copied to the Shiny Server app directory. Needed only if using Shiny Server; credentials are entered in the command line for local app use.
#' @param user MongoDB user name.
#' @param password MongoDB user password.
#' @param host MongoDB server host.
#' @param destination_path Folder where the files should be saved. Default is working directory.
#' @examples
#' \dontrun{
#' save_credentials(user = 'John', password = 'db_password_1234', host = 'server1234',
#' destination_path = getwd())
#' }
#' @export

save_credentials <- function(user, password, host, destination_path = getwd()) {
    
    app_path <- paste(find.package("CEDARS", lib.loc = NULL, quiet = TRUE), "/shiny/app.R", sep = "")
    
    g_user <- user
    g_password <- password
    g_host <- host
    
    file.copy(from = app_path, to = paste(destination_path, "/app.R", sep = ""))
    
    save(g_user, g_password, g_host, file = paste(destination_path, "/db_credentials.Rdata", sep = ""))
    
}


