Overview
--------

CEDARS (Clinical Event Detection and Recording System) is a computational paradigm for collection and aggregation of time-to-event data in retrospective clinical studies. Born out of a practical need for a more efficient way to conduct medical research, it aims to systematize and accelerate the review of electronic health record (EHR) corpora. It accomplishes those goals by deploying natural language processing (NLP) as a tool to assist detection and characterization of clinical events by human abstractors. In its current iteration, CEDARS is avalaible as an open-source R package under [GPL-3 license](https://www.gnu.org/licenses/gpl-3.0.en.html).

Requirements
------------

R 3.5.0 or above and package dependencies<br>
RStudio<br>
MongoDB<br>
Unified Medical Language System (UMLS) MRCONSO.RRF file (desirable but not required)

CEDARS can be installed locally or on a server. In the latter case, Shiny Server (open source or commercial version) will be required. A business-grade server installation of MongoDB is vastly preferred, even if CEDARS is run locally. Because by definition CEDARS handles protected health information (PHI), special consideration should be given to ensure HIPAA (Health Insurance Portability and Accountability Act) compliance, including but not limited to using HTTPS, encryption at rest, minimum password requirements and limiting operation to within institutional firewalls where indicated. **CEDARS is provided as-is with no guarantee whatsoever and users agree to be held responsible for compliance with their local government/institutional regulations.** All CEDARS installations should be reviewed with institutional information security authorities.

The [UMLS](https://www.nlm.nih.gov/research/umls/index.html) is a rich compendium of biomedical lexicons. It is maintained by the National Institutes of Health (NIH) and requires establishing an account in order to access the associated files. Those files are not included with the CEDARS R package, but CEDARS is designed to use them natively so individual users can easily include them in their annotation pipeline. NegEx ([Chapman *et al*, Stud Health Technol Inform. 2013; 192: 677–681.](https://pubmed.ncbi.nlm.nih.gov/23920642/)) is included with CEDARS.

Basic Concepts
--------------

<img src="GitHub Schema 2 A new color.png" alt="alt text" width="500"/>


Operational Schema
------------------

<img src="GitHub Schema 1 B new color.png" alt="alt text" width="500"/>

CEDARS is modular and all information for any given annotation project is stored in one MongoDB database. User credentials, original clinical notes, NLP annotations and patient-specific information are stored in dedicated collections. Once clinical notes have been uploaded, they are passed through the NLP pipeline. Currently only UDPipe is supported and integrated with CEDARS. If desired, the annotation pipeline can include negation and medical concept tagging by NegEx and UMLS respectively.

Sample Code
-----------

The R CEDARS package includes a small simulated clinical notes corpus. This corpus is fictitious and does not contain information from real patients. Once access to MongoDB has been achieved, you can install and test drive CEDARS with the following code:

```R
# The code below creates an instance of CEDARS project, populated with fictitious EHR corpora.
# It runs in a local R session and requires credentials to a MongoDB database system, which can be run locally but usually on a separate server.

remotes::install_github("simon-hans/CEDARS")
library(CEDARS)

# Substitute your MongoDB credentials
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"

# Substitute path to the UDPipe NLP model file
# This file can be obtained from a central repository through the UDPipe package, or you can train your own model
# CEDARS was tested on the generic file
udmodel_path <- "C:/R/NLP_models/latestversion.udpipe"

# Everything else can be ran as is!

# Name for MongoDB database which will contain the CEDARS project
mongo_database <- "EXAMPLE"

# We create the database and all required collections
create_project(uri_fun, db_user_name, db_user_pw, db_host, mongo_database, "CEDARS Example Project", "Dr Smith")

# Adding one CEDARS end user
add_end_user(uri_fun, db_user_name, db_user_pw, db_host, mongo_database, "John", "strongpassword")

# Negex is included with CEDARS and required for assessment of negation
negex_upload(udmodel_path, uri_fun, db_user_name, db_user_pw, db_host, mongo_database)

# Uploading the small simulated collection of EHR corpora
upload_notes(uri_fun, db_user_name, db_user_pw, db_host, mongo_database, simulated_patients)

# Running the NLP annotations on EHR corpora
# We are only using one core, for large datasets parallel processing is faster
automatic_NLP_processor(NA, "latin1", "udpipe", udmodel_path, uri_fun, db_user_name, db_user_pw, db_host, mongo_database, max_n_grams_length = 0, negex_depth = 6, select_cores = 1)

# This is a simple query which will report all sentences with a word starting in "bleed" or "hem", or an exact match for "bled"
search_query <- "bleed* OR hem* OR bled"
use_negation <- TRUE
hide_duplicates <- TRUE
skip_after_event <- TRUE
save_query(uri_fun, db_user_name, db_user_pw, db_host, mongo_database, search_query, use_negation, hide_duplicates, skip_after_event)

# Starts the CEDARS GUI locally
# Your user name is "John", password is "strongpassword"
start_local(db_user_name, db_user_pw, db_host, mongo_database)

# Remove project from MongoDB
terminate_project(uri_fun, db_user_name, db_user_pw, db_host, mongo_database)
```

If your systems use a different MongoDB URI string standard, you will have to substitute your string-generating function.

Future Development
------------------

We are currently documenting the performance of CEDARS with a focus on oncology clinical research. At the present time, we wish to solidify the CEDARS user interface and ensure a smooth experience in multi-user settings. In the longer term, plug-in modules featuring enhanced query generation and adaptive learning will be integrated into the R workflow. Support for other NLP engines and extensive parallel processing are also desirable.

Please communicate with package author Simon Mantha, MD, MPH (<smantha@cedars.io>) if you want to discuss new features or using this software for your clinical research application.
