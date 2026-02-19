({
   /* handleCloseModal : function(component, event, helper) {
        // var homeEvt = $A.get("e.force:navigateToObjectHome");
        // homeEvt.setParams({
        //     "scope": "Contract__c"
        // });
        // homeEvt.fire();
        console.log("recordId: ", component.get("v.recordId"));
        let navEvt = $A.get("e.force:navigateToSObject");
        if(navEvt != null){
            navEvt.setParams({ 
            "recordId": component.get("v.recordId")
            });
            navEvt.fire();
        }
        
    },*/
    //added by Raja
    handleFilterChange: function(component, event) {


        var CloseClicked = event.getParam('close');
        
        component.set('v.message', 'Close Clicked');

		
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            console.log('focusedTabId::'+focusedTabId);
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    //end
})