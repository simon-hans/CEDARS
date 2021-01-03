

#' Annotate for Negation
#'
#' Annotates EHR text for negation, based on Negex, as simple medical negation lexicon. Tokens are labelled by proximity. The original paper went up to 6 tokens before or after negation.
#' @param annotated_text Dataframe of NLP annotations.
#' @param negex_simp Dataframe of simplified negex.
#' @param negex_depth Maximum distance between word to label and negation term, before or after. Default is 6, as per original paper by Chapman et al.
#' @return Dataframe with added negation information.
#' @keywords internal

negex_processor <- function(annotated_text, negex_simp, negex_depth = 6) {

    negex_simp$item <- as.character(negex_simp$item)
    annotated_text$token <- as.character(annotated_text$token)

    i <- 2

    annotated_text$tolower_token <- tolower(annotated_text$token)
    annotated_text <- merge(annotated_text, subset(negex_simp, n_grams_length = 1, select = c("item", "category",
        "closure")), by.x = "tolower_token", by.y = "item", all.x = TRUE, all.y = FALSE)
    annotated_text$negex_end <- NA
    annotated_text$negex_end[!is.na(annotated_text$category) | !is.na(annotated_text$closure)] <- annotated_text$token_id[!is.na(annotated_text$category) |
        !is.na(annotated_text$closure)]
    colnames(annotated_text) <- gsub("category", "negex_category", colnames(annotated_text))
    colnames(annotated_text) <- gsub("closure", "negex_closure", colnames(annotated_text))

    max_n_grams_length <- max(negex_simp$n_grams_length)

    while (i <= max_n_grams_length) {
        annotated_text <- annotated_text[order(annotated_text$paragraph_id, annotated_text$sentence_id, annotated_text$start,
            decreasing = FALSE, method = "radix"), ]
        annotated_text$grams <- udpipe::txt_nextgram(annotated_text$tolower_token, n = i, sep = " ")
        annotated_text <- merge(annotated_text, subset(negex_simp, n_grams_length = i, select = c("item", "category",
            "closure")), by.x = "grams", by.y = "item", all.x = TRUE, all.y = FALSE)
        annotated_text$negex_category[!is.na(annotated_text$category) | !is.na(annotated_text$closure)] <- annotated_text$category[!is.na(annotated_text$category) |
            !is.na(annotated_text$closure)]
        annotated_text$negex_closure[!is.na(annotated_text$category) | !is.na(annotated_text$closure)] <- annotated_text$closure[!is.na(annotated_text$category) |
            !is.na(annotated_text$closure)]
        annotated_text <- annotated_text[order(annotated_text$paragraph_id, annotated_text$sentence_id, annotated_text$start,
            decreasing = FALSE, method = "radix"), ]
        annotated_text$negex_end[!is.na(annotated_text$category) | !is.na(annotated_text$closure)] <- annotated_text$token_id[(1:length(annotated_text[,
            1]))[!is.na(annotated_text$category) | !is.na(annotated_text$closure)] + i - 1]
        # We overwrite older phrases included in newer, larger ones
        temp <- list()
        for (j in (1:length(annotated_text[, 1]))[!is.na(annotated_text$category) | !is.na(annotated_text$closure)]) temp[[j]] <- j +
            (1:(i - 1))
        temp <- unlist(temp)
        annotated_text$negex_category[temp] <- NA
        annotated_text$negex_closure[temp] <- NA
        annotated_text$negex_end[temp] <- NA
        annotated_text$category <- NULL
        annotated_text$closure <- NULL
        i <- i + 1
    }

    annotated_text$grams <- NULL
    annotated_text$tolower_token <- NULL

    if (any(!is.na(annotated_text$negex_category)))
        annotated_text <- negation_tagger(annotated_text, negex_depth) else annotated_text$negated <- rep(FALSE, length(annotated_text[, 1]))

    annotated_text <- annotated_text[order(annotated_text$paragraph_id, annotated_text$sentence_id, annotated_text$start,
        decreasing = FALSE, method = "radix"), ]

    annotated_text

}


#' Tag for Negation
#'
#' Processes and NLP annotation dataframe and tags negated words based on distance from negation item.
#' @param annotated_text Dataframe of NLP annotations.
#' @param negex_depth Maximum distance between word to label and negation term, before or after. Default is 6, as per original paper by Chapman et al.
#' @return Dataframe with added negation information.
#' @keywords internal

negation_tagger <- function(annotated_text, negex_depth) {

    work_df <- subset(annotated_text, !is.na(negex_category), select = c("paragraph_id", "sentence_id", "token_id",
        "negex_category", "negex_end"))

    work_df$token_id <- lapply(1:length(work_df[, 1]), negex_token_tagger, work_df, negex_depth)

    work_df$paragraph_id <- lapply(1:length(work_df[, 1]), id_expander, work_df, "paragraph_id")

    work_df$sentence_id <- lapply(1:length(work_df[, 1]), id_expander, work_df, "sentence_id")

    work_df <- data.frame(paragraph_id = unlist(work_df$paragraph_id), sentence_id = unlist(work_df$sentence_id),
        token_id = unlist(work_df$token_id))
    work_df$negated <- TRUE
    work_df <- work_df[!duplicated(work_df), ]

    annotated_text <- merge(annotated_text, work_df, by = c("paragraph_id", "sentence_id", "token_id"), all.x = TRUE,
        all.y = FALSE)
    annotated_text$negated[is.na(annotated_text$negated)] <- FALSE

    annotated_text

}


#' Compute Token Series
#'
#' Computes negated token series as a function of index, i.e. position of negation item.
#' @param index Position of negation item.
#' @param work_df Working dataframe of NLP annotations.
#' @param negex_depth Maximum distance from index to which negation will spread.
#' @return Series of token positions within the working dataframe.
#' @keywords internal

negex_token_tagger <- function(index, work_df, negex_depth) {

    before <- as.numeric(as.character(work_df[index, ]$token))
    after <- as.numeric(as.character(work_df[index, ]$negex_end))

    # Getting negated token series
    before <- (before - negex_depth):(before - 1)
    after <- (after + 1):(after + negex_depth)

    out <- c(before, after)

    out

}


#' Expand ID's
#'
#' Duplicates paragraph or sentence ID's to help process negation based on negated token series.
#' @param index Row position within annotations dataframe.
#' @param work_df Working annotations dataframe.
#' @param field Field to duplicate.
#' @return Series of duplicated field values.
#' @keywords internal

id_expander <- function(index, work_df, field) {

    column <- which(colnames(work_df) == field)
    out <- as.numeric(as.character(work_df[index, column]))

    out <- rep(out, length(work_df[index, ]$token_id[[1]]))

}
