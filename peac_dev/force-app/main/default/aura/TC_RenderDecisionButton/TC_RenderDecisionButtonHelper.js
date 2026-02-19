/**
 * Created by szheng on 1/28/20.
 */

({

    getRenderDecisionDetailsHelper: function (cmp, event) {
        var action = cmp.get('c.getRenderDecisionDetails');
        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                cmp.set('v.wrapper', result.getReturnValue());
            } else {
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'title': 'Error',
                    'type': 'error',
                    'message': result.getError()[0].message,
                    'mode': 'sticky'
                });
                toastEvent.fire();
                this.dismissAction();
            }
        });
        $A.enqueueAction(action);
    },

    nextButtonHelper: function (cmp, event) {
        console.log("Next Button Helper");

        var wrapper = cmp.get('v.wrapper');
        if (wrapper.errorList.length > 0) {
            console.log('errorList > 0: dismissing action');
            var opp = wrapper.opp;
            /* Commented out per removal of SFP2 logic for Release 2.1
            if (opp.Decision_Status__c == 'R'
             && opp.SFP_Tier_2_Credit_Box__c != null
              && opp.SFP_Tier_2_Status__c != 'Approved'
               && opp.SFP_Tier_2_Status__c != 'Rejected') {
                this.setSFP2InProcessHelper(cmp, event);
            } else {
                this.dismissAction();
            }*/
            $A.get('e.force:refreshView').fire();
            this.dismissAction();
        } else if (wrapper.confirmActionStep) {
            // this.finalOppUpdateHelper(cmp);

            if (cmp.get('v.actionValue') == 'No') {
                $A.get('e.force:refreshView').fire();
                this.dismissAction();
            } else {
                console.log('yes: renderDecisionHelper');
                this.renderDecisionHelper(cmp, event);
            }
        } else if (wrapper.supplementalCodes) {
            console.log('wrapper.supplementalCodes = yes');
            if (this.validateSupplementalCodeInput(cmp, event)) {
                console.log('validateSupplementalCodeInput = yes: finalOppUpdateHelper');
                this.finalOppUpdateHelper(cmp, event);
            } else {
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'title': 'Error',
                    'type': 'error',
                    'message': 'You must select one or more Supplemental Codes.'
                });
                toastEvent.fire();
            }
        }
    },

    setSFP2InProcessHelper: function (cmp, event) {
        var action = cmp.get('c.setSFP2InProcess');
        action.setParams({
            opp: cmp.get('v.wrapper.opp')
        });
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                $A.get('e.force:refreshView').fire();
                this.dismissAction();
            } else {
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'title': 'Error',
                    'type': 'error',
                    'message': result.getError()[0].message,
                    'mode': 'sticky'
                });
                toastEvent.fire();
                this.dismissAction();
            }
        });
        $A.enqueueAction(action);
    },

    renderDecisionHelper: function (cmp, event) {
        console.log('inside renderDecisionHelper');
        cmp.set('v.wrapper.confirmActionStep', false);
        var action = cmp.get('c.renderDecision');
        action.setParams({
            wrapper: cmp.get('v.wrapper')
        });
        action.setCallback(this, function (result) {
            console.log('renderDecisionHelper.getState: ' + result.getState());
            if (result.getState() === 'SUCCESS') {
                var wrapper = result.getReturnValue();
                console.log('after renderDecisionHelper wrapper: ' + JSON.stringify(wrapper));
                if (!wrapper.supplementalCodes && wrapper.errorList.length == 0) {
                    // SAL-2633 Commented out some lines that prevent updating Resubmit to Credit Decision fields
                    // This calls the finalOppUpdate subroutine that does this, then dismisses the action

                    //console.log('after renderDecisionHelper: attempting to dismiss action');
                    //$A.get('e.force:refreshView').fire();
                    //this.dismissAction();

                    console.log('after renderDecisionHelper: calling finalOppUpdateHelper');
                    this.finalOppUpdateHelper(cmp, event);
                } else {
                    console.log('after renderDecisionHelper: displaying needed supplemental codes');
                    cmp.set('v.wrapper', result.getReturnValue());
                }
            } else {
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'title': 'Error',
                    'type': 'error',
                    'message': result.getError()[0].message,
                    'mode': 'sticky'
                });
                toastEvent.fire();
                this.dismissAction();
            }
        });
        $A.enqueueAction(action);
    },

    validateSupplementalCodeInput: function (cmp, event) {
        var declineCodeStrings = [
            'Business_or_Personal_Bankruptcy__c'
            , 'Dealer_Issue__c'
            , 'Additional_Bureau_Information__c'
            , 'Existing_Marlin_Customer_Not_Paid_As_Agr__c'
            , 'Equipment_Issue__c'
            , 'Exposure__c'
            , 'PG_on_app_not_linked_to_business__c'
            , 'Excessive_Suits_Liens_or_Judgments__c'
            , 'Poor_Financial_Condition__c'
            , 'No_Comp_Debt__c'
            , 'Scored_incorrect_bureau_correct_bureau_d__c'
            , 'Verified_Different_TIB__c'
            , 'Insufficient_Bank_Balance__c'
            , 'NSF_OD_Activity__c'
            , 'Fraud_Flag__c'
            , 'Other__c'];

        var approveCodeStrings = [
            'Sufficient_Financial_Strength__c'
            , 'Strong_Trade_Comparable_Lease_Bank_Refer__c'
            , 'Verified_Different_Time_in_Business__c'
            , 'Cross_Corporate_Guarantor__c'
            , 'Scored_incorrect_bureau_correct_bureau_s__c'
            , 'Additional_Bureau_Data__c'
            , 'Existing_Marlin_Customer_with_Good_Pay_H__c'
            , 'Approval_Other__c'];

        var opp = cmp.get('v.wrapper.opp');
        if (opp.Reason_for_Approval__c == 'Approved with Supplemental Information') {
            return approveCodeStrings.reduce(function (boolean, codeString) {
                boolean = boolean || opp[codeString];
                return boolean;
            }, false);
        } else if (opp.Decline_Reason__c == 'Rejected with Supplemental Information') {
            return declineCodeStrings.reduce(function (boolean, codeString) {
                boolean = boolean || opp[codeString];
                return boolean;
            }, false);
        }
    },

    finalOppUpdateHelper: function (cmp, event) {
        console.log('inside finalOppUpdateHelper');
        var action = cmp.get('c.finalOppUpdate');
        var wrapperVar = cmp.get('v.wrapper');
        // Here we can do the mapping
        // Like  wrapperVar.opp.Decision_Status__c = give the value you want to set

        action.setParams({
            wrapper: wrapperVar
        });
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                $A.get('e.force:refreshView').fire();
                console.log('about to close.. ');
                this.dismissAction();
            } else {
                var toastEvent = $A.get('e.force:showToast');
                toastEvent.setParams({
                    'title': 'Error',
                    'type': 'error',
                    'message': result.getError()[0].message,
                    'mode': 'sticky'
                });
                toastEvent.fire();
                this.dismissAction();
            }
        });
        $A.enqueueAction(action);
    },

    dismissAction: function () {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }

});