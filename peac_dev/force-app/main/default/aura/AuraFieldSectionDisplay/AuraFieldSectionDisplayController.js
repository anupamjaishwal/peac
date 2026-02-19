({
    doInit : function (component, event, helper) {
        var headerSectionMap = component.get('v.sectionToFieldMap');
        var headerName = component.get('v.sectionName');
        var sObject = component.get('v.sObject');
        var prePopulate = component.get('v.prePopulate');
        var fldList = component.get('v.fieldList');
        if ($A.util.isEmpty(fldList) && !$A.util.isEmpty(headerSectionMap)) component.set('v.fieldList',headerSectionMap[headerName]);
        if (!$A.util.isEmpty(sObject)) {
            for (var i = 0; i < fldList.length; i++) {
                var field = fldList[i];
                if (!prePopulate) field.fieldValue = null;
                if (!sObject.hasOwnProperty(field.fieldName)) sObject[field.fieldName] = field.fieldValue;
            }
            component.set('v.sObject',sObject);
        }
    },
    doValidateFields: function (component, event, helper) {
        console.log('doValidateFields');
        var fieldsValid = true;
        var fieldDisplays = component.find('auraFieldDisplay');
        if (!$A.util.isEmpty(fieldDisplays)) {

            if (typeof component.find('auraFieldDisplay').getConcreteComponent === 'undefined') { //then it's an array
                //alert('inside eq if #2');
                fieldsValid = component.find('auraFieldDisplay').reduce(function (validSoFar, inputcomponent) {
                    //alert('inside fieldsValid = component.find');
                    var valid2 = inputcomponent.validateField();

                    return validSoFar && valid2;
                }, true);
                console.log('array:'+fieldsValid);
            } else {
                fieldsValid = component.find('auraFieldDisplay').validateField();
                console.log('singular'+fieldsValid);
            }
        }
        return fieldsValid;
    },
});