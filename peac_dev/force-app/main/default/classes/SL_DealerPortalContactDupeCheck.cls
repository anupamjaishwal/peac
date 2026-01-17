public without sharing class SL_DealerPortalContactDupeCheck {
/* Created by: Carlos Herrera
 * Date: 8/31/2023
 * This class was made with the pourpose of doing a duplicate check on the Contact Object
 * Used on the flow "Create Application Contact Info"
 * Last Modified by:
 * Last Modified on:
 */
    @invocableMethod(label='Email Duplicate Check')
    public static List<Contact> EmailDuplicateCheck(List<Contact>contacts){
        contact theContact = contacts[0];       
        
        String EmailtoCheck = theContact.Email;
        if(EmailtoCheck != null){
            Id existingContactId = SL_DealerPortalCreateApp.getDupeId(theContact);
            if(existingContactId != null){
                theContact.Id = existingContactId;
            }
        }
        return new List<Contact>{theContact};
    }
}