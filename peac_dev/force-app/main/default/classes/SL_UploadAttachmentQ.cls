public with sharing class SL_UploadAttachmentQ implements Queueable {
    List<String> contractIds;
    List<String> idsToRetry;
    Boolean isFirstTime;
    public SL_UploadAttachmentQ(List<String> contractIds) {
        this.contractIds = contractIds;
        this.idsToRetry = new List<String>();
        this.isFirstTime = true;
    }
    public SL_UploadAttachmentQ(List<String> contractIds, List<String> idsToRetry, Boolean isFirstTime) {
        this.contractIds = contractIds;
        this.idsToRetry = idsToRetry;
        this.isFirstTime = isFirstTime;
    }

    public void execute(QueueableContext context) {
        if(contractIds.size() >0){
            Id contractToProcess = (Id)contractIds.remove(0);
            SL_OnBaseCallout.calloutFromQToOnBase(contractToProcess, contractIds, idsToRetry, isFirstTime);
        }
    }
}