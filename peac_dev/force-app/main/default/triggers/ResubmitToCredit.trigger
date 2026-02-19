trigger ResubmitToCredit on Resubmission_to_Credit_Details__c (before insert) {
    //https://marlinbusiness.atlassian.net/browse/SAL-2048
    if (Trigger.isInsert && Trigger.isBefore) 
        ResubmitToCreditHelper.validateReSubmit(Trigger.New);
}