# CEDARS User Manual

## Getting Started

### Requirements

CEDARS was tested on a desktop PC. All dependency packages need to be installed.

### System Architecture

### Installing CEDARS

## CEDARS R Package on Desktop Installation

## CEDARS App Server Installation

## CEDARS App RStudio Connect Installation

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
