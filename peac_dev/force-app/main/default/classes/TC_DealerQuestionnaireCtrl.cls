/**
 * Created by szheng on 4/27/20.
 */

public with sharing class TC_DealerQuestionnaireCtrl {

    @AuraEnabled
    public Boolean readMode {get; set;}
    @AuraEnabled
    public Account account {get; set;}
    public TC_DealerQuestionnaireCtrl(Account account) {
        this.account = account;
    }
    public TC_DealerQuestionnaireCtrl() {}

    @AuraEnabled
    public static TC_DealerQuestionnaireCtrl questionnaireInit(Id recordId) {
        List<Account> accList = new List<Account>([
                SELECT Owner.Profile.Name, Dealer_Number__c, Review_For__c, RecordType.Name
                        , Service__c, Delivery__c, Sales_Reps_Questionnaire__c, Location__c, Online_tools__c, Volume__c
                        , Service_Term__c, Service_Provider__c, Manufacturer_ISP__c, Hosted_Solution__c, Proprietary__c
                        , Purchased_Services__c, Percentage_of_Service__c, Alternative_Provider__c, Pro_Rata__c, Sales_Reps_1099__c
                        , Dealer_Service_Based__c, New_Dealer_Service_Based__c, DM_Review_Status__c, Dealer_Questionnaire_Required__c, Dealer_Questionnaire_Complete__c
                FROM Account
                WHERE Id =: recordId]);
        if (accList.isEmpty()) throw new TC_DealerQuestionnaireCtrlException('Invalid recordId provided. No questionnaire available.');

        Account account = accList[0];
        TC_DealerQuestionnaireCtrl wrapper = new TC_DealerQuestionnaireCtrl(account);
        wrapper.readMode = account.Owner.Profile.Name.contains('Management') ? false : (account.DM_Review_Status__c == 'Submitted for Review' || account.DM_Review_Status__c == 'Completed');
        return wrapper;
    }

    @AuraEnabled
    public static TC_DealerQuestionnaireCtrl updateAccount(TC_DealerQuestionnaireCtrl wrapper) {
        update wrapper.account;
        return wrapper;
    }

    public class TC_DealerQuestionnaireCtrlException extends Exception {}

}