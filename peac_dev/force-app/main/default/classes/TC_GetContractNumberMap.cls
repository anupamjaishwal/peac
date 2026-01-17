public class TC_GetContractNumberMap {
public static Map <Id, String> getContractNumberMap (Set <Id> oppIds) {
        Map <Id, String> contractNumberMap = new Map <Id, String> ();
        
        if (oppIds.size () > 0) {
            List <Opportunity> opps = [SELECT CCID__c,
                                       (SELECT Id,
                                        Name
                                        FROM Loan_Contracts__r)
                                       FROM Opportunity
                                       WHERE Id IN :oppIds
                                      ];
            
            for (Opportunity opp : opps) {
                String contractNumber = '500-' + (String.isNotEmpty (opp.CCID__c) && opp.CCID__c.length () == 7 ? opp.CCID__c.right (6) : '000000') + '-001';
                String currentPrefix = '';
                Integer currentSequence = 0;
                
                for (Loan_Contract__c lc : opp.Loan_Contracts__r) {
                    if (lc.Name.length () == 14) {
                        currentPrefix = lc.Name.left (11);
                        
                        Integer sequence = 0;
                        try {
                            sequence = Integer.valueOf (lc.Name.right (3));
                        }
                        catch (Exception e) {}
                        
                        if (sequence > currentSequence)
                            currentSequence = sequence;
                    }
                }
                
                if (currentSequence > 0) {
                    contractNumber = currentPrefix + String.valueOf (currentSequence + 1).leftPad (3, '0');
                }
                
                contractNumberMap.put (opp.Id, contractNumber);
            }
        }
        
        return contractNumberMap;
    }
    
}