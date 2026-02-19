({
    initialize : function(component, event, helper) {
        var fields = component.get('v.fields');
        var lookupObjectType = component.get('v.lookupObjectType');
        var lookupObjectId = component.get('v.lookupObjectId');
        var lookupFieldToFieldSet = component.get('v.lookupFieldToFieldSet');
        var lookupFieldName = component.get('v.lookupFieldName');
        var fieldSetName = component.get('v.fieldSetName');
        var recId = component.get('v.recordId');

        if($A.util.isEmpty(lookupFieldToFieldSet) && !$A.util.isEmpty(fieldSetName) && !$A.util.isEmpty(lookupFieldName)) {
            lookupFieldToFieldSet = ''+lookupFieldName+':'+fieldSetName;
            component.set('v.lookupFieldToFieldSet',lookupFieldToFieldSet);
        }

        if (!$A.util.isEmpty(lookupFieldToFieldSet) && ($A.util.isEmpty(fields) || $A.util.isEmpty(lookupObjectType))) {

            var apexCall = component.get('c.getFieldsFromLookupFieldAndFieldSet');
            var params = new Object();
            params.lookupFieldToFieldSet = lookupFieldToFieldSet;
            params.recordId = recId;
            apexCall.setParams(params);
            console.log(params);

            apexCall.setCallback(this, function(response) {
                var state = response.getState();
                console.log(state);
                if (state === 'SUCCESS') {
                    var obj = response.getReturnValue();

                    if (!$A.util.isUndefinedOrNull(obj) && $A.util.isObject(obj)) {
                        if ($A.util.isEmpty(obj.errors)) {
                            if ($A.util.isEmpty(fields) && !$A.util.isEmpty(obj.fields) && $A.util.isArray(obj.fields)) {
                                fields = obj.fields;
                                component.set('v.fields',fields);
                            }
                            if ($A.util.isEmpty(lookupObjectType)) {
                                lookupObjectType = obj.objectName;
                                component.set('v.lookupObjectType',lookupObjectType);
                            }
                            if ($A.util.isEmpty(lookupObjectId)) {
                                lookupObjectId = obj.recordId;
                                component.set('v.lookupObjectId',lookupObjectId);
                            }
                        }

                        var errorMsg = '';
                        var errors = obj.errors;
                        if (!$A.util.isEmpty(errors)) {
                            for (var i = 0, error; error=errors[i]; i++) {
                                if (i != 0) errorMsg+=';';
                                errorMsg+=error.message;
                            }
                        }
                        /* Disabling error message due to this component being placed on the portal where there may not
                           be any directly associated record, especially when working on the portal configuration
                        if (!$A.util.isEmpty(lookupObjectId)) {

                            if ($A.util.isEmpty(lookupObjectType)) errorMsg+= (!$A.util.isEmpty(errorMsg) ? ';' : '') + 'No lookup object was found! ';
                            if ($A.util.isEmpty(fields)) errorMsg+= (!$A.util.isEmpty(errorMsg) ? ';' : '') + 'No fields were found! ';
                        }
                         */

                        if (!$A.util.isEmpty(errorMsg)) {
                            console.log('Errors: '+errorMsg);
                            this.errorToast(errorMsg);
                        }
                    }
                } else {
                    var stateErrors = response.getError();
                    var message = 'Unknown error';
                    if (stateErrors && Array.isArray(stateErrors) && stateErrors.length > 0) {
                        message = stateErrors[0].message;
                    }

                    //Since we are displaying this component on the portal where it may have no recordId, need to not
                    //an error about not having a recordId
                    if (!message.includes("'recordId'") && !message.includes("'Id'")) {
                        this.errorToast(message);
                        console.error(message);
                    }
                }
            });
            $A.enqueueAction(apexCall);
        }
    },

    errorToast: function(errorMsg) {
        if (!$A.util.isEmpty(errorMsg)) {
            var resultsToast = $A.get("e.force:showToast");
            if ($A.util.isUndefined(resultsToast)){
                alert(errorMsg);
            } else {
                resultsToast.setParams({
                    "title": "Error",
                    "message": errorMsg
                });
                resultsToast.fire();
            }
        }
    }
})