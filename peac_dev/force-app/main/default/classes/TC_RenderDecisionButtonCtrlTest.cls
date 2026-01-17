@IsTest
public class TC_RenderDecisionButtonCtrlTest {
    @TestSetup
    static void makeData(){
        String username = 'standardusertest123@northteq.com';
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'testuser', Email = 'sfdc@northteq.com', EmailEncodingKey='UTF-8',
                          LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                          LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                          Username = username, Doc_Fee_Exception_Approver__c = true,Credit_Authority__c=1000,Credit_Authority_Loan__c=1000);
        insert u;
        
        Account acc = new Account();
        acc.Name = 'testacc';
        acc.Business_Phone__c = '1111111111';
        acc.CCID__c = 'C202020';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'testopp';
        opp.StageName = 'Decision';
        opp.CloseDate = Date.today()+5;
        opp.AccountId = acc.Id;
        opp.Program__c ='XBS';
        opp.Decision_Status__c = 'PE';
        opp.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('CVG Decision').getRecordTypeId();
        insert opp;
    }
    
    @IsTest
    static void testGetRenderDecisionDetailsAutomaticallyApproved() {
        
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_RenderDecisionButtonCtrl.getRenderDecisionDetails(oppId);
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetRenderDecisionDetailsManuallyApproved() {
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            Opportunity opp = new Opportunity();
            opp.Name = 'testopp';
            opp.Assigned_Credit_User__c = null;
            opp.Application_Status__c = 'Manually Approved'; 
            opp.Policy_Exception__c = null;
            opp.Financials_Reviewed__c = null;
            opp.Approved_Amount__c = 170000;
            opp.OFAC_Result__c = 'There is not a potential OFAC MATCH'; 
            opp.OFAC_Override__c = false; 
            opp.Decision_Status__c = 'A';
            opp.Program__c ='3D SYSTEMS';
            opp.Id = oppId;
            Update opp;
            TC_RenderDecisionButtonCtrl.getRenderDecisionDetails(oppId);
            Test.stopTest();
        }
    }
    @IsTest
    static void renderDecisionWithEmailNotification() {
        
        opportunity opportunityRecord = [SELECT Id, Name, OwnerId, Assigned_Credit_User__c,Reason_for_Approval__c,Terms__c, Max_Term_Approved__c, 
                                         Originally_Decisioned_By__c, Policy_Exception__c,Decisioned_By__c,Application__c,Credit_Decision__c, Resubmitted_to_Credit__c, Decision_Status__c, Application_Status__c,
                                         SFP_Tier_2_Credit_Box__c, SFP_Tier_2_Status__c, SIC_Code__c, Approved_Amount__c, OFAC_Result__c, Branch__c, Equip_Code1__c,Months_in_Profession__c, 
                                         Fraud_Flag__c, Fraud_Review_Status__c, SFP2_In_Process__c, Total_Exposure__c,Credit_Amount__c, Decline_Reason__c,
                                         FraudReviewFlag__c, StageName, Opportunity_Status__c,Loan_Record_Type__c,Lessor__c,Business_Type__c FROM Opportunity LIMIT 1];
        opportunity opp= new opportunity();
        opp.Id = opportunityRecord.Id;
        opp.FraudReviewFlag__c = 1 ;
        opp.Decision_Status__c = 'A';
        opp.Fraud_Review_Status__c = 'Rejected';
        Update opp;
        
        opportunity Updatetoppo = [SELECT Id,FraudReviewFlag__c,Decision_Status__c,Fraud_Review_Status__c,Approved_Amount__c,Lessor__c,Max_Term_Approved__c,
                                   Credit_Amount__c,Total_Exposure__c,Reason_for_Approval__c,Business_Type__c,Branch__c,Terms__c FROM Opportunity Where Id =: opp.Id LIMIT 1];
        
        TC_RenderDecisionButtonCtrl.RenderDecisionWrapper wrapper= new TC_RenderDecisionButtonCtrl.RenderDecisionWrapper(Updatetoppo);
        wrapper.opp = Updatetoppo;
        wrapper.fraudFlag = True;
        list<string> errorList1 = new list<string>();
        errorList1.add('Assigned Credit User must be populated.');
        wrapper.errorList = errorList1;
        wrapper.confirmActionStep = True;
        wrapper.supplementalCodes = True;
        User u = [SELECT Id,Credit_Authority__c FROM User WHERE Username = 'standardusertest123@northteq.com'];
        
        System.runAs(u) {
            Test.startTest();
            //TC_RenderDecisionButtonCtrl.renderDecision(wrapper);
            try{
                List<Messaging.SendEmailResult> sentCustomerVerifyEmail = TC_EmailUtil.sendEmailNotification(new List<String>{'test@test'}, null, null, null, 'subject', 'body', null, null, null);
                Id oppId = [SELECT Id FROM Opportunity][0].Id;
                TC_RenderDecisionButtonCtrl.renderDecision(wrapper);
                
            } catch (Exception e){
            }
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testFinalOppUpdate() {
        Account acc = new Account();
        acc.Name = 'testFinalUpdate';
        acc.Business_Phone__c = '1111111134';
        acc.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Business_Address__c = '123 Street Ave N';
        acc.Business_City__c = 'Minneapolis';
        acc.Business_State__c = 'MN';
        acc.Business_Zip__c = '55401';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.CloseDate = System.today();
        opp.StageName = 'Decision';
        opp.Opportunity_Status__c = 'Credit - In Queue';
        opp.AccountId = acc.Id;
        opp.Equipment_Cost__c = 12345;
        opp.Equipment_Description__c = 'test';
        opp.Terms__c = 60;
        opp.Approved_Amount__c = 5000;
        opp.Max_Term_Approved__c = 60;
        
        TC_RenderDecisionButtonCtrl.RenderDecisionWrapper wrapper= new TC_RenderDecisionButtonCtrl.RenderDecisionWrapper();
        wrapper.opp = opp;
        wrapper.fraudFlag = True;
        
        list<string> errorList1 = new list<string>();
        //errorList1.add('Assigned Credit User must be populated.');
        wrapper.errorList = errorList1;
        wrapper.confirmActionStep = True;
        wrapper.supplementalCodes = True; 
        
        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];
        
        System.runAs(u) {
            Test.startTest();
            insert opp;
            Resubmission_to_Credit_Details__c rcd = new Resubmission_to_Credit_Details__c();
            rcd.Opportunity__c = opp.Id;
            rcd.Appeal_Type__c = '1st';
            insert rcd;
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            TC_RenderDecisionButtonCtrl.finalOppUpdate(wrapper);
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testFinalOppUpdateWithTryCatch() {
        User u = [SELECT Id,Credit_Authority__c FROM User WHERE Username = 'standardusertest123@northteq.com'];
        TC_RenderDecisionButtonCtrl.RenderDecisionWrapper wrapper= new TC_RenderDecisionButtonCtrl.RenderDecisionWrapper();
        opportunity opp = [SELECT Id, Name, OwnerId, Assigned_Credit_User__c,Reason_for_Approval__c,Terms__c, Max_Term_Approved__c, 
                           Originally_Decisioned_By__c, Policy_Exception__c,Decisioned_By__c,Credit_Decision__c, Resubmitted_to_Credit__c, Decision_Status__c, Application_Status__c,
                           SFP_Tier_2_Credit_Box__c, SFP_Tier_2_Status__c, SIC_Code__c, Approved_Amount__c, OFAC_Result__c, Branch__c, Equip_Code1__c,Months_in_Profession__c, 
                           Fraud_Flag__c, Fraud_Review_Status__c, SFP2_In_Process__c, Total_Exposure__c,Credit_Amount__c, Decline_Reason__c,
                           FraudReviewFlag__c,Application__c, StageName, Opportunity_Status__c,Loan_Record_Type__c FROM Opportunity LIMIT 1];
        opp.FraudReviewFlag__c = 1 ;
        opp.Decision_Status__c = 'A';
        //opp.Decision_Status__c = 'R';
        opp.Fraud_Review_Status__c = 'Rejected';
        //opp.Decline_Reason__c = 'Auto-Reject';
        Update opp;
        wrapper.opp = opp;
        system.debug('Updated opportunity : '+opp);
        
        wrapper.fraudFlag = True;
        list<string> errorList1 = new list<string>();
        wrapper.errorList = errorList1;
        wrapper.confirmActionStep = True;
        wrapper.supplementalCodes = True;
        
        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            try{
                TC_RenderDecisionButtonCtrl.renderDecision(wrapper);
            }catch  (exception e){
            }
            Test.stopTest();
        }
    }
    @IsTest
    static void testFinalOppUpdateWithDecisionMTryCatch() {
        User u = [SELECT Id,Credit_Authority__c FROM User WHERE Username = 'standardusertest123@northteq.com'];
        TC_RenderDecisionButtonCtrl.RenderDecisionWrapper wrapper= new TC_RenderDecisionButtonCtrl.RenderDecisionWrapper();
        opportunity opp = [SELECT Id, Name, OwnerId, Assigned_Credit_User__c,Reason_for_Approval__c,Terms__c, Max_Term_Approved__c, 
                           Originally_Decisioned_By__c, Policy_Exception__c,Decisioned_By__c,Credit_Decision__c, Resubmitted_to_Credit__c, Decision_Status__c, Application_Status__c,
                           SFP_Tier_2_Credit_Box__c, SFP_Tier_2_Status__c, SIC_Code__c, Approved_Amount__c, OFAC_Result__c, Branch__c, Equip_Code1__c,Months_in_Profession__c, 
                           Fraud_Flag__c, Fraud_Review_Status__c, SFP2_In_Process__c, Total_Exposure__c,Credit_Amount__c, Decline_Reason__c,
                           FraudReviewFlag__c,Application__c, StageName, Opportunity_Status__c,Loan_Record_Type__c FROM Opportunity LIMIT 1];
        opp.FraudReviewFlag__c = 1 ;
        opp.Decision_Status__c = 'M';
        opp.Fraud_Review_Status__c = 'Rejected';
        opp.Reason_for_Approval__c = 'Approved with Supplemental Information';
        Update opp;
        wrapper.opp = opp;    
        wrapper.fraudFlag = True;
        list<string> errorList1 = new list<string>();
        wrapper.errorList = errorList1;
        wrapper.confirmActionStep = True;
        wrapper.supplementalCodes = True;
        
        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            try{
                TC_RenderDecisionButtonCtrl.renderDecision(wrapper);
            }catch  (exception e){
            }
            Test.stopTest();
        }
    }
    @IsTest
    static void testRenderDecisionApprovedAmount() {
        User u = [SELECT Id,Credit_Authority__c FROM User WHERE Username = 'standardusertest123@northteq.com'];
        TC_RenderDecisionButtonCtrl.RenderDecisionWrapper wrapper= new TC_RenderDecisionButtonCtrl.RenderDecisionWrapper();
        opportunity opp = [SELECT Id, Name, OwnerId, Assigned_Credit_User__c,Reason_for_Approval__c,Terms__c, Max_Term_Approved__c, 
                           Originally_Decisioned_By__c, Policy_Exception__c,Decisioned_By__c,Credit_Decision__c, Resubmitted_to_Credit__c, Decision_Status__c, Application_Status__c,
                           SFP_Tier_2_Credit_Box__c, SFP_Tier_2_Status__c, SIC_Code__c, Approved_Amount__c, OFAC_Result__c, Branch__c, Equip_Code1__c,Months_in_Profession__c, 
                           Fraud_Flag__c, Fraud_Review_Status__c, SFP2_In_Process__c, Total_Exposure__c,Credit_Amount__c, Decline_Reason__c,
                           FraudReviewFlag__c,Application__c, StageName, Opportunity_Status__c,Loan_Record_Type__c FROM Opportunity LIMIT 1];
        opp.FraudReviewFlag__c = 1 ;
        opp.Decision_Status__c = 'A';
        opp.Fraud_Review_Status__c = 'Rejected';
        opp.Approved_Amount__c = 10000;
        opp.Credit_Amount__c = 5000;
        opp.Total_Exposure__c = 2000;
        Update opp;
        wrapper.opp = opp;
        wrapper.fraudFlag = True;
        list<string> errorList1 = new list<string>();
        wrapper.errorList = errorList1;
        wrapper.confirmActionStep = True;
        wrapper.supplementalCodes = True;
        
        System.runAs(u) {
            Test.startTest();
            Id oppId = [SELECT Id FROM Opportunity][0].Id;
            try{
                TC_RenderDecisionButtonCtrl.renderDecision(wrapper);
            }catch  (exception e){
            }
            Test.stopTest();
        }
    }
}