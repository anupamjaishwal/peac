({
    handleInit : function (component, event, helper) {
        let params = new Object();
        params.recId = component.get('v.recordId');
        params.parentIdField = component.get('v.parentRecordField');
        params.fieldSetName = component.get('v.childObjToRelFldToFieldSet');
        params.subQueryRelationship = component.get('v.childRelationshipName');
        params.whereConditions = component.get('v.whereConds');
        params.orderByConditions = component.get('v.orderByConds');
        params.recordLimit = parseInt(component.get('v.limit'));

        if (
            !$A.util.isEmpty(params.recId) &&
            !$A.util.isEmpty(params.parentIdField) &&
            !$A.util.isEmpty(params.fieldSetName) &&
            !$A.util.isEmpty(params.subQueryRelationship)
        ) {
            let apexCall = component.get('c.handleChildRecordInitFromParentField');

            apexCall.setParams(params);
            apexCall.setCallback(this, function(response) {
                let state = response.getState();

                if (state === 'SUCCESS') {
                    let respObj = response.getReturnValue();
                    
                    component.set('v.respObj',respObj);
                    component.set('v.fields',respObj.fieldList);
                    component.set('v.childRecords',respObj.sObjects);
                    component.set('v.childSObjType',respObj.objectName);
                    console.log(component.get('v.childSObjType'));
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