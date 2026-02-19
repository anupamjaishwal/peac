({
    doInit: function (component, event, helper) {
        let describedSObjectFields = component.get('v.describedSObjectFields');
        let index = component.get('v.index');
        let numCols = component.get('v.numColumns');
        if (!$A.util.isEmpty(numCols)) {
            component.set('v.size', 12/numCols);
        }
        if (!$A.util.isEmpty(describedSObjectFields) && !$A.util.isEmpty(index)) {
            component.set('v.fields',describedSObjectFields[index]);
        }
    },
});