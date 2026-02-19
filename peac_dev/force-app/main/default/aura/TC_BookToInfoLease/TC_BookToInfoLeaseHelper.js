({
    bookToInfoLease: function (cmp) {
        console.log('bookToInfoLease', cmp.get('v.recordId'));
        var action = cmp.get('c.bookToInfoLease');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var response = result.getReturnValue();
                
                if (response.statusMessage == 'Success') {
                    if (response.opportunityStage == 'Funded/Booked')
                        this.showToast('Success', 'Contract ' + response.contractNbr + ' created in InfoLease.', 'success', 'sticky');
                    else
                        this.showToast('Warning', 'Contract ' + response.contractNbr + ' created in InfoLease but unable to update Stage, Application Status, Booked Date and Amount.  Please set those manually.', 'warning', 'sticky');
                } else
                    this.showToast('Error', response.responseMessageDesc, 'error', 'sticky');
            } else {
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
            
            $A.get('e.force:refreshView').fire();
            $A.get('e.force:closeQuickAction').fire();
        });

        $A.enqueueAction(action);
    },
    
    updateSentDate: function (cmp) {
        console.log('updateSentDate', cmp.get('v.recordId'));
        var action = cmp.get('c.updateSentDate');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });

        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                this.bookToInfoLease(cmp);
            } else {
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
                $A.get('e.force:closeQuickAction').fire();
            }
        });

        $A.enqueueAction(action);
    },
    
    showToast : function(title, message, type, mode) {
        var toastEvent = $A.get('e.force:showToast');
        
        toastEvent.setParams({
            'title': title,
            'message': message,
            'type': type,
            'mode': mode
        });
        
        toastEvent.fire();
    },

    checkSubmissionCriteria: function (cmp, event, helper) {

        var action = cmp.get('c.validateSubmissionCriteria');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });

        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");

        action.setCallback(this, function(result) {

            if (result.getState() === 'SUCCESS') {

                if (result.getReturnValue() == 'alreadySubmitted'){

                    this.showToast('Error', 'This application was already sent to InfoLease but no response has been returned yet. If the issue persists, please contact an admin to resolve the issue.', 'error', 'sticky');
                    $A.get('e.force:closeQuickAction').fire();

                }else if (result.getReturnValue() == 'costMillion'){

                    $A.createComponent("c:tc_bookMillionDollarLeasePopup", {},
                        function(content, status, errorMessage) {
                            if (status === "SUCCESS") {

                                var modalBody = content;
                                cmp.find('overlayLib').showCustomModal({
                                    header: "Total Equipment Cost is greater than $1,000,000. Please confirm this is correct before proceeding.",
                                    body: modalBody,
                                    showCloseButton: false,
                                    closeCallback: function() {
                                        console.log('Overlay is closing');
                                    }
                                }).then(function(overlay){
                                    console.log("Overlay is made");
                                });
                            }else{
                                $A.get('e.force:closeQuickAction').fire();
                            }
                        }
                    );

                }else if (result.getReturnValue() == 'ok'){

                    this.bookToInfoLease(cmp);
                }
            }else{

                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
                $A.get('e.force:closeQuickAction').fire();
            }

        });

        $A.enqueueAction(action);
    },

    handleMillionDollarDecision: function (cmp, event, helper) {
        var message = event.getParam('message');

        if (message == 'Ok'){
//            A.util.removeClass(spinner, "slds-hide");
            this.bookToInfoLease(cmp);
        }else{
            $A.get('e.force:closeQuickAction').fire();
        }
    }
})