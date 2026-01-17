public class TC_OpportunityTriggerHandlerRefactor{
    public static Trigger_Helper_Settings__c setting = Trigger_Helper_Settings__c.getOrgDefaults ();
    public static Boolean notDataAdmin = UserInfo.getProfileId () != setting.Data_Admin_Profile_Id__c;
    public static boolean contactFieldsPopulated = false;


    public static void afterUpdate(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, Account> mapAccounts){
    
        Set<Id> accId = new Set<Id>();
        
        for(Opportunity opp : newMap.values()){
            
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(notDataAdmin){// opportunityTrigger OpportunityTriggerHandler copyPhoneandTaxIdafterTrigger
                accId.Add(opp.AccountId);
            }
            //opportunityTrigger  OpportunityTriggerHandler.triggerOnBaseAPI
            if(oldOpp.Application__c <> null && opp.Application__c <> null && oldOpp.OnBase_Trigger_Flag__c <> opp.OnBase_Trigger_Flag__c && opp.OnBase_Trigger_Flag__c){
                if(!System.isBatch()) MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase(opp.Id,True);
            }
        }
        
        if(accId.size() > 0){// opportunityTrigger OpportunityTriggerHandler copyPhoneandTaxIdafterTrigger
        
            //Map<ID, Account> mapAccounts = new Map<ID, Account>([SELECT Id, Tax_ID__c,Business_Phone__c FROM Account where Id IN :accId]);// replace with accountmap param
            List<Account> acclist = new List<Account>();
            if(mapAccounts.size() > 0) {
                for(Opportunity opp : newMap.values()){
                    Boolean oppCondition = false;
                    if(accId.contains(opp.AccountId) && mapAccounts.containsKey(opp.AccountId)){
                        Account accObj= mapAccounts.get(opp.AccountId);
                        
                        if(!String.IsBlank(opp.Business_Phone__c)  && String.IsBlank(accObj.Business_Phone__c )){
                            accObj.Business_Phone__c = opp.Business_Phone__c;
                            //acclist.add(accObj);
                            oppCondition = true;
                        }
    
    
                        if(!String.IsBlank(opp.Tax_ID__c) && String.IsBlank(accObj.Tax_ID__c)){
                            accObj.Tax_ID__c = opp.Tax_ID__c ;
                            oppCondition = true;
                        }
                        if(oppCondition == true)
                            acclist.add(accObj);
                    }
                }
                if (acclist.size() > 0){
                    if(System.isBatch()==false) {
                        try {
                            update acclist;
                        } catch (Exception e) {
                            System.debug ('Error updating Accounts: ' + e);
                        }
                    }
                }
            }
        }
    }
    public static void beforeUpdate(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, Account> mapAccounts){
    
        Set<Id> strSet = new Set<Id>();
        Set<Id> PhoneandTaxaccIds = new Set<Id>();
        for(Opportunity opp : newMap.values()){
            //opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields start
            if (opp.Primary_Contact__c <> null && !contactFieldsPopulated) {
                strSet.add(opp.Primary_Contact__c);
            }//opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields end
            if(!TC_RecursiveTriggerHelper.oppBeforeTrigger && notDataAdmin){//opportunityTrigger  OpportunityTriggerHandler.copyBusinessPhoneandTaxId start
                PhoneandTaxaccIds.Add(opp.AccountId);
            }
        }
        
        TC_RecursiveTriggerHelper.oppBeforeTrigger = true;
        contactFieldsPopulated = true;
        if(PhoneandTaxaccIds.size() > 0){//opportunityTrigger  OpportunityTriggerHandler.copyBusinessPhoneandTaxId start
        
            //Map<ID, Account> mapAccounts = new Map<ID, Account>([SELECT Id, Tax_ID__c,Business_Phone__c,Business_Type__c FROM Account where Id IN :PhoneandTaxaccIds]);// replace with accountmap param
            if(mapAccounts.size() >0){
                for(Opportunity opp : newMap.values()){
                    if(PhoneandTaxaccIds.contains(opp.AccountId) && mapAccounts.containsKey(opp.AccountId)){
                        Account accObj= mapAccounts.get(opp.AccountId);
                        system.debug('****accObj' + accObj);
    
                        try {
                            if(! String.IsBlank(accObj.Tax_ID__c) && String.IsBlank(opp.Tax_ID__c)){
                                opp.Tax_ID__c = accObj.Tax_ID__c;
                            }
                            if(!String.IsBlank(accObj.Business_Phone__c) && String.IsBlank(opp.Business_Phone__c)){
                                opp.Business_Phone__c = accObj.Business_Phone__c;
                            }
                            if(!String.IsBlank(accObj.Business_Type__c) && String.IsBlank(opp.Business_Type__c)){
                                opp.Business_Type__c = accObj.Business_Type__c;
                            }
                        } catch (Exception e) {
                            System.debug ('Error updating Account with Opportunity information');
                        }
                    }
                }
            }
        }// opportunityTrigger OpportunityTriggerHandler.copyBusinessPhoneandTaxId end
                
        //opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields satrt
        if (!strSet.isEmpty()) {
           Map<Id, Contact> MapIdToCont = new Map<Id, Contact>();
           for(Contact objCOn : [SELECT Id,FirstName,MiddleName,LastName,Email,Fax,Phone FROM Contact WHERE Id IN: strSet]){
               MapIdToCont.put(objCOn.Id, objCon);
           }
           
           for(Opportunity objOpp : newMap.values()){

                if(objOpp.Primary_Contact__c != null ){
                    System.debug('>>>>>>>>objOpp.Primary_Contact__c '+objOpp.Primary_Contact__c);
                    System.debug('>>>>>>.objOppContName:::'+objOpp.Primary_Contact__r.FirstName);
                    System.debug('>>>>>>.objOppContEmail:::'+objOpp.Primary_Contact__r.Email);
                    System.debug('>>>>>>.objOppContFax:::'+objOpp.Primary_Contact__r.Fax);
                    System.debug('>>>>>>.objOppContPhone:::'+objOpp.Primary_Contact__r.Phone);
                    Contact oppContact = new Contact();
                    if(MapIdToCont.containsKey(objOpp.Primary_Contact__c)){
                        oppContact = (MapIdToCont.get(objOpp.Primary_Contact__c));
                    }
                    if(oppContact.Email != null)
                        objOpp.Primary_Contact_Email__c = oppContact.Email;
                    if(oppContact.Fax != null)
                        objOpp.Primary_Contact_Fax__c = oppContact.Fax;
                    if(oppContact.FirstName != null)
                        objOpp.Primary_Contact_Name__c = oppContact.FirstName;
                    if(oppContact.MiddleName != null)
                        objOpp.Primary_Contact_Name__c +=' '+oppContact.MiddleName ;
                    if(oppContact.LastName != null)
                        objOpp.Primary_Contact_Name__c += ' '+oppContact.LastName ;
                    if(oppContact.Phone != null)
                        objOpp.Primary_Contact_Phone__c = oppContact.Phone;
                }
            }
        }//opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields end
    }
    public static void afterInsert(List<Opportunity> opps, Map<ID, Account> mapAccounts){
        Set<Id> accId = new Set<Id>();
        
        for(Opportunity opp : opps){
            if(notDataAdmin){// opportunityTrigger OpportunityTriggerHandler copyPhoneandTaxIdafterTrigger
                accId.Add(opp.AccountId);
            }
        }
        
        if(accId.size() > 0){// opportunityTrigger OpportunityTriggerHandler copyPhoneandTaxIdafterTrigger
        
            //Map<ID, Account> mapAccounts = new Map<ID, Account>([SELECT Id, Tax_ID__c,Business_Phone__c FROM Account where Id IN :accId]);// replace with accountmap param
            List<Account> acclist = new List<Account>();
            if(mapAccounts.size() > 0) {
                for(Opportunity opp : opps){
                    Boolean oppCondition = false;
                    if(accId.contains(opp.AccountId) && mapAccounts.containsKey(opp.AccountId)){
                        Account accObj= mapAccounts.get(opp.AccountId);
                        
                        if(!String.IsBlank(opp.Business_Phone__c)  && String.IsBlank(accObj.Business_Phone__c )){
                            accObj.Business_Phone__c = opp.Business_Phone__c;
                            //acclist.add(accObj);
                            oppCondition = true;
                        }
    
    
                        if(!String.IsBlank(opp.Tax_ID__c) && String.IsBlank(accObj.Tax_ID__c)){
                            accObj.Tax_ID__c = opp.Tax_ID__c ;
                            oppCondition = true;
                        }
                        if(oppCondition == true)
                            acclist.add(accObj);
                    }
                }
                if (acclist.size() > 0){
                    if(System.isBatch()==false) {
                        try {
                            update acclist;
                        } catch (Exception e) {
                            System.debug ('Error updating Accounts: ' + e);
                        }
                    }
                }
            }
        }
    }
    public static void beforeInsert(List<Opportunity> opps, Map<ID, Account> mapAccounts){
        Set<Id> strSet = new Set<Id>();
        Set<Id> PhoneandTaxaccIds = new Set<Id>();
        for(Opportunity opp : opps){
            //opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields start
            if (opp.Primary_Contact__c <> null && !contactFieldsPopulated) {
                strSet.add(opp.Primary_Contact__c);
            }//opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields end
            if(!TC_RecursiveTriggerHelper.oppBeforeTrigger && notDataAdmin){//opportunityTrigger  OpportunityTriggerHandler.copyBusinessPhoneandTaxId start
                PhoneandTaxaccIds.Add(opp.AccountId);
            }
        }
        
        TC_RecursiveTriggerHelper.oppBeforeTrigger = true;
        contactFieldsPopulated = true;
        if(PhoneandTaxaccIds.size() > 0){//opportunityTrigger  OpportunityTriggerHandler.copyBusinessPhoneandTaxId start
        
            //Map<ID, Account> mapAccounts = new Map<ID, Account>([SELECT Id, Tax_ID__c,Business_Phone__c,Business_Type__c FROM Account where Id IN :PhoneandTaxaccIds]);// replace with accountmap param
            if(mapAccounts.size() >0){
                for(Opportunity opp : opps){
                    if(PhoneandTaxaccIds.contains(opp.AccountId) && mapAccounts.containsKey(opp.AccountId)){
                        Account accObj= mapAccounts.get(opp.AccountId);
                        system.debug('****accObj' + accObj);
    
                        try {
                            if(! String.IsBlank(accObj.Tax_ID__c) && String.IsBlank(opp.Tax_ID__c)){
                                opp.Tax_ID__c = accObj.Tax_ID__c;
                            }
                            if(!String.IsBlank(accObj.Business_Phone__c) && String.IsBlank(opp.Business_Phone__c)){
                                opp.Business_Phone__c = accObj.Business_Phone__c;
                            }
                            if(!String.IsBlank(accObj.Business_Type__c) && String.IsBlank(opp.Business_Type__c)){
                                opp.Business_Type__c = accObj.Business_Type__c;
                            }
                        } catch (Exception e) {
                            System.debug ('Error updating Account with Opportunity information');
                        }
                    }
                }
            }
        }// opportunityTrigger OpportunityTriggerHandler.copyBusinessPhoneandTaxId end
                
        //opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields satrt
        if (!strSet.isEmpty()) {
           Map<Id, Contact> MapIdToCont = new Map<Id, Contact>();
           for(Contact objCOn : [SELECT Id,FirstName,MiddleName,LastName,Email,Fax,Phone FROM Contact WHERE Id IN: strSet]){
               MapIdToCont.put(objCOn.Id, objCon);
           }
           
           for(Opportunity objOpp : opps){

                if(objOpp.Primary_Contact__c != null ){
                    System.debug('>>>>>>>>objOpp.Primary_Contact__c '+objOpp.Primary_Contact__c);
                    System.debug('>>>>>>.objOppContName:::'+objOpp.Primary_Contact__r.FirstName);
                    System.debug('>>>>>>.objOppContEmail:::'+objOpp.Primary_Contact__r.Email);
                    System.debug('>>>>>>.objOppContFax:::'+objOpp.Primary_Contact__r.Fax);
                    System.debug('>>>>>>.objOppContPhone:::'+objOpp.Primary_Contact__r.Phone);
                    Contact oppContact = new Contact();
                    if(MapIdToCont.containsKey(objOpp.Primary_Contact__c)){
                        oppContact = (MapIdToCont.get(objOpp.Primary_Contact__c));
                    }
                    if(oppContact.Email != null)
                        objOpp.Primary_Contact_Email__c = oppContact.Email;
                    if(oppContact.Fax != null)
                        objOpp.Primary_Contact_Fax__c = oppContact.Fax;
                    if(oppContact.FirstName != null)
                        objOpp.Primary_Contact_Name__c = oppContact.FirstName;
                    if(oppContact.MiddleName != null)
                        objOpp.Primary_Contact_Name__c +=' '+oppContact.MiddleName ;
                    if(oppContact.LastName != null)
                        objOpp.Primary_Contact_Name__c += ' '+oppContact.LastName ;
                    if(oppContact.Phone != null)
                        objOpp.Primary_Contact_Phone__c = oppContact.Phone;
                }
            }
        }//opportunityTrigger OpportunityTriggerHandler.PopulatePrimaryContactFields end
    }
}