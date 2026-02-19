/*
* @author: Tamarack Consulting, Inc.
* @date: 05/09/2018
* @description: Trigger for Aspire Submit Requests.
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
*
*/

trigger TC_AspireSubmitRequest on Aspire_Submit_Request__e(after insert) {
    for (Aspire_Submit_Request__e asrEvent : Trigger.new) {
        TC_AspireSubmitQueueable q = new TC_AspireSubmitQueueable(asrEvent.Opportunity_Id__c);
        System.debug('TC_AspireSubmitQueueable >>> ' + System.enqueueJob(q));
    }
}