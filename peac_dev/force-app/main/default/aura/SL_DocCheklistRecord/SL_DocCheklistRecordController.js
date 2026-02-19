({
	doInit : function(component, event, helper) {
		var rec = component.get('v.record');
		component.set('v.backup',rec);
		
		component.set('v.device', $A.get("$Browser.formFactor"));
		//console.log('doInit?');

		var lstFilesId = component.get('v.lstFiles');
		if(lstFilesId[rec.Id] != null && lstFilesId[rec.Id] != undefined){
			component.set('v.ContentDocId',lstFilesId[rec.Id]);
			component.set('v.uploadFile',false);
		}else{
			component.set('v.uploadFile',true);
		}
		//console.log('backup>>>>',JSON.stringify(component.get('v.backup')));

	},
	handleUploadFinished: function (component, event, helper) {

        var uploadedFiles = event.getParam("files");
        
        helper.uploadFile(component,uploadedFiles);
        
	},
	openRercord : function (component, event, helper) {
		$A.get('e.lightning:openFiles').fire({
        	recordIds: [component.get("v.ContentDocId")]
    	});
	},
	editRec : function (component, event, helper) {
		component.set('v.EditRecord',true);
	},
	
	save :  function(component, event, helper) {
		var record = component.get('v.record');
		var recId = event.getParam("recordId");
		var isSave = event.getParam("isSave");

		if(recId === record.Id){
			if(isSave){
				helper.handleSave(component, event, helper);
			}else{
				helper.cancel(component, event, helper);
			}
		}
	},
	detailPage : function(component, event, helper) {
		var rec = component.get('v.record');
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
		  "recordId": rec.Id,
		  "slideDevName": "related"
		});
		navEvt.fire();
	},
	
	isEdit : function(component, event, helper) {
		//console.log('isEdit>>>>>>>event handler')
		var record = component.get('v.record');
		var recId = event.getParam("recId");

		 if(recId === record.Id){
		 	component.set('v.EditRecord',true);
		 }
	},
	updatedValue : function(component, event, helper) {
		var rec = component.get('v.record');
		var recId = event.getParam("recordId");
		var fieldApi = event.getParam("fieldApi");
		var updatedValue = event.getParam("updatedValue");
		if(recId === rec.Id){
			rec[fieldApi]= updatedValue;
			component.set('v.record',rec);
		}
	}
})