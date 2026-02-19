/**
 * Created on 1/1/18.
 */
({
    handleSameAddress : function (cmp, event, helper) {
        if (cmp.find("sameAsCompanyAddress").get("v.checked")) {
            var guarantor = cmp.get("v.guarantor");
            var company = cmp.get("v.company");

            // Loan
            if (cmp.get ('v.clientWrapper.recordTypeName') == 'Loan') {

                guarantor.OtherStreet = company.BillingStreet;
                            guarantor.OtherCity = company.BillingCity;
                            guarantor.OtherStateCode = company.BillingStateCode;
                            guarantor.OtherPostalCode = company.BillingPostalCode;
                            guarantor.OtherCountryCode = company.BillingCountryCode;

            } else {
                // Lease
                guarantor.MailingStreet = company.BillingStreet;
                            guarantor.MailingCity = company.BillingCity;
                            guarantor.MailingStateCode = company.BillingStateCode;
                            guarantor.MailingPostalCode = company.BillingPostalCode;
                            guarantor.MailingCountryCode = company.BillingCountryCode;
            }




            cmp.set("v.guarantor", guarantor);
        }
    },

    handleLookupChoose : function (cmp, event, helper) {
        var that = this;
        var guarId = event.getParam('recordId');

        console.log('selectGuarantor', guarId);

        if (guarId) {
            TCLightningUtils.showSpinner(cmp);
            var action;
            if (event.getParam('objectAPIName') == 'Account') {
                action = cmp.get('c.selectGuarantorAccount');
            } else {
                action = cmp.get('c.selectGuarantor');
            }


            action.setParams({
                guarantorId: guarId
            });

            action.setCallback(this, function (result) {
                TCLightningUtils.hideSpinner(cmp);

                if (result.getState() == 'SUCCESS') {

                    var guarantor = result.getReturnValue();
                    var oldGuar;
                    if (event.getParam('objectAPIName') == 'Account') {
                        oldGuar = cmp.get('v.guarantor.account');
                    } else {
                        oldGuar = cmp.get('v.guarantor.contact');
                    }

                    for (var g in guarantor) {
                        oldGuar[g] = guarantor[g];
                    }

                    console.table ( oldGuar);

                    if (event.getParam('objectAPIName') == 'Account') {
                        cmp.set('v.guarantor.account', oldGuar);
                        cmp.set('v.guarantor.readOnly', true);
                        cmp.set('v.guarantor.dupe', false);
                    } else {
                        cmp.set('v.guarantor.contact', oldGuar);
                        cmp.set('v.ssn', '*****'+String(oldGuar.SSNMain__c).slice(-4));
                        cmp.set('v.guarantor.readOnly', true);
                        cmp.set('v.guarantor.dupe', false);
                    }


                } else {
                    console.log(result.getError());
                    TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                }
            });

            $A.enqueueAction(action);
        }
    },

    //Function to handle the LookupChooseEvent. Sets the chosen record.
        handleChooseCTRL: function (cmp, event, helper) {

            if (event.getParam('objectAPIName') == 'Account') {
                helper.selectCompany(cmp, event);
            }

            if (event.getParam('objectAPIName') == 'Contact') {
                helper.selectContact(cmp, event);
            }
        },
})