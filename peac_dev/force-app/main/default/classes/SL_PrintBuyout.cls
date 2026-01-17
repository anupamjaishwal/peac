public with sharing class SL_PrintBuyout {
    public List<FieldWrapper> headers{get;set;}
    public List<FieldWrapper> fields{get;set;}
    public Contract__c thisContract{get;set;}
    public string logoResourceName{get;set;}
    public string serialNumbers{get;set;}
    public boolean showAddress{get;set;}

    public void setHeaders(String contractId, string quoteSeq){
        System.debug('contractId::'+contractId);
        System.debug('quoteSeq::'+quoteSeq);
        List<FieldWrapper> allHeaders = new List<FieldWrapper>();
        thisContract = [SELECT Name, Customer__r.Name, AR_Address_1__c, 
                                    AR_Address_2__c, AR_Address_3__c, AR_City__c, Program__c,Is_Blind__c,IsXBS__c,
                                    AR_State__c,AR_Zip_Code__c ,Remit_To_City__c,Remit_To_Address__c,Remit_To_State__c,Remit_To_Zip_Code__c
                                    FROM Contract__c 
                                    WHERE Id =:contractId 
                                    LIMIT 1];
        String addressString = thisContract.AR_Address_1__c +' '+ 
                                thisContract.AR_Address_2__c +' '+ 
                                thisContract.AR_Address_3__c +' \n'+
                                thisContract.AR_City__c +', '+ 
                                thisContract.AR_State__c +' '+ 
                                thisContract.AR_Zip_Code__c;
        allHeaders.add(new FieldWrapper('Contract#', thisContract.Name, false, true));
        allHeaders.add(new FieldWrapper('Customer Name', thisContract.Customer__r.Name, false, true));
        allHeaders.add(new FieldWrapper('Customer Address', addressString.replaceAll('null', ''), false, true));
		if (thisContract.Program__c != null && thisContract.Program__c.contains('XBS')) {
            logoResourceName = 'XBSLogo';
        } else if(thisContract.Is_Blind__c == true){
            logoResourceName = 'LeaseServicesLogo';
        } else if(thisContract.Is_Blind__c == false && thisContract.IsXBS__c == false) {    
            logoResourceName ='PeacSolutionsLogo';
        } 
        if(quoteSeq != null) {
            List<Buyout__c> thisBuyoutList = [select Id,Name,Partial_Buyout__c, Date_Quoted__c, CreatedDate FROM Buyout__c WHERE Quote_Sequence__c = :quoteSeq AND Contract__c =: contractId];
            if(thisBuyoutList.size() > 0) {
                Buyout__c thisBuyout = thisBuyoutList.get(0);
                allHeaders.add(new FieldWrapper('Buyout Type', thisBuyout.Name, false, true));
                
                showAddress = true;
                for(ExcludeRemitToAddressOnBuyoutPDFS__mdt excludeConfig : [select Id, BuyoutType__c from ExcludeRemitToAddressOnBuyoutPDFS__mdt]) {
                    if(thisBuyout.Name.contains(excludeConfig.BuyoutType__c)) {
                        showAddress = false;
                        break;
                    }
                }
                System.debug('ThisBuyout::'+thisBuyout);
                // SL-2644 Misael Romero
                for(Buyout_Asset__c buyoutAsset : [SELECT Id, Contract_Asset_Serial_Number__c, Contract_Asset__r.Asset_Disposed_Date__c 
                    FROM Buyout_Asset__c 
                    WHERE Buyout__c =: thisBuyout.Id]) {
                    if(buyoutAsset.Contract_Asset_Serial_Number__c != null) {
                        serialNumbers = serialNumbers != null ? serialNumbers + ', ' + buyoutAsset.Contract_Asset_Serial_Number__c : buyoutAsset.Contract_Asset_Serial_Number__c;
                    }
                }
            }
            
        }
        
        this.headers = allHeaders;
    }

    public List<FieldWrapper> getHeaders(){
        return this.headers;
    }

    public void setFields(String incoming, String contractId){
        List<FieldWrapper> allFieldsTemp = new List<FieldWrapper>();
        List<FieldWrapper> allFields = new List<FieldWrapper>();
        JSONParser parser = JSON.createParser(incoming);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        FieldWrapper aField = (FieldWrapper)parser.readValueAs(FieldWrapper.class);

                        allFieldsTemp.add(aField);
                    }
                }
            }
        }
        for(FieldWrapper thisField: allFieldsTemp){
            System.debug('thisField::'+thisField.label);
            if (thisField.label == 'Total Buyout' ) {
                allFields.add(new FieldWrapper('Total Buyout', thisField.value, true, false));
            } 
            if (thisField.label == 'Expiration Date' ) {
                allFields.add(new FieldWrapper('Expiration Date', thisField.value, false, true));
            }
            if (thisField.label == 'Equipment Description' ) {
                allFields.add(new FieldWrapper('Equipment Description', thisField.value, false, true));
            }
            
            // allFields.add(new FieldWrapper('Expiration Date', String.valueOf(thisContract.Insurance_Expiration_Date__c), false, true));
        }
        
        this.fields = allFields;
    }
    public List<FieldWrapper> getFields(){
        return this.fields;
    }

    public SL_PrintBuyout(){
        this.setFields(ApexPages.currentPage().getParameters().get('rows'), ApexPages.currentPage().getParameters().get('contractId'));
        this.setHeaders(ApexPages.currentPage().getParameters().get('contractId'),ApexPages.currentPage().getParameters().get('quoteSeq'));
    }
    
    public class FieldWrapper{
        public String label{get;set;}
        public String value{get;set;}
        public Boolean isCurrency{get;set;}
        public Boolean isPlain{get;set;}
        public FieldWrapper(String label, String value, Boolean isCurrency, Boolean isPlain){
            this.label = label;
            this.value = value;
            this.isCurrency = isCurrency;
            this.isPlain = isPlain;
        }
    }
    
}