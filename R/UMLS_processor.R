

#' Tag Tokens With UMLS Concepts
#'
#' Main processor for matching to UMLS concepts.
#' @param annotated_text Dataframe of NLP annotations.
#' @param umls_selected UMLS dictionary.
#' @param max_n_grams_length Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If ) is chosen, UMLS CUI tags will not be provided.
#' @return Dataframe of NLP annotations with added UMLS tags.

umls_processor <- function(annotated_text, umls_selected, max_n_grams_length) {
    
    i <- 2
    
    annotated_text$tolower_token <- tolower(annotated_text$token)
    
    annotated_text <- fast_merge_umls(annotated_text, umls_selected, "tolower_token", i)
    annotated_text$umls_end <- NA
    annotated_text$umls_end[!is.na(annotated_text$CUI)] <- annotated_text$end[!is.na(annotated_text$CUI)]
    colnames(annotated_text) <- gsub("CUI", "umls_CUI", colnames(annotated_text))
    
    while (i <= max_n_grams_length) {
        annotated_text <- annotated_text[order(annotated_text$doc_id, annotated_text$paragraph_id, annotated_text$sentence_id, annotated_text$start, decreasing = FALSE, method = "radix"), ]
        annotated_text$grams <- udpipe::txt_nextgram(annotated_text$tolower_token, n = i, sep = " ")
        annotated_text <- fast_merge_umls(annotated_text, umls_selected, "grams", i)
        annotated_text$umls_CUI[!is.na(annotated_text$CUI)] <- annotated_text$CUI[!is.na(annotated_text$CUI)]
        annotated_text <- annotated_text[order(annotated_text$doc_id, annotated_text$paragraph_id, annotated_text$sentence_id, annotated_text$start, decreasing = FALSE, method = "radix"), ]
        annotated_text$umls_end[!is.na(annotated_text$CUI)] <- annotated_text$end[(1:length(annotated_text[, 1]))[!is.na(annotated_text$CUI)] + i - 1]
        # We overwrite older phrases included in newer, larger ones
        temp <- list()
        for (j in (1:length(annotated_text[, 1]))[!is.na(annotated_text$CUI)]) temp[[j]] <- j + (1:(i - 1))
        temp <- unlist(temp)
        annotated_text$umls_CUI[temp] <- NA
        annotated_text$umls_end[temp] <- NA
        annotated_text$CUI <- NULL
        i <- i + 1
    }
    
    annotated_text$umls_CUI <- as.character(annotated_text$umls_CUI)
    annotated_text$umls_CUI[is.na(annotated_text$umls_CUI)] <- "none"
    
    annotated_text$grams <- NULL
    annotated_text$tolower_token <- NULL
    
    annotated_text <- annotated_text[order(annotated_text$doc_id, annotated_text$paragraph_id, annotated_text$sentence_id, annotated_text$start, decreasing = FALSE, method = "radix"), ]
    
    annotated_text
    
}


#' Merge UMLS Tags
#'
#' Fast implementation of matching process to find UMLS concept unique identifiers (CUI's) corresponding to tokens from EHR documents.
#' @param query_x Vector of tokens to match.
#' @param umls_selected UMLS dictionary.
#' @param by_x Field name for tokens to match.
#' @param n_grams Length of tokens to match.
#' @return Tokens matched with a CUI.

fast_merge_umls <- function(query_x, umls_selected, by_x, n_grams) {
    
    i <- match(by_x, colnames(query_x))
    j <- match("STR", colnames(umls_selected))
    k <- match("CUI", colnames(umls_selected))
    last_col <- ncol(query_x) + 1
    
    query_x[, last_col] <- umls_selected[fastmatch::fmatch(query_x[, i], umls_selected[, j]), k]
    
    colnames(query_x)[last_col] <- "CUI"
    
    query_x
    
}
