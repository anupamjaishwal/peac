({
    doInit: function (component, event, helper) {
        helper.handleInit(component,event,helper);
    },
    addNewChildRecord : function (component, event, helper) {
        helper.handleAddNewChildRecord(component, event, helper);
    },
    saveRecords : function (component, event, helper) {
        helper.handleSaveChildRecords(component, event, helper);
    },
});