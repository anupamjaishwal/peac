/**
* @Author: D Balakrishna (LTIMindtree)
* @Description:This Class ensures the LWC component shows latest IL records for the contract and provides hyperlinks with status labels	
* @User Story: SL-2924
* Created Date : 24 March 2026
*/
public class PEAC_ILIntegrationLogService {
    
    public class LogRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String buyoutExternalId;
        @AuraEnabled public String status;
        @AuraEnabled public String errorMessage;
        
        @AuraEnabled public String quoteBuyoutType;       // e.g. "83"
        @AuraEnabled public String quoteBuyoutTypeLabel;  // picklist label
        
        @AuraEnabled public String startTime;
    }
    
    public class LogResponse {
        @AuraEnabled public Boolean showComponent;
        @AuraEnabled public List<LogRow> rows;
    }
    
    private class ParsedMeta {
        public String buyoutExternalId;
        public String status;
    }
    
    // ---- existing parsing logic 
    private static ParsedMeta parseMeta(String requestText) {
        ParsedMeta m = new ParsedMeta();
        if (String.isBlank(requestText)) return m;
        String t = requestText.trim();
        if (!t.startsWith('{')) return m;
        
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(requestText);
            
            if (root.containsKey('BuyoutExternalId')) m.buyoutExternalId = String.valueOf(root.get('BuyoutExternalId'));
            if (root.containsKey('Status')) m.status = String.valueOf(root.get('Status'));
            
            if (m.buyoutExternalId == null && root.containsKey('LogExternalId')) m.buyoutExternalId = String.valueOf(root.get('LogExternalId'));
            if (m.status == null && root.containsKey('LogStatus')) m.status = String.valueOf(root.get('LogStatus'));
            
        } catch (Exception e) { }
        return m;
    }
    private static String normalizeStatus(String s) {
        if (String.isBlank(s)) return null;
        String x = s.trim().toLowerCase();
        if (x == 'inprogress' || x == 'in progress') return 'In Progress';
        if (x == 'error' || x == 'failed') return 'Failed';
        if (x == 'success' || x == 'completed') return 'Completed';
        return s.trim();
    }
    private static String deriveQbtFromExternalId(String extId) {
        if (String.isBlank(extId)) return '';
        List<String> parts = extId.split('-');
        if (parts.size() < 2) return '';
        return parts[parts.size() - 2]; // second last token
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getInProgressQbts(Id contractId) {
        Set<String> qbtSet = new Set<String>();
        
        List<IL_Integration_Logs__c> logs = [
            SELECT Request_Text__c
            FROM IL_Integration_Logs__c
            WHERE Contract__c = :contractId
            AND Integration_Name__c LIKE 'InfoLease Generate Buyout Quote%'
            AND (Status__c = 'In Progress' OR Status__c = 'InProgress')
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
        
        for (IL_Integration_Logs__c logRec : logs) {
            if (String.isBlank(logRec.Request_Text__c)) continue;
            
            try {
                Map<String, Object> root =
                    (Map<String, Object>) JSON.deserializeUntyped(logRec.Request_Text__c);
                
                Map<String, Object> inputs =
                    (Map<String, Object>) root.get('inputs');
                if (inputs == null) continue;
                
                Map<String, Object> req =
                    (Map<String, Object>) inputs.get('Request');
                if (req == null) continue;
                
                if (req.containsKey('BuyoutType')) {
                    String bt = String.valueOf(req.get('BuyoutType'));
                    if (!String.isBlank(bt)) qbtSet.add(bt.trim());
                }
            } catch (Exception ignore) {}
        }
        
        return new List<String>(qbtSet);
    }
    
    @AuraEnabled(cacheable=true)
    public static LogResponse getLatestLogs(Id contractId, Integer minutesBack) {
        LogResponse resp = new LogResponse();
        resp.rows = new List<LogRow>();
        resp.showComponent = false;
        
        if (minutesBack == null || minutesBack <= 0) minutesBack = 1440;
        Datetime cutoff = System.now().addMinutes(-minutesBack);
        
        // Picklist value -> label map for QBT label
        Map<String, String> qbtLabelMap = new Map<String, String>();
        for (Schema.PicklistEntry pe : Contract__c.Quote_Buyout_Types__c.getDescribe().getPicklistValues()) {
            qbtLabelMap.put(pe.getValue(), pe.getLabel());
        }
        
        //tolerate integration name variants (DP etc.)
        List<IL_Integration_Logs__c> logs = [
            SELECT Id, CreatedDate, Request_Text__c, Status__c, Type__c, Error_Message__c, Integration_Name__c
            FROM IL_Integration_Logs__c
            WHERE Contract__c = :contractId
            AND Integration_Name__c LIKE 'InfoLease Generate Buyout Quote%'
            AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
        
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        Map<String, LogRow> bestByQbt = new Map<String, LogRow>();
        
        for (IL_Integration_Logs__c l : logs) {
            String status = normalizeStatus(l.Status__c);
            if (String.isBlank(status)) {
                status = (l.Type__c == 'Error') ? 'Failed' : null;
            }
            if (status != 'In Progress' && status != 'Failed') continue;
            
            ParsedReq parsed = parseRequest(l.Request_Text__c);
            if (String.isBlank(parsed.buyoutType)) continue;
            
            LogRow row = new LogRow();
            row.id = l.Id;
            row.recordUrl = baseUrl + '/' + l.Id;
            row.createdDate = l.CreatedDate;
            row.status = status;
            row.errorMessage = l.Error_Message__c;
            
            row.quoteBuyoutType = parsed.buyoutType;
            row.quoteBuyoutTypeLabel = qbtLabelMap.containsKey(parsed.buyoutType)
                ? qbtLabelMap.get(parsed.buyoutType)
                : parsed.buyoutType;
            
            row.buyoutExternalId = parsed.buyoutExternalId;
            
            //start time fallback
            String st = formatStartTimeFromExternalId(parsed.buyoutExternalId);
            row.startTime = String.isBlank(st) ? l.CreatedDate.format('M/d/yyyy h:mm a','America/New_York') : st;
            
            if (!bestByQbt.containsKey(parsed.buyoutType)) {
                bestByQbt.put(parsed.buyoutType, row);
            } 
            else {
                LogRow existing = bestByQbt.get(parsed.buyoutType);
                //Absolute preference: keep In Progress if we already have it
                if (existing != null && existing.status == 'In Progress') {
                    // Only replace if the new one is also In Progress and newer
                    if (row.status == 'In Progress' &&
                        row.createdDate != null && existing.createdDate != null &&
                        row.createdDate.getTime() > existing.createdDate.getTime()) {
                            bestByQbt.put(parsed.buyoutType, row);
                        }
                    // Never replace In Progress with Failed
                } else {
                    // existing is Failed (or null status), so take In Progress immediately
                    if (row.status == 'In Progress') {
                        bestByQbt.put(parsed.buyoutType, row);
                    } else {
                        // both are Failed -> keep most recent
                        if (row.createdDate != null && existing != null && existing.createdDate != null &&
                            row.createdDate.getTime() > existing.createdDate.getTime()) {
                                bestByQbt.put(parsed.buyoutType, row);
                            }
                    }
                }
            }
            
        }
        
        List<LogRow> out = new List<LogRow>();
        out.addAll(bestByQbt.values());
        out.sort(new LogRowDateSorter());
        
        resp.rows = out;
        resp.showComponent = !resp.rows.isEmpty();
        return resp;
    }
    
    
    /** helper wrapper for parsed request */
    private class ParsedReq {
        String buyoutType;
        String buyoutExternalId;
    }
    
    /** parse BuyoutType + externalId from Request_Text__c */
   /* private static ParsedReq parseRequest(String requestText) {
        ParsedReq p = new ParsedReq();
        if (String.isBlank(requestText) || !requestText.trim().startsWith('{')) return p;
        
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(requestText);
            Map<String, Object> inputs = (Map<String, Object>) root.get('inputs');
            Map<String, Object> req = inputs != null ? (Map<String, Object>) inputs.get('Request') : null;
            if (req == null) return p;
            
            if (req.containsKey('BuyoutType')) p.buyoutType = String.valueOf(req.get('BuyoutType'));
            
            // supports both keys
            if (req.containsKey('BuyoutexternalId')) p.buyoutExternalId = String.valueOf(req.get('BuyoutexternalId'));
            else if (req.containsKey('BuyoutExternalId')) p.buyoutExternalId = String.valueOf(req.get('BuyoutExternalId'));
            
        } catch (Exception ignore) {}
        return p;
    }*/
    
    private static ParsedReq parseRequest(String requestText) {
        ParsedReq p = new ParsedReq();
        if (String.isBlank(requestText) || !requestText.trim().startsWith('{')) return p;
        
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(requestText);
            
            Map<String, Object> req;
            
            if (root.containsKey('inputs')) {
                Map<String, Object> inputs = (Map<String, Object>) root.get('inputs');
                req = inputs != null ? (Map<String, Object>) inputs.get('Request') : null;
            } else {
                req = (Map<String, Object>) root.get('Request');
            }
            
            if (req == null) return p;
            
            if (req.containsKey('BuyoutType')) p.buyoutType = String.valueOf(req.get('BuyoutType'));
            
            if (req.containsKey('BuyoutexternalId')) p.buyoutExternalId = String.valueOf(req.get('BuyoutexternalId'));
            else if (req.containsKey('BuyoutExternalId')) p.buyoutExternalId = String.valueOf(req.get('BuyoutExternalId'));
            
        } catch (Exception ignore) {}
        return p;
    }
    
    /** sorter: CreatedDate desc */
    private class LogRowDateSorter implements Comparator<LogRow> {
        public Integer compare(LogRow a, LogRow b) {
            Long ta = (a.createdDate == null) ? 0 : a.createdDate.getTime();
            Long tb = (b.createdDate == null) ? 0 : b.createdDate.getTime();
            // DESC
            if (tb > ta) return 1;
            if (tb < ta) return -1;
            return 0;
        }
    }
    private static String formatStartTimeFromExternalId(String extId) {
        if (String.isBlank(extId)) return '';
        
        List<String> parts = extId.split('-');
        if (parts.size() < 3) return '';
        
        String ts = parts[parts.size() - 1];
        if (ts.length() < 14) return '';
        
        // yyyyMMddHHmmss (ignore milliseconds)
        try {
            Integer y  = Integer.valueOf(ts.substring(0, 4));
            Integer mo = Integer.valueOf(ts.substring(4, 6));
            Integer d  = Integer.valueOf(ts.substring(6, 8));
            Integer h  = Integer.valueOf(ts.substring(8, 10));
            Integer mi = Integer.valueOf(ts.substring(10, 12));
            Integer s  = Integer.valueOf(ts.substring(12, 14));
            
            Datetime dt = Datetime.newInstanceGmt(y, mo, d, h, mi, s);
            return dt.format('M/d/yyyy h:mm a','America/New_York');
        } catch (Exception e) {
            return '';
        }
    }
    
    
    
    
    // Test-visible wrappers to cover private helper methods
    // (No runtime behavior impact)
    @TestVisible
    private static String tv_normalizeStatus(String s) {
        return normalizeStatus(s);
    }
    
    @TestVisible
    private static String tv_deriveQbtFromExternalId(String extId) {
        return deriveQbtFromExternalId(extId);
    }
    
    @TestVisible
    private static String tv_formatStartTimeFromExternalId(String extId) {
        return formatStartTimeFromExternalId(extId);
    }
    
    //parseMeta() returns a private inner type, so expose a Map for tests.
    @TestVisible
    private static Map<String, String> tv_parseMeta(String requestText) {
        Map<String, String> out = new Map<String, String>();
        ParsedMeta m = parseMeta(requestText);
        out.put('buyoutExternalId', m != null ? m.buyoutExternalId : null);
        out.put('status', m != null ? m.status : null);
        return out;
    }
}