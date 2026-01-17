/**
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 11/23/2015
* @description: Class for ASPIRE API integration to send requests.
*
* © Copyright 2003 - 2015 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

global class TC_ASPIREAPI {
    public class APIException extends Exception {}
    
    webService static String sendToASPIRE(String opportunityId) {
        
        Opportunity opp = [SELECT ID, Credit_Stips_Completed_Date__c, Funding_Booking_Loan_Completed_Date__c FROM Opportunity WHERE Id = :opportunityId][0];
        if (opp.Credit_Stips_Completed_Date__c == null) throw new APIException (Label.TC_ASPIRE_Error_Credit_Stips_Uncompleted );
        if (opp.Funding_Booking_Loan_Completed_Date__c == null) throw new APIException (Label.TC_Funding_Booking_Checklist_Required );
        
        String error = '';
        Blob b = Crypto.GenerateAESKey(128);
        String token = null;//EncodingUtil.ConvertToHex(b).right(16);
        List<TC_ASPIRE__Contract__c> contracts;
        TC_ASPIRE__API_Setting__mdt settings = [SELECT TC_ASPIRE__Server__c, TC_ASPIRE__API__c, TC_ASPIRE__Version__c,
                                                TC_ASPIRE__Authorization__c, TC_ASPIRE__Content_Type__c, TC_ASPIRE__Accept__c,
                                                TC_ASPIRE__Output_Debug__c, TC_ASPIRE__Days_of_History__c, TC_ASPIRE__Certificate_Name__c
                                                FROM TC_ASPIRE__API_Setting__mdt
                                                WHERE MasterLabel = 'Default'];
        
        try {
            Map<String, Object> objectMap = TC_ASPIREDataUtility.selectASPIREObjectData(opportunityId);
            String json;
            //TC_ASPIRE.API.beginTransaction(token, settings);

            List<TC_ASPIRE__Account__c> accounts = (List<TC_ASPIRE__Account__c>) objectMap.get('accounts');
            if (accounts != null) {
                for (TC_ASPIRE__Account__c account : accounts) {
                    TC_ASPIRE.ASPIREAccount accountObject = new TC_ASPIRE.ASPIREAccount(account.Id);
                    json = accountObject.generateJSON();
                    Map<String, Object> jsonMap = (Map<String, Object>) System.JSON.deserializeUntyped(json);
                    jsonMap.remove('LocationRecordId');
                    jsonMap.remove('BillToLocationRecordId');
                    json = System.JSON.serialize(jsonMap);
                    System.debug('Account Object JSON: ' + json);
                    try {
                        TC_ASPIRE.API.APICall('GET', '/account/' + ((TC_Aspire__Account__c) accountObject.record).TC_Aspire__RecordId__c + '/record', '', token, settings, account.Id);
                        System.debug('Updating Account Object JSON: ' + json);
                        TC_ASPIRE.API.APICall('PUT', '/account', json, token, settings, account.Id);
                    }
                    catch (TC_ASPIRE.API.APIException e) {
                        if (e.getMessage().startsWith('HTTP Status Code 404: Not Found') || e.getMessage().startsWith('HTTP Status Code 400: Bad Request')) {
                            System.debug('Sending Account Object JSON: ' + json);
                            TC_ASPIRE.API.APICall('POST', '/account', json, token, settings, account.Id);
                        }
                    }
                }
            }
            
            List<TC_ASPIRE__Location__c> locations = (List<TC_ASPIRE__Location__c>) objectMap.get('locations');
            if (locations != null) {
                for (TC_ASPIRE__Location__c location : locations) {
                    TC_ASPIRE.ASPIREObject locationObject = new TC_ASPIRE.ASPIREObject('TC_ASPIRE__Location__c', location.Id);
                    json = locationObject.generateJSON();
                    System.debug('Location Object JSON: ' + json);
                    try {
                        TC_ASPIRE.API.APICall('GET', '/location/' + ((TC_Aspire__Location__c) locationObject.record).TC_Aspire__RecordId__c + '/record', '', token, settings, location.Id);
                        System.debug('Updating Location Object JSON: ' + json);
                        TC_ASPIRE.API.APICall('PUT', '/location', json, token, settings, location.Id);
                    }
                    catch (TC_ASPIRE.API.APIException e) {
                        if (e.getMessage().startsWith('HTTP Status Code 404: Not Found')) {
                            System.debug('Sending Location Object JSON: ' + json);
                            TC_ASPIRE.API.APICall('POST', '/location', json, token, settings, location.Id);
                        }
                    }
                }
            }
   
            if (accounts != null) {
                for (TC_ASPIRE__Account__c account : accounts) {
                    TC_ASPIRE.ASPIREAccount accountObject = new TC_ASPIRE.ASPIREAccount(account.Id);
                    json = accountObject.generateJSON();
                    System.debug('Account Object JSON: ' + json);
                    try {
                        TC_ASPIRE.API.APICall('GET', '/account/' + ((TC_Aspire__Account__c) accountObject.record).TC_Aspire__RecordId__c + '/record', '', token, settings, account.Id);
                        System.debug('Updating Account Object JSON: ' + json);
                        TC_ASPIRE.API.APICall('PUT', '/account', json, token, settings, account.Id);
                    }
                    catch (TC_ASPIRE.API.APIException e) {
                        if (e.getMessage().startsWith('HTTP Status Code 404: Not Found') || e.getMessage().startsWith('HTTP Status Code 400: Bad Request')) {
                            System.debug('Sending Account Object JSON: ' + json);
                            TC_ASPIRE.API.APICall('POST', '/account', json, token, settings, account.Id);
                        }
                    }
                }
            }
            
            //TC_ASPIRE.API.commitTransaction(token, settings);
            token = null;
            
            List<TC_ASPIRE__Bank__c> banks = (List<TC_ASPIRE__Bank__c>) objectMap.get('banks');
            if (banks != null) {
                for (TC_ASPIRE__Bank__c bank : banks) {
                    TC_ASPIRE.ASPIREObject bankObject = new TC_ASPIRE.ASPIREObject('TC_ASPIRE__Bank__c', bank.Id);
                    json = bankObject.generateJSON();
                    System.debug('Bank Object JSON: ' + json);
                    TC_ASPIRE.API.APICall('POST', '/account/banks', json, token, settings, bank.Id);
                }
            }
            
            List<TC_ASPIRE__Bank_Account__c> bankAccounts = (List<TC_ASPIRE__Bank_Account__c>) objectMap.get('bankAccounts');
            if (bankAccounts != null) {
                json = '';
                for (TC_ASPIRE__Bank_Account__c bankAccount : bankAccounts) {
                    TC_ASPIRE.ASPIREObject bankAccountObject = new TC_ASPIRE.ASPIREObject('TC_ASPIRE__Bank_Account__c', bankAccount.Id);
                    json += bankAccountObject.generateJSON() + ',';
                }
                
                if (String.isNotEmpty(json)) {
                    json = '[' + json.substring(0, json.length() - 1) + ']';
                    System.debug('Bank Account Object JSON: ' + json);
                    TC_ASPIRE.API.APICall('POST', '/account/banks/accounts', json, token, settings, bankAccounts[0].Id);
                }
            }
            /*
            List<TC_ASPIRE__Asset__c> assets = (List<TC_ASPIRE__Asset__c>) objectMap.get('assets');
            if (assets != null) {
                for (TC_ASPIRE__Asset__c asset : assets) {
                    TC_ASPIRE.ASPIREAsset assetObject = new TC_ASPIRE.ASPIREAsset(asset.Id);
                    json = '[' + assetObject.generateJSON() + ']';
                    System.debug('Asset Object JSON: ' + json);
                    try {
                        TC_ASPIRE.API.APICall('GET', '/assets/' + ((TC_ASPIRE__Asset__c) assetObject.record).TC_Aspire__RecordId__c + '/record', '', token, settings, asset.Id);
                        System.debug('Updating Asset Object JSON: ' + json);
                        TC_ASPIRE.API.APICall('PUT', '/assets', json, token, settings, asset.Id);
                    }
                    catch (TC_ASPIRE.API.APIException e) {
                        if (e.getMessage().startsWith('HTTP Status Code 404: Not Found') || e.getMessage().startsWith('HTTP Status Code 400: Bad Request')) {
                            System.debug('Sending Asset Object JSON: ' + json);
                            TC_ASPIRE.API.APICall('POST', '/assets', json, token, settings, asset.Id);
                        }
                    }
                }
            }
            */
            String contractRecordId = '';
            contracts = (List<TC_ASPIRE__Contract__c>) objectMap.get('contracts');
            if (contracts != null) {
                for (TC_ASPIRE__Contract__c contract : contracts) {
                    TC_ASPIRE.ASPIREContract contractObject = new TC_ASPIRE.ASPIREContract(contract.Id);
                    contractRecordId = ((TC_ASPIRE__Contract__c) contractObject.record).TC_Aspire__RecordId__c;
                    json = contractObject.generateJSON();
                    System.debug('Contract Object JSON: ' + json);
                    try {
                        TC_ASPIRE.API.APICall('GET', '/contract/' + ((TC_ASPIRE__Contract__c) contractObject.record).TC_Aspire__RecordId__c + '/record', '', token, settings, contract.Id);
                        System.debug('Updating Contract Object JSON: ' + json);
                        TC_ASPIRE.API.APICall('PUT', '/contract', json, token, settings, contract.Id);
                    }
                    catch (TC_ASPIRE.API.APIException e) {
                        if (e.getMessage().startsWith('HTTP Status Code 404: Not Found') || e.getMessage().startsWith('HTTP Status Code 400: Bad Request')) {
                            System.debug('Sending Contract Object JSON: ' + json);
                            TC_ASPIRE.API.APICall('POST', '/contract', json, token, settings, contract.Id);
                        }
                    }
                }
            }
            /*
            List<TC_ASPIRE__ContractAsset__c> contractAssets = (List<TC_ASPIRE__ContractAsset__c>) objectMap.get('contractAssets');
            if (contractAssets != null) {
                json = '';
                for (TC_ASPIRE__ContractAsset__c contractAsset : contractAssets) {
                    TC_ASPIRE.ASPIREContractAsset contractAssetObject = new TC_ASPIRE.ASPIREContractAsset(contractAsset.Id);
                    //TC_ASPIRE.API.APICall('POST', '/contract/asset', contractAssetObject.generateJSON(), token, settings, contractAsset.Id);
                    json += contractAssetObject.generateJSON() + ',';
                }
                
                if (String.isNotEmpty(json)) {
                    json = '[' + json.substring(0, json.length() - 1) + ']';
                    System.debug('ContractAsset Resource: ' + '/contract/' + contractRecordId + '/record/assets');
                    System.debug('ContractAsset Object JSON: ' + json);
                    TC_ASPIRE.API.APICall('POST', '/contract/' + contractRecordId + '/record/assets', json, token, settings, contractAssets[0].Id);
                }
            }
            */
            if (contracts != null) {
                for (TC_ASPIRE__Contract__c contract : contracts) {
                    contract.TC_ASPIRE__APICallStatus__c = 'Successful';
                }
                
                update contracts;
            }

            List<Opportunity> opportunities = [Select Id, Selected_Approved_Offer__r.Offer_Amount__c From Opportunity Where Id =: opportunityId];
            
            if (opportunities.size() > 0) {
                Opportunity opportunitytoSend = opportunities[0];
                //opportunitytoSend.StageName = 'Booked';
                //opportunitytoSend.Opportunity_Booked_Date__c = System.now();
                //SAL-3386 added booked update here so case center gets called
                opportunitytoSend.Application_Status__c = 'Booked';
                opportunitytoSend.Booked_Amount__c = opportunitytoSend.Selected_Approved_Offer__r.Offer_Amount__c;
                opportunitytoSend.Booked_to_External_System_Date__c = System.now();
                opportunitytoSend.Booked_to_External_System_User__c = System.UserInfo.getUserId();
                update opportunitytoSend;
            }
        }
        catch (APIException e) {
            error = handleAPIException(e, contracts);
        }
        catch (Exception e) {
            error = handleException(e, contracts, token, settings);
        }
        
        List<Integration_Log__c> integrationLogList = new List<Integration_Log__c>();
        
        for (TC_ASPIRE__CalloutHistory__c calloutHistory : TC_ASPIRE.API.calloutHistoryList) {
                integrationLogList.add(new Integration_Log__c(
                    Name = 'ASPIRE Booking Request',
                    Record_Id__c = opportunityId,
                    Status__c = (calloutHistory.TC_ASPIRE__Response__c.contains('200') || calloutHistory.TC_ASPIRE__Response__c.contains('404') ? 'Success' : 'Error'),
                    Error_Code__c = calloutHistory.TC_ASPIRE__Response__c,
                    Error_Message__c = calloutHistory.TC_ASPIRE__Response__c,
                    Request_Message__c = calloutHistory.TC_ASPIRE__Request_Body__c,
                    Response_Message__c= calloutHistory.TC_ASPIRE__Response_Body__c
                ));
        }
        
        if (!integrationLogList .isEmpty())
            insert integrationLogList;
        
        TC_ASPIRE.API.updateCalloutHistory(settings);
        return error;
    }
    
    public static String handleAPIException(APIException e, List<TC_ASPIRE__Contract__c> contracts) {
        String error = e.getMessage();
        
        if (contracts != null) {
            for (TC_ASPIRE__Contract__c contract : contracts) {
                contract.TC_ASPIRE__APICallStatus__c = 'Error';
            }
            
            update contracts;
        }
        
        return error;
    }
    
    public static String handleException(Exception e, List<TC_ASPIRE__Contract__c> contracts, String token, TC_ASPIRE__API_Setting__mdt settings) {
        String error = e.getMessage();
        
        try {
            //TC_ASPIRE.API.deleteTransaction(token, settings);
        }
        catch (Exception deleteException) {
            error += deleteException.getMessage() + '\n';
        }
        
        if (contracts != null) {
            for (TC_ASPIRE__Contract__c contract : contracts) {
                contract.TC_ASPIRE__APICallStatus__c = 'Error';
            }
            
            update contracts;
        }
        
        return error;
    }
    
    webService static String refreshASPIREData(String opportunityId) {
        String error = '';
        
        try {
            TC_ASPIREDataUtility.deleteASPIREObjectData(TC_ASPIREDataUtility.selectASPIREObjectData(opportunityId));
            TC_ASPIREDataUtility.createASPIREObjectData(opportunityId);
            System.debug('Refresh complete.');
        }
        catch (Exception e) {
            error = e.getMessage();
        }
        
        return error;
    }
}