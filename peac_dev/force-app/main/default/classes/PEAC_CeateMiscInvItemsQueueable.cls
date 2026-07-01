/************************************************************************************************************************
 @Description: Project Expo - eWaste Fee Automation - When the opportunity status is updated to ‘Docs IN’,
        get all the assets of the opportunity with Screensize populated and Equipment State is CA and
        Then create e-Waste Misc Invoice record grouped by screen size
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: February/10/2026
 @User Story:SAL-6047
*************************************************************************************************************************/

public without sharing class PEAC_CeateMiscInvItemsQueueable implements Queueable{
    Set<Id> optyIdSet;
    public PEAC_CeateMiscInvItemsQueueable(Set<Id> optyIdSet) {
        this.optyIdSet = optyIdSet;
    }
    public void execute(QueueableContext qc)
    {
        createMiscellaneousInvoiceItems(optyIdSet);
    }
    //SAL-6047 : Project Expo - eWaste Fee Automation - Start
    /*When the opportunity status is updated to ‘Docs IN’,
        get all the assets of the opportunity with Screensize populated and Equipment State is CA and
        Then create e-Waste Misc Invoice record grouped by screen size
    */  
    public static void createMiscellaneousInvoiceItems(List<Opportunity> newList,Map<Id,Opportunity> oldMap) {
        Set<Id> optyIdSet = new Set<Id>();
        for(Opportunity opty: newList) {
            if(opty.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_DOCS_IN  && opty.StageName != oldMap.get(opty.Id).StageName && !opty.Loan_Record_Type__c) {
                optyIdSet.add(opty.id);
            }
        }
        if(!optyIdSet.isEmpty())
        {
            System.enqueueJob( new PEAC_CeateMiscInvItemsQueueable(optyIdSet));
       
        }
    }   
    public static void createMiscellaneousInvoiceItems(Set<Id> optyIdSet) {
        if(!optyIdSet.isEmpty()) {
            List<Asset__c> assets = new List<Asset__c>();
            List<Miscellaneous_Invoice_Item__c> miscellaneousInvoiceItemList = new List<Miscellaneous_Invoice_Item__c>();
            miscellaneousInvoiceItemList = [Select Id,Opportunity__c FROM Miscellaneous_Invoice_Item__c WHERE Opportunity__c IN:optyIdSet AND GL_Code__c =:PEAC_ConstantClass.GLCODE_EWASTEDISPOSALFEE];
            system.debug(optyIdSet);
            if(!miscellaneousInvoiceItemList.isEmpty()) {
                delete miscellaneousInvoiceItemList;
                miscellaneousInvoiceItemList = new List<Miscellaneous_Invoice_Item__c>();
            }
            assets = [Select Opportunity__c,Screen_Size__c,Equipment_State__c FROM Asset__c WHERE Opportunity__c IN:optyIdSet AND Screen_Size__c!=null 
                        AND Equipment_State__c IN:System.label.PEAC_Screen_Asset_States.split(',')];
            if(!assets.isEmpty()) {
                Map<String,Map<String,Integer>> opportunityAssetMap = new Map<String,Map<String,Integer>>();
                List<Miscellaneous_Invoice_Map__mdt>  miscellaneousInvoiceMapRecords = new List<Miscellaneous_Invoice_Map__mdt>();
                miscellaneousInvoiceMapRecords = [Select Id,Min_Screen_Size__c,Max_Screen_Size__c,Amount__c FROM Miscellaneous_Invoice_Map__mdt];
                if(!miscellaneousInvoiceMapRecords.isEmpty()){
                    Map<String,Decimal> miscellaneousInvoiceMap = new Map<String,Decimal>();
                    for(Miscellaneous_Invoice_Map__mdt miscellaneousInvoiceMapRecord: miscellaneousInvoiceMapRecords) {
                        miscellaneousInvoiceMap.put(String.valueOf(miscellaneousInvoiceMapRecord.Min_Screen_Size__c) + '_' + String.valueOf(miscellaneousInvoiceMapRecord.Max_Screen_Size__c), miscellaneousInvoiceMapRecord.Amount__c);
                    }
                    for(Asset__c asset: assets) {
                        for(Miscellaneous_Invoice_Map__mdt miscellaneousInvoiceMapRecord: miscellaneousInvoiceMapRecords) {
                            String key = miscellaneousInvoiceMapRecord.Min_Screen_Size__c + '_' + miscellaneousInvoiceMapRecord.Max_Screen_Size__c;
                            if(asset.Screen_Size__c >= miscellaneousInvoiceMapRecord.Min_Screen_Size__c && asset.Screen_Size__c <= miscellaneousInvoiceMapRecord.Max_Screen_Size__c) {
                                Map<String,Integer> assetMap = new Map<String,Integer>();
                                if(opportunityAssetMap.containsKey(asset.Opportunity__c)) {
                                    assetMap = opportunityAssetMap.get(asset.Opportunity__c);
                                    if(assetMap.containsKey(key)) {
                                        assetMap.put(key,assetMap.get(key) + 1);
                                    }else {
                                        assetMap.put(key,1);
                                    }
                                }else {
                                    assetMap.put(key,1); 
                                }
                                opportunityAssetMap.put(asset.Opportunity__c,assetMap);
                                break;
                            }
                        }
                    }

                    for(String opty: opportunityAssetMap.keyset()) {
                        Map<String,Integer> assetMap = opportunityAssetMap.get(opty);
                        for(String screen: assetMap.keyset()) {    
                                Miscellaneous_Invoice_Item__c miscellaneousInvoiceItem = new Miscellaneous_Invoice_Item__c();
                                miscellaneousInvoiceItem.Opportunity__c = opty;
                                if(miscellaneousInvoiceMap.containsKey(screen) && !String.isBlank(String.valueOf(miscellaneousInvoiceMap.get(screen)))){
                                    miscellaneousInvoiceItem.Amount__c =  assetMap.get(screen) * miscellaneousInvoiceMap.get(screen);
                                }else{
                                    miscellaneousInvoiceItem.Amount__c =  0;
                                }
                                miscellaneousInvoiceItem.GL_Code__c = PEAC_ConstantClass.GLCODE_EWASTEDISPOSALFEE;
                            	miscellaneousInvoiceItem.Pay_Code__c = '0';
                                miscellaneousInvoiceItemList.add(miscellaneousInvoiceItem);
                        }
                    }
                }
                if(!miscellaneousInvoiceItemList.isEmpty()) {
                    insert miscellaneousInvoiceItemList;
                    TaxRules.runAutoGenerate(new List<Id>(optyIdSet)); //SAL-5468 Misael Romero   
                }
            }
        }
    }
}