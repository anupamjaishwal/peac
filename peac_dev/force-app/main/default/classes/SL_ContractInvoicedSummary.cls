public class SL_ContractInvoicedSummary {
//DP-904 - Carlos Herrera
    @AuraEnabled
    public static List<Map<String,Object>> SummaryAccount(String AccountId){
        List<String> RowTypes = new List<String>{'Lease Payment','Service','Equipment Protection Program', 'Asset Usage', 'Documentation Fees',
            'Late Fee', 'Supply Freight Fee', 'Remote Fee', 'Taxes', 'Miscellaneous'};
        List<Map<String,Object>> dataTab = new List<Map<String,Object>>();        
        List<Contract_Invoiced_Amount__c> AccCIA = new List<Contract_Invoiced_Amount__c>();
        AccCIA = [Select Id, Current_Amount_Due__c, Past_Due__c, Total__c, Type__c From Contract_Invoiced_Amount__c Where CCAN__c =:AccountId];
        for(String CIAType:RowTypes){            
            Decimal currentAmount = 0;
            Decimal pastDue = 0;
            Decimal Total = 0;
            String TabResults;
            Map<String,Object> dataFormated = new Map<String,Object>();
            if(AccCIA.size()>0){
                for(Contract_Invoiced_Amount__c obj :AccCIA){                    
                    if(obj.Type__c == CIAType){
                        currentAmount = currentAmount + obj.Current_Amount_Due__c;
                        pastDue = pastDue + obj.Past_Due__c;
                        Total = Total + obj.Total__c;
                    }
                }
                TabResults= '{"name":"'+CIAType+'","currentAmount":'+currentAmount+',"pastDue":'+pastDue+',"Total":'+Total+'}';
                dataFormated = (Map<String,Object>)JSON.deserializeUntyped(TabResults);
                dataTab.add(dataFormated);
            }else{
                TabResults= '{"name":"'+CIAType+'","currentAmount":'+currentAmount+',"pastDue":'+pastDue+',"Total":'+Total+'}';
                dataFormated = (Map<String,Object>)JSON.deserializeUntyped(TabResults);
                dataTab.add(dataFormated);
            }
        }
        
        return dataTab;
        
    }
}