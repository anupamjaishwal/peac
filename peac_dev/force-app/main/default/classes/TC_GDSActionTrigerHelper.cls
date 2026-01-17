public class TC_GDSActionTrigerHelper {
    public static void processActions (List <GDS_Action__e> actions) {
        System.debug ('user last name: ' + UserInfo.getLastName());
        Set<Id> processedIds = new Set<Id>();

        for (GDS_Action__e action : actions) {
            //skip duplicates in same event batch
            if (processedIds.contains(action.Record_Id__c)) {
                continue;
            }
            processedIds.add(action.Record_Id__c);

            // Lease App 
            if (action.Action__c == Label.TC_Gds_Infolease) {
                System.enqueueJob (new TC_CreateCustomerInfoleaseQueueable (action.Record_Id__c ));
            } else if (action.Action__c == Label.TC_Gds_GdsScore) {
                System.enqueueJob (new TC_GDSScoreQueueable (action.Record_Id__c ));
            } else if (action.Action__c == Label.TC_Gds_AppNumber) {
                System.enqueueJob (new TC_AutoNumberQueueable (action.Record_Id__c ));
            } else if (action.Action__c == Label.TC_GDS_Get_Dealer_InfoLease || action.Action__c == Label.TC_GDS_Get_Dealer) {
                System.enqueueJob(new TC_GDSDealerQueueable(action.Record_Id__c, action.Action__c));
            }
        
            // Loan App Actions
            else if (PEAC_ConstantClass.actionCallTypeMap.containsKey(action.Action__c)) {
                System.enqueueJob(new PEAC_LoanAppProcessor(action.Action__c, action.Record_Id__c));
            }
        }
    }
}