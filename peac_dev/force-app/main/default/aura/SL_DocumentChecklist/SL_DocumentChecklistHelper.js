({
	fetchRecords : function(component, event, helper) {

		 var that=this;
        var action = component.get('c.getrecords');
		action.setParams({
        	"recordId" : component.get('v.recordId'),
        	"ObjectName" : component.get('v.sObjectName'), //'Case', 
            "lstFields" : component.get('v.lstQueryFields')
        });
		action.setCallback(this,function(response){
			var state = response.getState();

			if(state === "SUCCESS"){
				var  records = response.getReturnValue();
				var lstRec = records.lstDocumentStatus;
				component.set('v.totalRecords',lstRec.length);
				component.set('v.lstFilesId',records.lstcontentDocID);
				component.set('v.lstRecords',lstRec);
                that.paginationSetUp(component, helper);
			}
		});
		$A.enqueueAction(action);
	},
	getPicklist : function(component, helper){
		var action = component.get('c.getselectOptions');
		action.setParams({
        	"fieldApi" :'Status__c'
        });
		action.setCallback(this,function(response){
			var state = response.getState();
			if(state === "SUCCESS"){
				var  records = response.getReturnValue();
				component.set('v.picklistVal',records);
				return 'wait';
			}
		});
		$A.enqueueAction(action);
	},
	getPicklist1 : function(component, event, helper){
		var action = component.get('c.getselectOptions');
		action.setParams({
        	"fieldApi" :'Type__c'
        });
		action.setCallback(this,function(response){
			var state = response.getState();
			if(state === "SUCCESS"){
				var  records = response.getReturnValue();
				component.set('v.typePicklist',records);
				return 'wait';
			}
		});
		$A.enqueueAction(action);
	},
	paginationSetUp : function (component, helper){
         setTimeout(function() { 
            var pBtn = component.find('prevButton');
            var nBtn = component.find('nextButton');
            component.set("v.startIndex",0);
            component.set("v.endIndex",component.get('v.pageSize'));
            if(pBtn != null && pBtn != undefined && nBtn != null && nBtn != undefined){
                if( component.get("v.totalRecords") != 0 && component.get("v.startIndex") == 0){
                    component.find('prevButton').getElement().setAttribute('disabled','true');
                    component.find('nextButton').getElement().setAttribute('disabled','false');
                    component.find('nextButton').getElement().removeAttribute("disabled");
                }  
            }
            var wait= helper.getPicklist(component, helper);                               
        }, 1000);
    },
     nextPage : function(component) {
        var totalRecords = component.get("v.totalRecords"),
            pageSize = component.get("v.pageSize"),
            startIndex = component.get("v.startIndex"),
            endIndex = component.get("v.endIndex");
        
        if(startIndex + pageSize < totalRecords) {
            component.set("v.startIndex", startIndex + pageSize);
            component.set("v.endIndex", endIndex + pageSize);
            component.find('prevButton').getElement().removeAttribute("disabled");
            if(component.get("v.startIndex") + pageSize  >= totalRecords){
                component.find('nextButton').getElement().setAttribute('disabled','true');
            }
        } 
        else {
            component.find('nextButton').getElement().setAttribute('disabled','true');
        }
    },
    
    //navigate to previous page
    previousPage : function(component) {
        var pageSize = component.get("v.pageSize"),
            startIndex = component.get("v.startIndex"),
            endIndex = component.get("v.endIndex");
        
        if(startIndex - pageSize >= 0) {
            component.set("v.startIndex", startIndex - pageSize);
            component.set("v.endIndex", endIndex - pageSize);
            component.find('nextButton').getElement().removeAttribute("disabled");
            if(startIndex - pageSize === 0)
                component.find('prevButton').getElement().setAttribute('disabled','true');
        } 
        else {
            component.find('prevButton').getElement().setAttribute('disabled','true');
        }
    },
    getFields : function(component, event, helper){
        var that = this;
        var act = component.get('c.getColumns');
        act.setCallback(this,function(res){
            var state = res.getState();
            if(state == 'SUCCESS'){
                var ret = res.getReturnValue();
                var lstFields = ret.lstFields;
                var lstQueryFields = ret.lstQuryFields;
                component.set('v.lstFields',lstFields);
                component.set('v.lstQueryFields',lstQueryFields);

                component.set('v.currentSortColumn',lstQueryFields[0]);
                component.set('v.selectedSortColumn',lstQueryFields[0]);

                helper.fetchRecords(component, event, helper); 
            }else{
                //console.log('ERROR');
            }
        });
        $A.enqueueAction(act);
    },
    sortRec : function(component, event){
        var filteredRecs = component.get('v.lstRecords');
        var fieldAPI = component.get('v.currentSortColumn');
        var ascending = component.get('v.ascending');
        var that = this;
        filteredRecs.sort(function(recA, recB){
            var aValue = that.getRealValue(fieldAPI, recA);
            var bValue = that.getRealValue(fieldAPI, recB);
           
            if(aValue === undefined){
                return 1;
            }
            else if(bValue === undefined){
                return -1;
            }
            else if(aValue === bValue){
                return 0;
            }
            else if(ascending) {
                return aValue < bValue ? -1 : 1;
            }
            else if(!ascending) {
                return aValue < bValue ? 1 : -1;
            }
            
        });
        component.set('v.lstRecords',filteredRecs);

    },
    getRealValue : function(fieldAPI,record){
        if(fieldAPI.includes('.')){
            var lstField = fieldAPI.split(".");
            var subObj = record[lstField[0]];

            return subObj[lstField[1]];
        }else{
            return record[fieldAPI];
        }
    },
    deleteFileRec : function(component, event){
        var action = component.get('c.deleteFile');
        var docuId =  component.get('v.contentID');
        action.setParams({
            "DocId" : docuId
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            var resultsToast = $A.get("e.force:showToast");
            if(state === "SUCCESS"){
                component.set('v.UploadFileName','');
                component.set('v.contentID','');
            }
        });
        if(docuId!= null && docuId != undefined && docuId != '')
            $A.enqueueAction(action);
    }
})