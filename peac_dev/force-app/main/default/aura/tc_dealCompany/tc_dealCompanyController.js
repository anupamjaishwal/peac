({
    doInit : function (cmp, event, helper) {
        cmp.set('v.isPreApproval', cmp.get('v.clientWrapper.deal.opportunity.Pre_Approval__c'));
        console.log(JSON.stringify(cmp.get('v.clientWrapper.deal.opportunity')));
    },

    quickSave : function (cmp, event, helper) {
        helper.quickSave(cmp, event, helper);

    },

    clearCompany: function (cmp, event, helper) {
        var company = {};
        company.sobjectType = 'Account';
        company.BillingCountryCode = 'US';
        cmp.set ('v.clientWrapper.company.readOnly', false);
        cmp.set ('v.clientWrapper.company.dupe', false);
        cmp.set("v.clientWrapper.company.account", company);
    },

    clearContact: function (cmp, event, helper) {
        var contact = {};
        contact.sobjectType = 'Contact';
        cmp.set ('v.clientWrapper.contact.readOnly', false);
        cmp.set ('v.clientWrapper.contact.dupe', false); 
        cmp.set ('v.clientWrapper.contact.role', '');
        cmp.set ('v.clientWrapper.contact.roleSaved', false);
        cmp.set("v.clientWrapper.contact.contact", contact);
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


    goToNext : function (cmp, event, helper) {
        var navEvent = $A.get("e.c:tc_applicationNavigation_evt");
        var dir = "next";
        
        navEvent.setParams({
            data: {
                direction: dir
            }
        });
        
        navEvent.fire();
    },

    customerAddressSameAsCompanyCTRL : function (cmp, event, helper) {
        // for some reason checking the checkbox doesn't set the value to true
            if (!cmp.get ('v.customerAddressSameAsCompany')){
                cmp.set ('v.customerAddressSameAsCompany', true);
            } else {
                cmp.set ('v.customerAddressSameAsCompany', false);
            }

        },

    test : function (cmp, event, helper) {
        console.log (cmp.find ('testId').get('v.value'));
    },

    contactLastNameChanged : function (cmp, event, helper) {
        if (cmp.get ('v.clientWrapper.contact.contact.LastName') != null && cmp.get ('v.clientWrapper.contact.contact.LastName') != '') {
            cmp.set ('v.contactFieldsRequired', true);
        } else {
            cmp.set ('v.contactFieldsRequired', false);
        }
    },
    saveAndQuitController : function (cmp, event, helper) {
            helper.saveAndQuitHelper (cmp, event, helper);
        },
    
    contactRoleSelected : function (cmp, event, helper) {
        helper.contactRoleSelectedHelper (cmp, event, helper);
    },

    entityConfirmationClicked : function (cmp, event, helper) {
        helper.navigateEntityConfirmationURL (cmp, event, helper);
    }




})