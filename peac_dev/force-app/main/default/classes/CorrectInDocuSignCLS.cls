public class CorrectInDocuSignCLS {
    public String recordId;
    @auraEnabled
    public static dsfs__DocuSign_Status__c getCorrectInDocuSignBtn(id docuId){
        //recordId = apexpages.currentPage().getparameters().get('id');
        list<dsfs__DocuSign_Status__c> docStatus = [select id,dsfs__Envelope_Status__c,dsfs__DocuSign_Envelope_ID__c from dsfs__DocuSign_Status__c where id =:docuId];
        return docStatus[0];
    }
}