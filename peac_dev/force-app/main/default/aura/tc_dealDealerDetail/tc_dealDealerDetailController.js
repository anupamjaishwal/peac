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

        doInit : function(component, event, helper) {
            var clientWrapper = component.get('v.clientWrapper');
            var oppProgramId  = clientWrapper &&
                                clientWrapper.deal &&
                                clientWrapper.deal.opportunity &&
                                clientWrapper.deal.opportunity.Program_Lookup__c;

        console.log('34',JSON.stringify(oppProgramId));
        console.log('clientWrapper.deal.opportunity.Program_Lookup__c', JSON.stringify(clientWrapper.deal.opportunity.Program_Lookup__c));


            if (oppProgramId != null) {
                // Opp already has a program — lock the LWC and pre-save to dealer
                component.set('v.oppProgramIdSet', true);

                // Also write it to the dealer object right away so it gets saved
                // even if the user never interacts with the field
                var partner = component.get('v.partner');
                if (!partner.dealer) partner.dealer = {};
                partner.dealer.Program__c = oppProgramId;
                component.set('v.partner', partner);
            }
        },

        handleProgramChange : function(component, event, helper) {

            var clientWrapper = component.get('v.clientWrapper');
            var oppProgramId  = clientWrapper &&
                                clientWrapper.deal &&
                                clientWrapper.deal.opportunity &&
                                clientWrapper.deal.opportunity.Program_Lookup__c;

            if (oppProgramId != null) {
                // Opp already has a program — lock the LWC and pre-save to dealer
                component.set('v.oppProgramIdSet', true);

                // Also write it to the dealer object right away so it gets saved
                // even if the user never interacts with the field
                var partner = component.get('v.partner');
                if (!partner.dealer) partner.dealer = {};
                partner.dealer.Program__c = oppProgramId;
                component.set('v.partner', partner);
            }
            else{
                var recordId = event.getParam('value');
                var partner  = component.get('v.partner');

                if (!partner.dealer) partner.dealer = {};
                partner.dealer.Program__c = recordId;

                component.set('v.partner', partner);

            }


        },
})