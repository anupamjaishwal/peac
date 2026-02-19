({
    dismiss : function(cmp, event, helper) {
        helper.dismissToast(cmp, event);
    },

    handleToast : function(cmp, event, helper) {
        var toastCmp = cmp.find('toast');
        var mode = cmp.get('v.mode');
        var toast = event.getParam("toast");

        console.log ('>>>>> type: ' + toast.messageType);
        console.log('handle toast', toast);
        // set the handler attributes based on event data
        cmp.set("v.message", toast.message);
        cmp.set("v.title", toast.title);
        cmp.set("v.type", toast.messageType);

        $A.util.removeClass(toastCmp, 'slds-hide');

        if (mode !== 'sticky' && (toast.messageType == 'success' || toast.messageType == 'info')) {
            window.setTimeout(
                $A.getCallback(function() {
                    helper.dismissToast(cmp, event)
                }), 3000
            );
        }

    },
})