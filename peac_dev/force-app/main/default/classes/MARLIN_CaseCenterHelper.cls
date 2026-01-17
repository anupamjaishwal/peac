public class MARLIN_CaseCenterHelper {

    
/****************************************************************************************
* @Author       Huron Team
* @Date         December 15, 2017
* @Description  Case Center Helper Function
*****************************************************************************************/  
    Private Static Map<String,String> ccMaps = new Map<String,String>();
    Private Static List<Dealer__c> lDealerList = new List<Dealer__c >();
    
    public Static string getXMLValue(Object fieldValue) {
        if(fieldValue == null)
            return '';
        else{
            fieldValue = String.ValueOf(fieldValue).replaceAll('>','&gt;'); 
            fieldValue = String.ValueOf(fieldValue).replaceAll('<','&lt;');            
            return String.ValueOf(fieldValue);
        }           
    }   
    

    
    public Static String validateRequiredFields(String opptyId) {
        
        String lInvalidFieldList = '';  
        Integer lDealerCount = 0;
        Integer lGuarantorCount = 0;
  
        Opportunity opty = [select id,RecordType.Name,Requested_Amount__c,Business_Phone__c,
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
                             from Guarantor__r where Type__c = 'Personal Guarantor')
                            from Opportunity where Id =:OpptyId ];
        
        if(opty.StageName != 'Application')
            return 'Fail [This application is not in Application Stage]';
        

        if(!String.IsBlank(opty.CaseCenter__c))
            return 'Fail [This application is already submitted and applicaiton number is generated]';
        
        if(!opty.RecordType.Name.Contains('Loan'))
            return 'Fail [Opportunity record type is not valid for this operation]';
                
        if(opty.Guarantor__r.size() == 0){
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
    
  
    
    public Static string createRequestMsg(String opptyId) {
        
        String UserName = System.Label.RapportUser;
        String Password = System.Label.RapportPassword;
        String Alias = System.Label.Rapport_Alias; 
        Guarantor__c lGuarantor = New Guarantor__c();  
        String lDealerNumber = '';
        String lRelatedPartyMsg = '';
        Integer lGrtCount = 0;
        String lGuarntorEmail = '';
        String BusinessType = '';
        String BusinessStreet = '';
        String BusinessCity = ''; 
        String BusinessState = '';
        String BusinessZip = '';
        String lContactName = '';
        String lContactEmail = '';
        String lContactMobilePhone = '';
        String lContactTitle = '';
       // String ,lEndUserSourceCode,lProfileName;
        
        
        buildCCMap();  
        
 //       List<Profile> userPropfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
 //       lProfileName = userPropfile[0].Name;           
        
        Opportunity optyList = [select id,RecordType.Name,Requested_Amount__c,Loan_Purpose__c,
                                Business_Type__c,Product__c,Oppt_FS_Use_Of_Funds__c,AccountId,Primary_Source__c,
                                Approved_Amount__c,Sales_Rep__c,Tax_ID__c,Business_Phone__c,Average_Daily_Balance__c,
                                Annual_Revenue__c,Sales_Comments__c,
                                Owner.Email, Account.Website,Account.Fax,
                                Account.Name, Account.DBA__c,Account.Business_Type__c,Account.PQ_Expiration__c,
                                Account.Line_of_Business__c,Account.Business_Address__c,Account.Business_City__c,
                                Account.Business_State__c,Account.Business_Zip__c,Account.Business_Phone__c,
                                Application__c,Account.BILLINGSTREET,Account.BILLINGCity,Account.BillingStateCode,
                                Account.BillingPostalCode, Account.Tax_ID__c,Account.Account_Mobile_Number__c,
                                Account.CCAN__c,Account.Account_State_Of_Incorporation__c,Account.CCID__c,
                                Account.Landlord_Mortgage_Company__c,Account.Rent_Own__c,Account.Landlord_Mortgage_Payment__c,
                                Account.Landlord_Mortgage_RentStartDate__c,Account.Landlord_Mortgage_LeaseTerm__c,
                                Account.Landlord_Mortgage_ContactName__c, Account.Landlord_Mortgage_ContactPhone__c, 
                                Account.Landlord_Mortgage_Email__c,Account.Loan_Pre_Qual_Amount__c,Account.Lease_Exposure__c,
                                Account.Loan_Exposure__c, Account.Total_Exposure__c, Primary_Broker__c, 
                                Account.Bank_Balance__c, Account.AnnualRevenue,Account.Date_Established__c,
                                // primary broker fields
                                Primary_Broker__r.Business_Address__c, Primary_Broker__r.Business_City__c,Primary_Broker__r.Name,Primary_Broker__r.Contact_Email__c,Primary_Broker__r.Business_State__c ,Primary_Broker__r.Tax_Id__c,Primary_Broker__r.Business_Zip__c,Primary_Broker__r.Business_Phone__c,
                                // additonal new fields
                                Program_Tier__c, Owner.Name,Competitor_Loan_Existing__c, Reported_Loans_w_Balance__c, Competitor_Loan_Existing_Y_N__c,
                                (SELECT IsPrimary,Contact.Name, Contact.Email, 
                                 Contact.MobilePhone, Contact.Title, Role,Contact.Validity_Verify__Status__c, Contact.Final_E_mail_Validity_Result__c FROM OpportunityContactRoles
                                 where Role = 'Primary Contact'),
                                (SELECT id,name,Primary_Dealer__c,Dealer__c,Dealer__r.Name,Dealer__r.Tax_ID__c, Dealer__r.Business_Address__c, 
                                 Dealer__r.Business_City__c, Dealer__r.Business_State__c,Dealer__r.Dealer_Number__c, 
                                 Dealer__r.Business_Zip__c, Dealer__r.Account_Branch__c,Dealer__r.Business_Phone__c,Dealer__r.Account_Dealer_Status__c, Dealer__r.Contact_Email__c 
                                 FROM Brokers__r),
                                (SELECT Id, Account__r.Name, Account__r.Business_Address__c, Account__r.Business_Phone__c,Account__r.Business_City__c,Account__r.Contact_Email__c,Account__r.Business_State__c,Account__r.Tax_Id__c,Account__r.Business_Zip__c,Account__c
                                FROM Brokers1__r ORDER BY CreatedDate DESC),
                                (Select Id,Contact__c,Account__c,Type__c,RP_PRIN_GUAR_CODE__c,Contact__r.Validity_Verify__Status__c, Contact__r.Final_E_mail_Validity_Result__c,
                                 Contact__r.FirstName, Contact__r.LastName, Contact__r.Suffix,
                                 Contact__r.SSN__c,Contact__r.Phone, Contact__r.Email,
                                 Contact__r.BirthDate, Contact__r.Ownership_Pct__c, Contact__r.DL_State__c,Contact__r.DL_Number__c,
                                 Contact__r.Title, Contact__r.HomePhone, Contact__r.OtherStreet,Contact__r.OtherCity,
                                 Contact__r.OtherState,Contact__r.OtherStateCode,Contact__r.OtherPostalCode,Contact__r.Account.CCAN__c
                                 from Guarantor__r where Type__c = 'Personal Guarantor'
                                 order by Contact__r.Ownership_Pct__c desc),
                                (SELECT Id, Type__c
                                FROM Attachments__r)
                                from Opportunity where Id =:OpptyId ];


 //       lContactPhone = getNumericOnly(getXMLValue(String.ValueOf(optyList.Business_Phone__c)));


        if (optyList.Account.Business_Type__c == '' || optyList.Account.Business_Type__c == null)
        {
            BusinessType = optyList.Business_Type__c;
        }

        else
        {
            BusinessType = optyList.Account.Business_Type__c;
        }

        if (optyList.Account.Business_Address__c == '' && optyList.Account.Business_City__c == '' && optyList.Account.Business_State__c == '' && optyList.Account.Business_Zip__c == '')
        {
            BusinessStreet = optyList.Account_Business_Street__c;
            BusinessCity = optyList.Account_Business_City__c;
            BusinessState = optyList.Account_Business_State_Province__c;
            BusinessZip = optyList.Account_Billing_Zip_Postal_Code__c;
        }

        else
        {
            BusinessStreet = optyList.Account.Business_Address__c;
            BusinessCity = optyList.Account.Business_City__c;
            BusinessState = optyList.Account.Business_State__c;
            BusinessZip = optyList.Account.Business_Zip__c;
        }

        System.debug('Rapport Opportunity: ' + optyList);



        for(OpportunityContactRole ocr : optyList.OpportunityContactRoles){

            lContactName = ocr.Contact.Name;
            lContactEmail = ocr.Contact.Email;
            lContactMobilePhone = ocr.Contact.MobilePhone;
            lContactTitle = ocr.Contact.Title;
        }

        // getting message for PGs
        if(optyList.Guarantor__r.size() > 0){
            System.debug ('?????? correct path' + optyList.Guarantor__r);
            lRelatedPartyMsg = createGuarantorMsg(optyList.Guarantor__r);
            lGuarntorEmail = optyList.Guarantor__r[0].Contact__r.Email;
        }


        String lDealerAccountId = '';
        lDealerList = optyList.Brokers__r;
        System.debug('Dealers Count:' + lDealerList.size());
        if(optyList.Brokers__r.size() > 0) {

       //     lDealerAccountId = String.ValueOf(lDealerList[0].Get('Dealer__c'));
            lDealerNumber = String.ValueOf(lDealerList[0].getSobject('Dealer__r').get('Dealer_Number__c'));
            System.debug('Dealer Name: ' + lDealerList[0].getSobject('Dealer__r').get('Name'));
        }
        System.Debug('Dealer Number:' + lDealerNumber);
 /*
        if(!String.isBlank(lDealerAccountId)){
            lDealerConList = [select id,FirstName,LastName,Email,Phone,Name
                              from Contact where AccountId =:lDealerAccountId ];

        }*/





        System.debug('Rapport Dealers: ' + lDealerList);
        String requestMsg = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<APPLICATIONDATA xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '   <offer_pricing_model>' + transCC('Primary_Source',optyList.Primary_Source__c) + '</offer_pricing_model>' +
            '   <CALLTYPE>SF</CALLTYPE>' +
            '   <APPLICATIONDATE>' + getFormattedDateString(System.today(),'MM/dd/YYYY') + '</APPLICATIONDATE>' +
            '   <BROKERVENDORNUMBER>' +  formatDealerNumber(lDealerNumber) + '</BROKERVENDORNUMBER>' +
            '   <CCAN>' + getXMLValue(optyList.Account.CCAN__c) + '</CCAN>' +
            '   <CCID>' + getXMLValue(optyList.Account.CCID__c) + '</CCID>' +
            '   <SALESREPCODE>' + getXMLValue(optyList.Owner.Email) + '</SALESREPCODE>' +
            '   <LOANAMOUNT>' + getXMLValue(optyList.Requested_Amount__c) + '</LOANAMOUNT>' +
            '   <LOANTYPE>' + transCC('product',optyList.product__c) + '</LOANTYPE>' +
            '   <LOANPURPOSE>' + getXMLValue(optyList.Loan_Purpose__c) + '</LOANPURPOSE>' +
            '   <OTHERPURPOSE>' + getXMLValue(optyList.Oppt_FS_Use_Of_Funds__c) + '</OTHERPURPOSE>' +
            '   <SalesCreditComments>' + getXMLValue(optyList.Sales_Comments__c) + '</SalesCreditComments>' +
            '   <COMPANY1>' +
            '      <ADDRESS>' + getXMLValue(BusinessStreet) + '</ADDRESS>' +
            '      <CITY>' + getXMLValue(BusinessCity) + '</CITY>' +
            '      <IDNUMBER>' + getSubstring(getXMLValue(optyList.Account.Tax_ID__c),30) + '</IDNUMBER>' +
            '      <NAME>' + getSubstring(getXMLValue(optyList.Account.Name),50) + '</NAME>' +
            '      <STATE>' + getXMLValue(BusinessState) + '</STATE>' +
            '      <ZIPCODE>' + getXMLValue(BusinessZip) + '</ZIPCODE>' +
            '      <FAX>' + getXMLValue(optyList.Account.Fax) + '</FAX>' +
            '      <CONTACT>' + lContactName + '</CONTACT>' +
            '      <CONTACTTITLE>' + lContactTitle + '</CONTACTTITLE>' +
            '      <WEBSITE>' + getXMLValue(optyList.Account.Website) + '</WEBSITE>' +
            '      <PHONE>'+ getNumericOnly(getXMLValue(String.ValueOf(optyList.Business_Phone__c))) +'</PHONE>' +
            '      <CELLPHONE>' + getNumericOnly(lContactMobilePhone) + '</CELLPHONE>' +
            '      <EMAIL>' + lContactEmail + '</EMAIL>' +
            '      <STATEINCORP>' + getXMLValue(optyList.Account.Account_State_Of_Incorporation__c) + '</STATEINCORP>' +
            '      <SELFREPORTEDBUSSTARTDATE>' + getFormattedDateString(optyList.Account.Date_Established__c,'MM/dd/YYYY') + '</SELFREPORTEDBUSSTARTDATE>' +
            '      <DBA>' + getXMLValue(optyList.Account.DBA__c) + '</DBA>' +
            '      <STRUCTURE>' + transCC('Business_Type',BusinessType) + '</STRUCTURE>' +
            '   </COMPANY1>' +
            lRelatedPartyMsg +
            '   <Landlord_Mortgage>' +
            '      <Landlord_Mortgage_Company>' + getXMLValue(optyList.Account.Landlord_Mortgage_Company__c) + '</Landlord_Mortgage_Company>' +
            '      <Landlord_Mortgage_Rent_Own>' + getXMLValue(optyList.Account.Rent_Own__c) + '</Landlord_Mortgage_Rent_Own>' +
            '      <Landlord_Mortgage_Payment>' + getXMLValue(optyList.Account.Landlord_Mortgage_Payment__c) + '</Landlord_Mortgage_Payment>' +
            '      <Landlord_Mortgage_RentStartDate>' + getFormattedDateString(optyList.Account.Landlord_Mortgage_RentStartDate__c,'MM/dd/YYYY') + '</Landlord_Mortgage_RentStartDate>' +
            '      <Landlord_Mortgage_LeaseTerm>' + getXMLValue(optyList.Account.Landlord_Mortgage_LeaseTerm__c) + '</Landlord_Mortgage_LeaseTerm>' +
            '      <Landlord_Mortgage_ContactName>' + getXMLValue(optyList.Account.Landlord_Mortgage_ContactName__c) + '</Landlord_Mortgage_ContactName>' +
            '      <Landlord_Mortgage_ContactPhone>' + getXMLValue(optyList.Account.Landlord_Mortgage_ContactPhone__c) + '</Landlord_Mortgage_ContactPhone>' +
            '      <Landlord_Mortgage_Email>' + getXMLValue(optyList.Account.Landlord_Mortgage_Email__c) + '</Landlord_Mortgage_Email>' +
            '   </Landlord_Mortgage>' +
            '   <FS_PQ_Amount>' + getXMLValue(optyList.Account.Loan_Pre_Qual_Amount__c) + '</FS_PQ_Amount>' +
            '   <PQ_Expiration_Date>' + getFormattedDateString(optyList.Account.PQ_Expiration__c,'MM/dd/YYYY') + '</PQ_Expiration_Date>' +
            '   <MLC_Exposure>' + getXMLValue(optyList.Account.Lease_Exposure__c) + '</MLC_Exposure>' +
            '   <FS_Exposure>' + getXMLValue(optyList.Account.Loan_Exposure__c) + '</FS_Exposure>' +
            '   <Total_Marlin_Exposure>' + getXMLValue(optyList.Account.Total_Exposure__c) + '</Total_Marlin_Exposure>' +
            '   <ANNUALREVENUE>' + getXMLValue(optyList.Annual_Revenue__c) + '</ANNUALREVENUE>' +
            '   <BANKBALANCE>' + getXMLValue(optyList.Average_Daily_Balance__c) + '</BANKBALANCE>';
        // 6/20/19 made change to support lending tree
        if (optyList.Primary_Source__c == 'Indirect' || optyList.Primary_Source__c == 'LendingTree') {
            String address = '', phone = '', city = '', name = '', email = '', state = '', taxId = '', zip = '';
            system.debug('optyList.Primary_Broker__c:'+optyList.Primary_Broker__c);
            if (optyList.Primary_Broker__c != null) {
                System.debug ('<<<< shouldnt be here');
                address = optyList.Primary_Broker__r.Business_Address__c; phone = optyList.Primary_Broker__r.Business_Phone__c;city = optyList.Primary_Broker__r.Business_City__c;name = optyList.Primary_Broker__r.Name;email = optyList.Primary_Broker__r.Contact_Email__c;state = optyList.Primary_Broker__r.Business_State__c;taxId = optyList.Primary_Broker__r.Tax_Id__c;zip = optyList.Primary_Broker__r.Business_Zip__c;
                email = getEmailsFromACRs(optyList.Primary_Broker__c, email);//SAL-4215
            } else {
                System.debug ('<<<<< correct 1');
                if (!optyList.Brokers1__r.isEmpty ()) {
                    System.debug ('<<<<< Correct 2');
                    address = optyList.Brokers1__r[0].Account__r.Business_Address__c; phone = optyList.Brokers1__r[0].Account__r.Business_Phone__c;city = optyList.Brokers1__r[0].Account__r.Business_City__c;name = optyList.Brokers1__r[0].Account__r.Name;email = optyList.Brokers1__r[0].Account__r.Contact_Email__c;state = optyList.Brokers1__r[0].Account__r.Business_State__c;taxId = optyList.Brokers1__r[0].Account__r.Tax_Id__c;zip = optyList.Brokers1__r[0].Account__r.Business_Zip__c;
                    email = getEmailsFromACRs(optyList.Brokers1__r[0].Account__c, email);//SAL-2604
                }
            }
            requestMsg += '<ORIGINATORS>' +
            '<ORIGINATORS_ADDRESS>' + getXMLValue(address) + '</ORIGINATORS_ADDRESS>' +
            '<ORIGINATORS_BUSINESSPHONE>' + getXMLValue(phone) + '</ORIGINATORS_BUSINESSPHONE>' +
            '<ORIGINATORS_CITY>' + getXMLValue(city) + '</ORIGINATORS_CITY>' +
            '<ORIGINATORS_COMPANYNAME>' + getXMLValue(name) + '</ORIGINATORS_COMPANYNAME>' +
            '<ORIGINATORS_EMAIL>' + getXMLValue(email) + '</ORIGINATORS_EMAIL>' +
            '<ORIGINATORS_STATE>' + getXMLValue(state) + '</ORIGINATORS_STATE>' +
            '<ORIGINATORS_TAXID>' + getXMLValue(taxId) + '</ORIGINATORS_TAXID>' +
            '<ORIGINATORS_ZIPCODE>' + getXMLValue(zip) + '</ORIGINATORS_ZIPCODE>' +
            '<ORIGINATORS_CLASSIFICATION></ORIGINATORS_CLASSIFICATION>' +
            '<ORIGINATORS_STATUS></ORIGINATORS_STATUS>' +
            '</ORIGINATORS>';
        }

        requestMsg += '<UD_FS_INCENT>' + getXMLValue(optyList.Program_Tier__c) + '</UD_FS_INCENT>' +
        '<processor>'  + getXMLValue(optyList.Owner.Name) +  '</processor>';
        if (optyList.Competitor_Loan_Existing_Y_N__c == 'Yes') {
            requestMsg += '<COMPETITOR>true</COMPETITOR>';
        } else {
            requestMsg += '<COMPETITOR>false</COMPETITOR>';
        }

        requestMsg += '<COMPETITORBALANCE1>' + getXMLValue(optyList.Reported_Loans_w_Balance__c) + '</COMPETITORBALANCE1>';

        // set APPLICATION_LP_STATUS_2 to incomplete if no bank statements
        Boolean bankStatements = false;

        for (Opportunity_Attachment__c onbaseFile : optyList.Attachments__r) {
            if (onbaseFile.Type__c != null && onbaseFile.Type__c.contains(Label.TC_BankStatementFileType) && !onbaseFile.Type__c.contains(Label.TC_MTDFileType)) bankStatements = true;
        }

        requestMsg += bankStatements ? '<APPLICATION_LP_STATUS_2>complete</APPLICATION_LP_STATUS_2>' : '<APPLICATION_LP_STATUS_2>incomplete</APPLICATION_LP_STATUS_2>';
        requestMsg += '</APPLICATIONDATA>';

        System.debug('>>>>> Case Center Request Message: ' + requestMsg);
        return requestMsg;

    }

    /**
     * @description             Gets emails from the ACR list based on the receive all loan notifications field being true on the contact
     * @see                     SAL-2604
     *
     * @param acctId            The account Id to query
     * @param existingEmails    The existing emails retrieved
     *
     * @return                  Returns a comma separated list of the emails to include
     */
    private static String getEmailsFromACRs(Id acctId, String existingEmails) {
        List<AccountContactRelation> acrs = [SELECT Id, ContactId, Contact.Email FROM AccountContactRelation WHERE AccountId = :acctId AND Contact.Receive_All_Loan_Notifications__c = true];
        Set<String> emails = new Set<String>();
        if (String.isNotBlank(existingEmails)) emails.addAll(existingEmails.toLowerCase().split(','));
        for (AccountContactRelation acr : acrs) emails.add(acr.Contact.Email?.toLowerCase());
        system.debug('acrs:'+ acrs);
        
        system.debug('emails:'+emails);
        return String.join(new List<String>(emails),';');
    }
    
    Private Static void buildCCMap(){
        
        ccMaps.Clear();
        
        for (Marlin_Case_Center_Mapping__mdt ccMap:[Select MasterLabel, CC_Value__c, Field_Name__c from Marlin_Case_Center_Mapping__mdt])
        {
            ccMaps.put(ccMap.Field_Name__c + '__' + ccMap.MasterLabel, ccMap.CC_Value__c);
        }        
        System.debug('CC Transform Map: ' + ccMaps);  
    }
    
    Private static String transCC(String fieldName, Object argVal) {
        System.debug('CC Transform call: ' + fieldName + '::' + argVal );  
        if(argVal != null) {
            system.debug('ccMaps-- '+ccMaps.Get(fieldName + '__' + String.valueof(argVal)));
            System.debug ('key:' + fieldName + '__' + String.valueof(argVal));
            return ccMaps.Get(fieldName + '__' + String.valueof(argVal));
        }
        
        return '';
    }     
    
    
    
    
    public static String getNumericOnly(String argVal) {
        
        if(argVal != null) {
            String tempString = String.valueOf(argVal);
            return tempString.replaceAll('[^0-9]', '');
            
        }
        
        return '';
    } 
    
    public static String formatDealerNumber(String argVal) {
        
        if(argVal != null) {
            argVal = argVal.replaceAll('[^0-9]', '');
            if(argVal.Length() == 10)
                return (argVal.Left(6) + '.' +  argVal.right(4));
            
        }
        
        return '';
    }       
    
    public static String getSubstring(String argVal, Integer argLength) {
        
        if(argVal != null) {
            if(argVal.Length() <= argLength)
                return argVal;
            else
                return argVal.Substring(0,argLength);
        }
        
        return '';
    }    
    
    public static String getFormattedDateString(Object argVal,String formatString) {
        if(argVal != null) {
            Date dArgVal = Date.valueof(argVal);
            DateTime dtArgVal = DateTime.newInstance(dArgVal.year(), dArgVal.month(),dArgVal.day());  
           // System.Debug('KKK:' + dArgVal.year() + ':' + dArgVal.month() + ':' + dArgVal.day());
            return String.valueOf(dtArgVal.format(formatString));
        }
        
        return '';
    }  
    
    public static String getFormattedDateTimeString(Object argVal,String formatString) {
        if(argVal != null) {
            DateTime dtArgVal = DateTime.valueOf(argVal);
            return String.valueOf(dtArgVal.format(formatString));
        }
        
        return '';
    }     

     public Static string createGuarantorMsg(List<Guarantor__c> aGurntList){
        
        
        String lGuarMessage = '';
        Integer lCounter = 0;

        for(Guarantor__c lGurnt : aGurntList)   {
                lCounter ++;
                System.debug ('?????? here status:' + lGurnt.Contact__r.Validity_Verify__Status__c);
            System.debug ('?????? here result:' + lGurnt.Contact__r.Final_E_mail_Validity_Result__c);
                lGuarMessage +=  '<PG' + String.ValueOf(lCounter) + '>'+
                    '   <FIRSTNAME>' + lGurnt.Contact__r.FirstName + '</FIRSTNAME>'+                    
                    '   <LASTNAME>' + lGurnt.Contact__r.LastName + '</LASTNAME>'+
                    '   <SUFFIX>' + lGurnt.Contact__r.Suffix + '</SUFFIX>'+
                    '   <ADDRESS>' + getSubstring(getXMLValue(lGurnt.Contact__r.OtherStreet),50) + '</ADDRESS>'+
                    '   <CITY>' + lGurnt.Contact__r.OtherCity + '</CITY>'+
                    '   <STATE>' + lGurnt.Contact__r.OtherStateCode + '</STATE>'+
                    '   <ZIPCODE>' + getSubstring(getXMLValue(lGurnt.Contact__r.OtherPostalCode),5) + '</ZIPCODE>'+
                    '   <SSN>' + lGurnt.Contact__r.SSN__c + '</SSN>'+
                  //  '   <CCAN>' + lGurnt.Contact__r.Account.CCAN__c + '</CCAN>'+
                      '   <CCAN />' + 
                    '   <EMAIL>' + lGurnt.Contact__r.Email + '</EMAIL>'+
                    '   <BIRTHDATE>' + getFormattedDateString(lGurnt.Contact__r.Birthdate,'MM/dd/YYYY') + '</BIRTHDATE>'+
                    /*'   <PHONE>' + getNumericOnly(lGurnt.Contact__r.HomePhone) + '</PHONE>'+*/
                    // change to  phone
                    '   <PHONE>' + getNumericOnly(lGurnt.Contact__r.Phone) + '</PHONE>'+
                    '   <OWNERSHIPPERCENTAGE>' + lGurnt.Contact__r.Ownership_Pct__c + '</OWNERSHIPPERCENTAGE>'+ 
                    '   <DLSTATE>' + lGurnt.Contact__r.DL_State__c + '</DLSTATE>'+ 
                    '   <DLNUMBER>' + lGurnt.Contact__r.DL_Number__c + '</DLNUMBER>'+ 
                    '   <TITLE>' + lGurnt.Contact__r.Title + '</TITLE>'+ 
                    '   <PG'+ String.ValueOf(lCounter) + '_VALIDITYVERIFY_RESULT>' + lGurnt.Contact__r.Validity_Verify__Status__c  + '</PG' + String.ValueOf(lCounter) + '_VALIDITYVERIFY_RESULT>'+ 
                    '   <PG'+ String.ValueOf(lCounter) + '_FINALEMAILVALIDITY>' + lGurnt.Contact__r.Final_E_mail_Validity_Result__c  + '</PG' + String.ValueOf(lCounter) + '_FINALEMAILVALIDITY>'+ 
                    '</PG' + String.ValueOf(lCounter) + '>';             

        }                       
        
        return lGuarMessage;
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
    
    Public Static String createUpdateAppMessage(String aAppNumber, Map<String,Map<String,String>> aDocIdToDocDetailsMap){

   
        String lAttachmentMessage = '';
        
        for(String key : aDocIdToDocDetailsMap.keyset()){
            
        lAttachmentMessage += '<RESPONSEDATA_DOCUMENTS_Document>' +
                        '<RESPONSEDATA_DOCUMENTS_Description>' + aDocIdToDocDetailsMap.Get(key).Get('DocType') + '</RESPONSEDATA_DOCUMENTS_Description>' +
                        '<RESPONSEDATA_DOCUMENTS_URL>' + aDocIdToDocDetailsMap.Get(key).Get('DOC_URL') + '</RESPONSEDATA_DOCUMENTS_URL>' +
                        '</RESPONSEDATA_DOCUMENTS_Document>';
                        
            
        }
   
        String lReqMsg = ' <?xml version="1.0" encoding="UTF-8"?>' + 
                        '<APPLICATIONDATA>' +
                        '<INFOLEASENUMBER>' + aAppNumber + '</INFOLEASENUMBER>' +
                         lAttachmentMessage +       
                        '<CCUpdate>Y</CCUpdate>' +
            //'<APPLICATION_LP_STATUS_2>complete</APPLICATION_LP_STATUS_2>' +
                        '</APPLICATIONDATA>';
 
    /*    lReqMsg = ' <?xml version="1.0" encoding="UTF-8"?>' + 
                        '<APPLICATIONDATA>' +
                        '<INFOLEASENUMBER>L004372</INFOLEASENUMBER>' +
                         '<RESPONSEDATA_DOCUMENTS_Document>' + 
                        '<RESPONSEDATA_DOCUMENTS_Description>FS - Bank Statements</RESPONSEDATA_DOCUMENTS_Description>' + 
                        '<RESPONSEDATA_DOCUMENTS_URL>http://testonbase2.marlinfinance.com/Appnet_16/docpop/docpop.aspx?docid=1766688&clienttype=html&chksum=bd9c6452413a84b44d3ed3b2c925cb59710cde173a8dacb5ed746dbaf5b0bd91</RESPONSEDATA_DOCUMENTS_URL>' +
                        '</RESPONSEDATA_DOCUMENTS_Document>' +       
                        '<CCUpdate>Y</CCUpdate>' +
                        '</APPLICATIONDATA>';    */    
        
        lReqMsg = '<?xml version="1.0" encoding="UTF-8"?><APPLICATIONDATA><INFOLEASENUMBER>' + aAppNumber + '</INFOLEASENUMBER>' + lAttachmentMessage + '<CCUpdate>Y</CCUpdate>';
        
        // checking if there is a bank statement
        List <Opportunity> opps = new List <Opportunity> ([SELECT Id, (SELECT Id, Type__c FROM Attachments__r) FROM Opportunity WHERE CaseCenter__c = :aAppNumber]);
        if (!opps.isEmpty ()) {
            Boolean bankStatements = false;
        
            for (Opportunity_Attachment__c onbaseFile : opps[0].Attachments__r) {
                if (onbaseFile.Type__c != null && onbaseFile.Type__c.contains(Label.TC_BankStatementFileType) && !onbaseFile.Type__c.contains(Label.TC_MTDFileType)) bankStatements = true;
            }
            //if (bankStatements) lReqMsg +='<APPLICATION_LP_STATUS_2>complete</APPLICATION_LP_STATUS_2>';

            //Changed the below for SAL-1607
            lReqMsg += bankStatements ? '<APPLICATION_LP_STATUS_2>complete</APPLICATION_LP_STATUS_2>' : '';
            //lReqMsg += bankStatements ? '<APPLICATION_LP_STATUS_2>complete</APPLICATION_LP_STATUS_2>' : '<APPLICATION_LP_STATUS_2>incomplete</APPLICATION_LP_STATUS_2>';
        }
        
        lReqMsg += '</APPLICATIONDATA>';  
        return lReqMsg;
    }

    public static String createUpdateApplicationStatusMessage(String aAppNumber){

        String lReqMsg = '<?xml version="1.0" encoding="UTF-8"?>' +
                '<APPLICATIONDATA>' +
                '<INFOLEASENUMBER>' + aAppNumber + '</INFOLEASENUMBER>' +
                '<CCUpdate>Y</CCUpdate>' +
                '<APPLICATION_STATUS>funded</APPLICATION_STATUS>' +
                //Added LP Status for SAL-1607
                '<APPLICATION_LP_STATUS_2>complete</APPLICATION_LP_STATUS_2>' +
                '</APPLICATIONDATA>';

        return lReqMsg;
    }

    public static String createUpdatePKNumberMessage(String aAppNumber, String PKNumber){

        String lReqMsg = '<?xml version="1.0" encoding="UTF-8"?>' +
                '<APPLICATIONDATA>' +
                '<INFOLEASENUMBER>' + aAppNumber + '</INFOLEASENUMBER>' +
                '<CCUpdate>Y</CCUpdate>' +
                '<PKNumber>' + PKNumber + '</PKNumber>' +
                '</APPLICATIONDATA>';

        return lReqMsg;
    }

}