public class TC_ApprovalProcessCtrl {
    
    // code was written with the assumption that you could sumbit a record to multiple approval processes
    
    @auraEnabled
    public static List <ApprovalProcessWrapper> getApprovalProcesses (Id recordId) {
        
        String recordName = recordId.getSobjectType().getDescribe().getName();
        
        // check for pending approvals
        List <ProcessInstance> currentProcesses = new List <ProcessInstance> ([select ProcessDefinition.Name from ProcessInstance where TargetObjectId = :recordId AND Status = 'Pending']);
        if (!currentProcesses.isEmpty ()) {
            String message = 'Record is currently pending approval for approval process: '+ currentProcesses[0].ProcessDefinition.Name+ '. Please complete before submitting this record to another approval process';
            AuraHandledException ae = new AuraHandledException (message);
            ae.setMessage (message);
            throw ae;
        }
        
        List <ApprovalProcessWrapper> approvalProcessWrappers = new List <ApprovalProcessWrapper> ();
        
        for (ProcessDefinition pd : [SELECT Description, DeveloperName, Name FROM ProcessDefinition WHERE State = 'Active' AND Type = 'Approval' AND TableEnumOrId = :recordName]) {
            approvalProcessWrappers.add (new ApprovalProcessWrapper (pd.Description, pd.DeveloperName, pd.Name));
        }
        
        return approvalProcessWrappers;
    }
    @auraEnabled 
    public static List <ApprovalProcessWrapper> submitApprovalProcesses (String approvalProcessWrappersJson, Id recordId) {
		List <ApprovalProcessWrapper> approvalProcessWrappers = (List <ApprovalProcessWrapper>) JSON.deserialize(approvalProcessWrappersJson, List<ApprovalProcessWrapper>.class);

        for (ApprovalProcessWrapper apw : approvalProcessWrappers) {
            if (apw.selected) {
                apw.submit (recordId);
                if (apw.status != 'SUCCESS'){
                    String message = apw.status + '' + apw.errorMessage;
            		AuraHandledException ae = new AuraHandledException (message);
            		ae.setMessage (message);
            		throw ae;
                }
            }
        }
        
        return approvalProcessWrappers;
    }
    
    public class ApprovalProcessWrapper {
        @auraEnabled
        public Boolean selected;
        @auraEnabled
        public String description;
        @auraEnabled
        public String developerName;
        @auraEnabled
        public String name;
        @auraEnabled
        public String status;
        @auraEnabled
        public String comment;
        @auraEnabled
        public Id assignedUserId;
        @auraEnabled
        public String assignedUserName;
        @auraEnabled
        public String errorMessage;
        @auraEnabled
        public TC_ApprovalProcess submission;
        
        // because lightning requires it: System.TypeException: TC_ApprovalProcessCtrl.ApprovalProcessWrapper does not have a no-arg constructor
        //public ApprovalProcessWrapper () {
        //    this.submission = new TC_ApprovalProcess ();
        //}
        
        public ApprovalProcessWrapper (String description, String developerName, String name) {
            this.selected = false;
            this.description = description;
            this.developerName = developerName;
            this.name = name;
            this.status = '';
            this.comment = '';
            this.submission = new TC_ApprovalProcess ();
        }
        
        public void submit (Id recordId) {
            this.submission.submitToProcess (this.comment, this.developerName, recordId, this.assignedUserId);
            this.status = this.submission.status;
            this.errorMessage = this.submission.message;
        }
    }

}