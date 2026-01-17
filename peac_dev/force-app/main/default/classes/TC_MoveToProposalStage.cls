/*
    Andrew Mayer
    Description:
    Move stage to proposal on application status approval

    JIRA:
    Need to track down

    Operations:
    Before Update

    Queries: 0
    DMLS: 0

    Test Class: none yet
 */

public with sharing class TC_MoveToProposalStage{

    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {

        List <Opportunity> newList = newMap.values();
        

        for (Opportunity opp : newList) {
            if ((opp.StageName == 'Application' || opp.StageName == 'Decision')
                && (
                    ((opp.Application_Status__c == 'Automatically Approved' || opp.Application_Status__c == 'Manually Approved') && !opp.Loan_Record_Type__c)
                        ||
                    (opp.Application_Status__c == 'Approved' && opp.Loan_Record_Type__c)
                    )
                && (opp.Application_Status__c != oldMap.get (opp.Id).Application_Status__c
                    ||
                        opp.Credit_Decision__c && !oldMap.get (opp.Id).Credit_Decision__c)
                && !opp.Resubmitted_to_Credit__c
                    ) {
                opp.StageName = 'Proposal';
                opp.Opportunity_Status__c = 'Proposal';
            }
        }

    }
}