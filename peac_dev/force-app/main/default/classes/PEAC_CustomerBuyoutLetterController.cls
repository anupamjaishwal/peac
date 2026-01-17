public class PEAC_CustomerBuyoutLetterController {
    
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
    public String serialNumbers { get; set; }
    public List<FieldWrapper> fieldsBuyoutLetter{get;set;}
    public Boolean isFound {get;set;}
    public Buyout__c Buyout {get; set;}
    public String phoneNumber { get; set; }
    public Boolean showAddress {get;set;}
    

    public PEAC_CustomerBuyoutLetterController(){
        
        next30Days = system.today().addDays(30);
        // this.setFields(ApexPages.currentPage().getParameters().get('rows'));
        // if(this.fields.size() > 0 && this.fields[0].Rows.size() > 0){
        //      maxRecSize = this.fields[0].Rows.size();
        // }
        
        String recId = ApexPages.currentPage().getParameters().get('recId');
        String source;
        if(ApexPages.currentPage().getParameters().get('sourceName') != null) {
            source = ApexPages.currentPage().getParameters().get('sourceName');
        }
        this.setLogoResource(recId);
        //Buyout__c buyout = new Buyout__c();
        List<string> orderList = new List<string>{'Buyout','Buyout to Return','Customer Buyout to Return','Customer Buyout to Keep','Customer Buyout to Return : No PTax','Customer Buyout to Keep : No PTax'};
        if(recId <> null) {
            ContractRec = [SELECT Id, Customer__r.Name,Logo__c,PO__c, Invoice_Description__c, Remit_To_Address__c, Remit_To_City__c,Remit_To_State__c,Remit_To_Zip_Code__c, Name, Opportunity__r.Purchase_Options__c, Commencement_Date__c, Payments_Remaining__c, Contract_Term__c, Gross_Equipment_Cost__c, Payment_Amount__c, Current_Rental_Payment__c, Next_Payment_Date__c, Quote_Buyout__c FROM Contract__c WHERE Id = :recId];
            List<Buyout__c> buyoutList = new List<Buyout__c>();
            if(source != null && source == 'Customer_Letter_SC') {
                string quoteSeq = ApexPages.currentPage().getParameters().get('quoteSeq');
                buyoutList = [SELECT Buyout_Type__c, Contract__c, Buyout_Description__c, Buyout_Amount__c, Most_Recent__c, Receivable_Balance__c, Residual__c, 
                    SalesTax__c, LateCharges__c, Early_Termination_Fee__c, Security_Deposit__c, Ending_Deposit__c, Service_pass_through__c, 
                    Property_tax__c, Insurance__c, Other_Lease_Charges__c, Total_Buyout__c, Partial_Buyout__c, Date_Quoted__c, 
                    Expiration_Date__c, Id,Quote_Sequence__c, Name, Service_Included__c, Service_Other__c  
                    FROM Buyout__c WHERE Quote_Sequence__c = :quoteSeq AND Contract__c =:recId];
                if(!(buyoutList.size() > 0)) {
                    isFound = false;
                    return;
                }
                buyout = buyoutList.get(0);
                isFound = true;
                if(buyoutList.size() > 0){
                    totalAmt = buyout.Total_Buyout__c;
                }
            } else if(source != null && source == 'Customer_Letter_DP') {
                string buyoutId = ApexPages.currentPage().getParameters().get('buyoutId');
                buyoutList = [SELECT Buyout_Type__c, Contract__c, Buyout_Description__c, Buyout_Amount__c, Most_Recent__c, Receivable_Balance__c, Residual__c, 
                    SalesTax__c, LateCharges__c, Early_Termination_Fee__c, Security_Deposit__c, Ending_Deposit__c, Service_pass_through__c, 
                    Property_tax__c, Insurance__c, Other_Lease_Charges__c, Total_Buyout__c, Partial_Buyout__c, Date_Quoted__c, 
                    Expiration_Date__c, Id,Quote_Sequence__c, Name, Service_Included__c, Service_Other__c 
                    FROM Buyout__c WHERE Id = :buyoutId];
            	if(!(buyoutList.size() > 0)) {
                    isFound = false;
                    return;
                }
                buyout = buyoutList.get(0);
                isFound = true;
                if(buyoutList.size() > 0){
                    totalAmt = buyout.Total_Buyout__c;
                }
            } else {
                Buyouts = [SELECT Buyout_Type__c, Contract__c, Buyout_Description__c, Buyout_Amount__c, Most_Recent__c, Receivable_Balance__c, Residual__c, 
                    SalesTax__c, LateCharges__c, Early_Termination_Fee__c, Security_Deposit__c, Ending_Deposit__c, Service_pass_through__c, 
                    Property_tax__c, Insurance__c, Other_Lease_Charges__c, Total_Buyout__c, Partial_Buyout__c, Date_Quoted__c, 
                    Expiration_Date__c, Id,Quote_Sequence__c, Name, Service_Included__c, Service_Other__c 
                    FROM Buyout__c WHERE Contract__c = :recId AND Most_Recent_DP__c = true order by Name];
                isFound = false;
                for(string str : orderList) {
                    for(Buyout__c buy : Buyouts) {
                        if(buy.Name == str) {
                            buyout = buy;
                            isFound = true;
                            break;
                        }
                    }
                    if(isFound) {
                        break;
                    }
                }
                if(Buyouts.size() > 0){
                    totalAmt = buyout.Total_Buyout__c;
                }
            }
            
        }
        if(buyout.Partial_Buyout__c) {
            for(Buyout_Asset__c buyoutAsset : [SELECT Id, Contract_Asset_Serial_Number__c FROM Buyout_Asset__c where Buyout__c =: buyout.Id]) {
                if(buyoutAsset.Contract_Asset_Serial_Number__c != null) {
                    serialNumbers = serialNumbers != null ? serialNumbers + ', ' + buyoutAsset.Contract_Asset_Serial_Number__c : buyoutAsset.Contract_Asset_Serial_Number__c;
                }
            }
        } else {
            Date buyoutDate; 
            buyoutDate = buyout.Date_Quoted__c;
            for(Contract_Asset__c contractAsset : [SELECT Id, Serial_Number__c,Asset_Cost__c FROM Contract_Asset__c where Contract__c =: recId AND (Asset_Disposed_Date__c = null OR Asset_Disposed_Date__c > :buyoutDate ) AND Asset_Cost__c > 0]) {
                if(contractAsset.Serial_Number__c != null) {
                    serialNumbers = serialNumbers != null ? serialNumbers + ', ' + contractAsset.Serial_Number__c : contractAsset.Serial_Number__c;
                    
                }
                
            }
        }
        List<FieldWrapper> allFields = new List<FieldWrapper>();
        String defaultZero = '0';
        allFields.add(new FieldWrapper('Receivable Balance', defaultZero, true, false));
        allFields.add(new FieldWrapper('Residual', defaultZero, true, false));
        allFields.add(new FieldWrapper('Sales Tax', defaultZero, true, false));
        allFields.add(new FieldWrapper('Late Charges', defaultZero, true, false));
        
        // Only add Early Termination Fee for Buyout_Type__c 72
        if (buyout != null && buyout.Buyout_Type__c == '72' && buyout.Early_Termination_Fee__c != null) {
            allFields.add(new FieldWrapper('Early Termination Fee', defaultZero, true, false));
        }
       
        allFields.add(new FieldWrapper('Security Deposit', defaultZero, true, false));
        allFields.add(new FieldWrapper('Ending Deposit', defaultZero, true, false));
        // allFields.add(new FieldWrapper('Pass Through', defaultZero, true, false));// DP-1561 Misael Romero
        allFields.add(new FieldWrapper('Property Tax', defaultZero, true, false));
        allFields.add(new FieldWrapper('Insurance', defaultZero, true, false));
        allFields.add(new FieldWrapper('Other Lease Charges', defaultZero, true, false));
        allFields.add(new FieldWrapper('Total Buyout', defaultZero, true, false));
    
       /* 
        allFields[0].value = buyout.Receivable_Balance__c;
        allFields[1].value = buyout.Residual__c;
        allFields[2].value = buyout.SalesTax__c;
        allFields[3].value = buyout.LateCharges__c;
        
        Integer fieldIndex = 4;
        if (buyout.Quote_Sequence__c == '72' && buyout.Early_Termination_Fee__c != null) {
            allFields[fieldIndex].value = buyout.Early_Termination_Fee__c;
            fieldIndex++;
        }
        
        allFields[5].value = buyout.Security_Deposit__c;
        allFields[6].value = buyout.Ending_Deposit__c;
        allFields[7].value = buyout.Service_pass_through__c;
        allFields[8].value = buyout.Property_tax__c;
        allFields[9].value = buyout.Insurance__c;
        allFields[10].value = buyout.Other_Lease_Charges__c;
        allFields[11].value = buyout.Total_Buyout__c; */

        // DP-1561 Misael Romero
        Decimal serviceIncluded = buyout.Service_Included__c ?? 0;
        Decimal serviceOther = buyout.Service_Other__c ?? 0;

        // Assign values by label
        if (buyout != null) {
            for (FieldWrapper fw : allFields) {
                if (fw.label == 'Receivable Balance') fw.value = buyout.Receivable_Balance__c + serviceIncluded;
                if (fw.label == 'Residual') fw.value = buyout.Residual__c;
                if (fw.label == 'Sales Tax') fw.value = buyout.SalesTax__c;
                if (fw.label == 'Late Charges') fw.value = buyout.LateCharges__c;
                if (fw.label == 'Early Termination Fee') fw.value = buyout.Early_Termination_Fee__c;
                if (fw.label == 'Security Deposit') fw.value = buyout.Security_Deposit__c;
                if (fw.label == 'Ending Deposit') fw.value = buyout.Ending_Deposit__c;
                // if (fw.label == 'Pass Through') fw.value = buyout.Service_pass_through__c;// DP-1561 Misael Romero
                if (fw.label == 'Property Tax') fw.value = buyout.Property_tax__c;
                if (fw.label == 'Insurance') fw.value = buyout.Insurance__c;
                if (fw.label == 'Other Lease Charges') fw.value = buyout.Other_Lease_Charges__c + serviceOther;
                if (fw.label == 'Total Buyout') fw.value = buyout.Total_Buyout__c;
            }
        }

        // // only show Early Termination Fee if Quote Seq = 72 and field has value
        // if (buyout.Buyout_Type__c != '72') {
        //     // remove the Early Termination Fee field
        //     allFields.remove(4);
        //     System.debug('==== Early Termination Fee removed since condition not met');
        // } else {
        //     System.debug('==== Early Termination Fee KEPT since condition met');
        // }

        // System.debug('==== All Fields AFTER condition: ' + allFields);
        
        
        this.fields = allFields;
        action = ApexPages.currentPage().getParameters().get('action');
       if(action <> null){
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
        showAddress = true;
        for(ExcludeRemitToAddressOnBuyoutPDFS__mdt excludeConfig : [select Id, BuyoutType__c from ExcludeRemitToAddressOnBuyoutPDFS__mdt]) {
            if(buyout.Name.contains(excludeConfig.BuyoutType__c)) {
                showAddress = false;
                break;
            }
        }
    }
    
   public void setLogoResource(String recId) {
        Contract__c thisContract = [
            SELECT Program__c
            FROM Contract__c
            WHERE Id = :recId
        ];
        
       if (thisContract.Program__c != null && thisContract.Program__c.contains('XBS')) {
           logoResourceName = 'XBSLogo';
           phoneNumber = System.label.CustomerLetterXeroxPhone;
       } else if (thisContract.Program__c != null && thisContract.Program__c.contains('Is_Blind__c')){
           logoResourceName = 'LeaseServicesLogo';
           phoneNumber = System.label.CustomerLetterLeaseServicesPhone;
       } else {
           logoResourceName = 'PeacSolutionsLogo';
           phoneNumber = System.label.CustomerLetterPeacSolutionPhone;
       }
   }
    
    public String getLogoResourceName() {
        return logoResourceName;
    }
    
    public class FieldWrapper{
        public String label{get;set;}
        public Double value{get;set;}
        public Boolean isCurrency{get;set;}
        public Boolean isPlain{get;set;}
        public FieldWrapper(String label, String value, Boolean isCurrency, Boolean isPlain){
            this.label = label;
            this.value = Double.valueof(value);
            this.isCurrency = isCurrency;
            this.isPlain = isPlain;
        }
        public FieldWrapper(){}
    }

}