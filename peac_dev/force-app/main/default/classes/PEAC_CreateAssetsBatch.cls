/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for creating assets in batch
@User Story:SAL-5358
@Created Date:April-20-2025
*********************************************************************************************************************/

public class PEAC_CreateAssetsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    List<Asset__c> assetsList = new List<Asset__c>();
    List<Asset__c> insertedAssestList = new List<Asset__c>();
    Integer successCount = 0;
    Integer failedCount = 0;
    Integer multiCountyAssets = 0;
    List<String> allErrors = new List<String>();
	Map<String, String> fieldsConfig = new Map<String, String>();
	String oppId = null;
    //SAL-6955
    //List<Opportunity> oppList = new List<Opportunity>();
    //Static Final String CUSTOMER_OWNED = 'Customer Owned';
    //End SAL-6955
    //Map<String, Set<Id>> assetIdsMap = new Map<String, Set<Id>>();
    //Map<String, Map<String, Set<Id>>> oppAssetsMap = new Map<String, Map<String, Set<Id>>>();
	public PEAC_CreateAssetsBatch(List<Asset__c> assetList, string oppId) {
        this.assetsList = assetList;
        this.oppId = oppId;
        for(PEAC_BulkAssetsUpload__mdt mdt : [SELECT DeveloperName,Value__c FROM PEAC_BulkAssetsUpload__mdt WHERE DeveloperName IN ('AssetFieldsRespDataMapping','RateFieldsRespDataMapping')]){
            fieldsConfig.put(mdt.DeveloperName, mdt.Value__c);
        }
    }

    public PEAC_CreateAssetsBatch(List<Asset__c> assetList) {
        this.assetsList = assetList;
		this.oppId = assetList[0].Opportunity__c;
		for(PEAC_BulkAssetsUpload__mdt mdt : [SELECT DeveloperName,Value__c FROM PEAC_BulkAssetsUpload__mdt WHERE DeveloperName IN ('AssetFieldsRespDataMapping','RateFieldsRespDataMapping')]){
			fieldsConfig.put(mdt.DeveloperName, mdt.Value__c);
		}
    }

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
		try{//Below logic added for SAL-5692 Expo: Opportunity Refactor
			Set<String> uniqueZipsSet = new Set<String>();
            List<TC_BridgewareTaxJurisdiction> ratesRespList = new List<TC_BridgewareTaxJurisdiction>();
			//SAL-6955
            //oppList = [SELECT ID,Purchase_Options__c FROM Opportunity WHERE Id=: oppId];
            //End SAL-6955
			for(Asset__c asset :scopeList){
				if(String.isNotEmpty(asset.Equipment_Zip__c)){
					uniqueZipsSet.add(asset.Equipment_Zip__c);
				}
			}
            Map<String, Map<String, List<TC_BridgewareTaxJurisdiction>>> zipRespsMap = PEAC_BridgewareSelectZipGeoCodes.getZipTaxCodes(uniqueZipsSet);
            for(String zip : uniqueZipsSet){
                if(zipRespsMap?.get(zip)?.get('Rates')?.isEmpty() == false)
                    ratesRespList.addAll(zipRespsMap?.get(zip).get('Rates'));
            }
            if(!ratesRespList.isEmpty())
                PEAC_BridgewareSelectZipGeoCodes.saveRates(ratesRespList, fieldsConfig.get('RateFieldsRespDataMapping'));

			for(Asset__c asset :scopeList){
				if(zipRespsMap?.get(asset.Equipment_Zip__c)?.get('Assets')?.isEmpty() == false){
					PEAC_BridgewareSelectZipGeoCodes.updateAssets(asset, zipRespsMap?.get(asset.Equipment_Zip__c).get('Assets'), fieldsConfig.get('AssetFieldsRespDataMapping'));
					//SAL-6955
                    /*If(!CUSTOMER_OWNED.equals(oppList[0].Purchase_Options__c))
                    {
                    	asset.Property_Status__c = getPropertyStatus(asset.Equipment_Location_State__c);   
                    }*/
                    //End SAL-6955
					//assetsToUpdate.addAll(updateAssets(asset, zipRespsMap.get(asset.Equipment_Zip__c).get('Assets'), fieldsConfig.get('AssetFieldsRespDataMapping')));
				}
			}
            for(Asset__c asset : scopeList){
                if(asset.Multiple_Counties__c){
                    multiCountyAssets++;
                }
            }
            //added the below code to enforce duplicate rules on assets
            //Commented below code because duplicates will be blocked during csv upload itself
            /*Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.allowSave = false;
            dmlOpts.DuplicateRuleHeader.runAsCurrentUser = true;
            for(Asset__c asset : scopeList){
                asset.setOptions(dmlOpts);
            }*/
            //List<Database.SaveResult> insertedAssetList = Database.insert(scopeList, dmlOptions);
            //List<Database.SaveResult> insertedAssetList = Database.insert(scopeList, false);
            List<Database.UpsertResult> insertedAssetList = Database.upsert(scopeList, Asset__c.Id,false); // false allows for partial success
            for(Integer i = 0; i < insertedAssetList.size(); i++){
                if(insertedAssetList[i].isSuccess()) {
                    successCount++;
                }else{
                    failedCount++;
                    for (Database.Error err : insertedAssetList[i].getErrors()){
                        allErrors.add(scopeList[i].Serial_Number__c + ',' + scopeList[i].Description__c + ',' + err.getFields().toString() + err.getMessage());
                    }
                }
            }
        }
        catch(Exception ex){
            failedCount++;
            allErrors.add('The following error has occurred.'+ '--' + ex.getMessage() +'\r\n' );
        }
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Get Property Status based on property state code
    @User Story:SAL-6955
    @Created Date:03/25/2026
    @Param: Location State
	@Return:None
    **************************************************************************************************************/
    /*public static String getPropertyStatus(String locationState) {
        String propertyStatus = '';
        if(PEAC_ConstantClass.STATE_PROPERTY_STATUS.containsKey(locationState)){
             propertyStatus = PEAC_ConstantClass.STATE_PROPERTY_STATUS.get(locationState);
        }
        return propertyStatus;
    }*/
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Finish method of the batch class
    @User Story:SAL-5358
    @Created Date:April-20-2025
    @Param: Database.BatchableContext
	@Return:None
    **************************************************************************************************************/

    public void finish(Database.BatchableContext BC) {
        String jobId = bc.getJobId();// Get the Job ID
        AsyncApexJob job = [SELECT CreatedBy.Email,Status FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];//Get the user who submitted the batch
        String userEmail = job.CreatedBy.Email;

        sendToUserMail(userEmail, job.status, allErrors,successCount,failedCount,multiCountyAssets);//call sendToUserMail method to send mail to user
        Opportunity parentOpp = new Opportunity(Id = this.oppId);
        parentOpp.Last_Tax_Calculation_Begin__c = System.now();
        parentOpp.Is_Tax_Calculation_In_Progress__c = true;
        parentOpp.Last_Tax_Calculation_Successful__c = true;
        update parentOpp;

        if(!Test.isRunningTest() && successCount > 0){
            PEAC_GenerateTaxMatrixBatch taxMatBatch = new PEAC_GenerateTaxMatrixBatch(new Set<Id>{this.oppId}, true);//SAL-5692 Expo: Opportunity Refactor
            Database.executeBatch(taxMatBatch, Integer.Valueof(Label.PEAC_SelectZipGeoCodeBatch_Limit)); //Adjust the batch size
        }
        /*if(!insertedAssestList.isEmpty()){
            PEAC_SelectZipGeoCodeBatch batchJob1 = New PEAC_SelectZipGeoCodeBatch(insertedAssestList,true);
            Database.executeBatch(batchJob1, Integer.ValueOf(Label.PEAC_SelectZipGeoCodeBatch_Limit)); //Adjust the batch size
        }*/
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Send an email to the user with the status of the batch
    @User Story:SAL-5358
    @Created Date:April-20-2025
    @Param: email id,status of the batch,list of all errors,count of success,count of failed
	@Return:None
    **************************************************************************************************************/

    public static void sendToUserMail(String toAddress, String status, List<String> allErrors,Integer successCount,Integer failedCount, Integer multiCountyAssets){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {toAddress});
        mail.setSubject('Assets Creation/Updation Job Status ' + status);
        String mailBody = 'Total number of inserted/updated assets: '+ successCount + '\n' + '\n';
        if(failedCount > 0 ){
            mailBody+='Total number of failed assets: '+failedCount + '\n';
            mailBody+='Please find the attached file with the list of failed assets and their error messages.' + '\n' + '\n';
        }
        if(successCount > 0){
          mailBody+='Tax Matrix generation has been initiated for the assets that were successfully inserted/updated.'+ '\n' + '\n';
        }
        if(multiCountyAssets > 0){
          mailBody+='NOTE : We have '+multiCountyAssets+' Asset(s) with Multiple Counties. Please review/resolve them under \'Multi-County Assets\' tab.';
        }
        mail.setPlainTextBody(mailBody);
        if (!allErrors.isEmpty()) {
            String csvContent = 'Serial_Number,Description,ErrorMessage\n' + String.join(allErrors, '\n');
            Blob csvBlob = Blob.valueOf(csvContent);
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Bulk_Asset_Insertion_Errors.csv');
            attachment.setBody(csvBlob);
            attachment.setContentType('text/csv');
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}