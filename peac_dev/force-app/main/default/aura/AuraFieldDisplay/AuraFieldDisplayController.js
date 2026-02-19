({
    doChange : function (component, event, helper) {
        var sobj = component.get('v.sObject');
        var field = component.get('v.field');
        console.log(field.fieldName);
        console.log(field.fieldValue);
        sobj[field.fieldName] = field.fieldValue;
        component.set('v.sObject',sobj);
    },
    doValidateField: function (component, event, helper) {
        var allValid = true;
        var fieldDisplay = component.find('aura_field_display_input');
        if (!$A.util.isEmpty(fieldDisplay)) {
            if ($A.util.isArray(fieldDisplay)) {
                allValid = fieldDisplay.reduce(function (validSoFar, inputcomponent) {
                    inputcomponent.showHelpMessageIfInvalid();
                    if (!$A.util.isEmpty(inputcomponent.checkValidity())) return validSoFar && inputcomponent.checkValidity();
                    else return validSoFar;
                }, true);
            } else {
                fieldDisplay.showHelpMessageIfInvalid();
                allValid = fieldDisplay.checkValidity();
            }
        }

        return allValid;
    },
});