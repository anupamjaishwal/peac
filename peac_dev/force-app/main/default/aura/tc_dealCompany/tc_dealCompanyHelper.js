({
    quickSave: function (cmp, event, helper) {
        TCLightningUtils.showSpinner(cmp);
        var action;
        var company = cmp.get('v.clientWrapper.company.account');
        var contact = cmp.get('v.clientWrapper.contact.contact');


        // Customer Address Same as Contact
        // Copying the address info over before saving
        var customerAddressSameAsCompany = cmp.get ('v.customerAddressSameAsCompany');

        if (customerAddressSameAsCompany) {
            contact.MailingStreet = company.Business_Address__c;
            contact.MailingCity = company.Business_City__c;
            contact.MailingStateCode = company.Business_State__c;
            contact.MailingPostalCode = company.Business_Zip__c;

            contact.OtherStreet = company.Business_Address__c;
            contact.OtherCity = company.Business_City__c;
            contact.OtherStateCode = company.Business_State__c;
            contact.OtherPostalCode = company.Business_Zip__c;
        }

        if (company != null && contact != null && (contact.Phone == null || contact.Phone == '')) {
            contact.Phone == company.Phone;
        }

        /*if (company != null) {
            company.Business_Phone__c = company.Phone;
        }*/

        cmp.set ('v.clientWrapper.contact.contact', contact);
		


        action = cmp.get('c.saveCompany');

        //var clientObject = {company : cmp.get ('v.company'), companyCustomer : cmp.get ('v.contact')};
        cmp.set('v.clientWrapper.deal.opportunity.Pre_Approval__c', cmp.get('v.isPreApproval'))
        console.log(cmp.get('v.isPreApproval'))
        console.log(JSON.stringify(cmp.get ('v.clientWrapper.deal.opportunity')))

        action.setParams({
            clientWrapperString: JSON.stringify(cmp.get ('v.clientWrapper'))
        })

        action.setCallback(this, function (result) {
            TCLightningUtils.hideSpinner(cmp);
            if (result.getState() === 'SUCCESS') {

                var returnedValue = JSON.parse(result.getReturnValue());
                cmp.set ('v.clientWrapper', returnedValue);
                //cmp.set ('v.clientWrapper.contact', returnValue.contact);

                this.goToNextHelper ();


            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(action);
    },

    validateRecord: function (cmp, event, helper) {
        return true;
    },

    selectCompany: function (cmp, event) {

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
                    var company = result.getReturnValue();
                    //cmp.set ('v.companyDupeOnSave', false);
                    cmp.set('v.clientWrapper.company.account', company);
                    cmp.set('v.clientWrapper.company.readOnly', true);
                    cmp.set('v.clientWrapper.company.dupe', false);
                } else {
                    console.log(result.getError());
                    TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                }
            });
            $A.enqueueAction(action);
        }
    },

    selectContact: function (cmp, event) {

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
                        cmp.set('v.clientWrapper.contact.contact', contact);
                        cmp.set('v.clientWrapper.contact.readOnly', true);
                        cmp.set('v.clientWrapper.contact.dupe', false);
                        cmp.set ('v.customerAddressSameAsCompany', false);
                        console.log('get contact');
                        cmp.set("v.ssn", '*****'+String(contact.SSNMain__c).slice(-4));
                    } else {
                        console.log(result.getError());
                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                    }
                });
                $A.enqueueAction(action);
            }
        },
    goToNextHelper : function () {
        var navEvent = $A.get("e.c:tc_applicationNavigation_evt");
        var dir = "next";
        
        navEvent.setParams({
            data: {
                direction: dir
            }
        });
        
        navEvent.fire();
    },
    saveAndQuitHelper: function (cmp) {

        TCLightningUtils.showSpinner(cmp);
                    var saveAndQuitAction = cmp.get('c.submitApplication');



        // start new

        TCLightningUtils.showSpinner(cmp);
                var action;
                var company = cmp.get('v.clientWrapper.company.account');
                var contact = cmp.get('v.clientWrapper.contact.contact');


                var customerAddressSameAsCompany = cmp.get ('v.customerAddressSameAsCompany');

                        if (customerAddressSameAsCompany) {
                            contact.MailingStreet = company.Business_Address__c;
                            contact.MailingCity = company.Business_City__c;
                            contact.MailingStateCode = company.Business_State__c;
                            contact.MailingPostalCode = company.Business_Zip__c;

                            contact.OtherStreet = company.Business_Address__c;
                            contact.OtherCity = company.Business_City__c;
                            contact.OtherStateCode = company.Business_State__c;
                            contact.OtherPostalCode = company.Business_Zip__c;
                        }

                        if (company != null && contact != null && (contact.Phone == null || contact.Phone == '')) {
                            contact.Phone == company.Phone;
                        }

                /*if (company != null) {
                    company.Business_Phone__c = company.Phone;
                }*/

                cmp.set ('v.clientWrapper.contact.contact', contact);



                action = cmp.get('c.saveCompany');

                cmp.set('v.clientWrapper.deal.opportunity.Pre_Approval__c', cmp.get('v.isPreApproval'))

                //var clientObject = {company : cmp.get ('v.company'), companyCustomer : cmp.get ('v.contact')};

                action.setParams({
                    clientWrapperString: JSON.stringify(cmp.get ('v.clientWrapper'))
                })

                action.setCallback(this, function (result) {
                    TCLightningUtils.hideSpinner(cmp);
                    if (result.getState() === 'SUCCESS') {

                        TCLightningUtils.showSpinner(cmp);

                        var returnedValue = JSON.parse(result.getReturnValue());
                        cmp.set ('v.clientWrapper', returnedValue);
                        //cmp.set ('v.clientWrapper.contact', returnValue.contact);


                        // start new again

                        saveAndQuitAction.setParams({
                                                clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
                                            });

                                            saveAndQuitAction.setCallback(this, function (result) {
                                                console.log('action setCallback');
                                                TCLightningUtils.hideSpinner(cmp);
                                                if (result.getState() === 'SUCCESS') {
                                                    TCLightningUtils.showToast('Success', 'Deal Saved. Press the Edit Deal in Wizard button to return.', 'success');
                                                    console.log('>>>>NAVIGATION TO URL:' + result.getReturnValue());
                                                    $A.get("e.force:navigateToURL").setParams({ "url": "/" + result.getReturnValue()}).fire();
                                                    //this.navigateToHome();
                                                } else {
                                                    console.log(result.getError());
                                                    TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                                                }
                                            });


                        $A.enqueueAction(saveAndQuitAction);
                        // end new again


                    } else {
                        console.log(result.getError());
                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                    }
                });
                $A.enqueueAction(action);


        // end new




        },
    
    	contactRoleSelectedHelper : function (cmp, event, helper) {
        	cmp.set ('v.clientWrapper.contact.contact.role', cmp.find("contactRoleSelect").get("v.value"));
    	},
    
    navigateEntityConfirmationURL : function (cmp) {
        window.open("https://marlincorp.sharepoint.com/sites/teamsites/credit/SitePages/Home.aspx");
    }

})