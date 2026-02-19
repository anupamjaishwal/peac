({
    doInit : function (cmp, event, helper) {
        
        // cpu limit logic
        
        const empApi = cmp.find('empApi');
        const channel = '/event/TC_Quick_App_Notification__e';
        const replayId = -1;
        
        empApi.onError($A.getCallback(error => {
            // Error can be any type of error (subscribe, unsubscribe...)
            alert('EMP API error: ' + JSON.stringify(error));
        }));
            
        
        
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            // Process event (this is called each time we receive an event)
            //alert ('hello' + eventReceived.data.payload.Opportunity_Id__c + ' ' + eventReceived.data.payload.Action__c);
            //alert ('compare ' + eventReceived.data.payload.Opportunity_Id__c + ' = ' + cmp.get ('v.clientWrapper.deal.opportunity.Id'));
            //alert ('eventReceived.data.payload.Action__c:' + eventReceived.data.payload.Action__c);
            if (eventReceived.data.payload.Opportunity_Id__c  == cmp.get ('v.clientWrapper.deal.opportunity.Id')) {
            	var spinner = cmp.find('spinner');
            
            	
            
            if (eventReceived.data.payload.Action__c == 'save_equipment' ) {
            	$A.util.removeClass(spinner, 'slds-show');
            	$A.util.addClass(spinner, 'slds-hide');
            
            	if (eventReceived.data.payload.Status__c == 'Success') {
            
            		cmp.set('v.clientWrapper', JSON.parse(eventReceived.data.payload.Json_Data__c));
					helper.goToNextHelper ();

        		} else if (eventReceived.data.payload.Status__c == 'Failure') {
        			TCLightningUtils.showToast('Error', eventReceived.data.payload.Message__c, 'error');
        		}
            
        	} else if (eventReceived.data.payload.Action__c == 'save_equipment_and_quit') {
                   if (eventReceived.data.payload.Status__c == 'Success') {
            				//alert ('jsonhi'); 
            				cmp.set('v.clientWrapper', JSON.parse(eventReceived.data.payload.Json_Data__c));
							var saveAndQuitAction = cmp.get('c.submitApplication');
            				saveAndQuitAction.setParams({clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))});

                                                                                    saveAndQuitAction.setCallback(this, function (result) {
                                                                                        $A.util.removeClass(spinner, 'slds-show');
            																			$A.util.addClass(spinner, 'slds-hide');
                                                                                        if (result.getState() === 'SUCCESS') {
                                                                                            TCLightningUtils.showToast('Success', 'Deal Saved. Press the Edit Deal in Wizard button to return.', 'success');
                                                                                            $A.get("e.force:navigateToURL").setParams({ "url": "/" + result.getReturnValue()}).fire();
                                                                                        } else {
                                                                                            console.log(result.getError());
                                                                                            TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                                                                                        }
                                                                                    });


                                                                                    $A.enqueueAction(saveAndQuitAction);

        		} else if (eventReceived.data.payload.Status__c == 'Failure') {
        			TCLightningUtils.showToast('Error', eventReceived.data.payload.Message__c, 'error');
        		}      
            }
            
            	
        	}
            
        	
        }))
        .then(subscription => {
            // Confirm that we have subscribed to the event channel.
            // We haven't received an event yet.
            //alert ('Subscribed to channel '+ subscription.channel);
            // Save subscription to unsubscribe later
            cmp.set('v.subscription', subscription);
        });
        
        // end cpu limit logic
        
        
        
        
        var equipmentList = cmp.get("v.clientWrapper.equipment");
        if (equipmentList.length < 1) {
            helper.addEquipment(cmp);
        }

        //helper.getPicklists(cmp);
    },

    addEquipment: function (cmp, event, helper) {
        helper.addEquipment(cmp);
    },

    deleteItem : function (cmp, event, helper) {
        helper.clearItemHelper (cmp, event, helper);


        var equipmentList = cmp.get("v.clientWrapper.equipment");
        var indexVal = event.getSource().get('v.value');
        equipmentList.pop(indexVal);
        cmp.set("v.clientWrapper.equipment", equipmentList);
    },

    clearItem : function (cmp, event, helper) {
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

    quickSave : function (cmp, event, helper) {
        helper.quickSave(cmp, event, helper);
    },

    goToNext : function (cmp, event, helper) {
        var navEvent = $A.get("e.c:tc_applicationNavigation_evt");
        var dir = "next";
        
        navEvent.setParams({
            data: {
                direction: dir
            }
        });
        
        navEvent.fire();
    },
    saveAndQuitEQController : function (cmp, event, helper) {
                        helper.saveAndQuitEQHelper (cmp);
             },
})