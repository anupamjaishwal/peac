/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This controller is used in pEAC_MeterCase lwc component where dealer user will be creating a meter read
				case.
@User Story:DP-957
@Created Date:June-20-2024 	    
*********************************************************************************************************************/

public with sharing class PEAC_MeterReadCaseController {
   	static final String QUEUE = 'queue';
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get current user login details
    @User Story:DP-957	 
    @Created Date:June-20-2024   
    **************************************************************************************************************/
	public static User getUser() {
        User currentUser = [SELECT Id,ContactId, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        return currentUser;
    } 
	/**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Get case queue id which will be assigned as case owner id
	@Param:Map od queue meter type and queue developer name
    @User Story:DP-957	 
    @Created Date:June-20-2024   
    **************************************************************************************************************/
	public static String getCaseQueues(Map<String,String>queueNameMap){
		List<Group> queuesList = New List<Group>();
        queuesList = [SELECT Id, DeveloperName FROM Group WHERE Type =:QUEUE AND DeveloperName IN :queueNameMap.values() LIMIT 1];
        String ownerId = '';
        if (!queuesList.isEmpty()) {
            for (Group queue : queuesList) {
                ownerId = queue.Id;
            }  
        }
        return ownerId;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Display list of meter case reason on LWC UI
    @User Story:DP-957	 
    @Created Date:June-20-2024   
    **************************************************************************************************************/

    @AuraEnabled(cacheable = true)
    public static Map<String,String> getCaseReason(){
      
        Map<String,String> reasonNameMap = new  Map<String,String>();
        List<Meter_Reads_Case__mdt> meterList = [SELECT MasterLabel,DeveloperName,Button_Name__c FROM Meter_Reads_Case__mdt];
        reasonNameMap.put(label.PEAC_Select_Reason_Type, PEAC_ConstantClass.EMPTY);
        if (!meterList.isEmpty()) {
            for (Meter_Reads_Case__mdt meter : meterList) {
                reasonNameMap.put(meter.MasterLabel,meter.Button_Name__c);
            }  
        
        }
        return reasonNameMap;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Get case recordtype id 
	@Param:Record Type developer name
    @User Story:DP-957	 
    @Created Date:June-20-2024   
    **************************************************************************************************************/

    private static String getCaseRecordTypeId(String typeName)
    {
        String caseRId = '';
        if(string.isNotBlank(typeName)){
            caseRId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get(typeName).getRecordTypeId();
        }
        return caseRId;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Get Meter reads configuration based on reason type
	@Param:Reason type
    @User Story:DP-957	 
    @Created Date:June-20-2024   
    **************************************************************************************************************/

    private static List<Meter_Reads_Case__mdt> getMeterReadsSetting(String meterReason){
       List<Meter_Reads_Case__mdt> meterList = [SELECT Queue_Name__c,
                                Default_Template__c,Case_Record_Type_API_Name__c,MasterLabel,DeveloperName,Button_Name__c 
                                FROM Meter_Reads_Case__mdt WHERE Button_Name__c =:meterReason];
      return meterList;  
    } 
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Prepare meter reads confguration and get vaules
	@Param:Reason type
    @User Story:DP-957	 
    @Created Date:June-20-2024   
	@Return:Return a wrapper class with predefined variables
    **************************************************************************************************************/
	@AuraEnabled
    public static CaseCreationWrapper getDetailedCase(String meterReason){
        String defaultValue = '';
        String accountId = '';
        String contactId = '';
        String recordTypeName = '';
        Map<String,String> queueNameMap = new Map<String,String>();
        List<Meter_Reads_Case__mdt> meterList = getMeterReadsSetting(meterReason);
        if (!meterList.isEmpty()) {
            for (Meter_Reads_Case__mdt meter : meterList) {
                queueNameMap.put(meter.Button_Name__c, meter.Queue_Name__c);
                recordTypeName = meter.Case_Record_Type_API_Name__c;
            }
        }
        User currentUser = getUser();
        if(currentUser!=null && currentUser.ContactId !=null)
        {
             contactId = currentUser.ContactId;
             accountId = currentUser.Contact.AccountId;
        }
        String ownerId = getCaseQueues(queueNameMap);
        String caseRId = getCaseRecordTypeId(recordTypeName);
        CaseCreationWrapper caseCreationWrap = new CaseCreationWrapper(accountId,contactId,ownerId,caseRId,'');// wrapper to assign variable and send to lwc componet
        if (!meterList.isEmpty()) {
            for (Meter_Reads_Case__mdt meter : meterList) {
				caseCreationWrap = new CaseCreationWrapper(accountId,contactId,ownerId,caseRId,meter.Default_Template__c);
				break;
            }  
        }
        return caseCreationWrap;
    }
    
   public class CaseCreationWrapper{
        @AuraEnabled
        public String ownerId;
        
        @AuraEnabled
        public String recordTypeIdValue; 
        
        @AuraEnabled
        public String defaultTemplate;

        @AuraEnabled
        public String dealerAccount;

        @AuraEnabled
        public String contactUser;

        public CaseCreationWrapper(String dealerAccount,String contactUser,String ownerId, String recordTypeIdValue, String defaultTemplate){
            this.ownerId = ownerId;
            this.recordTypeIdValue = recordTypeIdValue;
            this.defaultTemplate = defaultTemplate;
            this.dealerAccount = dealerAccount;
            this.contactUser = contactUser;
        }
    }
    
}