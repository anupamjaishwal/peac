public class PEAC_BuyoutComparisonController {
    
    public List<FieldWrapper> fields{get;set;}
    public integer maxRecSize {get; set;}
    public Contract__c ContractRec {get; set;}
    public Double totalAmt {get; set;}
    public Date next30Days {get; set;}
    public string action {get; set;}
    Set<String> labels = new Set<String>();
    public Double buyoutreceivableTotal = 0;
    public Double upreceivableTotal = 0;
    public Double returnoutreceivableTotal = 0;
    public final Integer COLUMN_MAX = 4;
    public List<Buyout__c> Buyouts {get; set;}
    public integer Buyoutssize {get; set;}
    public String logoResourceName { get; set; }
    public List<FieldWrapper> fieldsBuyoutLetter{get;set;}
    public boolean hidePDF { get; set; }
    public String serialNumbers { get; set; }
    public boolean isPartialChecked { get; set; }
    
    
    public PEAC_BuyoutComparisonController(){
        hidePDF = true;
        next30Days = system.today().addDays(30);
        // this.setFields(ApexPages.currentPage().getParameters().get('rows'));
        // if(this.fields.size() > 0 && this.fields[0].Rows.size() > 0){
        //      maxRecSize = this.fields[0].Rows.size();
        // }
        
        String recId = ApexPages.currentPage().getParameters().get('recId');
        // String rows = ApexPages.currentPage().getParameters().get('rows');
        this.setLogoResource(recId);
        if(recId <> null) {
            ContractRec = [SELECT Id, Customer__r.Name,Logo__c,PO__c, Invoice_Description__c, Remit_To_Address__c, Remit_To_City__c,Remit_To_State__c,Remit_To_Zip_Code__c, Name, Opportunity__r.Purchase_Options__c, Commencement_Date__c, Payments_Remaining__c, Contract_Term__c, Gross_Equipment_Cost__c, Payment_Amount__c, Current_Rental_Payment__c, Next_Payment_Date__c, Quote_Buyout__c FROM Contract__c WHERE Id = :recId];
            Buyouts = [SELECT Buyout_Type__c, Contract__c, Buyout_Description__c, Buyout_Amount__c, Most_Recent__c, Receivable_Balance__c, Residual__c, SalesTax__c, LateCharges__c, Early_Termination_Fee__c, Security_Deposit__c, Ending_Deposit__c, Service_pass_through__c, Property_tax__c, Insurance__c, Other_Lease_Charges__c, Total_Buyout__c, Partial_Buyout__c, Date_Quoted__c, Expiration_Date__c, Id, Name FROM Buyout__c WHERE Contract__c = :recId AND Most_Recent__c = true order by Quote_Sequence__c];
            for(Buyout__c buyout : Buyouts) {
                if(buyout.Partial_Buyout__c) {
                    isPartialChecked = true;
                    break;
                }
            }
            //Buyouts = (List<pEAC_BuyOutController.BuyoutWrapper>)JSON.deserialize(rows,List<pEAC_BuyOutController.BuyoutWrapper>.class); 
            Buyout__c thisBuyout;
            Set<String> serialNumberSet = new Set<String>();
            
            if(Buyouts.size() > 0) {
                thisBuyout = Buyouts.get(0);
                if(thisBuyout.Partial_Buyout__c) {
                    for(Buyout_Asset__c buyoutAsset : [select Id, Contract_Asset_Serial_Number__c from Buyout_Asset__c where Buyout__c IN : Buyouts]) {
                        if(buyoutAsset.Contract_Asset_Serial_Number__c != null) {
                            serialNumberSet.add(buyoutAsset.Contract_Asset_Serial_Number__c);
                            // serialNumbers = serialNumbers != null ? serialNumbers + ', ' + buyoutAsset.Contract_Asset_Serial_Number__c : buyoutAsset.Contract_Asset_Serial_Number__c;
                        }
                    }
                } else {
                    Date buyoutDate; 
                    buyoutDate =thisBuyout.Date_Quoted__c;
                    for(Contract_Asset__c contractAsset : [select Id, Serial_Number__c,Asset_Cost__c from Contract_Asset__c where Contract__c =: recId AND (Asset_Disposed_Date__c = null OR Asset_Disposed_Date__c > :buyoutDate ) AND Asset_Cost__c > 0]) {
                        if(contractAsset.Serial_Number__c != null) {
                            serialNumberSet.add(contractAsset.Serial_Number__c);
                            
                            //serialNumbers = serialNumbers != null ? serialNumbers + ', ' + contractAsset.Serial_Number__c : contractAsset.Serial_Number__c;
                            
                        }
                        
                    }
                }
                serialNumbers = String.join(serialNumberSet, ', ');
                Buyoutssize = Buyouts.size();
                maxRecSize = Buyoutssize;
                hidePDF = Buyoutssize > 4 || Buyoutssize == 1 ;
                integer recSize = Buyoutssize;
                System.debug('Buyoutssize '+Buyoutssize);
                while(recSize < COLUMN_MAX ){
                    System.debug('recSize '+recSize);
                    Buyouts.add(new Buyout__c());
                    recSize++;
                }
                
            } 
            List<FieldWrapper> allFields = new List<FieldWrapper>();
            String defaultZero = '0';
            allFields.add(new FieldWrapper('Receivable Balance', defaultZero, true, false));
            allFields.add(new FieldWrapper('Residual', defaultZero, true, false));
            allFields.add(new FieldWrapper('Sales Tax', defaultZero, true, false));
            allFields.add(new FieldWrapper('Late Charges', defaultZero, true, false));
            allFields.add(new FieldWrapper('Early Termination Fee', defaultZero, true, false));
            allFields.add(new FieldWrapper('Security Deposit', defaultZero, true, false));
            allFields.add(new FieldWrapper('Ending Deposit', defaultZero, true, false));
            allFields.add(new FieldWrapper('Pass Through', defaultZero, true, false));
            allFields.add(new FieldWrapper('Property Tax', defaultZero, true, false));
            allFields.add(new FieldWrapper('Insurance', defaultZero, true, false));
            allFields.add(new FieldWrapper('Other Lease Charges', defaultZero, true, false));
            allFields.add(new FieldWrapper('Total Buyout', defaultZero, true, false));
            for(FieldWrapper fw:allFields){
                fw.rows = new List<buyoutrows>();
                for(Integer colIndex = 0; colIndex < Buyoutssize; colIndex++){
                    fw.rows.add(new buyoutrows());
                }
            }
            for(Integer colIndex = 0; colIndex < Buyoutssize; colIndex++){
                if(Buyouts.size() > colIndex){
                    if(colIndex == 0){
                        
                        allFields[0].value = Buyouts[colIndex].Receivable_Balance__c;
                        allFields[1].value = Buyouts[colIndex].Residual__c;
                        allFields[2].value = Buyouts[colIndex].SalesTax__c;
                        allFields[3].value = Buyouts[colIndex].LateCharges__c;
                        allFields[4].value = Buyouts[colIndex].Early_Termination_Fee__c;
                        allFields[5].value = Buyouts[colIndex].Security_Deposit__c;
                        allFields[6].value = Buyouts[colIndex].Ending_Deposit__c;
                        allFields[7].value = Buyouts[colIndex].Service_pass_through__c;
                        allFields[8].value = Buyouts[colIndex].Property_tax__c;
                        allFields[9].value = Buyouts[colIndex].Insurance__c;
                        allFields[10].value = Buyouts[colIndex].Other_Lease_Charges__c;
                        allFields[11].value = Buyouts[colIndex].Total_Buyout__c;
                    }else{
                        
                        allFields[0].rows[colIndex].value = Buyouts[colIndex].Receivable_Balance__c;
                        allFields[1].rows[colIndex].value = Buyouts[colIndex].Residual__c;
                        allFields[2].rows[colIndex].value = Buyouts[colIndex].SalesTax__c;
                        allFields[3].rows[colIndex].value = Buyouts[colIndex].LateCharges__c;
                        allFields[4].rows[colIndex].value = Buyouts[colIndex].Early_Termination_Fee__c;
                        allFields[5].rows[colIndex].value = Buyouts[colIndex].Security_Deposit__c;
                        allFields[6].rows[colIndex].value = Buyouts[colIndex].Ending_Deposit__c;
                        allFields[7].rows[colIndex].value = Buyouts[colIndex].Service_pass_through__c;
                        allFields[8].rows[colIndex].value = Buyouts[colIndex].Property_tax__c;
                        allFields[9].rows[colIndex].value = Buyouts[colIndex].Insurance__c;
                        allFields[10].rows[colIndex].value = Buyouts[colIndex].Other_Lease_Charges__c;
                        allFields[11].rows[colIndex].value = Buyouts[colIndex].Total_Buyout__c; 
                    }
                }
            }
            this.fields = allFields;
            //action = ApexPages.currentPage().getParameters().get('action');
            //if(action <> null){
            for(Buyout_letter_table_fields__mdt buyLetter : [SELECT Id, TableLabel__c FROM Buyout_letter_table_fields__mdt]){
                labels.add(buyLetter.TableLabel__c);
            }
            fieldsBuyoutLetter = new List<FieldWrapper>();
            for(FieldWrapper field1 : this.fields){
                if(labels.contains(field1.Label)){
                    fieldsBuyoutLetter.add(field1);
                }
            }
        } 
        
        
        //}
    }
    
    public void setLogoResource(String recId) {
        Contract__c thisContract = [
            SELECT Program__c
            FROM Contract__c
            WHERE Id = :recId
        ];
        
        if (thisContract.Program__c != null && thisContract.Program__c.contains('XBS')) {
            logoResourceName = 'XBSLogo';
        } else if (thisContract.Program__c != null && thisContract.Program__c.contains('Is_Blind__c')){
            logoResourceName = 'LeaseServicesLogo';
        } else {
            logoResourceName = 'PeacSolutionsLogo';
        }
    }
    
    public String getLogoResourceName() {
        return logoResourceName;
    }
    
    public class buyoutrows{
        public Double value {get; set;}
        // public String QuoteSeq {get; set;}
    }
    public class FieldWrapper{
        public String label{get;set;}
        public Double value{get;set;}
        public Boolean isCurrency{get;set;}
        public Boolean isPlain{get;set;}
        public List<buyoutrows> rows{get; set;}
        public FieldWrapper(String label, String value, Boolean isCurrency, Boolean isPlain){
            this.label = label;
            this.value = Double.valueof(value);
            this.isCurrency = isCurrency;
            this.isPlain = isPlain;
        }
        public FieldWrapper(){}
    }
}