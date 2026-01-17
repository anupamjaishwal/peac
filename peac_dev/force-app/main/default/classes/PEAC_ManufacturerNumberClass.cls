/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is implemented to support Account object business logic
@User Story:SAL-5019
@Created Date:September-23-2024   
**************************************************************************************************************/
public with sharing class PEAC_ManufacturerNumberClass {
	/**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called from TC_AccountTriggerHandler class to generate manufacturer number
    @User Story:SAL-5019 
    @Created Date:September-23-2024    
    @Param: List of Accounts
    **************************************************************************************************************/
   
    public static void updateManucturerNumber(List<Account> accountList)
    {
       	String manufacturerNumber = generateManufNumber();
        for(Account manufAccount: accountList)
        {
            //check for manufacturer type and skip for data migration
            if(manufAccount.Type == PEAC_ConstantClass.MANUFACTURER && manufAccount.Dealer_Number__c == Null && String.isNotBlank(manufacturerNumber))
            {
              manufAccount.Business_Phone__c = incrementManufNumber(manufacturerNumber);//get new business phone number
              manufacturerNumber = manufAccount.Business_Phone__c;
            }
        }
        
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will get the maximum Business phone number
    @User Story:SAL-5019 
    @Created Date:September-23-2024    
    @Param:None
    **************************************************************************************************************/
   
    public static string generateManufNumber()
    {
        //get manufacturer account with max phone number
        List<Account> maxManufaturerNoList = [SELECT Id,Name,Business_Phone__c,Dealer_Number__c FROM
                                              Account WHERE Type =:PEAC_ConstantClass.MANUFACTURER
                                              ORDER BY Business_Phone__c DESC,Dealer_Number__c NULLS FIRST LIMIT 1];
        String manufacturerNumber = PEAC_ConstantClass.EMPTY;
        if(!maxManufaturerNoList.isEmpty())
        {
            manufacturerNumber = maxManufaturerNoList[0].Business_Phone__c;
        }
        return manufacturerNumber;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will get new Business phone number
    @User Story:SAL-5019 
    @Created Date:September-23-2024    
    @Param:Business phone number
	@Return:New Business phone number
    **************************************************************************************************************/

    public static String incrementManufNumber(String mNumber)
    {
        String firstMNumber = mNumber.left(PEAC_ConstantClass.MANUFATURER_FIRST_NUMBER);//get first part from the string
        String lastMNumber = mNumber.right(PEAC_ConstantClass.MANUFATURER_LAST_NUMBER);//get last part from the string
        Integer newNumber =  Integer.ValueOf(firstMNumber) + 1; // increment 1 in the first part
        Integer newNumberLength = PEAC_ConstantClass.MANUFATURER_FIRST_NUMBER - String.ValueOf(newNumber).length();//get total length of the first part
        string leftZeros = PEAC_ConstantClass.EMPTY;
        for(Integer i = 0 ;i<newNumberLength;i++)
        {
           leftZeros = leftZeros + PEAC_ConstantClass.ZEROS;  //add 0 at left
        }
        String finalFormat = leftZeros + String.valueOf(newNumber) + lastMNumber;//final business phone number
        return finalFormat;
    }
}