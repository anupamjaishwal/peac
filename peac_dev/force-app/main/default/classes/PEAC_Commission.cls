public without sharing class PEAC_Commission {
    //SAL-5818 : Split Commission rates
    //addCommission method is to insert commission record
    public static string addCommission (String OppID, String Salesrep ) {
        Commissions__c commission = new Commissions__c();
        commission.opportunity__c = oppID;
        commission.sales_rep__c = Salesrep;
        Boolean Com_Exist = [SELECT Id FROM Commissions__c WHERE opportunity__c =: oppID ].size() > 0;
        if (!Com_Exist) {
            Database.insert (commission,false,AccessLevel.SYSTEM_MODE);     
        } 
        system.debug('commission:: '+commission.id);
        return commission.id;
    }
}