({
    doinit : function (cmp, event, helper) {
        let filterList = [];
        let filterObj = {
            "fieldAPIName" : "Type",
            "operator" : "=",
            "value" : "M",
            "datatype" : "string"
        }
        let filterWithDealerN = {
            "fieldAPIName" : "Dealer_Number__c",
            "operator" : "!=",
            "value" : "",
            "datatype" : "string"
        }
        filterList.push(filterObj);
        filterList.push(filterWithDealerN);
        cmp.set('v.filterCriteria',filterList);
    },
    handleSameAddress : function (cmp, event, helper) {
        /*if (cmp.find("sameAsCompanyAddress").get("v.checked")) {
            var equipment = cmp.get("v.equipment.");
            var company = cmp.get("v.company");
            equipment.Location_Address__c = company.BillingStreet;
            equipment.Location_City__c = company.BillingCity;
            equipment.Location_State__c = company.BillingStateCode;
            equipment.Location_Zip__c = company.BillingPostalCode;
            equipment.County__c = company.County__c;
            cmp.set("v.equipment", equipment);
        }*/
    },
    
    setSeriesPicklist : function (cmp, event, helper) {
        /*var equipment = cmp.get("v.equipment.equipment");
        var picklists = cmp.get("v.picklists");
        helper.getPicklistVals(cmp, picklists.seriesPicklistMap, equipment.Make_Picklist__c, "seriesFieldId");*/
    },
    
    setModelEnginePicklist : function (cmp, event, helper) {
       /* var equipment = cmp.get("v.equipment.equipment");
        var picklists = cmp.get("v.picklists");
        helper.getPicklistVals(cmp, picklists.modelPicklistMap, equipment.Series_Picklist__c, "modelFieldId");
        helper.getPicklistVals(cmp, picklists.enginePicklistMap, equipment.Series_Picklist__c, "engineFieldId");*/
    },
    handleManufacturer : function (cmp, event, helper) {
        console.log(event.getParam('recordLabel'));
        console.log(event.getParam('recordId'));
        cmp.set ('v.equipment.equipment.Manufacturer__c', event.getParam('recordId'));
    },
    equipmentAddressSameAsCompanyCTRL : function (cmp, event, helper) {


        // for some reason checking the checkbox doesn't set the value to true

        // if false set to true and set related fields to true
        if (!cmp.get ('v.equipmentAddressSameAsCompany')) {
            cmp.set ('v.equipmentAddressSameAsCompany', true);
            cmp.set ('v.equipment.equipment.End_User_Billing_Address__c', true);
        } else {
            cmp.set ('v.equipmentAddressSameAsCompany', false);
            cmp.set ('v.equipment.equipment.End_User_Billing_Address__c', false);
        }
    },
    
    handleSelectedManufacturer : function (cmp, event, helper) {
        console.log('ReusableLookup::',JSON.stringify(event.getParams()));
        let selectedRecord = JSON.parse(JSON.stringify(event.getParams()));
        //console.log('ReusableLookup::',JSON.stringify(event.getParam('mainField')));
        if(selectedRecord.mainField == 'Other') {
            cmp.set ('v.otherManafacturerRequired', true);
        } else {
             cmp.set ('v.otherManafacturerRequired', false);
        }
        cmp.set ('v.equipment.equipment.Manufacturer__c', selectedRecord.id);
    },
})