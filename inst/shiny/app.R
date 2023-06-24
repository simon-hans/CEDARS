

library(CEDARS)

# Accessing the custom package environment

cedars.env <- CEDARS:::cedars.env


if (file.exists("db_credentials.Rdata")) load("db_credentials.Rdata", envir = cedars.env)

# Can be edited to use custom function. New app.R file should be copied to Shiny Server app folder!
# START EDIT
assign("g_mongodb_uri_fun", CEDARS::mongo_uri_standard, envir = cedars.env)
# END EDIT


ui <- fluidPage(

    titlePanel("Clinical Event Detection And Recording System"),

    # Logon displayed only if LDAP not in use

    conditionalPanel(condition = "output.display_logon == 'TRUE'", textInput(inputId = "user_id", label = "User ID:")),

    conditionalPanel(condition = "output.display_logon == 'TRUE'", passwordInput(inputId = "end_user_pw", label = "Password:")),

    # Conversely, if LDAP in use current user name will be displayed

    conditionalPanel(condition = "output.display_logon == 'FALSE'", tags$h3("LDAP user name:")),

    div(style = "border: 2px solid black; padding: 4px; width: fit-content", textOutput(outputId = "session_user")),

    tags$h3("Event date:"),

    tags$div(style = "border: 2px solid black; padding: 4px; width: fit-content", textOutput(outputId = "old_event_date")),

    tags$br(),

    actionButton(inputId = "enter_date", label = "ENTER NEW DATE"),

    actionButton(inputId = "delete_date", label = "DELETE OLD DATE"),

    tags$br(),

    tags$br(),

    dateInput(inputId = "event_date", label = NULL, value = NA),

    tags$h3("Selected sentence:"),

    actionButton(inputId = "adjudicate_sentence", label = "ADJUDICATE SENTENCE"),

    actionButton(inputId = "previous_sentence", label = "<<< PREVIOUS"),

    actionButton(inputId = "next_sentence", label = "NEXT >>>"),

    tags$br(),

    tags$br(),

    div(style = "border: 2px solid black; padding: 4px; width: fit-content", htmlOutput(outputId = "selected_sentence")),

    div(style = "font-weight:bold", textOutput(outputId = "sentence_position")),

    div(style = "font-weight:bold", textOutput(outputId = "text_date")),

    div(style = "font-weight:bold", textOutput(outputId = "patient_id")),

    textInput(inputId = "search_patient_id", label = "Search for patient:"),

    actionButton(inputId = "id_search", label = "SEARCH"),

    tags$h3("Comments:"),

    div(style = "border: 2px solid black; padding: 4px; width: fit-content", textOutput(outputId = "pt_comments")),

    tags$br(),

    textInput(inputId = "input_comments", label = "New comments:"),

    tags$h3("Selected note:"),

    div(style = "border: 2px solid black; padding: 4px; width: fit-content", htmlOutput(outputId = "selected_note")),

    tags$h3("Tags:"),

    tableOutput(outputId = "tags_table")

)


server <- function(input, output, session) {

    if (!exists("cedars.env$position")) cedars.env$position <- NA
    if (!exists("cedars.env$get_position")) cedars.env$get_position <- NA
    if (!exists("cedars.env$max_position")) cedars.env$max_position <- NA
    if (!exists("cedars.env$new_event_date")) cedars.env$new_event_date <- NA
    if (!exists("cedars.env$adjudicated")) cedars.env$adjudicated <- FALSE
    if (!exists("cedars.env$id_for_search")) cedars.env$id_for_search <- NA
    if (!exists("updated")) updated <- reactiveVal(Sys.time())

    observeEvent(eventExpr = input$enter_date, {

        if (length(input$event_date) > 0) cedars.env$new_event_date <- as.character(input$event_date) else cedars.env$new_event_date <- NA

        if (!is.na(cedars.env$new_event_date)) cedars.env$get_position <- NA else cedars.env$get_position <- cedars.env$position

        updated(Sys.time())

    })


    observeEvent(eventExpr = input$adjudicate_sentence, {

        cedars.env$adjudicated <- TRUE
        cedars.env$new_event_date <- NA
        cedars.env$get_position <- NA

        updated(Sys.time())

    })

    observeEvent(eventExpr = input$previous_sentence, {

        cedars.env$adjudicated <- FALSE
        cedars.env$new_event_date <- NA
        if (!is.na(cedars.env$position) & cedars.env$position>1) cedars.env$get_position <- cedars.env$position-1 else cedars.env$get_position <- cedars.env$position

        updated(Sys.time())

    })

    observeEvent(eventExpr = input$next_sentence, {

        cedars.env$adjudicated <- FALSE
        cedars.env$new_event_date <- NA
        if (!is.na(cedars.env$position) & cedars.env$max_position-cedars.env$position>0) cedars.env$get_position <- cedars.env$position+1 else cedars.env$get_position <- cedars.env$position

        updated(Sys.time())

    })

    observeEvent(eventExpr = input$delete_date, {

        cedars.env$adjudicated <- FALSE
        cedars.env$new_event_date <- "DELETE"
        cedars.env$get_position <- cedars.env$position

        updated(Sys.time())

    })

    observeEvent(eventExpr = input$id_search, {

        cedars.env$id_for_search <- input$search_patient_id
        if (cedars.env$id_for_search == "") cedars.env$id_for_search <- 0

        updated(Sys.time())

    })

    data <- eventReactive(eventExpr = updated(), {

        # Will not post if the "SEARCH" button was pressed
        if (is.na(cedars.env$id_for_search) & (!is.na(cedars.env$position) & (!is.na(cedars.env$new_event_date) | cedars.env$adjudicated == TRUE))) {

            if (cedars.env$g_ldap == TRUE) end_user_id <- session$user else end_user_id <- input$user_id
            post_wrapper(cedars.env$g_database, end_user_id, input$end_user_pw, cedars.env$position, cedars.env$new_event_date, input$input_comments, ldap = cedars.env$g_ldap)

        }

        updateDateInput(session = session, inputId = "event_date", value = NA)
        updateTextInput(session = session, inputId = "search_patient_id", value = NA)

        if (input$user_id != "" | cedars.env$g_ldap == TRUE) {

            if (cedars.env$g_ldap == TRUE) end_user_id <- session$user else end_user_id <- input$user_id

            output <- get_wrapper(cedars.env$g_database, end_user_id, input$end_user_pw, TRUE, cedars.env$get_position, cedars.env$id_for_search, ldap = cedars.env$g_ldap)
            cedars.env$id_for_search <- NA

            if (!(output[1] %in% c("error_0", "error_1", "error_2", "error_3", "error_4"))){

                # Resetting comments section
                if (is.null(output$pt_comments))  {

                    updateTextInput(session = session, inputId = "input_comments", value = NA)
                    output$pt_comments <- "none"

                } else {

                    updateTextInput(session = session, inputId = "input_comments", value = output$pt_comments)

                    if (gsub(" ", "", output$pt_comments) == "") output$pt_comments <- "none"

                }

                cedars.env$position <- output$unique_id
                cedars.env$max_position <- output$max_unique_id
                cedars.env$adjudicated <- FALSE
                if (length(output$event_date) == 0) output$event_date <- "none"
                if (is.na(output$event_date)) output$event_date <- "none"
                if (is.null(output$text_tag_1)) output$text_tag_1 <- "NA"
                if (is.null(output$text_tag_2)) output$text_tag_2 <- "NA"
                if (is.null(output$text_tag_3)) output$text_tag_3 <- "NA"
                if (is.null(output$text_tag_4)) output$text_tag_4 <- "NA"
                if (is.null(output$text_tag_5)) output$text_tag_5 <- "NA"
                if (is.null(output$text_tag_6)) output$text_tag_6 <- "NA"
                if (is.null(output$text_tag_7)) output$text_tag_7 <- "NA"
                if (is.null(output$text_tag_8)) output$text_tag_8 <- "NA"
                if (is.null(output$text_tag_9)) output$text_tag_9 <- "NA"
                if (is.null(output$text_tag_10)) output$text_tag_10 <- "NA"

                }

        } else {

            output <- list()
            output <- list()
            output$selected = output$pt_comments = output$note_text = output$event_date = output$text_date = output$patient_id = "no data"
            output$unique_id = output$max_unique_id = 0
            updateTextInput(session = session, inputId = "input_comments", value = NA)

        }

        if (output[1] == "error_0") {
            output <- list()
            output$selected = output$pt_comments = output$note_text = output$event_date = output$text_date = output$patient_id = "Incorrect credentials!"
            output$unique_id = output$max_unique_id = 0
        }

        if (output[1] == "error_1") {
            output <- list()
            output$selected = output$pt_comments = output$note_text = output$event_date = output$text_date = output$patient_id = "No records left to review!"
            output$unique_id = output$max_unique_id = 0
        }

        if (output[1] == "error_2") {
            output <- list()
            output$selected = output$pt_comments = output$note_text = output$event_date = output$text_date = output$patient_id = "No patient found with this ID!"
            output$unique_id = output$max_unique_id = 0
        }

        if (output[1] == "error_3") {
            output <- list()
            output$selected = output$pt_comments = output$note_text = output$event_date = output$text_date = output$patient_id = "Patient locked by another user!"
            output$unique_id = output$max_unique_id = 0
        }

        if (output[1] == "error_4") {
            output <- list()
            output$selected = output$pt_comments = output$note_text = output$event_date = output$text_date = output$patient_id = "No sentences to evaluate for this patient!"
            output$unique_id = output$max_unique_id = 0
        }

        output

    })

        output$selected_sentence <- renderText(data()$selected)
        output$pt_comments <- renderText(data()$pt_comments)
        output$selected_note <- renderText(data()$note_text)
        output$old_event_date <- renderText(data()$event_date)
        output$sentence_position <- renderText(paste("Position: ", data()$unique_id, " of ", data()$max_unique_id, sep=""))
        output$text_date <- renderText(paste("Note date: ", data()$text_date, sep=""))
        output$patient_id <- renderText(paste("Patient ID: ", data()$patient_id, sep=""))

        output$tags_table <- renderTable(data.frame(Tag_1 = data()$text_tag_1, Tag_2 = data()$text_tag_2, Tag_3 = data()$text_tag_3, Tag_4 = data()$text_tag_4, Tag_5 = data()$text_tag_5, Tag_6 = data()$text_tag_6, Tag_7 = data()$text_tag_7, Tag_8 = data()$text_tag_8, Tag_9 = data()$text_tag_9, Tag_10 = data()$text_tag_10))

        output$session_user <- renderText({session$user})

        output$display_logon <- renderText({!cedars.env$g_ldap})
        outputOptions(output, "display_logon", suspendWhenHidden = FALSE)

}


shinyApp(ui = ui, server = server)
