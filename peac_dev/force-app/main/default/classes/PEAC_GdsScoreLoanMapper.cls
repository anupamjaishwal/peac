/************************************************************************************************************************
 @Description: Queries aplication data and map usinf flow and custom metadata.
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 06/16/2025
 ************************************************************************************************************************/

public with sharing class PEAC_GdsScoreLoanMapper {
    
    public static PEAC_GDSScoreLoanReqRespBean mapSalesforceToBean(Id oppId) {
        PEAC_GDSScoreLoanReqRespBean reqRespBean = new PEAC_GDSScoreLoanReqRespBean ();

        // get salesforce ids to pass into mapping flows, apex orchestrates the flows
        List <Opportunity> opps = new List <Opportunity> ([
                SELECT Id
                        , Primary_Source__c
                        , AccountId
                        , Marlin_Business_Group__c,Loan_Purpose__c, CustomerType__c,Decision_Status__c, Digital_Portal_ID__c, Credit_Strategy__c
                        , (SELECT Id, Account__c, Contact__c, RecordType.Name, Primary__c,Sync_To_GDS__c,LastModifiedDate,Latest_Rescore_Date__c, IsDeleted, PG_Number__c, PG_N__c FROM Guarantor__r WHERE RP_PRIN_GUAR_CODE__c != 'Principal' 
                           AND PG_Number__c != null AND PG_N__c != 0 ORDER BY CreatedDate ASC)
                        , (SELECT Account__c, Primary_Broker__c, Broker_Dealer_Number__c  FROM Brokers1__r ORDER BY CreatedDate ASC)
                        
                FROM Opportunity
                WHERE Id = :oppId ALL ROWS
        ]);
        Opportunity opp = new Opportunity ();
        if (!opps.isEmpty ()) {
            reqRespBean.opp = opps[0];
            opp = opps[0];
            if( PEAC_GDSScoreLoanAPI.callType == 'SF' || PEAC_GDSScoreLoanAPI.callType == 'LP')
            {
                //LTIMindtree updated date 02-12-2025. SAL-6014
               reqRespBean.opp.Application_Status__c = (opp.Loan_Purpose__c != 'Teaser') ? 'In Process'  : 'Pending';
            }
        }
        Id salesforcePrimaryBrokerId;
        for (Broker__c broker : opp.Brokers1__r) {
            if (salesforcePrimaryBrokerId == null) {
                salesforcePrimaryBrokerId = broker.Account__c;
            }
        }
        List<Webservice_Field__c> latestCustomerCreditExpList = getWebserviceField ('DWH_GetCustomerCreditExposure','getGdsGetCustCreditExpLoan',oppId);
        List<Webservice_Field__c> latestFraudList = getWebserviceField ('GetFraudFlags','getGDSFraudFlags',oppId);
 
        
        reqRespBean.wsFields = !latestCustomerCreditExpList.isEmpty() ? latestCustomerCreditExpList[0] : null;
        reqRespBean.wsFieldsFraud = !latestFraudList.isEmpty() ? latestFraudList[0] : null;
        
        /*** instantiate req bean ***/

        // set oppId
        reqRespBean.oppId = oppId;
        reqRespBean.scoreReq.Opportunity__c = oppId;

        /*** add salesforce records to easy access variables ***/

        set <Id> salesforcePgIds = new set <Id> ();
        
        // pgs and ccg
        Map <Id, Id> conPgIdMap = new Map <Id, Id> (); // need to find assosiate the 2 becuase I map back to the pg
        Map<string, PGTypeWrapper> pgMap = new Map<string, PGTypeWrapper>();
        List<Guarantor__c> guarList = [SELECT Latest_Rescore_Date__c FROM Guarantor__c WHERE RP_PRIN_GUAR_CODE__c != 'Principal' 
                                       AND PG_Number__c != null AND PG_N__c != 0 AND Opportunity__c =: oppId AND Latest_Rescore_Date__c != null
                                       ORDER BY Latest_Rescore_Date__c DESC ALL ROWS];
        DateTime latestRescoreDate;
        
        if(guarList.size() > 0) {
            if(guarList.get(0).Latest_Rescore_Date__c != null) {
                latestRescoreDate = guarList.get(0).Latest_Rescore_Date__c;
            }
        }
                            System.debug('Debugger::latestRescoreDate::'+latestRescoreDate);
        // get salesforce list of pgs only up to 4 pgs
        if (!opp.Guarantor__r.isEmpty ()) {
            for (Integer i = 0; i < opp.Guarantor__r.size(); i++) {
                Guarantor__c guar = opp.Guarantor__r[i];
                if (guar.RecordType.Name != 'Corporate') {
                if(guar.IsDeleted && (guar.Latest_Rescore_Date__c == null || guar.LastModifiedDate < latestRescoreDate)) {
                     continue;
                  }
                 // if (guar.IsDeleted) continue; 
                  
                    PGTypeWrapper pg = new PGTypeWrapper();
                    pg.pgType = guar.PG_Number__c;
                    pg.pgN = Integer.valueOf(guar.PG_N__c);
                    
                    // NEW: mark unsynced guarantors as "new" (to be considered changed)
                    Boolean isNewUnsynced = (guar.Sync_To_GDS__c == false || guar.Sync_To_GDS__c == null);
                    
                    if(pgMap.containsKey(guar.PG_Number__c)) {
                        pg = pgMap.get(guar.PG_Number__c);
                       // if(guar.PG_Number__c == 'PG2') {
                            System.debug('Debugger::guar::'+guar);
                       // }
                        if(!guar.IsDeleted && pg.isDeleted && !guar.Sync_To_GDS__c) {
                            //Old Record is deleted and Creating new record 
                            //Added new check - To check, whether the details, it's already been synced or not
                            pg.guar = guar;
                            pg.ContactId = guar.Contact__c;
                            pg.isChanged = true;
                            pg.isDeleted = false;
                        } else if(guar.IsDeleted && !pg.isChanged && (latestRescoreDate == null || (guar.LastModifiedDate > latestRescoreDate))) {
                            System.debug('Debugger::gaur::'+ guar.LastModifiedDate);
                            System.debug('Debugger::gaur::'+ latestRescoreDate);
                            //Old Record is deleted
                            //Added new check - To check, whether the details, it's already been synced or not
                            pg.isDeleted = true;
                        } else {
                            // Nothing
                            pg.guar = guar;
                            pg.ContactId = guar.Contact__c;
                            pg.isChanged = false;
                            pg.isDeleted = false;
                            
                        }
                        
                        // NEW: if not deleted and not yet synced, consider it "changed" (Y)
                        if (!pg.isDeleted && isNewUnsynced) { pg.isChanged = true; }
                   
                            System.debug('Debugger::'+pg);
                     
                    } else {
                        // Initialize
                        pg.guar = guar;
                        pg.ContactId = guar.Contact__c;
                        pg.isDeleted = guar.IsDeleted && (guar.LastModifiedDate > latestRescoreDate);
                        
                        // NEW: if not deleted and not yet synced, consider it "changed" (Y)
                        if (!pg.isDeleted && isNewUnsynced) 
                        { 
                            pg.isChanged = true; 
                        }
                        
                    }
                    if(pg.ContactId == null) {
                        pg.ContactId = guar.Contact__c;
                    } 
                    pgMap.put(guar.PG_Number__c, pg);
                    salesforcePgIds.add (guar.Contact__c);
                    //conPgIdMap.put (guar.Contact__c, guar.Id);
                }
            }
        }
        Set<Id> changeContactIdSet = new Set<Id>();
        Boolean isAccountChanged = false;
        FieldTrackingForLoan__mdt trackingContactConfigs = FieldTrackingForLoan__mdt.getInstance('Contact');
        FieldTrackingForLoan__mdt trackingAccountConfigs = FieldTrackingForLoan__mdt.getInstance('Account');
        for(Field_Tracker__c tracker : [select Record_Id__c,Object_Name__c from Field_Tracker__c
                                        where (Object_Name__c = 'Contact' 
                                        AND Field_Name__c IN :trackingContactConfigs.GDS_Fields__c.split(';')
                                        AND Record_Id__c IN :salesforcePgIds AND Opportunity__c = :opp.Id
                                        AND Action__c = 'Modified') 
                                        OR 
                                        (Object_Name__c = 'Account' 
                                        AND Field_Name__c IN :trackingAccountConfigs.GDS_Fields__c.split(';')
                                        AND Record_Id__c = :opp.AccountId AND Opportunity__c = :opp.Id
                                        AND Action__c = 'Modified')
                                       ]) {
                                           if(tracker.Object_Name__c == 'Contact') {
                                               changeContactIdSet.add(tracker.Record_Id__c);     
                                           } else if(tracker.Object_Name__c == 'Account') {
                                               isAccountChanged = true;
                                           }
        }

        /*** Send salesforce ids into mapping flows ***/

        // map main applicaton bean
        Flow.Interview.GDS_Score_Loan_Application_Request_Mapping mapApplicationLevelFields = new Flow.Interview.GDS_Score_Loan_Application_Request_Mapping(new Map <String, Object>{
                'varOppId' => oppId, 'CallType' =>PEAC_GDSScoreLoanAPI.callType
        });
        mapApplicationLevelFields.start ();
        reqRespBean.scoreReq = (Gds_Score__c) mapApplicationLevelFields.getVariableValue('varRequestBean');
        // map company1 bean
        Flow.Interview.GDS_Score_Loan_Company_Request_Mapping1 mapCompany1LevelFields = new Flow.Interview.GDS_Score_Loan_Company_Request_Mapping1(new Map <String, Object>{
                'varAccId' => opp.AccountId, 'varCompanyType' => 'company1','varOppId' =>opp.Id 
        });
        mapCompany1LevelFields.start ();
        Gds_Score_Request_Company__c company = (Gds_Score_Request_Company__c) mapCompany1LevelFields.getVariableValue('varRequestBean');
        company.Is_Company_Changed__c = isAccountChanged;
        reqRespBean.company1 = company;
        
        //Map broker
        Flow.Interview.GDS_Score_Loan_Company_Request_Mapping1 mapBrokerLevelFields = new Flow.Interview.GDS_Score_Loan_Company_Request_Mapping1(new Map <String, Object>{
                'varAccId' => salesforcePrimaryBrokerId, 'varCompanyType' => 'BV','varOppId' =>opp.Id 
        });
        mapBrokerLevelFields.start ();
        reqRespBean.broker = (Gds_Score_Request_Company__c) mapBrokerLevelFields.getVariableValue('varRequestBean');
        
        // Map pg
        /*if (!salesforcePgIds.isEmpty ()) {
            for (Id pgId : salesforcePgIds) {
                Flow.Interview.GDS_Score_Loan_Individual_Request_Mapping mapPgLevelFields = new Flow.Interview.GDS_Score_Loan_Individual_Request_Mapping(new Map <String, Object>{
                        'varConId' => pgId
                });
                mapPgLevelFields.start ();
                Gds_Score_Request_Individual__c ind = (Gds_Score_Request_Individual__c) mapPgLevelFields.getVariableValue('varRequestBean');
                ind.Guarantor_Based_On__c = conPgIdMap.get (pgId);
                reqRespBean.pgs.add (ind);
            }
        }*/
        System.debug('pgMap::'+pgMap);
        if (!pgMap.isEmpty ()) {
            for (string pgId : pgMap.keySet()) {
                PGTypeWrapper pg = pgMap.get(pgId);
                
                Flow.Interview.GDS_Score_Loan_Individual_Request_Mapping mapPgLevelFields = new Flow.Interview.GDS_Score_Loan_Individual_Request_Mapping(new Map <String, Object>{
                        'varConId' => pg.ContactId
                });
                mapPgLevelFields.start ();
                Gds_Score_Request_Individual__c ind = (Gds_Score_Request_Individual__c) mapPgLevelFields.getVariableValue('varRequestBean');
                if( pg.guar != null && !pg.guar.IsDeleted) {
                    ind.Guarantor_Based_On__c = pg.guar.Id;
                }
                
                ind.Is_PG_Deleted__c = pg.isDeleted;
                ind.PG_Number__c = pg.pgN;
                ind.Is_PG_Changed__c = pg.isChanged || changeContactIdSet.contains(pg.ContactId);
                reqRespBean.pgs.add (ind);
            }
        }
         
        System.debug('reqRespBean.pgs::'+reqRespBean.pgs);
        return reqRespBean;
    }

    public static List<Webservice_Field__c> getWebserviceField (String nodePath, String storeProcedure,Id oppId)
    {
        String sQueryFields = getDyanamicFields(nodePath);
        string sQuery = 'SELECT ' + sQueryFields + ' FROM Webservice_Field__c WHERE Opportunity__c =:oppId AND Stored_Procedure__c =:storeProcedure ORDER BY CreatedDate DESC LIMIT 1';
        List<Webservice_Field__c> latestWebServiceFieldRecord = new List<Webservice_Field__c>();
        latestWebServiceFieldRecord = Database.query(sQuery);
        return latestWebServiceFieldRecord;
    }
    //get gds_score related field mapping from custom metadata
    public static String getDyanamicFields(String nodePathName){
        GDS_Mapping__mdt gdsMapping = [SELECT label,Field_Mapping_Details__c,Object_Name__c FROM GDS_Mapping__mdt WHERE developerName =:nodePathName];
        string sQueryFields = 'Id';
        Set<String> strValueSet = new Set<String>();
        if(gdsMapping !=null)
        {
            list<String> gdsTagWithFieldsList = gdsMapping.Field_Mapping_Details__c.split('\\r?\\n');
            if(!gdsTagWithFieldsList.isEmpty() )
            {

                for(String gdsTagWithFieldMap : gdsTagWithFieldsList)
                {
                    List<String> gdsTagAndFieldList = gdsTagWithFieldMap.split('-');
                    strValueSet.add(gdsTagAndFieldList[1]);
                }
            }
            for (String field : strValueSet) {
                if(field != 'Id')
                sQueryFields += ',' + field;
            }
        }
        return sQueryFields;
    }

    public static void mapBeanToSalesforce(PEAC_GDSScoreLoanReqRespBean reqResp) {
        PEAC_GdsScoreLoanApi.dmlSObjectCalloutRecords (reqResp);
    }

    public class PGTypeWrapper {
        public string pgType;
        public boolean isChanged;
        public boolean isDeleted;
        public Guarantor__c guar;
        public string contactId;
        public integer pgN;
        
        public PGTypeWrapper() {
            isChanged = false;
            isDeleted = false;
        }
    }




}