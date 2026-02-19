({
    getCurrentValues: function (cmp) {
        console.log('getCurrentValues', cmp.get('v.recordId'));
        cmp.set('v.isLoading', true);
        var action = cmp.get('c.getCurrentValues');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });

        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var taxJurisdiction = result.getReturnValue();
                cmp.set('v.taxJurisdiction', taxJurisdiction);
                
                // if (taxJurisdiction.zipUpdated){
                    this.search(cmp);
                // }else{
                //     cmp.set('v.isLoading', false);
                // }   
            } else {
                $A.get('e.force:closeQuickAction').fire();
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
            
        });

        $A.enqueueAction(action);
    },
    
    getOpportunityProbability: function (cmp) {
        console.log('getOpportunityProbability', cmp.get('v.recordId'));
        var action = cmp.get('c.getOpportunityProbability');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });

        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var opportunityProbability = result.getReturnValue();
                cmp.set('v.opportunityProbability', opportunityProbability);
                console.log('opportunityProbability', cmp.get('v.opportunityProbability'));
            } else {
                $A.get('e.force:closeQuickAction').fire();
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
        });

        $A.enqueueAction(action);
    },
    
    search: function (cmp) {
        console.log('search', cmp.get('v.taxJurisdiction.zip'));
        var action = cmp.get('c.search');

        action.setParams({
            recordId: cmp.get('v.recordId'),
            zip: cmp.get('v.taxJurisdiction.zip')
        });

        var spinner = cmp.find("spinner");
        //$A.util.removeClass(spinner, "slds-hide");
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var taxJurisdictions = result.getReturnValue();
                console.log('search result', taxJurisdictions);
                cmp.set('v.taxJurisdictions', taxJurisdictions);
                cmp.set('v.isLoading', false);
                if (taxJurisdictions.length == 1){
                    this.showToast('Success', 'Tax Jurisdiction successfully updated', 'success');
                    $A.get('e.force:refreshView').fire();
                    $A.get('e.force:closeQuickAction').fire();
                }else{
                    var opportunityProbability = cmp.get('v.opportunityProbability');
                
                    if (taxJurisdictions.length > 1 && opportunityProbability >= 75 && opportunityProbability != 100)
                        this.showToast('Warning', 'There are mulitple Tax Jurisdictions for new Zip Code.  Please select one below.', 'warning', 'dismissible');
                }
            } else {
                $A.get('e.force:closeQuickAction').fire();
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
            
            $A.util.addClass(spinner, "slds-hide");
        });

        $A.enqueueAction(action);
    },
    
    save: function (cmp, event) {
        console.log('save', JSON.stringify(event.getParam('row')));
        var action = cmp.get('c.save');

        action.setParams({
            recordId: cmp.get('v.recordId'),
            taxJurisdictionString: JSON.stringify(event.getParam('row'))
        });

        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        cmp.set('v.isLoading', true);
        action.setCallback(this, function (result) {
            $A.get('e.force:closeQuickAction').fire();
            
            if (result.getState() === 'SUCCESS') {
                this.showToast('Success', 'Tax Jurisdiction successfully updated.', 'success', 'dismissible');
                $A.get('e.force:refreshView').fire();
            } else {
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
            cmp.set('v.isLoading', false);
            $A.util.addClass(spinner, "slds-hide");
        });

        $A.enqueueAction(action);
    },
    
    showToast : function(title, message, type, mode) {
        var toastEvent = $A.get('e.force:showToast');
        
        toastEvent.setParams({
            'title': title,
            'message': message,
            'type': type,
            'mode': mode
        });
        
        toastEvent.fire();
    }
})