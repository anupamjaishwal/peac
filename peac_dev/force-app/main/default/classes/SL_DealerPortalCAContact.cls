public without sharing class SL_DealerPortalCAContact {
    @invocableMethod(label='Upsert Contact for App')
    public static List<Contact> upsertContactForApp(List<Contact> contacts){
        Contact theContact = contacts[0];
        
        SL_DealerPortalCAAllowSave.shareDealerAccount();
        if(theContact.Id == null){
          upsert theContact;
        }
        return new List<Contact>{theContact};
    }
}