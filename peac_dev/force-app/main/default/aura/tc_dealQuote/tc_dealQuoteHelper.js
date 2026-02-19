/**
 * Created by crudrud on 12/21/20.
 */

({
    quickSave : function (cmp, event, helper) {

        console.log('entered quick save in helper');

        TCLightningUtils.showSpinner(cmp);
        var action;

        //var deal = cmp.get('v.deal');


        action = cmp.get('c.saveQuote');
        action.setParams({
            clientWrapperString: JSON.stringify(cmp.get ('v.clientWrapper'))
        })

        console.log('action is: ', action);
        console.log('clientWrapper is: ', action.clientWrapperString);

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
});