({
    generateDocs : function(cmp) {
        let action = cmp.get('c.generateDocuments');
        let oppId = cmp.get('v.recordId');

        action.setParams({
            recordId : oppId
        });

        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS') {
                let url = response.getReturnValue();
                if(url) {
                    let urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                      "url": url,
                      "isredirect": "true"
                    });
                    urlEvent.fire();
                }
            } else {
                $A.get("e.force:closeQuickAction").fire();
                $A.util.addClass(cmp.find('spinner'), 'slds-hide');
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": response.getError()[0].message,
                    "type": "error",
                });
                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);
    }
})