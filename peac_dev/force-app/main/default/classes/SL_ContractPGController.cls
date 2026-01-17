public with sharing class SL_ContractPGController {
    @AuraEnabled(Cacheable = true)
    public static List<Contact> getContacts( String contractId) {
        List<Contact> conRetList = new List<Contact>();
        List<Contract_Contact_Role__c> conRole = [SELECT Contact__r.Id,Contact__r.Name, Contact__r.FirstName, Contact__r.LastName, Contact__r.Credit_Score__c, Contact__r.Email  
                                                    FROM Contract_Contact_Role__c 
                                                    WHERE Contract__c =: contractId 
                                                    AND Role__c = 'Personal Guarantor'];
        if (conRole == null) return null;
        for(Contract_Contact_Role__c thisRole: conRole){
            Contact thisCon = new Contact();
            thisCon.Id = thisRole.Contact__r.Id;
            thisCon.FirstName = thisRole.Contact__r.Name;                            
            thisCon.Email = thisRole.Contact__r.Email;                            
            thisCon.Credit_Score__c = thisRole.Contact__r.Credit_Score__c;   
            conRetList.add(thisCon);                         
        }
        return conRetList;
    }
}