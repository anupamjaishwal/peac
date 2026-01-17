/**
 * Created by corycafferty on 2019-06-20.
 */

 public class TC_LGHTNPullGDSDealerDNB {

    static Map <String, String> nodeToAccountFieldMap;
    public static Contact cont;
    public static String request;
    public static String response;
    public static HttpRequest req;
    public static HttpResponse res;

    @auraEnabled
    public static ClientResponse pullDNB (Id recId) {

        // initialized out here to be used in the finally
        req = req == null ? new HttpRequest() : req;
        res = res == null ? new HttpResponse () : res;
        Http http = new Http();
        Account acc = new Account ();
        Boolean error = false;
        ClientResponse cr = new ClientResponse ();

        try {
            req.setEndpoint(Label.Dealer_Management_Endpoint);
            req.setMethod('POST');
			req.setHeader('Content-Type', 'text/xml');
			req.setTimeout (120000);
			req.setHeader ('charset','utf-8');
			req.setHeader('SOAPAction', 'http://dvtransaction.com/ProcessApplication');

            acc = [
                    SELECT  Id, Name, Business_Phone__c, Dealer_Number__c, Business_Address__c, Business_City__c,
                            Business_State__c, Business_Zip__c, Last_DataView_Pull_Date__c,Pre_Delivery__c,
                            Dealer_Service_Based__c, Account_Dealer_Program__c, Account_Bad_Inaccurate__c,
                            Percentage_of_Service__c, Equipment_Type__c, New_Dealer_Service_Based__c,
                            Review_For__c, IF_Credit_Requested_Amount__c, IF_Financial_Metrics__c,
                    (SELECT Id, ContactId FROM AccountContactRelations WHERE Roles IN ('Primary Contact') ORDER BY CreatedDate DESC LIMIT 1)
                    FROM    Account
                    WHERE   Id = :recId LIMIT 1][0];

            String bodyString = '';
            Boolean isInventoryFinance = acc.Review_For__c == 'Inventory Finance';

            nodeToAccountFieldMap = new Map <String, String> ();

            // CC-389: escape special characters in name
            String accName = TC_GdsScoreXmlUtil.handleNull(acc.Name);
            
            // SAL-2096: escape special characters in address
            String accAddr = TC_GdsScoreXmlUtil.handleNull(acc.Business_Address__c);
            
            // SAL-2846/2850 escape special characters in all field mappings that aren't escaped already
            nodeToAccountFieldMap.put('NAME', accName);
            nodeToAccountFieldMap.put('PHONE', TC_GdsScoreXmlUtil.handleNull(acc.Business_Phone__c));
            nodeToAccountFieldMap.put('DEALERNUMBER', TC_GdsScoreXmlUtil.handleNull(acc.Dealer_Number__c));
            nodeToAccountFieldMap.put('ADDRESS', accAddr);
            nodeToAccountFieldMap.put('CITY', TC_GdsScoreXmlUtil.handleNull(acc.Business_City__c));
            nodeToAccountFieldMap.put('STATE', TC_GdsScoreXmlUtil.handleNull(acc.Business_State__c));
            nodeToAccountFieldMap.put('ZIPCODE', TC_GdsScoreXmlUtil.handleNull(acc.Business_Zip__c));
            //SAL-2242 - new nodes
            nodeToAccountFieldMap.put('DEALER_PreDelivery_Ind', TC_GdsScoreXmlUtil.handleNull(acc.Pre_Delivery__c));
            nodeToAccountFieldMap.put('DEALER_ServiceType', TC_GdsScoreXmlUtil.handleNull(String.valueOf(acc.New_Dealer_Service_Based__c)));
            nodeToAccountFieldMap.put('DEALER_ProgramType', TC_GdsScoreXmlUtil.handleNull(acc.Account_Dealer_Program__c));
            nodeToAccountFieldMap.put('DEALER_BadInd', TC_GdsScoreXmlUtil.handleNull(acc.Account_Bad_Inaccurate__c));
            nodeToAccountFieldMap.put('DEALER_ServicePrct', TC_GdsScoreXmlUtil.handleNull(acc.Percentage_of_Service__c));
            nodeToAccountFieldMap.put('DEALER_EquipType', TC_GdsScoreXmlUtil.handleNull(acc.Equipment_Type__c));
            nodeToAccountFieldMap.put('LOAN_AMOUNT', TC_GdsScoreXmlUtil.handleNull(acc.IF_Credit_Requested_Amount__c));
            nodeToAccountFieldMap.put('IF_Financial_Metrics', TC_GdsScoreXmlUtil.handleNull(acc.IF_Financial_Metrics__c));
            if(isInventoryFinance){
                nodeToAccountFieldMap.put('Review_For', TC_GdsScoreXmlUtil.handleNull(acc.Review_For__c));
            }

            cont = getPrimaryContact(acc);
            nodeToAccountFieldMap.put('DEALER_Contact_FirstName', TC_GdsScoreXmlUtil.handleNull(cont.FirstName));
            nodeToAccountFieldMap.put('DEALER_Contact_LastName', TC_GdsScoreXmlUtil.handleNull(cont.LastName));
            nodeToAccountFieldMap.put('DEALER_Contact_Email', TC_GdsScoreXmlUtil.handleNull(cont.Email));
            nodeToAccountFieldMap.put('DEALER_VALIDITYVERIFY_RESULT', TC_GdsScoreXmlUtil.handleNull(cont.Validity_Verify__Status__c));
            nodeToAccountFieldMap.put('DEALER_FINALEMAILVALIDITY', TC_GdsScoreXmlUtil.handleNull(cont.Final_E_mail_Validity_Result__c));

            bodyString = '<APPLICATIONDATA>';
            if(isInventoryFinance){
                bodyString += '<CALLTYPE>DEALER_IF</CALLTYPE>';
            }else{
                bodyString += '<CALLTYPE>DEALER</CALLTYPE>';
            }
            bodyString += getNodeString('DEALERNUMBER');
            bodyString += '<DEALER>';
            bodyString += getNodeString('NAME');
            bodyString += getNodeString('ADDRESS');
            bodyString += getNodeString('CITY');
            bodyString += getNodeString('STATE');
            bodyString += getNodeString('ZIPCODE');
            bodyString += getNodeString('ZIPEXTENSION');
            bodyString += getNodeString('PHONE');
            bodyString += getNodeString('IDNUMBER');
            bodyString += getNodeString('DBDUNSNUMBER');
            bodyString += getNodeString('EBFILENUMBER');
            //SAL-2242 - Added new nodes
            bodyString += getNodeString('DEALER_PreDelivery_Ind');
            bodyString += getNodeString('DEALER_ServiceType');
            bodyString += getNodeString('DEALER_ProgramType');
            bodyString += getNodeString('DEALER_BadInd');
            bodyString += getNodeString('DEALER_ServicePrct');
            bodyString += getNodeString('DEALER_EquipType');
            bodyString += getNodeString('Review_For');
            bodyString += getNodeString('LOAN_AMOUNT');
            bodyString += getNodeString('IF_Financial_Metrics');
            bodyString += getNodeString('DEALER_Contact_FirstName');
            bodyString += getNodeString('DEALER_Contact_LastName');
            bodyString += getNodeString('DEALER_Contact_Email');
            bodyString += getNodeString('DEALER_VALIDITYVERIFY_RESULT');
            bodyString += getNodeString('DEALER_FINALEMAILVALIDITY');
            bodyString += '</DEALER>';
            bodyString += '<D1><LASTNAME /><FIRSTNAME /><SUFFIX /><ADDRESS /><CITY /><STATE /><ZIPCODE /><ZIPEXTENSION /><SSN /></D1><D2><LASTNAME /><FIRSTNAME /><SUFFIX /><ADDRESS /><CITY /><STATE /><ZIPCODE /><ZIPEXTENSION /><SSN /></D2>';
            bodyString += '</APPLICATIONDATA>';

            String escapedBodyString = bodyString.escapeHtml4 ();
			String soapEnv = '<?xml version="1.0" encoding="utf-8"?> <soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"> <soap12:Body> <ProcessApplication xmlns="http://dvtransaction.com/"> <XmlRequest>';

            soapEnv += escapedBodyString;
            soapEnv += '</XmlRequest> </ProcessApplication> </soap12:Body> </soap12:Envelope>';
            req.setBody(soapEnv);
            request = soapEnv.unescapeHtml4();
			req.setHeader('Content-Length', String.isEmpty (soapEnv) ? '0' : String.valueOf(soapEnv.length()));
            
            if (!Test.isRunningTest()){
                res = http.send(req);
            }
            response = Test.isRunningTest() && String.isNotBlank(response) ? response : res.getBody().unescapeHtml4();
            
            // if http codes out of success range and no body throw error

            Set <String> errorMessages = new Set <String> ();

            if ((299 >= res.getStatusCode() || res.getStatusCode() >= 200) && !String.isBlank (req.getBody())){

                // check error tags for error now

                String responseXML = '';
                cr.body = res.getBody();

                Dom.Document xmlDoc = new Dom.Document ();
        		xmlDoc.load (res.getBody());
                for (Dom.XMLNode envNode : xmlDoc.getRootElement().getChildren()) {
                    for (Dom.XmlNode bodyNode : envNode.getChildren()) {
                        for (Dom.XmlNode responseNode : bodyNode.getChildren()) {
                            if ('ProcessApplicationResult' == responseNode.getName()) {
                                responseXML = responseNode.getText();
                            }
                        }
                    }
                }
                //responseXML = [SELECT Body FROM StaticResource WHERE Name = 'gdsfailtest'][0].Body.toString ();
                if (!String.isBlank (responseXML)) {

                    Dom.Document resultDoc = new Dom.Document ();
        			resultDoc.load (responseXML);


                    for (Dom.XMLNode recordNode : resultDoc.getRootElement().getChildren()) {
                        if ('Error' == recordNode.getParent()?.getName() && recordNode.getText().toUpperCase() != 'N') errorMessages.add(recordNode.getText());
                        if ('Error' == recordNode.getName()) {
                            for (Dom.XmlNode errorNode : recordNode.getChildren()) {
                                if (errorNode.getName() != null && errorNode.getText().toUpperCase() != 'N') {
                                    errorMessages.add (errorNode.getName());
                                }
                            }
                        }
                    }

                } else {
                    errorMessages.add ('No XML response inside the SOAP envelope');
                    Marlin_IntegrationLog.LogException('Pull Dealer Credit', acc.Id,'Error', req.getBody().unescapeHtml4(), res.getBody(), res.getStatusCode()!= null ? String.valueOf (res.getStatusCode()) : null, res.getStatus().unescapeHtml4());//Log when error added by Toms
                }
            } else {
				errorMessages.add ('HTTP Code' + res.getStatusCode() + ' Status: ' + res.getStatus() + ' or no SOAP response');
            }

            if (!errorMessages.isEmpty()) {
                /*AuraHandledException ae = new AuraHandledException (String.valueOf (errorMessages));
                ae.setMessage (String.valueOf (errorMessages));
                throw ae;*/
                System.debug('Error Message Block');
                throw new JobSequenceException(String.join(new List<String>(errorMessages),','));
                
            } else {
                update new Account(Id=acc.Id, Last_DataView_Pull_Date__c=Datetime.now());
            }

            return cr;

        } catch (Exception e) {
            String message = 'Error: ';
            System.debug(e.getStackTraceString());
            message += e.getMessage () != null && e.getMessage ().contains ('{') ? String.valueOf (e.getMessage ()).replace('{','').replace('}','') : e.getMessage ();
            cr.status = 'Error';
            cr.message = message;
            error = true;
            String reqBody = req.getBody() ?? '';
            String resBody = res.getBody() ?? '';
            String resStatus =  res.getStatus() ?? '';
            Marlin_IntegrationLog.LogException('Pull Dealer Credit - Exception Error', acc.Id, error ? 'Error' : 'Success', reqBody.unescapeHtml4(), resBody.unescapeHtml4(), res.getStatusCode()!= null ? String.valueOf (res.getStatusCode()) : null, resStatus.unescapeHtml4());
            //Marlin_IntegrationLog.LogException('Pull Dealer Credit - Exception Error', acc.Id, error ? 'Error' : 'Success', req.getBody().unescapeHtml4(), req.getBody().unescapeHtml4(), res.getStatusCode()!= null ? String.valueOf (res.getStatusCode()) : null, res.getStatus().unescapeHtml4());
            return cr;
        } finally {
            String respStr = res.getBody();
            respStr = respStr != null ? respStr.left (131071) : '';
			// log request
            if (respStr== null){
            String reqBody = req.getBody() ?? ''; // use this to fix the error
            String resStatus =  res.getStatus() ?? '';
            Marlin_IntegrationLog.LogException('Pull Dealer Credit - Response Error', acc.Id, error ? 'Error' : 'Success', reqBody.unescapeHtml4(), respStr, res.getStatusCode()!= null ? String.valueOf (res.getStatusCode()) : null, resStatus.unescapeHtml4());
            // Marlin_IntegrationLog.LogException('Pull Dealer Credit - Response Error', acc.Id, error ? 'Error' : 'Success', req.getBody().unescapeHtml4(), respStr, res.getStatusCode()!= null ? String.valueOf (res.getStatusCode()) : null, res.getStatus().unescapeHtml4());
            }
        }
    }

    /**
     * @description This function will get the primary contact for the account
     * @see         SAL-2242
     * @param acct  The queried account
     *
     * @return      The contact based on the rules set forth in SAL-2242
     */
    private static Contact getPrimaryContact(Account acct) {
        Contact cont = new Contact();
        Id contId;
        if (acct != null) {
            SObject relationship = acct.AccountContactRelations != null && !acct.AccountContactRelations.isEmpty() ? acct.AccountContactRelations[0] : null;
            if (relationship == null && System.isBatch()) for (OpportunityContactRole ocr : [SELECT Id, ContactId FROM OpportunityContactRole WHERE Role IN ('Primary Contact') AND Contact.AccountId = :acct.Id ORDER BY CreatedDate DESC LIMIT 1]) relationship = ocr;
            if (relationship != null) contId = (Id) relationship.get('ContactId');
        }

        if (contId != null) {
            cont = [
                    SELECT Id, FirstName, LastName, Email, Final_E_mail_Validity_Result__c, Validity_Verify__Status__c
                    FROM Contact
                    WHERE Id = :contId
            ];
        }

        if (cont.Id == null) throw new AuraHandledException ('A primary contact is required before submitting a dealer for review!');

        return cont;
    }

    public class ClientResponse {
        @auraEnabled
        public String status = 'SUCCESS';
        @auraEnabled
        public String message = 'Requested successfully';
        @AuraEnabled
        public String body;

        public ClientResponse () {
        }
    }

    private static String getNodeString (String nodeName){

        if (nodeToAccountFieldMap.get(nodeName) == null){
            return '<' + nodeName + ' />';
        }else{
            return '<' + nodeName + '>' + nodeToAccountFieldMap.get(nodeName) + '</' + nodeName + '>';
        }
    }

}