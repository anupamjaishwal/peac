({
    isQuoteGenerated : function(component, event) {
        
        
        console.log('called helper1');
        component.find("leadCreateForm").submit();
        
        component.set("v.isUpdate",true);
        
        //component.set("v.leadRecordId",component.get("v.leadRecordId"));
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.onGenerateQuote",false);
                component.set("v.onSave",true);
                component.set("v.Clicked",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message:' Created Lead Successfully',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'pester'
                });
                toastEvent.fire();
            }), 3000
        );
        
        
        //component.find("leadCreateForm").submit();
    }
})