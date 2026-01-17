/**
 * Queries data from database to bean (flow does this)
 */

public with sharing class TC_GdsScoreMapper {

    public static TC_GDSScoreReqRespBean mapSalesforceToBean(Id oppId) {
        TC_GDSScoreReqRespBean reqRespBean = new TC_GDSScoreReqRespBean ();

        // get salesforce ids to pass into mapping flows, apex orchestrates the flows
        List <Opportunity> opps = new List <Opportunity> ([
                SELECT Id
                        , Branch__c
                        , Primary_Source__c
                        , AccountId
                        , Terms__c
                        , Primary_Broker__c
                        , Dealer_Primary_Number__c
                        , Marlin_Business_Group__c, CustomerType__c,Decision_Status__c, Digital_Portal_ID__c, Credit_Strategy__c
                        , (SELECT Id, Account__c, Contact__c, RecordType.Name, Primary__c FROM Guarantor__r WHERE RP_PRIN_GUAR_CODE__c != 'Principal' ORDER BY CreatedDate ASC)
                        , (SELECT Dealer__c, Primary_Dealer__c   FROM Brokers__r ORDER BY CreatedDate ASC)
                        , (SELECT Account__c, Primary_Broker__c, Broker_Dealer_Number__c  FROM Brokers1__r ORDER BY CreatedDate ASC)
                        , (SELECT Franchisor__c FROM Franchisors__r)
                FROM Opportunity
                WHERE Id = :oppId
        ]);
        Opportunity opp = new Opportunity ();
        if (!opps.isEmpty ()) {
            reqRespBean.opp = opps[0];
            opp = opps[0];
            reqRespBean.Account_type = opp.Brokers1__r.size() > 0 ? 'Broker Account' : opp.Brokers__r.size() > 0 ? 'Dealer Account' : '';
        }

        // SAL-2765 
        List<Webservice_Field__c> latestWebServiceFieldRecord = [
            SELECT Id,Manager_PG_Override__c, RunNewCustomerFlow__c, BizInfoMatch__c, BizCityMatch__c, 
                BizStateMatch__c, BizZipMatch__c, BizPhoneMatch__c, PersonalInfoMatch__c, PG1SSNMatch__c, PG2SSNMatch__c, PG1EmailMatch__c, 
                PG2EmailMatch__c, PG1LastNameMatch__c, PG2LastNameMatch__c
            FROM Webservice_Field__c WHERE Opportunity__c=:oppId ORDER BY CreatedDate DESC LIMIT 1
        ];
        reqRespBean.wsFields = !latestWebServiceFieldRecord.isEmpty() ? latestWebServiceFieldRecord[0] : null;
        // END OF SAL-2765
        
        
        /*** instantiate req bean ***/

        // set oppId
        reqRespBean.oppId = oppId;
        reqRespBean.scoreReq.Opportunity__c = oppId;

        /*** add salesforce records to easy access variables ***/

        Id outboundDealerId;
        Id outboundBrokerId;
        List <Id> salesforcePgIds = new List <Id> ();
        Id salesforceCCId;
        Id salesforceCCGId;

        // the primary field on the broker and dealer arent used consitently so grab the first one

        // if IFP or broker is richie brothers, send primary broker as dealer then primary dealer as broker
        // if Franchisor send primary franchisor as dealer
        // all other scenarios send primary dealer as dealer and broker as broker

        Id salesforcePrimaryDealerId;
        Id salesforcePrimaryBrokerId;
        Id salesforcePrimaryFranchisorId;
        Boolean isBrokerRichieBrothers = false; // for now this is coded into a label, if there's more we should add a flag on the broker to specify this

        // branch to platform new
        TC_DealerTreatment dealerTreatment = new TC_DealerTreatment (opp);

        for (Dealer__c dealer : opp.Brokers__r) {
            if (salesforcePrimaryDealerId == null) salesforcePrimaryDealerId = dealer.Dealer__c;
        }

        for (Broker__c broker : opp.Brokers1__r) {
            if (salesforcePrimaryBrokerId == null) {
                salesforcePrimaryBrokerId = broker.Account__c;
                if (broker.Broker_Dealer_Number__c != null && Label.TC_Broker_IFP_Scenario != null && broker.Broker_Dealer_Number__c == Label.TC_Broker_IFP_Scenario) isBrokerRichieBrothers = true;
            }
        }

        for (Franchisor__c franchisor : opp.Franchisors__r) {
            if (salesforcePrimaryFranchisorId == null) salesforcePrimaryFranchisorId = franchisor.Franchisor__c;
        }


        if (dealerTreatment.sendBrokerAsDealer) {
            outboundDealerId = salesforcePrimaryBrokerId;
            outboundBrokerId = salesforcePrimaryDealerId;
        } else if (dealerTreatment.sendFranchisorAsDealer) {
            outboundDealerId = salesforcePrimaryFranchisorId;
        } else {
            outboundDealerId = salesforcePrimaryDealerId;
            outboundBrokerId = salesforcePrimaryBrokerId;
        }

        // pgs and ccg
        Map <Id, Id> conPgIdMap = new Map <Id, Id> (); // need to find assosiate the 2 becuase I map back to the pg

        // get salesforce list of pgs only up to 4 pgs
        if (!opp.Guarantor__r.isEmpty ()) {
            for (Integer i = 0; i < opp.Guarantor__r.size() && salesforcePgIds.size() <= 4; i++) {
                Guarantor__c guar = opp.Guarantor__r[i];
                if (guar.RecordType.Name != 'Corporate') {
                    salesforcePgIds.add (guar.Contact__c);
                    conPgIdMap.put (guar.Contact__c, guar.Id);
                }
            }
        }
        // get salesforce CCId, first cc is primary cc
        if (!opp.Guarantor__r.isEmpty ()) {
            for (Integer i = 0; i < opp.Guarantor__r.size(); i++) {
                Guarantor__c guar = opp.Guarantor__r[i];
                if (guar.RecordType.Name == 'Corporate' && salesforceCCId == null) {
                    salesforceCCId = guar.Account__c;
                    salesforceCCGId = guar.Id;
                }
            }
        }

        /*** Send salesforce ids into mapping flows ***/

        // map main applicaton bean
        Flow.Interview.TC_GDS_Score_Application_Request_Mapping mapApplicationLevelFields = new Flow.Interview.TC_GDS_Score_Application_Request_Mapping(new Map <String, Object>{
                'varOppId' => oppId
        });
        mapApplicationLevelFields.start ();
        reqRespBean.scoreReq = (Gds_Score__c) mapApplicationLevelFields.getVariableValue('varRequestBean');

        // map company1 bean
        Flow.Interview.TC_GDS_Score_Company_Request_Mapping mapCompany1LevelFields = new Flow.Interview.TC_GDS_Score_Company_Request_Mapping(new Map <String, Object>{
                'varAccId' => opp.AccountId, 'varCompanyType' => 'company1'
        });
        mapCompany1LevelFields.start ();
        reqRespBean.company1 = (Gds_Score_Request_Company__c) mapCompany1LevelFields.getVariableValue('varRequestBean');

        // map dealer bean
        if (outboundDealerId != null) {
            Flow.Interview.TC_GDS_Score_Company_Request_Mapping mapDealerLevelFields = new Flow.Interview.TC_GDS_Score_Company_Request_Mapping(new Map <String, Object>{
                    'varAccId' => outboundDealerId, 'varCompanyType' => 'Dealer'
            });
            mapDealerLevelFields.start ();
            reqRespBean.dealer = (Gds_Score_Request_Company__c) mapDealerLevelFields.getVariableValue('varRequestBean');
        }

        // map broker bean
        if (outboundBrokerId != null) {
            Flow.Interview.TC_GDS_Score_Company_Request_Mapping mapBrokerLevelFields = new Flow.Interview.TC_GDS_Score_Company_Request_Mapping(new Map <String, Object>{
                    'varAccId' => outboundBrokerId, 'varCompanyType' => 'BV'
            });
            mapBrokerLevelFields.start ();
            reqRespBean.broker = (Gds_Score_Request_Company__c) mapBrokerLevelFields.getVariableValue('varRequestBean');
        }

        // map cc
        if (salesforceCCId != null) {
            Flow.Interview.TC_GDS_Score_Company_Request_Mapping mapCCLevelFields = new Flow.Interview.TC_GDS_Score_Company_Request_Mapping(new Map <String, Object>{
                    'varAccId' => salesforceCCId, 'varCompanyType' => 'CC'
            });
            mapCCLevelFields.start ();
            reqRespBean.cc = (Gds_Score_Request_Company__c) mapCCLevelFields.getVariableValue('varRequestBean');
            reqRespBean.cc.Guarantor_Based_On__c = salesforceCCGId;
        }

        // map pg
        if (!salesforcePgIds.isEmpty ()) {
            for (Id pgId : salesforcePgIds) {
                Flow.Interview.TC_GDS_Score_Individual_Request_Mapping mapPgLevelFields = new Flow.Interview.TC_GDS_Score_Individual_Request_Mapping(new Map <String, Object>{
                        'varConId' => pgId
                });
                mapPgLevelFields.start ();
                Gds_Score_Request_Individual__c ind = (Gds_Score_Request_Individual__c) mapPgLevelFields.getVariableValue('varRequestBean');
                ind.Guarantor_Based_On__c = conPgIdMap.get (pgId);
                reqRespBean.pgs.add (ind);
            }
        }

        /*** mapping logic that's too complex for flows ***/

        // get custom metadata mappers
        List <MARLIN_Rapport_Mapping__mdt> mappings = new List <MARLIN_Rapport_Mapping__mdt> ([SELECT Label, Rapport_Value__c, Field_Name__c FROM MARLIN_Rapport_Mapping__mdt]);

        Map <String, Map <String, String>> mappingMap = new Map <String, Map<String, String>> ();

        for (MARLIN_Rapport_Mapping__mdt mapping : mappings) {
            if (mappingMap.get (mapping.Field_Name__c) != null) {
                mappingMap.get (mapping.Field_Name__c).put (mapping.Label, mapping.Rapport_Value__c);
            } else {
                mappingMap.put (mapping.Field_Name__c, new Map <String, String>{
                        mapping.Label => mapping.Rapport_Value__c
                });
            }
        }

        // Asset Codes

        List <Asset__c> assets = new List <Asset__c> ([SELECT Id, Equipment_Code__c, New_Used__c, Mileage__c,Equipment_Street__c,Equipment_Address_2__c, Equipment_City__c, Equipment_State__c, Equipment_Zip__c, Equipment_Sub_Category__c FROM Asset__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate ASC]);

        if (!assets.isEmpty()) {
            Map <String, String> eqCodeMappings = mappingMap.get ('Equipment_Code');
            // Added Equipment Code/Category logic
            // https://marlinbusiness.atlassian.net/browse/SAL-1622
            if (eqCodeMappings != null && assets[0].Equipment_Code__c != null) reqRespBean.scoreReq.Equip_Code__c = eqCodeMappings.get (TC_Asset.getMostGranularAssetCode (assets[0]));
            if (assets[0].New_Used__c != null) {
                if (assets[0].New_Used__c == 'New') {
                    reqRespBean.scoreReq.New_Used__c = 'N';
                } else if (assets[0].New_Used__c == 'Used') {
                    reqRespBean.scoreReq.New_Used__c = 'U';
                }
            }

            // calculating mileage field 750,000+
            String over750000 = '0';
            for (Asset__c asset : assets) {
                // Added Equipment Code/Category logic
                // https://marlinbusiness.atlassian.net/browse/SAL-1622
                if (asset.Mileage__c == '750,000+' || (String.isBlank(asset.Mileage__c ) && eqCodeMappings != null && asset.Equipment_Code__c != null && eqCodeMappings.get (asset.Equipment_Code__c) != null && eqCodeMappings.get (TC_Asset.getMostGranularAssetCode (asset)).contains('500.'))) over750000 = '1';
            }
            reqRespBean.scoreReq.Vehicle_Mileage__c = over750000;
        } 

        // branch
        if (opp.Branch__c != null) {
            Map <String, String> branchCodeMappings = mappingMap.get ('Branch');
            if (branchCodeMappings != null) reqRespBean.scoreReq.Branch__c = branchCodeMappings.get (opp.Branch__c);
        }


        // Application Level Dealer fields
        List <Account> dealers = new List <Account> ([SELECT Id, Account_Dealer_Status__c, Dealer_Number__c, CreatedDate, Pre_Delivery_20k_Trial__c FROM Account WHERE Id = :outboundDealerId]);
        if (!dealers.isEmpty ()) {
            
            // active dealer flag
            /*if (dealers[0].Account_Dealer_Status__c == 'Active' || dealers[0].Account_Dealer_Status__c == 'Approved') {
                reqRespBean.scoreReq.ud_Active_Dealer__c = 'DlrActiveDealer';
            }*/
            // dealer # Dealer_Number__c
            reqRespBean.scoreReq.Dealer_Number__c = dealers[0].Dealer_Number__c;

            // dealer status
            if (dealers[0].Account_Dealer_Status__c != null) {
                Map <String, String> statusCodeMappings = mappingMap.get ('UD_DEALER_STATUS');
                //reqRespBean.scoreReq.Dealer_Status__c = statusCodeMappings.get (dealers[0].Account_Dealer_Status__c);
                reqRespBean.dealer.Dealer_Status__c = statusCodeMappings.get (dealers[0].Account_Dealer_Status__c);
                reqRespBean.scoreReq.ud_Active_Dealer__c = reqRespBean.dealer.Dealer_Status__c;
                if (dealers[0].CreatedDate != null) {
                    String month = ('0' + dealers[0].CreatedDate.month()).right (2);
                    String day = ('0' + dealers[0].CreatedDate.day()).right (2);
                    reqRespBean.scoreReq.Ud_Dealer_Entered_Date__c = dealers[0].CreatedDate.year() + '-' + month + '-' + day;
                }
                
                
                // Send Pre-Delivery 20k Trial field to DE within GDS request https://marlinbusiness.atlassian.net/browse/SAL-1470
                if (dealers[0].Pre_Delivery_20k_Trial__c) {
                    reqRespBean.scoreReq.Pre_Delivery_20k_Trial__c = '1';
                } else {
                    reqRespBean.scoreReq.Pre_Delivery_20k_Trial__c = '0';
                }
                    

            }

            // broker vendor number
            // note broker vendor number is dealer number: https://marlinbusiness.atlassian.net/browse/SAL-1012
            if (outboundBrokerId != null && opp.Marlin_Business_Group__c != 'Franchise') {
                List <Account> brokerQueried = new List <Account> ([SELECT Id, Dealer_Number__c FROM Account WHERE Id = :outboundBrokerId]);
                if (!brokerQueried.isEmpty()) {
                    if (brokerQueried[0].Dealer_Number__c != null) {
                        if (brokerQueried[0].Dealer_Number__c.contains ('.')) {
                            reqRespBean.scoreReq.Broker_Vendor_Number__c = brokerQueried[0].Dealer_Number__c.remove ('.');
                        } else {
                            reqRespBean.scoreReq.Broker_Vendor_Number__c = brokerQueried[0].Dealer_Number__c;
                        }
                    }
                }

            }

        }

        // count pgs and ccgs for request
        Integer pgCount = 0;
        Integer cgCount = 0;
        for (Guarantor__c guar : opp.Guarantor__r) {
            if (guar.RecordType.Name == 'Personal') {
                pgCount++;
            } else if (guar.RecordType.Name == 'Corporate') {
                cgCount++;
            }
        }
        reqRespBean.scoreReq.ud_Rp_Num_Guar_Prin__c = String.valueOf (pgCount);
        reqRespBean.scoreReq.ud_Rp_Num_Guar_Prin_2__c = String.valueOf (cgCount);

        // end user source
        if (opp.Primary_Source__c != null) {
            Map <String, String> endUserSourceCodeMappings = mappingMap.get ('UD_END_USER_SOURCE_CODE');
            reqRespBean.scoreReq.Ud_End_User_Source_Code__c = endUserSourceCodeMappings.get (opp.Primary_Source__c);
        }
        List <Opportunity> company1CanceledOpps = new List <Opportunity>([SELECT Application_Status__c, Decision_Date__c FROM Opportunity WHERE AccountId = :opp.AccountId AND Application_Status__c = 'Rejected' AND Decision_Date__c = LAST_90_DAYS]);
        if (!company1CanceledOpps.isEmpty()) {
            reqRespBean.scoreReq.Ud_Rejected_App_Last_90__c = '1';
        } else {
            reqRespBean.scoreReq.Ud_Rejected_App_Last_90__c = '0';
        }

        // dealer customer distance

        // customer lat/long
        GoogleGeoCodeResponse custAddrInfo = GoogleGeoCodeAPI.getGeoCodeResponse(reqRespBean.company1.Address__c, reqRespBean.company1.City__c, reqRespBean.company1.State__c, reqRespBean.company1.Zip__c);

        // dealer lat/long
        GoogleGeoCodeResponse dealerAddrInfo = GoogleGeoCodeAPI.getGeoCodeResponse(reqRespBean.dealer.Address__c, reqRespBean.dealer.City__c, reqRespBean.dealer.State__c, reqRespBean.dealer.Zip__c);

        System.debug ('made it outside error');
        if (custAddrInfo != null && dealerAddrInfo != null && !custAddrInfo.results.isEmpty() && !dealerAddrInfo.results.isEmpty()) {
            String custLat = custAddrInfo.results[0].geometry.location.lat;
            String custLong = custAddrInfo.results[0].geometry.location.lng;

            String dealerLat = dealerAddrInfo.results[0].geometry.location.lat;
            String dealerLong = dealerAddrInfo.results[0].geometry.location.lng;

            if (custLat != null && custLong != null && dealerLat != null && dealerLong != null) {
                reqRespBean.scoreReq.Customer_Dealer_Distance__c = TC_GeoCodeUtil.calculateDistance (Decimal.valueOf (custLat),Decimal.valueOf (custLong),Decimal.valueOf (dealerLat),Decimal.valueOf (dealerLong));
            }

        }
        
        // get opportunity primary contact
        List <OpportunityContactRole> ocr = new List <OpportunityContactRole> ([SELECT Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.Validity_Verify__Status__c, Contact.Final_E_mail_Validity_Result__c  FROM OpportunityContactRole WHERE Role = 'Primary Contact' AND OpportunityId = :opp.Id]);
        
        if (!ocr.isEmpty ()) {
            reqRespBean.company1.Primary_Contact_First_Name__c = ocr[0].Contact.FirstName;
            reqRespBean.company1.Primary_Contact_Last_Name__c = ocr[0].Contact.LastName;
            // SAL-2768 Add Primary Contact Phone
            reqRespBean.company1.Primary_Contact_Phone__c = ocr[0].Contact.Phone;
            reqRespBean.company1.Primary_Contact_Email__c  = ocr[0].Contact.Email; 
            reqRespBean.company1.Primary_Contact_Validity_Verify_Result__c = ocr[0].Contact.Validity_Verify__Status__c; 
            reqRespBean.company1.Primary_Contact_Final_Email_Validity__c  = ocr[0].Contact.Final_E_mail_Validity_Result__c;
        } 
    
        if (!assets.isEmpty()) {
            // Added for equipment/shipping addresses
            // https://marlinbusiness.atlassian.net/browse/SAL-2763
            reqRespBean.company1.Equip_Address__c =  assets[0].Equipment_Street__c;
            reqRespBean.company1.Equip_Address2__c =  assets[0].Equipment_Address_2__c;
            reqRespBean.company1.Equip_City__c =  assets[0].Equipment_City__c;    
            reqRespBean.company1.Equip_State__c =  assets[0].Equipment_State__c;    
            reqRespBean.company1.Equip_Zip__c =  assets[0].Equipment_Zip__c;   
            
        } 

      return reqRespBean;
    }

    public static void mapBeanToSalesforce(TC_GDSScoreReqRespBean reqResp) {


        // unfortunately I need to dml in 2 places becuase passing records into a flow is very buggy, passing in Ids and querying them again is safer
        // this requires me to dml the sobject representation of the request then query them inside of the flow
        TC_GdsScoreApi.dmlSObjectCalloutRecords (reqResp);

        // accounts

        Flow.Interview.TC_GDS_Score_Response_Company_Mapping mapAccountFields = new Flow.Interview.TC_GDS_Score_Response_Company_Mapping(new Map <String, Object>{
                'varComReqId' => reqResp.company1.Id
        });
        mapAccountFields.start ();
        Account acc = (Account) mapAccountFields.getVariableValue('varAccount');

        // have to do sic outside of flow due to bug with picklist
        if (reqResp.company1.Marlin_Sic__c != null) acc.Account_EU_FS_SIC_Description__c = reqResp.company1.Marlin_Sic__c;

        update acc;


        // Opportunity
        Flow.Interview.TC_GDS_Score_Application_Response_Mapping mapOppFields = new Flow.Interview.TC_GDS_Score_Application_Response_Mapping(new Map <String, Object>{
                'varAppRespId' => reqResp.scoreReq.Id, 'varAccRespId' => reqResp.company1.Id
        });
        mapOppFields.start ();
        Opportunity opp = (Opportunity) mapOppFields.getVariableValue('varOpp');

        /** Doing mapping logic too complicated for flows **/



        // setting credit stips
        List <String> stips = new List <String> ();

        if (reqResp.scoreReq.UD_Verify_SLF_Stip__c == '1') stips.add ('Proof of satisfied Suits, Liens, and Judgements');
        if (reqResp.scoreReq.UD_Software_Stip__c == '1') stips.add ('Software Addendum');
        if (reqResp.scoreReq.Ud_Municipal_Addendum_Stip__c == '1') stips.add ('Municipal addendum');
        if (reqResp.scoreReq.Ud_Corp_Res_Lessee_Po_Stip__c == '1') stips.add ('Corporate resolution/lessee po');
        if (reqResp.scoreReq.Ud_Equipment_Approval_Stip__c == '1') stips.add ('Equipment Approval');
        if (reqResp.scoreReq.Ud_Proof_of_Business_Location_Stip__c == '1') stips.add ('Proof of business location');
        if (reqResp.scoreReq.Ud_Residual_Stip__c == '1') stips.add ('Residual Stip');
        if (reqResp.scoreReq.Ud_Owner_to_Sign_Stip__c == '1') stips.add ('Owner to sign');
        if (reqResp.scoreReq.Ud_Ucc_Filing_Search_Stip__c == '1') stips.add ('UCC Filing/Search');
        if (reqResp.scoreReq.Ud_Tecert_Stip__c == '1') stips.add ('Tax Exempt Cert');
        if (reqResp.scoreReq.Ud_Patriot_Stip__c == '1') stips.add ('Patriot Act');
        if (reqResp.scoreReq.Ud_Vendor_Approval_Output_Stip__c == '1') stips.add ('Vendor approval');
        if (reqResp.scoreReq.Ud_PG_Required_Stip__c == '1') stips.add ('PG Required');
        if (reqResp.scoreReq.Ud_Proof_of_Ownership_Stip__c == '1') stips.add ('Proof of ownership');
        if (reqResp.scoreReq.UD_ACH_Guarantor_Stip__c == '1') stips.add ('ACH Guarantee Form');
        if (reqResp.scoreReq.Ud_Proof_of_Equipment_Location_Stip__c == '1') stips.add ('Proof of equipment location');
        if (reqResp.scoreReq.Ud_Auth_Signer_Track_Bus_Stip__c == '1') stips.add ('Authorized Signer Must Track to Business');
        if (reqResp.scoreReq.Ud_Sales_Leaseback_Doc_Stip__c == '1') stips.add ('Sale/Leaseback documentation');
        if (reqResp.scoreReq.Ud_TV_Docs_Stip__c == '1') stips.add ('Titled Vehicle Doc Package');
        if (reqResp.scoreReq.Ud_Pg_Fraud_Alert_Stip__c == '1') stips.add ('PG Fraud Alert Cleared');
        if (reqResp.scoreReq.Ud_Copy_of_Driver_License_Stip__c == '1') stips.add ('Copy of drivers\'s license');
        if (reqResp.scoreReq.Ud_Cust_Ver_Proc_Request_Stip__c == '1') stips.add ('Customer Verification Procedures Required');
        if (reqResp.scoreReq.Ud_Cust_Verifiy_Bank_Info_Stip__c == '1') stips.add ('Verify Bank Info');
        if (reqResp.scoreReq.UD_QUICK_TRACK__c == '1') stips.add ('Site Inspection');
        if (reqResp.scoreReq.UD_DUE_DILIGENCE__c == '1') stips.add ('Credit Due Diligence');
        if (reqResp.scoreReq.UD_CREDIT_DOCPACK__c == '1') stips.add ('Review of Doc Package');
        if (reqResp.scoreReq.UD_BANK_STATEMENT__c == '1') stips.add ('Bank Statement Review');
        if (reqResp.scoreReq.UD_VER_SSN__c == '1') stips.add('Verification of SSN');
        if (reqResp.scoreReq.UD_VER_TAXID__c == '1') stips.add('Verification of Tax Id Number');
        if (reqResp.scoreReq.UD_VER_LEGALSTRUCTURE__c == '1') stips.add('Verify Legal Structure');
        if (reqResp.scoreReq.Ud_Verbal_Stip__c == '1') stips.add('Verbal Stip');
        if (reqResp.scoreReq.UD_CUST_IDOLOGY__c == '1') stips.add('IDology');
        
        if (!stips.isEmpty()) opp.Stipulations__c = String.join(stips, ';');

        // credit analyst mapping
        if (reqResp.scoreReq.Ud_Credit_Analyst__c != null) {
            if (reqResp.scoreReq.Ud_Credit_Analyst__c == '000') {
                opp.Credit_Analyst__c = 'Scorecard';
            } else {
                List <User> users = new List <User> ([SELECT Name FROM User WHERE Personnel_Number__c = :reqResp.scoreReq.Ud_Credit_Analyst__c]);
                if (!users.isEmpty ()) opp.Credit_Analyst__c = users[0].Name;
            }
        }

        // have to do this outside of flow due to bug with picklist
        opp.Decision_Status__c = reqResp.scoreReq.Ud_App_Status__c;

        if (!String.isBlank (reqResp.scoreReq.DLG_Risk_Grade__c)) {
            opp.Credit_Risk_Grade__c = reqResp.scoreReq.DLG_Risk_Grade__c;
        } else if (!String.isBlank (reqResp.scoreReq.RBP_Risk_Grade__c)) {
            opp.Credit_Risk_Grade__c = reqResp.scoreReq.RBP_Risk_Grade__c;
        } else {
            opp.Credit_Risk_Grade__c = ''; // SAL-2728
        }

        // reason for approval
        if (reqResp.scoreReq.Ud_Approved_Reason__c == 'AA') {
            opp.Reason_for_Approval__c = 'Auto Approval';
        } else if (reqResp.scoreReq.Ud_Approved_Reason__c == 'ASFP') {
            opp.Reason_for_Approval__c = 'Approved SFP Tier 2';
        } else if (reqResp.scoreReq.Ud_Approved_Reason__c == 'IAD') {
            opp.Reason_for_Approval__c = 'Instant Auto Decision';
        } else if (reqResp.scoreReq.Ud_Approved_Reason__c == 'NFR') {
            opp.Reason_for_Approval__c = 'Approved with Supplemental Information';
        } else if (reqResp.scoreReq.Ud_Approved_Reason__c == 'SCQ') {
            opp.Reason_for_Approval__c = 'Satisfactory Credit Quality';
        }
        
        
        //SAL-2895
        System.debug('reject reason');
        System.debug(reqResp.scoreReq.UD_REJECT_REASON__c);
        String rejectReasons = reqResp.scoreReq.UD_REJECT_REASON__c;
        if(rejectReasons != null){
            String[] eachReason = rejectReasons.split(';');
            String rejectReason;
            for(Integer i = 0; i < eachReason.size(); i++){
                String temp;
                String reason = eachReason[i].trim();
                if (reason == 'AR') {
                    temp = 'Auto-Reject';
                } else if(reason == 'UA'){
                    temp = 'Unknown Applicant';
                } else if(reason == 'UD'){
                    temp = 'Unapproved Dealer';
                } else if(reason == 'BCS'){
                    temp = 'Business - Below Required Credit Score';
                } else if(reason == 'PIC'){
                    temp = 'Personal - Insufficient Credit History';
                } else if(reason == 'PBRC'){
                    temp = 'Personal - Below Required Credit Score';
                } else if(reason == 'RI'){
                    temp = 'Restricted Industry';
                } else if(reason == 'FID'){
                    temp = 'Failed ID Verification';
                } else if(reason == 'BB'){
                    temp = 'Business - Bankruptcy';
                } else if(reason == 'IA'){
                    temp = 'Ineligble Asset Type';
                } else if(reason == 'BIC'){
                    temp = 'Business - Insufficient Credit History';
                } else if(reason == 'SL'){
                    temp = 'State Level Lending Restrictions';
                } else if(reason == 'BLC'){
                    temp = 'Personal - Liens and Judgments';
                } else if(reason == 'OT'){
                    temp = 'Other';
                } else if(reason == 'TIB'){
                    temp = 'Time in Business';
                } else if(reason == 'BLJ'){
                    temp = 'Business - Liens and Judgments';
                } 
                
                if(temp != null){
                    if(rejectReason != null){
                        rejectReason += ';' + temp;
                    }
                    else{
                        rejectReason = temp;
                    }
                }
                
            }
            if(rejectReason != null){
                opp.Decline_Reason__c = rejectReason;
            }
        }
        
        // reason for reject
        /* this would be for if decline reason is not a multi-picklist
        if (reqResp.scoreReq.UD_REJECT_REASON__c == 'AR') {
            opp.Decline_Reason__c = 'Auto-Reject';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'UA'){
            opp.Decline_Reason__c = 'Unknown Applicant';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'UD'){
            opp.Decline_Reason__c = 'Unapproved Dealer';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'BCS'){
            opp.Decline_Reason__c = 'Business - Below Required Credit Score';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'PIC'){
            opp.Decline_Reason__c = 'Personal - Insufficient Credit History';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'PBRC'){
            opp.Decline_Reason__c = 'Personal - Below Required Credit Score';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'RI'){
            opp.Decline_Reason__c = 'Restricted Industry';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'FID'){
            opp.Decline_Reason__c = 'Failed ID Verification';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'BB'){
            opp.Decline_Reason__c = 'Business - Bankruptcy';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'IA'){
            opp.Decline_Reason__c = 'Ineligble Asset Type';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'BIC'){
            opp.Decline_Reason__c = 'Business - Insufficient Credit History';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'SL'){
            opp.Decline_Reason__c = 'State Level Lending Restrictions';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'BLC'){
            opp.Decline_Reason__c = 'Personal - Liens and Judgments';
        } else if(reqResp.scoreReq.UD_REJECT_REASON__c == 'OT'){
            opp.Decline_Reason__c = 'Other';
        } 
        */



        // more info picklist
        List<String> moreInfoReasons = new List <String> ();
        if (reqResp.scoreReq.Ud_Min_Confrim_TIB__c == '1') moreInfoReasons.add ('Confirmation of Business Operations');
        if (reqResp.scoreReq.Ud_Min_Personal_Info__c == '1') moreInfoReasons.add ('Personal Information');
        if (reqResp.scoreReq.ud_Min_Bank_Info__c == '1') moreInfoReasons.add ('Bank Information');
        if (!moreInfoReasons.isEmpty()) opp.More_Info__c = String.join(moreInfoReasons, ';');


        // Fraud Risk Flag
        //Changed by Tyler to check if flag is in XML Response for SAL-3159
        if(reqResp.xmlResponse.contains('FraudReviewFlag')){
            opp.FraudReviewFlag__c = reqResp.scoreReq.FraudReviewFlag__c;
        }
        
        // SAL-3988 
        // Credit Strategy
        if(reqResp.xmlResponse.contains('Credit_strategy')){
            opp.Credit_Strategy__c = reqResp.scoreReq.Credit_Strategy__c;
        }

        // https://marlinbusiness.atlassian.net/browse/SAL-996
        // setting auto decision fields

        // https://marlinbusiness.atlassian.net/browse/SAL-1187
        // also update credit decision when app returns from GDS with an Auto Approve, reject or more info
        if (opp.Recommended_Decision__c == 'Application should be approved.' && opp.Decision_Status__c == 'A') {

            if (opp.UD_CO_REC_DEC__c == 4) {
                opp.Application_Status__c = 'Automatically Approved';
                opp.Decisioned_By__c = 'Scorecard';
                opp.Credit_Decision__c = true;
                if (opp.Originally_Decisioned_By__c == null){
                    opp.Originally_Decisioned_By__c = 'Scorecard';
                }

            } else if (opp.UD_CO_REC_DEC__c == 2) {
                opp.Application_Status__c = 'Pending Decision';
            }

        } else if (opp.Recommended_Decision__c == 'Application should be rejected.' && opp.UD_CO_REC_DEC__c == 3 && opp.Decision_Status__c == 'R') {
            if (opp.SFP_Tier_2_Credit_Box__c != null) {
                opp.SFP2_In_Process__c = true;
            } else {
                opp.Application_Status__c = 'Rejected';
                opp.Decisioned_By__c = 'Scorecard';
                opp.Credit_Decision__c = true;
                if (opp.Originally_Decisioned_By__c == null){
                    opp.Originally_Decisioned_By__c = 'Scorecard';
                }
            }
        } else if (opp.Recommended_Decision__c == 'Auto More Info needed sent to Sales.' && opp.UD_CO_REC_DEC__c == 8 && opp.Decision_Status__c == 'AM' && opp.UD_EVER_AUTO_MORE_INFO__c == 1) {
            // automore info
            opp.Application_Status__c = 'Returned to Submitter';
            opp.Credit_Decision__c = true;
        } else if (opp.Recommended_Decision__c == 'Application should be manually reviewed.' && opp.UD_CO_REC_DEC__c == 2 && opp.Decision_Status__c == 'PE') {
            opp.Application_Status__c = 'Pending Decision';
        }

        // https://marlinbusiness.atlassian.net/browse/SAL-2554 - Default Policy Exception to ‘No Exception’ when ‘Recommended Decision’ contains ‘Approve'
        if (opp.Recommended_Decision__c!=null && opp.Recommended_Decision__c.containsIgnoreCase('approve')) {
            opp.Policy_Exception__c = 'No Exception';
        }


        // https://marlinbusiness.atlassian.net/browse/SAL-1198
        List <Opportunity> oppQueried = new List <Opportunity> ([SELECT Terms__c, Fraud_Flag__c, Equip_Code1__c FROM Opportunity WHERE Id =:opp.Id]);
        // Update the code as per SAL-3351, since max term approved should come from response.
        //if (!oppQueried.isEmpty()) opp.Max_Term_Approved__c = oppQueried[0].Terms__c;


        // https://marlinbusiness.atlassian.net/browse/SAL-1691
        // needed to move # of advance payment and # of security deposits here to check against the label
        Map <String, String> labelMap = TC_PicklistUtil.getLabelMap(Asset__c.Equipment_Code__c);
        if(TC_EquipmentCodeUtil.isMedical(oppQueried[0].Equip_Code1__c, labelMap)){
            opp.Required_Adv_Payments__c = String.isBlank (reqResp.scoreReq.Ud_Payments_Upfront__c) ? null : Decimal.valueOf (reqResp.scoreReq.Ud_Payments_Upfront__c);
            opp.Sec_Dep_Pymts__c = 0;
        } else {
            opp.Required_Adv_Payments__c = 0;
            opp.Sec_Dep_Pymts__c = String.isBlank (reqResp.scoreReq.Ud_Payments_Upfront__c) ? null : Decimal.valueOf (reqResp.scoreReq.Ud_Payments_Upfront__c);
        }

        update opp;

        // PGs
        List <Guarantor__c> pgUpdates = new List <Guarantor__c> ();

        for (Gds_Score_Request_Individual__c pg : reqResp.pgs) {
            Flow.Interview.TC_GDS_Score_Guarantor_Response_Mapping mapPgFields = new Flow.Interview.TC_GDS_Score_Guarantor_Response_Mapping(new Map <String, Object>{
                    'varPGRespId' => pg.Id
            });
            mapPgFields.start ();
            pgUpdates.add ((Guarantor__c) mapPgFields.getVariableValue('varGuarantor'));
        }

        // SAL-1861 - update the corp guarantor on the opp
        if (reqResp.cc.Id <> null) {
            Flow.Interview.TC_GDS_Score_Corp_Guarantor_Response_Mapping mapCcgFields = new Flow.Interview.TC_GDS_Score_Corp_Guarantor_Response_Mapping(new Map <String, Object>{
                'varCCGRespId' => reqResp.cc.Id
            });
            mapCcgFields.start();
            pgUpdates.add((Guarantor__c) mapCcgFields.getVariableValue('varGuarantor'));
        }

        // emailage fields here, since there currently isn't a flow mapper. for the contact
        
        List <Contact> contactUpdates = new List <Contact> ();
        Map <Id, Boolean> conDupe = new Map <Id, Boolean> ();
        
        for (Gds_Score_Request_Individual__c pg : reqResp.pgs) {
            if (conDupe.get (pg.Request_Based_On__c)== null) {
                conDupe.put (pg.Request_Based_On__c, true);
                contactUpdates.add (new Contact (Id = pg.Request_Based_On__c , Emailage_Pull_Time_Stamp__c  = pg.Resp_Emailage_Datetime_Stamp__c != null ? TC_DateTimeFormatter.gdsFormatPlatformEvent(pg.Resp_Emailage_Datetime_Stamp__c) : null , Emailage_Result__c = pg.Resp_Emailage_Result__c ));
            }
            
        }
        
        List <OpportunityContactRole> ocr = new List <OpportunityContactRole> ([SELECT ContactId FROM OpportunityContactRole WHERE Role = 'Primary Contact' AND OpportunityId = :opp.Id]);
        
        if (!ocr.isEmpty ()) {
            if (conDupe.get (ocr[0].ContactId)== null) {
                conDupe.put (ocr[0].ContactId, true);
                contactUpdates.add (new Contact (Id = ocr[0].ContactId , Emailage_Pull_Time_Stamp__c  = reqResp.scoreReq.Resp_Primary_Contact_Emailage_Date_Stamp__c != null ? TC_DateTimeFormatter.gdsFormatPlatformEvent (reqResp.scoreReq.Resp_Primary_Contact_Emailage_Date_Stamp__c) : null , Emailage_Result__c = reqResp.scoreReq.Resp_Primary_Contact_Emailage_Results__c ));
            }
        }
        
        // update contacts
        if (!contactUpdates.isEmpty ()) {
            update contactUpdates;
        }
        

        // ud_co_scorex_requested only is for the first 2 pgs and sets the first 2
        /* Formula I was given:

        Line 1: RESPONSEDATA_DBPASSWORD != “” THEN Y
        Line 2: RESPONSEDATA_PGINFO_CREDITBUREAUDET_ALL005 != “” THEN Y
        Line 3: RESPONSEDATA_PGINFO_CREDITBUREAUDET_ALL005 != “” THEN Y
        ELSE “N”

         */
        String scoreRequestedResult = 'N';
        if (!String.isBlank(reqResp.scoreReq.DBA_Password__c)
                || (!reqResp.pgs.isEmpty() && reqResp.pgs.size()>0 && !String.isBlank(reqResp.pgs[0].CREDITBUREAUDET_ALL005__c))
                || (!reqResp.pgs.isEmpty() && reqResp.pgs.size()>1 && !String.isBlank(reqResp.pgs[1].CREDITBUREAUDET_ALL005__c))) {
            scoreRequestedResult = 'Y';
        }

        if (!pgUpdates.isEmpty() && pgUpdates.size()>0) pgUpdates[0].Scorex_Requested_or_Scorex_Hit__c = scoreRequestedResult;
        if (!pgUpdates.isEmpty() && pgUpdates.size()>1) pgUpdates[1].Scorex_Requested_or_Scorex_Hit__c = scoreRequestedResult;

        update pgUpdates;
        
        
        // new on hold
        if (reqResp.dealer != null && reqResp.dealer.Request_Based_On__c  != null && reqResp.scoreReq.DLR_ONHOLD_INDICATOR__c != null && reqResp.scoreReq.DLR_ONHOLD_INDICATOR__c == '1') {
            update new Account (Id = reqResp.dealer.Request_Based_On__c , Account_Dealer_Status__c = 'On Hold');
        }
            
    }

}