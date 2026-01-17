public without sharing class MARLIN_RapportCallout {
    /****************************************************************************************
* @Author       Huron Team
* @Date         March 21, 2017
* @Description  Rapport Call
*****************************************************************************************/
 Public Static Map<String,String> lPhoneToCCANMap = new Map<String,String>();
     
    public class ValidateRPResponse
 {
     @AuraEnabled
     Public Map<String,String> MapPhoneToCCAN = new Map<String,String>();  
      @AuraEnabled
     Public String errorCode = '200';    
      @AuraEnabled
     Public String Status = 'OK';       
 }
       
    
    @AuraEnabled    
    Public static String generateApplicationNumber(String OpptyId, String dNumber, Map<String,String> aMapPhoneToCCAN)
    {
        System.debug('***DealerNumber---- '+dNumber);
        System.debug('****OpptyId-- '+OpptyId);
        System.debug('****aMapPhoneToCCAN-- '+aMapPhoneToCCAN);
        String Endpoint = System.Label.RapportEndpoint;
        Integer Timeout = 120000;
        String returnStatus = '';
        String exceptionFlag = 'N';
        String applicationNumber = '';
        String infoMessage = '';  
        String entRefNum = '';   
        String strResponse = '';
        String requestMsg = '';  
        String faultCode = '';
        String faultString = '';
        string faultMessage = '';
 
        if(dNumber != null){
            //Create the callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint);
            req.setMethod('POST');
            
            try{   
                
                String lValidationResult = QueryAndCreateGuarantors(OpptyId,'N');
                
                if(lValidationResult != 'Success')
                    return 'Error Message: One ore more guarantors do not exists in Rapport. Please try after 6 Seconds. If problem persists please contact support team';        
                
                
                requestMsg = MARLIN_RapportHelper.createRequestMsg(OpptyId,dNumber,aMapPhoneToCCAN); 
                //Remove null entries
                requestMsg = requestMsg.replaceAll('>null<','><');
                requestMsg = requestMsg.replaceAll('&','&amp;');
                system.debug('requestMsg-- '+requestMsg);
                
                req.setBody(requestMsg);
                
                //Set the timeout
                req.setTimeout(Timeout);
                
                //Send the request
                Http h = new Http();
                HttpResponse res = h.send(req);
                
                //Process the response
                if(res.getStatusCode() != 200)
                    return 'Status Coder: ' + res.getStatusCode() + ', Status Message: ' + res.getStatus();
                
                String resStatus = res.getStatus();
                Integer resCode = res.getStatusCode();
                system.debug('resStatus- '+resStatus);
                system.debug('resCode- '+resCode);
                
                strResponse = res.getBody();
                system.debug('strResponse is' +strResponse);
                strResponse = strResponse.replaceAll('&lt;','<'); 
                strResponse = strResponse.replaceAll('&gt;','>'); 
                //      strResponse = strResponse.replaceAll('\'','"'); 
                
                
                
                XmlStreamReader reader   = new XmlStreamReader(strResponse);
                
                while (reader.hasNext()) {         
                    if('ApplicationNumber' == reader.getLocalName())
                        applicationNumber = MARLIN_RapportHelper.getValueFromTag(reader);
                    if('InfoMsg' == reader.getLocalName())
                        infoMessage = MARLIN_RapportHelper.getValueFromTag(reader); 
                    if('EntReferenceNum' == reader.getLocalName())
                        entRefNum = MARLIN_RapportHelper.getValueFromTag(reader);   
                    if('faultcode' == reader.getLocalName())
                        faultCode = MARLIN_RapportHelper.getValueFromTag(reader);   
                    if('faultstring' == reader.getLocalName())
                        faultString = MARLIN_RapportHelper.getValueFromTag(reader); 
                    if('message' == reader.getLocalName())
                        faultMessage = MARLIN_RapportHelper.getValueFromTag(reader);                                                                    
                    
                    reader.next();
                }//end of while     
                
                //returnStatus = applicationNumber + ':' + strResponse;
                
                
                Opportunity opty = new Opportunity();
                opty.id = OpptyId;
                opty.Application__c = ApplicationNumber;
                opty.Rapport_Submission_Time__c =  System.now();
                //          opty.CCAN__c = entRefNum;
                if(opty <> null && ApplicationNumber != '')
                {
                    update opty;
                    MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase(OpptyId,False);
                }
                
                List<Opportunity> op = [select Accountid from Opportunity where id =:OpptyId limit 1];
                if (op <> null && op.size() > 0)
                {
                    String accntid = op[0].Accountid;
                    Account acc = [select CCAN__c from Account where id =: accntid limit 1];
                    if (acc.CCAN__c == null)
                    {
                        Account upaccn = new Account();
                        upaccn.CCAN__c = entRefNum;
                        upaccn.id = acc.id;
                        if(upaccn <> null)
                        {
                            update upaccn;
                        }
                    }
                }
                
                MARLIN_RapportHelper.updateCCANOfCG(OpptyId, aMapPhoneToCCAN);
            }       
            catch(Exception e){
                exceptionFlag = 'Y';
                //returnStatus = e.getMessage() + '=>>> ' + e.getStackTraceString() + '=>>> ' + OpptyId;
                returnStatus = e.getMessage();
                Marlin_IntegrationLog.LogException('Rapport API',OpptyId, 'Error', strResponse, strResponse, '500',  e.getMessage() + ', ' + e.getStackTraceString());
            }  
        }
        
        Marlin_IntegrationLog.LogException('Rapport API',OpptyId, 'Success', requestMsg, strResponse, '200', 'OK');
        
        
        if(exceptionFlag == 'Y') {
            if(returnStatus.contains('timed out')){
                Opportunity op = [select id, Rapport_Time_Out__c from Opportunity where id =:OpptyId];
                if(op != null){
                    op.Rapport_Time_Out__c = true;
                    update op;
                }
            }
            return  'Error Message: Fault Code: ' + faultCode + ', Fault String: ' + faultString + ', Message:' + faultMessage + ', Exception Message: ' + returnStatus;
        }
        
        else if(applicationNumber == '') 
            return  'Error Message: Fault Code: ' + faultCode + ', Fault String: ' + faultString + ', Message:' + faultMessage + ', Response Message: ' + strResponse;
        
        
        else
            //return DealerNumber;
            return  'Application Number: ' + applicationNumber + ', EntReferenceNum: ' + entRefNum + ', Info Message: ' + infoMessage;
        
        
    }
    
    //Nirosha Changes
    /************************************************/
    //Send Dealer data to Infolease
    /**************************************************/
    
    @AuraEnabled
    Public static String checkAccountType(String OpptyId, String accountType){
        
        String accType1 = '' ;
        String accType2 = '' ;
        String flgException = 'N';
        String lDealerNumber = '';
        Boolean firstFranchisor = True;
        Boolean firstBroker = True;
        String lContactName = '';
        //String lContactEmail = '';
        
        Map<String,String> lValidationCalloutMapDealer = new Map<String,String>();
        List<map<String,String>> lDealerMsgList = new List<map<String,String>>();
        //String lDealerMsgString = '';
        Map<String,String> lSFAccountIDToDNMap = new Map<String,String>();
        
        Opportunity oppQuery = [SELECT Id,Recordtype.DeveloperName ,RecordType.Name,Sales_Rep__c,Primary_Contact_Name__c,EQUIP_CODE__c,
                               Business_Phone__c, Owner.Profile.Name, (SELECT id,Primary_Dealer__c,name,Dealer__c,Dealer__r.Name, Dealer__r.Business_Address__c,  
                             Dealer__r.Business_City__c, Dealer__r.Business_State__c,Dealer__r.Dealer_Number__c, 
                             Dealer__r.Website, Dealer__R.Contact_Email__c,Dealer__r.Account_Dealer_Status__c,
                             Dealer__r.Program_Manager__c,Dealer__r.Program_Manager__r.Personnel_Number__c ,  Dealer__r.Business_Zip__c, Dealer__r.Business_Phone__c, 
                             Dealer__r.Account_Branch__c,Dealer__r.Account_Dealer_Group_Code__c, Dealer__r.Equipment_Type__c  FROM Brokers__r), 
                                (Select contact.Phone,contact.LastName,contact.name, contact.FirstName, contact.Email  
                             From OpportunityContactRoles where IsPrimary = true),
                                (SELECT id,name,Franchisor__c,Franchisor__r.Name, Franchisor__r.Business_Address__c,Franchisor__r.Website, 
                             Franchisor__r.Business_City__c, Franchisor__r.Business_State__c,Franchisor__r.Dealer_Number__c, 
                             Franchisor__r.Contact_Email__c,Franchisor__r.Business_Zip__c, Franchisor__r.Business_Phone__c, 
                             Franchisor__r.Account_Branch__c,Franchisor__r.Account_Dealer_Status__c, Franchisor__r.Program_Manager__c, 
                             Franchisor__r.Program_Manager__r.Personnel_Number__c, Franchisor__r.Account_Dealer_Group_Code__c, 
                                 Franchisor__r.Equipment_Type__c FROM Franchisors__r),
                                (SELECT id,name,Account__c,Account__r.Name, Account__r.Business_Address__c,Account__r.Website, 
                             Account__r.Business_City__c, Account__r.Business_State__c,Account__r.Dealer_Number__c, 
                             Account__r.Contact_Email__c,Account__r.Business_Zip__c, Account__r.Business_Phone__c, 
                             Account__r.Account_Branch__c,Account__r.Account_Dealer_Status__c, Account__r.Program_Manager__c, 
                             Account__r.Program_Manager__r.Personnel_Number__c, Account__r.Account_Dealer_Group_Code__c,
                                 Account__r.Equipment_Type__c FROM Brokers1__r) 
                                FROM Opportunity WHERE Id =: OpptyId ];
        
        lContactName = oppQuery.OpportunityContactRoles.size() == 0 ? '' : String.valueOf(oppQuery.OpportunityContactRoles[0].getSobject('Contact').get('Name'));
        
        for(Dealer__c deal : oppQuery.Brokers__r){
            
            System.debug('Dealer dealer number1'+deal.Dealer__r.Dealer_Number__c);
            if(deal.Dealer__r.Dealer_Number__c != null)
                continue;
            
            //System.debug('Dealer dealer number'+deal.Dealer__r.Dealer_Number__c);
            //
            System.debug ('$$$$$ sending dealer1');
            lValidationCalloutMapDealer = sendDealerData(deal,'Dealer',oppQuery.Sales_Rep__c,oppQuery.EQUIP_CODE__c); 
            
            if(lValidationCalloutMapDealer.get('STATUS') == 'OK'){ 
                lSFAccountIDToDNMap.Put(deal.Dealer__c, lValidationCalloutMapDealer.get('DEALERID'));
                lDealerMsgList.add(lValidationCalloutMapDealer);
                
                if(deal.Primary_Dealer__c == true){
                    System.debug('Primary Dealer'+ deal.Primary_Dealer__c+ 'dealer name ---->'+ deal.Dealer__r.Name);
                    lDealerNumber = lValidationCalloutMapDealer.get('DEALERID');
                }
                
                
                // MARLIN_RapportHelper.updateDealerNumberInAccount(deal.Dealer__c, lDealerNumber );
                
            }
            else{
                lDealerMsgList.add(lValidationCalloutMapDealer);
                flgException = 'Y';
                break;
            }    
            
            
        }
        
        System.Debug('RecordType:' + oppQuery.Recordtype.DeveloperName.contains('Franchise'));
        System.Debug('Franchisor Size:' + oppQuery.Franchisors__r.size());
        
        if(oppQuery.Recordtype.DeveloperName.contains('Franchise')){
            for(Franchisor__c fran : oppQuery.Franchisors__r){
                
                if(!String.IsBlank(fran.Franchisor__r.Dealer_Number__c)  && firstFranchisor == True){
                    lDealerNumber =   fran.Franchisor__r.Dealer_Number__c;
                    firstFranchisor = false;
                }
                
                if(fran.Franchisor__r.Dealer_Number__c == null){
                    System.debug('franchise dealer number'+fran.Franchisor__r.Dealer_Number__c);
                    if(flgException == 'Y') break;
                    lValidationCalloutMapDealer = sendDealerData(fran,'Franchisor',oppQuery.Sales_Rep__c,oppQuery.EQUIP_CODE__c); 
                    System.Debug('Call Dealer Response:' + lValidationCalloutMapDealer);
                    if(lValidationCalloutMapDealer.get('STATUS') == 'OK'){
                        lSFAccountIDToDNMap.Put(fran.Franchisor__c, lValidationCalloutMapDealer.get('DEALERID'));
                        lDealerMsgList.add(lValidationCalloutMapDealer);
                        if(firstFranchisor == True){
                            System.debug('First Franchisor'+firstFranchisor);
                            lDealerNumber =   lValidationCalloutMapDealer.get('DEALERID');
                            firstFranchisor = false;
                        }
                        
                        
                        // MARLIN_RapportHelper.updateDealerNumberInAccount(fran.Franchisor__c, lDealerNumber );                	
                    }                    
                    else{
                        lDealerMsgList.add(lValidationCalloutMapDealer);
                        flgException = 'Y';
                        break;
                    }
                }                
            }
        }
        // if IFP or (Wholesale or Retail and if brokers exist) 
        if(oppQuery.Recordtype.DeveloperName.contains('IFP') || oppQuery.Recordtype.DeveloperName.contains('Wholesale') || (oppQuery.Owner.Profile.Name.contains ('HC BD'))){
            for(Broker__c brok : oppQuery.Brokers1__r){
                
                if(!String.IsBlank(brok.Account__r.Dealer_Number__c)  && firstBroker == True){
                    lDealerNumber =   brok.Account__r.Dealer_Number__c;
                    firstBroker = false;
                }                
                
                if(brok.Account__r.Dealer_Number__c == null){
                    System.debug('Broker dealer number'+ brok.Account__r.Dealer_Number__c);
                    if(flgException == 'Y') break;
                    
                    System.debug ('$$$$$ sending broker1');
                    lValidationCalloutMapDealer = sendDealerData(brok,'IFP',oppQuery.Sales_Rep__c,oppQuery.EQUIP_CODE__c);  
                    if(lValidationCalloutMapDealer.get('STATUS') == 'OK'){ 
                        lSFAccountIDToDNMap.Put(brok.Account__c, lValidationCalloutMapDealer.get('DEALERID'));
                        lDealerMsgList.add(lValidationCalloutMapDealer);
                        if(firstBroker == True){
                            System.debug('First Broker'+firstBroker);
                            lDealerNumber =   lValidationCalloutMapDealer.get('DEALERID');
                            firstBroker = false;
                        }                    
                        
                        //MARLIN_RapportHelper.updateDealerNumberInAccount(brok.Account__c, lDealerNumber );                 	
                    }
                    else{
                        lDealerMsgList.add(lValidationCalloutMapDealer);
                        flgException = 'Y';
                        break;
                    }
                }               
            }
        }
        
        
        system.debug('lValidationCalloutMapDealer-- '+lValidationCalloutMapDealer);
        system.debug('lSFAccountIDToDNMap-- '+lSFAccountIDToDNMap);
        if(lSFAccountIDToDNMap.size() > 0){
            for(String key : lSFAccountIDToDNMap.KeySet()){
                MARLIN_RapportHelper.updateDealerNumberInAccount(key, lSFAccountIDToDNMap.Get(key) );
            }
        }
        if(lDealerMsgList.size() > 0){
            for(Map<String,String> str : lDealerMsgList){
                if(str.get('STATUS') == 'OK')
                	Marlin_IntegrationLog.LogException('Dealer API',OpptyId, 'Success', str.get('Request Msg'), 
                                                   str.get('Response Msg'), '200', 'OK');
                else
                    Marlin_IntegrationLog.LogException('Dealer API',OpptyId, 'Error', str.get('Request Msg'), 
                                                       str.get('Response Msg'), '500',  str.get('Exception') );
            }
        }
        
        
        if(flgException == 'N'){
            
            return lDealerNumber;  
        }
        else
            return 'ERROR: ' + lValidationCalloutMapDealer.get('STATUSMSG');
        
    }
    
    Public static Map<String,String> sendDealerData(sObject OpptyId, String accountType, String salesRep, String equipCode)
    {
        system.debug('accountType in send dealer data method-- '+accountType);
        String Endpoint = System.Label.MarlinNetEndpoint;
        Integer Timeout = 120000;
        String returnStatus = '';
        String exceptionFlag = 'N';
        String entRefNum = '';   
        String strResponse = '';
        String requestMsg = '';  
        String dealerNumber = '';
        String resBody = '';
        Map<String,String> lCalloutLog = new Map<String,String>();
        
        if(accountType.contains('Dealer'))
            requestMsg = MARLIN_RapportHelper.createRequestMsgDealer(OpptyId,salesRep); 
        else if(accountType.contains('Franchisor'))
            requestMsg = MARLIN_RapportHelper.createRequestMsgFranchisor(OpptyId,salesRep); 
        else if(accountType.contains('IFP')) 
            requestMsg = MARLIN_RapportHelper.createRequestMsgBroker(OpptyId,salesRep); 
        else{
            // do nothing
        }
        //
        //Create the callout
        HttpRequest req = new HttpRequest();
        HTTPResponse res;
        req.setEndpoint(Endpoint);
        req.setMethod('POST');
        
        
        system.debug('Dealer Request Message----- '+requestMsg);
        
        //requestMsg = '<?xml version="1.0" encoding="UTF-8"?><DealerData><DLRNumber>3179951212</DLRNumber><DLRBusinessName>MyDealerName</DLRBusinessName><DLRAddress1>101 South St.</DLRAddress1><DLRAddress2>101 South St.</DLRAddress2><DLRCity>DakotaPlains</DLRCity><DLRState>SD</DLRState><DLRZipcode>12345</DLRZipcode><DLRPhoneNumber>1234561234</DLRPhoneNumber><DLRContactName>George Dudgeon</DLRContactName><DLRWebURL>www.mydealername.com</DLRWebURL><DLREmailAddress>George@mydealername.com</DLREmailAddress><DLRSalesRepID>001234</DLRSalesRepID><DLRBranch>00200</DLRBranch><DLRType>D</DLRType><DLRStatus>Pending</DLRStatus><DLRReviewDate>08/21/2017</DLRReviewDate><DLRFollowUpDate>08/21/2018</DLRFollowUpDate><DLRFiscalYEMonth>1</DLRFiscalYEMonth><DLRStmtDate>08/21/2017</DLRStmtDate><DLRAuditExtent>Audited</DLRAuditExtent><DLREquipCode>0823</DLREquipCode><DLRMarketingRep>1234</DLRMarketingRep><DLRProgramMgr>123</DLRProgramMgr><DLRGroupCode>888</DLRGroupCode></DealerData>';
        //Remove null entries
        requestMsg = requestMsg.replaceAll('>null<','><');
        requestMsg = requestMsg.replaceAll('&','&amp;');
        
        
        req.setBody('xml='+EncodingUtil.urlEncode(requestMsg, 'UTF-8'));
        
        //Set the timeout
        req.setTimeout(Timeout);
        
        try{
            //Send the request
            Http h = new Http();
            res = h.send(req);  
            strResponse = String.valueOf(res);
            
            
            //Process the response
            
            if(res.getStatusCode() != 200){
                lCalloutLog.Put('STATUS', 'KO');
                lCalloutLog.Put('STATUSCODE', String.ValueOf(res.getStatusCode()));  
                lCalloutLog.put('Request Msg', requestMsg);
                lCalloutLog.Put('Response Msg', strResponse);
                //Marlin_IntegrationLog.LogException('Dealer API',OpptyId.id, 'Success', requestMsg, strResponse, '500',  'OK');
                return lCalloutLog;
                
            }else if(res.getStatusCode() == 200 && res.getBody().contains('Error')){
                lCalloutLog.Put('STATUS', 'KO');
                lCalloutLog.Put('STATUSCODE', String.ValueOf(res.getStatusCode())); 
                lCalloutLog.Put('STATUSMSG', res.getBody()); 
                lCalloutLog.put('Request Msg', requestMsg);
                lCalloutLog.Put('Response Msg', res.getBody());
                system.debug('res body-- '+res.getBody());
                //Marlin_IntegrationLog.LogException('Dealer API',OpptyId.id, 'Error', requestMsg, strResponse, '200', 'Error');
                return lCalloutLog; 
            }
            
            resBody = res.getBody();
            system.debug('response---- '+res);
            system.debug('response body--- '+ res.getBody());
            lCalloutLog.Put('STATUS', 'OK');
            lCalloutLog.Put('RES', resBody);
            lCalloutLog.Put('STATUSCODE', String.ValueOf(res.getStatusCode()));
            lCalloutLog.put('Request Msg', requestMsg);
            lCalloutLog.Put('Response Msg', res.getBody());
            Dom.Document docx = new Dom.Document();
            docx.load(resBody);
            
            dom.XmlNode xroot = docx.getrootelement(); 
            dom.XmlNode[] xrec = xroot.getchildelements(); 
            for (Dom.XMLNode child: xrec) //Loop Through Records
            {
                if(child.getName() == 'DEALERID')
                    dealerNumber = child.gettext();
            }
            dealerNumber = dealerNumber.substring(0, 10);
            lCalloutLog.Put('DEALERID', dealerNumber);  
            //Marlin_IntegrationLog.LogException('Dealer API',OpptyId.id, 'Success', requestMsg, strResponse, '200', 'OK');
            
        }catch(Exception e){
            exceptionFlag = 'Y';
            lCalloutLog.Put('STATUS', 'KO');
            lCalloutLog.put('Request Msg', requestMsg);
            lCalloutLog.Put('Response Msg', res.getBody());
            lCalloutLog.Put('Exception', e.getMessage());
            //returnStatus = e.getMessage() + '=>>> ' + e.getStackTraceString() + '=>>> ' + OpptyId;
            returnStatus = e.getMessage();
                 //Marlin_IntegrationLog.LogException('Dealer API',OpptyId.id, 'Error', requestMsg, strResponse, '500',  e.getMessage() );
        }  
        
        return lCalloutLog;  
    }
    
    
    /**************************************************/
    //To call Infolease Service aRequestMessage , String aIDValue
    /**************************************************/
    Public static Map<String,String> sendRPToInfolease(String aRequestMessage, String aIDValue)
    {
        
        String Endpoint = System.Label.InfoleaseEndpoint;
        Integer lTimeout = 60000;
        String lReturnStatus = '';
        String lExceptionFlag = 'N'; 
        String lResponseMessage = '';
        String lRequestMsg = '';  
        String lCCANID = '';
        String lStatusMessage = '';
        String lErrorMsg = '';    
        Map<String,String> lCalloutLog = new Map<String,String>();
        
        try{   
            
            lRequestMsg = aRequestMessage;
            lRequestMsg = lRequestMsg.replaceAll('>null<','><');
            //   lRequestMsg = lRequestMsg.replaceAll('&','&amp;');
            
            lCalloutLog.Put('REQ', lRequestMsg);
            System.debug('Request Message Infolease: ' + lRequestMsg);
            HttpRequest lReq = new HttpRequest();
            lReq.setEndpoint(Endpoint);
            lReq.setMethod('POST');         
            
            lReq.setBody('xml='+EncodingUtil.urlEncode(lRequestMsg, 'UTF-8'));     
            lReq.setTimeout(lTimeout);
            
            Http h = new Http();
            HttpResponse lRes = h.send(lReq);
            
            
            //Process the response
            if(lRes.getStatusCode() != 200){
                lCalloutLog.Put('STATUS', 'KO');
                lCalloutLog.Put('STATUSCODE', String.ValueOf(lRes.getStatusCode()));    
                return lCalloutLog;             
                //return 'Status Coder: ' + lRes.getStatusCode() + ', Status Message: ' + lRes.getStatus();             
            }
            
            
            lResponseMessage = lRes.getBody();
            system.debug('Response is: ' +lResponseMessage);
            
            lCalloutLog.Put('RES', lResponseMessage);
            lCalloutLog.Put('STATUSCODE', String.ValueOf(lRes.getStatusCode()));         
            
            XmlStreamReader lReader  = new XmlStreamReader(lResponseMessage);
            
            while (lReader.hasNext()) {        
                if('Status' == lReader.getLocalName())
                    lStatusMessage = MARLIN_RapportHelper.getValueFromTag(lReader);
                if('CCANID' == lReader.getLocalName())
                    lCCANID = MARLIN_RapportHelper.getValueFromTag(lReader);                        
                if('Error' == lReader.getLocalName())
                    lErrorMsg += MARLIN_RapportHelper.getValueFromTag(lReader) + ', ';                          
                lReader.next();
            }//end of while     
            
        }       
        catch(Exception e){
            lExceptionFlag = 'Y';
            lReturnStatus = e.getMessage(); // + '=>>> ' + e.getStackTraceString();
        }  
        
        lCalloutLog.Put('EXCEPTION', lExceptionFlag);
        lCalloutLog.Put('EXCEPTIONMSG', + 'Infolease Error: ' + lResponseMessage + ', ' + lReturnStatus);
        
        System.debug(lStatusMessage + ':' + lReturnStatus + ':' + lCCANID);
        
        if(lExceptionFlag == 'N' && (lStatusMessage == 'Updated') ){
            lCalloutLog.Put('STATUS', 'OK');
            lCCANID = lCCANID.replaceAll('\n','');
            lCalloutLog.Put('CCANID', lCCANID);	
        }
        else
            lCalloutLog.Put('STATUS', 'KO');
 
        return lCalloutLog; 
    }    
    
    
    /**************************************************/
    //To call Marlin Validation Service
    /**************************************************/
    Public static Map<String,String> validateGuarantorInRapport(String aCCAN)
    {
        
        String Endpoint = System.Label.RapportValidationEndpoint;
        Integer lTimeout = 60000;
        String lReturnStatus = '';
        String lExceptionFlag = 'N'; 
        String lResponseMessage = '';
        String lRequestMsg = '';  
        String lResponseCCANID = '';
        String lRequestCCANID = '';   
        HttpResponse lRes;
        Map<String,String> lCalloutLog = new Map<String,String>();
        
        if(String.IsBlank(aCCAN)){
            lCalloutLog.Put('STATUS', 'KO');
            return lCalloutLog;
        }   
        
        try{   
            
            lRequestMsg = MARLIN_RapportHelper.createRapportValidationMsg(aCCAN); 
            
            System.debug('Request Message Report PG Validation: ' + lRequestMsg);
            HttpRequest lReq = new HttpRequest();
            lReq.setEndpoint(Endpoint);
            lReq.setMethod('POST');         
            
            lReq.setBody(lRequestMsg);       
            lReq.setTimeout(lTimeout);
            
            lCalloutLog.Put('REQ', lRequestMsg);
            
            Http h = new Http();
            lRes = h.send(lReq);
            
            
            //Process the response
            if(lRes.getStatusCode() != 200){
                lCalloutLog.Put('STATUS', 'KO');
                lCalloutLog.Put('STATUSCODE', String.ValueOf(lRes.getStatusCode()));            
                return lCalloutLog;
            }
            
            //  return 'Status Coder: ' + lRes.getStatusCode() + ', Status Message: ' + lRes.getStatus();
            
            lResponseMessage = lRes.getBody();
            system.debug('Response is: ' +lResponseMessage);
            lCalloutLog.Put('RES', lResponseMessage);
            lCalloutLog.Put('STATUSCODE', String.ValueOf(lRes.getStatusCode()));
            
            XmlStreamReader lReader  = new XmlStreamReader(lResponseMessage);
            
            while (lReader.hasNext()) {        
                if('organizationReferenceNumber' == lReader.getLocalName())
                    lResponseCCANID = MARLIN_RapportHelper.getValueFromTag(lReader);                        
                
                lReader.next();
            }//end of while     
            
            //Marlin_IntegrationLog.LogException('Rapport Validation API',aCCAN, 'Success', lRequestMsg, lResponseMessage, '200', 'OK');                
            
        }       
        catch(Exception e){
            lExceptionFlag = 'Y';
            lReturnStatus = e.getMessage(); // + '=>>> ' + e.getStackTraceString();
            //Marlin_IntegrationLog.LogException('Rapport Validation API',aCCAN, 'Error', lRequestMsg, lResponseMessage, '500',  e.getMessage() + ', ' + e.getStackTraceString());            
        }  
        
        System.debug(lRequestCCANID + ':' + lReturnStatus + ':' + lResponseCCANID);
        
        
        lCalloutLog.Put('EXCEPTION', lExceptionFlag);
        lCalloutLog.Put('EXCEPTIONMSG', lReturnStatus);
        
        if(lExceptionFlag == 'N' && String.isBlank(lResponseCCANID)) 
            lCalloutLog.Put('STATUS', 'OK');
        else
            lCalloutLog.Put('STATUS', 'KO');
        
        return lCalloutLog;
    }       
    
    
    @AuraEnabled    
    Public static String validateApplicationForSubmission(String OpptyId)
    {
        
        String lValidationResult = MARLIN_RapportHelper.validateRequiredFields(OpptyId);
        // && QueryAndCreateGuarantors(OpptyId) == 'Success'
        
        if(lValidationResult == 'Success')
            return 'Success';
        else
            
            return lValidationResult;
    }   
    
    //Nirosha Changes
    @AuraEnabled    		
    Public static String validateDealerForSubmission(String OpptyId)		
    {		
        
        String lValidationResult = MARLIN_RapportHelper.validateDealer(OpptyId);		
        // && QueryAndCreateGuarantors(OpptyId) == 'Success'		
        
        if(lValidationResult == 'SUCCESS')		
            return 'SUCCESS';		
        else		
            return lValidationResult;		
    }  
    
 /*   
    @AuraEnabled    
    Public static String validatePGsInRapport(String OpptyId)
    {
        
        String lValidationResult = QueryAndCreateGuarantors(OpptyId,'Y');
        
        if(lValidationResult == 'Success')
            return 'Success';        
        else
            return lValidationResult;
        
    }       
    
    */
    
    @AuraEnabled    
    Public static ValidateRPResponse validatePGsInRapportNew(String OpptyId)
    {
        ValidateRPResponse vr = new ValidateRPResponse();
        String lValidationResult = QueryAndCreateGuarantors(OpptyId,'Y');
        
		vr.Status = lValidationResult; 
        vr.MapPhoneToCCAN = lPhoneToCCANMap;
    	return vr;
        
    }


    
    
    Public static String QueryAndCreateGuarantors(String OpptyId,String CreateFlag)
    {
        
        Guarantor__c lGuarantor = New Guarantor__c();  
        Integer lGrtCount = 0;    
        String lValidateGurntResult = 'Success';    
        Map<String,Map<String,String>> lInfoleaseCalloutMaps = new  Map<String,Map<String,String>>(); 
        
        Opportunity optyList = [select id,RecordType.Name,Purchase_Options__c,UD_TIMERECEIVED__c,Primary_Contact_Email__c,Primary_Contact_Fax__c,
                                Primary_Contact_Name__c, Primary_Contact_Phone__c, Equipment_Description__c,Sales_Comments__c,
                                UD_DEALER_STATUS__c,UD_DECISION_INELIGIBLE__c, Payment_Amount__c,
                                Approved_Amount__c,Sales_Rep__c,
                                Equipment_Cost__c,Branch__c,Terms__c,Sec_Dep_Pymts__c,of_Payments__c,
                                UD_DATERECEIVED__c,UD_DLR_ENTERED_APP__c,Payment_Frequency__c,
                                Account.Name, Account.DBA__c,Account.Business_Type__c,
                                Account.Line_of_Business__c,Account.Business_Address__c,Account.Business_City__c,
                                Account.Business_State__c,Account.Business_Zip__c,Account.Business_Phone__c,
                                Application__c,Account.BILLINGSTREET,Account.BILLINGCity,Account.BillingStateCode,
                                Account.BillingPostalCode, Account.Tax_ID__c,Account.NumberOfEmployees,
                                Years_in_Business__c,Account.CCAN__c, (SELECT Name,Cost__c,Description__c,
                                                                       Equipment_City__c, Equipment_Code__c,Equipment_State__c,Equipment_Sub_Category__c ,
                                                                       Equipment_Street__c, Equipment_Zip__c,Quantity__c, Opportunity__c FROM Assets__r),
                                (SELECT id,name,Dealer__c,Dealer__r.Name, Dealer__r.Business_Address__c, 
                                 Dealer__r.Business_City__c, Dealer__r.Business_State__c,Dealer__r.Dealer_Number__c, 
                                 Dealer__r.Business_Zip__c,Dealer__r.Business_Phone__c,Dealer__r.Tax_ID__c 
                                 FROM Brokers__r),
                                (SELECT id,name,Account__c,Account__r.Name,Account__r.Tax_ID__c, Account__r.Business_Address__c, 
                                 Account__r.Business_City__c, Account__r.Business_State__c,Account__r.Dealer_Number__c, 
                                 Account__r.Business_Zip__c, Account__r.Account_Branch__c,Account__r.Business_Phone__c,Account__r.Account_Dealer_Status__c 
                                 FROM Brokers1__r Limit 1),
                                (Select Id,Contact__c,Account__c,Type__c,RP_PRIN_GUAR_CODE__c,
                                 Contact__r.FirstName, Contact__r.LastName, Contact__r.Name, 
                                 Contact__r.SSN__c,Contact__r.Phone, Contact__r.MailingStreet, 
                                 Contact__r.MailingCity,Contact__r.MailingStateCode, Contact__r.MailingPostalCode,
                                 Account__r.Name, Account__r.Id, Account__r.Primary_Contact__c,
                                 Account__r.Business_Address__c,Account__r.Business_City__c,
                                 Account__r.Business_State__c, Account__r.Business_Zip__c,
                                 Account__r.Business_Phone__c,Account__r.Tax_ID__c,
                                 Billing_Street__c, Billing_City__c, Billing_State__c,
                                 Billing_Country__c, Billing_ZipCode__c, Business_Phone__c,
                                 Account__r.Primary_Contact__r.FirstName, Account__r.Primary_Contact__r.LastName,
                                 Account__r.Primary_Contact__r.Phone  
                                 from Guarantor__r) 
                                from Opportunity where Id =:OpptyId ];
        
        
        System.debug('Rapport Guarantors: ' + optyList.Guarantor__r);
        lGrtCount = optyList.Guarantor__r.size();
        //!optyList.RecordType.Name.Contains('Franchise') && 
        if(lGrtCount > 0){
            lValidateGurntResult = MARLIN_RapportHelper.ValidateAndCreateGuarantors(OpptyId,optyList.Guarantor__r,CreateFlag,lInfoleaseCalloutMaps);         
            System.Debug('Guarantor Validation Call:- Size:' + lGrtCount + ', Result:-' + lValidateGurntResult);  
            if(lValidateGurntResult != 'Success')  
                return lValidateGurntResult;  
            else{
                for(string key : lInfoleaseCalloutMaps.keySet() ){
                    lPhoneToCCANMap.Put(key,lInfoleaseCalloutMaps.Get(key).Get('CCANID'));
                }
            }
        }       
        
        System.Debug('VVVV:' + CreateFlag + ':' + optyList.RecordType.Name + ':' + optyList.Brokers__r.size());
        if(CreateFlag == 'Y' && (optyList.RecordType.Name.Contains('Franchise') || optyList.RecordType.Name.Contains('IFP')) && optyList.Brokers__r.size() > 0){
            lValidateGurntResult = MARLIN_RapportHelper.ValidateAndCreateRelatedParty(OpptyId,optyList.RecordType.Name,optyList.Brokers__r,CreateFlag);           
            System.Debug('Franchisor Related Party Validation Call:- Size:' + optyList.Brokers__r.size() + ', Result:-' + lValidateGurntResult);                    
        }   
        
        return lValidateGurntResult;
    } 
    
    // We no longer submit to rapport. Rapport decommission feb 14 2020
    @future(callout=true)    
    Public static void updateApplicationInRapportAsync(String aOpptyId,String aObjectId, String aFieldsList, String aObjectName)
    {/*
        System.Debug('Update Call: Object Name:' + aObjectName);
        String lReqMessage = '';
        if(aObjectName == 'Opportunity')
            lReqMessage = MARLIN_RapportHelper.createUpdateApplicationMsg(aOpptyId,aFieldsList,aObjectName); 
        else if(aObjectName == 'Asset__c')
            lReqMessage = MARLIN_RapportHelper.createUpdateApplicationAssetMsg(aObjectId,aFieldsList);
        
        if(!String.IsBlank(lReqMessage))
            updateApplicationInRapport(aOpptyId,lReqMessage,True);
        */
    }
    
    
    //   @future(callout=true)    
    Public static void updateApplicationInRapport(String aOpptyId,String aReqMessage, Boolean aLogRequest)
    {
        
        String Endpoint = System.Label.RapportEndpoint;
        Integer Timeout = 120000;
        String returnStatus = '';
        String exceptionFlag = 'N';
        String infoMessage = '';   
        String strResponse = '';
        String reqMessage = '';  
        String faultCode = '';
        String faultString = '';
        string faultMessage = ''; 
        String lApplicationNumber = '';
        
        
        //Create the callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Endpoint);
        req.setMethod('POST');
        
        try{   
            
            reqMessage = aReqMessage; 
            
            if(String.IsBlank(reqMessage)){
                System.Debug('Request message is empty');
                return;
            }
            
            
            //Remove null entries
            reqMessage = reqMessage.replaceAll('>null<','><');
            system.debug('reqMessage is in callout' +reqMessage);
            req.setBody(reqMessage);
            
            //Set the timeout
            req.setTimeout(Timeout);
            
            //Send the request
            Http h = new Http();
            HttpResponse res = h.send(req);
            
            System.Debug(res);
            
            //Process the response
            
            strResponse = res.getBody();
            strResponse = strResponse.replaceAll('&lt;','<'); 
            strResponse = strResponse.replaceAll('&gt;','>'); 
            system.debug('strResponse is' +strResponse);
            
            XmlStreamReader reader   = new XmlStreamReader(strResponse);
            
            while (reader.hasNext()) {         
                if('ApplicationNumber' == reader.getLocalName())
                    lApplicationNumber = MARLIN_RapportHelper.getValueFromTag(reader);                                                              
                
                reader.next();
            }//end of while 
            
            System.Debug('Applicaiton Number in Response:' + lApplicationNumber);   
            
        } catch(exception e)
        {
            system.debug('Exception is' +e.getMessage());
            exceptionFlag = 'Y';
            returnStatus = e.getMessage() + '=>>> ' + e.getStackTraceString() + '=>>> ' + aOpptyId;
            
        }
        
        if(String.isBlank(lApplicationNumber) || exceptionFlag == 'Y'){
            returnStatus = 'Exception';
            if(aLogRequest == True)
                Marlin_IntegrationLog.LogException('Rapport Update API',aOpptyId, 'Error', strResponse, strResponse, '500',  returnStatus);
        }
        
        else{
            returnStatus = 'Success';
            if(aLogRequest == True)
                Marlin_IntegrationLog.LogException('Rapport Update API',aOpptyId, 'Success', reqMessage, strResponse, '200', 'OK');
        }
        
        
        // return returnStatus;      
    }
    @auraEnabled
    public static void callGdsScoreApex (Id recordId) {
        TC_GdsScoreApi.runGdsScoreFromTriggeredAction (new Set <Id> {recordId});
    }
    
 /*   
    Public static void updateOnBaseInfoInRapport(String aOpptyId, String aOpptyAttId,Integer aSeqNum)
    {
        
        String lReqMessage = '';        
        try{   
            
            Opportunity_Attachment__c lAtt = [select id,Attachment__c,Name,Document_URL__c,Description__c,
                                              Opportunity__r.Application__c 
                                              from Opportunity_Attachment__c 
                                              where Id = :aOpptyAttId];
            
            
            //lReqMessage =  MARLIN_RapportHelper.createUpdateApplicationDocumentMsg(lAtt.Opportunity__r.Application__c,'UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum),lAtt.Document_URL__c);
            //updateApplicationInRapport(aOpptyId,lReqMessage,False);
            
            //lReqMessage =  MARLIN_RapportHelper.createUpdateApplicationDocumentMsg(lAtt.Opportunity__r.Application__c,'UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '_FILENAME',lAtt.Name);
            //updateApplicationInRapport(aOpptyId,lReqMessage,False);  
            
            //lReqMessage =  MARLIN_RapportHelper.createUpdateApplicationDocumentMsg(lAtt.Opportunity__r.Application__c,'UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '_DESC',lAtt.Name);
            //updateApplicationInRapport(aOpptyId,lReqMessage,False);                   
            
            
            
        } catch(exception e)
        {
            system.debug('Exception is' +e.getMessage());
            
            
        }
        
        
    }
    */
}