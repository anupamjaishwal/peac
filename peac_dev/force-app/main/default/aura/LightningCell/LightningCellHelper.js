({
    doInit : function(component, event, helper) {
        var record = component.get("v.record");
        var field = component.get("v.field");       
        var Index = component.get("v.index");      
           
        if(component.get("v.statusField")){
            var statusField = component.get("v.statusField")[Index];
            component.set("v.statusFieldValue", record[0][statusField.name]);
            
        }
        if(field)
        {
            component.set("v.cellValue", record[0][field.name]);
           // component.set("v.cellLabel", field.name);
            console.log('field.type'+field.type);
            if(field.type == 'STRING' || field.type == 'PICKLIST')
            {
                component.set("v.isTextField", true);
            }
            else if(field.type == 'DATETIME'){
                component.set("v.isDateTimeField", true);
            }
            
        }
        
    }
})