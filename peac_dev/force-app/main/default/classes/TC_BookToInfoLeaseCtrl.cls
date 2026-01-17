public class TC_BookToInfoLeaseCtrl {

    public static void sendPartiesToInfoLeaseFromProcess (String recordId) {
        
        // fire off platform event to run gds after infolease call is done
        
        try {
            List<Contact> updateContacts = TC_BWcreateCustomerCtrl.checkAndUpdateILContacts(recordId);
            List<Account> updateAccounts = TC_BWcreateCustomerCtrl.checkAndUpdateILAccounts(recordId);
            
            update updateContacts;
            update updateAccounts;
            
            EventBus.publish(new GDS_Action__e (Action__c = Label.TC_Gds_GdsScore, Record_Id__c = recordId));
        } catch (Exception e) {
            // handle error
            // fire error event. Error during infolease
        }
        
    }
    
    @AuraEnabled
    public static TC_BridgewareBookContractRespBean bookToInfoLease(String recordId) {
        try {
            System.debug ('#$#$#$ bookToInfoLease');

            List<Contact> updateContacts = TC_BWcreateCustomerCtrl.checkAndUpdateILContacts(recordId);
            List<Account> updateAccounts = TC_BWcreateCustomerCtrl.checkAndUpdateILAccounts(recordId);
            
            Map<Id, String> ccanById = new Map<Id, String>();
            for (Account a : updateAccounts) {
                System.debug(a);
                ccanById.put(a.Id, a.CCAN__c);
            }
            for (Contact c : updateContacts) {
                System.debug(c);
                ccanById.put(c.Id, c.Contact_CCAN__c);
            }
            System.debug ('#$#$#$ ccanById' + ccanById);
            TC_BridgewareBookContractRespBean response = TC_BridgewareUtility.sendToBridgeware(recordId, ccanById);
            update new Opportunity(Id = recordId, Sent_to_InfoLease_Date_Time__c = null);
            if (!updateContacts.isEmpty()) update updateContacts;
            if (!updateAccounts.isEmpty()) update updateAccounts;

            response.opportunityStage = [SELECT StageName FROM Opportunity WHERE Id = :recordId].StageName;
            return response;
        } catch(TC_BridgewareUtility.TC_BridgewareUtilityException ex) {
            update new Opportunity(Id = recordId, Sent_to_InfoLease_Date_Time__c = null);
            
            TC_BridgewareBookContractRespBean resp = new TC_BridgewareBookContractRespBean();
            resp.responseMessageDesc = ex.getMessage();
            return resp;
        } catch(Exception ex) {
            MARLIN_IntegrationLog.addLog('Infolease Create Customer', '', 'Error', '', '', '', ex.getMessage());
            System.debug(ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
            
        } finally {
            // new added logging
            MARLIN_IntegrationLog.insertLogs ();
        }
    }
     
    @AuraEnabled
    public static void updateSentDate(String recordId) {
        if ([SELECT Sent_to_InfoLease_Date_Time__c FROM Opportunity WHERE Id = :recordId].Sent_to_InfoLease_Date_Time__c != null)
            throw new AuraHandledException('This application was already sent to InfoLease but no response has been returned yet. If the issue persists, please contact an admin to resolve the issue.');
        
        try {
            update new Opportunity(Id = recordId, Sent_to_InfoLease_Date_Time__c = System.now());
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateSubmissionCriteria (String recordId) {
        Opportunity opp = [SELECT Sent_to_InfoLease_Date_Time__c, Equipment_Cost__c, Loan_Record_Type__c FROM Opportunity WHERE Id = :recordId][0];

        if (opp.Sent_to_InfoLease_Date_Time__c != null){
            return 'alreadySubmitted';
        }else if (!opp.Loan_Record_Type__c && opp.Equipment_Cost__c != null && opp.Equipment_Cost__c > 1000000){
            return 'costMillion';
        }else{
            return 'ok';
        }
    }
}