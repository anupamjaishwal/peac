({
    handleInit : function (component, event, helper) {
        if (!$A.util.isEmpty(component.get('v.childObjToRelFldToFieldSet'))) {
            var params = new Object();
            params.parentRecordID = component.get('v.recordId');
            params.childObjParentFldFieldSet = component.get('v.childObjToRelFldToFieldSet');
            params.whereConditions = component.get('v.whereConds');
            params.orderByConditions = component.get('v.orderByConds');
            params.recordLimit = parseInt(component.get('v.limit'));

            var apexCall = component.get('c.handleChildRecordInit');
            apexCall.setParams(params);
            apexCall.setCallback(this, function(response) {
                var state = response.getState();

                if (state === 'SUCCESS') {
                    let respObj = response.getReturnValue();
                    component.set('v.fields',respObj.fieldList);
                    component.set('v.childRecords',respObj.sObjects);
                    component.set('v.childSObjType',respObj.objectName);
                    component.set('v.parentRelationshipField',respObj.parentIdFieldNm);
                    let parentFieldToId = new Object();
                    parentFieldToId[component.get('v.parentRelationshipField')] = component.get('v.recordId');
                    component.set('v.parentFieldToId',parentFieldToId);
                } else {
                    console.log(response.result);
                }
            });
            $A.enqueueAction(apexCall);
        }
    },
    handleAddNewChildRecord : function (component, event, helper) {
        let childRecs = component.get('v.childRecords');
        let newChild = new Object();
        newChild.sobjectType = component.get('v.childSObjType');
        newChild[component.get('v.parentRelationshipField')] = component.get('v.recordId');

        childRecs.push(newChild);
        component.set('v.childRecords',childRecs);
    },
    handleSaveChildRecords : function (component, event, helper) {

    },
});