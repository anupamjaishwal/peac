public abstract class TC_LockRuleAbstract {
    
    // maybe break these out into their own class to make more generic, swap between roles and profiles due to changing requirements
    private static Final Set <String> LOCKABLE_STAGES = new Set <String> {'Decision', 'Proposal', 'Docs Requested', 'Docs Out', 'Docs In', 'Booking', 'Funding', 'Funded/Booked', 'Lost'};
    private static Final Set <String> CREDIT_ROLES = new Set <String> {'Credit Analyst', 'Credit Manager', 'Credit VP', 'CVP Analyst'};
    private static Final Set <String> SALES_MANAGEMENT_ROLES = new Set <String>{
            'CapitalMarket Manager', 'CVG Manager', 'Express Manager', 'Funding Stream Manager', 'HKF Manager', 'Program Manager', 'Retail Manager', 'Specialty Manager'
    };
    private static Final ORE__c ore = ORE__c.getOrgDefaults ();
    private static Final Set <String> LOCKABLE_APP_STATUS = new Set <String> {'Automatically Approved', 'Manually Approved'};
    
        
    // override
    public abstract void doCheck (TC_TriggerParams params);
    
    // checks if opp is in a lockable stage
    public Boolean inLockableStage (Opportunity opp) {
        return LOCKABLE_STAGES.contains(opp.StageName) && LOCKABLE_APP_STATUS.contains(opp.Application_Status__c);
    }
    
    // checks if a user has a credit role
    public Boolean isCreditUser (User user) {
        return CREDIT_ROLES.contains (user.UserRole.Name);
    }
    

    public Boolean isSalesManagementUser (User user) {
        return SALES_MANAGEMENT_ROLES.contains (user.UserRole.Name);
    }
    
    
    public Boolean alwaysExcludedFromRules (User user) {
        return user.LastName.contains ('Process') || ore.Bypass__c || user.profile.Name.toLowerCase().contains ('admin');
    }
    
    public User getCurrentUser () {
        return [SELECT UserRole.Name, LastName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()][0];
    }
    
    public Map <Id, Opportunity> getOppMap (Set <Id> oppIds) {
        return new Map <Id, Opportunity> ([SELECT Id, StageName, Loan_Record_Type__c, Application_Status__c, Channel__c, No_of_Broker__c, No_of_Franchisors__c, (SELECT Id, Account_Name__c FROM Brokers__r)  FROM Opportunity WHERE Id IN :oppIds]);
    }
    
    public Map <Id, Account> getAccMap (Set <Id> accIds) {
        return new Map <Id, Account> ([SELECT Id, Account_Dealer_Status__c, Override_Sales_Lockdown_Restrictions__c  FROM Account WHERE Id IN :accIds]);
    }
    
    public List <SObject> getFilteredList (TC_TriggerParams params) {
        
        List <SObject> results = new List <SObject> ();
        
        if (params.getOldMap() != null && params.getNewMap() != null) {
            // update
            for (SObject sobj : params.getNewMap().values ()) {
                if (sobj != params.getOldMap().get (sobj.Id)) results.add (sobj);
            }
        } else if (params.getOldMap() == null && params.getNewList() != null) {
            // insert
            results.addAll (params.getNewList());
        } else if (params.getOldMap() != null && params.getNewMap() == null) {
            // delete
            results.addAll (params.getOldMap().values());
        }
        return results;
    }

}