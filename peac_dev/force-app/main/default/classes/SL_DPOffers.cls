public with sharing class SL_DPOffers {
    @AuraEnabled(cacheable=true)
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'getAssets'{
                    result = getAssets(parameters[0]);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    static string getAssets(Id OpportunityId){
        Opportunity oppInfo = [SELECT Account_Billing_State_Province__c, EF_Approved_Offers__r.Monthly_Payment__c, EF_Approved_Offers__r.Rate_Factor__c,Offer_Rate_Factor__c, StageName FROM Opportunity WHERE Id = :OpportunityId];
        //SAL-4968
        List<Asset__c> assets = [SELECT Id, Name, Asset_Description__c, Cost__c, Equipment_Code__c, Manufacturer__c, Model__c,Serial_Number__c FROM Asset__c WHERE Opportunity__c = :OpportunityId];
        //List<Asset__c> assets = [SELECT Id, Name, Asset_Description__c, Cost__c, Equipment_Code__c, Model__c,Serial_Number__c FROM Asset__c WHERE Opportunity__c = :OpportunityId];
        
        return '{"oppInfo": ' + JSON.serialize(oppInfo) + ', "assets": ' + JSON.serialize(assets) + '}';
    }

}