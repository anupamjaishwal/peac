/**
 * Created by andrewmayer on 11/29/18.
 */
({
    productChangedHelper : function (cmp, event, helper) {
        cmp.set ('v.recordTypeId', cmp.find("productSelect").get("v.value"));

        // no function for getting the text value so have to do it manually
        var rts = cmp.get ('v.recordTypes');

        for (var i = 0; i<rts.length;i++) {
            if (rts[i].recordTypeId == cmp.find("productSelect").get("v.value")) {
                cmp.set ('v.tempRecordTypeName', rts[i].recordTypeName);
            }
        }
    },
    quickSaveHelper: function (cmp, event, helper) {
        //cmp.set ('v.recordTypeName',cmp.get ('v.tempRecordTypeName'));

        //cmp.set ('v.clientWrapper.recordTypeName', cmp.get ('v.tempRecordTypeName'));

        var clientWrapper = cmp.get ('v.clientWrapper');
        clientWrapper.recordTypeName = cmp.get ('v.tempRecordTypeName');
        cmp.set ('v.clientWrapper', clientWrapper);


            // this.goToNextHelper ();
         },
    /*goToNextHelper : function () {
             var navEvent = $A.get("e.c:tc_applicationNavigation_evt");
             var dir = "next";

             navEvent.setParams({
                 data: {
                     direction: dir
                 }
             });

             navEvent.fire();
    }*/
})