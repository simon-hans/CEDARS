# CEDARS Administrator Manual

## Getting Started

### Requirements

**CEDARS is provided as-is with no guarantee whatsoever and users agree to be held responsible for compliance with their local government/institutional regulations.** All CEDARS installations should be reviewed with institutional information security authorities.

CEDARS was tested on a desktop PC. R 3.5.0 or above and all dependency packages need to be installed:

fastmatch  
jsonlite  
mongolite  
parallel  
readr  
shiny  
udpipe  
utils  

RStudio is required to use the app locally and to publish it to RStudio Connect. A MongoDB installation is required to hold all the project data, preferably on a dedicated server.

Lastly, the Unified Medical Language System (UMLS) MRCONSO.RRF file is required for searches using Concept Unique Identifiers (CUI's). The [UMLS](https://www.nlm.nih.gov/research/umls/index.html) is a rich compendium of biomedical lexicons. It is maintained by the National Institutes of Health \(NIH\) and requires establishing an account in order to access the associated files. Those files are not included with the CEDARS R package, but CEDARS is designed to use them natively so individual users can easily include them in their annotation pipeline. 

NegEx \([Chapman _et al_, Stud Health Technol Inform. 2013; 192: 677–681.](https://pubmed.ncbi.nlm.nih.gov/23920642/)\) is included with CEDARS.

### System Architecture

![CEDARS Operational Schema](pics/GitHub%20Schema%201%20C%20blue.png)

The CEDARS app runs from within a Shiny instance. It is possible to use either RStudio Connect or alternatively a dedicated server running Shiny Server. The former is easy to use from RStudio desktop but requires an existing RStudio Connect installation within your organization, while the latter is typically more costly and labor intensive.

Users connect to the Shiny app by accessing a web URL provided by RStudio Connect or a web server on a dedicated Shiny Server installation. CEDARS performs the operations to pull data from the database, process it and present it to the end users. Data entered by users is processed by CEDARS and saved to the database. RStudio Connect and Shiny Server Pro allow for the automatic generation of multiple processes ("workers") when multiple end users access the app simultaneously, however this is rarely needed with CEDARS since in most implementations only a few abstractors (i.e. <5) will have access to the interface. In most cases, if pre-search is used (see below), CEDARS will run fairly quickly with 2 simultaneous users in a single-threaded setup.

CEDARS can handle authentication, but ideally this will be done by Active Directory through RStudio Connect. This approach ensures optimal integration with an organization's IT architecture.

### Installing CEDARS

#### CEDARS R Package Installation

From RStudio, and with the devtools package installed:

```r
devtools::install_github("simon-hans/CEDARS", upgrade="never")
```

This will install CEDARS on a desktop or server. In the case of RStudio Connect implementations, CEDARS will be automatically installed when uploading the app through RStudio.

## Project Execution

### Overview

Extracting clinical event dates with CEDARS is a simple, sequential process:

![Project Execution Overview](pics/GitHub%20Schema%204%20B.png)

### App Installation

The CEDARS package includes its data entry interface in the form of a Shiny app. However, additional information from the administrator is required for the app instance to connect with MongoDB, including:

database user ID and password  
host server and port (default is 27017)  
database name  
whether or not Active Directory will be used for user authentication  
destination path to save the app, mapped from the R working directory  

The function save_credentials() must be called to generate the app and associated Rdata file: 

```r
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB"
use_LDAP <- TRUE
app_path <- "Out/app"

save_credentials(db_user_name, db_user_pw, db_host, db_port, db_name, use_LDAP, app_path)
```

Both the app.R and db_credentials.Rdata files must be uploaded to the Shiny instance.

#### RStudio Connect App Upload

This option assumes you have an account with your institution's RStudio Connect service. From within RStudio, simply navigate to the folder where the app was saved and click on the app.R file. Click the "Publish to Server" icon, making sure both necessary files are included and hit "Publish".

#### RStudio Server App Upload

A discussion of the installation process and use of Shiny Server is beyond the scope of this manual; pertinent information can be found on the maker's [website](https://rstudio.com/products/shiny/download-server/). The CEDARS app.R and db_credentials.Rdata files should be uploaded to the desired app directory.

### Database Setup

Creating the database and populating it with data pertaining to the project occurs as follows:

![Preparing the Database](pics/GitHub%20Schema%203%20E.png)

#### Project Initialization

Each data collection task on a given cohort of patients is a distinct CEDARS "project" with its own MongoDB database including all collections needed to operate. Different projects cannot share the same database or collections. This encapsulation allows for reliable backup and deletion of project data upon completion, also avoiding data corruption due to cross-talk between different annotation tasks. Initialization is the process by which necessary collections are generated and populated with project-specific data.

The function create_project() generates a database which will hold all collections pertaining to the project. If the CEDARS project administrator has database creation privileges, a new MongoDB instance will be created and collections generated automatically. If database creation privileges have not been granted, it is possible to have the MongoDB administrator create the blank database. Once this is done, create_project() can be used to generate the collections:

```r
uri_fun <- mongo_uri_standard
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB"
project_name <- "CEDARS Example Project"
project_owner <- "Dr Smith"

create_project(uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name, project_name, project_owner)
```

If the option to use Active Directory was set to FALSE when creating the app, the add_end_user() function must be used to add end users (i.e. data abstractors) to the project:

```r
new_end_user <- "John"
new_end_user_pw <- "strongpassword"

add_end_user(uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name, new_end_user, new_end_user_pw)
```

#### Electronic Health Record Corpus Upload

Function upload_notes() is used to transfer the raw clinical corpus to the CEDARS database. This would typically consist of a collection of clinical notes or radiology reports formatted as a dataframe with the follwing fields:

"patient_id" Patient-specific unique identifier, typically a medical record number  
"text_id" Unique identifier for the text segment  
"text" Text segment, can be a whole note or a section, sub-section etc.       
"text_date" Date of the clinical encounter or radiology test  
"doc_id" Unique identifier or the document  
"text_sequence" Optional, if a document contains more than one text segment (each with a distinct text_id), this field indicates the order of the segments/sections  
"text_tag_1" Optional metadata, for example patient's name, medical professional name, note section name, etc.   
"text_tag_2" Optional metadata    
"text_tag_3" Optional metadata   
"text_tag_4" Optional metadata  
"text_tag_5" Optional metadata  
"text_tag_6" Optional metadata  
"text_tag_7" Optional metadata  
"text_tag_8" Optional metadata  
"text_tag_9" Optional metadata  
"text_tag_10" Optional metadata  

```r
# patient_notes previously generated by user

uri_fun <- mongo_uri_standard
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB"

upload_notes(uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name, patient_notes)
```

In a typical use case, there would be a large number of patients/notes located on a separate server, so a custom batch function to download notes and transfer to CEDARS one patient at a time would have to be devised, e.g.:

```r
for (i in 1:10000){
  
  recnum <- patient_list$recnum[i]
  
  download_notes <- sqlQuery(origin_db_rodbc, paste(c("SELECT * FROM CORE_DB WHERE RECNUM = \'", recnum), collapse=""))
  
  # convert field names and ensure their format is compliant with CEDARS

  if (length(download_notes[,1])>0){
    
    upload_notes(uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name, download_notes)
    
    print(paste("notes uploaded for patient #", i, sep=""))
    
  } else print(paste("no notes for patient #", i, sep=""))
  
}
```

#### Natural Language Processing Annotation

CEDARS uses the [UDPipe](https://cran.r-project.org/web/packages/udpipe/vignettes/udpipe-annotation.html) natural language processing (NLP) pipeline for paragraph/sentence boundary detection, tokenization, lemmatization, part-of-speech tagging and dependency parsing. The function automatic_NLP_processor() will assess the project for missing annotations and process documents as needed:

```r
uri_fun <- mongo_uri_standard
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB"
txt_format <- "latin1"

# Only UDPipe is supported for now
nlp_type <- "udpipe"

# Use your favorite model, can be standard issue or custom fitted
udmodel_path <- "C:/R/NLP_models/latestversion.udpipe"

# We are not using UMLS concept unique identifiers
max_n_grams <-  0 

# Negation will look up to 6 positions away from index token
neg_depth <- 6 

# CEDARS supports parallel processing
sel_cores <- 10

automatic_NLP_processor(NA, txt_format, nlp_type, udmodel_path, uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name, max_n_grams, neg_depth, sel_cores)
```

#### Event Pre-Loading

Sometimes a cohort of patients will already have been assessed with other methods and CEDARS is used as a redundant method to pick up any previously missed events. In this use case, a list of known clinical events with their dates will exist. This information can be loaded on CEDARS as a "starting point", so as to avoid re-discovering already documented events. The function upload_events() can be used to insert these data:

```r
# event_dates is dataframe with patient unique ID's and event dates
uri_fun <- mongo_uri_standard
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB"

upload_events(uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name, event_dates$patient_id, event_dates$event_date)
```

#### Search Query Definition

The CEDARS search query incorporates the following wildcards:

"?": for one character, for example "r?d" would match "red" or "rod" but not "reed"

"\*": for zero to any number of characters, for example "r*" would match "red", "rod", "reed", "rd", etc.

CEDARS also applies the following Boolean operators:

"AND": both conditions present
"OR": either present present
"!": negation, for example "!red" would only match sentences without the word "red"

Lastly, the "(" and ")" operators can be used to further develop logic within a query.

#### Pre-Search

Once NLP annotations are complete and the search query has been defined, if an end user logs into CEDARS the system will automatically start parsing the annotations for matches. However, depending on the frequency (density) of hits, it can take several seconds to find a sentence to present the end user with. This can impact user experience, especially in multi-user settings. Because of this aspect, ideally records should be pre-searched:

```r
uri_fun <- mongo_uri_standard
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB"

# All patient records will undergo a pre-search
record_vect <- NA

pre_search(record_vect, uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name)
```

The result is a shorter interface reaction time and more efficient data entry.

### Assessment of Clinical Events

The process by which human abstractors annotate patient records for events is described in the [End User Manual](CEDARS_end_user_manual.md).

### Dataset Download

Once there are no sentences left to review, event data can be obtained from the database with function download_events(). 

```r
uri_fun <- mongo_uri_standard
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB"

output <- download_events(uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name)
```

Detailed information is provided, including which sentences were reviewed.

### Audit

CEDARS is by definition semi-automated, and depending on the specific use case and search query some events might be missed. This problem should be quantified by means of a systematic, old-fashion review of randomly selected patients. Typically, at least 200 patients would be selected and their corpora reviewed manually for events. Alternatively, a different method (e.g. billing codes) could be used. This audit dataset should be overlapped with the CEDARS event table to estimate sensitivity of the search query in the cohort at large. If this parameter falls below the previously established minimum acceptable value, the search query scope should be broadened, followed by a database reset, uploading of previously identified events and a new human annotation pass, followed by a repeat audit.

### Project Termination

Once all events have been tallied and the audit results are satisfactory, if desired the CEDARS project database can be deleted from the MongoDB database. This is an irreversible operation:

```r
uri_fun <- mongo_uri_standard
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
db_port <- 27017
db_name <- "MyDB

terminate_project(uri_fun, db_user_name, db_user_pw, db_host, db_port, db_name)
```

## Function Reference

The full function reference can be found [here](https://cedars.io/docs/CEDARS.pdf). 
