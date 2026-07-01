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

    // SAL-7243 — when the Quick App was launched from a New Quote that carried a
    // dealer, saveCompany inserts a Dealer__c junction on the new Opportunity but
    // the wizard's client-side dealerAccounts list stays empty, so the Partners
    // tab renders "Dealers (0)". Here, on Partners-tab init, we read the
    // Opportunity's actual persisted dealer junctions (server truth) and show
    // them as read-only rows — mirroring a dealer the user picks via the lookup.
    // Guarded on opportunity.Id so it only runs after saveCompany; never touches
    // saveCompany's path. Idempotent: skips if a dealer row already exists.
    prefillQuoteDealer: function (cmp) {
        var clientWrapper = cmp.get("v.clientWrapper");
        if (!clientWrapper || !clientWrapper.deal || !clientWrapper.deal.opportunity) {
            return;
        }
        var oppId = clientWrapper.deal.opportunity.Id;
        if (!oppId) {
            return; // Opportunity not created yet — do nothing during saveCompany.
        }

        if (!Array.isArray(clientWrapper.dealerAccounts)) {
            clientWrapper.dealerAccounts = [];
        }
        var alreadyHasDealer = clientWrapper.dealerAccounts.some(function (wr) {
            return wr && wr.account && wr.account.Id;
        });
        if (alreadyHasDealer) {
            return;
        }

        var action = cmp.get("c.getDealerAccountsForOpp");
        action.setParams({ opportunityId: oppId });
        action.setCallback(this, function (response) {
            if (response.getState() !== "SUCCESS") {
                console.warn("SAL-7243 dealer prefill failed:", response.getError());
                return;
            }
            var dealerAccounts = response.getReturnValue() || [];
            if (!dealerAccounts.length) {
                return;
            }
            var cw = cmp.get("v.clientWrapper");
            if (!Array.isArray(cw.dealerAccounts)) {
                cw.dealerAccounts = [];
            }
            dealerAccounts.forEach(function (acc) {
                var dup = cw.dealerAccounts.some(function (wr) {
                    return wr && wr.account && wr.account.Id === acc.Id;
                });
                if (!dup) {
                    cw.dealerAccounts.push({
                        account: acc,
                        readOnly: true,
                        dupe: false,
                        subRecord: { contact: { sobjectType: "Contact" }, readOnly: false, dupe: false }
                    });
                }
            });
            cmp.set("v.clientWrapper", cw);
        });
        $A.enqueueAction(action);
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
        console.log('quickSaveHelper');
        console.log(JSON.stringify(cmp.get('v.clientWrapper.dealerAccounts')));

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