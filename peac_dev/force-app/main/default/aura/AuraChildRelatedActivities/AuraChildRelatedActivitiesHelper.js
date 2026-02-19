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
                console.log(state);
                if (state === 'SUCCESS') {
                    let respObj = response.getReturnValue();
                    component.set('v.childRecords',respObj.sObjects);
                    component.set('v.childSObjType',respObj.objectName);
                    let describedSObjectFields = respObj.describedSobjectFieldsWithData;
                    if (!$A.util.isEmpty(describedSObjectFields)) {
                        component.set('v.describedSObjectFields', describedSObjectFields);
                    }

                    console.log(component.get('v.childSObjType'));
                    console.log(component.get('v.childRecords'));
                    console.log($A.util.isEmpty(component.get('v.describedSObjectFields')));
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
    navToActivity : function (component, event, helper) {
        let navService = component.find("navService");
        let pageReference = {};
        pageReference.type = "standard__recordPage"; //example for opening a record page, see bottom for other supported types
        pageReference.attributes = {};
        pageReference.attributes.recordId = event.getSource().get('v.value'); //place your record id here that you wish to open
        console.log(event.getSource().get('v.value'));
        pageReference.attributes.actionName = 'view';
        navService.generateUrl(pageReference).then(
            $A.getCallback(function(url) {
                console.log('success: ' + url); //you can also set the url to an aura attribute if you wish
                window.open(url,'_blank'); //this opens your page in a seperate tab here
            }),
            $A.getCallback(function(error) {
                console.log('error: ' + error);
            })
        );
    },
});