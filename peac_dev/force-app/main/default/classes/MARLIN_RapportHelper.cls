// Andrew M note:
// Rapport was decommissioned Feb 14 2020
// Look into refactoring this code


public class MARLIN_RapportHelper {
    
    /****************************************************************************************
* @Author       Huron Team
* @Date         March 30, 2017
* @Description  Rapport Helper Function
*****************************************************************************************/  
    Private Static Map<String,String> rapportMaps = new Map<String,String>();
    Private Static List<Contact> lConList = new List<Contact>();
    Private Static List<Dealer__c> lDealerList = new List<Dealer__c >();
    private static List<Dealer__c> mDealerListForOther = new List<Dealer__c >();
    Private Static List<Contact> lDealerConList = new List<Contact>();
    Private Static List<Franchisor__c> lFranchisorList = new List<Franchisor__c >();
    private static List<Broker__c> lBrokerList = new List<Broker__c >();
    Private Static Boolean mIsFranchise = False;
    private static Boolean mIsIFP = False; 
    
    public Static string getXMLValue(Object fieldValue) {
        if(fieldValue == null)
            return '';
        else{
            fieldValue = String.ValueOf(fieldValue).replaceAll('>','&gt;'); 
            fieldValue = String.ValueOf(fieldValue).replaceAll('<','&lt;');            
            return String.ValueOf(fieldValue);
        }           
    }   
    
    public Static string getContactData(List<Contact> aConList, String aFieldName) {
        if(aConList.Size() == 0)
            return '';
        
        if(aConList[0].Get(aFieldName) == null)
            return '';
        else
            return String.ValueOf(aConList[0].Get(aFieldName));
    }   
    
    public Static string getDealerData(String fieldName) {
        
        
        if(mIsFranchise == true){
            if(lFranchisorList.Size() == 0)
                return '';       
            
            if(lFranchisorList[0].getSobject('Franchisor__r').Get(fieldName) == null)
                return '';
            else
                return String.ValueOf(lFranchisorList[0].getSobject('Franchisor__r').Get(fieldName));
            
        }
        else if(mIsIFP == true){
            if(lBrokerList.Size() == 0)
                return '';       
            
            if(lBrokerList[0].getSobject('Account__r').Get(fieldName) == null)
                return '';
            else
                return String.ValueOf(lBrokerList[0].getSobject('Account__r').Get(fieldName));
            
        }
        else{
            
            if(lDealerList.Size() == 0)
                return '';  
            
            if(lDealerList[0].getSobject('Dealer__r').Get(fieldName) == null)
                return '';
            else
                return String.ValueOf(lDealerList[0].getSobject('Dealer__r').Get(fieldName));                   
            
        }
        return '';
    } 
    
    public Static string getValueFromTag(XMLStreamReader reader) {
        String DataValue;
        try{
            
            while (reader.hasNext()) {
                
                if (reader.getEventType() == XmlTag.END_ELEMENT) {
                    break;
                }
                else if (reader.getEventType() == XmlTag.CHARACTERS) {
                    DataValue = reader.getText();
                }
                reader.next();
            }
        }
        catch(Exception e){
            
            DataValue = 'XML Parsing Error. Check Logs.:' + e.getMessage();
            
        }          
        
        return DataValue;
    }
    
    // Nirosha Changes
    
    public static String validateDealer(String OpptyId){
        system.debug('OpptyId--- '+OpptyId);
        
        String lDealerNumber = '' ;
        String lDealerPhone = '' ;
        Integer lDealerCount = 0 ;
        String lDealerID = '';
        
        Integer lFranchisorCount = 0;
        String lFranchisorPhone = '';
        String lFranchisorNumber = '';
        String lFranchisorID = '';
        
        Integer lBrokerCount = 0;
        String lBrokerPhone = '';
        String lBrokerNumber = '';
        String lBrokerID = '';
        
        String lMultipleIDs = '';
        String DealerExists = 'Dealer already exists. Record ID : ';
        
        Map<String,Account> ldealerWithoutNumber = new Map<String,Account>();
        String finalResult = '';
        List<String> phoneWithFormat = new List<String>();
        Opportunity oppty = [SELECT Id,RecordType.Name,RecordType.DeveloperName,Payment_Frequency__c,Rapport_Time_Out__c,
                             Account.Name, Account.DBA__c,Account.Business_Type__c,Business_Phone__c,
                             Account.Line_of_Business__c,Account.Business_Address__c,Account.Business_City__c,Account.RecordType.DeveloperName,
                             Account.Business_State__c,Account.Business_Zip__c,Account.Business_Phone__c,Primary_Source__c,
                             Application__c,Account.BILLINGSTREET,Account.BILLINGCity,Account.BillingStateCode,
                             Account.BillingPostalCode, Account.Tax_ID__c, Account.Primary_Contact__r.Phone,
                             (SELECT Id,Primary_Dealer__c,name,Dealer__c,Dealer__r.Name, Dealer__r.Business_Address__c, 
                              Dealer__r.Business_City__c, Dealer__r.Business_State__c,Dealer__r.Dealer_Number__c, 
                              Dealer__r.Business_Zip__c, Dealer__r.Business_Phone__c, Dealer__r.Account_Branch__c 
                              FROM Brokers__r),
                             (SELECT id,name,Franchisor__c,Franchisor__r.Name, Franchisor__r.Business_Address__c, 
                              Franchisor__r.Business_City__c, Franchisor__r.Business_State__c,Franchisor__r.Dealer_Number__c, 
                              Franchisor__r.Business_Zip__c, Franchisor__r.Business_Phone__c, Franchisor__r.Account_Branch__c 
                              FROM Franchisors__r),
                             (SELECT id,Account__c,Account__r.Name, Account__r.Business_Address__c, 
                              Account__r.Business_City__c, Account__r.Business_State__c,Account__r.Dealer_Number__c, 
                              Account__r.Business_Zip__c, Account__r.Business_Phone__c, Account__r.Account_Branch__c 
                              FROM Brokers1__r) FROM Opportunity WHERE Id =: OpptyId ];
        
        system.debug('oppty --- '+oppty);
        
        lDealerCount = oppty.Brokers__r.size();
        lFranchisorCount = oppty.Franchisors__r.size();
        lBrokerCount = oppty.Brokers1__r.size();
        system.debug('lDealerCount-- '+lDealerCount + ' lFranchisorCount-- '+lFranchisorCount + ' lBrokerCount-- '+ lBrokerCount);
        
        if(oppty.Brokers__r.size() > 0){
            ldealerWithoutNumber.clear();
            for(Dealer__c dealerData : oppty.Brokers__r){
                if(dealerData.Dealer__r.Dealer_Number__c == null){
                    String lDNumber = 
                        dealerData.Dealer__r.Business_Phone__c.substring(0, 6) +
                        '.' + 
                        dealerData.Dealer__r.Business_Phone__c.substring(6, dealerData.Dealer__r.Business_Phone__c.length()); 
                    phoneWithFormat.add(lDNumber);
                        
                    ldealerWithoutNumber.put(dealerData.Dealer__r.Business_Phone__c,dealerData.Dealer__r);
                }
            }
        }
        if(ldealerWithoutNumber.size() > 0){
            String finalRes = checkDuplicateDealer(ldealerWithoutNumber,phoneWithFormat, 'Dealer');
            System.debug('finalRes--->'+finalRes);
            if(finalRes != '')
                finalResult = finalResult + finalRes;
            System.debug('finalResult--->'+finalResult);
        }
            
        
        if(oppty.RecordType.DeveloperName.contains('Franchise')){
            System.debug('Inside Franchisor');
            ldealerWithoutNumber.clear();
            phoneWithFormat.clear();
            if(oppty.Franchisors__r.size() > 0){
            for(Franchisor__c franchisorData : oppty.Franchisors__r){
                System.debug('franchisor dealer number--->'+franchisorData.Franchisor__r.Dealer_Number__c);
                if(franchisorData.Franchisor__r.Dealer_Number__c == null){
                     String lDNumber = 
                        franchisorData.Franchisor__r.Business_Phone__c.substring(0, 6) +
                        '.' + 
                        franchisorData.Franchisor__r.Business_Phone__c.substring(6, franchisorData.Franchisor__r.Business_Phone__c.length()); 
                    System.debug('lDNumber-->'+lDNumber);
                    phoneWithFormat.add(lDNumber);
                    System.debug('franchisorData.Franchisor__r phone'+ franchisorData.Franchisor__r.Business_Phone__c);
                    ldealerWithoutNumber.put(franchisorData.Franchisor__r.Business_Phone__c, franchisorData.Franchisor__r);
                }
            }
        }
            if(ldealerWithoutNumber.size() > 0){
            String finalRes = checkDuplicateDealer(ldealerWithoutNumber, phoneWithFormat, 'Franchisor');
            if(finalRes != '')
                finalResult = finalResult + finalRes;
                
             System.debug('finalResult--->'+finalResult);
        }
        }
        
        
        if(oppty.RecordType.DeveloperName.contains('IFP')){
            ldealerWithoutNumber.clear();
            phoneWithFormat.clear();
            if(oppty.Brokers1__r.size() > 0){
            for(Broker__c brokerData : oppty.Brokers1__r){
                if(brokerData.Account__r.Dealer_Number__c == null){
                    String lDNumber = 
                        brokerData.Account__r.Business_Phone__c.substring(0, 6) +
                        '.' + 
                        brokerData.Account__r.Business_Phone__c.substring(6, brokerData.Account__r.Business_Phone__c.length()); 
                    phoneWithFormat.add(lDNumber);
                    
                    ldealerWithoutNumber.put(brokerData.Account__r.Business_Phone__c, brokerData.Account__r);
                }
                
            }
        }
            if(ldealerWithoutNumber.size() > 0){
            String finalRes = checkDuplicateDealer(ldealerWithoutNumber, phoneWithFormat, 'Broker');
            if(finalRes != '')
                finalResult = finalResult + finalRes;
                
             System.debug('finalResult--->'+finalResult);
        }
        }    
        if(finalResult == '')
            return 'SUCCESS';
          
        else{
            System.debug('finalResult--->'+finalResult);
            return 'Duplicate Account : '+ finalResult;
        }
            
        
        
        
    } 
    public Static String checkDuplicateDealer(Map<String,Account> AccountID, List<String> dealerNum, String recordType){
        String lErrorAccountName = '' ;
        System.debug('dealer number list--->'+ dealerNum);
        System.debug('Account id map--->'+AccountID);
        LIST<Account> checkDupAccount = new LIST<Account>();
        List<Account> accQuery = [SELECT Id, RecordType.DeveloperName, RecordType.Name, RecordTypeID, 
                                Dealer_Number__c, Business_Phone__c, name FROM Account 
                                  WHERE Dealer_Number__c IN :dealerNum OR Dealer_Number__c IN : AccountID.keyset()];
        if(accQuery.size() > 0){
            System.debug('Duplicate Dealer number');
            for(Account acc : accQuery){    
                System.debug('acc.RecordType.Name---->'+acc.RecordType.Name);
                System.debug('recordType----->'+recordType);
                System.debug('acc.RecordType.Name.contains(recordType)---->'+acc.RecordType.Name.contains(recordType));
                if(acc.RecordType.Name.contains(recordType)){
                    lErrorAccountName = AccountID.get(acc.Business_Phone__c).name + ',' + lErrorAccountName ;
                    System.debug('lErrorAccountName--->'+lErrorAccountName);
                }
            }
        }
        
        if(lErrorAccountName != '')
                return lErrorAccountName;
             
        else
            return '';
    }
        
    
    
    public Static String validateRequiredFields(String opptyId) {
        
        String lInvalidFieldList = '';
        String lDealerNumber = '';
        String lDealerBusName = '';
        String lDealerAddress = '';
        String lDealerCity = '';
        String lDealerState = '';
        String lDealerZip = '';
        String lDealerPhone = '';   
        Integer lDealerCount = 0;
        Integer lAssetCount = 0;
        Integer lFanchiseCount = 0;
        String lContactPhone = '';
        String lDealerBranch = '';
        Boolean lIsFranchise = False;
        
        
        Opportunity opty = [select id,RecordType.Name,Payment_Frequency__c,Rapport_Time_Out__c,
                            Account.Name, Account.DBA__c,Account.Business_Type__c,Business_Phone__c,
                            Account.Line_of_Business__c,Account.Business_Address__c,Account.Business_City__c,
                            Account.Business_State__c,Account.Business_Zip__c,Account.Business_Phone__c,Primary_Source__c,
                            Application__c,Account.BILLINGSTREET,Account.BILLINGCity,Account.BillingStateCode,
                            Account.BillingPostalCode, Account.Tax_ID__c, Account.Primary_Contact__r.Phone, Branch__c,
                            (Select contact.Phone,contact.LastName 
                             From OpportunityContactRoles where IsPrimary = true),
                            (SELECT Name,Cost__c,Description__c,
                             Equipment_City__c, Equipment_Code__c,Equipment_State__c,
                             Equipment_Street__c, Equipment_Zip__c,Quantity__c,Vehicle_Make__c,
                             Vehicle_year__c, Vehicle_Type__c, Mileage__c, New_Used__c, Sleeper_Day_Cab__c, 
                             RecordType.DeveloperName,Opportunity__r.RecordType.Name FROM Assets__r),
                            (SELECT id,Primary_Dealer__c,name,Dealer__c,Dealer__r.Name, Dealer__r.Business_Address__c, 
                             Dealer__r.Business_City__c, Dealer__r.Business_State__c,Dealer__r.Dealer_Number__c, 
                             Dealer__r.Business_Zip__c, Dealer__r.Business_Phone__c, Dealer__r.Account_Branch__c, Dealer__r.PG_Required__c  
                             FROM Brokers__r),
                            (SELECT id,Account__c,Account__r.Name, Account__r.Business_Address__c, 
                             Account__r.Business_City__c, Account__r.Business_State__c,Account__r.Dealer_Number__c, 
                             Account__r.Business_Zip__c, Account__r.Business_Phone__c, Account__r.Account_Branch__c, Account__r.PG_Required__c  
                             FROM Brokers1__r),                                
                            (SELECT id,name,Franchisor__c,Franchisor__r.Name, Franchisor__r.Business_Address__c, 
                             Franchisor__r.Business_City__c, Franchisor__r.Business_State__c,Franchisor__r.Dealer_Number__c, 
                             Franchisor__r.Business_Zip__c, Franchisor__r.Business_Phone__c, Franchisor__r.Account_Branch__c, Franchisor__r.PG_Required__c  
                             FROM Franchisors__r),                                 
                            (Select Id, Type__c,
                             Contact__r.FirstName, Contact__r.LastName, 
                             Contact__r.SSN__c,Contact__r.Phone, Contact__r.MailingStreet, 
                             Contact__r.MailingCity,Contact__r.MailingStateCode, Contact__r.MailingPostalCode,
                             Account__r.Name, Account__r.Id, Account__r.CCAN__c, 
                             Account__r.Business_Address__c, Account__r.Business_City__c, Account__r.Business_State__c,
                             Account__r.Business_Zip__c, Account__r.Business_Phone__c, RecordType.Name
                             from Guarantor__r)  
                            from Opportunity where Id =:OpptyId ];
        
        if(!String.IsBlank(opty.Application__c))
            return 'Fail [This application is already submitted and applicaiton number is generated]';
        
        if(opty.Rapport_Time_Out__c == true)
            return 'Fail [A Timeout has been reported for this Application, Please check with Support Team]';

        if (opty.Branch__c == null || opty.Branch__c == '') return 'Branch is a required value on the Opportunity in order to send to Rapport';
        
        if(opty.RecordType.Name.Contains('Franchise'))
            lIsFranchise = True;
        if(opty.RecordType.Name.Contains('IFP'))
            mIsIFP = True;
        
        if(opty.OpportunityContactRoles.Size() > 0)
            lContactPhone = String.ValueOf(opty.OpportunityContactRoles[0].getSobject('Contact').get('Phone'));
        
        lDealerCount = opty.Brokers__r.size();
        if(lDealerCount > 0){
            lInvalidFieldList += validateDealerFields(opty.Brokers__r);
        }
         
        
                
        
        lAssetCount = opty.Assets__r.Size();                              
        
        if (String.isBlank(opty.Account.Business_Type__c))
            lInvalidFieldList += 'Account Business Type, '; 
        
        if (String.isBlank(opty.Account.Name))
            lInvalidFieldList += 'Account Name, ';  
        
        if (String.isBlank(opty.Account.Business_Address__c))
            lInvalidFieldList += 'Account Business Address, ';  
        
        if (String.isBlank(opty.Account.Business_City__c))
            lInvalidFieldList += 'Account Business City, ';                                             
        
        if (String.isBlank(opty.Account.Business_State__c))
            lInvalidFieldList += 'Account Business State, ';    
        
        if (String.isBlank(opty.Account.Business_Zip__c))
            lInvalidFieldList += 'Account Business Zip, ';  
        
        /*    if(opty.OpportunityContactRoles.Size() == 0)
lInvalidFieldList += 'Primary Contact, ';   */
        
        if (String.isBlank(opty.Business_Phone__c))
            lInvalidFieldList += 'Business Phone, ';    
        
        if(lIsFranchise == True)
            lInvalidFieldList += validateFranchisor(opty.Franchisors__r);
     
        
        
        if(lAssetCount == 0)
            lInvalidFieldList += 'Asset Detail, ';  
        
        if(lAssetCount > 0)
            lInvalidFieldList += validateAssets(opty.Assets__r);                                                    
        
        // Personal Guarantor validation
        if(lIsFranchise != True)
            lInvalidFieldList += validateGuarantors(opty.Guarantor__r);     
        
        if(opty.RecordType.Name.Contains('IFP')){
            lInvalidFieldList += validateBrokers(opty.Brokers1__r);
            System.debug('record type IFP ---->'+opty.RecordType.Name );
        }
        
        
        // Tamarack
        // PG is required when sending deal to rapport if pg required = true on Dealer/Broker/Franchisor Account
        // This Rule is not applicable for Loan and DLG Opportunities ( Opportunity Record Type contains “DLG”)
        // 
        Boolean pgMissing = false;
        
        List <Guarantor__c> pgs = new List <Guarantor__c> ();
        for (Guarantor__c g : opty.Guarantor__r) {
            if (g.RecordType.Name == 'Personal') {
                pgs.add (g);
            }
        }
        
        if (pgs.isEmpty() && !opty.RecordType.Name.toLowerCase ().contains ('loan') && !opty.RecordType.Name.toLowerCase ().contains ('dlg')) {
            
            for (Franchisor__c fran : opty.Franchisors__r) {
                if (fran.Franchisor__r.PG_Required__c) pgMissing = true;
            }
            
            for (Broker__c broker : opty.Brokers1__r) {
                if (broker.Account__r.PG_Required__c) pgMissing = true;
            }
            
            for (Dealer__c dealer : opty.Brokers__r) {
                if (dealer.Dealer__r.PG_Required__c) pgMissing = true;
            }
        }
        String failureMessage = 'Fail [Missing Fields:' + lInvalidFieldList + ']'; 
        if (pgMissing) failureMessage += Label.TC_Rapport_PGs_Required;
        
            
        
        
        if(String.IsBlank(lInvalidFieldList) && !pgMissing)
            return 'Success';
        else
            return failureMessage;
        
        
    }
    
    
    public Static String createUpdateMsgTemplate(String aAppNumber, String aDeltaMsg) {
        String UserName = System.Label.RapportUser;
        String Password = System.Label.RapportPassword;
        String Alias = System.Label.Rapport_Alias; 
        String reqMessage = '';
        
        
        reqMessage = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:RapportDataImportIntf-IRapportDataImport" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
            '   <soapenv:Header />'+
            '   <soapenv:Body>'+
            '      <urn:UpdateApplication soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'+
            '         <aApplicationXml xsi:type="xsd:string">'+
            '            <RapportDataImport>'+
            '               <Alias>' + Alias + '</Alias>'+
            '               <User>'+
            '                  <WorklistUser>' + UserName + '</WorklistUser>'+
            '                  <Password>' + Password + '</Password>'+
            '               </User>'+
            '               <AppData>'+
            '                  <ApplicationKey>'+ aAppNumber +'</ApplicationKey>'+
            '               <Application>' +
            '               <CO>'+ 
            '               ' + aDeltaMsg + // included delta xml
            '               </CO>' +
            '               </Application>' +
            '               </AppData>' +
            '           </RapportDataImport>'+
            '         </aApplicationXml>'+
            '      </urn:UpdateApplication>'+
            '   </soapenv:Body>'+
            '</soapenv:Envelope>';
        
        
        system.debug('Request Message is:' +reqMessage);
        return reqMessage; 
    }

    public Static String createUpdateApplicationMsg(String aOpptyId,String aFieldList, String aObjectName) {
        String UserName = System.Label.RapportUser;
        String Password = System.Label.RapportPassword;
        String Alias = System.Label.Rapport_Alias; 
        String lFieldName = '';
        System.Debug('Updated Field List:' + aFieldList);
        List<String> lXMLSequance = new List<String>{'CONTRACT.TERM', 'AM.PURCHASE.OPTION', 'UD_EQUIP.DESC', 
            'UD_DLR_ENTERED_COMMENT', 'UD_PYMT_FREQUENCY', 
            'EQUIPMENT.COST', 'CONTRACT.PYMT', 
            'SEC.DEPOSIT', 'UD_NUM_OF_PYMTS'};
                
                Map<String,String> lXMLNameToFieldNameMap = new Map<String,String>{
                    'CONTRACT.TERM'=>'terms__c','UD_EQUIP.DESC'=>'equipment_description__c',
                        'UD_DLR_ENTERED_COMMENT'=>'sales_comments__c','EQUIPMENT.COST'=>'equipment_cost__c',
                        'CONTRACT.PYMT'=>'payment_amount__c','SEC.DEPOSIT'=>'sec_dep_pymts__c',
                        'UD_NUM_OF_PYMTS'=>'of_payments__c'};                       
                            
                            Map<String,String> lTXMLNameToFieldNameMap = new Map<String,String>{
                                'AM.PURCHASE.OPTION'=>'purchase_options__c','UD_PYMT_FREQUENCY'=>'payment_frequency__c'
                                    };      
                                        
                                        Map<String,String> lTFieldNameToTransformNameMap = new Map<String,String>{
                                            'purchase_options__c'=>'PUR.OPTION','payment_frequency__c'=>'UD_PAYMENT_FREQUENCY'
                                                };                                                      
                                                    buildRapportMap();
        
        Opportunity lOppty = [SELECT  id,application__c,purchase_options__c,ud_timereceived__c,primary_contact_email__c,
                              primary_contact_fax__c,primary_contact_name__c,primary_contact_phone__c,
                              equipment_description__c,   sales_comments__c,ud_dealer_status__c,
                              ud_decision_ineligible__c,payment_amount__c,approved_amount__c, 
                              sales_rep__c,equipment_cost__c,branch__c,terms__c,sec_dep_pymts__c,
                              of_payments__c,ud_datereceived__c,ud_dlr_entered_app__c,
                              payment_frequency__c FROM OPPORTUNITY WHERE ID =: aOpptyId];       
        
        String objname = 'Opportunity';
        
        String xmlmessage = '';
        String reqMessage = '';
        
        String lOpptyXMLMsg = '';
        Set<String> lFieldList = new Set<String>();
        lFieldList.AddAll(aFieldList.Split(','));
        System.Debug('Updated Field List:' + lFieldList);
        lFieldList.remove(null);
        
        for(String lXMLTagdName : lXMLSequance){
            lFieldName = lXMLNameToFieldNameMap.get(lXMLTagdName);
            
            if(lFieldList.contains(lFieldName)){
                lOpptyXMLMsg = lOpptyXMLMsg + '<' + lXMLTagdName +
                    '>' + getXMLValue(lOppty.Get(lFieldName)) + '</' + lXMLTagdName + '>';
                System.Debug('Oppty XML Message:' + lOpptyXMLMsg);          
            }   
            
            lFieldName = lTXMLNameToFieldNameMap.get(lXMLTagdName);
            
            if(lFieldList.contains(lFieldName)){
                lOpptyXMLMsg = lOpptyXMLMsg + '<' + lXMLTagdName +
                    '>' + transRapport(lTFieldNameToTransformNameMap.get(lFieldName),lOppty.Get(lFieldName)) + '</' + lXMLTagdName + '>';
                System.Debug('Oppty XML Message:' + lOpptyXMLMsg);          
            }                       
            
        }
        
        if(String.IsBlank(lOpptyXMLMsg))
            return '';
        
        reqMessage = createUpdateMsgTemplate(getXMLValue(lOppty.application__c), lOpptyXMLMsg);
        
        system.debug('Request Message is:' +reqMessage);
        return reqMessage; 
    }
    
    
    public Static String createUpdateApplicationAssetMsg(String aAssetId,String aFieldList) {
        
        String lFieldName = '';
        System.Debug('Updated Field List:' + aFieldList);
        List<String> lXMLSequance = new List<String>{'EQUIP.COST', 'EQUIP.DESC', 'EQUIP.CODE', 
            'QUANTITY', 'EQUIP.ADDR1', 'EQUIP.CITY', 'EQUIP.STATE', 
            'EQUIP.ZIP', 'MODEL'};

                Map<String,String> lXMLNameToFieldNameMap = new Map<String,String>{
                    'EQUIP.COST'=>'cost__c','EQUIP.DESC'=>'description__c','EQUIP.CODE'=>'Equipment_Code__c',
                        'QUANTITY'=>'quantity__c','EQUIP.ADDR1'=>'equipment_street__c','EQUIP.CITY'=>'equipment_city__c',
                        'EQUIP.STATE'=>'equipment_state__c','EQUIP.ZIP'=>'equipment_zip__c','MODEL'=>'model__c'};                           
                            
                            Map<String,String> lTXMLNameToFieldNameMap = new Map<String,String>{
                                'EQUIP.CODE'=>'equipment_code__c'
                                    };      
                                        
                                        Map<String,String> lTFieldNameToTransformNameMap = new Map<String,String>{
                                            'equipment_code__c'=>'Equipment_Code'
                                                };                                                      
                                                    buildRapportMap();
        
        Asset__c lAsset = [SELECT  id,Cost__c,Description__c,Equipment_Code__c,Opportunity__r.Application__c,
                           Quantity__c,Equipment_Street__c,Equipment_City__c,Equipment_State__c,Equipment_Zip__c,
                           Model__c, Mileage__c, New_Used__c, Sleeper_Day_Cab__c, Vehicle_Make__c, Vehicle_Type__c, Vehicle_year__c, Opportunity__c FROM Asset__c WHERE ID =: aAssetId];       
        
        String reqMessage = '';
        
        String lAssetXMLMsg = '';
        Set<String> lFieldList = new Set<String>();
        lFieldList.AddAll(aFieldList.Split(','));
        System.Debug('Updated Field List:' + lFieldList);
        lFieldList.remove(null);
        
        for(String lXMLTagdName : lXMLSequance){
            lFieldName = lXMLNameToFieldNameMap.get(lXMLTagdName);
            System.Debug(lXMLTagdName + ':' + lFieldName);
            if(lFieldList.contains(lFieldName)){
                lAssetXMLMsg = lAssetXMLMsg + '<' + lXMLTagdName +
                    '>' + getXMLValue(lAsset.Get(lFieldName)) + '</' + lXMLTagdName + '>';
                System.Debug('Asset XML Message:' + lAssetXMLMsg);          
            }   
            
            lFieldName = lTXMLNameToFieldNameMap.get(lXMLTagdName);
            
            if(lFieldList.contains(lFieldName)){
                lAssetXMLMsg = lAssetXMLMsg + '<' + lXMLTagdName +
                    '>' + transRapport(lTFieldNameToTransformNameMap.get(lFieldName),lAsset.Get(lFieldName)) + '</' + lXMLTagdName + '>';
                System.Debug('Oppty XML Message:' + lAssetXMLMsg);          
            }                       
            
        }
        
        if(String.IsBlank(lAssetXMLMsg))
            return '';
        
        lAssetXMLMsg = '<AS>' + lAssetXMLMsg +  '</AS>';
        reqMessage = createUpdateMsgTemplate(getXMLValue(lAsset.Opportunity__r.Application__c), lAssetXMLMsg);
        
        system.debug('Asset Update Request Message is:' +reqMessage);
        return reqMessage; 
    }
    
    public Static String createUpdateApplicationDocumentMsg(String aAppNumber,String aFileName,String aFileDesc, String aDocURL,Integer aSeqNum) {
        String UserName = System.Label.RapportUser;
        String Password = System.Label.RapportPassword;
        String Alias = System.Label.Rapport_Alias; 
        String reqMessage = '';
        //    String lDocMessage = '<' + aXMLName + '>' + aXMLValue + '</' + aXMLName + '>';   
        
        reqMessage = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:RapportDataImportIntf-IRapportDataImport" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
            '   <soapenv:Header />'+
            '   <soapenv:Body>'+
            '      <urn:UpdateApplication soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'+
            '         <aApplicationXml xsi:type="xsd:string">'+
            '            <RapportDataImport>'+
            '               <Alias>' + Alias + '</Alias>'+
            '               <User>'+
            '                  <WorklistUser>' + UserName + '</WorklistUser>'+
            '                  <Password>' + Password + '</Password>'+
            '               </User>'+
            '               <AppData>'+
            '                  <ApplicationKey>'+ aAppNumber +'</ApplicationKey>'+
            '               <Application>' +
            '               <CO>'+ 
            '                  <UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '>'+ aDocURL +'</UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '>'+
            '                  <UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '_FILENAME>'+ aFileName +'</UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '_FILENAME>'+
            '                  <UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '_DESC>'+ aFileDesc +'</UD_DOC_UPLOAD_' + String.ValueOf(aSeqNum) + '_DESC>'+
            '               </CO>' +
            '               </Application>' +
            '               </AppData>' +
            '           </RapportDataImport>'+
            '         </aApplicationXml>'+
            '      </urn:UpdateApplication>'+
            '   </soapenv:Body>'+
            '</soapenv:Envelope>';
        
        
        system.debug('Request Message is:' +reqMessage);
        return reqMessage; 
    }  
    
    
    
    public Static String validateFranchisor(List<Franchisor__c> aFranchiseList){
        
        String lInvalidFieldList = '';
        
        Integer lFanchiseCount = aFranchiseList.size(); 
        if(lFanchiseCount == 0)
            return 'Franchisor Missing, ';
        
        
        for(Franchisor__c lFranchise : aFranchiseList){
            
            if(String.IsBlank(lFranchise.Franchisor__r.Name))
                lInvalidFieldList += 'Franchisor Name, ';
            
            if(String.IsBlank(lFranchise.Franchisor__r.Business_Address__c))
                lInvalidFieldList += 'Franchisor Address, ';                    
            
            if(String.IsBlank(lFranchise.Franchisor__r.Business_City__c))
                lInvalidFieldList += 'Franchisor City, ';
            
            if(String.IsBlank(lFranchise.Franchisor__r.Business_State__c))
                lInvalidFieldList += 'Franchisor State, ';
            
            if(String.IsBlank(lFranchise.Franchisor__r.Business_Zip__c))
                lInvalidFieldList += 'Franchisor Zip Code, ';
            
            if(String.IsBlank(lFranchise.Franchisor__r.Business_Phone__c))
                lInvalidFieldList += 'Franchisor Business Phone, ';                 
            
            /* if(String.IsBlank(lFranchise.Franchisor__r.Dealer_Number__c))
lInvalidFieldList += 'Franchisor Number, ';*/
            
            //if(String.IsBlank(lFranchise.Franchisor__r.Account_Branch__c))
            //  lInvalidFieldList += 'Franchisor Branch, ';                 
            
        }     
        
        return lInvalidFieldList;     
        
    }
    
    public Static String validateGuarantors(List<Guarantor__c> aGurntList){
        
        String lInvalidFieldList = '';
        
        for(Guarantor__c lGurnt : aGurntList){
            
            if(lGurnt.Type__c == 'Personal Guarantor'){
                
                if(String.IsBlank(lGurnt.Contact__r.SSN__c))
                    lInvalidFieldList += 'Personal Guarantor SSN, ';
                
                if(String.IsBlank(lGurnt.Contact__r.MailingCity))
                    lInvalidFieldList += 'Personal Guarantor City, ';                   
                
                if(String.IsBlank(lGurnt.Contact__r.MailingStateCode))
                    lInvalidFieldList += 'Personal Guarantor State, ';
                
                if(String.IsBlank(lGurnt.Contact__r.MailingPostalCode))
                    lInvalidFieldList += 'Personal Guarantor Zip Code, ';
                
                if(!String.IsBlank(lInvalidFieldList))  
                    break;                          
            }
        }     
        
        return lInvalidFieldList;     
        
    }
    
    public static String validateDealerFields(LIST<Dealer__C> aDealerList){
       
        String lInvalidFieldList = '';
        
        for(Dealer__c lDealer : aDealerList){
            
             if (String.isBlank(lDealer.Dealer__r.Name))
                lInvalidFieldList += 'Dealer Business Name, ';  
            
            if (String.isBlank(lDealer.Dealer__r.Business_Address__c))
                lInvalidFieldList += 'Dealer Address, ';                                                
            
            if (String.isBlank(lDealer.Dealer__r.Business_City__c))
                lInvalidFieldList += 'Dealer City, ';   
            
            if (String.isBlank(lDealer.Dealer__r.Business_State__c))
                lInvalidFieldList += 'Dealer State, ';  
            
            if (String.isBlank(lDealer.Dealer__r.Business_Zip__c))
                lInvalidFieldList += 'Dealer Zip Code, ';   
            
            if (String.isBlank(lDealer.Dealer__r.Business_Phone__c))
                lInvalidFieldList += 'Dealer Phone Number, ';                  
            
            if(String.IsBlank(lDealer.Dealer__r.Account_Branch__c))   
                lInvalidFieldList += 'Dealer Branch, ';  
            
            if(!String.IsBlank(lInvalidFieldList))  
                break;                          
            
        }     
        
        return lInvalidFieldList; 
    }
    
    public Static String validateAssets(List<Asset__c> aAssetList){
        
        String lInvalidFieldList = '';
        
        for(Asset__c lAsset : aAssetList){
            
            if(String.IsBlank(lAsset.Equipment_Code__c))
                lInvalidFieldList += 'Asset Code, ';
            
            if(String.IsBlank(lAsset.Description__c))
                lInvalidFieldList += 'Asset Description, ';                 
            
            if(lAsset.Quantity__c == null)
                lInvalidFieldList += 'Asset Quantity, ';
            
            if(lAsset.Cost__c == null)
                lInvalidFieldList += 'Asset Cost, ';    
            
            if(lAsset.Mileage__c  == null && lAsset.Opportunity__r.RecordType.Name.Contains('TFG') )
                lInvalidFieldList += 'Asset Mileage, ';
            
            if(lAsset.New_Used__c  == null && lAsset.Opportunity__r.RecordType.Name.Contains('TFG'))
                lInvalidFieldList += 'Asset New/Used, ';
            
            if(lAsset.Sleeper_Day_Cab__c  == null && lAsset.Opportunity__r.RecordType.Name.Contains('TFG'))
                lInvalidFieldList += 'Asset Sleeper/Day Cab, ';
            
            if(lAsset.Vehicle_Make__c  == null && lAsset.Opportunity__r.RecordType.Name.Contains('TFG'))
                lInvalidFieldList += 'Asset Vehicle Make, ';
            
            if(lAsset.Vehicle_Type__c  == null && lAsset.Opportunity__r.RecordType.Name.Contains('TFG'))
                lInvalidFieldList += 'Asset Vehicle Type, ';
            
            if(lAsset.Vehicle_year__c  == null && lAsset.Opportunity__r.RecordType.Name.Contains('TFG'))
                lInvalidFieldList += 'Asset Vehicle Year, ';
            
            if(!String.IsBlank(lInvalidFieldList))  
                break;                          
            
        }     
        
        return lInvalidFieldList;     
        
    }    
    
    public Static String validateBrokers(List<Broker__c> aBrokerList){
        
        String lInvalidFieldList = '';
        
        Integer lBrokerCount = aBrokerList.size(); 
        
        if(lBrokerCount <= 0)
            
            return 'Broker Missing';
        
        
        
        for(Broker__c lBroker : aBrokerList){
            
            if(String.IsBlank(lBroker.Account__r.Name))
                lInvalidFieldList += 'Broker Name, ';
            
            if(String.IsBlank(lBroker.Account__r.Business_Address__c))
                lInvalidFieldList += 'Broker Address, ';                    
            
            if(String.IsBlank(lBroker.Account__r.Business_City__c))
                lInvalidFieldList += 'Broker City, ';
            
            if(String.IsBlank(lBroker.Account__r.Business_State__c))
                lInvalidFieldList += 'Broker State, ';
            
            if(String.IsBlank(lBroker.Account__r.Business_Zip__c))
                lInvalidFieldList += 'Broker Zip Code, ';
            
            if(String.IsBlank(lBroker.Account__r.Business_Phone__c))
                lInvalidFieldList += 'Broker Business Phone, ';                 
            
            /*if(String.IsBlank(lBroker.Account__r.Dealer_Number__c))
                lInvalidFieldList += 'Broker Dealer Number, ';*/
            
            //if(String.IsBlank(lFranchise.Franchisor__r.Account_Branch__c))
            //  lInvalidFieldList += 'Franchisor Branch, ';                 
            
        }     
        
        return lInvalidFieldList;     
        
    }    
    
    //Nirosha Changes
    
    @future
    public static void updateDealerNumberInAccount(String acctId, String dealerNumber){
        
        List<Account> accQuery = new List<Account>();
        LIST<Account> updateAccList = new LIST<Account>();
  
  		accQuery = [SELECT Id, Dealer_Number__c FROM Account WHERE ID =: acctId];
        
        
        system.debug(' accQuery.size--- '+ accQuery.Size());
        
        String formatedDealerNumber = dealerNumber.substring(0, 6) + '.' + dealerNumber.substring(6, 10);
        
        for(account acc : accQuery){
            acc.Dealer_Number__c = formatedDealerNumber;
             updateAccList.add(acc);
        }
       
        system.debug(' updatelist.size--- '+ updateAccList);
        
        /*if(accQuery.Size() == 1){
            accQuery[0].Dealer_Number__c = dealerNumber;
        }*/
        
        try{
            if(updateAccList.size() > 0)
            	update updateAccList; 
        }catch( Exception e ){
            system.debug('exception at line number-- '+ e.getLineNumber() + ' message--- '+ e.getMessage() + ' Stack trace--- ' + e.getStackTraceString());
            // integration log
        }
        
    }
    
    
 
    public Static String createRequestMsgDealer(sObject dealerData,String salesRep){
        
        String lDLRNumber = '' ;
        String lDLRBusinessName = '' ;
        String lDLRAddress1 = '' ;
        String lDLRAddress2 = '' ;
        String lDLRCity = '' ;
        String lDLRState = '' ;
        String lDLRZipCode = '';
        String lDLRPhone = '' ;
        String lDLRContactName = '' ;
        String lDLRWebURL = '' ;
        String lDLREmail = '' ;
        String lDLRSalesRepID = '' ;
        String lDLRBranch = '' ;
        String lDLRType = '' ;
        String lDLRStatus = '' ;
        String lDLRReviewDate ;
        String lDLRFollowUpDate ;
        Integer lDLRFiscalYEMonth = 0;
        String lDLRStmtDate ;
        String lDLRAuditExtent = '' ;
        String lDLREquipCode = '';
        String lDLRMarketingRep = '' ;
        String lDLRProgramMgr = '' ;
        String lDLRGroupCode = '' ;
        
        buildRapportMap();
  
        System.debug('dealer data --->'+dealerData);
        System.debug('dealer account number --->'+ String.valueOf(dealerData.getSobject('Dealer__r').get('id')));
        list<contact> lAccContactList = [SELECT Id, Name, Email FROM Contact WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId = : String.valueOf(dealerData.getSobject('Dealer__r').get('id')))];
                 
        lDLRPhone = getNumericOnly(String.ValueOf(dealerData.getSobject('Dealer__r').get('Business_Phone__c')));
        
     //   lDLRNumber = lDLRPhone.substring(0, 6) + '.' + lDLRPhone.substring(6, lDLRPhone.length()); 
        
        //lDLRNumber = String.valueOf(dOpp.Brokers__r[0].getSobject('Dealer__r').get('Dealer_Number__c'));
        lDLRBusinessName = String.valueOf(dealerData.getSobject('Dealer__r').get('Name'));
        lDLRAddress1 = String.valueOf(dealerData.getSobject('Dealer__r').get('Business_Address__c')); 
        //lDLRAddress2 = '';
        lDLRCity = String.valueOf(dealerData.getSobject('Dealer__r').get('Business_City__c'));
        lDLRState = String.valueOf(dealerData.getSobject('Dealer__r').get('Business_State__c'));
        lDLRZipCode = String.valueOf(dealerData.getSobject('Dealer__r').get('Business_Zip__c'));
   //     lDLRPhone = getNumericOnly(String.valueOf(dealerData.getSobject('Dealer__r').get('Business_Phone__c')));
        if(lAccContactList.size() <> 0){
            System.debug('Contact id ---->' + lAccContactList[0].name);
            lDLRContactName = lAccContactList[0].name;
            lDLREmail = lAccContactList[0].email;
        }
        else{
            lDLRContactName = '';
            lDLREmail = '';
        }
        lDLRWebURL = String.valueOf(dealerData.getSobject('Dealer__r').get('Website'));
        
        lDLRSalesRepID = salesRep;
        lDLRBranch = String.valueOf(transRapport('Branch',dealerData.getSobject('Dealer__r').get('Account_Branch__c')));//String.valueOf(dOpp.Brokers__r[0].getSobject('Dealer__r').get('Account_Branch__c'));
        lDLRType = 'D';
        lDLRStatus = String.valueOf(transRapport('UD_DEALER_STATUS',dealerData.getSobject('Dealer__r').get('Account_Dealer_Status__c')));
        lDLRReviewDate = date.today().format();
        lDLRFollowUpDate = (date.today() + 365).format();
        lDLRFiscalYEMonth = 1;

		lDLRStmtDate = System.today().format();
        System.debug('lDLRStmtDate---->'+lDLRStmtDate);
        System.debug('date.today()---->'+System.now().date());
        lDLRAuditExtent = '1';
        //lDLREquipCode = equipCode;
        // Account_Equipment_Code to Equipment_Code
        lDLREquipCode = TC_EquipmentCodeUtil.removeDot(String.valueOf(transRapport('Equipment_Code', TC_MultiSelectUtil.getFirstValue (dealerData.getSobject('Dealer__r').get('Equipment_Type__c')))));
        lDLRMarketingRep = salesRep;
        //sObject ldlrDataTest = dealerData.getSobject('Dealer__r');        
        lDLRProgramMgr = dealerData.getSobject('Dealer__r').get('Program_Manager__c') != null ? String.valueOf(dealerData.getSobject('Dealer__r').getSobject('Program_Manager__r').get('Personnel_Number__c')) : null;
        lDLRGroupCode = String.valueOf(transRapport('Group code',dealerData.getSobject('Dealer__r').get('Account_Dealer_Group_Code__c')));
        
        System.debug('branch value -- '+dealerData.getSobject('Dealer__r').get('Account_Branch__c'));
        System.debug('branch after trans -- '+ transRapport('Branch',String.valueOf(dealerData.getSobject('Dealer__r').get('Account_Branch__c'))));
        System.debug('dealer branch---> '+lDLRBranch);
        
        //String reqDMessage = '<?xml version="1.0" encoding="UTF-8"?><DealerData><DLRNumber>988090.9786</DLRNumber><DLRBusinessName>MyDealerName</DLRBusinessName><DLRAddress1>101 South St.</DLRAddress1><DLRAddress2>101 South St.</DLRAddress2><DLRCity>DakotaPlains</DLRCity><DLRState>SD</DLRState><DLRZipcode>12345</DLRZipcode><DLRPhoneNumber>1234561234</DLRPhoneNumber><DLRContactName>George Dudgeon</DLRContactName><DLRWebURL>www.mydealername.com</DLRWebURL><DLREmailAddress>George@mydealername.com</DLREmailAddress><DLRSalesRepID>001234</DLRSalesRepID><DLRBranch>00200</DLRBranch><DLRType>D</DLRType><DLRStatus>Pending</DLRStatus><DLRReviewDate>08/21/2017</DLRReviewDate><DLRFollowUpDate>08/21/2018</DLRFollowUpDate><DLRFiscalYEMonth>1</DLRFiscalYEMonth><DLRStmtDate>08/21/2017</DLRStmtDate><DLRAuditExtent>Audited</DLRAuditExtent><DLREquipCode>0823</DLREquipCode><DLRMarketingRep>1234</DLRMarketingRep><DLRProgramMgr>123</DLRProgramMgr><DLRGroupCode>888</DLRGroupCode></DealerData>';        
        String reqDMessage = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<DealerData>'+
            '<DLRNumber>' + lDLRPhone + '</DLRNumber>'+
            '<DLRBusinessName>' + lDLRBusinessName + '</DLRBusinessName>'+
            '<DLRAddress1>' + lDLRAddress1 + '</DLRAddress1>'+
            '<DLRAddress2>' + lDLRAddress2 + '</DLRAddress2>'+
            '<DLRCity>' + lDLRCity + '</DLRCity>'+
            '<DLRState>' + lDLRState + '</DLRState>'+
            '<DLRZipcode>' + lDLRZipCode + '</DLRZipcode>'+
            '<DLRPhoneNumber>' + lDLRPhone + '</DLRPhoneNumber>'+
            '<DLRContactName>' + lDLRContactName + '</DLRContactName>'+
            '<DLRWebURL>' + lDLRWebURL +  '</DLRWebURL>'+
            '<DLREmailAddress>' + lDLREmail + '</DLREmailAddress>'+
            '<DLRSalesRepID>' + lDLRSalesRepID + '</DLRSalesRepID>'+
            '<DLRBranch>' + lDLRBranch + '</DLRBranch>'+
            '<DLRType>' + lDLRType + '</DLRType>'+
            '<DLRStatus>' + lDLRStatus + '</DLRStatus>'+
            '<DLRReviewDate>' + lDLRReviewDate + '</DLRReviewDate>'+
            '<DLRFollowUpDate>' + lDLRFollowUpDate + '</DLRFollowUpDate>'+
            '<DLRFiscalYEMonth>' + lDLRFiscalYEMonth + '</DLRFiscalYEMonth>'+
            '<DLRStmtDate>' + lDLRStmtDate + '</DLRStmtDate>'+
            '<DLRAuditExtent>' + lDLRAuditExtent + '</DLRAuditExtent>'+
            '<DLREquipCode>' + lDLREquipCode + '</DLREquipCode>'+
            '<DLRMarketingRep>' + lDLRMarketingRep + '</DLRMarketingRep>'+
            '<DLRProgramMgr>' + lDLRProgramMgr + '</DLRProgramMgr>'+
            '<DLRGroupCode>' + lDLRGroupCode + '</DLRGroupCode>'+
            '</DealerData>';
        
        system.debug('reqDMessage--- '+reqDMessage);
        return reqDMessage; 
    }
    
    
    public Static String createRequestMsgFranchisor(sObject franchisorData,String salesRep){
        
        system.debug('inside franchisor req msg');
        
        String lDLRNumber_f = '' ;
        String lDLRBusinessName_f = '' ;
        String lDLRAddress1_f = '' ;
        String lDLRAddress2_f = '' ;
        String lDLRCity_f = '' ;
        String lDLRState_f = '' ;
        String lDLRZipCode_f = '';
        String lDLRPhone_f = '' ;
        String lDLRContactName_f = '' ;
        String lDLRWebURL_f = '' ;
        String lDLREmail_f = '' ;
        String lDLRSalesRepID_f = '' ;
        String lDLRBranch_f = '' ;
        String lDLRType_f = '' ;
        String lDLRStatus_f = '' ;
        String lDLRReviewDate_f ;
        String lDLRFollowUpDate_f ;
        Integer lDLRFiscalYEMonth_F = 0;
        String lDLRStmtDate_f ;
        String lDLRAuditExtent_f = '' ;
        String lDLREquipCode_f = '';
        String lDLRMarketingRep_f = '' ;
        String lDLRProgramMgr_f = '' ;
        String lDLRGroupCode_f = '' ;
        
        buildRapportMap();
        
        //list<Contact> lAccContactList = [Select id, name, email from Contact where AccountId = : String.valueOf(franchisorData.getSobject('Franchisor__c'))];
        list<contact> lAccContactList = [SELECT Id, Name, Email FROM Contact WHERE Id IN (SELECT ContactId FROM 
                               AccountContactRelation WHERE AccountId = : String.valueOf(franchisorData.getSobject('Franchisor__r').get('id')))];
        lDLRPhone_f = getNumericOnly(String.ValueOf(franchisorData.getSobject('Franchisor__r').get('Business_Phone__c')));
        
       // lDLRNumber_f = lDLRPhone_f.substring(0, 6) + '.' + lDLRPhone_f.substring(6, lDLRPhone_f.length()); 
        
        lDLRBusinessName_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Name'));
        lDLRAddress1_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Business_Address__c')); 
        //lDLRAddress2 = '';
        lDLRCity_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Business_City__c'));
        lDLRState_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Business_State__c'));
        lDLRZipCode_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Business_Zip__c'));
   //     lDLRPhone_f = getNumericOnly(String.valueOf(franchisorData.getSobject('Franchisor__r').get('Business_Phone__c')));
        if(lAccContactList.size() <> 0){
            lDLRContactName_f = lAccContactList[0].name;
            lDLREmail_f = lAccContactList[0].email;
        }
        else{
            lDLRContactName_f = '';
            lDLREmail_f = '';
        }
        
        //lDLRContactName_f = primaryContact;
        lDLRWebURL_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Website'));
        //lDLREmail_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Contact_Email__c'));
        lDLRSalesRepID_f = salesRep;
        lDLRBranch_f = String.valueOf(transRapport('Branch',franchisorData.getSobject('Franchisor__r').get('Account_Branch__c')));//String.valueOf(fOpp.Franchisors__r[0].getSobject('Franchisor__r').get('Account_Branch__c'));
        lDLRType_f = 'D';
        lDLRStatus_f = String.valueOf(transRapport('UD_DEALER_STATUS',franchisorData.getSobject('Franchisor__r').get('Account_Dealer_Status__c')));
        lDLRReviewDate_f = date.today().format();
        lDLRFollowUpDate_f = (date.today() + 365).format();
        lDLRFiscalYEMonth_f = 1;
        lDLRStmtDate_f = date.today().format(); 
        lDLRAuditExtent_f = '1';
        //lDLREquipCode_f = equipCode;
        // Account_Equipment_Code to Equipment_Code
        lDLREquipCode_f = TC_EquipmentCodeUtil.removeDot(String.valueOf(transRapport('Equipment_Code',TC_MultiSelectUtil.getFirstValue (franchisorData.getSobject('Franchisor__r').get('Equipment_Type__c')))));
        lDLRMarketingRep_f = salesRep;
        //lDLRProgramMgr_f = String.valueOf(franchisorData.getSobject('Franchisor__r').get('Program_Manager__r.Personnel_Number__c'));
        lDLRProgramMgr_f = franchisorData.getSobject('Franchisor__r').get('Program_Manager__c') != null ? String.valueOf(franchisorData.getSobject('Franchisor__r').getSobject('Program_Manager__r').get('Personnel_Number__c')) : null;
        lDLRGroupCode_f = String.valueOf(transRapport('Group code',franchisorData.getSobject('Franchisor__r').get('Account_Dealer_Group_Code__c')));
        
        
        //String reqDMessage = '<?xml version="1.0" encoding="UTF-8"?><DealerData><DLRNumber>988090.9786</DLRNumber><DLRBusinessName>MyDealerName</DLRBusinessName><DLRAddress1>101 South St.</DLRAddress1><DLRAddress2>101 South St.</DLRAddress2><DLRCity>DakotaPlains</DLRCity><DLRState>SD</DLRState><DLRZipcode>12345</DLRZipcode><DLRPhoneNumber>1234561234</DLRPhoneNumber><DLRContactName>George Dudgeon</DLRContactName><DLRWebURL>www.mydealername.com</DLRWebURL><DLREmailAddress>George@mydealername.com</DLREmailAddress><DLRSalesRepID>001234</DLRSalesRepID><DLRBranch>00200</DLRBranch><DLRType>D</DLRType><DLRStatus>Pending</DLRStatus><DLRReviewDate>08/21/2017</DLRReviewDate><DLRFollowUpDate>08/21/2018</DLRFollowUpDate><DLRFiscalYEMonth>1</DLRFiscalYEMonth><DLRStmtDate>08/21/2017</DLRStmtDate><DLRAuditExtent>Audited</DLRAuditExtent><DLREquipCode>0823</DLREquipCode><DLRMarketingRep>1234</DLRMarketingRep><DLRProgramMgr>123</DLRProgramMgr><DLRGroupCode>888</DLRGroupCode></DealerData>';        
        String reqDMessage = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<DealerData>'+
            '<DLRNumber>' + lDLRPhone_f + '</DLRNumber>'+
            '<DLRBusinessName>' + lDLRBusinessName_f + '</DLRBusinessName>'+
            '<DLRAddress1>' + lDLRAddress1_f + '</DLRAddress1>'+
            '<DLRAddress2>' + lDLRAddress2_f + '</DLRAddress2>'+
            '<DLRCity>' + lDLRCity_f + '</DLRCity>'+
            '<DLRState>' + lDLRState_f + '</DLRState>'+
            '<DLRZipcode>' + lDLRZipCode_f + '</DLRZipcode>'+
            '<DLRPhoneNumber>' + lDLRPhone_f + '</DLRPhoneNumber>'+
            '<DLRContactName>' + lDLRContactName_f + '</DLRContactName>'+
            '<DLRWebURL>' + lDLRWebURL_f +  '</DLRWebURL>'+
            '<DLREmailAddress>' + lDLREmail_f + '</DLREmailAddress>'+
            '<DLRSalesRepID>' + lDLRSalesRepID_f + '</DLRSalesRepID>'+
            '<DLRBranch>' + lDLRBranch_f + '</DLRBranch>'+
            '<DLRType>' + lDLRType_f + '</DLRType>'+
            '<DLRStatus>' + lDLRStatus_f + '</DLRStatus>'+
            '<DLRReviewDate>' + lDLRReviewDate_f + '</DLRReviewDate>'+
            '<DLRFollowUpDate>' + lDLRFollowUpDate_f + '</DLRFollowUpDate>'+
            '<DLRFiscalYEMonth>' + lDLRFiscalYEMonth_f + '</DLRFiscalYEMonth>'+
            '<DLRStmtDate>' + lDLRStmtDate_f + '</DLRStmtDate>'+
            '<DLRAuditExtent>' + lDLRAuditExtent_f + '</DLRAuditExtent>'+
            '<DLREquipCode>' + lDLREquipCode_f + '</DLREquipCode>'+
            '<DLRMarketingRep>' + lDLRMarketingRep_f + '</DLRMarketingRep>'+
            '<DLRProgramMgr>' + lDLRProgramMgr_f + '</DLRProgramMgr>'+
            '<DLRGroupCode>' + lDLRGroupCode_f + '</DLRGroupCode>'+
            '</DealerData>';
        
        system.debug('reqDMessage franchisor--- '+reqDMessage);
        return reqDMessage; 
    }
    
    //Nirosha Changes
    
    public Static String createRequestMsgBroker(sObject brokerData,String salesRep){
        
        system.debug('inside broker req msg');
        
        String lDLRNumber_b = '' ;
        String lDLRBusinessName_b = '' ;
        String lDLRAddress1_b = '' ;
        String lDLRAddress2_b = '' ;
        String lDLRCity_b = '' ;
        String lDLRState_b = '' ;
        String lDLRZipCode_b = '';
        String lDLRPhone_b = '' ;
        String lDLRContactName_b = '' ;
        String lDLRWebURL_b = '' ;
        String lDLREmail_b = '' ;
        String lDLRSalesRepID_b = '' ;
        String lDLRBranch_b = '' ;
        String lDLRType_b = '' ;
        String lDLRStatus_b = '' ;
        String lDLRReviewDate_b ;
        String lDLRFollowUpDate_b ;
        Integer lDLRFiscalYEMonth_b = 0;
        String lDLRStmtDate_b ;
        String lDLRAuditExtent_b = '' ;
        String lDLREquipCode_b = '';
        String lDLRMarketingRep_b = '' ;
        String lDLRProgramMgr_b = '' ;
        String lDLRGroupCode_b = '' ;
        
        buildRapportMap();
        //list<Contact> lAccContactList = [Select id, name, email from Contact where AccountId = : String.valueOf(brokerData.getSobject('Account__c'))];
        list<contact> lAccContactList = [SELECT Id, Name, Email FROM Contact WHERE Id IN 
                                         (SELECT ContactId FROM AccountContactRelation WHERE 
                                          AccountId = : String.valueOf(brokerData.getSobject('Account__r').get('id')))];
      //  lDLRPhone_b = getNumericOnly(String.ValueOf(brokerData.getSobject('Account__r').get('Business_Phone__c')));
        
      //  lDLRNumber_b = lDLRPhone_b.substring(0, 6) + '.' + lDLRPhone_b.substring(6, lDLRPhone_b.length()); 
        
        lDLRBusinessName_b = String.valueOf(brokerData.getSobject('Account__r').get('Name'));
        lDLRAddress1_b = String.valueOf(brokerData.getSobject('Account__r').get('Business_Address__c')); 
        //lDLRAddress2 = '';
        lDLRCity_b = String.valueOf(brokerData.getSobject('Account__r').get('Business_City__c'));
        lDLRState_b = String.valueOf(brokerData.getSobject('Account__r').get('Business_State__c'));
        lDLRZipCode_b = String.valueOf(brokerData.getSobject('Account__r').get('Business_Zip__c'));
        lDLRPhone_b = getNumericOnly(String.valueOf(brokerData.getSobject('Account__r').get('Business_Phone__c')));
        
        if(lAccContactList.size() <> 0){
            lDLRContactName_b = lAccContactList[0].name;
            lDLREmail_b = lAccContactList[0].email;
        }
        else{
            lDLRContactName_b = '';
            lDLREmail_b = '';
        }
        //lDLRContactName_b = primaryContact;
        lDLRWebURL_b = String.valueOf(brokerData.getSobject('Account__r').get('Website'));
        //lDLREmail_b = String.valueOf(brokerData.getSobject('Account__r').get('Contact_Email__c'));
        lDLRSalesRepID_b = salesRep;
        lDLRBranch_b = String.valueOf(transRapport('Branch',brokerData.getSobject('Account__r').get('Account_Branch__c')));
        lDLRType_b = 'D';
        lDLRStatus_b = String.valueOf(transRapport('UD_DEALER_STATUS',brokerData.getSobject('Account__r').get('Account_Dealer_Status__c')));
        lDLRReviewDate_b = date.today().format();
        lDLRFollowUpDate_b = (date.today() + 365).format();
        lDLRFiscalYEMonth_b = 1;
        lDLRStmtDate_b = date.today().format(); 
        lDLRAuditExtent_b = '1';
        //lDLREquipCode_b = equipCode;
        // Account_Equipment_Code to Equipment_Code
        lDLREquipCode_b = TC_EquipmentCodeUtil.removeDot(String.valueOf(transRapport('Equipment_Code',TC_MultiSelectUtil.getFirstValue (brokerData.getSobject('Account__r').get('Equipment_Type__c')))));
        lDLRMarketingRep_b = salesRep;
        //lDLRProgramMgr_b = String.valueOf(brokerData.getSobject('Account__r').get('Program_Manager__r.Personnel_Number__c'));
        lDLRProgramMgr_b = brokerData.getSobject('Account__r').get('Program_Manager__c') != null ? String.valueOf(brokerData.getSobject('Account__r').getSobject('Program_Manager__r').get('Personnel_Number__c')) : null;
        lDLRGroupCode_b = String.valueOf(transRapport('Group code',brokerData.getSobject('Account__r').get('Account_Dealer_Group_Code__c')));
        
        
        //String reqDMessage = '<?xml version="1.0" encoding="UTF-8"?><DealerData><DLRNumber>988090.9786</DLRNumber><DLRBusinessName>MyDealerName</DLRBusinessName><DLRAddress1>101 South St.</DLRAddress1><DLRAddress2>101 South St.</DLRAddress2><DLRCity>DakotaPlains</DLRCity><DLRState>SD</DLRState><DLRZipcode>12345</DLRZipcode><DLRPhoneNumber>1234561234</DLRPhoneNumber><DLRContactName>George Dudgeon</DLRContactName><DLRWebURL>www.mydealername.com</DLRWebURL><DLREmailAddress>George@mydealername.com</DLREmailAddress><DLRSalesRepID>001234</DLRSalesRepID><DLRBranch>00200</DLRBranch><DLRType>D</DLRType><DLRStatus>Pending</DLRStatus><DLRReviewDate>08/21/2017</DLRReviewDate><DLRFollowUpDate>08/21/2018</DLRFollowUpDate><DLRFiscalYEMonth>1</DLRFiscalYEMonth><DLRStmtDate>08/21/2017</DLRStmtDate><DLRAuditExtent>Audited</DLRAuditExtent><DLREquipCode>0823</DLREquipCode><DLRMarketingRep>1234</DLRMarketingRep><DLRProgramMgr>123</DLRProgramMgr><DLRGroupCode>888</DLRGroupCode></DealerData>';        
        String reqDMessage = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<DealerData>'+
            '<DLRNumber>' + lDLRPhone_b + '</DLRNumber>'+
            '<DLRBusinessName>' + lDLRBusinessName_b + '</DLRBusinessName>'+
            '<DLRAddress1>' + lDLRAddress1_b + '</DLRAddress1>'+
            '<DLRAddress2>' + lDLRAddress2_b + '</DLRAddress2>'+
            '<DLRCity>' + lDLRCity_b + '</DLRCity>'+
            '<DLRState>' + lDLRState_b + '</DLRState>'+
            '<DLRZipcode>' + lDLRZipCode_b + '</DLRZipcode>'+
            '<DLRPhoneNumber>' + lDLRPhone_b + '</DLRPhoneNumber>'+
            '<DLRContactName>' + lDLRContactName_b + '</DLRContactName>'+
            '<DLRWebURL>' + lDLRWebURL_b +  '</DLRWebURL>'+
            '<DLREmailAddress>' + lDLREmail_b + '</DLREmailAddress>'+
            '<DLRSalesRepID>' + lDLRSalesRepID_b + '</DLRSalesRepID>'+
            '<DLRBranch>' + lDLRBranch_b + '</DLRBranch>'+
            '<DLRType>' + lDLRType_b + '</DLRType>'+
            '<DLRStatus>' + lDLRStatus_b + '</DLRStatus>'+
            '<DLRReviewDate>' + lDLRReviewDate_b + '</DLRReviewDate>'+
            '<DLRFollowUpDate>' + lDLRFollowUpDate_b + '</DLRFollowUpDate>'+
            '<DLRFiscalYEMonth>' + lDLRFiscalYEMonth_b + '</DLRFiscalYEMonth>'+
            '<DLRStmtDate>' + lDLRStmtDate_b + '</DLRStmtDate>'+
            '<DLRAuditExtent>' + lDLRAuditExtent_b + '</DLRAuditExtent>'+
            '<DLREquipCode>' + lDLREquipCode_b + '</DLREquipCode>'+
            '<DLRMarketingRep>' + lDLRMarketingRep_b + '</DLRMarketingRep>'+
            '<DLRProgramMgr>' + lDLRProgramMgr_b + '</DLRProgramMgr>'+
            '<DLRGroupCode>' + lDLRGroupCode_b + '</DLRGroupCode>'+
            '</DealerData>';
        
        system.debug('reqDMessage franchisor--- '+reqDMessage);
        return reqDMessage; 
    }
    
    
    
    public Static string createRequestMsg(String opptyId, String DealerNumber, Map<String,String> aMapPhoneToCCAN) {
        
        system.debug('DealerNumber-- ** '+DealerNumber);
        String UserName = System.Label.RapportUser;
        String Password = System.Label.RapportPassword;
        String Alias = System.Label.Rapport_Alias; 
        Guarantor__c lGuarantor = New Guarantor__c();  
        String lRelGuarantorMsg = '';
        String lFranchisorRelPartyMsg = '';
        String lBrokerRelPartyMsg = '';
        String lRelatedPartyMsg = '';
        String lVariablePaymentMsg = '';
        String lPointMsg = '';
        String lAssetMsg = '';
        Integer lGrtCount = 0;
        String BusinessType = '';
        String BusinessStreet = '';
        String BusinessCity = ''; 
        String BusinessState = '';
        String BusinessZip = '';
        String lContactName, lContactEmail, lContactPhone,lEndUserSourceCode,lProfileName;
        
        
        buildRapportMap();  
        
        List<Profile> userPropfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        lProfileName = userPropfile[0].Name;           
        
        Opportunity optyList = [select id,RecordType.Name,Purchase_Options__c,Business_Type__c,UD_TIMERECEIVED__c,
                                Primary_Contact_Email__c,Primary_Contact_Fax__c,Points__c,Primary_Source__c,
                                Primary_Contact_Name__c, Primary_Contact_Phone__c, Equipment_Description__c,Sales_Comments__c,
                                UD_DEALER_STATUS__c,UD_DECISION_INELIGIBLE__c, Payment_Amount__c,
                                Approved_Amount__c,Sales_Rep__c,Tax_ID__c,Business_Phone__c,
                                Equipment_Cost__c,Branch__c,Terms__c,Sec_Dep_Pymts__c,of_Payments__c,
                                UD_DATERECEIVED__c,UD_DLR_ENTERED_APP__c,Payment_Frequency__c,
                                Account.Name, Account.DBA__c,Account.Business_Type__c,
                                Account.Line_of_Business__c,Account.Business_Address__c,Account.Business_City__c,
                                Account.Business_State__c,Account.Business_Zip__c,Account.Business_Phone__c,
                                Application__c,Account.BILLINGSTREET,Account.BILLINGCity,Account.BillingStateCode,
                                Account.BillingPostalCode, Account.Tax_ID__c,Account.NumberOfEmployees,
                                Years_in_Business__c,Account.CCAN__c, 
                                (Select contact.Phone,contact.Name, contact.Email 
                                 From OpportunityContactRoles where IsPrimary = true),
                                (SELECT Name,Cost__c,Description__c,Model__c,Serial_Number__c,
                                 Equipment_City__c, Equipment_Code__c,Equipment_State__c,
                                 Equipment_Street__c, Equipment_Zip__c,Quantity__c, Mileage__c, New_Used__c, 
                                 Sleeper_Day_Cab__c, Vehicle_Make__c, Vehicle_Type__c, Vehicle_year__c, Opportunity__c FROM Assets__r),
                                (SELECT id,name,Primary_Dealer__c,Dealer__c,Dealer__r.Name,Dealer__r.Tax_ID__c, Dealer__r.Business_Address__c, 
                                 Dealer__r.Business_City__c, Dealer__r.Business_State__c,Dealer__r.Dealer_Number__c, 
                                 Dealer__r.Business_Zip__c, Dealer__r.Account_Branch__c,Dealer__r.Business_Phone__c,Dealer__r.Account_Dealer_Status__c 
                                 FROM Brokers__r),
                                (SELECT id,name,Account__c,Account__r.Name,Account__r.Tax_ID__c, Account__r.Business_Address__c, 
                                 Account__r.Business_City__c, Account__r.Business_State__c,Account__r.Dealer_Number__c, 
                                 Account__r.Business_Zip__c, Account__r.Account_Branch__c,Account__r.Business_Phone__c,Account__r.Account_Dealer_Status__c 
                                 FROM Brokers1__r Limit 1),
                                (SELECT id,name,Franchisor__c,Franchisor__r.Name, Franchisor__r.Business_Address__c,Franchisor__r.Account_Dealer_Status__c, 
                                 Franchisor__r.Business_City__c, Franchisor__r.Business_State__c,Franchisor__r.Dealer_Number__c, 
                                 Franchisor__r.Business_Zip__c, Franchisor__r.Business_Phone__c, Franchisor__r.Account_Branch__c 
                                 FROM Franchisors__r LIMIT 1),
                                (Select Id,Contact__c,Account__c,Type__c,RP_PRIN_GUAR_CODE__c,
                                 Contact__r.FirstName, Contact__r.LastName, Contact__r.Name, 
                                 Contact__r.SSN__c,Contact__r.Phone, Contact__r.MailingStreet, 
                                 Contact__r.MailingCity,Contact__r.MailingStateCode, Contact__r.MailingPostalCode,
                                 Account__r.Name, Account__r.Id, Account__r.CCAN__c, Account__r.Primary_Contact__c,
                                 Account__r.Business_Address__c, Account__r.Business_City__c, Account__r.Business_State__c,
                                 Account__r.Business_Zip__c, Account__r.Business_Phone__c,
                                 Account__r.Primary_Contact__r.FirstName, Account__r.Primary_Contact__r.LastName,
                                 Account__r.Primary_Contact__r.Phone  
                                 from Guarantor__r),
                                (SELECT ID, of_payments__c,Payment_Amount__c,Total__c 
                                 FROM Variable_Payments__r)  
                                from Opportunity where Id =:OpptyId ];
        
        
        lContactName =  optyList.OpportunityContactRoles.size() == 0 ? '' : getXMLValue(String.ValueOf(optyList.OpportunityContactRoles[0].getSobject('Contact').get('Name')));
        lContactEmail = optyList.OpportunityContactRoles.size() == 0 ? '' : getXMLValue(String.ValueOf(optyList.OpportunityContactRoles[0].getSobject('Contact').get('eMail')));
        lContactPhone = getNumericOnly(getXMLValue(String.ValueOf(optyList.Business_Phone__c)));
     
        
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
        System.debug('dealer number blank ****'+ String.isBlank(DealerNumber));



        
        
        System.debug('Rapport Opportunity: ' + optyList);
        
        if(optyList.RecordType.Name.Contains('Franchise'))
            mIsFranchise = True;            
        
        if(optyList.RecordType.Name.Contains('IFP'))
            mIsIFP = True;
        
        
        
        if((optyList.RecordType.Name.Contains('Lease') || optyList.RecordType.Name.Contains('DLG')) && lProfileName.contains('DLG Rep'))
            lEndUserSourceCode = transRapport('Primary Source',optyList.Primary_Source__c);
        else
            lEndUserSourceCode = '';        
        
        lRelGuarantorMsg = createGuarantorMsg(optyList.Guarantor__r,aMapPhoneToCCAN);        
        lFranchisorRelPartyMsg = createRelatedPartyMsg(optyList.Brokers__r);
        lBrokerRelPartyMsg = createRelatedPartyMsg(optyList.Brokers__r);
        lVariablePaymentMsg = createVPMsg(optyList.Variable_Payments__r);
        lPointMsg = createPointMsg(optyList.Points__c,optyList.Equipment_Cost__c);
        
        // getting related party message for PGs
        lRelatedPartyMsg = lRelGuarantorMsg;
        
        if(mIsFranchise == True)
            lRelatedPartyMsg += lFranchisorRelPartyMsg;
        
        if(optyList.RecordType.Name.Contains('IFP'))
            lRelatedPartyMsg += lBrokerRelPartyMsg;
        
        lGrtCount = optyList.Guarantor__r.size();
        
        lAssetMsg = createAssetsMsg(optyList.Assets__r);
        System.debug('Rapport Asset: ' + lAssetMsg);
        
        String lDealerAccountId = '';
        System.debug('Dealers Count:' + optyList.Brokers__r.size());
        if(optyList.Brokers__r.size() > 0) {
            
            for(Dealer__c dlr : optyList.Brokers__r){
                if(dlr.Primary_Dealer__c == true)
                    lDealerList.add(dlr);
            }
            //mDealerListForOther = optyList.Brokers__r; 
            
            mDealerListForOther =  optyList.Brokers__r; 
            
            lDealerAccountId = String.ValueOf(lDealerList[0].Get('Dealer__c'));
            System.debug('Dealer Name: ' + lDealerList[0].getSobject('Dealer__r').get('Name'));
        }  
        
        
        if(optyList.Franchisors__r.size() > 0)
            lFranchisorList = optyList.Franchisors__r;
        if(optyList.Brokers1__r.size() > 0)
            lBrokerList = optyList.Brokers1__r;
        
        if(!String.isBlank(lDealerAccountId)){
            List<AccountContactRelation> lAccountContRelList = [select ContactId
                                                                from AccountContactRelation  where AccountId = :lDealerAccountId
                                                                and Roles includes ('Primary Contact')];

            if (!lAccountContRelList.isEmpty())
                lDealerConList = [select id,FirstName,LastName,Email,Phone,Name
                                  from Contact where Id = :lAccountContRelList[0].ContactId];
            else
                lDealerConList = [select id,FirstName,LastName,Email,Phone,Name
                                  from Contact where AccountId =:lDealerAccountId ];
        }
        if(String.isBlank(DealerNumber)){
            System.debug('dealer number blank +++++');
            DealerNumber = getDealerData('Dealer_Number__c');
            System.debug('dealer number blank ###'+DealerNumber);
            if(String.IsBlank(DealerNumber))
                return 'Dealer Number is blank';
        }
        System.debug('Rapport Dealers: ' + lDealerList);
        System.debug('Primary Source-->: ' + transRapport('Primary Source',optyList.Primary_Source__c));
        
        String requestMsg = '<?xml version="1.0" encoding="UTF-8"?>'+
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:RapportDataImportIntf-IRapportDataImport" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
            '   <soapenv:Header />'+
            '   <soapenv:Body>'+
            '      <urn:SendApplication soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'+
            '         <aApplicationXml xsi:type="xsd:string">'+
            '            <RapportDataImport>'+
            '               <Action>SubmitForApproval</Action>'+
            '               <Alias>' + Alias + '</Alias>'+
            '               <User>'+
            '                  <WorklistUser>' + UserName + '</WorklistUser>'+
            '                  <Password>' + Password + '</Password>'+
            '               </User>'+
            '               <AppData>'+
            '                  <CUST_DATA>'+
            '                     <CUST_NAME>' + getSubstring(getXMLValue(optyList.Account.Name),50) + '</CUST_NAME>'+
            '                     <DBA>'+ getSubstring(getXMLValue(optyList.Account.DBA__c),30) + '</DBA>'+
            '                     <BUSINESS_TYPE>'+ transRapport('Business_Type',BusinessType) + '</BUSINESS_TYPE>'+ //01
            '                     <UD_SIC_CODE>'+ transRapport('Line_of_Business',optyList.Account.Line_of_Business__c) + '</UD_SIC_CODE>'+ //picklist
            '                     <ADDR_1>' + getSubstring(getXMLValue(BusinessStreet),50) + '</ADDR_1>'+
            '                     <CITY>' + getXMLValue(BusinessCity)+ '</CITY>'+
            '                     <STATE>' + getXMLValue(BusinessState) + '</STATE>'+
            '                     <ZIP>' + getSubstring(getXMLValue(BusinessZip),5) + '</ZIP>'+
            '                     <CONTACT_PHONE>' + lContactPhone + '</CONTACT_PHONE>'+
            '                     <CONTACT_NAME>' + lContactName + '</CONTACT_NAME>'+
            '                     <YEARS_IN_BUSINESS>'+ getXMLValue(optyList.Years_in_Business__c) + '</YEARS_IN_BUSINESS>' +
            '                     <FED_ID>'+ getXMLValue(optyList.Tax_ID__c) + '</FED_ID>'+
            '                     <CONTACT_EMAIL>' + lContactEmail + '</CONTACT_EMAIL>'+
            '                     <CCAN>' + getXMLValue(optyList.Account.CCAN__c) + '</CCAN>'+
            '                     <AR_ADDR_1>' + getSubstring(getXMLValue(optyList.Account.BillingStreet),50) + '</AR_ADDR_1>'+
            '                     <AR_CITY>' + getXMLValue(optyList.Account.BillingCity) + '</AR_CITY>'+
            '                     <AR_STATE>' + getXMLValue(optyList.Account.BillingStateCode) + '</AR_STATE>'+
            '                     <AR_ZIP>' + getSubstring(getXMLValue(optyList.Account.BillingPostalCode),5) + '</AR_ZIP>'+
            '                     <ADDR_2></ADDR_2>'+
            '                     <AR_ADDR_2></AR_ADDR_2>'+
            '                  </CUST_DATA>'+
            '                  <Application>'+
            '                     <CO>'+
            '                        <CUST.NAME>' + getSubstring(getXMLValue(optyList.Account.Name),50) + '</CUST.NAME>'+
            '                        <CUST.DBA>'+ getSubstring(getXMLValue(optyList.Account.DBA__c),30) + '</CUST.DBA>'+
            '                        <AM.BUSINESS.TYPE>'+ transRapport('Business_Type',optyList.Account.Business_Type__c) + '</AM.BUSINESS.TYPE>'+ //01
            '                        <UD_SIC_CODE>'+ transRapport('Line_of_Business',optyList.Account.Line_of_Business__c) + '</UD_SIC_CODE>'+ //picklist
            '                        <CUST.ADDRESS1>' + getSubstring(getXMLValue(BusinessStreet),50) + '</CUST.ADDRESS1>'+
            '                        <CUST.CITY>' + getXMLValue(BusinessCity)+ '</CUST.CITY>'+
            '                        <CUST.STATE>' + getXMLValue(BusinessState) + '</CUST.STATE>'+
            '                        <CUST.ZIP>' + getSubstring(getXMLValue(BusinessZip),5) + '</CUST.ZIP>'+
            '                        <CR.ATTG.PHONE>' + lContactPhone + '</CR.ATTG.PHONE>'+
            '                        <CR.ATTG.NAME>' + lContactName + '</CR.ATTG.NAME>'+
            '                        <UD_MONTHS_IN_BUSINESS />'+ // not able to find
            '                        <FED.ID>'+ getXMLValue(optyList.Tax_ID__c) + '</FED.ID>'+
            '                        <NMF.CONTACT.EMAIL>' + lContactEmail + '</NMF.CONTACT.EMAIL>'+
            '                        <UD_CUST_NUM_EMP>' + getXMLValue(optyList.Account.NumberOfEmployees) + '</UD_CUST_NUM_EMP>'+
            '                        <CONTRACT.TERM>' + getXMLValue(optyList.Terms__c) + '</CONTRACT.TERM>'+ 
            '                        <AM.PURCHASE.OPTION>' + transRapport('PUR.OPTION',optyList.Purchase_Options__c) + '</AM.PURCHASE.OPTION>' +
            '                        <UD_DISCLAIMER_CHECKBOX>1</UD_DISCLAIMER_CHECKBOX>'+ // awaited
            '                        <CUST.ID>' + getXMLValue(optyList.Account.CCAN__c) + '</CUST.ID>'+
            '                        <AR.ADDRESS1>' + getSubstring(getXMLValue(optyList.Account.BillingStreet),50) + '</AR.ADDRESS1>'+
            '                        <AR.CITY>' + getXMLValue(optyList.Account.BillingCity) + '</AR.CITY>'+
            '                        <AR.STATE>' + getXMLValue(optyList.Account.BillingStateCode) + '</AR.STATE>'+
            '                        <AR.ZIP>' + getSubstring(getXMLValue(optyList.Account.BillingPostalCode),5) + '</AR.ZIP>'+
            '                        <UD_TRADE_UP_AMT />'+  // defaulted as per design
            '                        <UD_TRADE_UP_CONTRACT />'+ // defaulted as per design
            '                        <UD_DEALER_NAME>' + getDealerData('Name') + '</UD_DEALER_NAME>'+
            '                        <DEALER>' + formatDealerNumber(DealerNumber) + '</DEALER>'+
            '                        <UD_DISCLAIMER />'+    // TBD as per design 
            '                        <UD_PORTAL_USER_ID>SF-</UD_PORTAL_USER_ID>'+ //Defaulted prefix SF- as per mail
            '                        <UD_CREDIT_AMOUNT>' + getXMLValue(optyList.Equipment_Cost__c) + '</UD_CREDIT_AMOUNT>'+ 
            '                        <UD_EQUIP.DESC>' + getXMLValue(optyList.Equipment_Description__c) + '</UD_EQUIP.DESC>'+
            '                        <UD_DLR_ENTERED_PGS>' + lGrtCount + '</UD_DLR_ENTERED_PGS>'+ //Count of PG's added to Application
            '                        <UD_DLR_ENTERED_COMMENT>' + getXMLValue(optyList.Sales_Comments__c) + '</UD_DLR_ENTERED_COMMENT>'+
            '                        <UD_PYMT_FREQUENCY >' + transRapport('UD_PAYMENT_FREQUENCY',optyList.Payment_Frequency__c) + '</UD_PYMT_FREQUENCY >'+
            '                        <UD_TIMERECEIVED>' + getTimeReceivedString() + '</UD_TIMERECEIVED>'+ // need to get
            '                        <UD_DATERECEIVED>' + System.now().Format('YYYY-MM-dd') + '</UD_DATERECEIVED>'+
            '                        <UD_DLR_ENTERED_APP>' + getXMLValue(optyList.UD_DLR_ENTERED_APP__c) + '</UD_DLR_ENTERED_APP>'+ 
            '                        <EQUIPMENT.COST>' + getXMLValue(optyList.Equipment_Cost__c) + '</EQUIPMENT.COST>'+
            //'                        <BRANCH>' + transRapport('Branch',getDealerData('Account_Branch__c')) + '</BRANCH>' +
                '                        <BRANCH>' + transRapport('Branch',optyList.Branch__c) + '</BRANCH>' +

                '                        <UD_SALESPERSON>' + getXMLValue(optyList.Sales_Rep__c) + '</UD_SALESPERSON>'+
            '                        <UD_DEALER_STATUS>' + transRapport('UD_DEALER_STATUS',getDealerData('Account_Dealer_Status__c')) + '</UD_DEALER_STATUS>'+
            '                        <UD_DLR_NAME>' + getDealerData('Name') + '</UD_DLR_NAME>'+
            '                        <UD_DLR_ADDR1>' + getSubstring(getDealerData('Business_Address__c'),50) + '</UD_DLR_ADDR1>'+
            '                        <UD_DLR_ADDR2></UD_DLR_ADDR2>'+
            '                        <UD_DLR_CITY>' + getDealerData('Business_City__c') + '</UD_DLR_CITY>'+
            '                        <UD_DLR_STATE>' + getDealerData('Business_State__c') + '</UD_DLR_STATE>'+
            '                        <UD_DLR_ZIP>' + getSubstring(getDealerData('Business_Zip__c'),5) + '</UD_DLR_ZIP>'+
            '                        <UD_DLR_CNTC_PHONE>' + getNumericOnly(getDealerData('Business_Phone__c')) + '</UD_DLR_CNTC_PHONE>'+
            '                        <UD_VENDOR_ADD1>' + getSubstring(getDealerData('Business_Address__c'),30) + '</UD_VENDOR_ADD1>'+
            '                        <UD_VENDOR_ADDR2></UD_VENDOR_ADDR2>'+
            '                        <UD_VENDOR_CITY>' + getDealerData('Business_City__c') + '</UD_VENDOR_CITY>'+
            '                        <UD_VENDOR_ZIP>' + getDealerData('Business_Zip__c') + '</UD_VENDOR_ZIP>'+
            '                        <UD_VENDOR_PHONE>' + getNumericOnly(getDealerData('Business_Phone__c')) + '</UD_VENDOR_PHONE>'+
            '                        <UD_VENDOR_STATE>' + getDealerData('Business_State__c') + '</UD_VENDOR_STATE>'+
            '                        <UD_DECISION_INELIGIBILE>' + getXMLValue(optyList.UD_DECISION_INELIGIBLE__c) + '</UD_DECISION_INELIGIBILE>'+
            '					     <UD_END_USER_SOURCE_CODE>' + lEndUserSourceCode + '</UD_END_USER_SOURCE_CODE>'+    
            '                        <UD_DEALER_APP_CONTACT>' + getContactData(lDealerConList, 'Name') + '</UD_DEALER_APP_CONTACT>'+
            '                        <UD_DEALER_APP_EMAIL>' + getContactData(lDealerConList, 'Email') + '</UD_DEALER_APP_EMAIL>'+
            '                        <CONTRACT.PYMT>' + getXMLValue(optyList.Payment_Amount__c) + '</CONTRACT.PYMT>'+
            
            '                        <UD_PORTAL_METHOD>2</UD_PORTAL_METHOD>'+ // defaulted as per design
            '                        <UD_ORIG_LOAN_AMT></UD_ORIG_LOAN_AMT>'+ // not able to find
            '                        <UD_TMETRIX_POLICY_SCORE />'+ // defaulted as per design
            '                        <UD_TMETRIX_REASON_CODE />'+ // defaulted as per design
            '                        <UD_TMETRIX_REVIEW_STATUS />'+ // defaulted as per design
            '                        <UD_TMETRIX_RISK_RATING />'+   // defaulted as per design
            '                        <UD_TMETRIX_TRUE_IP />'+   // defaulted as per design
            '                        <UD_ADV_RENTALS />'+
            '                        <SEC.DEPOSIT>' + getXMLValue(optyList.Sec_Dep_Pymts__c) + '</SEC.DEPOSIT>'+
            '                        <UD_NUM_OF_PYMTS>' + getXMLValue(optyList.of_Payments__c) + '</UD_NUM_OF_PYMTS>'+
            '                        <UD_CANADA_APP>0</UD_CANADA_APP>'+ // defaulted as per design
            '                        <CUST.ADDRESS2></CUST.ADDRESS2>'+
            '                        <AR.ADDRESS2></AR.ADDRESS2>'+
            '                           ' + lAssetMsg + // included asset messages
            '                           ' + lRelatedPartyMsg +  // included related party section here
            '                           ' + lVariablePaymentMsg + // included variable payment message here
            '                           ' + lPointMsg + // included point message in xml
            '                     </CO>'+
            '                  </Application>'+
            '               </AppData>'+
            '            </RapportDataImport>'+
            '         </aApplicationXml>'+
            '      </urn:SendApplication>'+
            '   </soapenv:Body>'+
            '</soapenv:Envelope>';          
        
        System.debug('Rapport Request Message: ' + requestMsg); 
        return requestMsg;
        
    }           
    
    public Static void buildRapportMap(){
        
        rapportMaps.Clear();
        
        for (MARLIN_Rapport_Mapping__mdt rapportMap:[Select MasterLabel, Rapport_Value__c, Field_Name__c from MARLIN_Rapport_Mapping__mdt])
        {
            rapportMaps.put(rapportMap.Field_Name__c + '__' + rapportMap.MasterLabel, rapportMap.Rapport_Value__c);
        }        
        System.debug('Rapport Transform Map: ' + rapportMaps);  
    }
    
    public static String transRapport(String fieldName, Object argVal) {
        System.debug('Rapport Transform call: ' + fieldName + '::' + argVal );  
        if(argVal != null) {
            system.debug('rapportMaps-- '+rapportMaps.Get(fieldName + '__' + String.valueof(argVal)));
            return rapportMaps.Get(fieldName + '__' + String.valueof(argVal));
        }
        
        return '';
    }     
    
    
    
    public Static string createInfoleaseRequestMsg(Guarantor__c aGurnt, String aType){
        
        String lReqMessage = '';
        String lRPAddress1,lRPCity,lRPState,lRPZip,lRPFName,lRPLName,lRPPhoneNumber,lRPTaxID,lRPType,lBusFullName;
        
        if(aGurnt == null)
            return lReqMessage;
        
        lRPAddress1 = aType == 'Personal Guarantor' ? aGurnt.Contact__r.MailingStreet : aGurnt.Account__r.Business_Address__c;
        lRPCity = aType == 'Personal Guarantor' ? aGurnt.Contact__r.MailingCity : aGurnt.Account__r.Business_City__c;
        lRPState = aType == 'Personal Guarantor' ? aGurnt.Contact__r.MailingStateCode : aGurnt.Account__r.Business_State__c;
        lRPZip = aType == 'Personal Guarantor' ? getSubstring(getXMLValue(aGurnt.Contact__r.MailingPostalCode),5) : getSubstring(getXMLValue(aGurnt.Account__r.Business_Zip__c),5);
        lRPFName = aType == 'Personal Guarantor' ? aGurnt.Contact__r.FirstName : String.ValueOf(aGurnt.Account__r.Name).Replace(' ','');
        lRPLName = aType == 'Personal Guarantor' ? aGurnt.Contact__r.LastName : String.ValueOf(aGurnt.Account__r.Name).Replace(' ','');
        lRPPhoneNumber = aType == 'Personal Guarantor' ? aGurnt.Contact__r.Phone : aGurnt.Account__r.Business_Phone__c;
        lRPTaxID = aType == 'Personal Guarantor' ? aGurnt.Contact__r.SSN__c : aGurnt.Account__r.Tax_ID__c;
        lRPType = aType == 'Personal Guarantor' ? '02' : '03';
        lBusFullName = aType == 'Personal Guarantor' ? lRPFName + lRPLName : aGurnt.Account__r.Name;            
        
        
        lReqMessage = '<?xml version="1.0" encoding="UTF-8"?>' + 
            '<RelatedParty>' + 
            '   <BusFullName>' + lBusFullName + '</BusFullName>' + 
            '   <RPAddress1>' + getSubstring(lRPAddress1,50) + '</RPAddress1>' + 
            '   <RPCity>' + lRPCity + '</RPCity>' + 
            '   <RPState>' + lRPState + '</RPState>' + 
            '   <RPZip>' + lRPZip + '</RPZip>' + 
            '   <RPFName>' + lRPFName + '</RPFName>' + 
            '   <RPLName>' + lRPLName + '</RPLName>' + 
            '   <RPPhoneNumber>' + getNumericOnly(lRPPhoneNumber) + '</RPPhoneNumber>' + 
            '   <RPTaxID>' + lRPTaxID + '</RPTaxID>' + 
            '   <RPType>'+ lRPType + '</RPType>' + 
            '</RelatedParty>';          
        
        
        return lReqMessage;
    }
    
    
    public Static string createInfoleaseRequestMsg(Dealer__c aDealer, String aOptyRecordType){
        
        String lReqMessage = '';
        Integer lRpType = 0;
        if(aDealer == null)
            return lReqMessage;
        
        if(aOptyRecordType.Contains('Franchise'))
            lRpType = 07;
        else if(aOptyRecordType.Contains('IFP'))
            lRpType = 04;
        
        lReqMessage = '<?xml version="1.0" encoding="UTF-8"?>' + 
            '<RelatedParty>' + 
            '   <BusFullName>' + String.ValueOf(aDealer.Dealer__r.Name) + '</BusFullName>' + 
            '   <RPAddress1>' + getSubstring(getXMLValue(aDealer.Dealer__r.Business_Address__c),50) + '</RPAddress1>' + 
            '   <RPCity>' + aDealer.Dealer__r.Business_City__c + '</RPCity>' + 
            '   <RPState>' + aDealer.Dealer__r.Business_State__c + '</RPState>' + 
            '   <RPZip>' + getSubstring(getXMLValue(aDealer.Dealer__r.Business_Zip__c),5) + '</RPZip>' + 
            '   <RPFName>' + String.ValueOf(aDealer.Dealer__r.Name).Replace(' ','') + '</RPFName>' + 
            '   <RPLName>' + String.ValueOf(aDealer.Dealer__r.Name).Replace(' ','') + '</RPLName>' + 
            '   <RPPhoneNumber>' + getNumericOnly(aDealer.Dealer__r.Business_Phone__c) + '</RPPhoneNumber>' + 
            '   <RPTaxID>' + getXMLValue(aDealer.Dealer__r.Tax_ID__c) + '</RPTaxID>' +             
            '   <RPType>' + lRpType + '</RPType>' + 
            '</RelatedParty>';          
        
        
        return lReqMessage;
    }  
   
    
    public Static string createRapportValidationMsg(String aCCAN){
        
        String lUserName = System.Label.RapportUser;
        String lPassword = System.Label.RapportPassword;
        String lAlias = System.Label.Rapport_Alias;             
        
        String lReqMessage = '<?xml version="1.0" encoding="UTF-8"?>' + 
            '<ENV:Envelope xmlns:ENV="http://schemas.xmlsoap.org/soap/envelope/">' + 
            '   <ENV:Header />' + 
            '   <ENV:Body>' + 
            '      <DI:SendApplication xmlns:DI="urn:RapportDataImportIntf-IRapportDataImport">' + 
            '         <aApplicationXml>' + 
            '            <RapportDataImport>' + 
            '               <Alias>' + lAlias + '</Alias>' + 
            '               <User>' + 
            '                  <WorklistUser>' + lUserName + '</WorklistUser>' + 
            '                  <Password>' + lPassword + '</Password>' + 
            '               </User>' + 
            '               <SERVICE METHOD="4">' + 
            '                  <OrgNumberRequest>' + 
            '                     <CsReferenceNum>' + Long.ValueOf(getNumericOnly(aCCAN)) + '</CsReferenceNum>' + 
            '                  </OrgNumberRequest>' + 
            '               </SERVICE>' + 
            '            </RapportDataImport>' + 
            '         </aApplicationXml>' + 
            '      </DI:SendApplication>' + 
            '   </ENV:Body>' + 
            '</ENV:Envelope>';          
        
        return lReqMessage;
    }        
    
    
    public Static string createGuarantorMsg(List<Guarantor__c> aGurntList, Map<String,String> aMapPhoneToCCAN){
        
        
        String lGuarMessage = '';
        
        for(Guarantor__c lGurnt : aGurntList)   {
            
            if(lGurnt.Type__c == 'Corporate Guarantor'){
                
                lGuarMessage +=  '<RELATED_PARTY>'+
                    '   <UD_LAST_NAME></UD_LAST_NAME>'+
                    '   <UD_FIRST_NAME></UD_FIRST_NAME>'+
                    '   <CUST_NAME>' + lGurnt.Account__r.Name + '</CUST_NAME>'+
                    '   <FED_ID>' + lGurnt.Account__r.CCAN__c + '</FED_ID>'+
                    '   <ADDR_1>' + getSubstring(getXMLValue(lGurnt.Account__r.Business_Address__c),50) + '</ADDR_1>'+
                    '   <CITY>' + lGurnt.Account__r.Business_City__c + '</CITY>'+
                    '   <STATE>' + lGurnt.Account__r.Business_State__c + '</STATE>'+
                    '   <ZIP>' + getSubstring(getXMLValue(lGurnt.Account__r.Business_Zip__c),5) + '</ZIP>'+
                    '   <RP_PRIN_GUAR_CODE>03</RP_PRIN_GUAR_CODE>'+ 
                    '   <CONTACT_PHONE>' + getNumericOnly(lGurnt.Account__r.Business_Phone__c) + '</CONTACT_PHONE>'+
                    '   <UD_ENTERED_SSN></UD_ENTERED_SSN>'+
                    '   <CCAN>' + (String.IsBlank(lGurnt.Account__r.CCAN__c)? aMapPhoneToCCAN.Get(getNumericOnly(lGurnt.Account__r.Business_Phone__c)) : lGurnt.Account__r.CCAN__c) + '</CCAN>'+
                    '</RELATED_PARTY>';             
                
            }
            else{
                lGuarMessage +=  '<RELATED_PARTY>'+
                    '   <UD_LAST_NAME>' + lGurnt.Contact__r.LastName + '</UD_LAST_NAME>'+
                    '   <UD_FIRST_NAME>' + lGurnt.Contact__r.FirstName + '</UD_FIRST_NAME>'+
                    '   <CUST_NAME>' + lGurnt.Contact__r.Name + '</CUST_NAME>'+
                    '   <FED_ID>' + lGurnt.Contact__r.SSN__c + '</FED_ID>'+
                    '   <ADDR_1>' + getSubstring(getXMLValue(lGurnt.Contact__r.MailingStreet),50) + '</ADDR_1>'+
                    '   <CITY>' + lGurnt.Contact__r.MailingCity + '</CITY>'+
                    '   <STATE>' + lGurnt.Contact__r.MailingStateCode + '</STATE>'+
                    '   <ZIP>' + getSubstring(getXMLValue(lGurnt.Contact__r.MailingPostalCode),5) + '</ZIP>'+
                    '   <RP_PRIN_GUAR_CODE>02</RP_PRIN_GUAR_CODE>'+ 
                    '   <CONTACT_PHONE>' + getNumericOnly(lGurnt.Contact__r.Phone) + '</CONTACT_PHONE>'+
                    '   <UD_ENTERED_SSN>' + lGurnt.Contact__r.SSN__c + '</UD_ENTERED_SSN>'+
                    '   <CCAN>' + Integer.ValueOf(lGurnt.Contact__r.SSN__c) + '</CCAN>'+
                    '</RELATED_PARTY>';             
                
            }
            
            
        }                       
        
        return lGuarMessage;
    }
    
    public Static string createRelatedPartyMsg(List<Dealer__c> aDealerList){
        
        
        String lRelPartyMessage = '';
        String lRpCode = '0';
        
        if(mIsFranchise == true)
            lRpCode = '07';
        else if(mIsIFP == true)
            lRpCode = '04';
        
        for(Dealer__c lDealer : aDealerList)   {
            
            
            lRelPartyMessage +=  '<RELATED_PARTY>'+
                '   <UD_LAST_NAME></UD_LAST_NAME>'+
                '   <UD_FIRST_NAME></UD_FIRST_NAME>'+
                '   <CUST_NAME>' + lDealer.Dealer__r.Name + '</CUST_NAME>'+
                '   <FED_ID>' + getNumericOnly(lDealer.Dealer__r.Business_Phone__c) + '</FED_ID>'+
                '   <ADDR_1>' + getSubstring(getXMLValue(lDealer.Dealer__r.Business_Address__c),50) + '</ADDR_1>'+
                '   <CITY>' + lDealer.Dealer__r.Business_City__c + '</CITY>'+
                '   <STATE>' + lDealer.Dealer__r.Business_State__c + '</STATE>'+
                '   <ZIP>' + getSubstring(getXMLValue(lDealer.Dealer__r.Business_Zip__c),5) + '</ZIP>'+
                '   <RP_PRIN_GUAR_CODE>' + lRpCode + '</RP_PRIN_GUAR_CODE>'+ 
                '   <CONTACT_PHONE>' + getNumericOnly(lDealer.Dealer__r.Business_Phone__c) + '</CONTACT_PHONE>'+
                '   <UD_ENTERED_SSN>' + getNumericOnly(lDealer.Dealer__r.Business_Phone__c) + '</UD_ENTERED_SSN>'+
                '   <CCAN>' + getNumericOnly(lDealer.Dealer__r.Business_Phone__c) + '</CCAN>'+
                '</RELATED_PARTY>';             
            
        }                       
        
        return lRelPartyMessage;
    }    
 
    
    public Static string createAssetsMsg(List<Asset__c> aAssetsList){
        
        String lAssetMessage = '';
        
        for(Asset__c asset : aAssetsList)   {
            //asset = ast;

            lAssetMessage = lAssetMessage +  '<AS>'+
                '   <EQUIP.COST>'+ getXMLValue(asset.Cost__c) + '</EQUIP.COST>'+
                '   <EQUIP.DESC>'+ getSubstring(getXMLValue(asset.Description__c),40) + '</EQUIP.DESC>'+
                '   <EQUIP.CODE>'+ transRapport('Equipment_Code',asset.Equipment_Code__c) + '</EQUIP.CODE>'+ // need mapping
                '   <QUANTITY>'+ getXMLValue(asset.Quantity__c) + '</QUANTITY>'+
                '   <EQUIP.ADDR1>'+ getSubstring(getXMLValue(asset.Equipment_Street__c),30) + '</EQUIP.ADDR1>'+
                '   <EQUIP.CITY>'+ getXMLValue(asset.Equipment_City__c) + '</EQUIP.CITY>'+
                '   <EQUIP.STATE>'+ getXMLValue(asset.Equipment_State__c) + '</EQUIP.STATE>'+
                '   <EQUIP.ZIP>'+ getSubstring(getXMLValue(asset.Equipment_Zip__c),5) + '</EQUIP.ZIP>'+
                '   <EQUIP.ADDR2></EQUIP.ADDR2>'+
                '   <MODEL>'+ getXMLValue(asset.Model__c) + '</MODEL>'+
                '   <AUM.ALPHA.FIELD4>' + getXMLValue(asset.Vehicle_Type__c) + '</AUM.ALPHA.FIELD4>'+
                '	<AUM.ALPHA.FIELD5>' +getXMLValue(asset.Mileage__c) + '</AUM.ALPHA.FIELD5>'+
                '	<NEW.USED>' + transRapport('new_used',asset.New_Used__c) + '</NEW.USED>'+
                '	<AUM.ALPHA.FIELD7>' + getXMLValue(asset.Sleeper_Day_Cab__c) + '</AUM.ALPHA.FIELD7>'+
                '	<UD_VEH_MAKE>' + getXMLValue(asset.Vehicle_Make__c)  + '</UD_VEH_MAKE>' +
                '	<A.MANUFACTURER.YEAR>' + getXMLValue(asset.Vehicle_year__c) + '</A.MANUFACTURER.YEAR>' +
                '   <SERIAL.NUMBER>'+ getXMLValue(asset.Serial_Number__c) + '</SERIAL.NUMBER>'+
                '</AS>';               
            
        }     
        system.debug('lAssetMessage---- '+lAssetMessage);
        return lAssetMessage;
    }  
    
    
    public Static string createVPMsg(List<Variable_Payment__c> aVPList){
        
        String lVPMessage = '';
        
        for(Variable_Payment__c vp : aVPList)   {
            //asset = ast;
            
            lVPMessage = lVPMessage +  '<VP>'+
                '   <VARIABLE.DATE>'+ getXMLValue(vp.of_payments__c) + '</VARIABLE.DATE>'+
                '   <VARIABLE.RATE>'+ getXMLValue(vp.Payment_Amount__c) + '</VARIABLE.RATE>'+
                '   <UD_TOTAL_VP>'+ getXMLValue(vp.Total__c) + '</UD_TOTAL_VP>'+
                '</VP>';                
            
        }     
        
        return lVPMessage;
    }  
    
    public Static string createPointMsg(Decimal aPoint, Decimal aEqipmentCost){
        
        String lPaymentMessage = '';
        
        if(aPoint != null && aEqipmentCost != null && aPoint > 0 && aEqipmentCost > 0)   {
            Decimal lPointAmount = (aPoint * aEqipmentCost)/100;
            lPaymentMessage = lPaymentMessage +  '<Mrln_Points>'+
                '   <UD_PTS_AMOUNT>'+ String.ValueOf(lPointAmount.setScale(2)) + '</UD_PTS_AMOUNT>'+
                '</Mrln_Points>';               
            
        }     
        
        return lPaymentMessage;
    }  
    
    
    /**************************************************/
    //Rapport Calls Orchestration Service to validate and create guarantors
    /**************************************************/
    Public static String ValidateAndCreateGuarantors(String aOpptyId, List<Guarantor__c> aGurntList,String aCreateFlag, Map<String,Map<String,String>> lInfoleaseCalloutMaps)
    {
        
        String lQueryRapportException = 'N';
        String lInfoleaeseException = 'N';
        Set<String> lCCANExistsInRapport = new Set<STring>();
        Set<String> lCCANNotExistsInRapport = new Set<STring>();        
        Map<String,String> lValidationCalloutMap = new Map<String,String>();
        Map<String,Map<String,String>> lValidationCalloutMaps = new  Map<String,Map<String,String>>();
        Map<String,String> lInfoleaseCalloutMap = new Map<String,String>();
       Map<String,String> lCorpGCCANMap = new  Map<String,String>();        
        String lInfoLeaseResponse = '';
        String lCCANForRapportValidation = '';
        
        // Validate Guarantors in Rapport   
        for(Guarantor__c lGurnt : aGurntList)   {
            
            if(aCreateFlag == 'N' && lGurnt.Type__c != 'Personal Guarantor')
                continue;
            
            lCCANForRapportValidation = lGurnt.Type__c == 'Personal Guarantor' ? lGurnt.Contact__r.SSN__c : lGurnt.Account__r.Business_Phone__c;
            
            if(String.IsBlank(lCCANForRapportValidation)){
                System.Debug('Rapport Validation Request:' + lCCANForRapportValidation);
                return 'Error Message: Missing ' +  (lGurnt.Type__c == 'Personal Guarantor' ? 'SSN' : 'Business Phone') + ' for ' + lGurnt.Type__c + ' ' + (lGurnt.Type__c == 'Personal Guarantor' ? lGurnt.Contact__r.Name : lGurnt.Account__r.Name);  
            }
            
            
            System.Debug('Rapport Validation Request:' + lCCANForRapportValidation);            
            lValidationCalloutMap = MARLIN_RapportCallout.validateGuarantorInRapport(lCCANForRapportValidation);
            System.Debug('Validation Result:' + lValidationCalloutMap);
            lValidationCalloutMaps.Put(lCCANForRapportValidation,lValidationCalloutMap);           
            System.Debug('Rapport Validation Response:' + lCCANForRapportValidation);
            
            if(lValidationCalloutMap.Get('STATUS') == 'OK')
                lCCANExistsInRapport.Add(lCCANForRapportValidation);
            else if(lValidationCalloutMap.Get('STATUS') == 'KO' && lValidationCalloutMap.Get('EXCEPTION') == 'N')
                lCCANNotExistsInRapport.Add(lCCANForRapportValidation);
            else{
                lQueryRapportException = 'Y';
                break;
            }
            
            
        }  
        
        if(lQueryRapportException == 'Y')  {
            Marlin_IntegrationLog.LogException('Rapport Validation API',aOpptyId, 'Error', JSON.serialize(lValidationCalloutMaps), '', '500', lValidationCalloutMap.Get('EXCEPTIONMSG'));
            return 'Error Message: ' + lValidationCalloutMap.Get('EXCEPTIONMSG');           
            
        }
        
        System.Debug('Rapport Validation CCAN Not exists: ' + lCCANNotExistsInRapport);
        System.Debug('Rapport Validation ends here');
        
        if(aCreateFlag == 'N' && lCCANNotExistsInRapport.Size() == 0)
            return 'Success';
        else if(aCreateFlag == 'N' && lCCANNotExistsInRapport.Size() > 0)
            return 'Fail';
        
        System.Debug('Infolease Call starts here');
        
        // Call InfoLease Script to add guarantor in Infolease
        for(Guarantor__c lGurnt : aGurntList)   {
            
            //   if(lGurnt.Type__c != 'Personal Guarantor')
            //       continue;
            lCCANForRapportValidation = lGurnt.Type__c == 'Personal Guarantor' ? lGurnt.Contact__r.SSN__c : lGurnt.Account__r.Business_Phone__c;
            if(lCCANExistsInRapport.Contains(lCCANForRapportValidation))    
                continue;
            
            // call Infolease Service
            lInfoleaseCalloutMap = MARLIN_RapportCallout.sendRPToInfolease(createInfoleaseRequestMsg(lGurnt,lGurnt.Type__c),lCCANForRapportValidation);   
            //   lInfoleaseCalloutMap = MARLIN_RapportCallout.sendGuarantorToInfolease(lGurnt);    
            lInfoleaseCalloutMaps.Put(lCCANForRapportValidation,lInfoleaseCalloutMap);
            System.Debug('InfoLease Add Response:' + lInfoLeaseResponse);   
 
            if(lGurnt.Type__c != 'Personal Guarantor' && lInfoleaseCalloutMap.Get('STATUS') == 'OK'){
                lCorpGCCANMap.Put(lGurnt.Account__c,lInfoleaseCalloutMap.Get('CCANID'));
                if(lInfoleaseCalloutMap.Get('CCANID') == 'ERROR'){
                    lInfoleaeseException = 'Y';
                	break;                    
                }

            }	
            
            
            if(lInfoleaseCalloutMap.Get('STATUS') == 'KO'){
                lInfoleaeseException = 'Y';
                break;
            }
            
            
        }  
        
        // update Corporate Guarantor CCAN in Salesforce
 /*       List<Account> accListToUpdate = new List<Account>();
        for(String accId : lCorpGCCANMap.keySet()){
            if(!String.IsBlank(lCorpGCCANMap.Get(accId)))
            	accListToUpdate.add(new account(Id=accId,CCAN__c=lCorpGCCANMap.Get(accId)));
        }
        //updated value from 0 to 20 for debugging
        if(accListToUpdate.size() > 20)
            update accListToUpdate;
        */
        
        if(lInfoleaeseException == 'Y')  {
            Marlin_IntegrationLog.LogException('Infolease API',aOpptyId, 'Error', JSON.serialize(lInfoleaseCalloutMaps), '', '500', lInfoleaseCalloutMap.Get('EXCEPTIONMSG'));
            return 'Error Message: ' + lInfoleaseCalloutMap.Get('EXCEPTIONMSG');            
            
        }                   
        
        //    Marlin_IntegrationLog.LogException('Rapport Validation API',aOpptyId, 'Success', JSON.serialize(lValidationCalloutMaps), '', '200', 'OK');
        return 'Success';
        
        
    }  
    
    
    Public static String ValidateAndCreateRelatedParty(String aOpptyId, String aOpptyRecordType, List<Dealer__c> aDealerList, String aCreateFlag)
    {
        
        String lQueryRapportException = 'N';
        String lInfoleaeseException = 'N';
        Set<String> lCCANExistsInRapport = new Set<STring>();
        Set<String> lCCANNotExistsInRapport = new Set<STring>();        
        Map<String,String> lValidationCalloutMap = new Map<String,String>();
        Map<String,Map<String,String>> lValidationCalloutMaps = new  Map<String,Map<String,String>>();
        Map<String,String> lInfoleaseCalloutMap = new Map<String,String>();
        Map<String,Map<String,String>> lInfoleaseCalloutMaps = new  Map<String,Map<String,String>>();        
        String lInfoLeaseResponse = '';
        
        // Validate Guarantors in Rapport   
        for(Dealer__c lDealer : aDealerList)   {
            
            if(String.IsBlank(lDealer.Dealer__r.Business_Phone__c)){
                System.Debug('Rapport Validation Request:' + lDealer.Dealer__r.Business_Phone__c);
                return 'Error Message: Missing Business Phone for Dealer: ' + lDealer.Dealer__r.Name;   
            }           
            
            System.Debug(' Rapport Validation Request:' + lDealer.Dealer__r.Business_Phone__c);           
            lValidationCalloutMap = MARLIN_RapportCallout.validateGuarantorInRapport(lDealer.Dealer__r.Business_Phone__c);
            System.Debug('Franchisor Validation Result:' + lValidationCalloutMap);
            lValidationCalloutMaps.Put(lDealer.Dealer__r.Business_Phone__c,lValidationCalloutMap);           
            System.Debug(' Rapport Validation Response:' + lDealer.Dealer__r.Business_Phone__c);
            
            if(lValidationCalloutMap.Get('STATUS') == 'OK')
                lCCANExistsInRapport.Add(lDealer.Dealer__r.Business_Phone__c);
            else if(lValidationCalloutMap.Get('STATUS') == 'KO' && lValidationCalloutMap.Get('EXCEPTION') == 'N')
                lCCANNotExistsInRapport.Add(lDealer.Dealer__r.Business_Phone__c);
            else{
                lQueryRapportException = 'Y';
                break;
            }
            
            
        }  
        
        if(lQueryRapportException == 'Y')  {
            Marlin_IntegrationLog.LogException('Rapport Validation API',aOpptyId, 'Error', JSON.serialize(lValidationCalloutMaps), '', '500', lValidationCalloutMap.Get('EXCEPTIONMSG'));
            return 'Error Message: ' + lValidationCalloutMap.Get('EXCEPTIONMSG');           
            
        }
        
        System.Debug(' Rapport Validation CCAN Not exists: ' + lCCANNotExistsInRapport);
        System.Debug(' Rapport Validation ends here');
        
        if(aCreateFlag == 'N' && lCCANNotExistsInRapport.Size() == 0)
            return 'Success';
        else if(aCreateFlag == 'N' && lCCANNotExistsInRapport.Size() > 0)
            return 'Fail';
        
        System.Debug('Infolease Call starts here');
        
        // Call InfoLease Script to add delaer as related party in Infolease/rapport
        for(Dealer__c lDealer : aDealerList)   {
            
            if(lCCANExistsInRapport.Contains(lDealer.Dealer__r.Business_Phone__c))  
                continue;
            
            // call Infolease Service
            lInfoleaseCalloutMap = MARLIN_RapportCallout.sendRPToInfolease(createInfoleaseRequestMsg(lDealer,aOpptyRecordType),String.ValueOf(lDealer.Dealer__r.Business_Phone__c));   
            lInfoleaseCalloutMaps.Put(lDealer.Dealer__r.Business_Phone__c,lInfoleaseCalloutMap);
            System.Debug('InfoLease Add Response:' + lInfoLeaseResponse);   
            
            if(lInfoleaseCalloutMap.Get('STATUS') == 'KO'){
                lInfoleaeseException = 'Y';
                break;
            }
            
            
        }   
        
        if(lInfoleaeseException == 'Y')  {
            Marlin_IntegrationLog.LogException('Infolease API',aOpptyId, 'Error', JSON.serialize(lInfoleaseCalloutMaps), '', '500', lInfoleaseCalloutMap.Get('EXCEPTIONMSG'));
            return 'Error Message: ' + lInfoleaseCalloutMap.Get('EXCEPTIONMSG');            
            
        }                   
        
        Marlin_IntegrationLog.LogException('Rapport Validation API',aOpptyId, 'Success', JSON.serialize(lValidationCalloutMaps), '', '200', 'OK');
        return 'Success';
        
        
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
        
        return 'ERROR';
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
            return String.valueOf(dtArgVal.format(formatString));
        }
        
        return '';
    }    
    
    public static String getTimeReceivedString() {
        
        if(rapportMaps.Size() == 0)
            buildRapportMap();
        
        Integer hours = Integer.ValueOf((System.now().Format('HH')));
        Integer minutes = Integer.ValueOf((System.now().Format('mm')));
        String minutesString = '';
        String timeReceived = '';
        
        if(minutes > 45)
            minutesString = '45';
        else if(minutes > 30)
            minutesString = '30';
        else if(minutes > 15)
            minutesString = '15';
        else if(minutes > 0)
            minutesString = '00';   
        
        System.Debug(String.ValueOf(hours) + ':' + minutesString);
        //  System.Debug(rapportMaps);  
        timeReceived = rapportMaps.Get('UD_TIMERECEIVED' + '__' + String.ValueOf(hours) + ':' + minutesString);                 
        
        if(String.IsBlank(timeReceived))
            return '';
        else
            return timeReceived;
    }    
  
  // To update CCAN for corporate guarantor
  public static String updateCCANOfCG(String aOpptyId, Map<String,String> aMapPhoneToCCAN) {

      String accountId = '';
      String ccanId = '';
      
      if(aMapPhoneToCCAN.size() == 0)
          return 'OK';
      
      Opportunity optyList = [select id, 
                                (Select Id,Account__c,Type__c,
                                 Account__r.Id, Account__r.CCAN__c,Account__r.Business_Phone__c   
                                 from Guarantor__r)
                                from Opportunity where Id =:aOpptyId ];  
      
      List<Account> accListToUpdate = new List<Account>();
      
      for(Guarantor__c grnt : optyList.Guarantor__r){
          
          if(grnt.Type__c == 'Personal Guarantor')
             continue;
          
          if(!String.IsBlank(grnt.Account__r.CCAN__c))
              continue;
          
          accountId = grnt.Account__r.Id;
          ccanId = aMapPhoneToCCAN.Get(getNumericOnly(grnt.Account__r.Business_Phone__c));
          
          if(!(String.IsBlank(accountId) || String.IsBlank(ccanId)))
          	accListToUpdate.add(new account(Id=accountId,CCAN__c=ccanId));
          
      }
      
      if(accListToUpdate.size() > 0)
          update accListToUpdate;   
      
      return 'OK';
  }
    
}