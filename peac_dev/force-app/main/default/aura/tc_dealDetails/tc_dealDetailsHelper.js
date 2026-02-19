/**
 * Created on 12/30/17.
 */
({
    getQuoteOptions : function (cmp) {
        /*
        var action = cmp.get('c.getQuoteOptionsByDealId');
        action.setParams ({
            dealId: cmp.get('v.deal').Id
        });
        console.log(cmp.get('v.deal').Id);
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                console.log(result.getReturnValue());
                /*cmp.set('v.quoteOptions', result.getReturnValue());
            } else {
                console.log(result.getError());
            }
        });

        $A.enqueueAction (action);*/
    },
    
    setMasterLine : function (cmp) {
        /*
        var action = cmp.get('c.getMasterLine');
        
        action.setParams ({
            masterLineId: cmp.get('v.masterLineId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                cmp.set('v.masterLine', result.getReturnValue());
            } else {
                console.log(result.getError());
            }
        });

        $A.enqueueAction (action);*/
    },
    
    quickSave : function (cmp, event, helper) {
        TCLightningUtils.showSpinner(cmp);
        var action;

        //var deal = cmp.get('v.deal');


        action = cmp.get('c.saveDeal');
        action.setParams({
            clientWrapperString: JSON.stringify(cmp.get ('v.clientWrapper'))
        })

        action.setCallback(this, function (result) {
            TCLightningUtils.hideSpinner(cmp);
            if (result.getState() === 'SUCCESS') {
                //console.log(result.getReturnValue());
                var returnedValue = JSON.parse(result.getReturnValue());
                cmp.set('v.clientWrapper', returnedValue);
                //TCLightningUtils.showToast('Success', 'Record saved.', 'success');
                this.goToNextHelper ();
            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');

            }
        });
        $A.enqueueAction(action);
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
    
    grabSalesRepsHelper : function (cmp, event, helper) {
        //TCLightningUtils.showSpinner(cmp);

/*
        var action = cmp.get('c.getSalesReps');

        action.setCallback(this, function (result) {
            //TCLightningUtils.hideSpinner(cmp);
            if (result.getState() === 'SUCCESS') {
                cmp.set('v.salesreps', result.getReturnValue());
            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');

            }
        });
        $A.enqueueAction(action);*/
    },

    saveAndQuitDealHelper: function (cmp) {

        var saveAndQuitAction = cmp.get('c.submitApplication');
        TCLightningUtils.showSpinner(cmp);
                var action;

                //var deal = cmp.get('v.deal');


                action = cmp.get('c.saveDeal');
                action.setParams({
                    clientWrapperString: JSON.stringify(cmp.get ('v.clientWrapper'))
                })

                action.setCallback(this, function (result) {
                    TCLightningUtils.hideSpinner(cmp);
                    if (result.getState() === 'SUCCESS') {
                        TCLightningUtils.showSpinner(cmp);
                        //console.log(result.getReturnValue());
                        var returnedValue = JSON.parse(result.getReturnValue());
                        cmp.set('v.clientWrapper', returnedValue);
                        //TCLightningUtils.showToast('Success', 'Record saved.', 'success');
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
                    } else {
                        console.log(result.getError());
                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');

                    }
                });
                $A.enqueueAction(action);

                },
})