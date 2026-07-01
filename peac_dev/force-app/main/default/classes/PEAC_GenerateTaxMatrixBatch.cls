/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This batch class is used to Generate Tax Matrix for bulk processing
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Oct-10-2025
**************************************************************************************************************/

public class PEAC_GenerateTaxMatrixBatch implements Database.Batchable<PEAC_MixedObjWrapper>, Database.Stateful, Database.AllowsCallouts {
	Set<Id> oppIds = new Set<Id>();
	Integer failedCount = 0;
	Integer successCount = 0;
	List<String> failedAssetList = new List<String>();
	String error = 'Tax Matrix generated successfully.';
    String errorDetails;
	Boolean sendEmail = false;
    public static Boolean isRunning = false;

	public PEAC_GenerateTaxMatrixBatch(Set<Id> oppIds) {
		this.oppIds = oppIds;
	}

	public PEAC_GenerateTaxMatrixBatch(Set<Id> oppIds, Boolean sendEmail) {
		this.oppIds = oppIds;
		this.sendEmail = sendEmail;
	}
	
    public Iterable<PEAC_MixedObjWrapper> start(Database.BatchableContext bc) {
        isRunning = true;
        return new PEAC_MixedObjIterable(this.oppIds);
    }
    
	/*public List<Asset__c> start(Database.BatchableContext BC) {
		List<Asset__c> assetsList = [SELECT Id,Opportunity__c FROM Asset__c WHERE Opportunity__c IN:this.oppIds];
		system.debug('Final size from start method ==>'+assetsList.size());
		if(Test.isRunningTest()){
			return new List<Asset__c>{assetsList[0]};
		}else{
			return assetsList;
		}
	}*/
	
	public void execute(Database.BatchableContext bc, List<PEAC_MixedObjWrapper> scopeList) {
		Map<String, Map<String, Set<Id>>> oppAssetsMap = new Map<String, Map<String, Set<Id>>>();
		
		try {
			for(PEAC_MixedObjWrapper rec : scopeList){
                switch on rec.objectType{
                    when 'Asset__c'{
                        if(oppAssetsMap.containsKey(((Asset__c)rec.record).Opportunity__c) && oppAssetsMap.get(((Asset__c)rec.record).Opportunity__c).containsKey('Asset__c')){
                            oppAssetsMap.get(((Asset__c)rec.record).Opportunity__c).get('Asset__c').add(((Asset__c)rec.record).Id);
                        }else if(oppAssetsMap.containsKey(((Asset__c)rec.record).Opportunity__c)){
                            oppAssetsMap.get(((Asset__c)rec.record).Opportunity__c).put('Asset__c', new Set<Id>{((Asset__c)rec.record).Id});
                        }else{
                            oppAssetsMap.put(((Asset__c)rec.record).Opportunity__c, new Map<String, Set<Id>>{'Asset__c' => new Set<Id>{((Asset__c)rec.record).Id}});
                        }
                    }
                    when 'Miscellaneous_Billable_Item__c'{
                        if(oppAssetsMap.containsKey(((Miscellaneous_Billable_Item__c)rec.record).Opportunity__c) && oppAssetsMap.get(((Miscellaneous_Billable_Item__c)rec.record).Opportunity__c).containsKey('Miscellaneous_Billable_Item__c')){
                            oppAssetsMap.get(((Miscellaneous_Billable_Item__c)rec.record).Opportunity__c).get('Miscellaneous_Billable_Item__c').add(((Miscellaneous_Billable_Item__c)rec.record).Id);
                        }else if(oppAssetsMap.containsKey(((Miscellaneous_Billable_Item__c)rec.record).Opportunity__c)){
                            oppAssetsMap.get(((Miscellaneous_Billable_Item__c)rec.record).Opportunity__c).put('Miscellaneous_Billable_Item__c', new Set<Id>{((Miscellaneous_Billable_Item__c)rec.record).Id});
                        }else{
                            oppAssetsMap.put(((Miscellaneous_Billable_Item__c)rec.record).Opportunity__c, new Map<String, Set<Id>>{'Miscellaneous_Billable_Item__c' => new Set<Id>{((Miscellaneous_Billable_Item__c)rec.record).Id}});
                        }
                    }
                    when 'Miscellaneous_Invoice_Item__c'{
                        if(oppAssetsMap.containsKey(((Miscellaneous_Invoice_Item__c)rec.record).Opportunity__c) && oppAssetsMap.get(((Miscellaneous_Invoice_Item__c)rec.record).Opportunity__c).containsKey('Miscellaneous_Invoice_Item__c')){
                            oppAssetsMap.get(((Miscellaneous_Invoice_Item__c)rec.record).Opportunity__c).get('Miscellaneous_Invoice_Item__c').add(((Miscellaneous_Invoice_Item__c)rec.record).Id);
                        }else if(oppAssetsMap.containsKey(((Miscellaneous_Invoice_Item__c)rec.record).Opportunity__c)){
                            oppAssetsMap.get(((Miscellaneous_Invoice_Item__c)rec.record).Opportunity__c).put('Miscellaneous_Invoice_Item__c', new Set<Id>{((Miscellaneous_Invoice_Item__c)rec.record).Id});
                        }else{
                            oppAssetsMap.put(((Miscellaneous_Invoice_Item__c)rec.record).Opportunity__c, new Map<String, Set<Id>>{'Miscellaneous_Invoice_Item__c' => new Set<Id>{((Miscellaneous_Invoice_Item__c)rec.record).Id}});
                        }
                    }
                }
			}
            for(String oppId : oppAssetsMap.keySet()){
				//system.debug('Final size before calling ==>'+oppAssetsMap.get(oppId).size());
				PEAC_CommonUtils.byPassAssetTrigger = true;
				TaxRules.generateTaxMatrix(oppId, oppAssetsMap.get(oppId));
				PEAC_CommonUtils.byPassAssetTrigger = false;
			}
		} catch (Exception ex) {
            system.debug('Error ==>'+ex.getMessage()+ex.getStackTraceString());
			failedCount++;
			error = 'Error:' +ex.getMessage();
            errorDetails = ex.getStackTraceString() + '';
		}
	}

	public void finish(Database.BatchableContext BC) {
		String jobId = bc.getJobId();
		AsyncApexJob job = [SELECT CreatedBy.Email,Status FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
		String userEmail = job.CreatedBy.Email;

		TaxRules.updateParent((new List<Id>(this.oppIds))[0], error, errorDetails);
        isRunning = false;
		if(sendEmail){
			sendToUserMail(userEmail, job.status, failedAssetList,successCount,failedCount);// call sendToUserMail method to send mail to user
		}
	}

	public static void sendToUserMail(String toAddress, String status, List<String> failedAssetList,Integer successCount,Integer failedCount){
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] {toAddress});
		mail.setSubject('Generate Tax Matrix Job Status ' + status);
		//String mailBody = 'Total number of processed assets: '+ successCount + '\n';
		String mailBody = 'Tax Matrix generation is completed with below status :'+ '\n' + status  + '\n' + '\n';

		/*if(failedCount > 0 ){
			mailBody+='List of failed assets:'+failedCount+' :'+ '\n';
			for(String failedRecord: failedAssetList){
			   mailBody+= failedRecord;  
			}
		}*/
		mail.setPlainTextBody(mailBody);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
}