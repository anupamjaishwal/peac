/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description:  Trigger Handler class to stamp/capture fields on log record when a Buyout on Contract is created 	
 * @User Story: SL-2924
 */
public class PEAC_IL_Integration_LogsTriggerHandler {
	
	public static void afterInsert(List<IL_Integration_Logs__c> newLogs) {
    List<IL_Integration_Logs__c> updates = new List<IL_Integration_Logs__c>();

    for (IL_Integration_Logs__c logRec : newLogs) {

        // Only for Buyout integration logs
        if (logRec.Integration_Name__c != 'InfoLease Generate Buyout Quote') {
            continue;
        }

        IL_Integration_Logs__c upd = new IL_Integration_Logs__c(Id = logRec.Id);

        // Defaults
        Integer assetCount = 0;
        Boolean hasExtId = false;
        String extIdValue;

        // Parse Request JSON (if present)
        if (String.isNotBlank(logRec.Request_Text__c)) {
            try {
                Map<String, Object> root =
                    (Map<String, Object>) JSON.deserializeUntyped(logRec.Request_Text__c);

                Map<String, Object> inputs =
                    (Map<String, Object>) root.get('inputs');

                Map<String, Object> req =
                    (inputs != null) ? (Map<String, Object>) inputs.get('Request') : null;

                if (req != null) {
                    // Asset count
                    Object a = req.get('Assets');
                    if (a instanceof List<Object>) {
                        assetCount = ((List<Object>) a).size();
                    }

                    // External id key could be either of these
                    if (req.containsKey('BuyoutexternalId')) {
                        extIdValue = String.valueOf(req.get('BuyoutexternalId'));
                    } else if (req.containsKey('BuyoutExternalId')) {
                        extIdValue = String.valueOf(req.get('BuyoutExternalId'));
                    }

                    hasExtId = String.isNotBlank(extIdValue);

                    if (hasExtId) {
                        upd.Buyout_External_Id__c = extIdValue;
                    }
                }
            } catch (Exception ignore) {
                // Do not break transaction on malformed JSON
            }
        }

        // Stamp Status__c based on Type + assetCount/extId
        if (logRec.Type__c == 'Error') {
            upd.Status__c = 'Failed';
        } else {
            // Success case
            if (assetCount > 200 || hasExtId) {
                upd.Status__c = 'In Progress';
            } else {
                	//New requirement: no status stamping for <200
                    // leave Status__c as null
                    upd.Status__c = null;
            }
        }

        // Only add update if we are setting something meaningful
        if (upd.Status__c != null || upd.Buyout_External_Id__c != null) {
            updates.add(upd);
            }
        }

        if (!updates.isEmpty()) {
            try {
                update updates;
            } catch (Exception e) {
                System.debug('IL log stamping failed: ' + e.getMessage());
            }
        }
    }
    // wrapper
    private class ParsedMeta {
        public String buyoutExternalId;
        public String status;
    }

    // Parses Request_Text__c JSON and extracts BuyoutExternalId + Status.
    // Backward compatible: also reads LogExternalId/LogStatus if older records exist.
    private static ParsedMeta parseMetaFromRequest(String requestText) {
        String t = requestText.trim();
        if (!t.startsWith('{')) return null;

        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(requestText);

            ParsedMeta out = new ParsedMeta();

            // New names (per doc)
            if (root.containsKey('BuyoutExternalId'))
                out.buyoutExternalId = String.valueOf(root.get('BuyoutExternalId'));

            if (root.containsKey('Status'))
                out.status = String.valueOf(root.get('Status'));

            // Backward compat (older keys)
            if (out.buyoutExternalId == null && root.containsKey('LogExternalId'))
                out.buyoutExternalId = String.valueOf(root.get('LogExternalId'));

            if (out.status == null && root.containsKey('LogStatus'))
                out.status = String.valueOf(root.get('LogStatus'));

            // Normalize status if needed (optional)
            out.status = normalizeStatus(out.status);

            return out;
        } catch (Exception e) {
            // RequestText sometimes may contain HTML or non-JSON in failures (seen earlier)
            // In that case, do nothing
            return null;
        }
    }

    // Normalize to your picklist values
    private static String normalizeStatus(String s) {
        if (String.isBlank(s)) return null;
        String x = s.trim().toLowerCase();

        if (x == 'inprogress' || x == 'in progress') return 'In Progress';
        if (x == 'success' || x == 'completed') return 'Completed';
        if (x == 'error' || x == 'failed') return 'Failed';

        // If already correct picklist value, return it
        return s.trim();
    }
       
    @TestVisible
    private static String tv_normalizeStatus(String s) {
        return normalizeStatus(s);
    }
    
    @TestVisible
    private static Map<String, String> tv_parseMetaFromRequest(String requestText) {
        Map<String, String> out = new Map<String, String>();
        ParsedMeta m = parseMetaFromRequest(requestText);
        out.put('buyoutExternalId', m != null ? m.buyoutExternalId : null);
        out.put('status', m != null ? m.status : null);
        return out;
    }

}