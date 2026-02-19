/**
 * @description       : 
 * @author            : Joseph Cadd
 * @group             : 
 * @last modified on  : 01-13-2021
 * @last modified by  : Joseph Cadd
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   01-12-2021   Joseph Cadd   Initial Version
**/
({
    addGuarantor: function (cmp) {
        //cmp.set("v.guarantors",guarantors);
        console.log('addGuarantor');
        var guarantors = cmp.get("v.clientWrapper.pgContacts");

        var guarantorWrapper = {};

        var guarantor = {};
        guarantor.sobjectType = 'Contact';
        guarantor.MailingCountryCode = 'US';
        guarantor.OtherCountryCode = 'US';
        guarantor["PG_Number__c"] = 'PG'+guarantors.length;

        guarantorWrapper.readOnly = false;
        guarantorWrapper.dupe = false;
        guarantorWrapper.contact = guarantor;
        
        guarantors.push(guarantorWrapper);
        // console.log(guarantors);
        cmp.set("v.clientWrapper.pgContacts",guarantors);

    },

    addCCGuarantorHelper: function (cmp) {
        var guarantors = cmp.get("v.clientWrapper.ccgAccounts");

        var guarantorWrapper = {};
        var guarantor = {};
        guarantor.sobjectType = 'Account';
        guarantor.MailingCountryCode = 'US';
        guarantorWrapper.readOnly = false;
        guarantorWrapper.dupe = false;
        guarantorWrapper.account = guarantor;

        guarantors.push(guarantorWrapper);
        // console.log(guarantors);
        cmp.set("v.clientWrapper.ccgAccounts", guarantors);
    },

    deleteGuarantor: function (cmp, event, helper) {
        var guarantors = cmp.get("v.clientWrapper.pgContacts");
        var indexVal = event.getSource().get('v.value');
        guarantors.pop(indexVal);
        console.log(guarantors);
        cmp.set("v.clientWrapper.pgContacts",guarantors);
    },

    deleteCCG: function (cmp, event, helper) {
        var guarantors = cmp.get("v.clientWrapper.ccgAccounts");
        var indexVal = event.getSource().get('v.value');
        guarantors.pop(indexVal);
        console.log(guarantors);
        cmp.set("v.clientWrapper.ccgAccounts",guarantors);
    },

    quickSave : function (cmp, event, helper) {
        this.saveGuarantors(cmp, true, false);
    },

    saveAndQuitGuarHelper: function (cmp) {
        this.saveGuarantors(cmp, false, true);
    },

    saveGuarantors: function(cmp, isQuickSave, isSaveAndQuit) {
        TCLightningUtils.showSpinner(cmp);
        var action;

        action = cmp.get('c.saveGuarantors');
        action.setParams({
            clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
        });

        action.setCallback(this, function (result) {
            TCLightningUtils.hideSpinner(cmp);
            if (result.getState() === 'SUCCESS') {

                var returnedValue = JSON.parse(result.getReturnValue());
                cmp.set('v.clientWrapper', returnedValue);
                //TCLightningUtils.showToast('Success', 'Records saved.', 'success');

                // this.callDwhAndAutoPgApi(cmp, isQuickSave, isSaveAndQuit); // SAL-5820 Misael Romero
                if (isQuickSave) {
                    this.goToNextHelper();
                } else if (isSaveAndQuit) {
                    this.submitAppAndNavigate(cmp);
                }
            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(action);
    },

    callDwhAndAutoPgApi: function(cmp, isQuickSave, isSaveAndQuit) {
        TCLightningUtils.showSpinner(cmp);

        var action = cmp.get('c.callDwhAndAutoPgApi');
        action.setParams({
            clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
        });
        action.setCallback(this, function (result) {
            TCLightningUtils.hideSpinner(cmp);
            if (result.getState() === 'SUCCESS') {
                //TCLightningUtils.showToast('Success', 'Records saved.', 'success');
                if (isQuickSave) {
                    this.goToNextHelper();
                } else if (isSaveAndQuit) {
                    this.submitAppAndNavigate(cmp);
                }
            } else {
                console.log(result.getError());
                console.log(result.getError()[0]);
                console.log(result.getError()[0].message);
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
        });
        $A.enqueueAction(action);
    },

    submitAppAndNavigate: function(cmp) {
        TCLightningUtils.showSpinner(cmp);
        var quitNavAction = cmp.get('c.submitApplication');
        quitNavAction.setParams({clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))});

        quitNavAction.setCallback(this, function (result) {
            TCLightningUtils.hideSpinner(cmp);
            if (result.getState() === 'SUCCESS') {
                TCLightningUtils.showToast('Success', 'Deal Saved. Press the Edit Deal in Wizard button to return.', 'success');
                $A.get("e.force:navigateToURL").setParams({ "url": "/" + result.getReturnValue()}).fire();
            } else {
                console.log(result.getError());
                console.log('====>'+ result.getError()[0].message);
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(quitNavAction);
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
})