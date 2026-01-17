/**
 * Serializes object representation of the request/response to and from xml
 *
 */

public with sharing class TC_GdsScoreXmlUtil{
    
    public static String handleNull (String str) {
        return str == null ? '' : str.escapeXml();
    }
    public static String handleNull (Decimal decValue) {
        return decValue == null ? '' : String.valueOf (decValue).escapeXml();
    }
    public static string handleBoolean (String boolValue) {
        return boolValue == 'true' ? '1' : '0';
    }
    
    // added a company type param, because Marlin doesn't want to send the empty tags for DBDUNSNUMBER for CC, BV, and company1
    private static String serializeCompanyRequest (Gds_Score_Request_Company__c company, String companyType) {
        
        String comXML = '';
        // CC should always have ccan tag, broker vendor for now should only have it it has a phone number
        if (companyType == 'CC') {
            comXML += '<CCAN>' + handleNull(company.Ccan__c) + '</CCAN>';
        } else if (companyType == 'BV') {
            if (company.Ccan__c != null) comXML += '<CCAN>' + company.Ccan__c + '</CCAN>';
        }
        
        comXml += '<NAME>' + handleNull(company.name) + '</NAME>';
        comXml += '<ADDRESS>' + handleNull(company.Address__c) + '</ADDRESS>';
        comXml += '<CITY>' + handleNull(company.City__c) + '</CITY>';
        comXml += '<STATE>' + handleNull(company.State__c) + '</STATE>';
        comXml += '<ZIPCODE>' + handleNull(company.Zip__c) + '</ZIPCODE>';
         
        
        
        comXml += '<ZIPEXTENSION></ZIPEXTENSION>';
        // phone was requested to be last for CC and BV
        if (companyType != 'CC' && companyType != 'BV') comXml += '<PHONE>' + handleNull(company.Phone__c) + '</PHONE>';
        comXml += '<IDNUMBER>' + handleNull(company.Id_Number__c) + '</IDNUMBER>';
        if (companyType != 'CC' && companyType != 'BV' && companyType != 'Company1') comXml += '<DBDUNSNUMBER>' + handleNull(company.Db_Duns_Number__c) + '</DBDUNSNUMBER>';
        comXml += '<EBFILENUMBER>' + handleNull(company.Ebfa_File_Number__c) + '</EBFILENUMBER>';
        if (company.Dealer_Status__c != null) comXML += '<DEALERSTATUS>' + company.Dealer_Status__c + '</DEALERSTATUS>';
        if (companyType == 'CC' || companyType == 'BV') comXml += '<PHONE>' + handleNull(company.Phone__c) + '</PHONE>';

        if (companyType == 'Company1'){
            // Added for equipment/shipping addresses
            // https://marlinbusiness.atlassian.net/browse/SAL-2763
            //changed tags from all uppercase per DFI Testing - Tyler 6/1/2021
            comXml += '<Equip_Address>' + handleNull(company.Equip_Address__c) + '</Equip_Address>';
            comXml += '<Equip_Address2>' + handleNull(company.Equip_Address2__c) + '</Equip_Address2>';
            comXml += '<Equip_City>' + handleNull(company.Equip_City__c) + '</Equip_City>';
            comXml += '<Equip_State>' + handleNull(company.Equip_State__c) + '</Equip_State>';
            comXml += '<Equip_Zip>' + handleNull(company.Equip_Zip__c) + '</Equip_Zip>';
            // End for equipment/shipping addresses
            // https://marlinbusiness.atlassian.net/browse/SAL-2763
            comXml += '<DBA>' + handleNull(company.DBA__c) + '</DBA>';
            comXml += '<PRIMARYCONTACT_FIRSTNAME>' + handleNull(company.Primary_Contact_First_Name__c) + '</PRIMARYCONTACT_FIRSTNAME>';
            comXml += '<PRIMARYCONTACT_LASTNAME>' + handleNull(company.Primary_Contact_Last_Name__c) + '</PRIMARYCONTACT_LASTNAME>';
            // SAL-2768 Add Primary Contact Phone
            comXml += (company.Primary_Contact_Phone__c != null) ? '<PRIMARYCONTACT_PHONE>'+handleNull(company.Primary_Contact_Phone__c)+'</PRIMARYCONTACT_PHONE>' : '<PRIMARYCONTACT_PHONE>'+handleNull(company.Phone__c)+'</PRIMARYCONTACT_PHONE>';
            comXml+= '<PRIMARYCONTACT_EMAIL>' + handleNull(company.Primary_Contact_Email__c) + '</PRIMARYCONTACT_EMAIL>';
            comXml+= '<PRIMARYCONTACT_VALIDITYVERIFY_RESULT>' + handleNull(company.Primary_Contact_Validity_Verify_Result__c) + '</PRIMARYCONTACT_VALIDITYVERIFY_RESULT>'; 
            comXml+= '<PRIMARYCONTACT_FINALEMAILVALIDITY>' + handleNull(company.Primary_Contact_Final_Email_Validity__c) + '</PRIMARYCONTACT_FINALEMAILVALIDITY>';
            comXML += '<TIB_Override>' + handleNull(company.TIB_Override__c) + '</TIB_Override>';
            comXML += '<TIBNUM_Manual>' + handleNull(company.TIBNUM_Manual__c) + '</TIBNUM_Manual>';
        }
        return comXml;
    }
    
    private static String serializeIndividualRequest (Gds_Score_Request_Individual__c ind, Integer i) {
        String indXml = '<CCAN>' + handleNull(ind.Ccan__c) + '</CCAN>';
        indXml += '<LASTNAME>' + handleNull(ind.Last_Name__c) + '</LASTNAME>';
        indXml += '<FIRSTNAME>' + handleNull(ind.First_Name__c) + '</FIRSTNAME>';
        indXml += '<SUFFIX></SUFFIX>';
        indXml += '<ADDRESS>' + handleNull(ind.Address__c) + '</ADDRESS>';
        indXml += '<CITY>' + handleNull(ind.City__c) + '</CITY>';
        indXml += '<STATE>' + handleNull(ind.State__c) + '</STATE>';
        indXml += '<ZIPCODE>' + handleNull(ind.Zip__c) + '</ZIPCODE>';
        indXml += '<ZIPEXTENSION></ZIPEXTENSION>';
        indXml += '<SSN>' + handleNull(ind.Ssn__c) +'</SSN>';
        //indXml += '<CCAN>' + handleNull(ind.Ccan__c) + '</CCAN>';
        indXml += '<HOMEPHONE>' + handleNull(ind.Phone__c) + '</HOMEPHONE>';
        indXml += '<EMAIL>' + handleNull(ind.Email__c) + '</EMAIL>';
        indXml += '<BIRTHDATE>' + handleNull(ind.Birthdate__c) + '</BIRTHDATE>';
        indXml += '<FraudFlag>' + handleBoolean(ind.FraudFlag__c) + '</FraudFlag>';
        if (i == 0) {
            indXml += '<PG1_VALIDITYVERIFY_RESULT>' + handleNull(ind.Validity_Verify_Status__c) + '</PG1_VALIDITYVERIFY_RESULT>';
            indXml += '<PG1_FINALEMAILVALIDITY>' + handleNull(ind.Final_Email_Validity_Result__c) + '</PG1_FINALEMAILVALIDITY>';
        } else if (i == 1) {
            indXml += '<PG2_VALIDITYVERIFY_RESULT>' + handleNull(ind.Validity_Verify_Status__c) + '</PG2_VALIDITYVERIFY_RESULT>';
            indXml += '<PG2_FINALEMAILVALIDITY>' + handleNull(ind.Final_Email_Validity_Result__c) + '</PG2_FINALEMAILVALIDITY>';            
        }

        return indXml;
    }

    public static String serializeRequest (TC_GDSScoreReqRespBean reqBean) {

        Gds_Score__c req = reqBean.scoreReq;// main request
        Gds_Score_Request_Company__c company1 = reqBean.company1;
        Gds_Score_Request_Company__c dealer = reqBean.dealer;
        Gds_Score_Request_Company__c broker = reqBean.broker;
        Gds_Score_Request_Company__c cc = reqBean.cc;
        List <Gds_Score_Request_Individual__c> pgs = reqBean.pgs;
        Opportunity opp = reqBean.opp;
        
        Webservice_Field__c wsFields = reqBean.wsFields;
        
        String xml = '<?xml version="1.0"?><APPLICATIONDATA>';
        xml += '<APPLICATIONDATE>' + handleNull(req.Application_Date__c) + '</APPLICATIONDATE>';
        
        String accType = opp.Brokers1__r.size() > 0 ? 'Broker Account' : opp.Brokers__r.size() > 0 ? 'Dealer Account' : '';
        xml += '<Account_type>'+accType+'</Account_type>';
        
        // new CALLTYPE logic
        if(opp.CustomerType__c == 'NEW' && opp.Decision_Status__c != null ){
            xml += '<CALLTYPE>Rescore_NEW</CALLTYPE>';  
        }else{
            xml += '<CALLTYPE></CALLTYPE>';  
        }
        
        // SFRescoreFlag - SAL-3812
        if(opp.Decision_Status__c != null ){
            xml += '<SFRescoreFlag>1</SFRescoreFlag>';  
        }else{
            xml += '<SFRescoreFlag>0</SFRescoreFlag>';  
        }
       
        /*
if we have lookup value , send what is there in the lookup 
if there is no value, send it as same.
 

*/
        
        xml += '<INFOLEASENUMBER>' + handleNull(req.Info_Lease_Number__c) + '</INFOLEASENUMBER>';
        
        //   xml += '<DEALERNUMBER>' + handleNull(opp.Brokers1__r[0].Broker_Dealer_Number__c) + '</DEALERNUMBER>';
        if(opp.Primary_Broker__c <> null && opp.Brokers1__r.size() > 0){
        xml += '<DEALERNUMBER>' + handleNull(opp.Brokers1__r[0].Broker_Dealer_Number__c) + '</DEALERNUMBER>';
        }else{
            xml += '<DEALERNUMBER>' + handleNull(req.Dealer_Number__c) + '</DEALERNUMBER>';
        }
        // requested to send empty tag: https://marlinbusiness.atlassian.net/browse/SAL-1088
        //xml += '<BROKERVENDORNUMBER>' + handleNull(req.Broker_Vendor_Number__c) + '</BROKERVENDORNUMBER>';
        xml += '<BROKERVENDORNUMBER></BROKERVENDORNUMBER>';
        xml += '<CCAN>' + handleNull(req.Ccan__c) + '</CCAN>';
        xml += '<BUSTYPE>' + handleNull(req.Business_Type__c) + '</BUSTYPE>';
        xml += '<TOTALEXPOSURE>' + handleNull(req.Total_Exposure__c) + '</TOTALEXPOSURE>';
        xml += '<SALESREPCODE>' + handleNull(req.Sales_Rep_Code__c) +  '</SALESREPCODE>';
        xml += '<LOANAMOUNT>' + handleNull(req.Loan_Amount__c) + '</LOANAMOUNT>';
        xml += '<LOANPURPOSE/>'; // requested to send empty tag
        xml += '<LOANEXISTING/>'; // requested to send empty tag

        xml += '<APPLICATIONMONTHS>' + handleNull(req.Application_Months__c) + '</APPLICATIONMONTHS>';
        xml += '<BRANCH>' + handleNull(req.Branch__c) + '</BRANCH>';
        
        if(wsFields != null){
            if (wsFields.Manager_PG_Override__c){
           xml += '<ManagerPGOveride>' + handleBoolean('True') + '</ManagerPGOveride>';
        } else{
            xml += '<ManagerPGOveride>' + handleBoolean('False') + '</ManagerPGOveride>';
            }
        }else {
            xml += '<ManagerPGOveride>' + handleBoolean('False') + '</ManagerPGOveride>';
        }
        
        //ORT Added Per SAL-2732
        xml += '<ORT>' + handleNull(req.Opportunity_Record_Type__c) + '</ORT>';

        // Pass the TIB Override and Manual TIB fields from the request to the company
        // easier to do it this way than refactoring the method to support opp as a parameter
        company1.TIB_Override__c = req.TIB_Override__c;
        company1.TIBNUM_Manual__c = req.Months_Verified_TIB__c;

        xml += '<COMPANY1>' + serializeCompanyRequest (company1, 'Company1') + '</COMPANY1>';
        if (dealer != new Gds_Score_Request_Company__c ()) xml += '<DEALER>' + serializeCompanyRequest (dealer, 'D') + '</DEALER>';
        // requested to add empty tags below
        xml += '<D1> <LASTNAME /> <FIRSTNAME /> <SUFFIX /> <ADDRESS /> <CITY /> <STATE /> <ZIPCODE /> <ZIPEXTENSION /> <SSN /> </D1> <D2> <LASTNAME /> <FIRSTNAME /> <SUFFIX /> <ADDRESS /> <CITY /> <STATE /> <ZIPCODE /> <ZIPEXTENSION /> <SSN /> </D2>';
        if (cc != new Gds_Score_Request_Company__c ()) xml += '<CC>' + serializeCompanyRequest (cc, 'CC') + '</CC>';
        if (broker != new Gds_Score_Request_Company__c ()) {
            xml += '<BV>' + serializeCompanyRequest (broker, 'BV') + '</BV>';
            // requested if there's a broker also send the b1,b2 empty tags
            xml += '<B1> <LASTNAME /> <FIRSTNAME /> <SUFFIX /> <ADDRESS /> <CITY /> <STATE /> <ZIPCODE /> <ZIPEXTENSION /> <SSN /> </B1> <B2> <LASTNAME /> <FIRSTNAME /> <SUFFIX /> <ADDRESS /> <CITY /> <STATE /> <ZIPCODE /> <ZIPEXTENSION /> <SSN /> </B2>';
        }
            
        // up to 4 pgs can be sent
        for (Integer i = 0; i < pgs.size () && i < 4; i++) {
            Integer pgTagNumber = i + 1;
            xml += '<PG'+ pgTagNumber + '>' + serializeIndividualRequest (pgs[i], i) + '</PG' + pgTagNumber + '>';
        }
        xml += '<UD_OFAC_HIT></UD_OFAC_HIT>'; // requested to send empty tag
        xml += '<UD_REJECTED_APP_LAST_90>' + handleNull(req.Ud_Rejected_App_Last_90__c) + '</UD_REJECTED_APP_LAST_90>';
        xml += '<NEW.USED>' + handleNull(req.New_Used__c) + '</NEW.USED>';
        //xml += '<UD_DEALER_STATUS>' + handleNull(req.Dealer_Status__c) + '</UD_DEALER_STATUS>'; not used
        xml += '<UD_PYMT_FREQUENCY>' + handleNull(req.Ud_Paymt_Frequency__c) + '</UD_PYMT_FREQUENCY>';
        xml += '<UD_RP_NUM_GUAR_PRIN>' + handleNull(req.ud_Rp_Num_Guar_Prin__c) + '</UD_RP_NUM_GUAR_PRIN>';
        xml += '<UD_RP_NOT_GUAR_PRIN2>' + handleNull(req.ud_Rp_Num_Guar_Prin_2__c) + '</UD_RP_NOT_GUAR_PRIN2>';
        xml += '<PROGRAM.TYPE>' + handleNull(req.Program_Type__c)+ '</PROGRAM.TYPE>';
        xml += '<UD_STATUS_CODE>' + handleNull(req.Ud_Status_Code__c) + '</UD_STATUS_CODE>';
        xml += '<CONTRACT.TERM>' + handleNull(req.Contract_Term__c) + '</CONTRACT.TERM>';
        xml += '<A.MANUFACTURER.YEAR>' + handleNull(req.Asset_Manufacturer_Year__c) + '</A.MANUFACTURER.YEAR>';
        xml += '<VEH_MILEAGE>' + handleNull(req.Vehicle_Mileage__c) + '</VEH_MILEAGE>';
        //xml += '<UD_CREDIT_AMOUNT>' + handleNull(req.Ud_Credit_Amount__c) + '</UD_CREDIT_AMOUNT>'; not used
        xml += '<timesDelinquentOver90>' + handleNull(req.Times_Delinquent_Over_90__c) + '</timesDelinquentOver90>';
        xml += '<UD_MONTHS_VERIFIED>' + handleNull(req.Ud_Months_Verified__c) +'</UD_MONTHS_VERIFIED>';
        xml += '<UD_PORTAL_USER_ID>' + handleNull(req.Ud_Portal_User_Id__c) + '</UD_PORTAL_USER_ID>';
        xml += '<UD_END_USER_SOURCE_CODE>' + handleNull(req.Ud_End_User_Source_Code__c) +'</UD_END_USER_SOURCE_CODE>';
        //xml += '<UD_SALESPERSON>' + handleNull(req.Ud_Sales_Person__c) + '</UD_SALESPERSON>'; requested to remove to match rapport
        xml += '<UD_ACTIVE_DEALER>' + handleNull(req.ud_Active_Dealer__c) + '</UD_ACTIVE_DEALER>';
        xml += '<UD_SFP_MODEL>' + handleNull(req.ud_SFP_Model__c) + '</UD_SFP_MODEL>';
        xml += '<UD_PORTAL_METHOD>2</UD_PORTAL_METHOD>';
        xml += '<UD_CUST_FRAUD_IND>' + handleNull(req.ud_Customer_Fraud_Ind__c) + '</UD_CUST_FRAUD_IND>';
        xml += '<UD_AUTOMOREINFO_OVERRIDE>' + handleNull(req.ud_Auto_More_Info_Override__c) + '</UD_AUTOMOREINFO_OVERRIDE>'; // might need to be 1/0
        xml += '<UD_PQ_FLAG /> <UD_PQ_DATE />'; // asked to add empty tags
        xml += '<UD_PQ_EXP_DATE>' + handleNull(req.Ud_Pq_Exp_Date__c) + '</UD_PQ_EXP_DATE>';
        xml += '<UD_PQ_AMT>' + handleNull(req.Ud_Pq_Amount__c) + '</UD_PQ_AMT>';
        xml += '<UD_PQ_LEVEL /> <UD_PQ_SCORE />'; // asked to add empty tags
        xml += '<UD_TAX_EXEMPT_CUST>' + handleNull(req.Ud_Tax_Exempt_Cust__c) + '</UD_TAX_EXEMPT_CUST>';
        xml += '<UD_TAX_EXEMPT_DATE>' + handleNull(req.Ud_Tax_Exempt_Date__c) + '</UD_TAX_EXEMPT_DATE>';
        xml += '<UD_VENDOR_APPROVAL>' + handleNull(req.Vendor_Approval__c) + '</UD_VENDOR_APPROVAL>';
        xml += '<UD_UB_BV_FLAG>'+handleNull(req.Ud_Ub_Bv_Flag__c)+'</UD_UB_BV_FLAG>';
        xml += '<UD_CUST_ASSET_ADDR_MATCH>' + handleNull(req.Ud_Cust_Asset_Address_Match__c) + '</UD_CUST_ASSET_ADDR_MATCH>';
        xml += '<EQUIP.CODE>' + handleNull(req.Equip_Code__c) + '</EQUIP.CODE>';
        xml += '<CustomerDealerDistance>' + handleNull(req.Customer_Dealer_Distance__c) + '</CustomerDealerDistance>'; // how to calculate
        xml += '<UD_CO_DLR_EXMPT_FRD_MDL>' + handleNull(req.Ud_Co_Dealer_Exempt_Fraud_Model__c) + '</UD_CO_DLR_EXMPT_FRD_MDL>';
        xml += '<UD_DLR_ENTERED_DATE>'+ handleNull(req.Ud_Dealer_Entered_Date__c) + '</UD_DLR_ENTERED_DATE>';
        xml += '<PreDelivery_20K_Trial>'+ handleNull(req.Pre_Delivery_20k_Trial__c) + '</PreDelivery_20K_Trial>'; // 4/30/20 https://marlinbusiness.atlassian.net/browse/SAL-1470
        // requested to add empty tags below
        xml +='<UD_SC_SCORE1 /> <UD_SC_USED1 /> <UD_SC_SCORE2 /> <UD_SC_USED2 /> <UD_SC_SCORE3 /> <UD_SC_USED3 /> <UD_SC_SCORE4 /> <UD_SC_USED4 /> <UD_SC_SCORE5 /> <UD_SC_USED5 /> <UD_RETAIL_GRADE1 /> <UD_RETAIL_GRADE2 /> <UD_RETAIL_GRADE3 />';
        
        xml += serializeMatchingNode(reqBean); // SAL-2765
        xml += '<CustomerType>'+ handleNull(reqBean.opp.CustomerType__c) +'</CustomerType>'; // SAL-2765

        // threatmetrix
        xml += '<THREATMETRIX>';
        xml += '<policy_score>' + handleNull(req.UD_TMETRIX_POLICY_SCORE__c) + '</policy_score>';
        xml += '<reason_code>' + handleNull(req.UD_TMETRIX_REASON_CODE__c) + '</reason_code>';
        xml += '<review_status>' + handleNull(req.UD_TMETRIX_REVIEW_STATUS__c) + '</review_status>';
        xml += '<risk_rating>' + handleNull(req.UD_TMETRIX_RISK_RATING__c) + '</risk_rating>';
        xml += '<true_ip>' + handleNull(req.UD_TMETRIX_TRUE_IP__c) + '</true_ip>';
        xml += '</THREATMETRIX>';

        // opportunity id
        xml += '<OPPORTUNITY_ID>' + handleNull(req.Opportunity__c) + '</OPPORTUNITY_ID>';
        xml += '<AppLinkedPortalID>' + handleNull(reqBean.opp.Digital_Portal_ID__c) + '</AppLinkedPortalID>';

        xml += '</APPLICATIONDATA>';
        return xml;
    }

    public static String serializeMatchingNode(TC_GDSScoreReqRespBean reqBean) {
        // Return empty Matching element if no WebService Fields record exists
        if (reqBean.wsFields==null) {return '<MATCHING />';}

        Webservice_Field__c wsFields = reqBean.wsFields;

        String matchingNode = '<MATCHING>';
        matchingNode += '<RunNewCustomerFlow>'+ handleNull(wsFields.RunNewCustomerFlow__c) +'</RunNewCustomerFlow>';
        matchingNode += '<BizInfoMatch>'+ handleNull(wsFields.BizInfoMatch__c) +'</BizInfoMatch>';
        matchingNode += '<BizCityMatch>'+ handleNull(wsFields.BizCityMatch__c) +'</BizCityMatch>';
        matchingNode += '<BizStateMatch>'+ handleNull(wsFields.BizStateMatch__c) +'</BizStateMatch>';
        matchingNode += '<BizZipMatch>'+ handleNull(wsFields.BizZipMatch__c) +'</BizZipMatch>';
        matchingNode += '<BizPhoneMatch>'+ handleNull(wsFields.BizPhoneMatch__c) +'</BizPhoneMatch>';
        matchingNode += '<PersonalInfoMatch>'+ handleNull(wsFields.PersonalInfoMatch__c) +'</PersonalInfoMatch>';
        matchingNode += '<PG1SSNMatch>'+ handleNull(wsFields.PG1SSNMatch__c) +'</PG1SSNMatch>';
        matchingNode += '<PG2SSNMatch>'+ handleNull(wsFields.PG2SSNMatch__c) +'</PG2SSNMatch>';
        matchingNode += '<PG1EmailMatch>'+ handleNull(wsFields.PG1EmailMatch__c) +'</PG1EmailMatch>';
        matchingNode += '<PG2EmailMatch>'+ handleNull(wsFields.PG2EmailMatch__c) +'</PG2EmailMatch>';
        matchingNode += '<PG1LastNameMatch>'+ handleNull(wsFields.PG1LastNameMatch__c) +'</PG1LastNameMatch>';
        matchingNode += '<PG2LastNameMatch>'+ handleNull(wsFields.PG2LastNameMatch__c) +'</PG2LastNameMatch>';
        matchingNode += '</MATCHING>';
        return matchingNode;
    }

    public static void deSerializeResponse (TC_GDSScoreReqRespBean respBean, String xmlResp) {

        Dom.Document xmlDoc = new Dom.Document ();
        xmlDoc.load (xmlResp);
        
        for (Dom.XMLNode gdsNode : xmlDoc.getRootElement().getChildren()) {
            if (gdsNode.getName() == 'APPLICATIONDATA_APPLICATIONDATE') {
                //Opportunity.Last_Date_Scorex_Retrieved__c
                String lastScoreDate = xmlDecode(gdsNode.getText ());
                respBean.scoreReq.Last_Date_Score_Retrieved__c = lastScoreDate != null ? Date.valueOf (lastScoreDate) : null;
            }else if (gdsNode.getName() == 'RESPONSEDATA_EBFILENUMBER') {
                respBean.company1.EBFILENUMBER__c = xmlDecode(gdsNode.getText ()); //  mapped
            } else if (gdsNode.getName() == 'RESPONSEDATA_DBPASSWORD') {
                // mapping document looks wrong
                respBean.scoreReq.DBA_Password__c = xmlDecode(gdsNode.getText ());
            } else if (gdsNode.getName() == 'RESPONSEDATA_DNBDVPACKET_APPLICANT') {
                parseDNBFields (respBean.company1, gdsNode);
            } else if (gdsNode.getName() == 'RESPONSEDATA_DNBDVPACKET_DEALER') {
                parseDNBFields (respBean.dealer, gdsNode);
            } else if (gdsNode.getName() == 'RESPONSEDATA_DNBDVPACKET_BV') {
                parseDNBFields (respBean.broker, gdsNode);
            } else if (gdsNode.getName() == 'ExtractFields') {
                parseExtractFields (respBean.scoreReq, respBean.dealer, respBean.company1, gdsNode);
            } else if (gdsNode.getName() == 'UD_OFAC_HIT') {
                //Opportunity.OFAC_HIT__c
                respBean.scoreReq.Ud_Ofac_Hit__c = gdsNode.getText ();
            } else if (gdsNode.getName() == 'UD_OFAC_PERFORMED') {
                //Opportunity.OFAC_Webservice_Called__c
                respBean.scoreReq.Ud_Ofac_Performed__c = gdsNode.getText ();
            } else if (gdsNode.getName() == 'UD_OFACRESULT') {
                //Opportunity.OFAC_Result__c
                respBean.scoreReq.Ud_Ofac_Result__c = gdsNode.getText ();
            } else if (gdsNode.getName() == 'SICCODELOOKUP') {
                //parseSICFields (respBean.company1, gdsNode); not from here anymore
            } else if (gdsNode.getName() == 'ScorecardSummary') {
                parseScorecardFields (respBean.scoreReq, gdsNode);
            } else if (gdsNode.getName() == 'RESPONSEDATA_PAYNET_APPLICANT') {
                parsePaynetFields (respBean.company1, gdsNode);
            } else if (gdsNode.getName() == 'PG_RETURN_INFORMATION_PG1') {
                if (!respBean.pgs.isEmpty () && respBean.pgs.size () >=1) parsePGFields (respBean.pgs[0], gdsNode);
            } else if (gdsNode.getName() == 'PG_RETURN_INFORMATION_PG2') {
                if (!respBean.pgs.isEmpty () && respBean.pgs.size () >=2) parsePGFields (respBean.pgs[1], gdsNode);
            } else if (gdsNode.getName() == 'PG_RETURN_INFORMATION_PG3') {
                if (!respBean.pgs.isEmpty () && respBean.pgs.size () >=3) parsePGFields (respBean.pgs[2], gdsNode);
            } else if (gdsNode.getName() == 'PG_RETURN_INFORMATION_PG4') {
                if (!respBean.pgs.isEmpty () && respBean.pgs.size () >=4) parsePGFields (respBean.pgs[3], gdsNode);
            } else if (gdsNode.getName() == 'Data_Warehouse') {
                parseDataWarehouseFields (respBean.company1, respBean.scoreReq, gdsNode);
            } else if (gdsNode.getName() == 'RESPONSEDATA_SCORES') {
                parseDataScoresFields (respBean, gdsNode);
            } else if (gdsNode.getName() == 'EQUIPCODELOOKUP') {
                parseEquipCodeLookupFields (respBean.scoreReq, gdsNode);
            } else if (gdsNode.getName() == 'MONTHS_IN_BUSINESS') {
                if (respBean.company1 != null) respBean.company1.Tib_Num__c  = gdsNode.getText ();
            } else if (gdsNode.getName() == 'UD_QUICK_TRACK') {
                respBean.scoreReq.UD_QUICK_TRACK__c  = xmlDecode(gdsNode.getText());
            } else if (gdsNode.getName() == 'DLR_ONHOLD_INDICATOR') {
                respBean.scoreReq.DLR_ONHOLD_INDICATOR__c = xmlDecode(gdsNode.getText());             
            } // new fields
            else if (gdsNode.getName() == 'UD_BANK_STATEMENT') {
                respBean.scoreReq.UD_BANK_STATEMENT__c  = xmlDecode(gdsNode.getText());
            } else if (gdsNode.getName() == 'UD_CREDIT_DOCPACK') {
                respBean.scoreReq.UD_CREDIT_DOCPACK__c  = xmlDecode(gdsNode.getText());
            } else if (gdsNode.getName() == 'UD_DUE_DILIGENCE') {
                respBean.scoreReq.UD_DUE_DILIGENCE__c  = xmlDecode(gdsNode.getText());
            } else if (gdsNode.getName() == 'UD_VER_SSN') {
                respBean.scoreReq.UD_VER_SSN__c = xmlDecode(gdsNode.getText()); // SAL-2853 new stip
            } else if (gdsNode.getName() == 'UD_VER_TAXID') {
                respBean.scoreReq.UD_VER_TAXID__c = xmlDecode(gdsNode.getText()); // SAL-2853 new stip
            } else if (gdsNode.getName() == 'UD_VER_LEGALSTRUCTURE') {
                respBean.scoreReq.UD_VER_LEGALSTRUCTURE__c = xmlDecode(gdsNode.getText()); // added during DFI End to End Testing 5/6
            } else if (gdsNode.getName() =='High_Risk_5_Deals') {
                respBean.scoreReq.High_Risk_5_Deals__c  = xmlDecode(gdsNode.getText());
            } // no sample xml and tags given in messy manner. emailage mappings may be wrong
            else if (gdsNode.getName() =='EmailageResults') {
                parseEmailageFields (respBean, gdsNode);
            } else if (gdsNode.getName() == 'CCG') {
                parseCCGFields (respBean, gdsNode);
            } else if (gdsNode.getName() == 'FraudReviewFlag') {
                respBean.scoreReq.FraudReviewFlag__c = Integer.valueOf(xmlDecode(gdsNode.getText()));
            } else if (gdsNode.getName() == 'Credit_strategy') {
                respBean.scoreReq.Credit_Strategy__c = xmlDecode(gdsNode.getText());
            }
        }
    }

    // SAL-1861: Map CCG (Corp Guarantor) fields from XML to Gds_Score_Request_Company__c (respBean.cc) object
    private static void parseCCGFields (TC_GDSScoreReqRespBean respBean, Dom.XmlNode xmlNode) {

        // Check the node for fields contained within
        if (!xmlNode.getChildren().isEmpty()) {

            for (Dom.XmlNode childNode : xmlNode.getChildren()) {
                if (childNode.getName() == 'CCG_MarlinScore') {
                    respBean.cc.CCG_Marlin_Score__c = Integer.valueOf(xmlDecode(childNode.getText()));
                } else if (childNode.getName() == 'CCG_BusinessRules') {
                    respBean.cc.CCG_Business_Rules__c = xmlDecode(childNode.getText());
                } else if (childNode.getName() == 'CCG_RNS') {
                    respBean.cc.CCG_Reasons_Not_Scored__c = xmlDecode(childNode.getText());
                } else if (childNode.getName() == 'CCG_RiskGrade') {
                    respBean.cc.CCG_Risk_Grade__c = xmlDecode(childNode.getText());
                } else if (childNode.getName() == 'CCG_ScorecardUsed') {
                    respBean.cc.CCG_Scorecard_Used__c = xmlDecode(childNode.getText());
                } else if (childNode.getName() == 'CCG_Total_Exposure_Amount') {
                    respBean.cc.CCG_Total_Exposure_Amount__c = Decimal.valueOf(xmlDecode(childNode.getText()));
                }
            }
        }
    }
    
    private static void parseEmailageFields (TC_GDSScoreReqRespBean respBean, Dom.XMLNode xmlNode) {

        if (!xmlNode.getChildren().isEmpty ()) {

            for (Dom.XMLNode resultsNode : xmlNode.getChildren()) {
                if (resultsNode.getName () == 'PrimaryContact_Emailage_Result') {
                    respBean.scoreReq.Resp_Primary_Contact_Emailage_Results__c = xmlDecode(resultsNode.getText());
                } else if (resultsNode.getName () == 'PrimaryContact_Emailage_Timestamp') {
                    respBean.scoreReq.Resp_Primary_Contact_Emailage_Date_Stamp__c = xmlDecode(resultsNode.getText());
                } else if (resultsNode.getName () == 'PG1_Emailage_Timestamp' && !respBean.pgs.isEmpty ()) {
                    respBean.pgs[0].Resp_Emailage_Datetime_Stamp__c  = xmlDecode(resultsNode.getText());
                } else if (resultsNode.getName () == 'PG1_Emailage_Result' && !respBean.pgs.isEmpty ()) {
                    respBean.pgs[0].Resp_Emailage_Result__c = xmlDecode(resultsNode.getText());
                } else if (resultsNode.getName () == 'PG2_Emailage_Result' && !respBean.pgs.isEmpty () && respBean.pgs.size () > 1) {
                    respBean.pgs[1].Resp_Emailage_Result__c = xmlDecode(resultsNode.getText());
                } else if (resultsNode.getName () == 'PG2_Emailage_Timestamp' && !respBean.pgs.isEmpty () && respBean.pgs.size () > 1) {
                    respBean.pgs[1].Resp_Emailage_Datetime_Stamp__c = xmlDecode(resultsNode.getText());
                }
                
            }
        }

    }
    
    private static void parseExtractFields (Gds_Score__c app, Gds_Score_Request_Company__c dealer, Gds_Score_Request_Company__c com, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {
            for (Dom.XMLNode extractNode : xmlNode.getChildren()) {
                
                // stips all mapped
                if (extractNode.getName() == 'UD_VERIFY_SLF') {
                    app.UD_Verify_SLF_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_SOFTWARE_STIP') {
                    app.UD_Software_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_MUNICIPAL_ADDENDUM') {
                    app.Ud_Municipal_Addendum_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_CORP_RES_LESSEE_PO') {
                    app.Ud_Corp_Res_Lessee_Po_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_EQUIPMENT_APPROVAL') {
                    app.Ud_Equipment_Approval_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_PROOF_OF_BUS_LOC') {
                    app.Ud_Proof_of_Business_Location_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_RESIDUAL_STIP') {
                    app.Ud_Residual_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_OWNER_TO_SIGN') {
                    app.Ud_Owner_to_Sign_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_UCC_FILING_SEARCH') {
                    app.Ud_Ucc_Filing_Search_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_TECERT') {
                    app.Ud_Tecert_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_PATRIOT_STIP') {
                    app.Ud_Patriot_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_VENDOR_APPROVAL_OUTPUT') {
                    app.Ud_Vendor_Approval_Output_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_PG_REQUIRED') {
                    app.Ud_PG_Required_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_PROOF_OF_OWNERSHIP') {
                    app.Ud_Proof_of_Ownership_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_ACH_GUAR') {
                    app.UD_ACH_Guarantor_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_PROOF_OF_EQUIP_LOC') {
                    app.Ud_Proof_of_Equipment_Location_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_AUTH_SIGNER_TRACK_BUS') {
                    app.Ud_Auth_Signer_Track_Bus_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_SALE_LEASEBACK_DOC') {
                    app.Ud_Sales_Leaseback_Doc_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_TV_DOCS') {
                    app.Ud_TV_Docs_Stip__c  = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_PG_FRAUD_ALERT') {
                    app.Ud_Pg_Fraud_Alert_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_COPY_OF_DRIVER_LICENSE') {
                    app.Ud_Copy_of_Driver_License_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_CUST_VER_PROC_REQ') {
                    app.Ud_Cust_Ver_Proc_Request_Stip__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_VERIFY_BANK_INFO') {
                    app.Ud_Cust_Verifiy_Bank_Info_Stip__c  = xmlDecode(extractNode.getText());
                }
                else if (extractNode.getName() == 'UD_CUST_IDOLOGY') {
                    app.UD_CUST_IDOLOGY__c  = xmlDecode(extractNode.getText());
                }
                // non stip fields
                else if (extractNode.getName() == 'LOAN_AMOUNT') {
                    app.Credit_Amount__c = xmlDecode(extractNode.getText()); // mapped
                } else if (extractNode.getName() == 'Total_Exposure_Amount') {
                    app.Total_Exposure_Amount__c  = xmlDecode(extractNode.getText());// mapped
                } else if (extractNode.getName() == 'UD_ACTIVE_CONT_PAST_31') {
                    app.Ud_Active_Cont_Past_31__c  = xmlDecode(extractNode.getText());// mapped
                } else if (extractNode.getName() == 'DispContPymtsMade') {
                    app.Display_Contact_Payments_Made__c  = xmlDecode(extractNode.getText());// mapped
                } else if (extractNode.getName() == 'ActiveContPymtsMade') {
                    app.Active_Contact_Payments_Made__c = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'UD_MIN_CONFIRM_TIB') {
                    app.Ud_Min_Confrim_TIB__c  = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'UD_MIN_BANK_INFO') {
                    app.ud_Min_Bank_Info__c  = xmlDecode(extractNode.getText()); //mapped
                } else if (extractNode.getName() == 'UD_MIN_PERSONAL_INFO') {
                    app.Ud_Min_Personal_Info__c  = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'UD_SYND_ELIGIBLE') {
                    app.Ud_Syndication_Eligible__c  = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'MODEL_NAME') {
                    app.Model_Name__c = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'UNDERLYING_MODEL') {
                    app.Underlying_Model__c = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'UD_EXP_OVER_150K') {
                    app.Ud_Exp_Over_150K__c = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'UD_MONTHS_VERIFIED_DE_IN') {
                    app.Ud_Months_Verified__c = xmlDecode(extractNode.getText());//MAPPED
                } else if (extractNode.getName() == 'UD_EXIST_CUST_OUTPUT') {
                    app.Ud_Existing_Customer__c = xmlDecode(extractNode.getText()); //MAPPED
                } else if (extractNode.getName() == 'UD_SFP_MODEL_OUTPUT') {
                    app.Ud_SFP_Model_Output__c = xmlDecode(extractNode.getText()); //mapped
                } else if (extractNode.getName() == 'UD_PYMTS_UPFRONT') {
                    app.Ud_Payments_Upfront__c = xmlDecode(extractNode.getText()); // mapped
                } else if (extractNode.getName() == 'LESSOR') {
                    app.Lessor__c = xmlDecode(extractNode.getText()); //mapped
                } else if (extractNode.getName() == 'UD_APPROVED_REASON') {
                    app.Ud_Approved_Reason__c = xmlDecode(extractNode.getText());// mapped, restricted picklist
                } else if (extractNode.getName() == 'UD_CREDIT_ANALYST') {
                    app.Ud_Credit_Analyst__c = xmlDecode(extractNode.getText());//mapped
                } else if (extractNode.getName() == 'UD_CO_REC_DEC') {
                     app.UD_CO_REC_DEC__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_APP_STATUS') {
                    app.Ud_App_Status__c  = xmlDecode(extractNode.getText()); //mapped
                } else if (extractNode.getName() == 'UD_SS_CREDIT_BOX') {
                    app.Ud_SS_Credit_Box__c  = xmlDecode(extractNode.getText());// mapped
                } else if (extractNode.getName() == 'UD_EVER_AUTO_MORE_INFO') {
                    app.UD_EVER_AUTO_MORE_INFO__c  = xmlDecode(extractNode.getText());// mapped
                } else if (extractNode.getName() == 'UD_TAX_EXEMPT_DATE_OUTPUT') {
                    app.UD_TAX_EXEMPT_DATE_OUTPUT__c  = xmlDecode(extractNode.getText()); // opp.Tax_Exempt_Date__c
                } else if (extractNode.getName() == 'UD_MAX_TERM') {
                    app.UD_MAX_TERM__c  = xmlDecode(extractNode.getText()); // Opportunity.Max_Term_Approved__c
                    //when Term > Max term, system should override the term 
                    if(app.Opportunity__r.Terms__c > Double.valueOf(app.UD_MAX_TERM__c)){
                        app.UD_Term__c  = xmlDecode(extractNode.getText()); // Opportunity.Term
                    }
                } else if (extractNode.getName() == 'UD_REJECT_REASON') {
                    app.UD_REJECT_REASON__c  = xmlDecode(extractNode.getText()); // Opportunity.Decline_Reason__c
                } else if (extractNode.getName() == 'PUR_OPTION') {
                    //app.PUR_OPTION__c  = xmlDecode(extractNode.getText()); // Opportunity.Purchase_Options__c told not to map
                } else if (extractNode.getName() == 'UD_DLR_PREFERRED') {
                    //app.UD_DLR_PREFERRED__c  = xmlDecode(extractNode.getText()); // acc.Preferred_Dealer_Level__c told not to map
                } else if (extractNode.getName() ==  'UD_DLR_CLASSIFICATION') {
                    dealer.UD_DLR_CLASSIFICATION__c  = xmlDecode(extractNode.getText()); // acc.Dealer_Classification__c
                } else if (extractNode.getName() == 'SICCODE_preference_input') {
                    app.SICCODE_Preference_Input__c = xmlDecode(extractNode.getText());// mapped
                } else if (extractNode.getName() == 'SICCODE') {
                    //sic
                    com.Marlin_Sic__c = xmlDecode(extractNode.getText());
                } else if (extractNode.getName() == 'UD_MIN_MISC_NOTES') {
                    //opportunity.more_info_misc_notes__c
                    app.UD_MIN_MISC_NOTES__c = xmlDecode(extractNode.getText());
                }
            }
        }
    }
    
    private static void parseDNBFields (Gds_Score_Request_Company__c com, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {
            for (Dom.XMLNode dnbNode : xmlNode.getChildren()) {
                if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE') {
                    //com.D_B_SBRI_Score__c = xmlDecode(dnbNode.getText()); // udpated mapping
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_SICPRIMARYPKTEO') {
                    
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE') {
                    com.D_B_Commercial_Credit_Score__c = xmlDecode(dnbNode.getText());
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_HIGHESTCREDIT') {
                    com.D_B_Highest_Credit__c = xmlDecode(dnbNode.getText()); // mapped
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_EMPLOYEESTOTAL') {
                    com.D_B_Number_of_Employees__c = xmlDecode(dnbNode.getText()); // mapped
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_NUMTRADEEXPPAYDEX') {
                    com.D_B_Number_Trade_Exp__c = xmlDecode(dnbNode.getText());
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_CURRMONTHPAYDEX') {
                    com.Current_Month_Paydex__c = xmlDecode(dnbNode.getText()); // mapped
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_RETURNCODE') {
                    com.D_B_Return_Code__c = xmlDecode(dnbNode.getText()); // mapped
                } else if (dnbNode.getName() == 'RESPONSEDATA_DNBDVPACKET_DUNSNUMBER') {
                    com.Db_Duns_Number__c = xmlDecode(dnbNode.getText()); // mapped
                }
            }
        }
        
    }
    private static void parseScorecardFields (Gds_Score__c app, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {
            for (Dom.XMLNode scorecardNode : xmlNode.getChildren()) {
                if (scorecardNode.getName() == 'RawScore') {
                    app.Raw_Score__c  = xmlDecode(scorecardNode.getText()); // mapped
                } else if (scorecardNode.getName() == 'FinalScore') {
                    app.Final_Score__c  = xmlDecode(scorecardNode.getText()); // mapped
                } else if (scorecardNode.getName() == 'FinalDecision_Comment') {
                    app.Final_Decision_Comments__c  = xmlDecode(scorecardNode.getText()); // mapped
                } else if (scorecardNode.getName() == 'Signal_Count') {
                    app.Signal_Count__c  = xmlDecode(scorecardNode.getText()); // mapped
                } else if (scorecardNode.getName() == 'Rule_Count') {
                    app.Rule_Count__c = xmlDecode(scorecardNode.getText()); // mapped
                } else if (scorecardNode.getName() == 'RNS_description') {
                    app.RNS_Description__c = xmlDecode(scorecardNode.getText()); //mapped
                } else if (scorecardNode.getName() == 'businessrule_description') {
                    app.Business_Rule_Description__c = xmlDecode(scorecardNode.getText());
                } else if (scorecardNode.getName() == 'DLG_RiskGrade') {
                    app.DLG_Risk_Grade__c = xmlDecode(scorecardNode.getText()); //mapped
                } else if (scorecardNode.getName() == 'RBP_RiskGrade3') {
                    app.RBP_Risk_Grade__c = xmlDecode(scorecardNode.getText()); //mapped
                }
            }
        }
        
    }
    
    private static void parsePaynetFields (Gds_Score_Request_Company__c com, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {
            for (Dom.XMLNode paynetNode : xmlNode.getChildren()) {
                if (paynetNode.getName() == 'RESPONSEDATA_PAYNET_MAXORIGRECEIVABLEAMT') {
                    com.Paynet_Max_Orig_Receivable_Amount__c = xmlDecode(paynetNode.getText());
                    //Opportunity.Max_Orig_Receivable_Amt__c
                } else if (paynetNode.getName() == 'RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE') {
                    com.Paynet_Sbri_Score__c = xmlDecode(paynetNode.getText());
                }
            }
        }
    }
    
    private static void parsePGFields (Gds_Score_Request_Individual__c ind, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {
            for (Dom.XMLNode pgNode : xmlNode.getChildren()) {
                if (pgNode.getName() == 'RESPONSEDATA_LEXISNEXIS') {
                    for (Dom.XMLNode lexisNexisNode : pgNode.getChildren()) {
                        if (lexisNexisNode.getName() == 'RESPONSEDATA_LEXISNEXIS_LNCRALIENANDJUDGMENTTOTALAMOUNT') {
                            ind.Lexis_Nexis_Total_CRA_Lien_Judgments__c = xmlDecode(lexisNexisNode.getText ());//MAPPED
                        }
                    }
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_CREDITBUREAUDET_BAC403') {
                    ind.PG_Utilization__c = xmlDecode(pgNode.getText()); // MAPPED
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_CREDITBUREAUDET_ALL803') {
                    ind.Inquiries_in_last_6_Months__c = xmlDecode(pgNode.getText());
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_CREDITBUREAUDET_ALL005') {
                    ind.CREDITBUREAUDET_ALL005__c = xmlDecode(pgNode.getText());
                }
                /*
                else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_TUFIELDS_ALL803') {
                    //Guarantor.Inquiries_in_last_6_Months__c
                    //ind.Transunion_Inquiries_in_last_6_Months__c = xmlDecode(pgNode.getText ()); // mapped
                } else if (pgNode.getName() =='RESPONSEDATA_PGINFO_TUFIELDS_ALL005') {
                    //Guarantor.Scorex_Requested_or_Scorex_Hit__c
                    //ind.Transunion_Scorex_Requested_or_Hit__c = xmlDecode(pgNode.getText ()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EQUFIELDS_ALL803') {
                    //Guarantor.Inquiries_in_last_6_Months__c
                    //ind.Equifax_Inquiries_in_last_6_Months__c = xmlDecode(pgNode.getText()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EQUFIELDS_ALL005') {
                    //Guarantor.Scorex_Requested_or_Scorex_Hit__c
                    //ind.Equifax_Scorex_Requested_or_Hit__c = xmlDecode(pgNode.getText()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EXPERIANFIELDS_ALL803') {
                    //Guarantor.Inquiries_in_last_6_Months__c
                    //ind.Experian_Inquiries_in_last_6_Months__c = xmlDecode(pgNode.getText ()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EXPERIANFIELDS_ALL005') {
                    //Guarantor.Scorex_Requested_or_Scorex_Hit__c
                    //ind.Experian_Scorex_Requested_or_Hit__c = xmlDecode(pgNode.getText ()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_CREDITBUREAUDET_BAC403') {
                    ind.PG_Utilization__c = xmlDecode(pgNode.getText()); // MAPPED
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EXPERIANFIELDS_VANTAGE_V3_SCORE') {
                    //ind.Experian_Vantage__c = xmlDecode(pgNode.getText ()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EXPERIANFIELDS_ALL0200') {
                    //Guarantor.Total_Trades__c
                    //ind.Experian_Total_Trades__c = xmlDecode(pgNode.getText()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EQUFIELDS_ALL0200') {
                    //Guarantor.Total_Trades__c
                    //ind.Equifax_Total_Trades__c = xmlDecode(pgNode.getText ()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_TUFIELDS_ALL0200') {
                    //Guarantor.Total_Trades__c
                    //ind.Transunion_Total_Trades__c = xmlDecode(pgNode.getText()); //mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_CREDITBUREAUDET_ALL005') {
                    //ind.Total_Trades__c = xmlDecode(pgNode.getText()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_TUFIELDS_VANTAGE_V3_SCORE') {
                    //ind.Transunion_Vantage__c = xmlDecode(pgNode.getText()); // mapped
                } else if (pgNode.getName() == 'RESPONSEDATA_PGINFO_EQUFIELDS_VANTAGE_V3_SCORE') {
                    //ind.Equifax_Vantage__c = xmlDecode(pgNode.getText());
                }*/
            }
        }
    }
    
   /* private static void parseSICFields (Gds_Score_Request_Company__c com, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {
            for (Dom.XMLNode sicNode : xmlNode.getChildren()) {
                if (sicNode.getName() == 'MARLINSIC') {
                    com.Marlin_Sic__c = xmlDecode(sicNode.getText());
                    //Account.Account_EU_FS_SIC_Description__c (API Name)
                } else if (sicNode.getName() == 'MARLINSICDESC') {
                    com.Marlin_Sic_Code_Description__c = xmlDecode(sicNode.getText());
                    //Account.Account_EU_FS_SIC_Description__c  // mapped
                }
            }
        }
    }*/

    private static void parseDataWarehouseFields (Gds_Score_Request_Company__c com, Gds_Score__c app, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {

            for (Dom.XMLNode warehouseNode : xmlNode.getChildren()) {
                if (warehouseNode.getName () == 'DWH_GetDataForCreditScoring') {
                    for (Dom.XMLNode creditScoringNode : warehouseNode.getChildren()) {
                        if (creditScoringNode.getName () == 'FastTrak_IAD_Eligible') {
                            com.FastTrak_IAD_Eligible__c = xmlDecode(creditScoringNode.getText());
                        }
                    }
                } else if (warehouseNode.getName () == 'DWH_GetDataForFraud') {
                    for (Dom.XMLNode node : warehouseNode.getChildren()) {
                        /* this is mapped to another FraudReviewFlag field in a different path
                        if (node.getName () == 'FraudReviewFlag') {
                            app.FraudReviewFlag__c = Integer.valueOf(xmlDecode(node.getText()));
                        }
                        */
                    }
                }
            }
        }
    }

    private static void parseDataScoresFields (TC_GDSScoreReqRespBean respBean, Dom.XMLNode xmlNode) {
    //Gds_Score_Request_Company__c com, Gds_Score__c app,
        if (!xmlNode.getChildren().isEmpty ()) {

            for (Dom.XMLNode dataScoreNode : xmlNode.getChildren()) {
                if (dataScoreNode.getName () == 'TIB_NUM') {
                    //respBean.company1.Tib_Num__c = xmlDecode(dataScoreNode.getText()); not using anymore
                } else if (dataScoreNode.getName () == 'APP1_RESPONSEDATA_VANTAGE_V3') {
                    if (!respBean.pgs.isEmpty()) respBean.pgs[0].Vantage__c = xmlDecode(dataScoreNode.getText());
                } else if (dataScoreNode.getName () == 'APP2_RESPONSEDATA_VANTAGE_V3') {
                    if (!respBean.pgs.isEmpty() && respBean.pgs.size()>1) respBean.pgs[1].Vantage__c = xmlDecode(dataScoreNode.getText());
                } else if (dataScoreNode.getName () == 'RESPONSEDATA_DNB_SBRILEASESCORE') {
                    if (respBean.company1 != null) respBean.company1.D_B_SBRI_Score__c = xmlDecode(dataScoreNode.getText());
                }
            }
        }

    }

    private static void parseEquipCodeLookupFields (Gds_Score__c app, Dom.XMLNode xmlNode) {
        if (!xmlNode.getChildren().isEmpty ()) {
            for (Dom.XMLNode equipCodeLookupNode : xmlNode.getChildren()) {
                if (equipCodeLookupNode.getName () == 'RestrictedEquip') {
                    app.Restricted_Equip__c = xmlDecode(equipCodeLookupNode.getText());
                }
            }
        }
    }

    private static String xmlDecode (String xmlValue) {
        return xmlValue == null ? '': xmlValue.unescapeXml ();
    }

}