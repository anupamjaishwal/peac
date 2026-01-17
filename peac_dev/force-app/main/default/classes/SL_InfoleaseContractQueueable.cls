public class SL_InfoleaseContractQueueable implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful{
	private Map<Id, Set<String>> fieldsByContractId = new Map<Id, Set<String>>();
	private Set<Id> contractIds = new Set<ID>();
	String stepName = '';
	Boolean needToPublishError = false;
	String lastErrorId = '';
	String lastErrorMessage = '';
	final String mainQuery = 'SELECT Id, Infolease_Environment__c, Address_1__c, Address_2__c, Address_3__c, City__c, State__c, Zip_Code__c, '
			+ 'AR_Name__c, AR_Address_1__c, AR_Address_2__c, AR_Address_3__c, AR_City__c, AR_State__c, AR_Zip_Code__c, Attention__c, '
			+ 'Tax_ID__c, Invoice_Code__c, User_Code__c, Reprint_Invoice__c, PO_Number__c, Name, Quote_Buyout__c, Invoice_Format__c, '
			+ 'Insurance_Status__c FROM Contract__c WHERE Id IN:contractIds';
   
	public SL_InfoleaseContractQueueable(List<Contract__c> contractList,Map<Contract__c,Set<String>> contractMap,Boolean listMap){
		if(listMAp == true){
			for(Contract__c cont:contractList){
				contractIds.add(cont.Id);
			}
		}else{
			for(Contract__c con:contractMap.keySet()){
				fieldsByContractId.put(con.Id, contractMap.get(con));
				contractIds.add(con.Id);
			}
		}
		
	}
	public SL_InfoleaseContractQueueable(String stepName){
		this.stepName = stepName;
	}

	public Database.QueryLocator start(Database.BatchableContext bc){
		String query = mainQuery;
		switch on stepName {
			when 'processPending' {
				query = 'SELECT Id, Record_Id__c, Fields_To_Update__c, Processed__c FROM IL_Update__c WHERE Processed__c = false';
			}
		}
		return Database.getQueryLocator(query);
	}
   
	public void execute(Database.BatchableContext bc, List<SObject> batchOfRecords){
		List<Contract__c> batchContracts = new List<Contract__c>();
		List<IL_Update__c> processedUpdates = new List<IL_Update__c>();
		switch on stepName {
			when 'processPending' {
				contractIds.clear();
				for(SObject obj:batchOfRecords){
					IL_Update__c pendingRecord = (IL_Update__c)obj;
					Id recordId = Id.valueOf(pendingRecord.Record_Id__c);
					if(recordId.getSObjectType().getDescribe().getName() == 'Contract__c'){
						contractIds.add(recordId);
						if(String.isNotEmpty(pendingRecord.Fields_To_Update__c)){
							fieldsByContractId.put(recordId, new Set<String>(pendingRecord.Fields_To_Update__c.split(',')));
						}
						pendingRecord.Processed__c = true;
						processedUpdates.add(pendingRecord);
					}
				}
				batchContracts = (List<Contract__c>)Database.query(mainQuery);
			}
			when else{
				batchContracts = (List<Contract__c>)batchOfRecords;
			}
		}
		String lastSuccessId = '';
		lastErrorId = '';
		for(Contract__c currentCon:batchContracts){
			SL_InfoleaseContractHelper contractAPI = new SL_InfoleaseContractHelper(currentCon.Id);
			SL_InfoleaseContractService service = new SL_InfoleaseContractService();
			Set<String> changeSet= new Set<String>();
			if(fieldsByContractId.size()>0){
				changeSet=fieldsByContractId.get(currentCon.Id);
			}	
			service.recordId = contractAPI.recordId;
			if (contractAPI.validate()) {
				try{
					String errorMessage = String.join(contractAPI.getErrorMessages(), ',');
					if(String.isNotEmpty(errorMessage)){
						storeError(errorMessage, currentCon, true);
					}else{
						String requestString = '';
						SL_InfoleaseIntegrationResponseWrapper response = null;
						if(changeSet.size() == 0){
							SL_InfoleaseContractRequestWrapper request = contractAPI.createRequest();
							response = service.updateContract(request, null, currentCon.Infolease_Environment__c);
							requestString = JSON.serialize(request, true);
						}else{
							requestString = contractAPI.mapSpecificFields(currentCon.Id, changeSet);
							response = service.updateContract(null, requestString,currentCon.Infolease_Environment__c);
						}
						errorMessage = processResponse(requestString, response, currentCon.Id);
						if(errorMessage == ''){
							currentCon.Integration_Status__c = 'Synced';
							lastSuccessId = currentCon.Id;
						}else{
							storeError(errorMessage, currentCon, false);
						}
					}
				} catch (Exception e) {
					storeError(e.getMessage(), currentCon, true);
				}
			}else{
				String errorMessage = String.join(contractAPI.getErrorMessages(), ',');
				storeError(errorMessage, currentCon, true);
				return;
			}
		}
		if(needToPublishError){
			EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+lastErrorMessage+'\n'+SL_InfoleaseConstants.contactAdmin,
				Status__c = 'Error', Record_Id__c = lastErrorId));
		}else{
			EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Record Synced Successfully.', 
				Status__c = 'Success', Record_Id__c = lastSuccessId));
		}
		update batchContracts;
		SL_InfoleaseLoggingUtils.flush();
		update processedUpdates;
	}
   
	void storeError(String errorMessage, Contract__c theContract, Boolean needsToLogError){
		Id contractId = theContract.Id;
		theContract.Integration_Status__c = 'Error';
		needToPublishError = true;
		lastErrorId = contractId;
		lastErrorMessage = errorMessage;
		if(needsToLogError){
			SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.contractUpdateJob , contractId, '', '', errorMessage, true);
		}
	}

	String processResponse(String editrequestJSON, SL_InfoleaseIntegrationResponseWrapper respBean, String contractId){
		String message = '';
		if(respBean != null){
			String responseJSON = JSON.serialize(respBean);
			if (respBean.response.Response.errors != null && !respBean.response.Response.errors.isEmpty ()) {
				
				for (String error : respBean.response.Response.errors) {
					System.debug('error: '+error);
					message = message + error +', ';
				}
				if (String.isNotBlank(message) && message.contains(',')) message = message.removeEnd (',');
				SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.contractUpdateJob , contractId, editrequestJSON, responseJSON, message, true);
			}else{
				SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.contractUpdateJob , contractId, editrequestJSON, responseJSON, '', false);
			}
		}
		return message;
	}
   
   public void finish(Database.BatchableContext bc){
		Id thisBatchId = bc.getJobId();
		Integer enqueuedBatchJobs = [SELECT COUNT() FROM AsyncApexJob 
            WHERE JobType='BatchApex' AND ApexClass.Name = 'SL_InfoleaseContractQueueable' AND Status IN ('Processing','Preparing','Queued', 'Holding')
			AND Id != :thisBatchId];
		if(enqueuedBatchJobs == 0){
			Integer pendingUpdates = [SELECT COUNT() FROM IL_Update__c WHERE Processed__c = false];
			if(pendingUpdates > 0){
				Database.executeBatch(new SL_InfoleaseContractQueueable('processPending'), Integer.valueOf(Label.SL_MaxCalloutsToIL));
			}
			
		}
   }
}