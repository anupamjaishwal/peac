/**
 * Created on 1/2/18.
 */
({
    //Function to toggle the record list drop-down
    toggleLookupList : function (cmp, ariaexpanded, classadd, classremove) {
        //console.log('toggleLookupList', cmp.find("lookupdiv"));
        //cmp.find("lookupdiv").set("v.aria-expanded", true);
        $A.util.addClass(cmp.find("lookupdiv"), classadd);
        $A.util.removeClass(cmp.find("lookupdiv"), classremove);
    },

    //function to call SOSL apex method.
    searchSOSLHelper : function (cmp,searchText) {
        //validate the input length. Must be greater then 3.
        //This check also manages the SOSL exception. Search text must be greater then 2.
        if(searchText && searchText.length > 3){
            //show the loading icon for search input field
            cmp.find("searchinput").set("v.isLoading", true);

            //server side callout. returns the list of record in JSON string
            var action = cmp.get("c.search");
            action.setParams({
                "objectAPIName": cmp.get("v.objectAPIName"),
                "searchText": searchText,
                "whereClause" : cmp.get("v.filter"),
                "extrafields":cmp.get("v.subHeadingFieldsAPI")
            });

            action.setCallback(this, function(a){
                var state = a.getState();

                if(cmp.isValid() && state === "SUCCESS") {
                    //parsing JSON return to Object[]
                    var result = [].concat.apply([], JSON.parse(a.getReturnValue()));
                    cmp.set("v.matchingRecords", result);
                    console.log( cmp.get("v.matchingRecords"));

                    //Visible the list if record list has values
                    if(a.getReturnValue() && a.getReturnValue().length > 0){
                        this.toggleLookupList(cmp,
                            true,
                            'slds-is-open',
                            'slds-combobox-lookup');

                        //hide the loading icon for search input field
                        cmp.find("searchinput").set("v.isLoading", false);
                    }else{
                        this.toggleLookupList(cmp, false,
                            'slds-combobox-lookup',
                            'slds-is-open');
                    }
                }else if(state === "ERROR") {
                    console.log('error in searchRecords');
                }
            });
            $A.enqueueAction(action);
        }else{
            //hide the drop down list if input length less then 3
            this.toggleLookupList(cmp,
                false,
                'slds-combobox-lookup',
                'slds-is-open'
            );
        }
    },

    //function to call SOQL apex method.
    searchSOQLHelper : function (cmp) {
        cmp.find("searchinput").set("v.isLoading", true);
        //var searchText = cmp.find("searchinput").get("v.value");

        var action = cmp.get("c.getRecentlyViewed");
        action.setParams({
            "objectAPIName": cmp.get("v.objectAPIName"),
            "whereClause" : cmp.get("v.filter"),
            "extrafields":cmp.get("v.subHeadingFieldsAPI")
        });

        //console.log(searchText);

        // Configure response handler
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(cmp.isValid() && state === "SUCCESS") {
                if(response.getReturnValue()){
                    cmp.set("v.matchingRecords", response.getReturnValue());
                    console.log( cmp.get("v.matchingRecords"));
                    if(response.getReturnValue().length>0){
                        this.toggleLookupList(cmp,
                            true,
                            'slds-is-open',
                            'slds-combobox-lookup');
                    }
                    cmp.find("searchinput").set("v.isLoading", false);
                }
            } else {
                console.log('Error in loadRecentlyViewed: ' + state);
            }
        });
        $A.enqueueAction(action);
    }
})