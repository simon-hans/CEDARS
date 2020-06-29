Overview
--------

CEDARS (Clinical Event Detection and Recording System) is a computational paradigm for collection and aggregation of time-to-event data in retrospective clinical studies. Born out of a practical need for a more efficient way to conduct medical research, it aims to systematize and accelerate the review of electronic health record (EHR) corpora. It accomplishes those goals by deploying natural language processing (NLP) as a tool to assist detection and characterization of clinical events by human abstractors. In its current iteration, CEDARS is avalaible as an open-source R package under GPL-3 license.

Requirements
------------

R 3.5.0 and package dependencies<br>
RStudio<br>
MongoDB
Unified Medical Language System (UMLS) MRCONSO.RRF file (desirable but not required)

CEDARS can be installed locally or on a server. In the latter case, Shiny Server (open source or commercial version) will be required. A business-grade server installation of MongoDB is vastly preferred, even if CEDARS is run locally. Because by definition CEDARS handles protected health informsation (PHI), special consideration should be given to ensure HIPAA (Health Insurance Portability and Accountability Act) compliance, including but not limited to using HTTPS, encryption at rest, minimum password requirements and limiting operation to within institutional firewalls when indicated. **CEDARS is provided as-is with no guarantee whatsoever and users agree to be held responsible for compliance with their local government/institutional regulations.** All CEDARS installations should be reviewed with institutional information security authorities.

The [UMLS](https://www.nlm.nih.gov/research/umls/index.html) is a rich compendium of biomedical lexicons. It is maintained by the National Institutes of Health and requires establishing an account in order to access the associated files. Those files are not included with the CEDARS R package, but CEDARS is designed to use them natively so individual users can easily include them in their annotation pipeline. NegEx ([Chapman *et al*, Stud Health Technol Inform. 2013; 192: 677–681.](https://pubmed.ncbi.nlm.nih.gov/23920642/) is included with CEDARS.

Operational Schema
------------------

(pic)

CEDARS is modular and all information for any given annotation project is stored in one MongoDB database. User credentials, original clinical notes, NLP annotations and patient-specific information are stored in dedicated collections. Once clinical notes have been uploaded, they are passed through the NLP pipeline. Currently only UDPipe is supported and integrated with CEDARS. If desired, the annotation pipeline will include medical negation by means of NegEx and UMLS concept unique identifier (CUI) tags.

Sample Code
-----------

The R CEDARS package includes a small simulated clinical notes corpora. This corpora is fictitious and does not contain information from real patients. Once access to MongoDB has been achieved, you can install and test drive CEDARS with the following code:

```R
# Substitute your credentials
db_user_name <- "myname"
db_user_pw <- "mypassword"
db_host <- "myserver"
```

If your systems use a different MongoDB URI string standard, you will have to substitute your string-generating function.

Future Development
------------------

We are currently documenting the performance of CEDARS with a focus on oncology clinical research. At the present time, we wish to solidify the CEDARS user interface and ensure a smooth experience in multi-user settings. In the longer term, plug-in modules featuring enhanced query generation and adaptive learning will be integrated into the R workflow. Support for other NLP engines and extensive parallel processing are also desirable.

Please communicate with package author Simon Mantha MD MPH if you want to discuss new features or using this software for your clinical research application.
