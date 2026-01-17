/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is implemented to support email message object business logic
@User Story:SL-2121 
@Created Date:August-07-2024   
**************************************************************************************************************/
public without sharing class PEAC_EmailMessageTriggerHelper {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will calculate Initial Response Time and update in Case record
    @User Story:SL-2121  
    @Created Date:August-07-2024   
    @Param: Map of email message Id and it's Record
    **************************************************************************************************************/
    
    public static void calculateIntialResporseDate(Map<Id, EmailMessage> newMap)
    {
        Set<Id> caseIdSet = New Set<Id>();// Initialise Set of case id
        List<Case> caseList = New List<Case>();//Initialise Case record to retrieve the case
        BusinessHours defaultBH = PEAC_UtilsClass.getDefalutBusinessHour();//get default Business Hours
        for(EmailMessage emailM : newMap.Values())
        {
            if(emailM.ParentId != NULL)//Check for Case Id
            {
                caseIdSet.add(emailM.ParentId);//Add Case It to the set
            }//end of if block
            
        }//end of for block
        caseList = PEAC_UtilsClass.getCaseList(caseIdSet); // Get case record with child email message with email sent from salesforce
        List<Case> casesToUpdate = New List<Case>();
        if(!caseList.isEmpty())
        {
            for(Case emailCase: caseList)
            {
                //Check if Case has email message record and reponse sent and response time is not null
                if(!emailCase.EmailMessages.IsEmpty() && emailCase.Initial_Response_Sent__c == NULL && emailCase.Response_Time__c == NULL) {
                    emailCase.Initial_Response_Sent__c = emailCase.EmailMessages[0].MessageDate;// assign intial response sent as message date
                    //set the respose time based on business hours of the company , case created date and message date
                    emailCase.Response_Time__c = PEAC_UtilsClass.calculateIntialResporseTime(defaultBH.Id, emailCase.CreatedDate, emailCase.Initial_Response_Sent__c);
                    // SL-2793 Misael Romero
                    if(!TC_RecursiveTriggerHelper.casesAlreadyInitialResponseTime.contains(emailCase.Id)){
                        casesToUpdate.add(emailCase);
                        TC_RecursiveTriggerHelper.casesAlreadyInitialResponseTime.add(emailCase.Id);
                    }
                }//end of if block           
            }//end of for block
            // update caseList;// Update Case list
        }
        // SL-2793 Misael Romero
        if(casesToUpdate.size() > 0){
            update casesToUpdate;
        }
    }//end of the method
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:This method will calculate Response Time based on case closed
    @User Story:SL-2121  
    @Created Date:August-07-2024   
    @Param:Map of Id with old record and Map of It with new record
    @Retun:None
    **************************************************************************************************************/
    public static void updateResponseTimeOnCaseClose(Map<Id, SObject> oldMap, Map<Id, SObject> newMap)
    {
        Map<Id, Case> newCaseMap = (Map<Id, Case>)newMap; //Typecasting of sboject to case 
        Map<Id, Case> oldCaseMap = (Map<Id, Case>)oldMap;//Typecasting of sboject to case
        Set<Id> caseIdSet = New Set<Id>();// Initialise set of case ids
        List<Case> caseList = New List<Case>();//list of case records to be updated
        BusinessHours defaultBH = PEAC_UtilsClass.getDefalutBusinessHour();//get the default businesshours
        for(Id caseId : newCaseMap.keyset())
        {
            //Check for closed case
            if(newCaseMap.get(caseId).isClosed && !oldCaseMap.get(caseId).isClosed)
            {
                caseIdSet.add(caseId);// add case id into set
            }//end of if block
        }//end of for block
        List<Case> casesToUpdate = New List<Case>();
        if(!caseIdSet.isEmpty())
        {
            caseList = PEAC_UtilsClass.getCaseList(caseIdSet);// get the case records with email message on case closed
            for(Case emailCase: caseList)
            {
                //email message should be empty for case to update response time on case
                if(emailCase.EmailMessages.IsEmpty())
                {
                    //get the response time as minutes from the businesshour class
                    emailCase.Response_Time__c = PEAC_UtilsClass.calculateIntialResporseTime(defaultBH.Id, newCaseMap.get(emailCase.Id).CreatedDate, newCaseMap.get(emailCase.Id).ClosedDate);
                    // SL-2793 Misael Romero
                    if(!TC_RecursiveTriggerHelper.casesAlreadyInitialResponseTime.contains(emailCase.Id)){
                        casesToUpdate.add(emailCase);
                        TC_RecursiveTriggerHelper.casesAlreadyInitialResponseTime.add(emailCase.Id);
                    }
                }//end of if block
            }//end of for block
            // update caseList;//update list of case records
        }//end of If block
        // SL-2793 Misael Romero
        if(casesToUpdate.size() > 0){
            update casesToUpdate;
        }
    }//end of the method
}