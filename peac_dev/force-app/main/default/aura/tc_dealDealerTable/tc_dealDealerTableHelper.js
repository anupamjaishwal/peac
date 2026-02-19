/**
 * Created on 1/2/18.
 */
({
    addDealerHelper: function (cmp) {
        var dealerList = cmp.get("v.clientWrapper.dealerAccounts");
        var dealer = {sobjectType: 'Account'};
        dealerList.push(dealer);
        cmp.set("v.clientWrapper.dealerAccounts", dealerList);
    },

    addBrokerHelper: function (cmp) {
            var brokerList = cmp.get("v.clientWrapper.brokerAccounts");
            var broker = {sobjectType: 'Account'};
            brokerList.push(broker);
            cmp.set("v.clientWrapper.brokerAccounts", brokerList);
        },

     addFranchisorHelper: function (cmp) {
                 var franchisorList = cmp.get("v.clientWrapper.franchisorAccounts");
                 var franchisor = {sobjectType: 'Account'};
                 franchisorList.push(franchisor);
                 cmp.set("v.clientWrapper.franchisorAccounts", franchisorList);
             },






    quickSaveHelper: function (cmp, event, helper) {

        TCLightningUtils.showSpinner(cmp);
        var action = cmp.get('c.savePartners');

        action.setParams({
            clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
        });

        action.setCallback(this, function (result) {
                    TCLightningUtils.hideSpinner(cmp);
                    if (result.getState() === 'SUCCESS') {

                    var returnedValue = JSON.parse(result.getReturnValue());
                        cmp.set('v.clientWrapper', returnedValue);
                        this.goToNextHelper ();
                    } else {
                        console.log(result.getError());
                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');

                    }
                });
                $A.enqueueAction(action);



/*

        TCLightningUtils.showSpinner(cmp);
        var action = cmp.get('c.savePartners');

        action.setParams({
            clientWrapperString: JSON.stringify(cmp.get ())
        });

        action.setCallback(this, function (result) {
            TCLightningUtils.hideSpinner(cmp);


            if (result.getState() === 'SUCCESS') {
                console.log('eq quick save return', result.getReturnValue());
                cmp.set('v.equipmentList', result.getReturnValue().equipment);
                cmp.set('v.deal', result.getReturnValue().deal);
                //TCLightningUtils.showToast('Success', 'Records saved.', 'success');
				this.goToNextHelper ();
            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(action);*/
    },

    goToNextHelper: function (cmp, event, helper) {
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
    saveAndQuitPartnerHelper: function (cmp) {

            var saveAndQuitAction = cmp.get('c.submitApplication');

            TCLightningUtils.showSpinner(cmp);
                    var action = cmp.get('c.savePartners');

                    action.setParams({
                        clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
                    });

                    action.setCallback(this, function (result) {
                                TCLightningUtils.hideSpinner(cmp);
                                if (result.getState() === 'SUCCESS') {
                                    TCLightningUtils.showSpinner(cmp);

                                var returnedValue = JSON.parse(result.getReturnValue());
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
                                } else {
                                    console.log(result.getError());
                                    TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');

                                }
                            });
                            $A.enqueueAction(action);

                    },
})