({
	doInit : function(component, event, helper) {
		helper.getFields(component, event, helper); 
		// var wait1= helper.getPicklist1(component, event, helper);
		// helper.fetchRecords(component, event, helper);
	},
	newDoc : function(component, event, helper) {
		component.set('v.SecondPage',true);
		component.set('v.FirstLoyout',false);
	},
	nextBtn : function(component, event, helper) {
		component.set('v.thirdPage',true);
		component.set('v.SecondPage',false);
		component.set('v.FirstLoyout',false);
	},
	onSelectChange2 : function(component, event, helper) {
  		var selectCmp = component.find("picklist2");
        component.set("v.pickval", selectCmp.get("v.value"));
	},
	save : function(component, event, helper) {
		var action = component.get('c.SaveRecord');
		action.setParams({
        	"name" : component.get('v.DocName'),
        	"descption" : component.get('v.DocDesc'),
        	"status" : component.get('v.pickval'),
        	"contentID" : component.get('v.contentID'),
        	"recordId" : component.get('v.recordId'),
        	"ObjectName" : component.get('v.sObjectName')
        });
		action.setCallback(this,function(response){
			var state = response.getState();
			var resultsToast = $A.get("e.force:showToast");
			if(state === "SUCCESS"){
				helper.fetchRecords(component, event, helper);
				component.set('v.thirdPage',false);
				component.set('v.SecondPage',false);
				component.set('v.FirstLoyout',true);

				component.set('v.contentID',null);
				component.set('v.DocName',null);
				component.set('v.DocDesc',null);
				component.set('v.pickval',null);

				 var objToast = {
                    "message" : "Record updated successfully",
                    "type" : "success"
                }; 

                component.set('v.UploadFileName','');
        		component.set('v.contentID','');

                resultsToast.setParams(objToast);
                resultsToast.fire();
			}
		});
		$A.enqueueAction(action);
	},
	handleUploadFinished: function (component, event, helper) {

		var rec = component.get('v.record');
        var uploadedFiles = event.getParam("files");
        component.set('v.UploadFileName',uploadedFiles[0].name);
        component.set('v.contentID',uploadedFiles[0].documentId);    
       
	},
	naviToDetail : function (component, event, helper) {
    	var id  = component.get('v.contentID');
		$A.get('e.lightning:openFiles').fire({
        	recordIds: [id]
    	});
	},
	cancel : function (component, event, helper) {
		helper.deleteFileRec(component, event);
		helper.fetchRecords(component, event, helper);
		component.set('v.thirdPage',false);
		component.set('v.SecondPage',false);
		component.set('v.FirstLoyout',true);
	},
	deleteUploadedFile : function (component, event, helper) {
		helper.deleteFileRec(component, event);
	},
	next : function(component, event, helper) {
        //component.find('foucusOnClick').getElement().focus();
        helper.nextPage(component);
    },
    prev : function(component, event, helper) {
        //component.find('foucusOnClick').getElement().focus();
        helper.previousPage(component);
    },
    refreshcmp :  function (component, event, helper) {
    	 var type = event.getParam("type");
    	 var that = this;
    	 if(type != 'error'){
    	 	helper.fetchRecords(component, event, helper);
    	 }
    },
	handleRecordUpdate: function(component, event, helper){
		var changeType = event.getParams().changeType;
		if (changeType === "CHANGED") { 
			helper.fetchRecords(component, event, helper);
		}
	},
    sortRecords :  function (component, event, helper) {

    	var fieldApi = event.currentTarget.id;
    	var lstField = fieldApi.split('--');
    	if(lstField[1] === 'true'){
	    	var currentSortColumn = component.get('v.currentSortColumn');
	    	if(currentSortColumn != lstField[0]){
	    		component.set('v.currentSortColumn',lstField[0]);
	    		component.set('v.ascending',true);
	    	}else{
	    		var asc = component.get('v.ascending');
	    		asc = !asc;
	    		component.set('v.ascending',asc);
	    	}
	    	helper.sortRec(component, event);
	    }
    },
    
})