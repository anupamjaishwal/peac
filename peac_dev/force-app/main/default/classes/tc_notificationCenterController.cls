public class tc_notificationCenterController {
    @AuraEnabled
    public static Account GetAccount(String AccId){
        system.debug('AccId:'+AccId);
        Account lstacc = [
            SELECT Id, 
            Submitted__c, 
            More_Info__c,
            Approved__c,
            Declined__c,
            Approved_with_pricing__c,
            Docs_Out__c,
            Docs_Out_Contracts__c,
            Docs_In__c,
            In_Funding__c,
            Funded__c,
            Is_Broker__c,
            Submitted_Loan__c,
            More_Info_Loan__c,
            Approved_Loan__c,
            Declined_Loan__c,
            Docs_Out_Loan__c,
            Docs_Out_Contracts_Loan__c,
            Docs_In_Loan__c,
            Funded_Loan__c,
            Name
            FROM Account 
            WHERE Id =: AccId
        ];
        return lstacc;
    }
    
    @AuraEnabled
    public static  List<AccountContactRelationWrap> GetContact(String AccId){
     //   List<Contact> lstCon = [SELECT Id,Receive_All_Notifications__c,Name FROM Contact WHERE AccountId =: AccId];
     List<AccountContactRelation > lstCon = [
         SELECT Id,
         Roles,
         contact.Receive_All_Notifications__c,
         contact.Receive_All_Loan_Notifications__c,
         contact.FirstName,
         contact.LastName,
         contact.Name,
         ContactId,
         contact.Email 
         from AccountContactRelation 
         Where AccountId =: AccId
     ];
        
         List<AccountContactRelationWrap> lstWrap = new  List<AccountContactRelationWrap>();
      
        for(AccountContactRelation objACR : lstCon ){
            AccountContactRelationWrap objWrap = new AccountContactRelationWrap();
            objWrap.Id = objACR.Id;
            objWrap.ConName = objACR.contact.Name;
            objWrap.Role = objACR.Roles;
            objWrap.ReceiveAllNotifications = objACR.contact.Receive_All_Notifications__c;
            objWrap.ReceiveLoanNotifications = objACR.contact.Receive_All_Loan_Notifications__c;
            objWrap.ConId = objACR.ContactId;
            objWrap.ConEmail = objACR.contact.Email;
            lstWrap.add(objWrap);
        }
        
        return lstWrap;
        
    }
    
    public class AccountContactRelationWrap {
        @AuraEnabled
        public String Id{get;set;} 
        @AuraEnabled
        public String ConName{get;set;} 
        @AuraEnabled
        public String Role {get;set;} 
        @AuraEnabled
        public boolean ReceiveAllNotifications {get;set;} 
        @AuraEnabled
        public boolean ReceiveLoanNotifications {get; set;}
        @AuraEnabled
        public String  ConId {get;set;} 
        @AuraEnabled
        public String  ConEmail {get;set;} 
    }
    
   
    
     @AuraEnabled
    public static  void  UpdateContact (String objACRW, Account objAcc){
        try{

            system.debug('objAcc'+objAcc);
            Update objAcc;
            system.debug('objAcc>>>'+objAcc);
            List<AccountContactRelationWrap> lstACRW = (List<AccountContactRelationWrap>)JSON.deserialize(objACRW,List<AccountContactRelationWrap>.class);               
            List<Contact> Updatelst = new  List<Contact>();
            system.debug('objACRW###'+lstACRW); 
            List<AccountContactRelation> lstRelation = new List<AccountContactRelation>();
            for(AccountContactRelationWrap objAR : lstACRW){
                
                AccountContactRelation objACR = new AccountContactRelation();
                objACR.Id = objAR.Id ;
                objACR.Roles = objAR.Role;
                lstRelation.add(objACR);
                
                contact objContact = new contact();
                objContact.Id = objAR.ConId;
                objContact.Receive_All_Notifications__c = objAR.ReceiveAllNotifications;
                objContact.Receive_All_Loan_Notifications__c = objAR.ReceiveLoanNotifications;
                Updatelst.add(objContact);
            }
            
            if(lstRelation.Size() >0 ){
                Update lstRelation;
            }
            
            
            if(Updatelst.Size() >0 ){
                Update   Updatelst;
            }
        }catch(dmlException ex) {
            String msg = '';
            for (Integer i = 0; i < ex.getNumDml(); i++) {
                //Get Validation Rule & Trigger Error Messages
                msg =+ ex.getDmlMessage(i) +  '\n' ;
            }
            throw new AuraHandledException(msg);
        }catch(exception ex){
            system.debug(ex.getMessage());
            throw new AuraHandledException(ex.getMessage());  
            
        }
        
    }
    
    @AuraEnabled
    public static List<AccountContactRelationWrap> GetuserContact(String userId){
        USer u = [SELECT Id, Contact.AccountId FROM User WHERE Id =: userId];
        return GetContact(u.Contact.AccountId);
    }
    @AuraEnabled
    public static Account GetuserAccount(String userId){
        USer u = [SELECT Id, Contact.AccountId FROM User WHERE Id =: userId];
        return GetAccount(u.Contact.AccountId);
    }
    
    @AuraEnabled
    public static void updateAccountRec(Account acc){
        update acc;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getFields(String objectName) {
        // Get the SObjectType for the given object name
        List<String> fieldSetList = new list<String>();
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        for(DPNotificationCenter_Contact_Edit__mdt nc : [SELECT Id, FieldApiName__c FROM DPNotificationCenter_Contact_Edit__mdt where Object_Name__c = :objectName]){
            //Schema.FieldSet fieldSet = sObjectType.getDescribe().fieldSets.getMap().get(fieldSetName);
            fieldSetList.add(nc.FieldApiName__c);
        }
        // Get the FieldSet for the given field set name and SObjectType
        

        // Return the list of fields from the FieldSet
        return fieldSetList;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getRoleOptions(String objectName, String fieldName) {
        //String objectName = 'AccountContactRelation';
        //String fieldName ='Roles';
        List<String> options = new List<String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName) ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            options.add(pickListVal.getValue());
        }
        return options;
    }
    @AuraEnabled
    public static void updateRole(String role, String roleid) {
        try{
            update new AccountContactRelation(Id = roleid, Roles = role);
        } catch(exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
}