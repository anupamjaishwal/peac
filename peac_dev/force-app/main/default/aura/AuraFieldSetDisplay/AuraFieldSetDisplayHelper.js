({
    initialize : function(component, event, helper) {
        var sObjectName = component.get('v.sObjectName');
        sObjectName = $A.util.isEmpty(sObjectName) ? component.get('v.objType') : sObjectName;
        if ($A.util.isEmpty(component.get('v.objType'))) component.set('v.objType',sObjectName);
        component.set('v.sObjectName',sObjectName);
        console.log(component.get('v.objType'));
        var fieldSetName = component.get('v.fieldSetName');
        if ($A.util.isEmpty('v.recId') && $A.util.isEmpty(component.get('v.recordId')) && !$A.util.isEmpty(component.get('v.rec'))) {
            component.set('v.recId',component.get('v.rec').Id);
        }
        if (!$A.util.isEmpty(component.get('v.fields')) && $A.util.isArray(component.get('v.fields'))) {
            this.processFields(component, component.get('v.fields'));
        }
        console.log(component.get('v.recId'));
        console.log(component.get('v.recordId'));
        console.log(component.get('v.fields'));
        if ($A.util.isEmpty(component.get('v.fields')) && $A.util.isEmpty(component.get('v.record'))) {
            if (!$A.util.isEmpty(sObjectName) && !$A.util.isEmpty(fieldSetName)) {
                var apexCall = component.get('c.getFieldsFromFieldSet');
                var params = new Object();
                params.objectName = sObjectName;
                params.fieldSetName = fieldSetName;
                apexCall.setParams(params);

                apexCall.setCallback(this, function(response) {
                    var state = response.getState();

                    if (state === 'SUCCESS') {
                        var fsDisplayResult = response.getReturnValue();
                        if (!$A.util.isEmpty(fsDisplayResult) && $A.util.isObject(fsDisplayResult)) {
                            var errors = fsDisplayResult.errors;

                            if (!$A.util.isEmpty(errors)) {
                                var errorsConcat = '';
                                for (var i = 0, error; error=errors[i]; i++) {
                                    if (i != 0) errorsConcat+=';';
                                    errorsConcat+=error.message;
                                }
                                console.log('Errors from apex controller:'+errorsConcat);
                                this.errorToast(errorsConcat);
                            } else {
                                let fields = fsDisplayResult.fields;
                                if (!$A.util.isEmpty(fields) && $A.util.isArray(fields)) {
                                    this.processFields(component, fields);
                                }
                                if (!$A.util.isEmpty(fsDisplayResult.objectName)) {
                                    component.set('v.sObjectName',fsDisplayResult.objectName);
                                }
                                if (!$A.util.isEmpty(fsDisplayResult.recordId)) {
                                    component.set('v.recordId',fsDisplayResult.recordId);
                                }
                            }
                        }


                    } else {
                        console.log('Apex call failed! Code:'+state);
                        this.errorToast('Apex call failed! Code:'+state);
                    }
                });
                $A.enqueueAction(apexCall);
            }
        }
    },

   /* handleSubmit : function (component, event, helper) {
        let defaultVals = component.get('v.defaultVals');
        let recordId = component.get('v.recordId');
        if($A.util.isObject(defaultVals) && !$A.util.isEmpty(defaultVals) && $A.util.isEmpty(recordId)) {
            event.preventDefault();       // stop the form from submitting
            const fields = event.getParam('fields');
            for (let [key, value] of Object.entries(defaultVals)) {
                fields[key] = value;
            }
            component.find('fieldSetDisplay').submit(fields);
        }
    }, */
    
    handleSubmit : function (component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        const fields = event.getParam('fields');
        if(component.get('v.respObj'))
            fields.AccountId = component.get('v.respObj').parentId // modify a field
            component.find('fieldSetDisplay').submit(fields);   
        
    } ,   

    errorToast: function(errorMsg) {
        if (!$A.util.isEmpty(errorMsg)) {
            var resultsToast = $A.get("e.force:showToast");
            if ($A.util.isUndefined(resultsToast)) {
                alert(errorMsg);
            }else {
                resultsToast.setParams({
                    "title": "Error",
                    "message": errorMsg
                });
                resultsToast.fire();
            }
        }
    }, 

    processFields : function (component, fields) {
        let defaultVals = component.get('v.defaultVals');
        if ($A.util.isEmpty(component.get('v.recordId')) && !$A.util.isEmpty(defaultVals) && $A.util.isObject(defaultVals)) {
            let defaultFlds = Object.keys(defaultVals);
            let tempFlds = [];
            for (let i = 0; i < fields.length; i++) {
                let field = fields[i];
                if (!defaultFlds.includes(field)) tempFlds.push(field);
            }
            fields = tempFlds;
        }

        component.set('v.fields', fields);
    },
})