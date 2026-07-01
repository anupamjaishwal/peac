/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is displaying message on guidance line amount logic.
@User Story:SAL-6483
@Created Date:February/03/2026 	    
*********************************************************************************************************************/

public with sharing class PEAC_DisplayGuidanceLineAmtMessageClass {
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called to display warming message on Opportunity or Asset Pages
    @User Story:SAL-6483	 
    @Param:Record Id and Object Name
    @Created Date:February/5/2026   
    **************************************************************************************************************/
   
    @AuraEnabled
    public static Boolean getGuidanceAmessage(string oppRecordId, string objectName){
        Boolean isGuidanceLineAmountMessage = false;
        string oppId = '';
        try {
            if(objectName == 'Opportunity')
            {
                oppId = oppRecordId;
            }
            else if(objectName == 'Asset')
            {
                oppId = getOppId(oppRecordId);
            }
            List<Opportunity> oppDetailsList = getAccountId(oppId);
            Set<Id> accIdSet = new set<Id>();
            accIdSet.add(oppDetailsList[0].AccountId);
            Set<String> accountIdSet = PEAC_EquipmentCostWOTax.getGuidanceAmounts(accIdSet);

            if(!accountIdSet.isEmpty() && (accountIdSet.contains(oppDetailsList[0].AccountId) ||  (oppDetailsList[0].Account.Infolease_Group_Code__c !=null 
                && accountIdSet.contains(oppDetailsList[0].Account.Infolease_Group_Code__c))))
            {
                isGuidanceLineAmountMessage = true;
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return isGuidanceLineAmountMessage;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get Account Id
    @User Story:SAL-6483	 
    @Param:Record Id
    @Created Date:February/5/2026   
    **************************************************************************************************************/
  
    public static string getOppId(string objId)
    {
        string accId = '';
        List<Asset__c> assetList = new List<Asset__c>();
        assetList = [SELECT Id, Opportunity__r.AccountId FROM Asset__c WHERE Id =: objId];
        if(!assetList.isEmpty())
        {
            accId = assetList[0].Opportunity__r.AccountId;
        }
        return accId;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get List of Opportunity
    @User Story:SAL-6483	 
    @Param:Record Id
    @Created Date:February/5/2026   
    **************************************************************************************************************/
  
    public static List<Opportunity> getAccountId(string objId)
    {
        List<Opportunity> oppList = new List<Opportunity>();
        oppList = [SELECT Id, AccountId,Account.Infolease_Group_Code__c FROM Opportunity WHERE Id =: objId];
        
        return oppList;
    }
    
    /**************************************************************************************************************
    @Author:Varun S
    @Description: This method will be called from LWC component to display warning message
    @User Story:SAL-6483	 
    @Param:Record Id and Object Name
    @Created Date:February/5/2026   
    **************************************************************************************************************/
  
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGuidanceLineWarning(String recordId, String objectName) {

        Map<String, Object> result = new Map<String, Object>();
        result.put('showWarning', false);
        result.put('message', null);

        if (String.isBlank(recordId) || String.isBlank(objectName)) {
            return result;
        }

        Boolean showMessage = getGuidanceAmessage(recordId, objectName);

        if (showMessage) {
            result.put('showWarning', true);
            result.put(
                'message',
                Label.PEAC_Equipment_Cost_exceeds_Guidance_Amount
            );
        }

        return result;
    }

}