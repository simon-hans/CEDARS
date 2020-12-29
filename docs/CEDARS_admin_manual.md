# CEDARS Administrator Manual

## Getting Started

### Requirements

CEDARS is provided as-is with no guarantee whatsoever and users agree to be held responsible for compliance with their local government/institutional regulations. All CEDARS installations should be reviewed with institutional information security authorities.

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

The CEDARS app runs from within a Shiny instance. It is possible to use either a dedicated server running Shiny Server or RStudio Connect. The former is typically more costly and labor intensive, the latter is easy to use from RStudio desktop but requires an existing RStudio Connect installation within your organization.

Users connect to the Shiny app by accessing a web URL

### Installing CEDARS

## CEDARS R Package on Desktop Installation

## CEDARS App Server Installation

## CEDARS App RStudio Connect Installation

## Overview of Project Execution

Extracting clinical events dates with CEDARS is a simple, sequential process:

![Project Execution Overview](pics/GitHub%20Schema%204%20A.png)

## Database Setup

Creating the database and populating it with data pertaining to the project occurs as follows:

![Preparing the Database](pics/GitHub%20Schema%203%20E.png)

### Initializing a Project

Each data collection task on a given cohort of patients is a distinct CEDARS "project" with its own MongoDB database with all collections needed to operate. Different projects cannot share the same database or collections. This encapsulation allows for reliable backup and deletion of project data upon completion, also avoiding data corruption due to cross-talk between different annotation tasks.

Initialization is the process by which necessary collections are generated and populated with project-specific data. Once initialization is complete, data entry by human observers can start.

## Creating MongoDB Collections

The function create_project() generates a database which will hold all collections pertaining to the project. If the CEDARS project administrator has database creation privileges, a new MongoDB instance will be created and collections generated automatically. If database creation privileges have not been granted, it is possible to have the MongoDB administrator create the blank database. Once this is done, create_project() can be used to generate the collections.

## Adding End Users

The add_end_user() function adds an end user (i.e. data abstractor) to the project. This will be done with CEDARS from the R console only if not using another authentication system, e.g. Active Directory with RStudio Connect.

## Building the Search Query

The CEDARS search query incorporates the following wildcards:

"?": for one character, for example "r?d" would match "red" or "rod" but not "reed"

"\*": for zero to any number of characters, for example "r*" would match "red", "rod", "reed", "rd", etc.

CEDARS also applies the following Boolean operators:

"AND": both conditions present
"OR": either present present
"!": negation, for example "!red" would only match sentences without the word "red"

Lastly, the "(" and ")" operators can be used to further develop logic within a query.

## Preparing Data for Event Detection

### Transferring Electronic Medical Record Corpora

### Performing NLP Annotations

### Generating and Installing the Shiny App

### Pre-Searching Records

## Entering Event Data

### Login

### Flow of Information

### Overview of CEDARS Interface

### Moving Between Sentences

### Assessing a Negative Sentence

### Entering, Correcting or Deleting an Event Date

### Entering a Comment

### Marking a Record for Review

### Searching for a Specific Patient

### Record Locking

Once an end user accesses a patient corpora, this record is locked and cannot be modified by other users until it is released. Release occur automatically after 24 hours of inactivity, or if the user access another corpora.



### 
