/**
 * Created by szheng on 1/28/20.
 */

({
    doInit : function(cmp, event, helper) {
        helper.getRenderDecisionDetailsHelper(cmp, event);
    },

    nextButton : function(cmp, event, helper) {
        helper.nextButtonHelper(cmp, event);
    },

    showSpinner: function(component, event, helper) {
        component.set("v.spinner", true);
    },

    hideSpinner : function(component,event,helper){
        component.set("v.spinner", false);
    },

});