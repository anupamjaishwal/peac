/**
 * Created on 1/2/18.
 */
({
    loadValues : function (cmp) {
        var record = cmp.get("v.record");
        var subheading = '';
        cmp.get("v.subHeadingFieldsAPI").forEach(function(el){
            if(record[el]){
                subheading = subheading + record[el] + ' • ';
            }
        });


        subheading = subheading.substring(0,subheading.lastIndexOf('•'));
        cmp.set("v.subHeadingFieldValues", subheading);
    },

    choose : function (cmp,event) {
        var chooseEvent = cmp.getEvent("lookupChoose");
        console.log('inputItem choose', chooseEvent.getName());
        chooseEvent.setParams({
            "recordId" : cmp.get("v.record").Id,
            "recordLabel":cmp.get("v.record").Name,
            "objectAPIName" : cmp.get('v.objectAPIName'),
            "itemIndex" : cmp.get('v.itemIndex')
        });
        chooseEvent.fire();
        console.log('event fired');
    }
})