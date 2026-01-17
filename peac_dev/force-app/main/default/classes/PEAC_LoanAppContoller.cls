/****************************************************************************************************
 * Author:Rajesh Kumar(LTMindtree)
 * Description: This class is used for loan app controller
 * Created Date: 05/12/2025
 *****************************************************************************************************/
public without sharing class PEAC_LoanAppContoller {
    
    @AuraEnabled
    public static string deleteAttachment(String oppId, String attachmentId){
        try {
            
            delete [SELECT Id FROM Opportunity_Attachment__c  WHERE Id = :attachmentId];
            return getOppAttachments(oppId);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    public static String getOppAttachments(String opportunityId){
        List<Opportunity_Attachment__c> oppAttachmentsList = [SELECT Id, Name, Dealer_Doc_Type__c,Type__c, createdById FROM Opportunity_Attachment__c WHERE Opportunity__c = :opportunityId];
        return JSON.serialize(oppAttachmentsList, true);
    }
}