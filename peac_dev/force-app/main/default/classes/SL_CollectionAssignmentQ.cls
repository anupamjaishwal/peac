public class SL_CollectionAssignmentQ implements Queueable{
    List<Account> accountsToChangeGroup;
    List<Contract__c> contractsToQ;
    String processType;
    String toAddress;
    String status;
    String allErrors;

    public SL_CollectionAssignmentQ(){
        this.processType = 'startBatch';
    }
    public SL_CollectionAssignmentQ(List<Account> accountsToChangeGroup){
        this.processType = 'changeAccountGroups';
        this.accountsToChangeGroup = accountsToChangeGroup;
    }
    public SL_CollectionAssignmentQ(List<Contract__c> contractsToQ){
        this.processType = 'updateContracts';
        this.contractsToQ = contractsToQ;
    }
    public SL_CollectionAssignmentQ(String toAddress, String status, String allErrors){
        this.processType = 'sendInfoByEmail';
        this.toAddress = toAddress;
        this.status = status;
        this.allErrors = allErrors;
    }

    public void execute(QueueableContext context) {
        List<Database.SaveResult> updateResults = null;
        switch on this.processType {
            when 'startBatch'{
                Database.executeBatch(new SL_CollectionAssignmentBatch());
            }
            when 'changeAccountGroups'{
                if(accountsToChangeGroup.size() > 0){
                    updateResults = Database.update(accountsToChangeGroup, false);
                }
            }
            when 'updateContracts'{
                if(contractsToQ.size() > 0){
                    updateResults = Database.update(contractsToQ, false);
                }
            }
            when 'sendInfoByEmail'{
                SL_CollectionAssignmentBatch.sendErrorsMail(toAddress, status, allErrors);
            }
        }
        if(updateResults != null){
            for(Database.SaveResult result :updateResults){
                if(!result.isSuccess()){
                    allErrors = 'SObject Id: ' + result.getId() + '\r\n' + result.getErrors();
                    System.debug('SObject Id: ' + result.getId() + '\r\n' + result.getErrors());
                    SL_CollectionAssignmentBatch.sendErrorsMail(toAddress, 'failed (on second Queueable class) ', allErrors);
                }
            }
        }
    }
}