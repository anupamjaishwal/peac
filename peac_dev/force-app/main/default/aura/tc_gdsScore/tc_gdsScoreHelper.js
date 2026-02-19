({
	runGdsScore : function(cmp, event) {
        var action = cmp.get('c.callGdsScore');
        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function (result) {
            var state = result.getState();
            if (state === 'SUCCESS') {
                var errorMessage = result.getReturnValue ();
                if (errorMessage != '') {
                    console.error( errorMessage );
                    this.showToast('Error', errorMessage, 'sticky', 'error');
                } else {
                    this.showToast('Success', 'Gds Score Requested. Please wait up to 30 seconds for the process to complete', 'dismissible', 'Success');
                    $A.get('e.force:closeQuickAction').fire();
                }
            } else {
                this.showToast('Error', result.getError()[0].message, 'sticky', 'error');
                console.error( result.getError()[0].message );
            }
            //$A.get('e.force:closeQuickAction').fire();
        });
        $A.enqueueAction(action);
	},

    // 2065 
    runTwhStoredProcFraudQuery: function(cmp, event) {
        this.showSpinner(cmp);
        var action = cmp.get('c.callDwhStoredProcFraudQuery');
        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        action.setCallback(this, function (result) {
            this.hideSpinner( cmp );
            var state = result.getState();
            if (state === 'SUCCESS') {
                var errorMessage = result.getReturnValue ();
                if (errorMessage != '') {
                    console.error( 'error message in return value: ', errorMessage );
                    this.showToast('Error', errorMessage, 'sticky', 'error');
                }
                this.runGdsScore( cmp, event );
            } else {
                // uncaught error message
                console.error( result.getError()[0].message );

                this.showToast('Error', result.getError()[0].message, 'sticky', 'error');
            }
            $A.get('e.force:closeQuickAction').fire();
        });
        $A.enqueueAction(action);
    },
    
    showSpinner: function(cmp) {
        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass( spinner, 'slds-show' );
    },

    hideSpinner : function(cmp) {
        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-hide");
    },

    showToast : function (title, message, mode, type) {
        var toastEvt = $A.get("e.force:showToast");
        toastEvt.setParams({"title" : title
                            , "message" : message
                            , "mode" : mode
                            , "type" : type});
        toastEvt.fire ();
    }
})