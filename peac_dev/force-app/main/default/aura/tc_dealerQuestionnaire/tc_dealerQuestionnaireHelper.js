/**
 * Created by szheng on 4/27/20.
 */

({
    doInitHelper : function(cmp, event, helper, openModel) {
        this.toggleSpinner(cmp);
        var action = cmp.get('c.questionnaireInit');
        action.setParams({
            recordId : cmp.get('v.recordId')
        });
        action.setCallback(this, function(result) {
            if (result.getState() === 'SUCCESS') {
                cmp.set('v.wrapper', result.getReturnValue());
             if(openModel) helper.openModalHelper(cmp);
            } else {
                this.toastEvent('Error', 'error', result.getError()[0].message, 'dismissible');
            }
            this.toggleSpinner(cmp);
        });
        $A.enqueueAction(action);
    },

    saveQuestionnaireHelper : function(cmp) {
        this.toggleSpinner(cmp);
        var validateBoolean = false;
        var requiredBoolean = cmp.get('v.wrapper.account.Dealer_Questionnaire_Required__c');
        if (requiredBoolean) {
            validateBoolean = cmp.find('tc_dealerQuestionnaireModal').fieldValidation(true);
        } else {
            validateBoolean = cmp.find('tc_dealerQuestionnaireModal').fieldValidation(false);
        }
        var account = cmp.get('v.wrapper').account;
        var serviceFieldValid = true;
        if ((account.Service__c == 'Yes' ||account.New_Dealer_Service_Based__c == 'Service-Based') && (!account.Percentage_of_Service__c || !account.Alternative_Provider__c)) {
            serviceFieldValid = false;
        }
        if (((requiredBoolean && validateBoolean) || !requiredBoolean) && serviceFieldValid) {
            cmp.set('v.wrapper.account.Dealer_Questionnaire_Complete__c', validateBoolean);
            var action = cmp.get('c.updateAccount');
            action.setParams({
                wrapper : cmp.get('v.wrapper')
            });
            action.setCallback(this, function(result) {
                if (result.getState() === 'SUCCESS') {
                    cmp.set('v.wrapper', result.getReturnValue());
                    this.closeModalHelper(cmp);
                    this.toastEvent('Success', 'success', 'Questionnaire has been submitted!', 'dismissible');
                } else {
                    this.toastEvent('Error', 'error', result.getError()[0].message, 'dismissible');
                }
                this.toggleSpinner(cmp);
            });
            $A.enqueueAction(action);
        } else {
            this.toggleSpinner(cmp);
            this.toastEvent('Error', 'error', 'Please complete all fields.', 'dismissible');
        }
    },

    toastEvent : function(title, type, message, mode) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            'title': title,
            'type': type,
            'message': message,
            'mode': mode
        });
        toastEvent.fire();
    },

    toggleSpinner : function(cmp) {
        cmp.set('v.spinnerBoolean', !cmp.get('v.spinnerBoolean'));
    },

    openModalHelper : function(cmp) {
        var modal = cmp.find('questionnaireModal');
        $A.util.removeClass(modal, 'slds-hide');
        $A.util.addClass(modal, 'slds-show');
    },

    closeModalHelper : function(cmp) {
        var modal = cmp.find('questionnaireModal');
        $A.util.addClass(modal, 'slds-hide');
        $A.util.removeClass(modal, 'slds-show');
    },
});