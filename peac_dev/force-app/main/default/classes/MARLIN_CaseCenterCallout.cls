public class MARLIN_CaseCenterCallout {
 
/****************************************************************************************
* @Author       Huron Team
* @Date         Feb 15, 2018
* @Description  Case Center Callout service
*****************************************************************************************/
    
    @AuraEnabled    
    Public static String submitAppToCaseCenter(String OpptyId)
    {
        String Endpoint = System.Label.Case_Center_Endpoint;
        Integer Timeout = 120000;
        String returnStatus = '';
        String exceptionFlag = 'N';
        String applicationNumber = '';
        String infoMessage = '';  
        String ccNumber = '';   
        String strResponse = '';
        String requestMsg = '';  
        String faultCode = '';
        String faultString = '';
        string faultMessage = '';     
        
            //Create the callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint);
            req.setMethod('POST');
            
            try{   
                
                requestMsg = MARLIN_CaseCenterHelper.createRequestMsg(OpptyId); 
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
                system.debug('*****strResponse is' +strResponse);
             
                XmlStreamReader reader   = new XmlStreamReader(strResponse);
                
                String appStatus = '';
                String bankStatementStatus = '';
                
                // only pg1 and pg2 fields defined in jira
                // don't want to redo entire xml parser so continuing with the existing pattern
                String pg1EmailageResult = '';
                String pg2EmailageResult = '';
                String pg1EmailageOverride = '';
                String pg2EmailageOverride = '';
                String pg1EmailageDatetimeStamp = '';
                String pg2EmailageDatetimeStamp = '';
                
                while (reader.hasNext()) {         
                    if('APPLICATIONDATA_CC_CUSTOMERNUMBER' == reader.getLocalName())
                        ccNumber = MARLIN_RapportHelper.getValueFromTag(reader);
                    if('APPLICATIONDATA_INFOLEASENUMBER' == reader.getLocalName())
                        applicationNumber = MARLIN_RapportHelper.getValueFromTag(reader);                       
                    if('ErrorMessage' == reader.getLocalName())
                        faultMessage = MARLIN_RapportHelper.getValueFromTag(reader);
                    // newly added
                    if ('Application_Status__c' == reader.getLocalName()) appStatus = MARLIN_RapportHelper.getValueFromTag(reader);
                    if ('Bank_Statement_Status__c' == reader.getLocalName()) bankStatementStatus = MARLIN_RapportHelper.getValueFromTag(reader);
                    // 6/4/2020
                    if('PG1_Emailage_Result' == reader.getLocalName()) pg1EmailageResult = MARLIN_RapportHelper.getValueFromTag(reader);
                    if('PG2_Emailage_Result' == reader.getLocalName()) pg2EmailageResult = MARLIN_RapportHelper.getValueFromTag(reader);
                    //if('pg1EmailageOverride' == reader.getLocalName()) pg1EmailageOverride = MARLIN_RapportHelper.getValueFromTag(reader);
                    //if('pg2EmailageOverride' == reader.getLocalName()) pg2EmailageOverride = MARLIN_RapportHelper.getValueFromTag(reader);
                    if('PG1_Emailage_Timestamp' == reader.getLocalName()) pg1EmailageDatetimeStamp = MARLIN_RapportHelper.getValueFromTag(reader);
                    if('PG2_Emailage_Timestamp' == reader.getLocalName()) pg2EmailageDatetimeStamp = MARLIN_RapportHelper.getValueFromTag(reader);
                    reader.next();
                }//end of while     
                
                //returnStatus = applicationNumber + ':' + strResponse;
                
                
                Opportunity opty = new Opportunity();
                opty.id = OpptyId;
                opty.CaseCenter__c = applicationNumber;
               // opty.Application__c = ccNumber;
                opty.Application_Submitted__c = System.now();
                opty.Rapport_Submission_Time__c =  System.now();
                //          opty.CCAN__c = entRefNum;
                //          
                
                // newly added
                opty.Application_Status__c = appStatus;
                opty.Bank_Statement_Status__c = bankStatementStatus;
                
                if(opty <> null && applicationNumber != '')
                {
                    update opty;
                }
                
              List<Opportunity> op = [select Accountid, (Select Id ,Contact__c
                                 from Guarantor__r where Type__c = 'Personal Guarantor' 
                                 order by Contact__r.Ownership_Pct__c desc) from Opportunity where id =:OpptyId limit 1];
                if (op <> null && op.size() > 0)
                {
                    String accntid = op[0].Accountid;
                    Account acc = [select CCID__c from Account where id =: accntid limit 1];
                    if (acc.CCID__c == null)
                    {
                        Account upaccn = new Account();
                        upaccn.CCID__c = ccNumber;
                        upaccn.id = acc.id;
                        if(upaccn <> null)
                        {
                            update upaccn;
                        }
                    }
                    
                    // setting pg emailage fields 6/4/2020, only first 2
                    List <Contact> updateList = new List <Contact> ();
                    Map <Id, Boolean> conDupe = new Map <Id, Boolean> ();
                    
                    if (op[0].Guarantor__r.size() >= 1) {
                        conDupe.put (op[0].Guarantor__r[0].Contact__c, true);
                        updateList.add (new Contact (Id = op[0].Guarantor__r[0].Contact__c, Emailage_Result__c = pg1EmailageResult, Override_Emailage_Result__c = pg1EmailageOverride == '1' ? true :false,Emailage_Pull_Time_stamp__c  =  TC_DateTimeFormatter.gdsFormat(pg1EmailageDatetimeStamp)));
                    }
                    
                    if (op[0].Guarantor__r.size() >= 2) {
                        if (conDupe.get (op[0].Guarantor__r[1].Contact__c) == null) {
                            updateList.add (new Contact (Id = op[0].Guarantor__r[1].Contact__c, Emailage_Result__c = pg2EmailageResult, Override_Emailage_Result__c = pg2EmailageOverride == '2' ? true :false, Emailage_Pull_Time_stamp__c  = TC_DateTimeFormatter.gdsFormat(pg2EmailageDatetimeStamp)));
                        }
                        
                    }
                    
                    if (!updateList.isEmpty ()) {
                        update updateList;
                    }
                    
                }  
                System.debug ('!!!!! right before: MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase:OpptyId' + OpptyId);
                MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(OpptyId,false);
                // tam add ocrolus
                // platform event 10-9-2019
            	EventBus.publish (new TC_Ocrolus_Add_Book__e  (Opportunity_Id__c  = OpptyId));
                
            }       
            catch(Exception e){
                exceptionFlag = 'Y';
                returnStatus = e.getMessage();
                Marlin_IntegrationLog.LogException('CaseCenter API',OpptyId, 'Error', requestMsg, (strResponse.length() < 32000 ? strResponse : strResponse.substring(0, 31999)), '500',  'CC Number / App Number:' + applicationNumber + '/' + ccNumber + ', ' + e.getMessage() + ', ' + e.getStackTraceString());
            }  

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
        
        else if(applicationNumber == '' || ccNumber == '') 
            return  'Error Message: Fault Code: ' + faultCode + ', Fault String: ' + faultString + ', Message:' + faultMessage + ', Response Message: ' + strResponse;
        
        
        else
            Marlin_IntegrationLog.LogException('CaseCenter API',OpptyId, 'Success', requestMsg, (strResponse.length() < 100000 ? strResponse : strResponse.substring(0, 100000)), '200', 'OK');

            return  'Application Number: ' + applicationNumber + ', CC ID: ' + ccNumber;
        
        
    }
  
    
    @AuraEnabled    
    Public static String validateApplicationForSubmission(String OpptyId)
    {
        
        String lValidationResult = MARLIN_CaseCenterHelper.validateRequiredFields(OpptyId);
        // && QueryAndCreateGuarantors(OpptyId) == 'Success'
        
        if(lValidationResult == 'Success')
            return 'Success';
        else
            
            return lValidationResult;
    }   
 
    public static String submitUpdatedAppToCaseCenter(String aOptyId, String aAppNumber,Map<String,Map<String,String>> aDocIdToDocDetailsMap)
    {
        System.debug ('$$$$$ submitUpdatedAppToCaseCenter:');
        String Endpoint = System.Label.Case_Center_Endpoint;
        Integer Timeout = 120000;
        String returnStatus = '';
        String exceptionFlag = 'N';
        String applicationNumber = '';
        String infoMessage = '';  
        String ccNumber = '';   
        String strResponse = '';
        String requestMsg = '';  
        String faultCode = '';
        String faultString = '';
        string faultMessage = '';     
        
            //Create the callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint);
            req.setMethod('POST');
            
            try{   
                
                requestMsg = MARLIN_CaseCenterHelper.createUpdateAppMessage(aAppNumber,aDocIdToDocDetailsMap); 
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
                if(res.getStatusCode() != 200){
                    Marlin_IntegrationLog.LogException('CaseCenter Update API',aOptyId, 'Error', requestMsg, String.ValueOf(res.getStatusCode()), '500',  'Error');
                    return 'Status Code: ' + res.getStatusCode() + ', Status Message: ' + res.getStatus();
                }
                    
                
                String resStatus = res.getStatus();
                Integer resCode = res.getStatusCode();
                system.debug('resStatus- '+resStatus);
                system.debug('resCode- '+resCode);
                
                strResponse = res.getBody();
                system.debug('strResponse is' +strResponse);
                String appStatus = '';
                String bankStatementStatus = '';
             
                XmlStreamReader reader   = new XmlStreamReader(strResponse);
                
                while (reader.hasNext()) {         
                    if('APPLICATIONDATA_CC_CUSTOMERNUMBER' == reader.getLocalName())
                        ccNumber = MARLIN_RapportHelper.getValueFromTag(reader);
                    if('APPLICATIONDATA_INFOLEASENUMBER' == reader.getLocalName())
                        applicationNumber = MARLIN_RapportHelper.getValueFromTag(reader);                       
                    if('ErrorMessage' == reader.getLocalName())
                        faultMessage = MARLIN_RapportHelper.getValueFromTag(reader);       
                    //if ('Application_Status__c' == reader.getLocalName()) appStatus = MARLIN_RapportHelper.getValueFromTag(reader);
                    //if ('Bank_Statement_Status__c' == reader.getLocalName()) bankStatementStatus = MARLIN_RapportHelper.getValueFromTag(reader);
                    
                    reader.next();
                }//end of while     
                System.debug ('$$$$$ submitUpdatedAppToCaseCenter success:');
                
                //aOptyId
                //
                // newly added
                /*if (aOptyId != null) {
                    update new Opportunity (Id = aOptyId, Application_Status__c = appStatus, Bank_Statement_Status__c = bankStatementStatus);
                }*/
                
            }       
            catch(Exception e){
                System.debug ('$$$$$ submitUpdatedAppToCaseCenter failure:');
                exceptionFlag = 'Y';
                returnStatus = e.getMessage();
                Marlin_IntegrationLog.LogException('CaseCenter Update API',aOptyId, 'Error', requestMsg, (strResponse.length() < 32000 ? strResponse : strResponse.substring(0, 31999)), '500',  e.getMessage() + ', ' + e.getStackTraceString());
            }  

        if(exceptionFlag == 'Y') {
            return  'Error Message: Fault Code: ' + faultCode + ', Fault String: ' + faultString + ', Message:' + faultMessage + ', Exception Message: ' + returnStatus;
        }
        
        else
            Marlin_IntegrationLog.LogException('CaseCenter Update API',aOptyId, 'Success', requestMsg, (strResponse.length() < 100000 ? strResponse : strResponse.substring(0, 100000)), '200', 'OK');

            return  'Application Number: ' + applicationNumber + ', CC ID: ' + ccNumber;
        
        
    }

    @Future(Callout=true)
    public static void updateCaseCenterApplicationStatus(String aOptyId, String aAppNumber, String PKNumber) {
        System.debug ('$$$$$ updateCaseCenterApplicationStatus:');
        String Endpoint = System.Label.Case_Center_Endpoint;
        Integer Timeout = 120000;
        String returnStatus = '';
        String exceptionFlag = 'N';
        String applicationNumber = '';
        String infoMessage = '';
        String ccNumber = '';
        String strResponse = '';
        String requestMsg = '';
        String faultCode = '';
        String faultString = '';
        String faultMessage = '';

        //Create the callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml');
        req.setTimeout (120000);

        try {
            
            // check if only MTD attachments, if true don't send an update 4-13-2020
            // https://marlinbusiness.atlassian.net/browse/SAL-1136
            
            String likeMTD = '%' + Label.TC_MTDFileType + '%';
            
            List<Opportunity_Attachment__c> oppAtts = new List<Opportunity_Attachment__c>([SELECT Id,Type__c,
                Name, Sent_To_Ocrolus__c FROM Opportunity_Attachment__c WHERE Opportunity__c = :aOptyId AND Sent_To_Ocrolus__c = False AND (NOT Type__c LIKE :likeMTD)]);
			
            if (oppAtts.isEmpty ()) return; // if there's no attachments after filtering out mtd bank statements don't send an update


            if (PKNumber == null){
                requestMsg = MARLIN_CaseCenterHelper.createUpdateApplicationStatusMessage(aAppNumber);
            }else{
                requestMsg = MARLIN_CaseCenterHelper.createUpdatePKNumberMessage(aAppNumber,PKNumber);
            }
//

            requestMsg = requestMsg.replaceAll('>null<', '><');
            requestMsg = requestMsg.replaceAll('&', '&amp;');
            System.debug('requestMsg--' + requestMsg);

            req.setBody(requestMsg);

            //Set the timeout
            //req.setTimeout(Timeout);

            //Send the request
            Http h = new Http();
            HttpResponse res = h.send(req);

            strResponse = res.getBody();

            //Process the response
            if (res.getStatusCode() != 200) {
                MARLIN_IntegrationLog.LogException('CaseCenter Update API (Application Status/PK Number)', aOptyId, 'Error', requestMsg, String.ValueOf(res.getStatusCode()), '500', 'Error');
            } else {
                system.debug('strResponse is' +strResponse);
            }
        } catch (Exception e) {
            System.debug ('$$$$$ updateCaseCenterApplicationStatus failure:');
            exceptionFlag = 'Y';
            returnStatus = e.getMessage();
            MARLIN_IntegrationLog.LogException('CaseCenter Update API (Application Status/PK Number)', aOptyId, 'Error', requestMsg, (strResponse.length() < 32000 ? strResponse : strResponse.substring(0, 31999)), '500', e.getMessage() + ', ' + e.getStackTraceString());
        }

        if (exceptionFlag != 'Y') {
            MARLIN_IntegrationLog.LogException('CaseCenter Update API (Application Status/PK Number)', aOptyId, 'Success', requestMsg, (strResponse.length() < 100000 ? strResponse : strResponse.substring(0, 100000)), '200', 'OK');
        }


    }


}