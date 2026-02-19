({
    closeQuickAction : function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    } ,
    submitAction : function(cmp, event, helper) {
        //Call api TBD
        var action = cmp.get('c.makeCallout');
        action.setParams ({
            "email" : cmp.get("v.CaseRecord.Email"),
            "contact" : cmp.get("v.recordId"),
            "ccan" : cmp.get("v.CaseRecord.ccan__c"),
            "ccid" : cmp.get("v.CaseRecord.ccid__c")
        })
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                cmp.set('v.sObjList', a.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        $A.get("e.force:closeQuickAction").fire();
    }
})