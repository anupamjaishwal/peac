({
	getSignerLabels : function(component, event, helper) {
         this.showSpinner(component);
		 let action = component.get("c.getSignerLabelsInfo");
            action.setParams({
            });
            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state == 'SUCCESS') {          
                     var fieldSetObj = response.getReturnValue();
                    fieldSetObj.sort((a,b) => (a.DeveloperName > b.DeveloperName) ? 1 : ((b.DeveloperName > a.DeveloperName) ? -1 : 0));
                    component.set("v.signerLabelsList",fieldSetObj);                  
                } else if (state == 'ERROR') {
                    var errors = response.getError();
                   
                }
            });
            $A.enqueueAction(action);
	},
   getTableFieldSetForStatus : function(component, event, helper) {
        var action = component.get("c.getFieldSet");
        action.setParams({
            sObjectName: "Signer_Portal_Status__c",
            fieldSetName: "Status"
        });

        action.setCallback(this, function(response) {
            var fieldSetObj = JSON.parse(response.getReturnValue());
            fieldSetObj.sort((a,b) => (a.name > b.name) ? 1 : ((b.name > a.name) ? -1 : 0));
            component.set("v.fieldSetStatusValues", fieldSetObj);
            var fieldSetStatusValues = 'fieldSetStatusValues';
            this.getTableFieldSetForStart(component, event, helper);        
        })
        $A.enqueueAction(action);
    },
    getTableFieldSetForStart : function(component, event, helper) {
        var action = component.get("c.getFieldSet");
        action.setParams({
            sObjectName: "Signer_Portal_Status__c",
            fieldSetName: "Start"
        });

        action.setCallback(this, function(response) {
            var fieldSetObj = JSON.parse(response.getReturnValue());
            fieldSetObj.sort((a,b) => (a.name > b.name) ? 1 : ((b.name > a.name) ? -1 : 0));
            component.set("v.fieldSetStartValues", fieldSetObj);
            this.getTableFieldSetForComplete(component, event, helper);        
        })
        $A.enqueueAction(action);
    },
    getTableFieldSetForComplete : function(component, event, helper) {
        var action = component.get("c.getFieldSet");
        action.setParams({
            sObjectName: "Signer_Portal_Status__c",
            fieldSetName: "Complete"
        });

        action.setCallback(this, function(response) {
            var fieldSetObj = JSON.parse(response.getReturnValue());
            fieldSetObj.sort((a,b) => (a.name > b.name) ? 1 : ((b.name > a.name) ? -1 : 0));
            component.set("v.fieldSetCompleteValues", fieldSetObj);
            var fieldSetCompleteValues = 'fieldSetCompleteValues';
            this.getTableRows(component, event);
        })
        $A.enqueueAction(action);
    },
    getTableRows : function(component, event){
      // var fieldSetValues = [];
        var action = component.get("c.getRecords");
        let fieldSetValuesStatus = component.get("v.fieldSetStatusValues");        
        let fieldSetValuesStart = component.get("v.fieldSetStartValues");        
        let fieldSetValuesComplete = component.get("v.fieldSetCompleteValues");
        let combinedArray1 = fieldSetValuesStatus.concat(fieldSetValuesStart);
		let fieldSetValues = fieldSetValuesComplete.concat(combinedArray1);
        var setfieldNames = new Set();
        for(var c=0;c<fieldSetValues.length; c++){             
            if(!setfieldNames.has(fieldSetValues[c].name)) {                 
                setfieldNames.add(fieldSetValues[c].name);                   
                if(fieldSetValues[c].type == 'REFERENCE') {                     
                    if(fieldSetValues[c].name.indexOf('__c') == -1) {                     	
                        setfieldNames.add(fieldSetValues[c].name.substring(0, fieldSetValues[c].name.indexOf('Id')) + '.Name');                          
                    }                    
                    else {                     	
                        setfieldNames.add(fieldSetValues[c].name.substring(0, fieldSetValues[c].name.indexOf('__c')) + '__r.Name');                              }                 }             }         }         var arrfieldNames = [];         setfieldNames.forEach(v => arrfieldNames.push(v));
        action.setParams({
            sObjectName: "Signer_Portal_Status__c",
            recordIdName: "Id",
            recordId:  component.get("v.signerRec.Id"),
            fieldNameJson: JSON.stringify(arrfieldNames)
        });
        action.setCallback(this, function(response) {
            var list = JSON.parse(response.getReturnValue());            
            component.set("v.tableRecordsForStatus", list);
            this.hideSpinner(component);
            component.set("v.showChild", true);            
        })
        $A.enqueueAction(action);
    },
    
   getDateTime: function (component, event, helper, time)  {
   // Check correct time format and split into components
   time = "".toString ().match (/^([01]\d|2[0-3])(:)([0-5]\d)(:[0-5]\d)?$/) || [time];

    if (time.length > 1) { // If time format correct
      time = time.slice (1);  // Remove full string match value
      time[5] = +time[0] < 12 ? 'AM' : 'PM'; // Set AM/PM
      time[0] = +time[0] % 12 || 12; // Adjust hours
    }
    return time.join (''); // return adjusted time or original string
  },
    
    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    }  
})