({
	uploadFile : function(component,  uploadedFiles) {
    	var rec = component.get('v.record');
    	var action = component.get('c.linkFileToRelatedRec');
    	var caseId ='',oppId='';
    	caseId = rec.Case_c;
    	oppId = rec.Opportunity__c;
    	
        action.setParams({
        	"caseID" : caseId,
        	"OppId"  : oppId,
        	"DocId"  : uploadedFiles[0].documentId,
        	"DocStatusID" : rec.Id
        });
		action.setCallback(this,function(response){
			var state = response.getState();
			if(state === "SUCCESS"){
				var  records = response.getReturnValue();
				component.set('v.lstRecords',records);
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
				    "title": "Success!",
				    "message": "The record has been updated successfully."
				});
				toastEvent.fire();
			}
		});
		$A.enqueueAction(action);
    },
})