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


Keywords or concepts are highlighted in red to help you located them in the text.

### Evaluating a Sentence

Typically you will be able to make up your mind just by reading the sentence itself. If the sentence is ambiguous and you would like to obtain more context, the note or report from which the sentence was drawn is presented in its entirety at the bottom of the screen under the section "Selected note:".

### Annotating a Negative Sentence

In many cases, the sentence you are looking at will be a false positive, i.e. it does not represent the kind of event you were tasked to report. In this case, simply click on the button "ADJUDICATE SENTENCE". This will mark the sentence as such and move to the next one in line.

### Move Between Sentences Within a Patient's Record

Often the sentence and note presented to you will hint at a possible event but remain ambiguous, or an event will be obvious but the timing unclear. In such cases, you can move from sentence to sentence by using the "<<< PREVIOUS" and "NEXT >>>" buttons. You will go from sentence to sentence, following the timeline of electronic record notes/reports. Note that using previous/next will not annotate sentences or otherwise enter information in the CEDARS database.

## Entering Information About a Patient

### Entering an Event Date

Once you have ascertained the timing of a clinical event, click on the data entry field under the "ENTER NEW DATE" button. You will be prompted with a calendar. Once the date displayed is correct, press on button "ENTER NEW DATE".

### Deleting an Event Date

It is possible to replace an erroneous date by entering a new one in the date entry field. If there was actually no event, the previously entered date can be deleted by clicking on button "DELETE OLD DATE".

### Entering Comments About a Patient

At any point you can enter comments about a patient, however those will be saved only if you 1) adjudicate the sentence or 2) enter an event date.

## Search for a Specific Patient

If you want to go back to a specific patient later on, take note of the patient ID number. CEDARS will automatically present you for the next available patient to review, so if you have already annotated all sentences for a given patient, the only way to find that record again is to do a search. In this case, simply enter the patient ID number under in the box under "Search for patient" and click button "SEARCH".

## Record Locking

Only one end user can access a specific patient in the CEDARS database. If someone else is already looking at a given patient, you will be locked from accessing it.
