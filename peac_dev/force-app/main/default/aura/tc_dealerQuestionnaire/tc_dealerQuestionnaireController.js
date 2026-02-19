/**
 * Created by szheng on 4/27/20.
 */

({
    doInit : function(cmp, event, helper) {
        helper.doInitHelper(cmp, event, helper, false);
    },

    saveQuestionnaire : function(cmp, event, helper) {
        helper.saveQuestionnaireHelper(cmp, event);
    },

    openModal : function(cmp, event, helper) {
        //helper.openModalHelper(cmp);
        helper.doInitHelper(cmp, event, helper, true);
    },

    closeModal : function(cmp, event, helper) {
        helper.closeModalHelper(cmp);
    }

});