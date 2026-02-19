/**
 * Created on 1/2/18.
 */
({
    //Function to handle the LookupChooseEvent. Sets the chosen record Id and Name
    handleLookupChooseEvent : function (component,event,helper) {/*

        component.set ('v.chosenRecordId', event.getParam("recordId"));


        component.set("v.chosenRecordId", event.getParam("recordId"));
        component.set("v.chosenRecordLabel",event.getParam("recordLabel"));
        helper.toggleLookupList(component,
            false,
            'slds-combobox-lookup',
            'slds-is-open');*/
    },

    //Function for finding the records as for given search input
    searchRecords : function (component,event,helper) {

        //var input = component.find("searchinput");

        //var removeAutoFill = function () {document.getElementsByName("Search Company")[0].setAttribute("autocomplete","off")};
        //removeAutoFill();

        //caseDetails.set("v.body", body);
        //v.body being an attribute of the component.  I wonder if you could set caseDetails.set("v.focus", functionName);

        //var debugtest = document.getElementsByName("Search Company")[0].setAttribute("autocomplete","off");
//debugger;

        /*var searchEvent12 = event;
        var input = component.find("searchinput");
debugger;
        console.log (input);

        console.log (component.find("searchinput").getLocalId());
        console.log (component.find("searchinput").getGlobalId());*/

        //document.getElementById(input.localId).setAttribute("autocomplete","off");
        /*
            if(input.getAttribute("autocomplete") !== "off"){
                input.setAttribute("autocomplete","off");
            }*/

        // remove autofill chrome
        //var element = document.getElementsByClassName("autofillremover")[0];
       // element.setAttribute("autocomplete","off");

       //document.getElementsByClassName("autofillremover")[0].setAttribute("autocomplete","off");


       /* var input = component.find("searchinput");
            if(input.getAttribute("autocomplete") !== "off"){
                input.setAttribute("autocomplete","off");
            }*/

        //var input = component.find("searchinput");

       // console.log ('Id nput: ' + input.get ('Id'));
 /*
        console.log ('>>>>> input1: ' + input.Id);
        console.log ('>>>>> input.getGlobalId(): ' + input.getGlobalId());
        console.log ('>>>>> input.getLocalId(): ' + input.getLocalId());
        console.log ('>>>>> input.get(): ' + input.get('attribute'));*/

        var searchText = component.find("searchinput").get("v.value");

        if(searchText){
            helper.searchSOSLHelper(component,searchText);
        }else{
            helper.searchSOQLHelper(component);
        }
    },

    //function to hide the list on onblur event.
    hideList :function (component,event,helper) {

        //Using timeout and $A.getCallback() to avoid conflict between LookupChooseEvent and onblur
        window.setTimeout(
            $A.getCallback(function() {
                if (component.isValid()) {
                    helper.toggleLookupList(component,
                        false,
                        'slds-combobox-lookup',
                        'slds-is-open'
                    );
                }
            }), 200
        );
    },

})