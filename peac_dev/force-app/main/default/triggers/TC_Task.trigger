trigger TC_Task on Task (before insert, before update, before delete, after insert, after update, after delete) {
    TC_TaskHelper helper = new TC_TaskHelper();
    helper.TC_TaskHelperExecute();
}