public without sharing class SL_DealerPortalCAContact {
    @invocableMethod(label='Upsert Contact for App')
    public static List<Contact> upsertContactForApp(List<Contact> contacts){
        Contact theContact = contacts[0];
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

        if(theContact.Id == null){
          upsert theContact;
        }
        return new List<Contact>{theContact};
    }
}