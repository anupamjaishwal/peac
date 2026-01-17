/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for creating assets in batch
@User Story:SAL-5358
@Created Date:April-20-2025 	    
*********************************************************************************************************************/

public class PEAC_CreateAssetsBatch implements Database.Batchable<sObject>,database.AllowsCallouts,database.stateful {
    List<Asset__c> assetsList = new List<Asset__c>();
    List<Asset__c> insertedAssestList = new List<Asset__c>();
    Integer successCount = 0;
    Integer failedCount = 0;
    List<String> allErrors = new List<String>();
    //Call this constructor to execute batch from controller
    public PEAC_CreateAssetsBatch(List<Asset__c> assetList) {
        this.assetsList = assetList;
        
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This is start method of the batch class
    @User Story:SAL-5358
    @Created Date:April-20-2025    
    @Param: Database.BatchableContext
	@Return:Get list of Asset__c to be created
    **************************************************************************************************************/

    public List<Asset__c> start(Database.BatchableContext BC) {
        return assetsList;
    }
       
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Execute method of the batch class
    @User Story:SAL-5358
    @Created Date:April-20-2025    
    @Param: Database.BatchableContext and List of Asset__c
	@Return:None
    **************************************************************************************************************/

    public void execute(Database.BatchableContext BC, List<Asset__c> scopeList) {
        // Process the list of Asset__c and insert them
        Try{
            List<Database.SaveResult> insertedAssetList = Database.insert(scopeList, false);
            for(Database.SaveResult aResult : insertedAssetList) {
                if (aResult.isSuccess()) {
                    successCount++;
                }
                else {
                    FailedCount++;
                    // Operation failed, so get all errors                
                    for(Database.Error err : aResult.getErrors()) {
                        allErrors.add('The following error has occurred.'+ '--' + err.getFields().toString() + err.getMessage() +'\r\n' );
                    }
                }
            
            }    
            for(Asset__c assetR :scopeList){
                if(assetR.Id !=null)
                {
                    insertedAssestList.add(assetR);
                }
                
            }
        }
        catch(Exception ex)
        {
            FailedCount++;
            allErrors.add('The following error has occurred.'+ '--' + ex.getMessage() +'\r\n' );
             
        }
        
        
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Finish method of the batch class
    @User Story:SAL-5358
    @Created Date:April-20-2025    
    @Param: Database.BatchableContext
	@Return:None
    **************************************************************************************************************/

    public void finish(Database.BatchableContext BC) {
        // Get the Job ID
        String jobId = bc.getJobId();

        // Get the user who submitted the batch (using AsyncApexJob)
        AsyncApexJob job = [SELECT CreatedBy.Email,Status FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
        String userEmail = job.CreatedBy.Email;

        sendToUserMail(userEmail, job.status, allErrors,successCount,failedCount);// call sendToUserMail method to send mail to user
        
        if(!insertedAssestList.isEmpty())
        {
          	PEAC_SelectZipGeoCodeBatch batchJob1 = New PEAC_SelectZipGeoCodeBatch(insertedAssestList,true);
        	Database.executeBatch(batchJob1, Integer.ValueOf(Label.PEAC_SelectZipGeoCodeBatch_Limit)); // Adjust the batch size
     	  
        }
        	
        
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Send an email to the user with the status of the batch
    @User Story:SAL-5358
    @Created Date:April-20-2025    
    @Param: email id,status of the batch,list of all errors,count of success,count of failed
	@Return:None
    **************************************************************************************************************/

    public static void sendToUserMail(String toAddress, String status, List<String> allErrors,Integer successCount,Integer failedCount){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {toAddress});
        mail.setSubject('Assets Creation Job Status ' + status);
        String mailBody = 'Total number of inserted assets: '+ successCount + '\n';
        if(failedCount > 0  )
        {
            mailBody+='Total failed assets:'+failedCount+' with the below errors:'+ '\n';
            mailBody+= allErrors;  
        }
        if(successCount > 0){
          mailBody+='Tax Jurisdiction has been initiated for inserted assets.';  
        }
        mail.setPlainTextBody(mailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
        
}