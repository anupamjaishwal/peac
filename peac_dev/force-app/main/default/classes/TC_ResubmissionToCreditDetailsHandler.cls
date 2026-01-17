// SAL-2791
public with sharing class TC_ResubmissionToCreditDetailsHandler {
    
    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {

        Map<Id, Opportunity> parentOpps = creditDecisionChangedToTrue(oldMap, newMap);

        if (parentOpps.size() > 0) {
            Map<Id, Resubmission_to_Credit_Details__c> resubmissions = getMostRecentResubmissionToCreditDetails(parentOpps);

            if (resubmissions.size() > 0) {
                updateResubmissionToCreditDetails(parentOpps, resubmissions);
            }
        }
    }

    private static Map<Id, Opportunity> creditDecisionChangedToTrue(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        Map<Id, Opportunity> parentOpps = new Map<Id, Opportunity>();

        for (Opportunity opp : newMap.values()) {
            if (opp.Credit_Decision__c && !oldMap.get(opp.Id).Credit_Decision__c) {
                parentOpps.put(opp.Id, opp);
            }
        }

        return parentOpps;
    }

    public static Map<Id, Resubmission_to_Credit_Details__c> getMostRecentResubmissionToCreditDetails(Map<Id, Opportunity> opps) {

        Map<Id, Resubmission_to_Credit_Details__c> resubmissionMap = new Map<Id, Resubmission_to_Credit_Details__c>();

        List<Resubmission_to_Credit_Details__c> resubmissions = [
            SELECT Id, Render_Decision_Date_Time__c, Opportunity__c 
            FROM Resubmission_to_Credit_Details__c 
            WHERE Opportunity__c IN :opps.keySet()
            ORDER BY CreatedDate DESC
        ];

        for (Resubmission_to_Credit_Details__c resubmission : resubmissions) {
            if (resubmissionMap.get(resubmission.Opportunity__c) == null) {
                resubmissionMap.put(resubmission.Opportunity__c, resubmission);
            }
        }

        return resubmissionMap;
    }

    public static void updateResubmissionToCreditDetails(Map<Id, Opportunity> opps, Map<Id, Resubmission_to_Credit_Details__c> resubmissions) {

        for (Resubmission_to_Credit_Details__c resubmission : resubmissions.values()) {

            Opportunity objOpp = opps.get(resubmission.Opportunity__c);

            String decimalStrWithDollarSign;
			String MaxTermApproved;

            If( String.isNotBlank(String.valueOf(objOpp.Approved_Amount__c))) {
                    decimalStrWithDollarSign = string.format('${0}', new string[]{String.valueOf(objOpp.Approved_Amount__c.setScale(2).format())});

                    }
            else
            {
                 decimalStrWithDollarSign = '';
            }
            
            If( String.isNotBlank(String.valueOf(objOpp.Max_Term_Approved__c))) {
				MaxTermApproved = String.valueOf(objOpp.Max_Term_Approved__c);

                    }
            else
            {
                MaxTermApproved = '';
            }            


            resubmission.Render_Decision_Date_Time__c = System.now();
            resubmission.Resub_Decisioned_By__c = UserInfo.getUserId();
            resubmission.Field_Values_at_Resub_Render_Decision__c = 'Decision Status: ' +objOpp.Decision_Status__c + '\nApproved Amount: ' + decimalStrWithDollarSign + '\n Max Term Approved: ' + MaxTermApproved;
        }

        update resubmissions.values();
    }
}