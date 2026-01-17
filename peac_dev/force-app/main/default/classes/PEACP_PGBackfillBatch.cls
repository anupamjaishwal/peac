global class PEACP_PGBackfillBatch implements Database.Batchable<SObject> {
    
  global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all Opportunities that match
        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity
            WHERE Loan_Record_Type__c = true
            AND StageName NOT IN ('Review for Booking','Funding','Booking','Funded','Closed – Withdrawn')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Set<Id> oppIds = new Map<Id, Opportunity>(scope).keySet();
        
        // 1. Integration Logs
        List<Integration_Log__c> logs = [
            SELECT Id, Request_Message__c, Opportunity__c
            FROM Integration_Log__c
            WHERE Opportunity__c IN :oppIds
        ];
        if (logs.isEmpty()) {
            System.debug('No logs found for this batch of Opps.');
            return;
        }
        
        // 2. Guarantors
        Set<Id> oppsWithLogs = new Set<Id>();
        for (Integration_Log__c log : logs) oppsWithLogs.add(log.Opportunity__c);
        
        List<Guarantor__c> allGuarantors = [
            SELECT Id, Contact_First_Name__c, Contact_Last_Name__c, Opportunity__c, PG_Number__c
            FROM Guarantor__c
            WHERE Opportunity__c IN :oppsWithLogs
        ];
        
        // Map: OppId|first|last → list of Guarantors
        Map<String, List<Guarantor__c>> nameKeyToGuarantors = new Map<String, List<Guarantor__c>>();
        for (Guarantor__c g : allGuarantors) {
            String key = g.Opportunity__c + '|' +
                (g.Contact_First_Name__c != null ? g.Contact_First_Name__c.trim().toLowerCase() : '') + '|' +
                (g.Contact_Last_Name__c != null ? g.Contact_Last_Name__c.trim().toLowerCase() : '');
            if (!nameKeyToGuarantors.containsKey(key)) {
                nameKeyToGuarantors.put(key, new List<Guarantor__c>());
            }
            nameKeyToGuarantors.get(key).add(g);
        }
        
        // 3. Process logs
        Map<Id, Guarantor__c> guarantorsToUpdate = new Map<Id, Guarantor__c>();
        Integer successCount = 0, failCount = 0;
        List<String> successSamples = new List<String>();
        List<String> failSamples = new List<String>();
        
        for (Integration_Log__c log : logs) {
            if (String.isBlank(log.Request_Message__c)) continue;
            
            try {
                Dom.Document doc = new Dom.Document();
                doc.load(log.Request_Message__c);
                Dom.XmlNode root = doc.getRootElement();
                
                for (Integer i = 1; i <= 4; i++) {
                    String tagName = 'PG' + i;
                    Dom.XmlNode pgNode = root.getChildElement(tagName, null);
                    if (pgNode == null) continue;
                    
                    String firstName = pgNode.getChildElement('FIRSTNAME', null) != null ?
                        pgNode.getChildElement('FIRSTNAME', null).getText().trim().toLowerCase() : '';
                    String lastName = pgNode.getChildElement('LASTNAME', null) != null ?
                        pgNode.getChildElement('LASTNAME', null).getText().trim().toLowerCase() : '';
                    
                    if (String.isBlank(firstName) || String.isBlank(lastName)) continue;
                    
                    String key = log.Opportunity__c + '|' + firstName + '|' + lastName;
                    if (nameKeyToGuarantors.containsKey(key)) {
                        for (Guarantor__c g : nameKeyToGuarantors.get(key)) {
                            if (g.PG_Number__c != tagName) {
                                g.PG_Number__c = tagName;
                                guarantorsToUpdate.put(g.Id, g); // prevents duplicate Id error
                                successCount++;
                                if (successSamples.size() < 3) {
                                    successSamples.add('Opp ' + log.Opportunity__c +
                                                       ' → Guarantor ' + g.Id +
                                                       ' matched ' + firstName + ' ' + lastName +
                                                       ' set ' + tagName);
                                }
                            }
                        }
                    } else {
                        failCount++;
                        if (failSamples.size() < 3) {
                            failSamples.add(' Opp ' + log.Opportunity__c +
                                            ' → No Guarantor for ' + firstName + ' ' + lastName);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error processing log: ' + log.Id + ' — ' + e.getMessage());
            }
        }
        
        // 4. Update
        if (!guarantorsToUpdate.isEmpty()) {
            Database.update(guarantorsToUpdate.values(), false);
        }
        
        // 5. Debug summary
        
        for (String s : successSamples) System.debug(s);
        for (String f : failSamples) System.debug(f);
        
        System.debug('Summary: ' + successCount + ' successes, ' + failCount + ' failures in this batch.');
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch completed for PG backfill.');
    }
}