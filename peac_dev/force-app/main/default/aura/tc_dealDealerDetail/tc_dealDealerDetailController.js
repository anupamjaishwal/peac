/**
 * Created by andrewmayer on 1/10/19.
 */
({
    //Function to handle the LookupChooseEvent. Sets the chosen record.
    handleChoosePartnerCTRL: function (cmp, event, helper) {

            if (event.getParam('objectAPIName') == 'Account') {
                helper.selectPartnerCompany(cmp, event);
            }

            if (event.getParam('objectAPIName') == 'Contact') {
                helper.selectPartnerContact(cmp, event);
            }
        },
        contactLastNameChanged : function (cmp, event, helper) {
  
            if (cmp.get ('v.partner.subRecord.contact.LastName') != null && cmp.get ('v.partner.subRecord.contact.LastName') != '') {
                    cmp.set ('v.contactFieldsRequired', true);
                } else {
                    cmp.set ('v.contactFieldsRequired', false);
                }

            	
            },

        handleProgramChange : function(component, event, helper) {
            var recordId = event.getParam('value');
            var partner  = component.get('v.partner');

            // partner.dealer holds the Dealer__c junction fields
            if (!partner.dealer) partner.dealer = {};
            partner.dealer.Program__c = recordId;

            component.set('v.partner', partner);
        },
})