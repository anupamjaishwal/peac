({
	doInit : function(component, event, helper) {
		var field = component.get('v.field');
		var fieldAPI = field.fieldApi;
		var record = component.get('v.record');
		component.set("v.entryAllowed", component.get("v.isEdit") && !field.readOnly && field.isEditable);
		
		if(fieldAPI != 'ICON'){
			if(field.type === 'REFERENCE'){
				var res = fieldAPI.split(".");
				var recObj = record[res[0]];
				component.set('v.value',recObj[res[1]]);
				component.set('v.DetailPageID',recObj['Id']);

			}else if(field.type === 'PICKLIST'){
				field.fldValue 
				component.set('v.picklistStatus',field.fldValue);
				component.set('v.value',record[fieldAPI]);
			}else{
				component.set('v.value',record[fieldAPI]);	
			}

		}if(fieldAPI === 'Name'){
			field.type = 'REFERENCE';
			component.set('v.DetailPageID',record['Id']);
			component.set('v.field',field);
			component.set('v.value',record[fieldAPI]);
		}

	},
	editRecord : function(component, event, helper) {
		var record = component.get('v.record');
		var compEvent = component.getEvent("SL_EditRecord");
		compEvent.setParams({
			"recId" : record.Id 
		});
		compEvent.fire();
	},
	updateVal : function(component, event, helper){
		var record = component.get('v.record');
		var field = component.get('v.field');
		var fieldAPI = field.fieldApi;

		var compEvent = component.getEvent("SL_UpdateRecord");
		compEvent.setParams({
			"fieldApi" : fieldAPI,
			"recordId" : record.Id,
			"updatedValue" : component.get('v.value')
		});
		compEvent.fire();
	},
	saveRecord : function(component, event, helper){
		var record = component.get('v.record');
		var compEvent = component.getEvent("SL_SaveRecord");
		compEvent.setParams({
			"recordId" : record.Id,
			"isSave" : true
		});
		compEvent.fire();
	},
	cancelUpdate : function(component, event, helper){
		var record = component.get('v.record');
		var compEvent = component.getEvent("SL_SaveRecord");
		compEvent.setParams({
			"recordId" : record.Id,
			"isSave" : false
		});
		compEvent.fire();
	},
	previewRec : function(component, event, helper){ 
		$A.get('e.lightning:openFiles').fire({
        	recordIds: [component.get("v.ContentDocId")]
    	});
	},
	handleUploadFinished: function (component, event, helper) {

        var uploadedFiles = event.getParam("files");
        
        helper.uploadFile(component,uploadedFiles);
        
	},
	naviToDetail : function (component, event, helper) {
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
		  "recordId":component.get('v.DetailPageID'),
		  "slideDevName": "related"
		});
		navEvt.fire();
	}
	
})