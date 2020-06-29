Overview
--------

CEDARS (Clinical Event Detection and Recording System) is a computational paradigm for collection and aggregation of time-to-event data in retrospective clinical studies. Born out of a practical need for a more efficient way to conduct medical research, it aims to systematize and accelerate the review of electronic health record (EHR) corpora. It accomplishes those goals by deploying natural language processing (NLP) as a tool to assist detection and characterization of clinical events by human abstractors. In its current iteration, CEDARS is avalaible as an open-source R package under GPL-3 license.

Requirements
------------

R 3.5.0 and package dependencies
RStudio
MongoDB

CEDARS can be installed locally or on a server. In the latter case, Shiny Server (open source or commercial version) will need to be installed. A business-grade server installation of MongoDB is vastly preferred, even if CEDARS is run locally. Because by definition CEDARS handles protected health informsation (PHI), special consideration should be given to ensure HIPAA (Health Insurance Portability and Accountability Act) compliance, including but not limited to using HTTPS, at-rest encryption, minimum password requirements and limiting operation to within institutional firewalls when indicated. **CEDARS is provided as-is with no guarantee whatsoever and users agree to be held responsible for compliance with their local government/institutional regulations.** All CEDARS installations should be reviewed with institutional information security authorities.
