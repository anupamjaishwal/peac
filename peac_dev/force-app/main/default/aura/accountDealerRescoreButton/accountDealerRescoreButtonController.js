/**
 * @description       : 
 * @author            : Joseph Cadd
 * @group             : 
 * @last modified on  : 05-06-2021
 * @last modified by  : Joseph Cadd
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   05-06-2021   Joseph Cadd   Initial Version
**/
({
    init : function(component, event, helper) {
        var record = component.get("v.simpleRecord");
        record.Review_For__c = 'Approval';
        record.DM_Review_Status__c = 'Submitted for Review';
        component.set("v.simpleRecord", record);

        if (component.get("v.recordSaved")) {return;}

        var resultsToast = $A.get("e.force:showToast");

        component.find("recordEditor").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");

                component.set("v.recordSaved", true);

                // record is saved successfully
                resultsToast.setParams({"title": "Saved","message": "The record was saved."});

            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
                resultsToast.setParams({"title": "Incomplete","message": "User is offline, device doesn't support drafts."});
            } else if (saveResult.state === "ERROR") {
                var errorMsg = 'Problem saving record, error: ' + JSON.stringify(saveResult.error)
                console.log(errorMsg);
                resultsToast.setParams({"title": "Error","message": errorMsg});

            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }

            resultsToast.fire();

            // Close quick action
            $A.get("e.force:closeQuickAction").fire();
        }));
    }
})