public without sharing class SL_DealerPortalCAAllowSave {
    @invocableMethod(label='Update Opportunity')
    public static List<Opportunity> updateOpp(List<AllowSaveParams> params){
        Opportunity o = params[0].opportunity;
        Boolean updOpp = params[0].isToUpdateOpp;
        shareDealerAccount();
        if(updOpp){
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            if(o.Id == null){
                Database.SaveResult sr = Database.insert(o,dml);
            }else{
                Database.SaveResult sr = Database.update(o,dml);
            }
        }else{
            // DP-2080 Misael Romero
            Id uid = System.UserInfo.getUserId();
            Set<Id> duIds = new Set<Id>();
            if(o.Dealer_User__c != null){
                duIds.add(o.Dealer_User__c);
            }
            duIds.add(uid);
            Map<Id, User> duRecs = new Map<Id, User>([SELECT Id, IsActive, Contact.AccountId, Contact.Account.OwnerId, Contact.Account.Dealer_Tier__c 
                FROM User WHERE Id IN :duIds]);
            User ui = duRecs.get(uid);
            if(duRecs.get(o.Dealer_User__c) != null && duRecs.get(o.Dealer_User__c).IsActive){
                ui = duRecs.get(o.Dealer_User__c);
            }
            if(ui != null){
                o.Dealer_User__c = ui.Id;
                List<Dealer__c> ds = [SELECT Id, Dealer__c FROM Dealer__c WHERE Opportunity__c = :o.Id AND Primary_Dealer__c = true];
                Boolean nd = false;
                if(ds.size() == 1){
                    if(ds[0].Dealer__c != ui.Contact.AccountId){
                        delete ds[0];
                        nd = true;
                    }
                }else{
                    nd = true;
                }
                if(nd){
                    insert new Dealer__c(Dealer__c = ui.Contact.AccountId, Primary_Dealer__c = true, Opportunity__c = o.Id);
                }
                o.Dealer_Account__c = ui.Contact.AccountId;
                o.OwnerId = ui.Contact.Account.OwnerId;
                o.Dealer_Tier__c = ui.Contact.Account.Dealer_Tier__c;
            }
        }
        return new List<Opportunity>{o};
    }

    public static void shareDealerAccount(){
        User theUser = [SELECT Id, Contact.AccountId FROM User WHERE Id = :System.UserInfo.getUserId() LIMIT 1];
        Boolean isEditable = false;
        List<AccountShare> sharesWithUser = [SELECT Id, AccountAccessLevel FROM AccountShare 
            WHERE AccountId = :theUser.Contact.AccountId AND UserOrGroupId = :theUser.Id];
        if(sharesWithUser.size() > 0){
            for(AccountShare accShare :sharesWithUser){
                if(accShare.AccountAccessLevel == 'Edit'){
                    isEditable = true;
                }
            }
        }
        if(!isEditable && theUser.Contact.AccountId != null){
            insert new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', CaseAccessLevel = 'None',
                RowCause = 'Manual', AccountId = theUser.Contact.AccountId, UserOrGroupId = theUser.Id);
        }
    }

    public class AllowSaveParams {
        @InvocableVariable(required=true)
        public Opportunity opportunity;
        @InvocableVariable(required=true)
        public Boolean isToUpdateOpp;
    }
}