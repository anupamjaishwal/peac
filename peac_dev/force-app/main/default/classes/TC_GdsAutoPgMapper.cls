/**
* @description       : SAL-2310 - New Integration call to GDS Auto PG Webservice
 * @author            : Joseph Cadd
 * @group             : 
 * @last modified on  : 12-30-2020
 * @last modified by  : Joseph Cadd
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   12-24-2020   Joseph Cadd   Initial Version
 * 1.1   1-13-2021    Craig Rudrud  Update to EQUIP_CODE and BUSTYPE mappings for opportunities, as well as dealer number
 * 1.2   3-20-2021    Joseph Cadd   SAL-2767 Update AutoPG Webservice call with new fields for Digital Fraud Initiative
**/
public with sharing class TC_GdsAutoPgMapper {

    public static TC_GdsAutoPgReqResp mapSalesforceToBean(Id recordId, TC_DwhStoredProcedureRespBean.resultBean dwhResults) {

        TC_GdsAutoPgReqResp bean = new TC_GdsAutoPgReqResp(recordId);
        Opportunity opp = bean?.opp;

        // Map Application, PGSEQUENCING, COMPANY1
        if (bean.objectName == 'Opportunity') {
            mapRequest_Application_Opportunity(bean, dwhResults);
            mapRequest_Company1_Opportunity(bean);

        } else if (bean.objectName == 'Lead') {
            mapRequest_Application_Lead(bean);
            mapRequest_Company1_Lead(bean);
        }
        
        
        mapRequest_Webservice_Fields(bean, dwhResults); // SAL-2767
        mapRequest_PgSequencing(bean, dwhResults);

        return bean;
    }


    public static TC_GdsAutoPgReqResp mapRequest_Application_Opportunity(TC_GdsAutoPgReqResp bean, TC_DwhStoredProcedureRespBean.resultBean dwhResults) {
        
        Opportunity oppRec = [SELECT Id, (SELECT Id, Account__r.Equipment_type__c FROM Brokers1__r), (SELECT Id, Dealer__r.Equipment_type__c FROM Brokers__r) FROM Opportunity WHERE Id = :bean.opp.Id];
        bean.request.OPPORTUNITY_ID = bean.recordId;         
        bean.request.APPLICATIONDATE = dateTimeToDateString(bean.opp.Application_Submitted__c);
        bean.request.DEALERNUMBER = handleNull( getDealerNumberByDealerRecordId(bean.opp.Primary_Dealer__c) );
        bean.request.BUSTYPE = handleNull( getRapportMapping(bean.acc.Business_Type__c, 'Business_Type') ); // Change to '03'?
        bean.request.CCAN = handleNull( bean.opp.CCAN__c );
        bean.request.EQUIP_CODE = handleNull( getAssetEquipmentCode(bean.recordId) );
        bean.request.EQUIP_COST = handleNull( bean.opp.Equipment_Cost__c ); 
        bean.request.LOANAMOUNT = handleNull( bean.opp.Equipment_Cost__c );
        bean.request.CustomerType = handleNull( dwhResults?.CustomerType );
        bean.request.UD_DLR_ENTERED_DATE = handleNull(getDealerCreatedDateByDealerRecordId(bean.opp.Primary_Dealer__c, true));
        bean.request.timesDelinquentOver90 = String.isBlank(handleNull(bean.acc.Account_121__c)) ? '0' : handleNull(bean.acc.Account_121__c);
        //SAL-2732
        bean.request.ORT = handleNull(bean.opp.record_type_name__c?.split(' ')[0]);
        bean.request.Accounttype = oppRec.Brokers1__r.size() > 0 ? 'Broker Account' : oppRec.Brokers__r.size() > 0 ? 'Dealer Account' : '';
        bean.request.PGSEQUENCING.Equipment_type = getEquipment(oppRec);
        return bean;
    }
    public static TC_GdsAutoPgReqResp mapRequest_Application_Lead(TC_GdsAutoPgReqResp bean) {
        String coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        coveragePlease = '1';
        coveragePlease = '0';
        Opportunity oppRec = [SELECT Id, (SELECT Id, Account__r.Equipment_type__c FROM Brokers1__r), (SELECT Id, Dealer__r.Equipment_type__c FROM Brokers__r)  FROM Opportunity WHERE Id = :bean.recordId];
        bean.request.OPPORTUNITY_ID = bean.recordId;         
        bean.request.APPLICATIONDATE = dateTimeToDateString(bean.lead.Loan_Portal_Creation_Date__c);
        bean.request.DEALERNUMBER = handleNull( getDealerNumberByAccountId(bean.lead.Related_Dealer__c) );
        bean.request.BUSTYPE = '03'; // Change to '03'?
        bean.request.CCAN = handleNull( bean.lead.CCAN__c );
        bean.request.EQUIP_CODE = handleNull( getRapportMapping(bean.lead.Equipment_Type__c, 'Equipment_Code') );
        bean.request.EQUIP_COST = handleNull( bean.lead.Equipment_Cost__c ); 
        bean.request.LOANAMOUNT = handleNull( bean.lead.Equipment_Cost__c );
        bean.request.Accounttype = oppRec.Brokers1__r.size() > 0 ? 'Broker Account' : oppRec.Brokers__r.size() > 0 ? 'Dealer Account' : '';
        bean.request.PGSEQUENCING.Equipment_type = getEquipment(oppRec);
        return bean;
    }
    
    

    public static TC_GdsAutoPgReqResp mapRequest_Company1_Opportunity(TC_GdsAutoPgReqResp bean) {
        TC_GdsAutoPgReqResp.cls_Company1 company = bean.request.COMPANY1;
        List <Asset__c> assets = new List <Asset__c> ([SELECT Id, Equipment_Code__c,Equipment_Street__c,Equipment_Address_2__c,Equipment_City__c,Equipment_State__c,Equipment_Zip__c, 
                                                       New_Used__c, Mileage__c, Equipment_Sub_Category__c FROM Asset__c WHERE Opportunity__c = :bean.opp.Id ORDER BY CreatedDate ASC]);

        Opportunity opp = bean.opp;
        Account acc = bean.acc;
        Contact primaryCon = (Contact) TC_DataUtility.queryAllById(opp.Primary_Contact__c);
        Opportunity oppRec = [SELECT Id, (SELECT Id, Account__r.Equipment_type__c FROM Brokers1__r), (SELECT Id, Dealer__r.Equipment_type__c FROM Brokers__r)  FROM Opportunity WHERE Id = :opp.Id];
        company.NAME = acc?.Name?.escapeXml();                       
        company.ADDRESS = handleNull( opp?.Account_Business_Street__c);
        company.CITY = handleNull( opp?.Account_Business_City__c);
        company.STATE = handleNull( opp?.Account_Business_State_Province__c);
        company.ZIPCODE = handleNull( opp?.Account_Business_Zip_Postal_Code__c);  
        company.ZIPEXTENSION = '';
        company.PHONE = handleNull( opp?.Phone__c); 
        company.IDNUMBER = handleNull( acc?.Tax_ID__c);
        company.DBDUNSNUMBER = handleNull( acc?.DUNS__c);   
        company.EBFILENUMBER = handleNull( acc?.EB_File_Number__c);  
        company.STATEINCORP = handleNull( opp?.State_of_Incorporation__c);               
        company.DBA = handleNull( opp?.DBA__c);                         
        company.SELFREPORTEDBUSSTARTDATE = String.valueOf(acc?.Account_Business_Start_Date__c);     
        company.STRUCTURE = handleNull( acc?.Legal_Structure__c);
        company.PRIMARYCONTACT_FIRSTNAME = handleNull ( primaryCon?.FirstName );
        company.PRIMARYCONTACT_LASTNAME = handleNull ( primaryCon?.LastName );
        company.PRIMARYCONTACT_PHONE = handleNull ( primaryCon?.Phone );
        company.PRIMARYCONTACT_EMAIL = handleNull( opp?.Primary_Contact_Email_Formula__c); // <PRIMARYCONTACT_EMAIL />
        company.PRIMARYCONTACT_FINALEMAILVALIDITY = handleNull( primaryCon?.Final_E_mail_Validity_Result__c); // <PRIMARYCONTACT_FINALEMAILVALIDITY />
        company.PRIMARYCONTACT_VALIDITYVERIFY_RESULT = handleNull( primaryCon?.Validity_Verify__Status__c); // <PRIMARYCONTACT_VALIDITYVERIFY_RESULT />
        
        if (!assets.isEmpty()) {
            // Added Equipment Code/Category logic
            // https://marlinbusiness.atlassian.net/browse/SAL-1622
            company.EQUIP_ADDRESS =  handleNull(assets[0].Equipment_Street__c);
            company.EQUIP_ADDRESS2 =  handleNull(assets[0].Equipment_Address_2__c);
            company.EQUIP_CITY =  handleNull(assets[0].Equipment_City__c);    
            company.EQUIP_STATE =  handleNull(assets[0].Equipment_State__c);    
            company.EQUIP_ZIP =  handleNull(assets[0].Equipment_Zip__c);    
                
        } 
        
        // Store mapped pgSequence and return the bean
        bean.request.COMPANY1 = company;
        bean.request.Accounttype = oppRec.Brokers1__r.size() > 0 ? 'Broker Account' : oppRec.Brokers__r.size() > 0 ? 'Dealer Account' : '';
        bean.request.PGSEQUENCING.Equipment_type = getEquipment(oppRec);
        return bean;
    }
    public static TC_GdsAutoPgReqResp mapRequest_Company1_Lead(TC_GdsAutoPgReqResp bean) {
        TC_GdsAutoPgReqResp.cls_Company1 company = bean.request.COMPANY1;
        Lead lead = bean.lead;
        // Account acc = bean.acc;
        // Contact primaryCon = (Contact) TC_DataUtility.queryAllById(opp.Primary_Contact__c);
        
        company.NAME = handleNull(lead.Company);                       
        company.ADDRESS = handleNull(lead?.Business_Address__c);
        company.CITY = handleNull(lead?.Business_City__c);
        company.STATE = handleNull(lead?.Business_State__c);
        company.ZIPCODE = handleNull( lead?.Business_Zip__c.length()>5 ? lead.Business_Zip__c.substring(0, 5) : lead?.Business_Zip__c );  
        company.ZIPEXTENSION = handleNull(lead?.Business_Zip__c.length()>5 ? lead.Business_Zip__c.substring(5) : ''); 
        company.PHONE = handleNull(lead?.Business_Phone__c); 
        company.IDNUMBER = '';
        company.DBDUNSNUMBER = handleNull(lead?.Tax_ID__c);   
        company.EBFILENUMBER = '';  
        company.STATEINCORP = handleNull(lead?.Business_State__c);               
        company.DBA = handleNull(lead?.Business_DBA__c);                         
        company.SELFREPORTEDBUSSTARTDATE = String.valueOf(lead?.Date_Established__c);     
        company.STRUCTURE = handleNull(lead?.Legal_Structure__c);                   
        company.PRIMARYCONTACT_EMAIL = handleNull(lead?.Email); // <PRIMARYCONTACT_EMAIL />
        company.PRIMARYCONTACT_FINALEMAILVALIDITY = handleNull(lead?.Validity_Verify__Status__c); // <PRIMARYCONTACT_FINALEMAILVALIDITY />
        company.PRIMARYCONTACT_VALIDITYVERIFY_RESULT = handleNull(lead?.Validity_Verify__Status__c); // <PRIMARYCONTACT_VALIDITYVERIFY_RESULT />
        
        // Store mapped pgSequence and return the bean
        bean.request.COMPANY1 = company;
        return bean;
    }


    public static TC_GdsAutoPgReqResp mapRequest_PgSequencing(TC_GdsAutoPgReqResp bean, TC_DwhStoredProcedureRespBean.resultBean dwhResults) {
        TC_GdsAutoPgReqResp.cls_PgSequencing ps = bean.request.PGSEQUENCING;

        ps.Total_Exposure = dwhResults?.Lease_OnBalanceSheet_Total_Exposure;// String.valueOf(opp?.Total_Exposure__c); // <Total_Exposure>1</Total_Exposure>
        ps.UD_ACT_CONT_PYMTS_MADE = dwhResults?.Lease_Active_Contracts_Payments_Made;        // <UD_ACT_CONT_PYMTS_MADE>10</UD_ACT_CONT_PYMTS_MADE>
        ps.UD_EXIST_CUST = dwhResults?.Existing_Loan_Customer;                // <UD_EXIST_CUST>5</UD_EXIST_CUST>
        ps.UD_DISP_CONT_PYMTS_MADE = dwhResults?.Lease_Disposed_Contracts_Payments_Made;       // <UD_DISP_CONT_PYMTS_MADE>0</UD_DISP_CONT_PYMTS_MADE>
        ps.UD_GAIN_LOSS_CHECK = dwhResults?.Lease_Gain_Loss_Check;            // <UD_GAIN_LOSS_CHECK>5</UD_GAIN_LOSS_CHECK>
        ps.Lease_61plus_Delin = dwhResults?.Lease_Curr_61_Plus_Delin;            // <Lease_61plus_Delin>0</Lease_61plus_Delin>
        ps.Lease_Ever91plus_Delin = dwhResults?.Lease_Ever_91_Plus_Delin;        // <Lease_Ever91plus_Delin>0</Lease_Ever91plus_Delin>
        ps.UD_ACTIVE_CONT_PAST_31 = dwhResults?.Lease_Active_Contracts_Past_31;        // <UD_ACTIVE_CONT_PAST_31>0</UD_ACTIVE_CONT_PAST_31>
        ps.Loan_Total_Charge_Off_Count = dwhResults?.Loan_Total_Charge_Off_Count;   // <Loan_Total_Charge_Off_Count>5</Loan_Total_Charge_Off_Count>
        ps.Loan_Current_Days_Delinquent = dwhResults?.Loan_Curr_15_Plus_Days_Delin;  // <Loan_Current_Days_Delinquent>5</Loan_Current_Days_Delinquent>
        ps.PriorPGonApp = dwhResults?.Prior_PG_On_App;                  // <PriorPGonApp>0</PriorPGonApp>
        ps.COVID_Restructure = dwhResults?.COVID_Restructure;             // <COVID_Restructure>0</COVID_Restructure>
        ps.UD_DLR_PREFERRED = dwhResults?.UD_DEALER_PREFERRED;              // <UD_DLR_PREFERRED>0</UD_DLR_PREFERRED>
        ps.UD_DLR_CLASSIFICATION = dwhResults?.UD_DEALER_CLASSIFICATION;         // <UD_DLR_CLASSIFICATION>0</UD_DLR_CLASSIFICATION>
        
        // Store mapped pgSequence and return the bean
        bean.request.PGSEQUENCING = ps;
        return bean;
    }
    
    public static String getEquipment(Opportunity oppRec){
    
        String EquipmentType = '';
        if(oppRec.Brokers1__r.size() > 0){
            EquipmentType = oppRec.Brokers1__r[0].Account__r.Equipment_type__c;
        }else if(oppRec.Brokers__r.size() > 0){
            EquipmentType = oppRec.Brokers__r[0].Dealer__r.Equipment_type__c;
        }
        return handleNull(String.isNotBlank(EquipmentType) ? String.join(EquipmentType.split(';'), ',') : '');
    }

    // SAL-2767 Update AutoPG Webservice call with new fields
    public static TC_GdsAutoPgReqResp mapRequest_Webservice_Fields(TC_GdsAutoPgReqResp bean, TC_DwhStoredProcedureRespBean.resultBean dwhResults) {
        // Return bean if no WebService Fields record exists
//        if (bean.wsFields==null) {return bean;} Commented out because we're mapping these fields from dwhResult bean

        // Map MATCHING data
        TC_GdsAutoPgReqResp.cls_Matching matching = bean.request.MATCHING;

        System.debug('dwhResults?.BizInfoMatch>>>' + dwhResults?.BizInfoMatch);
        System.debug('dwhResults?.RunNewCustomerFlow>>>' + dwhResults?.RunNewCustomerFlow);
        System.debug('dwhResults?.DealerDistance>>>' + dwhResults?.DealerDistance);

        matching.BizInfoMatch = handleNull(dwhResults?.BizInfoMatch);
        matching.RunNewCustomerFlow = handleNull(dwhResults?.RunNewCustomerFlow);

        System.debug('matching.BizInfoMatch>>>' + matching.BizInfoMatch);
        System.debug('matching.RunNewCustomerFlow>>>' + matching.RunNewCustomerFlow);

        // Map Opp Specific Fields
        if (bean.objectName=='Opportunity') {
            bean.request.CustomerDealerDistance = handleNull( dwhResults?.DealerDistance );
            System.debug('bean.request.CustomerDealerDistance>>> ' + bean.request.CustomerDealerDistance);
        }

        return bean;
    }

    private static String handleNull (String str) {
        return str == null ? '' : str.escapeXml();
    }
    private static String handleNull (Decimal decValue) {
        return decValue == null ? '' : String.valueOf (decValue).escapeXml();
    }
    private static Integer handleBoolean (Boolean boolValue) {
        return boolValue == true ? 1 : 0;
    }

    public static String dateTimeToDateString(DateTime dt) {
        if (dt == null) {return '';}
        Date myDate = dt.date();
        return String.valueOf(myDate).escapeXml();
    }

    public static String getRapportMapping(String recordName, String mappingName) {

        String equipmentCode = '';

        if (recordName <> null && recordName <> '') {
            Map <String, Map <String, String>> mappingMap = getMappingMap();
            if (mappingMap <> null && mappingMap.size() > 0) {
                Map <String, String> eqCodeMappings = mappingMap.get (mappingName);
                if (eqCodeMappings <> null) {
                    equipmentCode = eqCodeMappings.get (recordName);
                }
            }
        }

        return equipmentCode;
    }

    public static String getAssetEquipmentCode(Id oppId) {

        String eqCode = '';

        // Asset Codes
        List <Asset__c> assets = new List <Asset__c> ([
                SELECT Id,
                        Equipment_Code__c,
                        Equipment_Sub_Category__c
                FROM Asset__c
                WHERE Opportunity__c = :oppId
                ORDER BY CreatedDate ASC
        ]);

        if (!assets.isEmpty()) {
            eqCode = getRapportMapping(TC_Asset.getMostGranularAssetCode(assets[0]), 'Equipment_Code');
        }

        return eqCode;
    }

    private static String getDealerNumberByAccountId(Id accountId) {

        String dealerNumber = '';

        if (accountId <> null) {

            Account acc = [SELECT Id, Dealer_Number__c FROM Account WHERE Id = :accountId];

            if (acc <> null) {
                dealerNumber = acc.Dealer_Number__c;
            }
        }

        return dealerNumber;
    }

    private static String getDealerNumberByDealerRecordId(Id dealerRecordId) {
        String dealerNumber = '';

        if (dealerRecordId <> null) {

            Dealer__c dealer = [SELECT Id, Dealer__r.Dealer_Number__c FROM Dealer__c WHERE Id = :dealerRecordId];

            if (dealer <> null) {
                dealerNumber = dealer.Dealer__r.Dealer_Number__c;
            }
        }

        return dealerNumber;
    }

    private static String getDealerCreatedDateByDealerRecordId(Id dealerRecordId, Boolean transformDate) {
        String createdDate = '';

        if (dealerRecordId <> null) {

            Dealer__c dealer = [SELECT Id, Dealer__r.CreatedDate FROM Dealer__c WHERE Id = :dealerRecordId];

            if (dealer <> null) {

                if (transformDate) {
                    String month = ('0' + dealer.Dealer__r.CreatedDate.month()).right (2);
                    String day = ('0' + dealer.Dealer__r.CreatedDate.day()).right (2);
                    createdDate = dealer.Dealer__r.CreatedDate.year() + '-' + month + '-' + day;
                } else {
                    createdDate = String.valueOf(dealer.Dealer__r.CreatedDate);
                }                
            }
        }

        return createdDate;
    }

    private static Map <String, Map <String, String>> getMappingMap() {

        List <MARLIN_Rapport_Mapping__mdt> mappings = new List <MARLIN_Rapport_Mapping__mdt> ([
                SELECT Label,
                        Rapport_Value__c,
                        Field_Name__c
                FROM MARLIN_Rapport_Mapping__mdt
        ]);

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

        return mappingMap;
    }
}