public class TC_GdsScoreCtrl {
    
    @auraEnabled
    public static String callGdsScore (Id recordId) {
        try{
            TC_GdsScoreApi.runGdsScoreFromTriggeredAction (new Set <Id> {recordId});
        } catch(Exception e) {System.debug( e.getMessage() ); throw new AuraHandledException(e.getMessage()); }
        return '';
        //return TC_GdsScoreApi.runGdsScore (recordId); due to cpu limits
    }

    // SAL-2065
    @AuraEnabled
    public static String callDwhStoredProcFraudQuery(Id recordId ){
        try {
            TC_DwhStoredProcedureRespBean businessFraudRespBean = TC_DwhStoredProcedureApi.businessFraudQuery( recordId );
            System.debug( businessFraudRespBean );

            if( businessFraudRespBean <> null && !businessFraudRespBean.results.isEmpty() ){
                List<Opportunity> oppResult = [SELECT Id, CustomerType__c FROM Opportunity WHERE Id = :recordId];// SAL-5820 Misael Romero
                if(oppResult.size() > 0){
                    businessFraudRespBean.results[0].CustomerType = oppResult[0].CustomerType__c;
                }
                TC_DwhStoredProcedureMapper.mapBeansToWebserviceField(recordId, businessFraudRespBean);
            }
        } catch (Exception e) { System.debug( e.getMessage() ); throw new AuraHandledException(e.getMessage());
        } finally {
            MARLIN_IntegrationLog.insertLogs();
        }
        return '';
    }

    // process builder instead of trigger so i don't have to write a static variable to see if gds score was already ran, because the trigger runs twice
    @InvocableMethod(label='Call Gds' description='Calls Gds Scoring service')
    public static void callGdsPb (List <Id> recordIds) {

        //Added on 8/14
        List<Id> portalIds = new List<Id>();
        List<Id> otherIds = new List<Id>();

        List<Opportunity> opps = [SELECT Id, Portal_User_ID__c FROM Opportunity WHERE Id IN :recordIds];
        for(Opportunity opp : opps){
            if(opp.Portal_User_ID__c.contains('PUDA-') || 
            opp.Portal_User_ID__c.contains('UDA-') || 
            opp.Portal_User_ID__c.contains('SF-')){
                otherIds.add(opp.Id);
            }else {
                portalIds.add(opp.Id);
            }
        }
        if(!portalIds.isEmpty()){
            DoMarlinNetB2BCalls(portalIds);
        }
        //Turned this into an Asynchronous method so we can make callouts after the update to resubmission object
        if(!recordIds.isEmpty()){
            DoCallouts(otherIds);
        }
    }

    @future(callout = true)
    private static void DoCallouts(List <Id> recordIds){
        Set <Id> idSet = new Set<Id> ();
        System.debug ('>>>>> recordIds: ' + recordIds);
        idSet.addAll (recordIds);
        //Added per discussion on Call per, added part of SAL-3065   -Tyler 8/11/21
        if(recordIds.size() > 0){
            TC_DwhStoredProcedureRespBean businessFraudRespBean = TC_DwhStoredProcedureApi.businessFraudQuery( recordIds[0] );
            System.debug( businessFraudRespBean );
            if(businessFraudRespBean <> null && businessFraudRespBean.results != null && !businessFraudRespBean.results.isEmpty()){
                System.debug('Mapping to WebserviceField');
                List<Opportunity> oppResult = [SELECT Id, CustomerType__c FROM Opportunity WHERE Id = :recordIds[0]];// SAL-5820 Misael Romero
                if(oppResult.size() > 0){
                    businessFraudRespBean.results[0].CustomerType = oppResult[0].CustomerType__c;
                }
                TC_DwhStoredProcedureMapper.mapBeansToWebserviceField(recordIds[0], businessFraudRespBean);
                MARLIN_IntegrationLog.insertLogs();
            }
        }
        TC_GdsScoreApi.runGdsScoreFromTriggeredAction (idSet);
              //  FieldChangeTracker.removeTrackedChanges(recordIds);
    }
    
    @testVisible
    private static void DoMarlinNetB2BCalls(List<Id> recordIds){
        Set <Id> idSet = new Set<Id> ();
        System.debug ('>>>>> recordIds: ' + recordIds);
        idSet.addAll (recordIds);
        TC_GdsScoreApi.runGdsScoreFromTriggeredAction (idSet);
    }
    
   /* @AuraEnabled
    public static void removeTrackedChanges(List<string> recordIdList) {
        FieldChangeTracker.removeTrackedChanges(recordIdList);
    }*/
    

}