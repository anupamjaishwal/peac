public with sharing class SL_MiscInvoiceItemTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    private Set<Id> miiIds = new Set<Id>();
    Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
    
    public override void beforeInsert(List<SObject> newList){
        List<Miscellaneous_Invoice_Item__c> theList = new List<Miscellaneous_Invoice_Item__c>();
        for(SObject theObject :newList){
            getLookupMaps(theObject);
            theList.add((Miscellaneous_Invoice_Item__c)theObject);
        }
        
        beforeChangesToSelf(theList, true);        
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        checkUpdatedFields(oldMap, newMap);
        List<Miscellaneous_Invoice_Item__c> theList = new List<Miscellaneous_Invoice_Item__c>();
        for (Id opportunityId :newMap.keySet()){
            SObject theObject = newMap.get(opportunityId);
            getLookupMaps(theObject);
            theList.add((Miscellaneous_Invoice_Item__c)theObject);
        }
        beforeChangesToSelf(theList, false);
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        checkUpdatedFields(oldMap, newMap);
        // for (Id opportunityId :newMap.keySet()){
        //     SObject theObject = newMap.get(opportunityId);
        //     getLookupMaps(theObject);
        // }
        afterChangesToOthers(newMap, false);
    }

    public override void afterInsert(Map<Id, SObject> newMap){
        afterChangesToOthers(newMap, true);  
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = new List<String>{'CB_Disp__c', 'Description__c', 'GL_Code__c', 'Opportunity__c', 'Pay_Code__c'};
        for(Id miscInvoiceItemId :newMap.keySet()){
            Miscellaneous_Invoice_Item__c miscInvoiceItem = (Miscellaneous_Invoice_Item__c)newMap.get(miscInvoiceItemId);
            Miscellaneous_Invoice_Item__c oldMII = (Miscellaneous_Invoice_Item__c)oldMap.get(miscInvoiceItemId);
            
            SL_TriggerUtil.findChangedFields(miscInvoiceItemId, miscInvoiceItem, oldMII, fieldsChangedById, fieldsToCheck);
        }
            
    }

    private void getLookupMaps(SObject obj){
        Miscellaneous_Invoice_Item__c theMii = (Miscellaneous_Invoice_Item__c)obj;
        if(theMii.Opportunity__c != null){
            this.opps.put(theMii.Opportunity__c, new Opportunity());
        }
        if(theMii.Id != null){
            this.miiIds.add(theMii.Id);
            //child records 
            // this.permissionSetsAssigned.put(theMii.Id, new List<PermissionSetAssignment>());          
        }
    }

    private void getInfoFromOthers(){
        if(miiIds.size() > 0){
            for(Miscellaneous_Invoice_Item__c related : [SELECT Id, Opportunity__r.First_Payment_Date__c, Opportunity__r.Interim_Rent__c, 
                Opportunity__r.Documentation_Fee__c, Opportunity__r.Security_Deposit__c, Opportunity__r.StageName,
                Opportunity__r.Primary_Dealer__r.Dealer__c  
                FROM Miscellaneous_Invoice_Item__c WHERE Id IN:miiIds]){
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
            this.opps.putAll([SELECT Id, First_Payment_Date__c, Interim_Rent__c, Documentation_Fee__c, 
                Security_Deposit__c, StageName, Primary_Dealer__r.Dealer__c 
                 FROM Opportunity WHERE Id IN :this.opps.keySet()]);
        }
    }
    
    private void beforeChangesToSelf(List<Miscellaneous_Invoice_Item__c> newList, Boolean isNew){
        getInfoFromOthers();
        SL_MiscBillableItemTriggerHandler.codingsByGLCode = 
            SL_MiscBillableItemTriggerHandler.prepareMiscCodingMatrix('Miscellaneous_Invoice_Item__c');// SAL-5821 Misael Romero
        for(Miscellaneous_Invoice_Item__c theMii :newList){
            Opportunity theOpp = this.opps.get(theMii.Opportunity__c);
            List<String> fieldsChanged = fieldsChangedById.get(theMii.Id);
            miscInvoiceRulesFormerPB(theMii, theOpp, fieldsChanged, isNew);
            SL_MiscBillableItemTriggerHandler.updateUsingMiscCodingMatrix(theMii, fieldsChanged, isNew, 'GL_Code__c');// SAL-5821 Misael Romero
            // SAL-6006 Misael Romero
            Boolean isPayDealer = theMii.Pay_Code__c == '1';
            theMii.PassThrough__c = isPayDealer;
            // theMii.PaymentType__c = isPayDealer; // not requested yet, but misc billables do have it
            // theMii.PassThroughPercentage__c = isPayDealer? 100000: null;
        }
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNew){
        // getInfoFromOthers();
        for (SObject obj :newMap.values()){
            Miscellaneous_Invoice_Item__c miscInvoiceItem = (Miscellaneous_Invoice_Item__c)obj;
            List<String> fieldsChanged = fieldsChangedById.get(miscInvoiceItem.Id);
            miscInvoiceActionsFormerPB(miscInvoiceItem, fieldsChanged, isNew);                
        }
    }

    public static void miscInvoiceRulesFormerPB(Miscellaneous_Invoice_Item__c theMii, Opportunity theOpp, List<String> fieldsChanged, Boolean isNew){
        // List<String> payDealerCodes = Label.SL_MiiPayDealerCodes.split(',');// SAL-5821 Misael Romero
        Boolean changedGLCode = fieldsChanged != null && fieldsChanged.contains('GL_Code__c');
        Boolean changedPayCode = fieldsChanged != null && fieldsChanged.contains('Pay_Code__c');
        Boolean changedDescription = fieldsChanged != null && fieldsChanged.contains('Description__c');
        Boolean changedCbDisp = fieldsChanged != null && fieldsChanged.contains('CB_Disp__c');
        if((isNew || changedGLCode)){
            if(!changedDescription){
                theMii.Description__c = String.isBlank(theMii.GL_Code__c)? null: theMii.GL_Code__c.substringAfter(' - ');
            }
            // SAL-5821 Misael Romero
            // if(!changedPayCode){
            //     theMii.Pay_Code__c = payDealerCodes.contains(theMii.GL_Code__c.left(4))? '1': '0';
            // }
            if(!changedCbDisp){
                theMii.CB_Disp__c = true;
            }
        }
        if(theOpp != null){
            if((theMii.GL_Code__c == '0001 - Interim Rent' 
                || theMii.GL_Code__c == '0003 - OneTime Documentation Fee' 
                || theMii.GL_Code__c == '0005 - Security Deposit') && (changedGLCode
                || theMii.Amount__c == null)){
                switch on theMii.GL_Code__c {
                    when '0001 - Interim Rent' {
                        theMii.Amount__c = theOpp.Interim_Rent__c;
                    }
                    when '0003 - OneTime Documentation Fee' {
                        theMii.Amount__c = theOpp.Documentation_Fee__c;
                    }
                    when '0005 - Security Deposit' {
                        theMii.Amount__c = theOpp.Security_Deposit__c;
                    }
                }
            }
            if(isNew && theOpp.First_Payment_Date__c != null){
                theMii.Due_Date__c = theOpp.First_Payment_Date__c;
            }
            if(theMii.Dealer__c == null){
                theMii.Dealer__c = theOpp.Primary_Dealer__r?.Dealer__c;
            }
        }
        // SAL-6006 Misael Romero
        Boolean isPayDealer = theMii.Pay_Code__c == '1';
        theMii.PassThrough__c = isPayDealer;
        // theMii.PaymentType__c = isPayDealer; // not requested yet, but misc billables do have it
        // theMii.PassThroughPercentage__c = isPayDealer? 100000: null;
    }
    public static void miscInvoiceActionsFormerPB(Miscellaneous_Invoice_Item__c miscInvoiceItem, List<String> fieldsChanged, Boolean isNew) {
        if(!System.isFuture() && !System.isBatch()){
            if(miscInvoiceItem.Opportunity__c != null && (isNew
                || (fieldsChanged != null && (fieldsChanged.contains('GL_Code__c')
                || fieldsChanged.contains('Opportunity__c'))))
                && !TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.contains(miscInvoiceItem.Opportunity__c)){
                TC_RecursiveTriggerHelper.oppsAlreadyTaxMatrixRan.add(miscInvoiceItem.Opportunity__c);
                List<Id> oppIds = new List<Id>{miscInvoiceItem.Opportunity__c};
                if(!Test.isRunningTest()){
                    TaxRules.runAutoGenerate(oppIds); //SAL-5468 Misael Romero   
                }
            }
        }
    }

}