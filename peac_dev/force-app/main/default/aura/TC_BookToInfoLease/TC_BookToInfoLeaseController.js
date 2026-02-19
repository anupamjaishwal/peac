({
    doInit: function (cmp, event, helper) {
        helper.checkSubmissionCriteria(cmp);
    },

    handleMillionDollarQuestionEvent: function (cmp, event, helper){
        helper.handleMillionDollarDecision(cmp, event, helper);
    }
})