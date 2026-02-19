/**
 * Created by szheng on 4/27/20.
 */

({
    fieldValidation : function(cmp, event, helper) {

        var params = event.getParam('arguments');
        var displayError = params ? params.displayError : true;
        var account = cmp.get('v.wrapper.account');
        var required = cmp.find('required');
        var requiredValid = true;
        requiredValid = required.reduce(function (validSoFar, inputCmp) {
            var errorBoolean = !inputCmp.get('v.value');
            if (errorBoolean && displayError) $A.util.addClass(inputCmp, 'custom_focus');
            return validSoFar && !errorBoolean;
        }, true);

        var serviceRequired = cmp.find('serviceRequired');
        var serviceRequiredAlways = cmp.find('serviceRequiredAlways');
        var serviceRequiredValid = true;
        var serviceRequiredAlwaysValid = true;
        if (cmp.get('v.wrapper.account.Service__c') == 'Yes' || cmp.get('v.wrapper.account.New_Dealer_Service_Based__c') == 'Service-Based') {
            serviceRequiredValid = serviceRequired.reduce(function (validSoFar, inputCmp) {
                if (!inputCmp.get('v.value') && displayError) $A.util.addClass(inputCmp, 'custom_focus');
                return validSoFar && inputCmp.get('v.value');
            }, true);
            serviceRequiredAlwaysValid = serviceRequiredAlways.reduce(function (validSoFar, inputCmp) {
                if (!inputCmp.get('v.value') ) $A.util.addClass(inputCmp, 'custom_focus');
                return validSoFar && inputCmp.get('v.value');
            }, true);
        } else {
            var serviceRequiredNullList = ['Service_Term__c', 'Service_Provider__c', 'Hosted_Solution__c', 'Purchased_Services__c', 'Percentage_of_Service__c', 'Alternative_Provider__c', 'Pro_Rata__c'];
            serviceRequiredNullList.forEach(function(item, index) {
                account[item] = null;
            });
        }

        var dealerRequired = cmp.find('dealerRequired');
        var dealerRequiredValid = true;
        if (cmp.get('v.wrapper.account.Service_Provider__c') == '3rd party') {
            if (!dealerRequired.get('v.value')) {
                if (displayError) $A.util.addClass(dealerRequired, 'custom_focus');
                dealerRequiredValid = false;
            }
        } else {
            account['Manufacturer_ISP__c'] = null;
        }

        var hostedRequired = cmp.find('hostedRequired');
        var hostedRequiredValid = true;
        if (cmp.get('v.wrapper.account.Hosted_Solution__c') == 'Yes') {
            if (!hostedRequired.get('v.value')) {
                if (displayError) $A.util.addClass(hostedRequired, 'custom_focus');
                hostedRequiredValid = false;
            }
        } else {
            account['Proprietary__c'] = null;
        }

        cmp.set('v.wrapper.account', account);

        return requiredValid && serviceRequiredValid && dealerRequiredValid && hostedRequiredValid && serviceRequiredAlwaysValid;
    },

    checkValid : function(cmp, event, helper) {
        var value = event.getSource().get('v.value');
        if (value) $A.util.removeClass(event.getSource(), 'custom_focus');
    }
});