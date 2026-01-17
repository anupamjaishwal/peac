public without sharing class AccountDetails {
    
    public class ErrorWrapperClass { 
        
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String errorMsg; //error msg
        @AuraEnabled public String successMsg; //success msg
        
        public ErrorWrapperClass(){
            isSuccess = true;
            errorMsg = '';
            successMsg = '';
        }
    }

@AuraEnabled
    public static ErrorWrapperClass getAccount(String stepName, String recordID) 
    {
        ErrorWrapperClass returnMessage = new ErrorWrapperClass();
        
        try{
			Account acct = [SELECT ID,Account_Stage__c FROM ACCOUNT where ID =:  recordID]; 
            acct.Account_Stage__c = stepName;
            update acct;
            returnMessage.successMsg = acct.Account_Stage__c;
        }
        catch(Exception e){
            //returnStatus = e.getMessage();
            system.debug('exception'+returnMessage);
             returnMessage.isSuccess = false;
            
            //Adding the error message if an exception is occured
            returnMessage.errorMsg = e.getMessage();
            system.debug('summary' + e.getCause());
            //throw new AuraHandledException('error occured' + e.getMessage());
            
        }
        return returnMessage;
    }    


@AuraEnabled
    public static Account getAccountPriority(String recordID) 
    {
        String returnStatus = '';
        Account acct;
        try{
			acct = [SELECT ID,Account_Stage__c FROM ACCOUNT where ID =:  recordID];
            returnStatus = acct.Id;
        }
        catch(Exception e){
            returnStatus = e.getMessage() + ', ' + e.getStackTraceString();
        }
        return acct;
    }    
}