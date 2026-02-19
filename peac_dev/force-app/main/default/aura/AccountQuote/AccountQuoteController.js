({
    init : function(component, event, helper) {
        /// alert(component.get("v.recordId"));
        
        var action = component.get("c.getAccountRecord");
        action.setParams({
            "recId" : component.get("v.recordId")
        });
        action.setCallback(this, function(result){
            var state = result.getState();
            
            if (state === "SUCCESS"){
                var relt = result.getReturnValue();
                //alert(relt[0].Account_Dealer_Status__c);
                // if(relt[0].Playbook_Status__c != null && relt[0].Playbook_Status__c != ''){	
                if(relt[0].Risk_Based_Pricing__c != false && ( relt[0].Playbook_Status__c == 'Rejected' || relt[0].Playbook_Status__c == 'Cut-off' || relt[0].Playbook_Status__c == 'Do Not Solicit (New)') ){
                    component.set("v.ShowError", true);
                    component.set("v.ShowForm", false);
                    // alert(component.get("v.ShowForm"));
                }
                //}
                else if(relt[0].Risk_Based_Pricing__c == false){
                    component.set("v.ShowErr2", true);
                    component.set("v.ShowForm", false);
                    
                }
                
                    else if(relt[0].Risk_Based_Pricing__c == false && (relt[0].Playbook_Status__c == 'Rejected' || relt[0].Playbook_Status__c == 'Cut-off' || relt[0].Playbook_Status__c == 'Do Not Solicit (New)')){
                        component.set("v.ShowErr2", false);
                        component.set("v.ShowError", false);
                        component.set("v.ShowErr3", true);
                        component.set("v.ShowForm", false);
                    }
                        else if(relt[0].Risk_Based_Pricing__c == true && (relt[0].Playbook_Status__c != 'Rejected' || relt[0].Playbook_Status__c != 'Cut-off' || relt[0].Playbook_Status__c != 'Do Not Solicit (New)')){
                            component.set("v.ShowForm", true);
                        }
                
                
            }
            
            
            
        });
        $A.enqueueAction(action);   
        
    },

    handleSuccess : function(component, event, helper) {
        
        if(component.get("v.isUpdate") == false){
            var recId = component.get("v.recordId");
            var EquipCost = component.find("EquipmentCost").get("v.value");
            component.set("v.Clicked",true);
            var record = event.getParam("response");
            var myRecordId = record.id; 
            console.log('>>>on success lead-id>>>::',myRecordId); 
            var action = component.get("c.getPortalCustCreditExpAndAutoPG");
            action.setParams({
                "accId" : component.get("v.recordId"),
                "LeadId" : myRecordId
                
            });
             component.set("v.callout1",false);
            component.set("v.callout2",true);
            action.setCallback(this, function(response){
                console.log(response.getState());
                var state = response.getState();
                if (state === "SUCCESS"){
                    component.set("v.leadRecordId",myRecordId);
                    var res = response.getReturnValue();
                    /**************************/
                    var riskGrade =  component.get("v.Corp");
                    var action2 = component.get("c.callWebserviceGetXMLResponse");
                 
                    action2.setParams({
                        "accId" : recId,
                        "EquipmentCost" : EquipCost,
                        "LeadId": myRecordId
                    });
                      component.set("v.callout2",false);
                    component.set("v.callout3",true);
                    action2.setCallback(this, function(response2){

                        // SAL-2602 changed timer from 20000 to 0
                       console.log('>>>>>setTime');
                        window.setTimeout(
                            $A.getCallback(function() {
                                helper.isQuoteGenerated(component, event)
                            }), 0
                        );
                        
                        console.log(response2.getState());
                        console.log('res',response2.getReturnValue());
                        if (response2.getState() == "SUCCESS"){
                            console.log('>>>>>success');
                        }
                            else{
                                //component.set("v.Clicked",false);
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    title : 'Error',
                                    message:'Sorry! Something went wrong, please Try again',
                                    duration:' 5000',
                                    key: 'info_alt',
                                    type: 'error',
                                    mode: 'pester'
                                });
                                toastEvent.fire();
                            }
                        });
                        $A.enqueueAction(action2);
                        
                        /**************************/   
                        
                    }
                });
            $A.enqueueAction(action); 
            
        }
    },
    CloseModal : function(component, event, helper) {
        
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();   
    },
    
    handleError : function(component, event, helper) {
        alert('eroorrr');
        component.set("v.Clicked",false);   
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error',
            message:'Sorry! Something went wrong, please Try again',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    
    getQuoteDetail : function(component, event, helper) { 
        
        component.set("v.Clicked",true);
        component.set("v.callout1",true);
        
        var EquipCost = component.find("EquipmentCost").get("v.value");
        var LeadSource = component.find("LeadSource").get("v.value");
        var LeadStatus = component.find("LeadStatus").get("v.value");
        var LeadType = component.find("LeadType").get("v.value");
        var RelatedDealer = component.find("RelatedDealer").get("v.value");
        var CompanyName = component.find("CompanyName").get("v.value");
        var AddLine1 = component.find("AddLine1").get("v.value");
        var BusinessCity = component.find("BusinessCity").get("v.value");
        var BusinessState = component.find("BusinessState").get("v.value");
        var BusinessZip = component.find("BusinessZip").get("v.value");
        var BusinessPhone = component.find("BusinessPhone").get("v.value");
        var FirstName = component.find("FirstName").get("v.value");
        var LastName = component.find("LastName").get("v.value");
        var EquipmentType = component.find("EquipmentType").get("v.value");
        
        
        var recId = component.get("v.recordId");
        
        
        console.log('AccRecordID', recId);   
        if(EquipCost != null && EquipmentType != null && LastName != null && FirstName != null && BusinessPhone != null && BusinessZip != null&& BusinessState != null &&
           BusinessCity != null && AddLine1 != null && CompanyName != null && RelatedDealer != null && LeadType != null && LeadStatus != null && LeadSource ){
            
            if(EquipCost <= 150000){
                component.find("leadCreateForm").submit();
                
            }
            else{
                component.set("v.Clicked",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'Equipment Cost should not be greater than 1,50,000',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }
        }
        else{
            component.set("v.Clicked",false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message:'Please Enter all required fields',
                duration:' 5000',
                key: 'info_alt',
                type: 'error',
                mode: 'pester'
            });
            toastEvent.fire();
        }
    }
})