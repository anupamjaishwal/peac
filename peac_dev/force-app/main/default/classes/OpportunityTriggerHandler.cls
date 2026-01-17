/****************************************************************************************
* @Author       Huron IT Team
* @Date         Aprl  30, 2017
*
*****************************************************************************************/
public class OpportunityTriggerHandler {
    public static boolean runTrigger = false;
    public static boolean contactFieldsPopulated = false;// Recursive check for 101 error SAL-2414
   public static void PopulatePrimaryContactFields(List<Opportunity> lstOpp){
        //Start Recursive check for 101 error SAL-2414
        //****Dont commment or delete this recursive check and this is causing 101 SOQL error while submitting apps. ****//
        if(contactFieldsPopulated){
            return;
        }else{
            contactFieldsPopulated = true;
        }
        //End Recursive check for 101 error SAL-2414
        System.debug('>>>>>>>>opportunity in PopulatePrimaryContactFields'+lstOpp);



        Set<Id> strSet = new Set<Id>();
        Map<Id, Contact> MapIdToCont = new Map<Id, Contact>();
        for(Opportunity objOppty : lstOpp){
            if (objOppty.Primary_Contact__c <> null) {
                strSet.add(objOppty.Primary_Contact__c);
            }
        }

       if (!strSet.isEmpty()) {
           for(Contact objCOn : [SELECT Id,FirstName,MiddleName,LastName,Email,Fax,Phone FROM Contact WHERE Id IN: strSet]){
               MapIdToCont.put(objCOn.Id, objCon);
           }
       }

        for(Opportunity objOpp : lstOpp){

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

            System.debug('>>>>>>.objOpp:::'+objOpp.Primary_Contact_Name__c);
            System.debug('>>>>>>.objOpp:::'+objOpp.Primary_Contact_Fax__c);
            System.debug('>>>>>>.objOpp:::'+objOpp.Primary_Contact_Email__c);
            System.debug('>>>>>>.objOpp:::'+objOpp.Primary_Contact_Phone__c);
        }
    }

    /*public static void getUpdatedRapportAPIField(List<Opportunity> aNewList,List<Opportunity> aOldList) {
Integer lIndex = 0;
String lUpdatedFieldList = '';
Set<String> lRapportAPIField = new Set<String> {
'Equipment_Description__c','Sales_Comments__c','Payment_Amount__c','Equipment_Cost__c','Terms__c','Sec_Dep_Pymts__c','of_Payments__c',
'Payment_Frequency__c','purchase_options__c'
};

for(Opportunity lNewOppty : aNewList){
Opportunity lOldOppty = aOldList[lIndex];

// no need to process if Applicaiton is not submitted yet
if(lOldOppty.Get('Application__c') == null && lNewOppty.Get('Application__c') == null)
continue;

for(String lFieldName : lRapportAPIField){
if(lNewOppty.Get(lFieldName) != lOldOppty.Get(lFieldName)){
lUpdatedFieldList = lUpdatedFieldList + lFieldName + ',';
System.Debug('Updated Field:' + lFieldName);

}

}
System.Debug('Updaed Field List:' + lUpdatedFieldList);

if(!String.IsBlank(lUpdatedFieldList)){
MARLIN_RapportCallout.updateApplicationInRapportAsync(lNewOppty.Id,'',lUpdatedFieldList.toLowerCase(),'Opportunity');
System.Debug('Rapport Update API Call for fields:' + lUpdatedFieldList.toLowerCase());
}

lIndex++;
}

}*/


    public static void triggerOnBaseAPI(List<Opportunity> aNewList,List<Opportunity> aOldList) {
        /*if (TC_RecursiveTriggerHelper.triggerOnBaseAPI) {
return;
        } else {
            TC_RecursiveTriggerHelper.triggerOnBaseAPI = true;
        }*/

        Integer lIndex = 0;

        System.Debug('triggerOnBaseAPI' + aNewList);
        for(Opportunity lNewOppty : aNewList){
            Opportunity lOldOppty = aOldList[lIndex];

            // no need to process if Applicaiton is not submitted yet
            if(lOldOppty.Get('Application__c') == null && lNewOppty.Get('Application__c') == null)
                continue;
            System.Debug('triggerOnBaseAPI 2');
            if(lNewOppty.Get('OnBase_Trigger_Flag__c') != lOldOppty.Get('OnBase_Trigger_Flag__c') && lNewOppty.Get('OnBase_Trigger_Flag__c') == True){
                if(!System.isBatch()) MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase(lNewOppty.Id,True);
                //System.Debug('On Base API from trigger:' + lNewOppty.Id);

            }
            lIndex++;
        }

    }
    // this is done in else where now
    public static void updatePrimaryContactOnOpportunity(List<Opportunity> aNewList) {
        /*Integer lIndex = 0;
        Set<Id> lOpptyIDs = new Set<ID>();

        for(Opportunity lNewOppty : aNewList){
            lOpptyIDs.Add(lNewOppty.Id);
        }

        List<Opportunity> lOpptyList = [SELECT ID,NAME,
                                        (Select ContactId,contact.Phone,contact.Email,contact.Fax,
                                         contact.FirstName,contact.LastName,contact.MiddleName
                                         From OpportunityContactRoles where IsPrimary = true)
                                        FROM Opportunity where ID IN : lOpptyIDs];

        Map<ID,OpportunityContactRole> lOpptyContactRoleMap = new  Map<ID,OpportunityContactRole>();

        for(Opportunity lOppty : lOpptyList){
            for(OpportunityContactRole orole : lOppty.OpportunityContactRoles)
                lOpptyContactRoleMap.Put(lOppty.Id,orole);

        }


        System.Debug('Map:' + lOpptyContactRoleMap);

        for(Opportunity lNewOppty : aNewList){

            if(lOpptyContactRoleMap.containsKey(lNewOppty.Id)){

                lNewOppty.Primary_Contact__c = lOpptyContactRoleMap.Get(lNewOppty.Id).ContactID;
                lNewOppty.Primary_Contact_Email__c = lOpptyContactRoleMap.Get(lNewOppty.Id).contact.Email ;
                lNewOppty.Primary_Contact_Fax__c = lOpptyContactRoleMap.Get(lNewOppty.Id).contact.Fax;
                lNewOppty.Primary_Contact_Name__c = lOpptyContactRoleMap.Get(lNewOppty.Id).contact.FirstName + ' ' +  lOpptyContactRoleMap.Get(lNewOppty.Id).contact.MiddleName + ' ' + lOpptyContactRoleMap.Get(lNewOppty.Id).contact.LastName;
                lNewOppty.Primary_Contact_Phone__c = lOpptyContactRoleMap.Get(lNewOppty.Id).contact.Phone;
                System.Debug('Name:' + lOpptyContactRoleMap.Get(lNewOppty.Id).contact.FirstName);
            }

        }*/



    }

    /* public static void defaultStageQuote(List<Opportunity> aNewList) {
for (Opportunity opp: aNewList){
if (opp.StageName == null || opp.StageName == ' ')
opp.StageName = 'Quote' ;
}


}  */
    /* Branch to platform, bandita confirmed we can remove this. this code also isn't used anymore after quick app
    public static void addFranchisor(List<Opportunity> aNewList) {

        List<Franchisor__c> franList = new List<Franchisor__c>();
        Map<ID, Account> mapAccounts = new Map<ID, Account>();
        //Id RecId = [Select Id, Name from RecordType where name = 'Franchise Opportunity' limit 1].Id;
        //tamarack update
        Id RecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Franchise Opportunity').getRecordTypeId();

        Set<Id> accId = new Set<ID>();
        //system.debug('aNewList((((');
        //system.debug('aNewList***' + aNewList);
        for(Opportunity lNewOppty : aNewList){
            system.debug('****lNewOppty ' + lNewOppty );


            if(lNewOppty.RecordTypeId== RecId  ){
                //system.debug('****lNewOppty.RecordType' + RecId );
                accId.Add(lNewOppty.AccountId);
            }
        }

        //system.debug('****accId' + accId);

        if(accId.size() == 0)
            return;
        else if(accId.size() > 0)
            mapAccounts = new Map<ID, Account>([SELECT Id, Franchisor_Account__c FROM Account where Id IN :accId and Franchisor_Account__c != null]);
        //system.debug('****mapAccounts' + mapAccounts);

        List<Opportunity> oppList = new List<Opportunity>();


        if(mapAccounts.size() > 0) {
            for(Opportunity opp : aNewList){
                //system.debug('****opp' + opp);
                if(mapAccounts.containsKey(opp.AccountId)){
                    Account accObj= mapAccounts.get(opp.AccountId);
                    //system.debug('****accObj' + accObj);
                    if (accObj != null){
                        Franchisor__c franchisor = new Franchisor__c();
                        franchisor.Franchisor__c = accObj.Franchisor_Account__c;
                        franchisor.Opportunity__c = opp.id;
                        franList.add(franchisor);

                    }

                }
            }

            // system.debug('****list' + franList);
            if (franList.size() > 0){
                insert franList;
            }
        }
    }   */
    // To copy Business Phone, Tax Id and Business Type to opportunity from Account
    public static void copyBusinessPhoneandTaxId(List<Opportunity> aNewList) {
        if (TC_RecursiveTriggerHelper.oppBeforeTrigger) {
            return;
        } else {
            TC_RecursiveTriggerHelper.oppBeforeTrigger = true;
        }

        Set<Id> accId = new Set<ID>();
        Map<ID, Account> mapAccounts = new Map<ID, Account>();

        for (Opportunity lNewOppty: aNewList){
            accId.Add(lNewOppty.AccountId);
        }

        system.debug('****accId' + accId);
        if(accId.size() == 0)
            return;
        else if(accId.size() > 0)
            mapAccounts = new Map<ID, Account>([SELECT Id, Tax_ID__c,Business_Phone__c,Business_Type__c FROM Account where Id IN :accId]);

        system.debug('****mapAccounts' + mapAccounts);
        if(mapAccounts.size() > 0) {
            for(Opportunity opp : aNewList){
                system.debug('****opp' + opp);
                if(mapAccounts.containsKey(opp.AccountId)){
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

    }


    public static void copyPhoneandTaxIdafterTrigger(List<Opportunity> aNewList) {
        /*if(runTrigger == true)
            return;
        else
            runTrigger = true;*/
        if (TC_RecursiveTriggerHelper.oppAfterTrigger) {
            return;
        } else {
            TC_RecursiveTriggerHelper.oppAfterTrigger = true;
        }
        Set<Id> accId = new Set<ID>();
        boolean oppCondition = false;
        Map<ID, Account> mapAccounts = new Map<ID, Account>();
        List<Account> acclist = new List<Account>();
        List<Opportunity> oppList = new List<Opportunity>();

        for (Opportunity lNewOppty: aNewList){
            accId.Add(lNewOppty.AccountId);
        }

        system.debug('****1accId' + accId);
        if(accId.size() == 0)
            return;
        else if(accId.size() > 0)
            mapAccounts = new Map<ID, Account>([SELECT Id, Tax_ID__c,Business_Phone__c FROM Account where Id IN :accId]);

        system.debug('****1mapAccounts' + mapAccounts);
        if(mapAccounts.size() > 0) {
            for(Opportunity opp : aNewList){
                oppCondition = false;
                system.debug('****1opp' + opp);
                if(mapAccounts.containsKey(opp.AccountId)){
                    Account accObj= mapAccounts.get(opp.AccountId);
                    system.debug('****accObj' + accObj);
                    /*if(accObj.Tax_ID__c != null && opp.Tax_ID__c == null){
opp.Tax_ID__c = accObj.Tax_ID__c;
oppList.add(opp);
}
if(accObj.Business_Phone__c != null && opp.Business_Phone__c == null){
opp.Business_Phone__c = accObj.Business_Phone__c;
oppList.add(opp);
}*/
                    if(!String.IsBlank(opp.Business_Phone__c)  && String.IsBlank(accObj.Business_Phone__c )){
                        accObj.Business_Phone__c = opp.Business_Phone__c;
                        //acclist.add(accObj);
                        oppCondition = true;
                    }

                    system.debug('****1opp.Tax_ID__c' + opp.Tax_ID__c);
                    system.debug('****1accObj.Tax_ID__c' + accObj.Tax_ID__c);

                    if(!String.IsBlank(opp.Tax_ID__c) && String.IsBlank(accObj.Tax_ID__c)){
                        system.debug('****Tax condition');
                        accObj.Tax_ID__c = opp.Tax_ID__c ;
                        oppCondition = true;
                        //acclist.add(accObj);
                    }
                    System.debug('Account Update List:' + acclist);
                    if(oppCondition == true)
                        acclist.add(accObj);
                }


            }

        }

        //system.debug('****1oppList' + oppList);

        if (acclist.size() > 0)
            if(System.isBatch()==false) {
                try {
                    update acclist;
                } catch (Exception e) {
                    System.debug ('Error updating Accounts: ' + e);
                }
            }


    }
    // trigger handler to add program to opportunity related to dealer account
    /*public static void addProgram(list<opportunity> optyList){

        Set<id> accIdList = new Set<id>();
        //List<Opportunity> optyRecordList = new List<Opportunity>();
        List<Opportunity_Program__c> optyProgram = new List<Opportunity_Program__c>();

        for(opportunity opp: optyList){
            accIdList.add(opp.Accountid);
        }

        String accountRecordTypeIds = label.AccountRecordTypeId;
        list<String> accRecordTypeIdList = accountRecordTypeIds.split(',');
        Set<Id> accIds = new Set<Id>();

        List<Account> lAcc = [Select id, RecordType.DeveloperName from Account where id IN: accIdList AND RecordType.DeveloperName IN :accRecordTypeIdList];

        if(lAcc.size() > 0) {
            for(Account ac : lAcc) {
                accIds.add(ac.id);
            }
            List<Account_Program__c> AccProgramList = [select Id, Account__c, Program__c from Account_Program__c where Account__c IN :accIds];

            Map<id,Set<Id>> AccProgramLMap = new Map<id,Set<Id>>();
            if(AccProgramList.size()>0){
                for(Account_Program__c ap : AccProgramList) {
                    if(AccProgramLMap.containsKey(ap.Account__c)) {
                        Set<Id> programSet = AccProgramLMap.get(ap.Account__c);
                        programSet.add(ap.Program__c);
                        AccProgramLMap.put(ap.Account__c, programSet);
                    } else {
                        AccProgramLMap.put(ap.Account__c, new Set<Id> { ap.Program__c });
                    }
                    System.debug('AccProgramLMap---->'+AccProgramLMap);
                }


                System.debug('Account Program-----> '+AccProgramList);

                for(Opportunity opp: optyList){
                    if(accIds.contains(opp.AccountId)) {
                        for(Account_Program__c accProg: AccProgramList){
                            System.debug('Opportunity name--->'+opp.Name);

                            if(AccProgramLMap.get(opp.AccountId).contains(accProg.Program__c)){
                                System.debug('Program name---->'+accProg);
                                Opportunity_Program__c oppProg = new Opportunity_Program__c();
                                oppProg.Opportunity__c = opp.id;
                                oppProg.Program__c = accProg.Program__c;

                                optyProgram.add(oppProg);
                            }
                        }
                    }
                }
                System.debug('optyProgram---->'+optyProgram);

                if(optyProgram.size()>0) {
                    insert optyProgram;
                }
            }

        }
    }*/
}