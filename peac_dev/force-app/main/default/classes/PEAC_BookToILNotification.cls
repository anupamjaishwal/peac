/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to handle Asset trigger
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Feb-02-2026
**************************************************************************************************************/
public class PEAC_BookToILNotification {
    //SAL-5692 Expo: Opp Refactor - To send an email when opportunity is booked in InfoLease
    public static void sendBookToILConfn(List<Opportunity> newList, Map <Id, Opportunity> oldMap) {
        for (Opportunity opp : newList) {
            if(System.UserInfo.getUserName().contains(System.Label.PEAC_DataLoaderUser) || test.isRunningTest()){
                List<EmailTemplate> confnILTempList = new List<EmailTemplate>();
                if((opp.Application_Status__c != ((Opportunity)oldMap.get(opp.Id)).Application_Status__c && opp.Application_Status__c != null 
                    && (opp.Contract__c != ((Opportunity)oldMap.get(opp.Id)).Contract__c && opp.Contract__c != null))){
                        if(opp.Opportunity_Booked_Date__c == null){
                            opp.Opportunity_Booked_Date__c = System.now();
                        }
                        if(opp.Booked_Amount__c == null){
                            opp.Booked_Amount__c = opp.Equipment_Cost__c;
                        }
                        opp.Booked_to_External_System_Date__c = System.now();
                        confnILTempList = [SELECT Id FROM EmailTemplate WHERE Name = 'PEAC_OpportunityBookedToInfoLease' LIMIT 1];
                        if(!confnILTempList.isEmpty() && !Test.isRunningTest())
                        {
                            sendEmailNotification(opp.Id, confnILTempList[0].Id, opp.Booked_to_External_System_User__c);    
                        }
                    }else if(opp.Book_to_InfoLease_Error__c != ((Opportunity)oldMap.get(opp.Id)).Book_to_InfoLease_Error__c && opp.Book_to_InfoLease_Error__c != null){
                        confnILTempList = [SELECT Id FROM EmailTemplate WHERE Name = 'PEAC_OpportunityBookToInfoLeaseFailed' LIMIT 1];
                        if(!confnILTempList.isEmpty() && !Test.isRunningTest())
                        {
                            sendEmailNotification(opp.Id, confnILTempList[0].Id, opp.Booked_to_External_System_User__c);    
                        }
                    }
            }
        }
    }
    
    @future
    public static void sendEmailNotification(Id oppId, String templateId, String toAddress){
        
        if(String.isBlank(toAddress)){
            return;
        }
        List<contact> conList = [SELECT ID FROM Contact LIMIT 1];
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateId, conList[0].Id, oppId);
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(toAddress);
        mail.setWhatId(oppId);
        mail.setSaveAsActivity(false);
        if(!test.isRunningTest() && !conList.isEmpty()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});   
        }   
        
    }
    
    
}