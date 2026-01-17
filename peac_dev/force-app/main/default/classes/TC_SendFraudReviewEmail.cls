/** 
 * @description Class to work as a trigger on Opportunity Sending the fraud email when meeting criteria
 * Created by: Trohweder 6/4/21
 * SAL-3139
 */
public with sharing class TC_SendFraudReviewEmail{

    public static List<String> customerVerification = new List<String>{'CustomerVerifications@marlincorp.com','BRay@peacsolutions.com', 'sakuthota@peacsolutions.com','vsuragani@peacsolutions.com'};
    public static List<String> ccEmails = new List<String>{'MGiordano@peacsolutions.com','BRay@peacsolutions.com','sakuthota@peacsolutions.com','vsuragani@peacsolutions.com'};

    /** 
     * @description Method to add to our trigger action through the mettadata
     * @param tc Context of the trigger to get old and new maps
     * 
     */
    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {

        System.debug(LoggingLevel.DEBUG, 'TC_SendFraudReviewEmail');
        sendFraudReviewEmail(oldMap, newMap);

    }

    /**
     * @description Sends the Fraud Review Email to certain recipients
     * @param newMap Context of the trigger to get old and new maps
     * @param oldMap Context of the trigger to get old and new maps
     * 
     */
    public static void sendFraudReviewEmail(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        for (Opportunity opp : newMap.values()){

            if(checkConditions(opp, oldMap.get(opp.Id))){

                String appNumber = opp.Application__c;
                String appName = opp.Name;
                String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+opp.Id;

                String subject = appNumber+ ' Ready for Review';
                String body = 'The application#'+ appNumber +', '+ appName +', is in the Fraud Queue and ready for Fraud Review. '+ recordLink;
                try {
                    // Create and send email to Customer Verification Email box
                    List<Messaging.SendEmailResult> sentCustomerVerifyEmail = TC_EmailUtil.sendEmailNotification(customerVerification, null, opp.Id, null, subject, body, label.Org_Wide_Email_Id_Marlin_No_Reply, null, null);
                    System.debug(LoggingLevel.DEBUG, 'sentCustomerVerifyEmail Successful: '+sentCustomerVerifyEmail[0].isSuccess());
                    System.debug(LoggingLevel.DEBUG, 'sentCustomerVerifyEmail Errors: '+sentCustomerVerifyEmail[0].getErrors());

                    // Create and send email to Sales Rep
                    subject = appNumber +', '+appName;
                    body = 'The application#'+ appNumber +', '+ appName +', is under Further Identity Verification. Please contact your CVP Analyst for questions. '+recordLink;
                    List<Messaging.SendEmailResult> sentSalesRepEmail = TC_EmailUtil.sendEmailNotification(null, ccEmails, opp.Id, opp.OwnerId, subject, body, label.Org_Wide_Email_Id_Marlin_No_Reply, null, null);
                    System.debug(LoggingLevel.DEBUG, 'sentSalesRepEmail Successful: '+sentSalesRepEmail[0].isSuccess());

                } catch (EmailException e) {
                    System.debug(LoggingLevel.DEBUG, 'Error: '+e.getMessage());
                    System.debug(LoggingLevel.DEBUG, e.getStackTraceString());
                    AuraHandledException ahe = new AuraHandledException(e.getMessage());                    
                    if (e.getMessage().contains('INVALID_EMAIL_ADDRESS')) {
                        ahe.setMessage('Please confirm the owner\'s email address is valid/correct and try again.');
                    }
                    throw ahe;
                }
            }
        }
    }

    private static Boolean checkConditions(Opportunity opp, Opportunity oldOpp){
        Boolean sendEmail = false;


        if(opp.FraudReviewFlag__c != oldOpp.FraudReviewFlag__c || opp.Decision_Status__c != oldOpp.Decision_Status__c){

            if(opp.FraudReviewFlag__c == 1 && opp.Decision_Status__c == 'A' && 
            opp.StageName == 'Decision' && opp.Application_Status__c == 'Pending Decision' &&
            opp.Opportunity_Status__c == 'Fraud Review' &&
            opp.Reason_for_Approval__c == 'Instant Auto Decision'){
                sendEmail = true;
            }
        }

        return sendEmail;

    }
}