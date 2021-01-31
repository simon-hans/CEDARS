

assign("cedars.env", new.env())


#' Load Options on Startup
#'
#' Disables scientific notation which can be a problem for large ID's.
#' @param libname Library name.
#' @param pkgname Package name.
#' @keywords internal

.onLoad <- function(libname, pkgname) {

    # op <- options(scipen = 999)

    # cedars.env <- new.env(parent=emptyenv())

    utils::globalVariables(c("CUI1", "CUI2", "LAT", "SAB", "col_character", "cols", "doc_id", "end", "lemma", "negated", "negex", "negex_category", "nlp_model",
        "paragraph_id", "reviewed", "sentence_id", "start.x", "start.y", "text_date", "text_id", "umls_CUI", "umls_end",
        "unique_id", "cedars.env"))

}
