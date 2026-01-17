/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: http://docs.bridgewaretamarack.apiary.io
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public with sharing class TC_BridgewareServiceImpl implements TC_BridgewareService {
	TC_BridgewareUtility serviceUtil = TC_BridgewareUtility.getInstance();

	public TC_BridgewareBookContractRespBean bookContract(TC_BridgewareBookContractRequestUCI uci) {
		TC_BridgewareBookContractRespBean respBean;
		IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
		Boolean isIL10 = il10Setting.use_IL10__c;
		Integer successStatusCode = isIL10? 200: 201;
		if (uci != null) {
			String requestJson = JSON.serialize(uci);
			if(isIL10){
            	requestJson = uci.getIL10Json();
            }
            System.debug('requestJson: ' + requestJson);
			System.debug('requestJson tail: ' + requestJson.right(255));
			serviceUtil.logInfo(requestJson);

			try {
				Http h = new Http ();
				HttpRequest req = new HttpRequest ();

				if (serviceUtil.getServiceSettings().Mock_Callout__c && !String.isEmpty(serviceUtil.getServiceSettings().Mock_Endpoint__c)) {
					Blob headerValue = Blob.valueOf('username' + ':' + 'password');
					String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
					req.setHeader('Authorization', authorizationHeader);
					req.setEndpoint(serviceUtil.getServiceSettings().Mock_Endpoint__c + '/bookContract');
					
				} else {
					if(isIL10){
                        TC_BWUtility.requestToIL10(req, 'UCI');
					}else{
						req.setEndpoint('callout:Bridgeware/bookContract');
					}
				}

				req.setMethod('POST');
				req.setHeader('CONFIG-NAME', serviceUtil.getServiceSettings().Config_Name__c);
				req.setHeader('Content-Type','application/json');
				req.setBody(requestJson);
                req.setTimeout(120000);

				HttpResponse resp = h.send(req);
				String respBody= resp.getBody();
				System.debug('respBody: ' + respBody);
				if (resp.getStatusCode() == successStatusCode) { //created
					if(isIL10){
						respBean = new TC_BridgewareBookContractRespBean();
						String transformedResp = respBody.removeStartIgnoreCase('{"uci.Results":"').removeEndIgnoreCase('"}')
							.replaceAll('\\\\/', '/').replaceAll('\\\\r\\\\n', '\r\n');
						if(transformedResp.contains('<Status>Success</Status>')){
							respBean.statusMessage = 'Success';
							respBean.contractNbr = transformedResp.substringBetween('<ContractNbr>', '</ContractNbr>');
						}else{
							respBean.statusMessage = 'Failed';
							respBean.responseMessageDesc = 'Message returned by BridgeWare server:'
								+ transformedResp.substringBetween('<FatalMessages>', '</FatalMessages>');
						}
					}else{
						serviceUtil.logInfo('bookContract response #####\n' + respBody);
						respBean = TC_BridgewareBookContractRespBean.createResponseBeanFromJson (respBody);
						serviceUtil.logInfo('TC_BridgewareBookContractRespBean ######\n' + respBean);
					}
				} else {
					serviceUtil.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + respBody);
					respBean = new TC_BridgewareBookContractRespBean ();
					respBean.statusMessage = 'Failed';
					respBean.responseMessageDesc = resp.getStatusCode() + ' Status Code returned by BridgeWare server.';
				}
				MARLIN_IntegrationLog.addLog ('Infolease Booking Request',
					uci.getUciKey(), 
					(resp.getStatusCode() == successStatusCode && respBean.statusMessage == 'Success' ? 'Success' : 'Error'),
					req.getBody(),
					respBody,
					resp.getStatusCode() + '',
					resp.getStatus());
                MARLIN_IntegrationLog.insertLogs();
			} catch (Exception e) {
				System.debug(new BridgewareServiceException (e.getMessage() + e.getStackTraceString()));
				throw new BridgewareServiceException (e.getMessage());
			} 

		} else {
			respBean = new TC_BridgewareBookContractRespBean ();
		}

		return respBean;
	}

	public TC_BridgewareSelectZipGeoCodeRespBean selectZipGeoCode(TC_BridgewareSelectZipGeoCodeRequestBean bean) {
		TC_BridgewareSelectZipGeoCodeRespBean respBean;
		IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
		Boolean isIL10 = il10Setting.use_IL10__c;
		if (bean != null) {
			String requestJson = JSON.serialize(bean);
			System.debug('requestJson: ' + requestJson);
			System.debug('requestJson tail: ' + requestJson.right(255));
			serviceUtil.logInfo(requestJson);

			try {
				Http h = new Http ();
				HttpRequest req = new HttpRequest ();

				if (serviceUtil.getServiceSettings().Mock_Callout__c && !String.isEmpty(serviceUtil.getServiceSettings().Mock_Endpoint__c)) {
					Blob headerValue = Blob.valueOf('username' + ':' + 'password');
					String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
					req.setHeader('Authorization', authorizationHeader);
					req.setEndpoint(serviceUtil.getServiceSettings().Mock_Endpoint__c + '/selectZipGeoCode');
					
				} else {
					if(isIL10){
                        TC_BWUtility.requestToIL10(req, 'ZIP');
					}else{
						req.setEndpoint('callout:Bridgeware/selectZipGeoCode');
					}
				}

				req.setMethod('POST');
				req.setHeader('CONFIG-NAME', serviceUtil.getServiceSettings().Config_Name__c);
				req.setHeader('Content-Type','application/json');
				req.setBody(requestJson);
                req.setTimeout(120000);

				HttpResponse resp = h.send(req);
				String responseJson = TC_BWResponseBean.unWrap(resp.getBody());
				System.debug('req.getEndpoint(): ' + req.getEndpoint());
				System.debug('responseJson: ' + responseJson);
				System.debug('responseJson tail: ' + responseJson.right(255));
				if (resp.getStatusCode() == 200) {
					serviceUtil.logInfo('selectZipGeoCode response #####\n' + responseJson);
					if(isIL10){
						respBean = TC_BridgewareSelectZipGeoCodeRespBean.createResponseBeanFromXml(responseJson);
					}else{
						respBean = TC_BridgewareSelectZipGeoCodeRespBean.createResponseBeanFromJson(responseJson);
					}
					serviceUtil.logInfo('TC_BridgewareSelectZipGeoCodeRespBean ######\n' + respBean);
				} else {
					serviceUtil.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + responseJson);
					respBean = TC_BridgewareSelectZipGeoCodeRespBean.createResponseBeanFromJson (responseJson);
				}
				MARLIN_IntegrationLog.addLog ('Select Zip Geo Code',
					'', 
					(resp.getStatusCode() == 200 ? 'Success' : 'Error'),
					req.getBody(),
					responseJson,
					resp.getStatusCode() + '',
					resp.getStatus());
                MARLIN_IntegrationLog.insertLogs();
			} catch (Exception e) {
				System.debug(new BridgewareServiceException (e.getMessage() + e.getStackTraceString()));
				throw new BridgewareServiceException (e.getMessage());
			} 
		} else {
			respBean = new TC_BridgewareSelectZipGeoCodeRespBean ();
		}

		return respBean;
	}

	public class BridgewareServiceException extends Exception {}
}