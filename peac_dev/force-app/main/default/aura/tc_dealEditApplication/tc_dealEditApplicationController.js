/**
 * Created by andrewmayer on 1/11/19.
 */
({
    doInit: function (cmp, event, helper) {
        //alert (cmp.get ('v.recordId') + ' 200'); 
            helper.getAppRecordById(cmp);
        }
})