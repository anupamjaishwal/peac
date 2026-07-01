/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description: The Helper Class to handle Asynchronous Integration for Contract Assets with count greater than 200.
 * @User Story: SL-2924
 */
public class PEAC_BuyoutAsyncCalloutHelper {
	
	@future(callout=true)
    public static void submitBuyoutFromIntegrationLog(Id ilLogId) {
        
        String traceId = 'TRACE-' + Datetime.now().getTime() + '-' + UserInfo.getUserId();
    
        System.debug('================ BRIDGEWARE CALLOUT START ================');
        System.debug('TRACE_ID    : ' + traceId);
        System.debug('IL_LOG_ID   : ' + ilLogId);
        System.debug('IsFuture    : ' + System.isFuture());
        System.debug('UserId      : ' + UserInfo.getUserId());
		System.debug('ASYNC BUYOUT START logId=' + ilLogId + ' time=' + System.now());
        
        if (ilLogId == null) return;
        
        System.debug('ASYNC BUYOUT START logId=' + ilLogId + ' user=' + UserInfo.getUserId() + ' time=' + System.now());
        
        List<IL_Integration_Logs__c> logs = [SELECT Id, Contract__c, Request_Text__c, Integration_Name__c
                 , Status__c, Error_Message__c, Type__c
            FROM IL_Integration_Logs__c
            WHERE Id = :ilLogId
            LIMIT 1];
        
        if (logs.isEmpty()) return;
        IL_Integration_Logs__c logRec = logs[0];
        if (String.isBlank(logRec.Request_Text__c)) return;
		System.debug(logginglevel.error,'Request JSON' + logRec.Request_Text__c);
        
        System.debug('ASYNC PAYLOAD LEN=' + (logRec.Request_Text__c == null ? 0 : logRec.Request_Text__c.length()));
		System.debug('ASYNC CONTRACT=' + logRec.Contract__c);
        
        
        String payloadHash = EncodingUtil.convertToHex(
                Crypto.generateDigest('MD5', Blob.valueOf(logRec.Request_Text__c))
            );
        System.debug('PAYLOAD_MD5_HASH=' + payloadHash);

        // Determine IL10 flag (same logic path as current implementation)
        Boolean isIL10 = false;
        try {
            Contract__c c = [SELECT Id, Infolease_Environment__c FROM Contract__c WHERE Id = :logRec.Contract__c LIMIT 1];
            isIL10 = TC_BWUtility.isIL10Record(c);
        } catch (Exception ignore) {}

        String response;
        try {
            // Use existing Bridgeware callout utility to preserve endpoint/header behavior 
            // IMPORTANT: saveLog = false to avoid creating a SECOND log row; we update the same row instead.
            response = SL_SummaryAndDetail.callBridgeware(
                logRec.Request_Text__c,
                String.valueOf(logRec.Contract__c),
                false,   // saveLog
                false,   // isWaiver
                isIL10
            );
			System.debug('ASYNC RESPONSE LEN=' + (response == null ? 0 : response.length()));
			System.debug('ASYNC RESPONSE HEAD=' + (response != null && response.length() > 200 ? response.substring(0,200) : response));
            // Evaluate failure from response
            Boolean isFail = isInfoleaseFailure(response);
            if (isFail) {
                String msg = extractInfoleaseMessage(response);
               updateSafeLog(logRec.Id, 'Failed', 'Error', msg, response);
            } else {
                // Mark as Completed so it disappears from summary LWC (it shows only In Progress/Failed)
                updateSafeLog(logRec.Id, 'In Progress', 'Success', null, response);// Updated from Completed to "In Progress"
            }
        } catch (Exception e) {
            updateSafeLog(logRec.Id, 'Failed', 'Error', e.getMessage(), null);
        }
    }

    // --- Lightweight parsers (keep helper self-contained) ---
    private static Boolean isInfoleaseFailure(String rawResponse) {
        if (String.isBlank(rawResponse)) return true;
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(rawResponse);
            Map<String, Object> respWrap = (Map<String, Object>) (root.get('response') != null ? root.get('response') : root);
            Map<String, Object> resp = (Map<String, Object>) respWrap.get('Response');
            if (resp == null) return true;
            String successVal = String.valueOf(resp.get('Success'));
            return successVal != null && successVal.toLowerCase() == 'false';
        } catch (Exception e) {
            return true;
        }
    }

    private static String extractInfoleaseMessage(String rawResponse) {
        if (String.isBlank(rawResponse)) return 'No response returned from Infolease.';
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(rawResponse);
            Map<String, Object> respWrap = (Map<String, Object>) (root.get('response') != null ? root.get('response') : root);
            
            // Handle error shape: {"response":{"Errors":{"Err1":"..."}}}
            Object errsTop = respWrap.get('Errors');
                if (errsTop instanceof Map<String, Object>) {
                    Map<String, Object> m = (Map<String, Object>) errsTop;
                    if (m.containsKey('Err1')) return String.valueOf(m.get('Err1'));
                }            

            Map<String, Object> resp = (Map<String, Object>) respWrap.get('Response');            
            if (resp != null) {
                Object errs = resp.get('Errors');
                if (errs instanceof List<Object>) {
                    List<Object> eList = (List<Object>) errs;
                    List<String> msgs = new List<String>();
                    for (Object o : eList) if (o != null) msgs.add(String.valueOf(o));
                    if (!msgs.isEmpty()) return String.join(msgs, ', ');
                }
            }
            return rawResponse;
        } catch (Exception e) {
            return rawResponse;
        }
    }

    // Update log safely   
    private static void updateSafeLog(Id logId, String status, String typeVal, String errMsg, String responseText) {
        SObject s = new IL_Integration_Logs__c(Id = logId);
    
        Map<String, SObjectField> f = IL_Integration_Logs__c.SObjectType.getDescribe().fields.getMap();
    
        if (f.containsKey('Status__c')) s.put('Status__c', status);
        if (f.containsKey('Type__c')) s.put('Type__c', typeVal);
        if (f.containsKey('Error_Message__c')) s.put('Error_Message__c', errMsg);
    
        // ✅ Persist response payload 
        if (responseText != null && f.containsKey('ResponseText__c')) {
            Integer maxLen = 32000; // safe guard if it's a long text area
            String trimmed = responseText.length() > maxLen ? responseText.substring(0, maxLen) : responseText;
            s.put('ResponseText__c', trimmed);
        }
    
        try { update s; } catch (Exception ignore) {}
    }

    
    // Test-visible wrappers (no runtime impact)
    @TestVisible private static Boolean tv_isInfoleaseFailure(String s) { return isInfoleaseFailure(s); }
    @TestVisible private static String tv_extractInfoleaseMessage(String s) { return extractInfoleaseMessage(s); }
    @TestVisible private static void tv_updateSafeLog(Id id, String st, String ty, String em, String rt) { updateSafeLog(id, st, ty, em, rt); }

}