public class TC_OpportunityAttachmentHelper {

    public static void sendStatementsOnBaseURLToCC (Map <Id, Opportunity_Attachment__c> newMap) {
    /*
        // no bulk processing, becuase only one file can be uploaded at a time
        if (!newMap.values ().isEmpty () && newMap.values ().size () > 1) {
        
            Opportunity_Attachment__c att = newMap.values ()[0];

            if (att.Type__c != null && att.Type__c.contains ('Bank Statement')) System.enqueueJob(new TC_OnBaseToCC (att));

        }*/
        
    }

//    public static void sendPKNumberToCC (Map <Id, Opportunity_Attachment__c> newMap) {
//        if (!newMap.values().isEmpty() && newMap.values().size() == 1){
//            if (newMap.values()[0].Opportunity__c != null){
//                String id = newMap.values()[0].Opportunity__c;
//                Opportunity opp = [SELECT Id, CaseCenter__c, PK__c FROM Opportunity WHERE Id = :id LIMIT 1][0];
//
////                MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus(opp.Id, opp.CaseCenter__c);
//
//            }
//
//        }
//
//    }

    public static void deleteOldAttachments(List<Opportunity_Attachment__c> onBaseAttachments) {

        Set<Id> oppIds = new Set<Id>();
        Set<String> attachmentNames = new Set<String>();
        for (Opportunity_Attachment__c onBaseAttachment : onBaseAttachments) {
            oppIds.add(onBaseAttachment.Opportunity__c);
            attachmentNames.add(onBaseAttachment.Name);
        }

        List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId IN :oppIds AND Name IN :attachmentNames];
        if (!attachments.isEmpty()) {
            delete attachments;
        }
    }
    
    public static void onBaseUploadNotification(List<Opportunity_Attachment__c> lstOnBaseAtt){
        Set<Id> attId = new Set<Id>();
        
        for (Opportunity_Attachment__c onBaseAttachment : lstOnBaseAtt) {
            
            attId.add(onBaseAttachment.Id);
        }
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Opportunity_Attachment__c> attachments = [SELECT Id,Opportunity__r.OwnerId,Opportunity__r.Assign_To_CMS_User__c,Opportunity__r.Assign_To_CMS_User__r.Email,Opportunity__r.Assign_To_CMS_User__r.arxxusleadassig__Available__c,Opportunity__r.Assign_To_CMS_User__r.OutOfOfficeMessage, Opportunity__r.Application__c,Opportunity__r.StageName,Opportunity__r.Probability,CreatedById,Opportunity__r.Owner.Email FROM Opportunity_Attachment__c WHERE Id IN : attId];
        for (Opportunity_Attachment__c onBaseAttachment : attachments) {
            if(onBaseAttachment.Opportunity__r.Probability >= 75 && onBaseAttachment.Opportunity__r.Probability < 93 && onBaseAttachment.Opportunity__r.Assign_To_CMS_User__c != null){
                if(onBaseAttachment.Opportunity__r.OwnerId == onBaseAttachment.CreatedById ){
                    Messaging.SingleEmailMessage objSingleEmail = new Messaging.SingleEmailMessage();
                    String[] toEmail = new List<String>();
                    if(!onBaseAttachment.Opportunity__r.Assign_To_CMS_User__r.arxxusleadassig__Available__c){
                        toEmail.add(onBaseAttachment.Opportunity__r.Assign_To_CMS_User__r.Email);
                        objSingleEmail.toaddresses = toEmail;
                        objSingleEmail.setSubject('Sales Doc Uploaded ' +onBaseAttachment.Opportunity__r.Application__c);
                        objSingleEmail.setPlainTextBody('Sales uploaded a document to this Opportunity to OnBase. Please review ASAP.');
                        mails.add(objSingleEmail);
                    }else{
                        toEmail.add(onBaseAttachment.Opportunity__r.Owner.Email);
                        objSingleEmail.toaddresses = toEmail;
                        objSingleEmail.setSubject('Assign To CMS User is Out Of Office for Application'+onBaseAttachment.Opportunity__r.Application__c);
                        if(String.isNotBlank(onBaseAttachment.Opportunity__r.Assign_To_CMS_User__r.OutOfOfficeMessage)){
                            objSingleEmail.setPlainTextBody(onBaseAttachment.Opportunity__r.Assign_To_CMS_User__r.OutOfOfficeMessage);
                        }else{
                            objSingleEmail.setPlainTextBody('Assign To CMS User is Out Of Office ');
                        }
                        
                        mails.add(objSingleEmail);
                    }
                    
                }
            }
        }
        System.debug('mails---'+mails);
        Messaging.sendEmail(mails);
        
        
    }

  public static void onBeforeInsert(List<Opportunity_Attachment__c> lstNewOppAttachment){
    for(Opportunity_Attachment__c oppAtt : lstNewOppAttachment){
      System.debug('Oattachment onBeforeInsert' + oppAtt.Dealer_Doc_Type__c);
      if(oppAtt.Dealer_Doc_Type__c != null){
        dealerDocTypeToTypeField(oppAtt);
      }
    }
  }

  public static void onBeforeUpdate(Map<Id, Opportunity_Attachment__c> mapNewOppAttachment, Map<Id, Opportunity_Attachment__c> mapoldOppAttachment){
    for(Opportunity_Attachment__c oppAtt : mapNewOppAttachment.values()){
    System.debug('Oattachment onBeforeUpdate' + oppAtt.Dealer_Doc_Type__c);

      Opportunity_Attachment__c oldOppAtt = mapoldOppAttachment.get(oppAtt.Id);
      if(oppAtt.Dealer_Doc_Type__c != oldOppAtt.Dealer_Doc_Type__c){
        dealerDocTypeToTypeField(oppAtt);
      }
    }
  }

  private static void dealerDocTypeToTypeField(Opportunity_Attachment__c oppAtt){
    oppAtt.Type__c = oppAtt.Dealer_Doc_Type__c;
  }
}