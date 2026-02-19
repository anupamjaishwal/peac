/*
* @author: Tamarack Consulting, Inc.
* @date: 05/29/2018
* @description: Trigger for InfoLease Book Requests.
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
*
*/

trigger TC_InfoLeaseBookRequest on InfoLease_Book_Request__e(after insert) {
    for (InfoLease_Book_Request__e ibrEvent : Trigger.new) {
        TC_InfoLeaseBookQueueable q = new TC_InfoLeaseBookQueueable(ibrEvent.Opportunity_Id__c);
        System.debug('TC_InfoLeaseBookQueueable >>> ' + System.enqueueJob(q));
    }
}