public class PEAC_PartnerQuotePDFController {
    public Contract__c thisContract{get;set;}
    public Buyout__c thisBuyout {get; set;}
    public Buyout_Asset__c thisContractAsset {get; set;}
    public string serialNumbers{get; set;}
    public PEAC_PartnerQuotePDFController(){
        String buyoutId = ApexPages.currentPage().getParameters().get('buyoutId');
        
        thisBuyout = [ SELECT Id,Name, Contract__c, Buyout_Description__c, Quote_Sequence__c, Buyout_Amount__c, Most_Recent__c, Receivable_Balance__c, Residual__c, SalesTax__c, LateCharges__c, Early_Termination_Fee__c, Security_Deposit__c, Ending_Deposit__c, Service_pass_through__c, Property_tax__c, Insurance__c, Other_Lease_Charges__c, Total_Buyout__c, Partial_Buyout__c, Date_Quoted__c, Expiration_Date__c, Createddate FROM Buyout__c WHERE Id = :buyoutId];
       //  thisContractAsset = [SELECT Id, Contract_Asset__r.Asset_Cost__c,Serial_Number__c, Contract_Asset__r.Purchase_Option__c FROM Buyout_Asset__c];
        thisContract = [SELECT Name, Customer__r.Name, AR_Address_1__c, 
                                    AR_Address_2__c, AR_Address_3__c, AR_City__c,Contract_Term__c,Payments_Made__c,Dealer_Name__r.name, 
                                    AR_State__c,AR_Zip_Code__c,Next_Payment_Date__c,Commencement_Date__c, Payments_Remaining__c, Purchase_Option_Description__c, Payment_Amount__c
                                    FROM Contract__c 
                                    WHERE Id =:thisBuyout.Contract__c
                                    LIMIT 1];
        Set<string> serialNumberSet = new Set<string>();
        if(thisBuyout.Partial_Buyout__c) {
            for(Buyout_Asset__c buyoutAsset : [select Id, Contract_Asset_Serial_Number__c from Buyout_Asset__c where Buyout__c =: buyoutId]) {
                if(buyoutAsset.Contract_Asset_Serial_Number__c != null) {
                    serialNumbers = serialNumbers != null ? serialNumbers + ', ' + buyoutAsset.Contract_Asset_Serial_Number__c : buyoutAsset.Contract_Asset_Serial_Number__c;
                }
            }
        } else {
            Date buyoutDate; 
            buyoutDate = thisBuyout.Date_Quoted__c;
            for(Contract_Asset__c contractAsset : [select Id, Serial_Number__c from Contract_Asset__c where Contract__c =: thisBuyout.Contract__c AND (Asset_Disposed_Date__c = null OR Asset_Disposed_Date__c > :buyoutDate ) AND Asset_Cost__c > 0]) {
                if(contractAsset.Serial_Number__c != null) {
                    serialNumbers = serialNumbers != null ? serialNumbers + ', ' + contractAsset.Serial_Number__c : contractAsset.Serial_Number__c;
                    
                }
                
            }
        }
       // serialNumbers = serialNumberSet.toString();
        
    }
    
}