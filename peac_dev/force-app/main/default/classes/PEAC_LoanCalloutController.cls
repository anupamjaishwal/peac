/************************************************************************************************************
*@Author:Rajesh Kumar(LTIMindtree)
@Description:This controller class is used to validate and process data to GDS,Onbase and Ocrolus application for loan opportunity
@Created Date:06/04/2025
@User Story:SAL-5460
 ************************************************************************************************************/

public without sharing class PEAC_LoanCalloutController {
 
/****************************************************************************************
* @Author:Rajesh Kumar(LTIMindtree)
* @Date:06/04/2025
* @Description: GDS Callout service
*****************************************************************************************/
    
    @AuraEnabled    
    Public static String submitAppToGDS(String OpptyId)
    {
        Set <Id> oppIsSet = New Set<Id>();
        oppIsSet.add(OpptyId);
        PEAC_AutoCaseCenterNumber.updateOppAppNumber(oppIsSet);
        List <Opportunity> updateList = new List <Opportunity> (); //Initialise the opportunity to update case center number
        updateList = [SELECT ID,CaseCenter__c,Loan_Purpose__c,Application_Submitted__c,StageName,Application_Status__c FROM Opportunity WHERE ID IN: oppIsSet];
        //Add for Teaser
        String actionType = updateList[0].Loan_Purpose__c != 'Teaser'?Label.PEAC_Initiate_Loan_App_to_GDS:Label.PEAC_Teaser_Initial_Submission;
        List<GDS_Action__e> gdsActionEventList = new List<GDS_Action__e>();
        gdsActionEventList.add(new GDS_Action__e(Record_Id__c = OpptyId,Action__c = actionType));
        System.debug('gdsActionEventList'+gdsActionEventList);
        if (!gdsActionEventList.isEmpty()) {
           EventBus.publish(gdsActionEventList);
        }
        updateList[0].Application_Submitted__c = System.now();
        update updateList;
        System.debug('updateList'+updateList);
        return  'Application Number: ' + updateList[0].CaseCenter__c ;
    }
  
    @AuraEnabled    
    Public static String validateApplicationForSubmission(String OpptyId)
    {
        
        String lValidationResult = validateRequiredFields(OpptyId);
        if(lValidationResult == 'Success')
            return 'Success';
        else
            
            return lValidationResult;
    }

    public Static String validateRequiredFields(String opptyId) {
        
        String lInvalidFieldList = '';  
        Integer lDealerCount = 0;
        Integer lGuarantorCount = 0;
  
        Opportunity opty = [select id,RecordType.Name,Requested_Amount__c,Business_Phone__c,Loan_Purpose__c,
                            Account.Account_State_Of_Incorporation__c,StageName,
                            Application__c,CaseCenter__c,Account.Tax_ID__c, Account_Business_Street__c,
                            Account_Business_City__c,Account_Business_State_Province__c,Account_Billing_Zip_Postal_Code__c,
                            Account.Business_Address__c,Account.Business_City__c,Account.Business_State__c,
                            Account.Business_Zip__c,Account.Date_Established__c,
                            (SELECT id,Primary_Dealer__c,name,Dealer__c,Dealer__r.Name, Dealer__r.Business_Address__c, 
                             Dealer__r.Business_City__c, Dealer__r.Business_State__c,Dealer__r.Dealer_Number__c, 
                             Dealer__r.Business_Zip__c, Dealer__r.Business_Phone__c, Dealer__r.Account_Branch__c 
                             FROM Brokers__r),                                                           
                            (Select Id,Contact__c,Account__c,Type__c,RP_PRIN_GUAR_CODE__c,
                                 Contact__r.FirstName, Contact__r.LastName, Contact__r.Suffix, 
                                 Contact__r.SSN__c,Contact__r.Phone, Contact__r.Email,
                                 Contact__r.BirthDate, Contact__r.Ownership_Pct__c, Contact__r.DL_State__c,Contact__r.DL_Number__c,
                                 Contact__r.Title, Contact__r.HomePhone, Contact__r.OtherStreet,Contact__r.OtherCity,
                                 Contact__r.OtherState,Contact__r.OtherStateCode,Contact__r.OtherPostalCode,
                                Contact__r.Account.CCAN__c  
                             from Guarantor__r where Type__c = 'Personal Guarantor'),(SELECT ID FROM Attachments__r
                                WHERE Type__c Like 'FS -%')
                            from Opportunity where Id =:OpptyId ];
        
        if(opty.StageName != 'Application')
            return 'Fail [This application is not in Application Stage]';
        
        if(String.IsBlank(opty.Account.Tax_ID__c))
            return 'Fail [Tax Id is missing]';

        if(!String.IsBlank(opty.CaseCenter__c))
            return 'Fail [This application is already submitted and applicaiton number is generated]';
        
        if(!opty.RecordType.Name.Contains('Loan'))
            return 'Fail [Opportunity record type is not valid for this operation]';
        
        //Check for bank statment
        if(opty.Attachments__r.isEmpty() && opty.Loan_Purpose__c != 'Teaser')
        {
          return 'Fail [Bank statement is missing for the loan application]';
        }
                
        if(opty.Guarantor__r.isEmpty()){
            lInvalidFieldList += 'Missing Guarantor Information, '; 
        }else{
            
            lInvalidFieldList += validateGuarantorFields(opty.Guarantor__r);
        }
        
        if (String.isBlank(opty.Account.Business_Address__c) && String.isBlank(opty.Account_Business_Street__c))
            lInvalidFieldList += 'Business Address, '; 
        
        if (String.isBlank(opty.Account.Business_City__c) && String.isBlank(opty.Account_Business_City__c))
            lInvalidFieldList += 'Business City, ';         

        if (String.isBlank(opty.Account.Business_State__c) && String.isBlank(opty.Account_Business_State_Province__c))
            lInvalidFieldList += 'Business State, '; 
        
        if (String.isBlank(opty.Account.Business_Zip__c) && String.isBlank(opty.Account_Billing_Zip_Postal_Code__c))
            lInvalidFieldList += 'Business Postal Code, ';    
        
        if (String.isBlank(opty.Business_Phone__c))
            lInvalidFieldList += 'Business Phone, ';  
                  
       
        if (opty.Requested_Amount__c == null)
            lInvalidFieldList += 'Loan Amount, ';    

        if(String.IsBlank(lInvalidFieldList))
            return 'Success';
        else
            return 'Fail [Missing Fields:' + lInvalidFieldList + ']';
        
        
    }
    
    public static String validateGuarantorFields(List<Guarantor__c> aLstGurtr){
        
        String lInvalidFieldList = '';
        
        for(Guarantor__c g : aLstGurtr){
            
          if (String.isBlank(g.Contact__r.FirstName))
            lInvalidFieldList += 'Guarantor First Name, ';        
            
          if (String.isBlank(g.Contact__r.LastName))
            lInvalidFieldList += 'Guarantor Last Name, ';   
            
          if (String.isBlank(g.Contact__r.Email))
            lInvalidFieldList += 'Guarantor Email, ';              

          if (String.isBlank(g.Contact__r.OtherStreet))
            lInvalidFieldList += 'Guarantor Address, ';   

          if (String.isBlank(g.Contact__r.OtherCity))
            lInvalidFieldList += 'Guarantor City, '; 
            
          if (String.isBlank(g.Contact__r.OtherState))
            lInvalidFieldList += 'Guarantor State, ';     

          if (String.isBlank(g.Contact__r.OtherStateCode))
            lInvalidFieldList += 'Guarantor Postal Code, ';    
            
          if (String.isBlank(g.Contact__r.SSN__c))
            lInvalidFieldList += 'Guarantor SSN, '; 

          if (g.Contact__r.BirthDate == null)
            lInvalidFieldList += 'Guarantor Birth Date, ';   
            
          if (g.Contact__r.Ownership_Pct__c == null)
            lInvalidFieldList += 'Guarantor Ownership %, ';            
            
        }

        return lInvalidFieldList;
    }  
    

    

}