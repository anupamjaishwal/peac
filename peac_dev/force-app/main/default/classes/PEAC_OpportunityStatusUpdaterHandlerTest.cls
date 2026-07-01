@IsTest
public class PEAC_OpportunityStatusUpdaterHandlerTest {
    @IsTest
    static void decision_inQueue_rule() {
        Test.startTest();
        Opportunity o = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Decision',
            CloseDate = Date.today().addDays(30),
            Decision_Status__c = 'A', // not AM/C/R
            Reason_for_Approval__c = 'Normal',
            Credit_Decision__c = false,
            Assigned_Credit_User__c = null,
            Application_Status__c = 'More Info',
            Resubmitted_to_Credit__c = true
        );
        insert o;
        
        o.Decision_Status__c = 'PE';
        update o; // invoke trigger
        Test.stopTest();
        
        o = [SELECT Opportunity_Status__c FROM Opportunity WHERE Id = :o.Id];
        //System.assertEquals('Credit - More Info Requested', o.Opportunity_Status__c);
    }
    
    @IsTest
    static void credit_inReview_onAssignment() {
        Test.startTest();
        Opportunity o = new Opportunity(
            Name = 'Review Opp',
            StageName = 'Decision',
            CloseDate = Date.today().addDays(30),
            //Opportunity_Status__c = 'Some Status',
            Assigned_Credit_User__c = null
        );
        insert o;
        
        // simulate assignment
        User u = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        o.Assigned_Credit_User__c = u.Id;
        update o;
        Test.stopTest();
        
        o = [SELECT Opportunity_Status__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals('Credit - In Review', o.Opportunity_Status__c);
    }
    
    @IsTest
    static void testEvaluateAndSetStatus(){
        Opportunity o = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Decision_Status__c = 'A', // not AM/C/R
            Reason_for_Approval__c = 'Normal',
            Credit_Decision__c = false,
            Assigned_Credit_User__c = null,
            Application_Status__c = 'More Info',
            Resubmitted_to_Credit__c = true
        );
        List<Opportunity> opplist = new List<Opportunity>();
        opplist.add(o);
        Test.startTest();
        PEAC_OpportunityStatusUpdaterHandler.evaluateAndSetStatus(opplist, null);
        Test.stopTest();
        
    }
}