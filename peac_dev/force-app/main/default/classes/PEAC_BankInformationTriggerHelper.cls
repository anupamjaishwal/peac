/********************************************************************************************************************
@Author: Chalapati Murru(LTIMindtree)
@Description: This is a PEAC_BankInformationTriggerHelper class to support PEAC_BankInformationTriggerHandler
class
@User Story: SAL-5998
@Created Date: 29-Oct-2025
*********************************************************************************************************************/
public with sharing class PEAC_BankInformationTriggerHelper {
    /**************************************************************************************************************
    @Author: Chalapati Murru(LTIMindtree)
    @Description: This method will update Indicator__c field based on the existing bank account records
    @User Story: SAL-5998
    @Created Date: 29-Oct-2025
    **************************************************************************************************************/
    public static void setIndicator(Map<Id, SObject> newMap){
        List<Financial_Bank_Information__c> bankInfoList = new List<Financial_Bank_Information__c>();
        Set<Id> oppIds = new Set<Id>();

        for(Financial_Bank_Information__c bankInfo : (List<Financial_Bank_Information__c>)newMap.values()){
            oppIds.add(bankInfo.Opportunity__c);
        }
        Map<Id, Opportunity> oppBankInfoMap = new Map<Id, Opportunity>([SELECT Id, (SELECT Id, Indicator__c FROM Financial_Bank_Information__r ORDER BY CreatedDate) FROM Opportunity WHERE Id IN :oppIds]);
        
        for(Opportunity opp : oppBankInfoMap.values()){
            Integer count = 0;
            for(Financial_Bank_Information__c bankInfo : oppBankInfoMap.get(opp.Id).Financial_Bank_Information__r){
                count++;
                switch on count {
                when 1 {
                    bankInfo.Indicator__c = 'Primary';
                }
                when 2 {
                    bankInfo.Indicator__c = 'Backup';
                }
                when 3 {
                    bankInfo.Indicator__c = 'Other';
                }
                when else {
                    bankInfo.Indicator__c = '-';
                }
                }
                bankInfoList.add(bankInfo);
            }
        }
        if(!bankInfoList.isEmpty())
            update bankInfoList;
   }
}