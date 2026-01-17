public with sharing class SL_MiscBillableItemTriggerHandler extends SL_Trigger.baseHandler {
    private Set<Id> mbiIds = new Set<Id>();
    Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();

    public override void beforeInsert(List<SObject> newList){
        for (SObject theObject :newList){
            getLookupMaps(theObject);
        }
        beforeChangesToSelf(newList, true);        
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        checkUpdatedFields(oldMap, newMap);
        for (Id mbiId :newMap.keySet()){
            SObject theObject = newMap.get(mbiId);
            getLookupMaps(theObject);
        }
        beforeChangesToSelf(newMap.values(), false);
    }

    public override void afterInsert(Map<Id, SObject> newMap){
        afterChangesToOthers(newMap, true);  
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        checkUpdatedFields(oldMap, newMap);
        // for (Id mbiId :newMap.keySet()){
        //     SObject theObject = newMap.get(mbiId);
        //     getLookupMaps(theObject);
        // }
        afterChangesToOthers(newMap, false);
    }
    
    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = new List<String>();
        if(Trigger.isBefore){
            fieldsToCheck = new List<String>{'Included_in_Rental__c', 'Misc_GL_Code__c', 'Misc_Item_Description__c', 'Pay_Code__c'};
        }else{// isAfter
            fieldsToCheck = new List<String>{'Misc_GL_Code__c'};
        }
        for(Id miscInvoiceItemId :newMap.keySet()){
            Miscellaneous_Billable_Item__c miscBillableItem = (Miscellaneous_Billable_Item__c)newMap.get(miscInvoiceItemId);
            Miscellaneous_Billable_Item__c oldMBI = (Miscellaneous_Billable_Item__c)oldMap.get(miscInvoiceItemId);
            
            SL_TriggerUtil.findChangedFields(miscInvoiceItemId, miscBillableItem, oldMBI, fieldsChangedById, fieldsToCheck);
        }
            
    }

    private void getLookupMaps(SObject obj){
        Miscellaneous_Billable_Item__c theMbi = (Miscellaneous_Billable_Item__c)obj;
        if(theMbi.Opportunity__c != null){
            this.opps.put(theMbi.Opportunity__c, new Opportunity());
        }
        if(theMbi.Id != null){
            this.mbiIds.add(theMbi.Id);
            //child records 
            // this.permissionSetsAssigned.put(theMbi.Id, new List<PermissionSetAssignment>());          
        }
    }

    private void getInfoFromOthers(){
        if(mbiIds.size() > 0){
            for(Miscellaneous_Billable_Item__c related : [SELECT Id, Opportunity__r.First_Payment_Date__c, Opportunity__r.Payment_Frequency__c,
                Opportunity__r.Primary_Dealer__r.Dealer__c
                FROM Miscellaneous_Billable_Item__c WHERE Id IN:mbiIds]){
                if(this.opps.get(related.Opportunity__c) != null){
                    this.opps.put(related.Opportunity__c, related.Opportunity__r);
                }
                // child records
                // List<PermissionSetAssignment> relatedPermissionSets = new List<PermissionSetAssignment>();
                // for(PermissionSetAssignment thePSA: related.PermissionSetAssignments){
                //     relatedPermissionSets.add(thePSA);
                // }
                // this.permissionSetsAssigned.get(related.Id).addAll(relatedPermissionSets);
            }
        }
        if(Trigger.isBefore && this.opps.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.opps.values())){
            this.opps.putAll([SELECT Id, First_Payment_Date__c, Payment_Frequency__c, Primary_Dealer__r.Dealer__c
                FROM Opportunity WHERE Id IN :this.opps.keySet()]);
        }
    }

    private void beforeChangesToSelf(List<SObject> newList, Boolean isNew){
        getInfoFromOthers();
        codingsByGLCode = prepareMiscCodingMatrix('Miscellaneous_Billable_Item__c');// SAL-5299 Misael Romero
        for(SObject obj :newList){
            Miscellaneous_Billable_Item__c theMbi = (Miscellaneous_Billable_Item__c)obj;
            Opportunity theOpp = this.opps.get(theMbi.Opportunity__c);
            List<String> fieldsChanged = fieldsChangedById.get(theMbi.Id);
            MiscBillableDefaultRulesFormerPB(theMbi, theOpp, fieldsChanged, isNew);// SAL-5897 Misael Romero
            updateUsingMiscCodingMatrix(theMbi, fieldsChanged, isNew, 'Misc_GL_Code__c');// SAL-5299 Misael Romero
        }
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNew){
        getInfoFromOthers();
        for (SObject obj :newMap.values()){
            Miscellaneous_Billable_Item__c miscBillableItem = (Miscellaneous_Billable_Item__c)obj;
            List<String> fieldsChanged = fieldsChangedById.get(miscBillableItem.Id);
            miscInvoiceActionsFormerPB(miscBillableItem, fieldsChanged, isNew);      
        }
    }

    public static void miscInvoiceActionsFormerPB(Miscellaneous_Billable_Item__c miscBillableItem, List<String> fieldsChanged, Boolean isNew) {
        if(!System.isFuture() && !System.isBatch()){
            if(miscBillableItem.Opportunity__c != null && (isNew
                || (fieldsChanged != null && fieldsChanged.contains('Misc_GL_Code__c')))
                && !TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.contains(miscBillableItem.Opportunity__c)){
                TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.add(miscBillableItem.Opportunity__c);
                List<Id> oppIds = new List<Id>{miscBillableItem.Opportunity__c};
                if(!Test.isRunningTest()){
                    TaxRules.runAutoGenerate(oppIds); //SAL-5468 Misael Romero
                }
            }
        }
    }
    // SAL-5897 Misael Romero
    public static void MiscBillableDefaultRulesFormerPB(Miscellaneous_Billable_Item__c theMbi, Opportunity theOpp, List<String> fieldsChanged, Boolean isNew){
        Boolean changedGLCode = fieldsChanged != null && fieldsChanged.contains('Misc_GL_Code__c');
        Boolean changedPayCode = fieldsChanged != null && fieldsChanged.contains('Pay_Code__c');
        Boolean changedDescription = fieldsChanged != null && fieldsChanged.contains('Misc_Item_Description__c');
        if((isNew || changedGLCode)){
            if(!changedDescription){
                theMbi.Misc_Item_Description__c = String.isBlank(theMbi.Misc_GL_Code__c)? null: theMbi.Misc_GL_Code__c.substringAfter(' - ');
            }
            // SAL-5299 Misael Romero
            theMbi.CB_Disp__c = false;
            theMbi.Future_Bill_Misc_Type__c = true;
            // List<String> glCodesForFutureBill = new List<String>{'0017 - Service Contract', '0018 - Property Tax', 
            //     '0033 - Postage Meter Fees', '0041 - E-Waste Disposal Fee', '0065 - Medical Consumable', '0066 - Medical Service Fee',
            //     '0090 - Convenience Fee', '0092 - Servicing Fee'};
            // if((glCodesForFutureBill.contains(theMbi.Misc_GL_Code__c)) 
            //     && (theMbi.Future_Bill_Misc_Type__c != true || theMbi.Included_in_Rental__c != true)){
            //     theMbi.CB_Disp__c = true;
            //     theMbi.Future_Bill_Misc_Type__c = true;
            //     theMbi.Included_in_Rental__c = true;
            // }
            // if(!changedPayCode){
            //     List<String> glCodesForPayDealer = new List<String>{'0017 - Service Contract', '0033 - Postage Meter Fees', 
            //         '0065 - Medical Consumable', '0066 - Medical Service Fee'};
            //     if(glCodesForPayDealer.contains(theMbi.Misc_GL_Code__c) && theMbi.Pay_Code__c != '1'){
            //         theMbi.Pay_Code__c = '1';
            //     }
            //     List<String> glCodesForDontPayDealer = new List<String>{'0018 - Property Tax', '0041 - E-Waste Disposal Fee', 
            //         '0090 - Convenience Fee', '0092 - Servicing Fee'};
            //     if(glCodesForDontPayDealer.contains(theMbi.Misc_GL_Code__c) && theMbi.Pay_Code__c != '0'){
            //         theMbi.Pay_Code__c = '0';
            //     }
            // }
        }
        if(theMbi.Final_Payment_Date__c != null && theMbi.Amount__c < 0){// this seems to be only for negative amounts... the PB was like that, so maybe ask the business
            theMbi.Final_Payment_Date__c = null;
        }
        if(theOpp != null){
            if(isNew){
                if(theOpp.First_Payment_Date__c != null){
                    theMbi.Due_Date__c = theOpp.First_Payment_Date__c;
                    theMbi.First_Payment_Date__c = theOpp.First_Payment_Date__c;
                }
                if(theOpp.Payment_Frequency__c != null){
                    theMbi.Billing_Cycle__c = theOpp.Payment_Frequency__c;
                }
            }
            if(theMbi.Dealer__c == null){
                theMbi.Dealer__c = theOpp.Primary_Dealer__r?.Dealer__c;
            }
        }
    }

    public static Map<String, List<Misc_Coding_Matrix__mdt>> codingsByGLCode;
    public static Map<String, Schema.SObjectField> miscFieldsMap;

    public static Map<String, List<Misc_Coding_Matrix__mdt>> prepareMiscCodingMatrix(String objApiName){
        codingsByGLCode = new Map<String, List<Misc_Coding_Matrix__mdt>>();
        for(Misc_Coding_Matrix__mdt miscCoding : [SELECT Object_Name__c, GL_Code__c, Field_To_Update__c, Value_To_Update__c
            FROM Misc_Coding_Matrix__mdt WHERE Object_Name__c = :objApiName]){
            List<Misc_Coding_Matrix__mdt> existingCodings = codingsByGLCode.get(miscCoding.GL_Code__c) ?? new List<Misc_Coding_Matrix__mdt>();
            existingCodings.add(miscCoding);
            codingsByGLCode.put(miscCoding.GL_Code__c, existingCodings);
        }
        miscFieldsMap = ((SObject)(Type.forName('Schema.'+objApiName).newInstance())).getSObjectType().getDescribe().fields.getMap();
        return codingsByGLCode;
    }
    public static void updateUsingMiscCodingMatrix(SObject theMisc, List<String> fieldsChanged, Boolean isNew, String glCodeField){
        Boolean changedGLCode = fieldsChanged != null && fieldsChanged.contains(glCodeField);
        if((isNew || changedGLCode)){
            String actualGLCode = ((String)theMisc.get(glCodeField)).left(4);
            List<Misc_Coding_Matrix__mdt> codingsToUse = codingsByGLCode.get(actualGLCode);
            if(codingsToUse != null){
                for(Misc_Coding_Matrix__mdt mcm : codingsToUse){
                    if(fieldsChanged == null || !fieldsChanged.contains(mcm.Field_To_Update__c)){
                        String fieldType = miscFieldsMap.get(mcm.Field_To_Update__c).getDescribe().getType().toString();
                        Object convertedValue = mcm.Value_To_Update__c;
                        switch on fieldType {
                            when 'BOOLEAN' {
                                convertedValue = Boolean.valueOf(mcm.Value_To_Update__c);
                            }
                            when 'DATE' {
                                convertedValue = Date.valueOf(mcm.Value_To_Update__c);
                            }
                            when 'DATETIME' {
                                convertedValue = Datetime.valueOfGmt(mcm.Value_To_Update__c.replace('T',' ').replace('Z',''));
                            }
                            when 'INTEGER' {
                                convertedValue = Integer.valueOf(mcm.Value_To_Update__c);
                            }
                        }
                        theMisc.put(mcm.Field_To_Update__c, convertedValue);
                    }
                }
            }
        }
    }
}