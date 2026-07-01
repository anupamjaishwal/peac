/**
 * Created by andrewmayer on 1/10/19.
 */
({
    selectPartnerCompany: function (cmp, event) {

            var companyId = event.getParam('recordId');

            if (companyId) {
                console.log('selectCompany');
                TCLightningUtils.showSpinner(cmp);
                var action = cmp.get('c.selectCompany');

                action.setParams({
                    companyId: companyId
                });

                action.setCallback(this, function (result) {
                    TCLightningUtils.hideSpinner(cmp);

                    if (result.getState() == 'SUCCESS') {

                                                var clientWrapper = cmp.get('v.clientWrapper');
                        var oppProgramId  = clientWrapper &&
                                            clientWrapper.deal &&
                                            clientWrapper.deal.opportunity &&
                                            clientWrapper.deal.opportunity.Program_Lookup__c;

                    console.log('34',JSON.stringify(oppProgramId));
                    console.log('clientWrapper.deal.opportunity.Program_Lookup__c', JSON.stringify(clientWrapper.deal.opportunity.Program_Lookup__c));


                        if (oppProgramId != null) {
                            // Opp already has a program — lock the LWC and pre-save to dealer
                            cmp.set('v.oppProgramIdSet', true);

                            // Also write it to the dealer object right away so it gets saved
                            // even if the user never interacts with the field
                            var partner = cmp.get('v.partner');
                            if (!partner.dealer) partner.dealer = {};
                            partner.dealer.Program__c = oppProgramId;
                            cmp.set('v.partner', partner);
                        }
                        var company = result.getReturnValue();
                        //console.log('company::'+JSON.stringify(company));
                        //cmp.set ('v.companyDupeOnSave', false);
                        cmp.set('v.partner.account', company);
                        cmp.set('v.partner.readOnly', true);
                        cmp.set('v.partner.dupe', false);




                            

                    } else {
                        console.log(result.getError());
                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                    }
                });
                $A.enqueueAction(action);
            }
        },

        selectPartnerContact: function (cmp, event) {


                var conId = event.getParam('recordId');

                if (conId) {
                    console.log('selectContact');
                    TCLightningUtils.showSpinner(cmp);
                    var action = cmp.get('c.selectGuarantor');

                    action.setParams({
                        guarantorId: conId
                    });

                    action.setCallback(this, function (result) {
                        TCLightningUtils.hideSpinner(cmp);

                        if (result.getState() == 'SUCCESS') {
                            var contact = result.getReturnValue();
                            cmp.set('v.partner.subRecord.contact', contact);
                            cmp.set('v.partner.subRecord.readOnly', true);
                            cmp.set('v.partner.subRecord.dupe', false);
                        } else {
                            console.log(result.getError());
                            TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                        }
                    });
                    $A.enqueueAction(action);
                }
            },
})