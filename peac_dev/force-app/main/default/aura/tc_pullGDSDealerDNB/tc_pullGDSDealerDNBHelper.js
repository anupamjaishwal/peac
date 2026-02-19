({
	pullDNBHelper : function(cmp) {

		var action = cmp.get('c.pullDNB');

        action.setParams({
            recId: cmp.get('v.recordId')
        });

        action.setCallback(this, function (result) {
			var spinner = cmp.find("mySpinner");
            $A.util.toggleClass(spinner, "slds-hide");
            
            var clientResult = result.getReturnValue();

            if (clientResult.status === 'SUCCESS') {
                TCLightningUtils.showToast('Success', 'success','success', 'dismissible');
            } else {
                TCLightningUtils.showToast('Error', clientResult.message, 'error', 'sticky');
            }

            $A.get("e.force:closeQuickAction").fire()

        });

        $A.enqueueAction(action);

	},
    // success, error
    showToast : function(title, message, toastType, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            messageTemplate: '',
            duration:' 5000',
            key: 'info_alt',
            type: toastType,
            mode: mode
        });
        toastEvent.fire();
    },
})