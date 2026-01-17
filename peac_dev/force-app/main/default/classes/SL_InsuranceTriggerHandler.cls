public with sharing class SL_InsuranceTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    private Map<Id, Account> customerAccounts = new Map<Id, Account>();
    private Map<Id, Map<Id, Contract__c>> contracts = new Map<Id, Map<Id, Contract__c>>();
    User currentUser = new User();
    
    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        checkUpdatedFields(oldMap, newMap);
        for (Id insuranceId :newMap.keySet()){
            getLookupMaps(newMap.get(insuranceId));
        }
        getInfoFromOthers();
        beforeChangesToSelf(newMap, false);
    }

    public override void afterInsert(Map<Id, SObject> newMap){
        for(SObject obj : newMap.values()){
            getLookupMaps(obj);
        }
        getInfoFromOthers();
        afterChangesToOthers(newMap, true);
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        //push to Bridgeware to Sync with Infolease
        if(!SL_InfoleaseUtils.isRecursive && !System.isFuture() && !System.isBatch()){
            Map <Id, Insurance__c> oldMapInsurance = new Map <Id, Insurance__c>();
            Map <Id, Insurance__c> newMapInsurance = new Map <Id, Insurance__c>();
            for (SObject theObj : oldMap.values()){
                oldMapInsurance.put(theObj.Id, (Insurance__c)theObj);
                newMapInsurance.put(theObj.Id, ((Insurance__c)newMap.get(theObj.Id)));
            }
            SL_InfoleaseInsuranceController.updateInsurance(oldMapInsurance, newMapInsurance);
        }
        for(SObject obj : newMap.values()){
            getLookupMaps(obj);
        }
        getInfoFromOthers();
        afterChangesToOthers(newMap, false);
    }

    public override void afterDelete(Map<Id, SObject> oldMap){
        // not yet sure if doing anything when insurance gets deleted
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = new List<String>{'Account_Level__c', 'Cancel_Date__c', 'Carrier__c', 'Customer__c', 'Effective_Date__c',
            'Expiration_Date__c', 'Insurance_Agent__c', 'Insurance_Contact__c', 'Insurance_Id__c', 'Insurance_Type__c',
            'Integration_Status__c', 'Name', 'Policy_Status__c', 'Property_Damage_Coverage__c', 'Save_at_Account_Level__c',
            'Title__c', 'Titled_Vehicles__c'};
        for(Id insuranceId :newMap.keySet()){
            Insurance__c newInsurance = (Insurance__c)newMap.get(insuranceId);
            Insurance__c oldInsurance = (Insurance__c)oldMap.get(insuranceId);
            SL_TriggerUtil.findChangedFields(insuranceId, newInsurance, oldInsurance, fieldsChangedById, fieldsToCheck);

        }
    }

    private void getLookupMaps(SObject obj){
        Insurance__c insurance = (Insurance__c)obj;
        if(insurance.Customer__c != null){
            this.customerAccounts.put(insurance.Customer__c, new Account());
        }
        contracts.put(insurance.Id, new Map<Id, Contract__c>());
    }
    
    private void getInfoFromOthers(){
        this.customerAccounts.putAll([SELECT Id, Active_Insurance__c, Active_Insurance__r.Expiration_Date__c,
            Account_CurrentUser_Profile__c 
            FROM Account WHERE Id IN : this.customerAccounts.keySet()]);
        for(Contract__c contract : [SELECT Id, Name, Customer__c, Insurance__c, Infolease_Environment__c, Insurance_Status__c 
            FROM Contract__c WHERE Insurance__c IN :contracts.keySet()]){
            contracts.get(contract.Insurance__c).put(contract.Id, contract);
        }
        if(Trigger.isBefore /*&& (this.customerAccounts.values().size() == 0 || SL_TriggerUtil.checkForMissingInfo(this.customerAccounts.values()))*/){
            this.currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :System.UserInfo.getUserId()];
        }
    }

    private void beforeChangesToSelf(Map<Id, SObject> newMap, Boolean isNew){
        for(SObject obj : newMap.values()){
            Insurance__c insurance = (Insurance__c)obj;
            Map<Id, Contract__c> relatedContracts = this.contracts.get(insurance.Id);
            Account customerAccount = this.customerAccounts.get(insurance.Customer__c);
            Contract__c currentCon = null;
            if(relatedContracts != null && relatedContracts.values().size() > 0){
                for(Contract__c relatedContract : relatedContracts.values()){
                    if(insurance.Insurance_Id__c != null && insurance.Insurance_Id__c.contains(relatedContract.Name)){
                        currentCon = relatedContract;
                        break;
                    }
                }
            }
            String currentProfile = customerAccount != null? 
                customerAccount.Account_CurrentUser_Profile__c: this.currentUser.Profile.Name;
            List<String> fieldsChanged = this.fieldsChangedById.get(insurance.Id);
            if(currentProfile != 'DataAdmin' && currentCon != null 
                && (currentCon.Insurance_Status__c=='03'||currentCon.Insurance_Status__c=='20A') 
                && (insurance.Infolease_Environment__c=='10' || insurance.Infolease_Environment__c=='C')
               && fieldsChanged != null && ((fieldsChanged.contains('Cancel_Date__c') && fieldsChanged.size() > 1)
               || (!fieldsChanged.contains('Cancel_Date__c') && fieldsChanged.size() > 0))){
                insurance.addError('This insurance policy must be updated in Infolease 10');
            }
        }
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNewInsurance){
        List<Account> customersToUpdate = new List<Account>();
        List<Insurance__c> insurancesToSync = new List<Insurance__c>();
        Set<Id> accountIds = new Set<Id>();
        for(SObject obj : newMap.values()){
            Insurance__c insurance = (Insurance__c)obj;
            if(insurance.Customer__c != null && !accountIds.contains(insurance.Customer__c)){
                accountIds.add(insurance.Customer__c);
                Account customer = SL_InsuranceTriggerHandler.newActiveInsuranceToAccount(this.customerAccounts.get(insurance.Customer__c), insurance);
                if (customer != null){
                    customersToUpdate.add(customer);
                }
            }
            if(insurance.Save_at_Account_Level__c){
                Insurance__c turnOff = new Insurance__c(Id = insurance.Id, Save_at_Account_Level__c = false);
                insurancesToSync.add(turnOff);
                Id accountId = null;
                if(insurance.Customer__c != null){
                    accountId = insurance.Customer__c;
                }else{
                    List<Contract__c> contractList = contracts.get(insurance.Id).values();
                    for(Integer i = 0; i < contractList.size(); i++){
                        if(contractList[i].Customer__c != null){
                            accountId = contractList[i].Customer__c;
                            break;
                        }
                    }
                }
                Set<Id> insuranceIds = new Set<Id>();
                List<Contract__c> otherContracts = [SELECT Insurance__c, Insurance__r.Insurance_Id__c FROM Contract__c 
                    WHERE Customer__c = : accountId AND Insurance__c != null AND Insurance__r.Titled_Vehicles__c = FALSE AND Insurance__r.Save_at_Account_Level__c = FALSE AND (NOT Status__c LIKE 'Disposed%')];
                for(Contract__c contract: otherContracts){
                    if(!insuranceIds.contains(contract.Insurance__c) && contract.Insurance__c != insurance.Id){
                        insuranceIds.add(contract.Insurance__c);
                        Insurance__c copy = new Insurance__c();
                        copy = insurance.clone(false,false,false,false);
                        copy.Id = contract.Insurance__c;
                        copy.Insurance_Id__c = contract.Insurance__r.Insurance_Id__c;
                        copy.Save_at_Account_Level__c = false;
                        insurancesToSync.add(copy);
                    }
                }
                    
            }
            
        }
        update customersToUpdate;
        if(insurancesToSync.size() > 0){
            SL_InfoleaseUtils.isRecursive = false;
            update insurancesToSync;
        }
    }

    public static Account newActiveInsuranceToAccount(Account customer, Insurance__c insurance){
        Account updatedCustomer = null;
        if (insurance.Account_Level__c && insurance.Expiration_Date__c > Date.today()
            && (customer.Active_Insurance__c == null 
            || customer.Active_Insurance__r.Expiration_Date__c <= Date.today()
            || customer.Active_Insurance__r.Expiration_Date__c <= insurance.Expiration_Date__c)){
            customer.Active_Insurance__c = insurance.Id;
            updatedCustomer = customer;
        }
        return updatedCustomer;
    }
}