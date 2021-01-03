

<!-- toc -->

January 02, 2021

# DESCRIPTION

```
Package: CEDARS
Title: Simple and Efficient Pipeline for Electronic Health Record Annotation
Version: 0.1
Authors@R: 
    person(given = "Simon",
           family = "Mantha",
           role = c("aut", "cre"),
           email = "smantha@cedars.io",
           comment = c(ORCID = "0000-0003-4277-5261"))
Description: Search EHR documents for keywords and UMLS concept ID's.
Depends: R (>= 3.5.0)
License: GPL-3
Encoding: UTF-8
LazyData: true
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.1.0
Imports:
  fastmatch,
  jsonlite,
  mongolite,
  parallel,
  readr,
  shiny,
  udpipe,
  utils```


# `add_end_user`: Add a CEDARS End User

## Description


 Adds an end user. Password must be at least 8 characters in length.


## Usage

```r
add_end_user(
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  end_user,
  end_user_password
)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```end_user```     |     CEDARS end user name.
```end_user_password```     |     CEDARS end user password.

## Examples

```r 
 list("\n", "add_end_user(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT', end_user = 'Mike',\n", "end_user_password = 'user_pw_5678')\n") 
 ``` 

# `aggregate_note`: Aggregate Contents of a Note

## Description


 When using atomized notes, this function 'pastes' back the different sections together in the intended order. Preselected lemmas are marked, along with those for which thr CUI is
 in the list of interest.


## Usage

```r
aggregate_note(selected_doc_id, annotations, cui_elements)
```


## Arguments

Argument      |Description
------------- |----------------
```selected_doc_id```     |     Document ID for the note to which the sentence belongs.
```annotations```     |     NLP annotations dataframe.
```cui_elements```     |     Vector of UMLS concept unique identifier (CUI) elements derived from the search query.

## Value


 Aggregated note in one text string.


# `automatic_NLP_processor`: Process NLP Annotations on the Current Patient Cohort

## Description


 Accepts a list of patient ID's or alternatively can perform NLP annotations on all available patients in the database.


## Usage

```r
automatic_NLP_processor(
  patient_vect = NA,
  text_format = "latin1",
  nlp_engine = "udpipe",
  URL,
  uri_fun = mongo_uri_standard,
  user,
  password,
  host,
  port,
  database,
  max_n_grams_length = 7,
  negex_depth = 6,
  select_cores = NA
)
```


## Arguments

Argument      |Description
------------- |----------------
```patient_vect```     |     Vector of patient ID's. Default is NA, in which case all available patient records will undergo NLP annotation.
```text_format```     |     Text format for NLP engine.
```nlp_engine```     |     Which NLP engine should be used? UDPipe is the only one supported for now.
```URL```     |     UDPipe model URL.
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```max_n_grams_length```     |     Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If 0 is chosen, UMLS CUI tags will not be provided.
```negex_depth```     |     Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
```select_cores```     |     How many CPU cores should be used for parallel processing? Max allowed is total number of cores minus one. If 1 is entered, parallel processing will not be used.

## Examples

```r 
 list("\n", "automatic_NLP_processor(patient_vect = NA, text_format = 'latin1', nlp_engine = 'udpipe',\n", "URL = 'models/english-ewt-ud-2.4-190531.udpipe', uri_fun = mongo_uri_standard, user = 'John',\n", "password = 'db_password_1234', host = 'server1234', port = NA, database = 'TEST_PROJECT',\n", "max_n_grams_length = 7, negex_depth = 6, select_cores = NA)\n") 
 ``` 

# `batch_processor_db`: Batch NLP Annotations for a Cohort

## Description


 NLP annotates documents for a cohort of patients, in parallel. Locks each record before proceeding with NLP annotations.


## Usage

```r
batch_processor_db(
  patient_vect,
  text_format,
  nlp_engine,
  URL,
  negex_simp,
  umls_selected,
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  max_n_grams_length,
  negex_depth,
  select_cores
)
```


## Arguments

Argument      |Description
------------- |----------------
```patient_vect```     |     Vector of patient ID's.
```text_format```     |     Text format.
```nlp_engine```     |     NLP engine, UDPipe only for now.
```URL```     |     UDPipe model URL.
```negex_simp```     |     Simplifed negex.
```umls_selected```     |     Processed UMLS table.
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```max_n_grams_length```     |     Maximum length of tokens for matching with UMLS concept unique identifiers (CUI's). Shorter values will result in faster processing. If ) is chosen, UMLS CUI tags will not be provided.
```negex_depth```     |     Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
```select_cores```     |     How many CPU cores should be used for parallel processing? Max allowed is total number of cores minus one. If 1 is entered, parallel processing will not be used.

# `colorize`: Highlight Keywords and Concepts

## Description


 Adds color and changes font to bold for selected strings of sentences and notes. The current method uses HTML.


## Usage

```r
colorize(get_output)
```


## Arguments

Argument      |Description
------------- |----------------
```get_output```     |     Dataframe with field 'selected', the latter containing text string corresponding to selected sentences.

## Value


 Text string with HTML markup.


# `commit_patient`: Select and Lock Patient Record

## Description


 Selects yet to be assessed patient with at least one positive sentence and locks record in DB for the CEDARS end user.


## Usage

```r
commit_patient(
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  end_user,
  search_query,
  use_negation,
  hide_duplicates,
  patient_id = NA
)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```end_user```     |     CEDARS end user name.
```search_query```     |     Medical corpus query containg keywords/CUI's, boolean elements and other operators ('AND', 'OR', '!', '(', or ')').
```use_negation```     |     Should negated items be ignored in the keyword/concept search?
```hide_duplicates```     |     Should duplicated sentences be removed for search results?
```patient_id```     |     Used if a specific patient record is requested, instead of a search for next record to annotate.

# `complete_case`: Mark a Case as Completed

## Description


 Once all sentences before a recorded event have been annotated by the end user, this functions marks patient record as 'reviewed'.


## Usage

```r
complete_case(uri_fun, user, password, host, port, database, selected_patient)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```selected_patient```     |     Selected patient.

# `create_project`: Create a New CEDARS Project

## Description


 Creates a new MongoDB database and collections needed for a CEDARS annotation project. The MongoDB account used must have sufficient privileges.


## Usage

```r
create_project(
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  project_name,
  investigator_name
)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```project_name```     |     Research or QA project name.
```investigator_name```     |     Investigator name.

## Examples

```r 
 list("\n", "create_project(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT', project_name = 'Test project',\n", "investigator_name = 'Dr Smith')\n") 
 ``` 

# `db_download`: Obtain Patient Notes

## Description


 Downloads the notes for one patient. If there are missing fields, those are created with NA values inserted.


## Usage

```r
db_download(uri_fun, user, password, host, port, database, patient_id)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```patient_id```     |     Patient ID for which notes are being requested.

## Value


 Dataframe of full notes and/or note parts with associated metadata.


# `db_upload`: Upload Annotations

## Description


 Uploads NLP annotations for one patient.


## Usage

```r
db_upload(
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  patient_id,
  annotations
)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```patient_id```     |     Patient ID.
```annotations```     |     NLP annotations.

# `delete_end_user`: Delete a CEDARS End USer

## Description


 Deletes one end user and associated password.


## Usage

```r
delete_end_user(uri_fun, user, password, host, port, database, end_user)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```end_user```     |     CEDARS end user name.

## Examples

```r 
 list("\n", "delete_end_user(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT', end_user = 'Mike')\n") 
 ``` 

# `document_processor`: Functions to process documents with NLP engine
 Process a Document

## Description


 Processes one EHR document with NLP pipeline and applies NegEx.


## Usage

```r
document_processor(
  text_df,
  text_format,
  nlp_engine,
  negex_simp,
  negex_depth,
  single_core_model = NA
)
```


## Arguments

Argument      |Description
------------- |----------------
```text_df```     |     Dataframe of 1 row, containing all text metadata, including: text_id, text_date, text_sequence, doc_section_name, doc_id, text_tag_1, text_tag_2, text_tag_3, text_tag_4, text_tag_5, text_tag_6, text_tag_7, text_tag_8, text_tag_9 and text_tag_10.
```text_format```     |     Text format.
```nlp_engine```     |     NLP engine, UDPipe only for now.
```negex_simp```     |     Simplified negex.
```negex_depth```     |     Maximum distance between negation item and token to negate. Shorter distances will result in decreased sensitivity but increased specificity for negation.
```single_core_model```     |     NLP model in case parallel processing is not used.

## Value


 NLP annotations dataframe.


# `.onLoad`: Load Options on Startup

## Description


 Disables scientific notation which can be a problem for large ID's.


## Usage

```r
.onLoad(libname, pkgname)
```


## Arguments

Argument      |Description
------------- |----------------
```libname```     |     Library name.
```pkgname```     |     Package name.

# `download_events`: Download Event Data

## Description


 Downloads patient event data. Typically done after all records have been annotated and the project is complete.


## Usage

```r
download_events(uri_fun, user, password, host, port, database)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "download_events(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA)\n") 
 ``` 

# `end_users`: Download End User List

## Description


 Downloads list of CEDARS end users along with their passwords.


## Usage

```r
end_users(uri_fun, user, password, host, port, database)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "end_users(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT')\n") 
 ``` 

# `fast_merge_umls`: Merge UMLS Tags

## Description


 Fast implementation of matching process to find UMLS concept unique identifiers (CUI's) corresponding to tokens from EHR documents.


## Usage

```r
fast_merge_umls(query_x, umls_selected, by_x, n_grams)
```


## Arguments

Argument      |Description
------------- |----------------
```query_x```     |     Vector of tokens to match.
```umls_selected```     |     UMLS dictionary.
```by_x```     |     Field name for tokens to match.
```n_grams```     |     Length of tokens to match.

## Value


 Tokens matched with a CUI.


# `format_keywords`: Format Keyword Elements

## Description


 Prepares keyword element vector, converting wildcards to Regex syntax. Wildcards include '?' for any single character and '*' for any number of characters including zero.


## Usage

```r
format_keywords(keyword_elements)
```


## Arguments

Argument      |Description
------------- |----------------
```keyword_elements```     |     Keywords.

## Value


 Formatted keywords.


# `get_data`: Get one Sentence for Review

## Description


 Gets one sentence, one note and date of note for one patient. Main way for an end user to query CEDARS.


## Usage

```r
get_data(
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  end_user,
  end_user_password,
  html = TRUE,
  position,
  patient_id = NA,
  ldap = FALSE
)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB server host.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```end_user```     |     CEDARS end user name.
```end_user_password```     |     CEDARS end user password.
```html```     |     Should output keywords/concepts be highlighted with HTML markup? Default is TRUE.
```position```     |     Sentence position within the sequence of selected sentences for a given patient.
```patient_id```     |     Used if a specific patient record is requested, instead of a search for next record to annotate.
```ldap```     |     Is LDAP authentication being used? If so, password will not be checked and access will be granted automatically.

## Value


 A list with patient-specific information and a dataframe with selected sentences along with sentence-specific data.


# `get_patient`: Retrieve Patient Data

## Description


 Retrieves annotated electronic health record sentences for one patient. Returns basic info, along with a dataframe containing sentences and corresponding notes.


## Usage

```r
get_patient(
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  end_user,
  search_query,
  use_negation,
  hide_duplicates,
  patient_id = NA
)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```end_user```     |     CEDARS end user name.
```search_query```     |     Medical corpus query containg keywords/CUI's, boolean elements and other operators ('AND', 'OR', '!', '(', or ')').
```use_negation```     |     Should negated items be ignored in the keyword/concept search?
```hide_duplicates```     |     Should duplicated sentences be removed for search results?
```patient_id```     |     Used if a specific patient record is requested, instead of a search for next record to annotate.

# `get_wrapper`: Wrap the get_data() Function

## Description


 Obtain one sentence and related info from MongoDB. Uses DB credentials pre-loaded in the main environment. For use with Shiny or REST GET (latter yet to be implemented).


## Usage

```r
get_wrapper(
  database,
  end_user,
  end_user_password,
  html = TRUE,
  position,
  patient_id = NA,
  ldap = FALSE
)
```


## Arguments

Argument      |Description
------------- |----------------
```database```     |     MongoDB database.
```end_user```     |     CEDARS end user name..
```end_user_password```     |     CEDARS end user password.
```html```     |     Should output keywords/concepts be highlighted with HTML markup? Default is TRUE.
```position```     |     Sentence position within the sequence of selected sentences for a given patient.
```patient_id```     |     Used if a specific patient record is requested, instead of a search for next record to annotate.
```ldap```     |     Is LDAP authentication being used? If so, password will not be checked and access will be granted automatically.

## Value


 A list with patient-specific information and a dataframe with selected sentences along with sentence-specific data.


## Examples

```r 
 list("\n", "get_wrapper(database = 'TEST_PROJECT', end_user = 'John', end_user_password = 'db_password_1234',\n", "html = TRUE, position = NA)\n") 
 ``` 

# `id_expander`: Expand ID's

## Description


 Duplicates paragraph or sentence ID's to help process negation based on negated token series.


## Usage

```r
id_expander(index, work_df, field)
```


## Arguments

Argument      |Description
------------- |----------------
```index```     |     Row position within annotations dataframe.
```work_df```     |     Working annotations dataframe.
```field```     |     Field to duplicate.

## Value


 Series of duplicated field values.


# `initialize_annotations`: Initialize Annotations
 Deletes all NLP annotations and patient-specific information, including clinical event dates.New, empty 'ANNOTATIONS' and 'PATIENTS' collections are created. Dictionaries and original patient notes are preserved.

## Description


 Initialize Annotations
 Deletes all NLP annotations and patient-specific information, including clinical event dates.New, empty 'ANNOTATIONS' and 'PATIENTS' collections are created. Dictionaries and original patient notes are preserved.


## Usage

```r
initialize_annotations(uri_fun, user, password, host, port, database)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "initialize_annotations(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT')\n") 
 ``` 

# `initialize_notes`: Initialize EHR Notes

## Description


 Deletes all patient notes from the database.


## Usage

```r
initialize_notes(uri_fun, user, password, host, port, database)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "initialize_notes(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT')\n") 
 ``` 

# `initialize_patients`: Initialize Patient List

## Description


 All patient-specific information is deleted, including clinical event dates. Original notes and NLP annotations are preserved.


## Usage

```r
initialize_patients(uri_fun, user, password, host, port, database)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "initialize_patients(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT')\n") 
 ``` 

# `initialize_users`: Initialize End User List

## Description


 Deletes all CEDARS end user credentials information.


## Usage

```r
initialize_users(uri_fun, user, password, host, port, database)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "initialize_users(uri_fun = mongo_uri_standard, user = 'John', password = 'db_password_1234',\n", "host = 'server1234', port = NA, database = 'TEST_PROJECT')\n") 
 ``` 

# `lemma_match`: Match Lemmas to Regex Keywords

## Description


 Matches lemmas in NLP annotations to keywords, considering Regex syntax.


## Usage

```r
lemma_match(annotations, keyword_elements)
```


## Arguments

Argument      |Description
------------- |----------------
```annotations```     |     Patient-specific NLP annotations.
```keyword_elements```     |     Keywords with Regex syntax.

## Value


 Annotations dataframe with one extra column.


# `lock_records`: Lock Record for one Patient

## Description


 Locks record for selected patient. The first available unreviewed, unlocked record is locked for the CEDARS end user.


## Usage

```r
lock_records(
  uri_fun,
  user,
  password,
  host,
  port,
  database,
  end_user,
  patient_id = NA
)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```end_user```     |     CEDARS end user name.
```patient_id```     |     Used if a specific patient record is requested, instead of a search for next record to annotate.

# `lock_records_admin`: Lock Record for Admin Work
 When tasks need to be performed by the CEDARS server, this functions locks one patient record at a time. The record is locked only if not already locked by a CEDARS end user. Admin lock and end user lock do not coexist.

## Description


 Lock Record for Admin Work
 When tasks need to be performed by the CEDARS server, this functions locks one patient record at a time. The record is locked only if not already locked by a CEDARS end user. Admin lock and end user lock do not coexist.


## Usage

```r
lock_records_admin(uri_fun, user, password, host, port, database, patient_id)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```patient_id```     |     Patient ID being locked.

# `mark`: Mark Tokens

## Description


 Marks tokens corresponding to keywords/CUI's so that they can be highlighted later.


## Usage

```r
mark(annotations, cui_elements)
```


## Arguments

Argument      |Description
------------- |----------------
```annotations```     |     NLP annotation dataframe.
```cui_elements```     |     Vector of search query CUI's.

## Value


 Full sentence with marked tokens.


# `mongo_connect`: Connect to MongoDB

## Description


 Basic function used by CEDARS to connect to MongoDB instance. Wraps mongo() from mongolite.


## Usage

```r
mongo_connect(uri_fun, user, password, host, port, database, mongo_collection)
```


## Arguments

Argument      |Description
------------- |----------------
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.
```mongo_collection```     |     MongoDB collection; if NA, will connect to DB itself.

# `mongo_uri_standard`: Prepare MongoDB URI string

## Description


 Formats the MongoDB URI string for use by package mongolite. In this case the 'standard' URI format is used. If a different format is to be used, the end user will have to write their own formatting function.


## Usage

```r
mongo_uri_standard(user, password, host, port = NA)
```


## Arguments

Argument      |Description
------------- |----------------
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.

## Value


 URI string.


## Examples

```r 
 list("\n", "mongo_uri_standard(user = 'John', password = 'db_password_1234', host = 'server1234', port = NA)\n") 
 ``` 

# `mrconso_upload`: Upload UMLS Dictionary

## Description


 Prepares and uploads UMLS MRCONSO.RRF file. This file is not included in the CEDARS package and can be obtained on the NIH web site at https://www.nlm.nih.gov/research/umls/index.html.


## Usage

```r
mrconso_upload(
  path,
  language = "ENG",
  subsets,
  max_grams = 7,
  uri_fun,
  user,
  password,
  host,
  port,
  database
)
```


## Arguments

Argument      |Description
------------- |----------------
```path```     |     Path to file MRCONSO.RRF.
```language```     |     Language of biomedical lexicon, default is English (ENG).
```subsets```     |     Character vector of lexicon subsets to retain. UMLS is quite large so most applications can use only a few lexicon subsets.
```max_grams```     |     Maximum length of token in grams. Tokens above the thresold length will not be retained. Empirically, a value of 7 suffices for most applications.
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "mrconso_upload(path = 'dictionaries/MRCONSO.RRF', language = 'ENG', subsets = c('SNOMEDCT_US',\n", "'MTHICD9', 'ICD9CM', 'ICD10', 'ICD10CM', 'DSM-5', 'MSH', 'RXNORM', 'NCI'), max_grams = 7,\n", "user = 'John', password = 'db_password_1234', host = 'server1234', port = NA,\n", "database = 'TEST_PROJECT')\n") 
 ``` 

# `mrrel_upload`: Upload UMLS Relationships

## Description


 Prepares and uploads UMLS MRREL.RRF file. This file is not included in the CEDARS package and can be obtained on the NIH web site at https://www.nlm.nih.gov/research/umls/index.html. It is very large and not currently used by CEDARS.


## Usage

```r
mrrel_upload(path, uri_fun, user, password, host, port, database)
```


## Arguments

Argument      |Description
------------- |----------------
```path```     |     Path to file MRREL.RRF.
```uri_fun```     |     Uniform resource identifier (URI) string generating function for MongoDB credentials.
```user```     |     MongoDB user name.
```password```     |     MongoDB user password.
```host```     |     MongoDB host server.
```port```     |     MongoDB port.
```database```     |     MongoDB database name.

## Examples

```r 
 list("\n", "mrrel_upload(path = 'dictionaries/MRREL.RRF', uri_fun = mongo_uri_standard, user = 'John',\n", "password = 'db_password_1234', host = 'server1234', port = NA, database = 'TEST_PROJECT')\n") 
 ``` 

# `negation_tagger`: Tag for Negation

## Description


 Processes and NLP annotation dataframe and tags negated words based on distance from negation item.


## Usage

```r
negation_tagger(annotated_text, negex_depth)
```


## Arguments

Argument      |Description
------------- |----------------
```annotated_text```     |     Dataframe of NLP annotations.
```negex_depth```     |     Maximum distance between word to label and negation term, before or after. Default is 6, as per original paper by Chapman et al.

## Value

