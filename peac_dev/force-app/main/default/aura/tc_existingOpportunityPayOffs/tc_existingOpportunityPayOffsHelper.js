({
    grabOppInfoHelper : function(cmp, event, helper) {
		var action = cmp.get('c.grabOppInfo');
        
        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var payment = JSON.parse(result.getReturnValue());
                cmp.set('v.oppId', payment.Opportunity__c);
                var rt = payment.Opportunity__r.Loan_Record_Type__c ? 'loan' : 'lease';
                cmp.set('v.rt', rt);
                this.refreshPayOffs (cmp, event, helper);
            } else {
                console.log(result.getError());
            }
        });
        
        $A.enqueueAction(action);
	},
	refreshPayOffs : function(cmp, event, helper) {
		var action = cmp.get('c.grabPayOffs');
        
        action.setParams({
            recordId: cmp.get('v.recordId')
            , oppId : cmp.get('v.oppId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var payOffs = JSON.parse(result.getReturnValue());
                cmp.set('v.payOffs', payOffs);
            } else {
                console.log(result.getError());
            }
        });
        
        $A.enqueueAction(action);
	}, 
    
    savePayOffsHelper : function(cmp, event, helper) {
		var action = cmp.get('c.savePayOffs');
        
        action.setParams({
            payOffsJSON : JSON.stringify (cmp.get ('v.payOffs'))
            , recordId: cmp.get('v.recordId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                $A.get('e.force:refreshView').fire();
                helper.createToastMessage ('Success', 'Selected payoffs successfully tied to payment', 'success');
                helper.refreshPayOffs (cmp, event, helper);
            } else {
                console.log(result.getError());
            }
        });
        
        $A.enqueueAction(action);
	},
    
    createToastMessage : function (title, message, type, mode) {
            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": title,
                                "message": message,
                                "type" : type,
                                "mode": mode
                            });
            toastEvent.fire();
     },
})