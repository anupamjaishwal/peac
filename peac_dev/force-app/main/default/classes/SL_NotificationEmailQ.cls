public with sharing class SL_NotificationEmailQ implements Queueable {
    public Map<Id, Opportunity> oldMap;
    public Map<Id, Opportunity> newMap;
    public String emailNotification;

    public SL_NotificationEmailQ(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, String emailNotification) {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.emailNotification = emailNotification;
    }

    public void execute(QueueableContext context) {
        switch on emailNotification {
            when 'Submitted' {
                TC_SendDealerNotification.submissionNotification(oldMap, newMap);
            }
            when 'Approved' {
                TC_SendDealerNotification.approvalNotification(oldMap, newMap);
            }
            when 'Rejected' {
                TC_SendDealerNotification.declinedNotification(oldMap, newMap);
            }
            when 'More Info' {
                TC_SendDealerNotification.moreInfoNotification(oldMap, newMap);
            }
            when 'Submitted Loan' {
                TC_SendLoanNotifications.checkNotificationCenter(newMap, 'Submitted_Loan__c', 'Loan Submitted');
            }
        }
    }
}