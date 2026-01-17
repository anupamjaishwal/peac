/**
 * Created by tamarack on 2/24/20.
 */

public with sharing class TC_RetrieveAutoNumber {

    // Invocable function called from process builder TC Opportunity: Set Auto Number. Created so functionality could be easily de/activated via PB.
    @InvocableMethod(label='Retrieve Auto Number' description='Creates an Auto_Number__c record and returns the generated number')
    public static void retrieve(List<Opportunity> oppList) {

        Set<Id> oppIdSet = new Set<Id>();
        List<Auto_Number__c> autoNumberList = new List<Auto_Number__c>();
        for (Opportunity opp : oppList) {
            autoNumberList.add(new Auto_Number__c(Opportunity__c = opp.Id));
            oppIdSet.add(opp.Id);
        }
        insert autoNumberList;

        List<Auto_Number__c> autoNumberQueryList = new List<Auto_Number__c>([
                SELECT Id, Name, Opportunity__c
                FROM Auto_Number__c
                WHERE Opportunity__c IN: oppIdSet
        ]);

        List<Opportunity> oppUpdateList = new List<Opportunity>();
        Map<Id, Integer> oppIdAutoNumberMap = new Map<Id, Integer>();
        for (Auto_Number__c autoNumber : autoNumberQueryList) {
            // Unsure whether they want to maintain all leading zeros so I'm casting to Integer and then back to String for now
            oppUpdateList.add(new Opportunity(Id = autoNumber.Opportunity__c, Application_Test__c = String.valueOf(Integer.valueOf(autoNumber.Name))));
        }
        delete autoNumberList;
        update oppUpdateList;

    }

    // Function call if retrieval of auto-generated number is not on opportunity create. Returns map of <Key = Id oppId, Value = Integer autoNumber>
    public static Map<Id, Integer> retrieve(Set<Id> oppIdSet) {

        List<Auto_Number__c> autoNumberList = new List<Auto_Number__c>();
        for (Id oppId : oppIdSet) {
            autoNumberList.add(new Auto_Number__c(Opportunity__c = oppId));
        }
        insert autoNumberList;

        List<Auto_Number__c> autoNumberQueryList = new List<Auto_Number__c>([
                SELECT Id, Name, Opportunity__c
                FROM Auto_Number__c
                WHERE Opportunity__c IN: oppIdSet
        ]);

        Map<Id, Integer> oppIdAutoNumberMap = new Map<Id, Integer>();
        for (Auto_Number__c autoNumber : autoNumberQueryList) {
            oppIdAutoNumberMap.put(autoNumber.Opportunity__c, Integer.valueOf(autoNumber.Name));
        }
        delete autoNumberList;

        return oppIdAutoNumberMap;

    }
    
    public static void updateOppAppNumber (Set <Id> oppIds) {
        
        	System.debug ('>>>>> auto number generation: ' + UserInfo.getProfileId());
        	System.debug ('>>>>> auto number generation: ' + UserInfo.getUserName());
        //getUserName()
        
            
            Map<Id, Integer> appNums = retrieve (oppIds);
            List <Opportunity> updateList = new List <Opportunity> (); 
            
            for (Id oppId : appNums.keySet ()) {
                updateList.add (new Opportunity (Id = oppId, Application__c = appNums.get (oppId) != null ? String.valueOf (appNums.get (oppId)) : ''));
            }
            
            if (!updateList.isEmpty()) update updateList;
    }
   

}