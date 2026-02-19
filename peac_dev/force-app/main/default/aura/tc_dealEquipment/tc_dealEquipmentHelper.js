/**
 * Created on 1/2/18.
 */
({
    addEquipment: function (cmp) {


    var equipmentList = cmp.get("v.clientWrapper.equipment");

     var eqWrapper = {};
     var eq = {};
     eq.sobjectType = 'Asset__c';
     eq.Quantity__c = 1;
     eq.New_Used__c = 'New';
     eq.Sleeper_Day_Cab__c = 'No';
     eq.End_User_Billing_Address__c = false;

     eqWrapper.equipment = eq;

     equipmentList.push(eqWrapper);
     cmp.set("v.clientWrapper.equipment", equipmentList);

    },

    quickSave: function (cmp, event, helper) {



        TCLightningUtils.showSpinner(cmp);


        var action = cmp.get('c.saveEquipment');

        action.setParams({
            clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
            , fromAsync : false
            , action : 'save_equipment'
        });

        action.setCallback(this, function (result) {
            //TCLightningUtils.hideSpinner(cmp); commented out for cpu issue bandaid

            
            if (result.getState() === 'SUCCESS') {
                var returnedValue = JSON.parse(result.getReturnValue());
                cmp.set('v.clientWrapper', returnedValue);
				//this.goToNextHelper ();
            } else {
                console.log(result.getError());
                TCLightningUtils.hideSpinner(cmp); //added for cpu issue bandaid
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(action);
    },

    goToNext: function (cmp, event, helper) {
        var navEvent = $A.get("e.c:tc_applicationNavigation_evt");
        var dir = "next";

        navEvent.setParams({
            data: {
                direction: dir
            }
        });

        navEvent.fire();
    },
    
    getPicklists: function (cmp) {
        /*
        var action = cmp.get('c.getDependentPicklists');

        action.setParams({
        });

        action.setCallback(this, function (result) {
            console.log('getPicklists', result.getReturnValue());
            
            if (result.getState() === 'SUCCESS') {
                cmp.set('v.picklists', result.getReturnValue());
            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(action);*/
    },
    goToNextHelper : function () {
        var navEvent = $A.get("e.c:tc_applicationNavigation_evt");
        var dir = "next";
        
        navEvent.setParams({
            data: {
                direction: dir
            }
        });
        
        navEvent.fire();
    },
    saveAndQuitEQHelper: function (cmp) {

            //var saveAndQuitAction = cmp.get('c.submitApplication'); cpu temp

            TCLightningUtils.showSpinner(cmp);


                    var action = cmp.get('c.saveEquipment');

                    action.setParams({
                        clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
                        , fromAsync : false
                        , action : 'save_equipment_and_quit'
                    });

                    action.setCallback(this, function (result) {
                        //TCLightningUtils.hideSpinner(cmp); cpu temp work around

						
                        if (result.getState() === 'SUCCESS') {
                            /*var returnedValue = JSON.parse(result.getReturnValue());
                            cmp.set('v.clientWrapper', returnedValue);
            				saveAndQuitAction.setParams({clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))});

                                                                                    saveAndQuitAction.setCallback(this, function (result) {
                                                                                        TCLightningUtils.hideSpinner(cmp);
                                                                                        if (result.getState() === 'SUCCESS') {
                                                                                            TCLightningUtils.showToast('Success', 'Deal Saved. Press the Edit Deal in Wizard button to return.', 'success');
                                                                                            $A.get("e.force:navigateToURL").setParams({ "url": "/" + result.getReturnValue()}).fire();
                                                                                        } else {
                                                                                            console.log(result.getError());
                                                                                            TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                                                                                        }
                                                                                    });


                                                                                    $A.enqueueAction(saveAndQuitAction);
                        */} else {
                            console.log(result.getError());
                            var spinner = cmp.find('spinner');
                            $A.util.removeClass(spinner, 'slds-show');
            				$A.util.addClass(spinner, 'slds-hide');
                            
                            TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                        }
                    });
                    $A.enqueueAction(action);

                    },
                    clearItemHelper : function (cmp, event, helper) {
                            var equipmentList = cmp.get("v.clientWrapper.equipment");

                            var indexVal = event.getSource().get('v.value');

                            var equipment = {sobjectType: 'Asset__c'};
                            equipment.Quantity__c = 1;
                            equipment.New_Used__c = 'New';
                            equipment.Sleeper_Day_Cab__c = 'No';
                            equipment.End_User_Billing_Address__c = false;


                            equipmentList[indexVal] = equipment;
                            console.log(equipmentList);
                            cmp.set("v.clientWrapper.equipment", equipmentList);
                        },
})