# Background

CEDARS \(Clinical Event Detection and Recording System\) is a computational paradigm for collection and aggregation of time-to-event data in retrospective clinical studies. Developed out of a practical need for a more efficient way to conduct medical research, it aims to systematize and accelerate the review of electronic health record \(EHR\) corpora. It accomplishes those goals by deploying natural language processing \(NLP\) as a tool to assist detection and characterization of clinical events by human abstractors. In its current iteration, CEDARS is available as an open-source R package under [GPL-3 license](https://www.gnu.org/licenses/gpl-3.0.en.html). The latest stable package can be downloaded from [CRAN](https://cran.r-project.org/web/packages/CEDARS/index.html) and the most recent development version can be cloned from [GitHub](https://github.com/simon-hans/CEDARS). Full documentation is available [here](https://docs.cedars.io).

# Requirements

R 3.5.0 or above and package dependencies  
 RStudio  
 MongoDB  
 Unified Medical Language System \(UMLS\) MRCONSO.RRF file \(desirable but not required\)

CEDARS can be installed locally or on a server. In the latter case, Shiny Server \(open source or commercial version\) will be required. A business-grade server installation of MongoDB is vastly preferred, even if CEDARS is run locally. Because by definition CEDARS handles protected health information \(PHI\), special consideration should be given to ensure HIPAA \(Health Insurance Portability and Accountability Act\) compliance, including but not limited to using HTTPS, encryption at rest, minimum password requirements and limiting operation to within institutional firewalls where indicated. **CEDARS is provided as-is with no guarantee whatsoever and users agree to be held responsible for compliance with their local government/institutional regulations.** All CEDARS installations should be reviewed with institutional information security authorities.

The [UMLS](https://www.nlm.nih.gov/research/umls/index.html) is a rich compendium of biomedical lexicons. It is maintained by the National Institutes of Health \(NIH\) and requires establishing an account in order to access the associated files. Those files are not included with the CEDARS R package, but CEDARS is designed to use them natively so individual users can easily include them in their annotation pipeline. NegEx \([Chapman _et al_, Stud Health Technol Inform. 2013; 192: 677–681.](https://pubmed.ncbi.nlm.nih.gov/23920642/)\) is included with CEDARS.

# Basic Concepts

![CEDARS Workflow](docs/pics/GitHub%20Schema%202%20C.png)

Sentences with keywords or concepts of interest are presented to the end user one at a time and in chronological order. The user assesses each sentence, determining whether or not a clinical event is being reported. The whole note or report drawn from the EHR is available for review in the GUI. If no event is declared in the sentence, CEDARS presents the next sentence for the same patient \(\#1\). If an event date is entered, CEDARS moves to the next unreviewed sentence before the event date. If there are no sentences left to review before the event, the GUI moves to the next patient \(\#2\) and the process is repeated with the following record \(\#3 and \#4\), until all selected sentences have been reviewed.

In order for CEDARS to be sufficiently sensitive and not miss and unacceptable number of clinical events, the keyword/concept search query must be well thought and exhaustive. The performance of CEDARS will vary by medical area, since the extent of medical lexicon will vary substantially between event types.

# Operational Schema

![CEDARS Operational Schema](docs/pics/GitHub%20Schema%201%20C%20blue.png)

CEDARS is modular and all information for any given annotation project is stored in one MongoDB database. User credentials, original clinical notes, NLP annotations and patient-specific information are stored in dedicated collections. Once clinical notes have been uploaded, they are passed through the NLP pipeline. Currently only UDPipe is supported and integrated with CEDARS. If desired, the annotation pipeline can include negation and medical concept tagging by NegEx and UMLS respectively.

Multiple users can load the web GUI and annotate records at the same time. Once accessed, a given patient record is locked for the user.

# Sample Code

The R CEDARS package includes a small simulated clinical notes corpus. This corpus is fictitious and does not contain information from real patients. Once access to MongoDB has been achieved, you can install and test drive CEDARS with the following code:

```r
Sys.unsetenv("GITHUB_PAT")
devtools::install_github("simon-hans/CEDARS", upgrade="never")

# Loading required packages

library(CEDARS)
library(readr)

# The code below creates an instance of CEDARS project on a public test MongoDB
# cluster, populated with fictitious EHR corpora.

# MongoDB credentials
uri_fun <- mongo_uri_standard
user <- "testUser"
password <- "testPW"
host <- "cedars.yvjp6.mongodb.net"
project_user_name_pw <- "pwdpwd123"
project_user_name <- "proj_user"
replica_set <- NA
port <- NA
database <- find_project_name()
project_name <- "external_proj"
investigator <- "scott"

# Generate app
# Create directory to save RConnect app
# This app will need to be uploaded to a shiny server
# The app then generates a GUI to enter annotations,
# accesses MongoDB in the background

if (!dir.exists("app")) dir.create("app")


# Initialize CEDARS project

create_project(uri_fun, user, password, host, replica_set,
               port, database, project_name, investigator)


# Separate access if LDAP not used
# Rarely use if ever

add_end_user(uri_fun, user, password, host, replica_set, port,
             database, project_user_name, project_user_name_pw)


# Upload NegEx
# If udpipe model not in your R install, will download and save main english one

negex_upload(uri_fun, user, password, host, replica_set, port, database)


# Generate search query

search_query <- "bleed* OR hem* OR bled"

use_negation <- TRUE
hide_duplicates <- TRUE
skip_after_event <- TRUE

tag_query <- list(exact = FALSE, nlp_apply = FALSE, include = NA, exclude = NA)

save_query(uri_fun, user, password, host, replica_set,
           port, database, search_query, use_negation,
           hide_duplicates, skip_after_event, tag_query)


# Uploading EMD documents, i.e. clinical notes and radiology reports

# for reading a csv file use read_csv
# EMR_docs <- read_csv("data/simulated_patients.csv")  # Use for CSV files

load("data/simulated_patients.RData")
EMR_docs <- as.data.frame(simulated_patients)

id_list <- unique(EMR_docs$patient_id)

for (i in 1:length(id_list)){

  patient_id_instance <- id_list[i]
  documents <- subset(EMR_docs, patient_id == patient_id_instance)
  upload_notes(uri_fun, user, password, host, replica_set,
               port, database, documents)
  print(paste("documents uploaded for patient #", i, sep=""))

}


# Generate NLP annotations

automatic_NLP_processor(patient_vect = NA, text_format = "latin1",
                        nlp_engine = "udpipe", uri_fun = mongo_uri_standard,
                        user, password, host, replica_set, port,
                        database, max_n_grams_length = 0, negex_depth = 6)


# Performing search to speed up process later on
# Documents/sentences with matching keywords of interest
# are selected and prepped for annotation

pre_search(patient_vect = NA, uri_fun, user, password,
           host, replica_set, port, database)


# Upload Shiny app on RConnect/locally and have annotator(s) do the work!
# use project_user_name and project_user_name_pw to login in the UI

start_local(user, password, host, replica_set, port, database)

# Once human annotator has completed work on GUI, download events

output <- download_events(uri_fun, user, password, host, replica_set,
                          port, database, dates = TRUE, sentences_only = FALSE)


# Delete project
# This is irreversible!

terminate_project(uri_fun, user, password, host, replica_set,
                  port, database, fast=TRUE)

```

If your systems use a different MongoDB URI string standard, you will have to substitute your string-generating function.

# Future Development

We are currently documenting the performance of CEDARS with a focus on oncology clinical research. At the present time, we wish to solidify the CEDARS user interface and ensure a smooth experience in multi-user settings. In the longer term, plug-in modules featuring enhanced query generation and adaptive learning will be integrated into the R workflow. Support for other NLP engines and extensive parallel processing are also desirable.

Please communicate with package author Simon Mantha, MD, MPH \([smantha@cedars.io](mailto:smantha@cedars.io)\) if you want to discuss new features or using this software for your clinical research application.

