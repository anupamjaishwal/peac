({
    doInit: function (cmp, event, helper) {
        helper.getCurrentValues(cmp);
        helper.getOpportunityProbability(cmp);
        
        cmp.set('v.resultColumns', [
            {label: 'City', fieldName: 'city', type: 'text'},
            {label: 'County', fieldName: 'county', type: 'text'},
            {label: 'State', fieldName: 'state', type: 'text'},
            {label: 'Select', fieldName: 'Select', type: 'button',
             typeAttributes: {
                 iconName: 'utility:check',
                 name: 'select',
                 title: 'Select',
                 disabled: false
             }
            }
        ]);
    },
    
    doSearch: function (cmp, event, helper) {
        helper.search(cmp);
    },
    
    saveSelected: function (cmp, event, helper) {
        helper.save(cmp, event);
    }
})