public class pEAC_CustomerBuyOutLetterCon{
   
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

    public void setFields(String incoming){
        List<FieldWrapper> allFields = new List<FieldWrapper>();
        JSONParser parser = JSON.createParser(incoming);
        action = ApexPages.currentPage().getParameters().get('action');
        if(action <> null){
            for(Buyout_letter_table_fields__mdt buyLetter : [SELECT Id, TableLabel__c FROM Buyout_letter_table_fields__mdt]){
                labels.add(buyLetter.TableLabel__c);
            }
        }
        integer i = 1;
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                system.debug('count:'+i);
                
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        
                        FieldWrapper aField = (FieldWrapper)parser.readValueAs(FieldWrapper.class);
                        totalAmt = aField.rows[0].value;
                        system.debug(labels+'aField:'+aField.label);
                        if(action == 'buyout' && labels.contains(aField.label)){
                            allFields.add(aField);
                        } else if(action != 'buyout'){
                            allFields.add(aField);
                        }
                        if(action == 'buyout' &&  (aField.label == 'Receivable Balance' || aField.label == 'Service Pass Through') && aField.value <> null){
                            buyoutreceivableTotal = buyoutreceivableTotal + aField.Rows[0].value; 
                            //if(aField.Rows.size() > 1) upreceivableTotal = upreceivableTotal+ aField.Rows[1].value;
                            //if(aField.Rows.size() > 2) returnoutreceivableTotal =  returnoutreceivableTotal+ aField.Rows[2].value;
                        }
                    }
                    
                }
            }
            i++;
        }
        this.fields = allFields;
    }
    public List<FieldWrapper> getFields(){
        return this.fields;
    }

    public pEAC_CustomerBuyOutLetterCon(){
        next30Days = system.today().addDays(30);
        this.setFields(ApexPages.currentPage().getParameters().get('rows'));
        if(this.fields.size() > 0 && this.fields[0].Rows.size() > 0){
             maxRecSize = this.fields[0].Rows.size();
        }
        
        String recId = ApexPages.currentPage().getParameters().get('recId');
        
        if(recId <> null) {
            ContractRec = [SELECT Id, Customer__r.Name, Invoice_Description__c, Name, Opportunity__r.Purchase_Options__c, Commencement_Date__c, Payments_Remaining__c, Contract_Term__c, Gross_Equipment_Cost__c, Payment_Amount__c, Current_Rental_Payment__c, Next_Payment_Date__c, Quote_Buyout__c FROM Contract__c WHERE Id = :recId];
        }
        
        System.debug('####this.setFields: '+this.fields.size());
       
        integer recSize = maxRecSize;
        System.debug('recSize '+recSize);
        while(recSize < 3 ){
            System.debug('recSize '+recSize);
            FieldWrapper fw = new FieldWrapper();
            fw.rows = new List<buyoutrows>();
            
            this.fields.add(fw);
            recSize++;
        }
        for(FieldWrapper fw : this.fields){
            while(fw.rows.size() < 3){
                //fw.rows = new List<buyoutrows>();
                buyoutrows br = new buyoutrows();
                //br.value = 0;
                //br.QuoteSeq = '';
                fw.rows.add(br);
            }
        }
        System.debug('this.fields '+this.fields.size());
        if(action == 'buyout'){
            for(FieldWrapper fw : this.fields){
                if(fw.label == 'Receivable Balance'){
                    fw.value = buyoutreceivableTotal;
                    //if(fw.rows.size() > 1) fw.rows[1].value = upreceivableTotal;
                    //if(fw.rows.size() > 2) fw.rows[2].value = returnoutreceivableTotal;
                }
            }
        }
        
    }
    public class buyoutrows{
        public Double value {get; set;}
        public String QuoteSeq {get; set;}
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