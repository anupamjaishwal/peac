({
    doInitStartHelper : function(component) {
        $A.util.toggleClass(component.find('resultsDiv'),'slds-is-open');
        var value = component.get('v.value');
        var values = component.get('v.values');
        //if( !$A.util.isEmpty(value) || !$A.util.isEmpty(values) ) {
            var searchString;
            var count = 0;
            var multiSelect = component.get('v.multiSelect');
            /* calling apex*/
            var action = component.get("c.getPiklistValues");
        console.log(component.get("v.objApi")+'---'+component.get("v.fieldName"));
        action.setParams({
            "objName": component.get("v.objApi"),
            "fieldApiName":component.get("v.fieldName")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var result = response.getReturnValue();
                var plValues = [];
                for (var i = 0; i < result.length; i++) {
                    plValues.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                console.log('plValues::',plValues);
                component.set("v.options", plValues);
                //component.set("v.multipicklstList", plValues);
           
        
            var options = component.get('v.options');
          if(options.length > 0){
            options.forEach( function(element, index) {
                if(multiSelect) {
                    if(values.includes(element.value)) {
                        element.selected = true;
                        count++;
                    }  
                } else {
                    if(element.value == value) {
                        searchString = element.label;
                    }
                }
            });
            }
            if(multiSelect)
                component.set('v.searchString', count + ' options selected');
            else
                component.set('v.searchString', searchString);
            component.set('v.options', options);
             }
        });
            $A.enqueueAction(action);
        //}
    },
     
    filterOptionsDataHelper : function(component) {
        component.set("v.message", '');
        var searchText = component.get('v.searchString');
        var options = component.get("v.options");
        var minChar = component.get('v.minChar');
        if(searchText.length >= minChar) {
            var flag = true;
            options.forEach( function(element,index) {
                if(element.label.toLowerCase().trim().startsWith(searchText.toLowerCase().trim())) {
                    element.isVisible = true;
                    flag = false;
                } else {
                    element.isVisible = false;
                }
            });
            component.set("v.options",options);
            if(flag) {
                component.set("v.message", "No results found for '" + searchText + "'");
            }
        }
        $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
    },
     
    selectOptionHelper : function(component, event) {
        console.log('**selectOptionHelper');
        var options = component.get('v.options');
        var multiSelect = component.get('v.multiSelect');
        var searchString = component.get('v.searchString');
        var values = component.get('v.values') || [];
        var value;
        var count = 0;
        let selectedVals = [];
        let sVals;
        options.forEach( function(element, index) {
            if(element.value === event.currentTarget.id) {
                if(multiSelect) {
                    if(values.includes(element.value)) {
                        values.splice(values.indexOf(element.value), 1);
                    } else {
                        values.push(element.value);
                    }
                    element.selected = element.selected ? false : true;   
                } else {
                    value = element.value;
                    searchString = element.label;
                }
            }
            if(element.selected) {
                console.log('selected val::'+element+'---'+JSON.stringify(element));
                count++;
                selectedVals.push(element.value);
                 sVals = selectedVals.toString();
                
            }
        });
        sVals = sVals.replaceAll(",", ";");
        component.set('v.value', sVals);
        component.set('v.values', sVals);
        console.log('vals::'+JSON.stringify(component.get("v.value"))+'--'+JSON.stringify(component.get("v.values")));
        //component.set('v.value', value);
        //component.set('v.values', values);
        component.set('v.options', options);
        
        if(multiSelect)
            component.set('v.searchString', count + ' options selected');
        else
            component.set('v.searchString', searchString);
        if(multiSelect)
            event.preventDefault();
        else
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    },
     
    removeOptionPillHelper : function(component, event) {
        var value = event.getSource().get('v.name');
        var multiSelect = component.get('v.multiSelect');
        var count = 0;
        var options = component.get("v.options");
        var values = component.get('v.values') || [];
        options.forEach( function(element, index) {
            if(element.value === value) {
                element.selected = false;
                values.splice(values.indexOf(element.value), 1);
            }
            if(element.selected) {
                count++;
            }
        });
        if(multiSelect)
            component.set('v.searchString', count + ' options selected');
        component.set('v.values', values)
        component.set("v.options", options);
    },
     
    handleBlurHelper : function(component, event) {
        var selectedValue = component.get('v.value');
        var multiSelect = component.get('v.multiSelect');
        var previousLabel;
        var count = 0;
        var options = component.get("v.options");
        if(options.length > 0){
        options.forEach( function(element, index) {
            if(element.value === selectedValue) {
                previousLabel = element.label;
            }
            if(element.selected) {
                count++;
            }
        });
        }
        if(multiSelect)
            component.set('v.searchString', count + ' options selected');
        else
            component.set('v.searchString', previousLabel);
         
        if(multiSelect)
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    }
})