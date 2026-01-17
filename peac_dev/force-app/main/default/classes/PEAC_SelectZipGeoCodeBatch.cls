/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This batch class is used to call create Zip Geo Code
@User Story:SAL-5412
@Created Date:April-16-2025    
@Param: Database.BatchableContext
**************************************************************************************************************/

public class PEAC_SelectZipGeoCodeBatch implements Database.Batchable<sObject>,database.stateful,database.AllowsCallouts {
    List<Asset__c> assetList = new List<Asset__c> ();
    List<Asset__c> assetUpdateList = new List<Asset__c> ();
    Integer failedCount = 0;
    Integer successCount = 0;
    List<String> allErrorsList = new List<String>();
    List<String> failedAssetList = new List<String>();
    Boolean sendEmail = false;
    

    public PEAC_SelectZipGeoCodeBatch(List<Asset__c> assetList) {
        this.assetList = assetList;
    }
    public PEAC_SelectZipGeoCodeBatch(List<Asset__c> assetList, Boolean sendEmail) {
        this.assetList = assetList;
        this.sendEmail = sendEmail;
        
    }
/**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This is start method of the batch class
    @User Story:SAL-5412
	@Created Date:April-16-2025    
    @Param: Database.BatchableContext
	@Return:Get list of sObject
    **************************************************************************************************************/

    public List<Asset__c> start(Database.BatchableContext BC) {
        List<Asset__c> batchOfAssets = new List<Asset__c>();
                if(Test.isRunningTest()){
                    batchOfAssets.add(assetList[0]);
                }else{
                    batchOfAssets.addAll(assetList);
                }
        return batchOfAssets;
    }
       
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Execute method of the batch class
    @User Story:SAL-5412
    @Created Date:April-16-2025    
    @Param: Database.BatchableContext and List of sObject
	@Return:None
    **************************************************************************************************************/

    public void execute(Database.BatchableContext BC, List<Asset__c> scopeList) {
        try {
            
            for(Asset__c assetR :scopeList){
                if(assetR.Equipment_Zip__c!=Null)
                {
                    TC_BridgewareSelectZipGeoCodeCtrl.search(assetR.id,assetR.Equipment_Zip__c); 
                    successCount++;
                }
                
            }
            
        } catch (Exception ex) {
            // Handle exceptions as needed
            FailedCount++;
            failedAssetList.add('Asset Record Id-'+scopeList[0].Id);
            allErrorsList.add('The following error has occurred.'+ '--' + ex.getMessage() +'\r\n' );
            
                           
        }
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Finish method of the batch class
    @User Story:SAL-5412
    @Created Date:April-16-2025    
    @Param: Database.BatchableContext
	@Return:None
    **************************************************************************************************************/

    public void finish(Database.BatchableContext BC) {
        // Get the Job ID
        String jobId = bc.getJobId();

        // Get the user who submitted the batch (using AsyncApexJob)
        AsyncApexJob job = [SELECT CreatedBy.Email,Status FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
        String userEmail = job.CreatedBy.Email;
        if (sendEmail) {
          sendToUserMail(userEmail, job.status, failedAssetList,successCount,failedCount);// call sendToUserMail method to send mail to user
        }
        
	}
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Send an email to the user with the status of the batch
    @User Story:SAL-5358
    @Created Date:May-28-2025    
    @Param: email id,status of the batch,list of all errors,count of success,count of failed
	@Return:None
    **************************************************************************************************************/

    public static void sendToUserMail(String toAddress, String status, List<String> failedAssetList,Integer successCount,Integer failedCount){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {toAddress});
        mail.setSubject('Tax Jurisdiction Job Status ' + status);
        String mailBody = 'Total number of processed assets: '+ successCount + '\n';
        if(failedCount > 0  )
        {
            mailBody+='List of failed assets:'+failedCount+' :'+ '\n';
            for(String failedRecord: failedAssetList)
            {
               mailBody+= failedRecord;  
            }
             
        }
        
        mail.setPlainTextBody(mailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
    
    
}