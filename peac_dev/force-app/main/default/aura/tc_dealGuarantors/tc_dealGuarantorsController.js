({
    addGuarantor: function (cmp, event, helper) {
        helper.addGuarantor(cmp);
    },
    addCCGuarantor: function (cmp, event, helper) {
            helper.addCCGuarantorHelper(cmp);
    },


    doInit : function (cmp, event, helper) {
        var guarantors = cmp.get("v.guarantors");
        
        //if (guarantors.length == 0)
         //   helper.addGuarantor(cmp);
    },

    deleteItem : function (cmp, event, helper) {
        helper.deleteGuarantor(cmp, event, helper);
    },

    deleteCCGItem : function (cmp, event, helper) {
            helper.deleteCCG(cmp, event, helper);
    },

    clearPGItem : function (cmp, event, helper) {
        var guarantors = cmp.get("v.clientWrapper.pgContacts");

        var indexVal = event.getSource().get('v.value');

        var guarantor = {};
        guarantor.sobjectType = 'Contact';
        guarantor.MailingCountryCode = 'US';
        guarantor.OtherCountryCode = 'US';
        guarantors[indexVal] = guarantor;
        console.log(guarantors);
        cmp.set("v.clientWrapper.pgContacts",guarantors);
    },
    clearCCGItem : function (cmp, event, helper) {

    var guarantors = cmp.get("v.clientWrapper.ccgAccounts");

    var guarantorWrapper = {};
    var guarantor = {};
                    guarantor.sobjectType = 'Account';
                    guarantor.MailingCountryCode = 'US';
                    //guarantor.OtherCountryCode = 'US';
                    guarantorWrapper.readOnly = false;
                    guarantorWrapper.dupe = false;
                    guarantorWrapper.account = guarantor;

                    var indexVal = event.getSource().get('v.value');

            var guarantors = cmp.get("v.clientWrapper.ccgAccounts");

            var indexVal = event.getSource().get('v.value');

            guarantors[indexVal] = guarantorWrapper;
            cmp.set("v.clientWrapper.ccgAccounts",guarantors);
        },


    //clearCCGItem

    quickSave : function (cmp, event, helper) {
        helper.quickSave (cmp, event, helper);
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
    saveAndQuitGuarController : function (cmp, event, helper) {
                helper.saveAndQuitGuarHelper (cmp);
     },
})