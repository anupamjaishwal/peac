public without sharing class TC_GDSDealerQueueable implements Queueable, Database.AllowsCallouts {
    private static final Set<String> DECIMAL_TYPES = new Set<String>{'DOUBLE','PERCENT','CURRENCY'};
    private static Set<String> FIELD_TYPES_TO_CAST = new Set<String> {'DATE','DATETIME','INTEGER','BOOLEAN','DOUBLE','PERCENT','CURRENCY'};

    private String functionToExecute {get; set;}

    private Id recordId {get; set;}

    private Account acct {
        get {
            if (this.acct == null && this.recordId != null && this.recordId.getSobjectType() == Account.getSObjectType()) this.acct = getAccount(this.recordId);
            return acct;
        }
        set;
    }

    private Contact cont;

    private static Map<String, String> dealerOutputToAccountFieldMap = new Map<String, String> {
            'DEALER_HardRule_Count'=>'Hard_Rule_Count__c',
            'DEALER_SoftRule_Count'=>'Soft_Rule_Count__c',
            'DEALER_PreDelivery_Ind'=>'Pre_Delivery__c',
            'DEALER_MarlinScore'=>'Marlin_Score__c',
            'DEALER_TIBNUM'=>'Account_Months_In_Business__c',
            'DEALER_MarlinScore'=>'Marlin_Score__c',
            'DEALER_RecommendedDecision'=>'Recommended_Decision__c',
            'DEALER_PreDelivery_Ind'=>'Pre_Delivery__c',
            'DEALER_BusinessRulesNotMet'=>'Business_Rules_Not_Met__c',
            'DEALER_ReasonNotScored'=>'Reasons_Not_Scored__c'

    };

    private static Map<String, String> xmlToAccountFieldMap {
            get {
                if (xmlToAccountFieldMap == null) {
                    xmlToAccountFieldMap = new Map<String, String>();
                    xmlToAccountFieldMap.putAll(dealerOutputToAccountFieldMap);
                    xmlToAccountFieldMap.putAll(dbNodeToAccountFieldMap);
                }
                return dealerOutputToAccountFieldMap;
            }
            set;
    }

    private static Map<String, String> dealerOutputToContactFieldMap = new Map<String, String> {
            'DEALER_EmailageTimestamp'=>'Emailage_Pull_Time_Stamp__c',
            'DEALER_EmailageResult'=>'Emailage_Result__c'
    };

    private static Map<String, String> dbNodeToAccountFieldMap = new Map<String, String> {
            'RESPONSEDATA_DNBDVPACKET_EMPLOYEESTOTAL'=>'of_Employees_DE__c',
            'RESPONSEDATA_DNBDVPACKET_CURRMONTHPAYDEX'=>'Current_Month_PYDX__c',
            'RESPONSEDATA_DNBDVPACKET_COMMERCIALCREDITSCORE'=>'CC_Score__c',
            'RESPONSEDATA_DNBDVPACKET_HIGHESTCREDIT'=>'D_B_High_Credit__c',
            'RESPONSEDATA_DNBDVPACKET_SBRILEASESCORE'=>'SBRI__c',
            'RESPONSEDATA_DNBDVPACKET_SICPRIMARYPKTEO'=>'Account_EU_FS_SIC_Description__c',
            'RESPONSEDATA_DNBDVPACKET_LINEOFBUSINESS'=>'SicDesc',
            'FinalScore'=>'IF_Marlin_Score__c',
            'RNS_description'=>'IF_Reasons_Not_Scored__c',
            'FinalDecision'=>'IF_Recommended_Decision__c',
            'businessrule_description'=>'IF_Business_Rules_Not_Met__c',
            'RBP_RiskGrade1'=>'IF_Credit_Risk_Grade__c',
            'Total_Exposure_Amount'=>'IF_Total_Exposure_Amount__c'
    };

    public TC_GDSDealerQueueable(Id recordId, String functionToExecute) {
        this.recordId = recordId;
        this.functionToExecute = functionToExecute;
    }


    public void execute(QueueableContext qc) {
        //SAL-2242/2243
        if (this.functionToExecute == Label.TC_GDS_Get_Dealer) doGetDealer();
        //SAL-2241
        if (this.functionToExecute == Label.TC_GDS_Get_Dealer_InfoLease) doDealerInfoLeaseCallout();
    }

    /**
     * @description This function will get the dealer based on the GDS logic
     * @see         SAL-2242/2243
     */
    private void doGetDealer() {
        if (this.acct != null) {
            String message;
            String req;
            String resp;
            //SAL-2241
            if (String.isBlank(acct.Dealer_Number__c) && acct.Account_Dealer_Status__c != 'Pending' && String.isBlank(acct.Reasons_Not_Scored__c) && !Test.isRunningTest()) {
                System.enqueueJob(new TC_GDSDealerQueueable(this.recordId, Label.TC_GDS_Get_Dealer_InfoLease));
            } else {
                TC_LGHTNPullGDSDealerDNB.ClientResponse cr;
                try {
                    //SAL-2242/2243
                    if (String.isNotBlank(acct.Dealer_Number__c)) {

                        cr = TC_LGHTNPullGDSDealerDNB.pullDNB(this.recordId);
                        req = TC_LGHTNPullGDSDealerDNB.request;
                        resp = TC_LGHTNPullGDSDealerDNB.response;
                        this.cont = TC_LGHTNPullGDSDealerDNB.cont;
                        message = cr.message;
                        System.debug(cr.message);
                        if (String.isNotBlank(message) && message.containsIgnoreCase(' success')) {
                            String responseXML = getResponseXML(cr.body);
                            doProcessDealerResponse(responseXML);
                            doFinalAccountAndContactUpdate();
                            sendNotificationToIFCredit();
                        }
                    }
                } catch (Exception e) {
                    System.debug(e.getMessage() + ':' + e.getStackTraceString());
                    message += ':' + e.getMessage() + ':' + e.getStackTraceString() + '---' + acct.DM_Review_Status__c;
                } finally {
                    MARLIN_IntegrationLog.addLog(Label.TC_GDS_Get_Dealer, this.recordId, cr.status, req, resp, '200', message);
                }
                if (!MARLIN_IntegrationLog.logs.isEmpty()) MARLIN_IntegrationLog.insertLogs();
            }
        }

    }

    /**
     * @description This function will get the response from the dealer XML response
     * @see         SAL-2243
     *
     * @param body  The body containing the response data
     *
     * @return      The response XML data
     */
    private String getResponseXML(String body) {
        String responseXML = '';
        Dom.Document xmlDoc = new Dom.Document ();
        xmlDoc.load (body);

        //Finding the main result
        for (Dom.XmlNode envNode : xmlDoc.getRootElement().getChildren()) {
            for (Dom.XmlNode bodyNode : envNode.getChildren()) {
                for (Dom.XmlNode responseNode : bodyNode.getChildren()) {
                    if ('ProcessApplicationResult' == responseNode.getName()) {
                        responseXML = responseNode.getText();
                    }
                }
            }
        }

        return responseXML;
    }

    /**
     * @description         This function will process the individual elements and update the account
     * @see                 SAL-2243
     *
     * @param responseXML   The response XML
     */
    private void doProcessDealerResponse(String responseXML) {
        if (String.isNotBlank(responseXML)) {
            Dom.Document resultDoc = new Dom.Document ();
            resultDoc.load (responseXML);
            List<String> branchNodeNames = new List<String>{'RESPONSEDATA_DNBDVPACKET', 'RESPONSEDATA_DNBDVPACKET_DEALER',
                'ScorecardSummary', 'ExtractFields'};
            for (Dom.XMLNode recordNode : resultDoc.getRootElement().getChildren()) {
                if (recordNode.getName()?.equalsIgnoreCase('DEALER_Output')){
                    processDealerOutput(recordNode?.getChildren());
                }
                if(branchNodeNames.contains(recordNode.getName())){
                    processDNBPacket(recordNode?.getChildren());
                }
            }
        }
    }

    /**
     * @description This function will do the final account and contact updates as needed
     * @see         SAL-2243
     */
    private void doFinalAccountAndContactUpdate() {
        Account currentAccount = getAccount(acct.Id);
        String branch = String.isBlank(acct.Account_Branch__c) ? '' : acct.Account_Branch__c;
        String equipmentType = String.isBlank(acct.Equipment_Type__c) ? '' : acct.Equipment_Type__c;

        // acct.Account_Dealer_Status__c = acct.Recommended_Decision__c == 'Rejected' ? acct.Recommended_Decision__c : acct.Account_Dealer_Status__c;
        // acct.Account_Dealer_Status__c = acct.Recommended_Decision__c == 'Approved' && !branch.containsIgnoreCase('OEG') && !equipmentType.containsIgnoreCase('Copiers') ? 'Active' : acct.Account_Dealer_Status__c;
        // acct.Account_Dealer_Status__c = acct.Recommended_Decision__c == 'Approved' && (branch.containsIgnoreCase('OEG') || equipmentType.containsIgnoreCase('Copiers')) ? 'Need Signed Agreement' : acct.Account_Dealer_Status__c;
        // acct.Account_Dealer_Status__c = acct.Recommended_Decision__c == 'Manual Review' ? 'Pending' : acct.Account_Dealer_Status__c;
        Boolean isDealerStatusLocked = (acct.DM_Review_Status__c == 'Submitted for Review' && acct.Review_For__c == 'Inventory Finance')
            || (acct.IF_Marlin_Score__c != 0 && acct.IF_Marlin_Score__c != null);
        if(!isDealerStatusLocked){
            // SAL-2854
            if (acct.Recommended_Decision__c=='Rejected') {
                acct.Account_Dealer_Status__c = acct.Recommended_Decision__c;

            } else if (acct.Recommended_Decision__c=='Approved') {
                // OEG Exception
                if ((branch.containsIgnoreCase('Office Equip Group-OEG') || equipmentType.containsIgnoreCase('Copiers'))
                    && (!acct.VPA__c && !acct.VPA_w_PD__c && !acct.VPA_w_CPC__c && !acct.VPA_w_FPD__c && !acct.VPA_w_Remittance__c && !acct.VPA_w_Capped_Residual__c && !acct.Sales_and_Assignment__c)) 
                {
                    acct.Account_Dealer_Status__c ='Need Signed Agreement';
                } else {
                    acct.Account_Dealer_Status__c ='Active';
                }
                //Added Status does not equal 'Pre-Qualified' for SAL-3212
            } else if (acct.Recommended_Decision__c=='Manual Review' && acct.Account_Dealer_Status__c != 'Pre-Qualified') {
                acct.Account_Dealer_Status__c = 'Pending';
            } 
        }
        


        acct.Approved_Reason__c = acct.Recommended_Decision__c == 'Approved' ? 'Auto-Approved' : acct.Approved_Reason__c;
        acct.Rejected_Reason__c = acct.Recommended_Decision__c == 'Rejected' ? 'Auto-Rejected' : acct.Rejected_Reason__c;

        acct.Assigned_to_DM_User__c = acct.Account_Dealer_Status__c == 'Active' || acct.Account_Dealer_Status__c == 'Rejected' ? scoreCardUser?.Id: acct.Assigned_to_DM_User__c;
        if (currentAccount.Account_Dealer_Status__c != 'Active' && acct.Account_Dealer_Status__c == 'Active') acct.Date_Dealer_Approved_Most_Recent__c = Date.today();
        acct.Last_DataView_Pull_Date__c = System.now();
        
        // SAL-2858 Only update status to Completed if Review_For__c does not contain values other than 'Approval;Predelivery' (only Approval or predeliver can be selected)
        String reviewFor = acct.Review_For__c;
        if (reviewFor != null 
            && (reviewFor.equals('Approval') || reviewFor.equals('Predelivery') || reviewFor.equals('Approval;Predelivery') || reviewFor.equals('Predelivery;Approval'))) {
            acct.DM_Review_Status__c = 'Completed';
        }
        update acct;
        if (cont != null) update cont;
    }

    private void sendNotificationToIFCredit(){
        if(acct.Review_For__c == 'Inventory Finance'){
            List<Messaging.SingleEmailMessage> mailPouch = new List<Messaging.SingleEmailMessage>();
            SL_AccountTriggerEmailsQ.sendEmailToIFCredit(mailPouch, new List<Id>{this.acct.Id}, true);
            Messaging.sendEmail(mailPouch);
        }
    }

    private static User scoreCardUser {
        get {
            if (scoreCardUser == null) scoreCardUser = [SELECT Id FROM User WHERE LastName = 'Scorecard' LIMIT 1];
            return scoreCardUser;
        }
        set;
    }

    /**
     * @description     This function will process the dealer output node
     * @see             SAL-2243
     *
     * @param xmlNodes  The xml child nodes of the dealer output section
     */
    private void processDealerOutput(List<Dom.XmlNode> xmlNodes) {
        for (Dom.XmlNode dbNode : xmlNodes) {
            String fieldNm = xmlToAccountFieldMap.get(dbNode.getName());
            fieldNm = fieldNm == null ? dealerOutputToContactFieldMap.get(dbNode.getName()) : fieldNm;
            SObjectField fld = acctFields.get(fieldNm);
            fld = fld == null && String.isNotBlank(fieldNm) ? acctFields.get(fieldNm.toLowerCase()) : fld;
            fld = fld == null ? contFields.get(fieldNm) : fld;
            fld = fld == null && String.isNotBlank(fieldNm) ? contFields.get(fieldNm.toLowerCase()) : fld;
            if (dealerOutputToAccountFieldMap.containsKey(dbNode.getName())) acct.put(fieldNm, convertStringToType(fld, dbNode.getText()));
            if (dealerOutputToContactFieldMap.containsKey(dbNode.getName())) cont.put(fieldNm, convertStringToType(fld, dbNode.getText()));
        }
    }

    /**
     * @description     This function will process the D&B packet section
     * @see             SAL-2243
     *
     * @param xmlNodes  The xml child nodes of the D&B packet section
     */
    private void processDNBPacket(List<Dom.XmlNode> xmlNodes) {
        for (Dom.XmlNode dbNode : xmlNodes) {
            String nodeName = dbNode.getName();
            String fieldNm = dbNodeToAccountFieldMap.get(nodeName);
            SObjectField fld = acctFields.get(fieldNm);
            fld = fld == null && String.isNotBlank(fieldNm) ? acctFields.get(fieldNm.toLowerCase()) : fld;
            if (String.isNotBlank(nodeName) && dbNodeToAccountFieldMap.containsKey(nodeName)) {
                this.acct.put(fieldNm, convertStringToType(fld, dbNode.getText()));
            }
        }
    }

    private Object convertStringToType(SObjectField field, String strVal) {
        Object val = String.isBlank(strVal) ? null : strVal; // SAL-2846
        String fldType = String.valueOf(field.getDescribe().getType());

        //If the value is not null, need to cast the value of the field appropriately if needed
        if (val != null && fldType != null && FIELD_TYPES_TO_CAST.contains(fldType)) {
            if (fldType == 'DATE') val = Date.valueOf(strVal);
            if (fldType == 'DATETIME') val = Datetime.valueOfGmt(strVal.replace('T',' ').replace('Z',''));
            if (fldType == 'INTEGER') val = Integer.valueOf(strVal);
            if (fldType == 'BOOLEAN') val = Boolean.valueOf(strVal);
            if (DECIMAL_TYPES.contains(fldType)) val = Decimal.valueOf(strVal);
        }
        if (String.isNotBlank(strVal) && !FIELD_TYPES_TO_CAST.contains(fldType) && field.getDescribe().getLength() != null && strVal.length() > field.getDescribe().getLength()) val = strVal.left(field.getDescribe().getLength());

        return val;
    }

    private static Map<String, SObjectField> acctFields {
        get {
            if (acctFields == null) {
                acctFields = Account.getSObjectType().getDescribe().fields.getMap();
            }
            return acctFields;
        }
        set;
    }

    private static Map<String, SObjectField> contFields {
        get {
            if (contFields == null) {
                contFields = Contact.getSObjectType().getDescribe().fields.getMap();
            }
            return contFields;
        }
        set;
    }

    /**
     * @description This function will do the dealer info lease call out to obtain a dealer number
     * @see         SAL-2241
     */
    private void doDealerInfoLeaseCallout() {
        String requestStr;
        String responseStr;
        String message;
        try {
            System.debug('doDealerInfoLeaseCallOut');
            if (this.acct != null) {
                message = TC_BWcreateDealerCtrl.createDealer(this.recordId);
                requestStr = JSON.serializePretty(TC_BWcreateDealerCtrl.request);
                responseStr = JSON.serializePretty(TC_BWcreateDealerCtrl.response);
                system.debug('responseStr: ' + responseStr);
                this.acct = getAccount(this.recordId);

                if (String.isBlank(this.acct.Dealer_Number__c)) this.acct.Account_Dealer_Status__c = 'Pending';
                if (String.isBlank(this.acct.Dealer_Number__c)) this.acct.Business_Rules_Not_Met__c = message.containsIgnoreCase('duplicate') && message.containsIgnoreCase('phone number') ? 'Duplicate phone number' : message;
                if (String.isBlank(this.acct.Dealer_Number__c)) update this.acct;

                //Re-enqueueing the job after the info lease functionality has been run
                if (!Test.isRunningTest() && String.isNotBlank(this.acct.Dealer_Number__c)) System.enqueueJob(new TC_GDSDealerQueueable(this.recordId, Label.TC_GDS_Get_Dealer));
            }
        } catch (Exception e) {
            System.debug(e); message = e.getMessage()+':'+e.getStackTraceString();
        } finally {
            MARLIN_IntegrationLog.addLog('dealerInfoLeaseCallout',this.recordId, TC_BWcreateDealerCtrl.response?.Response?.Success, requestStr, responseStr, '200', message);
        }
        if (!MARLIN_IntegrationLog.logs.isEmpty()) MARLIN_IntegrationLog.insertLogs();
    }

    /**
     * @description     This function queries the account object
     *
     * @param acctId    The account id to query
     *
     * @return          The account
     */
    private Account getAccount(Id acctId) {
        return [
                SELECT  Id, Account_Dealer_Status__c, Dealer_Number__c, Reasons_Not_Scored__c, Account_Branch__c,
                        Equipment_Type__c, Assigned_to_DM_User__c, Approved_Reason__c, Rejected_Reason__c,
                        Date_Dealer_Approved_Most_Recent__c, RecordType.Name, DM_Review_Status__c, Review_For__c,
                        VPA__c, VPA_w_PD__c, VPA_w_CPC__c,VPA_w_FPD__c, VPA_w_Remittance__c, VPA_w_Capped_Residual__c, 
                        Sales_and_Assignment__c, Recommended_Decision__c, IF_Marlin_Score__c
                FROM    Account
                WHERE   Id = :acctId
        ];
    }


}