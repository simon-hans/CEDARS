# End User Manual

## Introduction

This short manual is intended for data abstractors who will enter information about clinical events detected by CEDARS.

CEDARS is a data pipepline set up to optimally present you with sentences drawn from a patient's medical record and potentially indicating the presence of a clinical event. Sentence detection is automatic and based on the words used, but often those sentences do not actually represent a true event. For example, the following sentence does not signal an actual new thrombotic episode:

"The patient was ruled-out for deep vein thrombosis last night."

If sentence detection is based only on reporting sentences with the words "deep vein thrombosis", such a negative finding will be reported. In this case, you would not report an event and move on to the next sentence. Event detection approaches used by your CEDARS system administrator will vary, and some queries will be more selective than others, but generally the system will be set up to detect as many events as possible, at the cost of having a certain number of false positive findings. The intent here is for CEDARS to minimize the number of missed events, even if this approach results in you having to review a greater number of sentences.

Sentences are presented in chronological order. Once you have identified and dated a clinical event, CEDARS might be set up by bypass all following sentences for this patient and move on to the next patient. This approach will be used when your system administrator only aims at capturing the first instance of an event of interest. Also, once you have evaluated all sentences of interest for a given patient, CEDARS will move on to the enxt patient seamlessly. This sequence of events is illustrated in the picture below:



## Login

### Using RStudio Connect

Using an internet browser, navigate to the web page provided by your CEDARS system administrator. Enter your user ID and password.

## Find Clinical Events

As soon as you are logged in, CEDARS will start looking for the next available patient with information to review. It might take a few moments before the first sentence is presented to you. The following is an example from a simulated cohort:

