({
    doInit : function (cmp, event, helper) {
        //helper.addDealerHelper(cmp);
        //helper.getPicklists(cmp);
        var recordTypeName = cmp.get("v.clientWrapper.recordTypeName");
        console.log(recordTypeName);

        // SAL-7243 — surface the dealer that came from a New Quote on the
        // Partners tab. Runs here (Partners-tab init, after saveCompany has
        // created the Opportunity) rather than at wizard init, so saveCompany
        // is never affected.
        helper.prefillQuoteDealer(cmp);
    },
    recordUpdate: function(cmp, event, helper) {
        
        if($A.get("$Label.c.ExpressRepBrokerTab")) {
            let labelValue = $A.get("$Label.c.ExpressRepBrokerTab");
            console.log('labelValue::',labelValue);
            let expressProfileList = labelValue.split(',');
            console.log('expressProfile::',expressProfileList);
            let currentProfileName = cmp.get('v.currentUser')["Profile"].Name;
            console.log('currentProfileName::',currentProfileName);
            if(expressProfileList.includes(currentProfileName)) {
                cmp.set('v.expressProfile',true);
            }
        }
    },

    addBroker: function (cmp, event, helper) {
        helper.addBrokerHelper(cmp);
    },

    deleteBrokerItem : function (cmp, event, helper) {
        var brokerList = cmp.get("v.clientWrapper.brokerAccounts");

        var indexVal = event.getSource().get('v.value');

        brokerList.pop(indexVal);
        console.log(brokerList);
        cmp.set("v.clientWrapper.brokerAccounts",brokerList);
    },

    clearBrokerItem : function (cmp, event, helper) {
        var brokerList = cmp.get("v.clientWrapper.brokerAccounts");

        var indexVal = event.getSource().get('v.value');

        var broker = {sobjectType: 'Account'};

        brokerList[indexVal] = broker;
        cmp.set("v.clientWrapper.brokerAccounts",brokerList);
    },

    addDealer: function (cmp, event, helper) {
            helper.addDealerHelper(cmp);
    },

    deleteDealerItem : function (cmp, event, helper) {
            var dealerList = cmp.get("v.clientWrapper.dealerAccounts");
            var indexVal = event.getSource().get('v.value');
            dealerList.pop(indexVal);
            console.log(dealerList);
            cmp.set("v.clientWrapper.dealerAccounts",dealerList);
    },

    clearDealerItem : function (cmp, event, helper) {
            var dealerList = cmp.get("v.clientWrapper.dealerAccounts");

            var indexVal = event.getSource().get('v.value');

            var dealer = {sobjectType: 'Account'};

            dealerList[indexVal] = dealer;
            cmp.set("v.clientWrapper.dealerAccounts",dealerList);
    },
    addFranchisor: function (cmp, event, helper) {
                helper.addFranchisorHelper(cmp);
        },

        deleteFranchisorItem : function (cmp, event, helper) {
                var franchisorList = cmp.get("v.clientWrapper.franchisorAccounts");
                var indexVal = event.getSource().get('v.value');
                franchisorList.pop(indexVal);
                cmp.set("v.clientWrapper.franchisorAccounts",franchisorList);
        },

        clearFranchisorItem : function (cmp, event, helper) {
                var franchisorList = cmp.get("v.clientWrapper.franchisorAccounts");

                var indexVal = event.getSource().get('v.value');

                var franchisor = {sobjectType: 'Account'};

                franchisorList[indexVal] = franchisor;
                cmp.set("v.clientWrapper.franchisorAccounts",franchisorList);
        },


    //Franchisor

    quickSave : function (cmp, event, helper) {
        helper.quickSaveHelper(cmp, event, helper);
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
    saveAndQuitPartnerController : function (cmp, event, helper) {
                        helper.saveAndQuitPartnerHelper (cmp);
             },
})