public class TC_ApprovalProcess {
    
    public Approval.ProcessResult submit;
    //public Approval.ProcessResult approve;
    public List<Id> workItemIds = new List<Id> ();

    public String status;
    public String message;

    public Boolean skipEntryCriteria = FALSE;

    //public String submitComment = 'AUTO SUBMIT';
    //public String approveComment = 'AUTO APPROVE';
    
    
    
    public void submitToProcess (String submitComment, String processName, Id objId, Id userId) {

        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest ();
        request.setComments(submitComment);
        request.setObjectId(objId);

        // Submit on behalf of a specific submitter
        request.setSubmitterId(UserInfo.getUserId());

        request.setProcessDefinitionNameOrId(processName);
        request.setSkipEntryCriteria(skipEntryCriteria);

        request.setNextApproverIds(new Id[] {
            userId
        });

        system.debug('----submitting to = ' + processName);

        try {
            submit = Approval.process(request);
        } catch (Exception e) {
            system.debug('ERROR: ' + processName + '--' + e.getMessage());
            status = 'ERROR: ';
            message = e.getMessage();
        }

        system.debug('----submission result = ' + submit);


        if (submit <> NULL) {
            if (submit.isSuccess()) {
                status = 'SUCCESS';
                workItemIds = submit.getNewWorkitemIds();
            } else {
                status = 'ERROR';
                if (submit.getErrors().size() > 0) {
                    message = submit.getErrors()[0].getMessage();
                } else {
                    message = 'Unknown error';
                }

            }
        }
        system.debug('submit workItemIds = ' + workItemIds);
    }

}