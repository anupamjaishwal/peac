public without sharing class TC_DocFeeRuleHelper {
    
    // temp CVG, should be excluded from all rules. Should always be 595
    public static void setDocFeesCVG (Set <Id> oppIds) {
        List <Opportunity> updateList = new List <Opportunity> ();
        for (Id oppId : oppIds) {
            updateList.add (new Opportunity (Id = oppId, Documentation_Fee__c = 595));
        }
        if (!updateList.isEmpty ()) update updateList;
    }
    
    public static void setDocFees (Set <Id> oppIds) {
        // uncommenting as per 4/4/2023 to see the logs.
        // temp logging
        for (Id oppId : oppIds) {
            MARLIN_IntegrationLog.addLog('Doc Fee Triggered', oppId, 'Success', 'not an integration', 'Doc Fee fired for: ' + oppId, '', '');
        }



        System.debug ('made it here');
        
        // 1. Get Doc Fee by Primary Dealer
        Map <Id, Decimal> docFees = new Map <Id, Decimal> ();
        docFees = getDocFeeByPrimaryDealer (oppIds);
        removeOppsWithDocFees (docFees, oppIds);
        
        // 2. Get Doc Fee by Rules
        docFees.putAll (getDocFeeByRule (oppIds));
        removeOppsWithDocFees (docFees, oppIds);
        
        // 3. Get Doc Fee by Channel
        docFees.putAll (getChannelDocFees (oppIds));
        removeOppsWithDocFees (docFees, oppIds);
        
        //4. Check if Funding Type = Pre-Delivery/Delivery Guarantee
        Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id, Opportunity_Funding_Type__c FROM Opportunity WHERE Id IN :docFees.keySet ()]);
        
        List <Opportunity> updateList = new List <Opportunity> ();
        
        for (Id oppId : docFees.keySet ()) {
            //Add null check for SAL-3483
            Decimal docFee;
            if(docFees.get (oppId) != null){
                docFee = docFees.get (oppId);
            }
            else{
                docFee = 0;
            }
            if (oppMap.get (oppId).Opportunity_Funding_Type__c == 'Delivery Guarantee' || oppMap.get (oppId).Opportunity_Funding_Type__c == 'Pre-delivery') {
                docFee+=100;
            }
            updateList.add (new Opportunity (Id = oppId, Documentation_Fee__c = docFee));
        }
        System.debug ('opps: ' + updateList);
        if (!updateList.isEmpty ()) update updateList;
        MARLIN_IntegrationLog.insertLogs ();
        
    }
    
    // remove from opp id from set so opp isn't part of doc fee search anymore
    public static void removeOppsWithDocFees (Map <Id, Decimal> docFees, Set <Id> oppIds) {
        for (Id oppId : oppIds) {
            if (docFees.get (oppId) != null) oppIds.remove (oppId);
        }
    }
    
    
    public static Map <Id, Decimal> getDocFeeByPrimaryDealer (Set <Id> oppIds) {
        
        Map <Id, Decimal> returnMap = new Map <Id, Decimal> ();
        for (Opportunity opp : [SELECT Id, (SELECT Dealer__r.Doc_Fee__c FROM Brokers__r WHERE Primary_Dealer__c = true) FROM Opportunity WHERE Id IN :oppIds]) {
            if (!opp.Brokers__r.isEmpty ()) { 
                String docFeeStr = opp.Brokers__r[0].Dealer__r.Doc_Fee__c;
                Decimal docFee = null;
                if (docFeeStr != null) {
                    if (docFeeStr == 'Waived') {
                        docFee = 0;
                    } else if (docFeeStr == 'Standard') {
                        docFee = null;
                    } else if (docFeeStr.contains ('$')) {
                        docFee = Decimal.valueOf (docFeeStr.remove ('$'));
                    } else {
                        docFee = Decimal.valueOf (docFeeStr);
                    }
                }
            	returnMap.put (opp.Id, docFee);
            }
        }
        
        return returnMap;
    }

	public static final String DOC_FEE_OBJ_APINAME = 'Doc_Fee_Rule__c';
    
    public class DocFeeRuleWrapper {
        public Id oppId;
        public Map<Id, Boolean> resultsOpp;
        public Map<Id, Boolean> resultsFirstAsset;
        public Map<Id, Boolean> resultsPrimaryDealer;
        
        public Decimal docFee;
        public DocFeeRuleWrapper (Id oppId) {
            this.oppId = oppId;
        }
        
    }
    
    public static Map <Id, Decimal> getDocFeeByRule (Set <Id> oppIds) {
        
        // run rules on the opportunity
        TCRE.RuleEngine reOpp = new TCRE.RuleEngine();
        reOpp.logicObjectIds = oppIds;
		reOpp.ruleObjectType = DOC_FEE_OBJ_APINAME;
		reOpp.TestRuleConditions();
        
        // get first assets
        Map <Id, Opportunity> additionalOppValues = new Map <Id, Opportunity> ([SELECT ID, (SELECT Id FROM Assets__r ORDER BY CreatedDate ASC LIMIT 1) FROM Opportunity WHERE Id IN :oppIds]);
        Set <Id> oppAssetIds = new Set <Id> ();
        Map <Id, Id> oppAssets = new Map <Id, Id> ();
        for (Opportunity opp : additionalOppValues.values ()) {
            if (!opp.Assets__r.isEmpty ()) {
                oppAssets.put (opp.Id, opp.Assets__r[0].Id);
                oppAssetIds.add (opp.Assets__r[0].Id);
            }
        }
        
        // run rules on first assets
        TCRE.RuleEngine reAsset = new TCRE.RuleEngine();
		reAsset.logicObjectIds = oppAssetIds;
		reAsset.ruleObjectType = DOC_FEE_OBJ_APINAME;
		reAsset.TestRuleConditions();
        
        // get primary dealer account
        
        Map <Id, Opportunity> oppPrimaryDealer = new Map <Id, Opportunity> ([SELECT ID, (SELECT Dealer__c FROM Brokers__r WHERE Primary_Dealer__c = true) FROM Opportunity WHERE Id IN :oppIds]);
		Map <Id, Id> oppDealers = new Map <Id, Id> ();
        Map <Id, Id> dealerOpps = new Map <Id, Id> ();
        for (Opportunity opp : oppPrimaryDealer.values ()) {
            if (!opp.Brokers__r.isEmpty () && opp.Brokers__r[0].Dealer__c != null) {
                dealerOpps.put (opp.Brokers__r[0].Dealer__c, opp.Id);
                oppDealers.put (opp.Id, opp.Brokers__r[0].Dealer__c);
            }
        }
        
        // run rules on primary dealer
        TCRE.RuleEngine reDealer = new TCRE.RuleEngine();
		reDealer.logicObjectIds = dealerOpps.keySet ();
		reDealer.ruleObjectType = DOC_FEE_OBJ_APINAME;
		reDealer.TestRuleConditions();
        
        // get apex rules
		List <Doc_Fee_Rule__c> docFeeRules = new List <Doc_Fee_Rule__c> ([SELECT Id, Doc_Fee_Amount__c, Rule_Config__c, Apex_Class_Define_Entry_Criteria_Value__c  FROM Doc_Fee_Rule__c ORDER BY Order__c ASC]);
        
        Set <String> apexClasses = new Set <String> ();
        // not using wrapper becuase i need to do extra looping to force it into that structure
        // if decimal is null, it means entry criteria has not been met
        Map <String, Map <Id, Decimal>> apexClassResults = new Map <String, Map <Id, Decimal>> ();
        
        for (Doc_Fee_Rule__c docFeeRule : docFeeRules) {
            if (docFeeRule.Apex_Class_Define_Entry_Criteria_Value__c != null) apexClasses.add (docFeeRule.Apex_Class_Define_Entry_Criteria_Value__c);
        }
        
        for (String apexClass : apexClasses) {
            Type t = Type.forName(apexClass);
			TC_DocFeeRule rule = (TC_DocFeeRule) t.newInstance();
            apexClassResults.put (apexClass, rule.runDocFeeRule (oppIds));
        }
        
        
        // handle results
        
        List <DocFeeRuleWrapper> ruleWrappers = new List <DocFeeRuleWrapper> ();
        
        for (Id oppId : oppIds) {
            DocFeeRuleWrapper dfrw = new DocFeeRuleWrapper (oppId);
            dfrw.resultsOpp = reOpp.ruleResults.get(oppId);
            dfrw.resultsFirstAsset = reAsset.ruleResults.get(oppAssets.get (oppId));
            dfrw.resultsPrimaryDealer = reDealer.ruleResults.get(oppDealers.get (oppId));
            ruleWrappers.add (dfrw);
        }
        
        // check rules
        
        for (DocFeeRuleWrapper dfrw : ruleWrappers) {
            for (Doc_Fee_Rule__c docFeeRule : docFeeRules) {
                
                Decimal docFee;
                // users should never have docFeeRule.Rule_Config__c and docFeeRule.Apex_Class_Define_Entry_Criteria_Value__c populate at the same time
                if (docFeeRule.Rule_Config__c != null) {
                    // deciding if logic is based on rule engine or apex class
                    if (dfrw.resultsOpp != null && !dfrw.resultsOpp.isEmpty () && dfrw.resultsOpp.get (docFeeRule.Rule_Config__c)) {
                        // check if opp rule is true
                        docFee = docFeeRule.Doc_Fee_Amount__c;
                    } else if (dfrw.resultsFirstAsset != null && !dfrw.resultsFirstAsset.isEmpty() && dfrw.resultsFirstAsset.get (docFeeRule.Rule_Config__c) != null && dfrw.resultsFirstAsset.get (docFeeRule.Rule_Config__c) == true) {
                        // check if first asset rule is true
                        docFee = docFeeRule.Doc_Fee_Amount__c;
                    } else if (dfrw.resultsPrimaryDealer != null && !dfrw.resultsPrimaryDealer.isEmpty() && dfrw.resultsPrimaryDealer.get (docFeeRule.Rule_Config__c) != null && dfrw.resultsPrimaryDealer.get (docFeeRule.Rule_Config__c) == true ) {
                        // check if primary dealer rule is true
                        docFee = docFeeRule.Doc_Fee_Amount__c;
                    } 
                } else  if (docFeeRule.Apex_Class_Define_Entry_Criteria_Value__c != null && apexClassResults != null && apexClassResults.get (docFeeRule.Apex_Class_Define_Entry_Criteria_Value__c) != null && apexClassResults.get (docFeeRule.Apex_Class_Define_Entry_Criteria_Value__c).get (dfrw.oppId) != null) {
                    // checking apex class
                    docFee = apexClassResults.get (docFeeRule.Apex_Class_Define_Entry_Criteria_Value__c).get (dfrw.oppId);
                }
                
                if (docFee != null) {
                    // once doc fee is found go to the next deal, priority should be used to resolve overlapping rules
                    dfrw.docFee = docFee;
                    break;
                }
            }
        }
        
        Map <Id, Decimal> returnMap = new Map <Id, Decimal> ();
        for (DocFeeRuleWrapper dfrw : ruleWrappers) {
            returnMap.put (dfrw.oppId, dfrw.docFee);
        }
		return returnMap;
        
    }
    public static Map <Id, Decimal> getChannelDocFees (Set <Id> oppIds) {
        
        Map <Id, Decimal> returnMap = new Map <Id, Decimal> ();
        
        List <Opportunity> opps = new List <Opportunity> ([SELECT Id, Equipment_Cost__c, Opportunity_Funding_Type__c, Channel__c, OwnerId  FROM Opportunity WHERE Id IN :oppIds]);
        
        // to avoid running into the 2000 query limit, finding the max/min values
        Decimal maxCost;
        Decimal lowCost;
        Set <String> channels = new Set <String> ();
        
        for (Opportunity opp : opps) {
            System.debug ('>>>>> Channel: ' + opp.Channel__c);
            System.debug ('>>>>> opp.Equipment_Cost__c: ' + opp.Equipment_Cost__c);
            if (maxCost == null || opp.Equipment_Cost__c > maxCost) maxCost = opp.Equipment_Cost__c;
            if (lowCost == null || opp.Equipment_Cost__c < lowCost) lowCost = opp.Equipment_Cost__c; 
            channels.add (opp.Channel__c);
        }
        
        
        List <Doc_Fee_Schedule__c > docSchedules = new List <Doc_Fee_Schedule__c > ([SELECT Approver__c
                                                                                     , Channel__c
                                                                                     , Documentation_Fee__c
                                                                                     , Documuntation_Fee_DG__c
                                                                                     , Range_High__c
                                                                                     , Range_Low__c
                                                                                     , Pre_Delivery_Install_Fee__c
                                                                                    FROM Doc_Fee_Schedule__c
                                                                                    WHERE Channel__c IN :channels 
                                                                                    LIMIT 2000]);
        
        // loop through each opp, then loop through each doc schedule
        for (Opportunity opp : opps) {
            for (Doc_Fee_Schedule__c docSchedule : docSchedules) {
                if (docSchedule.Range_High__c >= opp.Equipment_Cost__c && docSchedule.Range_Low__c <= opp.Equipment_Cost__c && docSchedule.Channel__c == opp.Channel__c) {
                    /*if (opp.Opportunity_Funding_Type__c == 'Delivery Guarantee') {
                        returnMap.put (opp.Id, docSchedule.Documuntation_Fee_DG__c);
                    } else if (opp.Opportunity_Funding_Type__c == 'Pre-delivery') {
                        returnMap.put (opp.Id, docSchedule.Documuntation_Fee_DG__c );
                    } else {
                        returnMap.put (opp.Id, docSchedule.Documentation_Fee__c);
                    }*/
                    returnMap.put (opp.Id, docSchedule.Documentation_Fee__c);
                    break;
                }
            }
        }
        
        // uncommenting as per 4/4/2023 to see the logs.
        // channel error logging basic
        if (!opps.isEmpty()) {
            for (Opportunity opp : opps) {
                MARLIN_IntegrationLog.addLog('Doc Fee Channel Run', opp.Id, 'Success', 'not an integration', String.valueOf (opp), '', '');
            }
            MARLIN_IntegrationLog.insertLogs ();
        }


        return returnMap;
    }
    

}