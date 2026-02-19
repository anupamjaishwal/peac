({
	 handleSave : function(component, event, helper) {
	 	var rec = component.get('v.record');
		var action = component.get("c.updateRecord");
        action.setParams({
            jsonObjArr : JSON.stringify(rec)
        });
        action.setCallback(this, function(response) {
            var resultsToast = $A.get("e.force:showToast");
            if (response.getState() === "SUCCESS") {
                var res = response.getReturnValue();
                var objToast = {
                    "message" : "Record updated successfully",
                    "type" : "success"
                };
                if(res === 'success'){
                	component.set('v.EditRecord',false);
                }else{
                    objToast['message'] = JSON.parse(res)[0].message;
                    objToast["type"] = "error";
                    objToast["mode"] = "sticky";
                    resultsToast.setParams(objToast);
               		resultsToast.fire();
                }            
                
            }else{
                resultsToast.setParams({
                    "message" : "Something went wrong please try again.",
                    "type"    : "error"
                });
                resultsToast.fire();
            }
        });
        $A.enqueueAction(action);
    },
    uploadFile : function(component,  uploadedFiles) {
    	var rec = component.get('v.record');
    	var action = component.get('c.updateFile');
        action.setParams({
        	"DocID" : uploadedFiles[0].documentId,
        	"ObjId" : rec.Id
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
	cancel :  function(component, event, helper) {
		component.set('v.record',component.get('v.backup'));
		component.set('v.EditRecord',false);
	},
})