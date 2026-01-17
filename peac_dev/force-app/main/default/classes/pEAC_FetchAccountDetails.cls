public class pEAC_FetchAccountDetails {
    @AuraEnabled(cacheable=true)
    public static Account getFastTrackURL(){
    system.debug('FastTrackURL:');
        Account acc;
        USer u = [SELECT Id, ContactId FROM User WHERE ID = :userInfo.getUSerId()];
        for(Contact con : [SELECT Id, Account.EF_Partner_UDA_URL__c, Account.Name FROM Contact WHERE Id = :u.ContactId]){
            acc = con.Account;
        }
        return acc;
    }
}