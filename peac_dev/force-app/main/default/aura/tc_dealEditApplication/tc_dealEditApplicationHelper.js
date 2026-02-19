/**
 * Created by andrewmayer on 1/11/19.
 */
({
    getAppRecordById: function (cmp) {

            //alert ('Is refreshing');

            TCLightningUtils.showSpinner(cmp);
            var action = cmp.get('c.getApplicationById');
/*
            action.setParams({
                appId: cmp.get("v.recordId")
            });*/
            action.setParams({appId: cmp.get ('v.recordId')});



            action.setCallback(this, function (result) {

                TCLightningUtils.hideSpinner(cmp);
                if (result.getState() === 'SUCCESS') {
                    var returnedValue = JSON.parse(result.getReturnValue());
                    cmp.set ('v.clientWrapper', returnedValue);


                    // return user to page if already submitted
                    if (cmp.get ('v.clientWrapper.deal.opportunity.Application__c') != null && cmp.get ('v.clientWrapper.deal.opportunity.Application__c') != '' ) {
                        TCLightningUtils.showToast('Warning', 'This Application has been submitted and can no longer be edited. Rapport #: ' + cmp.get ('v.clientWrapper.deal.opportunity.Application__c'), 'warning');
                        $A.get("e.force:navigateToURL").setParams({ "url": "/" + cmp.get ('v.clientWrapper.deal.opportunity.Id')}).fire();
                    } else if (cmp.get ('v.clientWrapper.deal.opportunity.CaseCenter__c') != null && cmp.get ('v.clientWrapper.deal.opportunity.CaseCenter__c') != '' ) {
                        TCLightningUtils.showToast('Warning', 'This Application has been submitted and can no longer be edited. Case Center #: ' + cmp.get ('v.clientWrapper.deal.opportunity.CaseCenter__c'), 'warning');
                                                $A.get("e.force:navigateToURL").setParams({ "url": "/" + cmp.get ('v.clientWrapper.deal.opportunity.Id')}).fire();
                    }

                } else {
                    console.log(result.getError());
                    TCLightningUtils.showToast('Error', result.getError()[0].getMessage(), 'error', 'sticky');
                }
                cmp.set('v.doInitBoolean', true);
            });

            $A.enqueueAction(action);
        }
})