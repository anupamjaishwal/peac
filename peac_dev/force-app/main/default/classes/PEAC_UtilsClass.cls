/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is a Utils calss to reuse common resources across the applications
@User Story:SL-2121 
@Created Date:August-07-2024   
**************************************************************************************************************/
public with sharing class PEAC_UtilsClass {

    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will calculate Response Time based on input provided
    @User Story:SL-2121  
    @Created Date:August-07-2024   
    @Param: Business hours Id, DateTime, Datetime
    @Retun: Respone time in minutes
    **************************************************************************************************************/
    public static Decimal calculateIntialResporseTime(Id bhID, DateTime caseCreated, Datetime responseSent)
    {
        Decimal reponseTime = BusinessHours.diff(bhID,caseCreated,responseSent);// Call inbuilt method to calculate diff as milliseconds 
        Integer mintuesInTime = Integer.ValueOf((reponseTime / 1000)/60) ;//convert as minutes
        Integer remainingMinutes = Math.Mod(Integer.valueOf(reponseTime / 1000),60);//get remaining from minutes as seconds
        String totalMinutes = mintuesInTime + PEAC_ConstantClass.DOT + remainingMinutes; // concatinate minutes and seconds in decimal format
        Decimal newResTime = Decimal.ValueOf(totalMinutes);//convert it as decimal
        return newResTime;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get default BusinessHour record
    @User Story:SL-2121  
    @Created Date:August-07-2024   
    @Param: None
    @Retun: BusinessHours
    **************************************************************************************************************/
	public static BusinessHours getDefalutBusinessHour()
    {
       BusinessHours defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];//get default Business Hours
       return defaultBH;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get case records with sent email message details
    @User Story:SL-2121  
    @Created Date:August-07-2024   
    @Param: Set of case ids
    @Retun: List of cases
    **************************************************************************************************************/
	
    public static List<Case> getCaseList(Set<Id> caseIdSet){
        String searchKeyword = PEAC_ConstantClass.PERCENTAGE + Label.PEAC_No_Reply_Email + PEAC_ConstantClass.PERCENTAGE ;//Get the no reply from custom label
        List<Case> caseList = New List<Case>();
        caseList = [SELECT Id,Initial_Response_Sent__c,Response_Time__c,CreatedDate,
                    (SELECT ID,ParentId,MessageDate FROM EmailMessages WHERE Incoming = false AND (NOT FROMAddress Like:searchKeyword) 
                     ORDER BY MessageDate ASC LIMIT 1)
                    FROM Case WHERE ID IN:caseIdSet];// Get case record with child email message with email sent from salesforce
        return caseList;
    }
}