/**
 * SL-1283 Developed by Harsh@Silverline 11/04/2022
 */
public with sharing class SL_OtherContractsController {
    @AuraEnabled
    public static List<Contract__c> getContractList(Id recordId){
        List<Contract__c> conLst = [SELECT Id, Customer__c FROM Contract__c WHERE Id =: recordId LIMIT 1];
        List<Contract__c> contractList;
        if(conLst.size() > 0){
            contractList = [SELECT Id, Name, Contract_Balance_Remaining__c,
                            Total_Past_Due__c, Delinquency_Status_Code__c, Status__c,
                            Commencement_Date__c, Term_Date__c, OwnerId, Owner.Name
                            FROM Contract__c 
                            WHERE Customer__c =: conLst[0].Customer__c 
                            AND Id !=: recordId];
        }
        return contractList;
    }
}