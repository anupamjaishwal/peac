({
    handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        var appEvent = $A.get("e.c:tc_bookMillionDollarLeaseConfirmation_evt");
        appEvent.setParams({
            "message" : "Cancel" });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
    },
    handleOK : function(component, event, helper) {
        //do something
        var appEvent = $A.get("e.c:tc_bookMillionDollarLeaseConfirmation_evt");
        appEvent.setParams({
            "message" : "Ok" });
        appEvent.fire();
        component.find("overlayLib").notifyClose();
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
        }
})