public without sharing class SL_DocGenController {
  private static final String primaryRole = 'Primary Contact';

   @AuraEnabled
   public static List<Contact> getContacts(String accountId){
      List<Contact> dealerCont = new List<Contact>();
      dealerCont = [Select Id, Name, Email from Contact WHERE AccountId = :accountId /*OwnerId=:UserInfo.getUserId()*/] ;
      return dealerCont;
   }

   @AuraEnabled(cacheable=true)
   public static Opportunity getOppInfo(String recordId){
      try {
         Opportunity opp = [SELECT id, Application_Status__c,
         Primary_Contact__r.FirstName, Primary_Contact__r.LastName, 
         Primary_Contact__r.Name, Primary_Contact__r.Email, Primary_Contact__c, 
         Private_Label_Documents__c,Branch__c, Amount,Payment_Amount__c, AccountId, Equipment_Cost__c  
         FROM Opportunity where Id=:recordId];
         return opp;
       } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
   }

   @AuraEnabled(cacheable=true)
   public static String getInstance(){
      Organization o=[SELECT InstanceName FROM Organization  WHERE Id = :UserInfo.getOrganizationId()];
      return o.InstanceName;
   }

   @AuraEnabled
   public static Boolean isOppValid(String recordId){
         List<Asset__c> assets=[select ID from Asset__c  where Opportunity__c =:recordId and Equipment_Code__c like 'Titled Vehicle%'];
         return assets.size()==0;
   }
   @AuraEnabled
   public static Boolean isStateValid(String recordId){
        Opportunity opp=[SELECT Account_Billing_State_Province__c, Purchase_Options__c FROM Opportunity  WHERE Id =:recordId];
       String state=opp.Account_Billing_State_Province__c ;
        String po = opp.Purchase_Options__c;
        if(po != 'FMV' && (state=='CA' || state=='UT'|| state=='NY')){
           return false;
       }
       return true;
   }

   @AuraEnabled
   public static Boolean hasPendingItems(String recordId){
      List<TC_Origination__Checklist_Item_with_Attachments__c> pendingItems=[select id from TC_Origination__Checklist_Item_with_Attachments__c where TC_Origination__Checklist_s_Opportunity__c = :recordId
      and TC_Origination__Included__c = true
      and name in ('Verify Legal Structure','Equipment Approval') and TC_Origination__Is_Complete__c=false];
      return pendingItems.size()>0;
   }

   @AuraEnabled
   public static string sendDocuments(String recordId, String contactId, String sendMethod){
         string result= '';
         Opportunity opp= [select id,SL_DocGen_Variables__c,Branch__c,Private_Label_Documents__c,SendMessage__c,SignerContact__c     from Opportunity where Id=:recordId];
         Map<String, Id> packages=new Map<String,Id>();
         for(Loop__DDP__c p :[Select id,Name from Loop__DDP__c]){
            packages.put(p.Name, p.Id);
         }
         String packId='';
         String docGenVar='SFContact:'+contactId+';Contact:'+contactId+';ContactID:'+contactId;
         if(opp.Private_Label_Documents__c){
            packId=packages.get('Private Label');
         }else{
            switch on opp.Branch__c {
               when 'CT&I Field', 'SNAP (National Accounts)', 'OEG Non-Copier' {
                    // DP-970 Misael Romero
                  packId=packages.get('CTI DocGen Package');
               }
               when 'Healthcare Division' {
                  packId=packages.get('Healthcare');
               }
               when 'Office Equip Group-OEG' {
                  packId=packages.get('OEG Doc Gen Package');
               }
            }
         }
         docGenVar+=';DDPId:'+packId;
         result+='&ddpIds='+packId;
         String alikeVar=sendMethod+'%';
         List<Loop__DDP_Integration_Option__c> iOptions=[Select Id, Name from Loop__DDP_Integration_Option__c where Loop__DDP__c=:packId and name like :alikeVar limit 1];
         if(iOptions.size()>0){

            docGenVar+=';Deploy:'+iOptions[0].Id;
            result+='&deploy='+iOptions[0].Id;

            if(sendMethod=='Docusign'){
               docGenVar+=';DeployType:autodocusign';
            }else if(sendMethod=='Email'){
               docGenVar+=';DeployType:autoemail';
            }

            opp.SendMessage__c=false;
            opp.SL_DocGen_Variables__c=docGenVar;
            if(String.isNotBlank(contactId)){
               opp.SignerContact__c=contactId;
            }
            update opp;
            return result;
         }else{
         return '';
         }

      
   }

   @AuraEnabled
   public static void handlePrimaryContact(String contactId, String OpportunityId){
    try {

      OpportunityContactRole ocr = new OpportunityContactRole(ContactId = contactId, IsPrimary = true,
                                  OpportunityId = OpportunityId, Role = primaryRole);
      ocr.Id = [SELECT Id FROM OpportunityContactRole WHERE ContactId = :contactId AND OpportunityId = :OpportunityId AND Role = :primaryRole]?.Id;

      UPSERT ocr;

      Opportunity opp = new Opportunity(Id = OpportunityId, Primary_Contact__c = contactId);

      UPDATE opp;
     } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
   }

   @AuraEnabled
   public static User getUserContact(){
      User u = [Select Id, Name, contact.Account.Pre_Delivery__c from User WHERE Id =:UserInfo.getUserId()] ;
      return u;
   }
   
   @AuraEnabled
   public static List<Disclaimer_for_DP_D_A_Button__mdt> getDisclaimers(){
       return [Select Id, Message__c, Pre_Delivery__c,Equipment_Cost__c from Disclaimer_for_DP_D_A_Button__mdt];
   }
   
}