/** @author : Northteq Consulting, Inc.
 * @date : 2/5/21
 * @description: Handles scheduling email notifications on the Opportunity for when they need to be delayed.
 * SAL-2105
 */
public with sharing class TC_NotificationEmailBatch implements Database.Batchable<Opportunity> {

    public Map<Id, Opportunity> oldMap;
    public Map<Id, Opportunity> newMap;
    public String emailNotification;

    /**
     * Constructor for the class to store items in memory.
     * @param oldMap The old map of opportunities
     * @param newMap The new map of opportunities
     * @param emailNotification The email notification that should be sent
     */
    public TC_NotificationEmailBatch(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, String emailNotification) {

        this.oldMap = oldMap;
        this.newMap = newMap;
        this.emailNotification = emailNotification;
    }

    /**
     * This method determines which email notification to send. It does not utilize batchable context or the list of
     * opportunities; those are required in Apex.
     * @param bc Batchable context
     * @param opportunities a list of opportunities
     */
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities) {

        System.debug('TC_NotificationEmailBatch execute');
        String replaced = 'by Queueable';
        // SAL-5496 Misael Romero
        // switch on emailNotification {
        //     when 'Submitted' {
        //         TC_SendDealerNotification.submissionNotification(oldMap, newMap);
        //     }
        //     when 'Approved' {
        //         TC_SendDealerNotification.approvalNotification(oldMap, newMap);
        //     }
        //     when 'Rejected' {
        //         TC_SendDealerNotification.declinedNotification(oldMap, newMap);
        //     }
        //     when 'More Info' {
        //         TC_SendDealerNotification.moreInfoNotification(oldMap, newMap);
        //     }
        //     when 'Submitted Loan' {
        //         TC_SendLoanNotifications.checkNotificationCenter(newMap, 'Submitted_Loan__c', 'Loan Submitted');
        //     }
        // }
    }

    /**
     * This method comes default with batchable classes, but for this use case, it does not do anything.
     * @param bc Batchable context
     */
    public void finish(Database.BatchableContext bc) {}

    /**
     * This method simply returns newMap.values because Salesforce requires something to be returned. It doesn't have
     * any purpose in this use case; it's simply a default method that comes with batchable classes.
     * @param bc Batchable context
     * @return a list of opportunities
     */
    public List<Opportunity> start(Database.BatchableContext bc) {
        return newMap.values();
    }
}