/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to store the data for InfoLease API and Validation checks.
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Jan-30-2026
**************************************************************************************************************/    
public class PEAC_BWInfoLeaseDataWrapper {
    public Opportunity opp;
	public List<Guarantor__c> guarantorList;
	public List<Variable_Payment__c> variablePayList;
    public List<Blended_Income_Item__c> blendedIncomeItemList;
    public List<Asset__c> assetList;
    public List<Miscellaneous_Billable_Item__c> miscBillableItemList;
    public List<Miscellaneous_Invoice_Item__c> miscInvoiceItemList;
    public List<Dealer__c> dealerList;
    public List<Broker__c> primaryBorkerList;
    public List<Franchisor__c> franchisorList;
    public List<Contract__c> contractList;//SAL-6343
    public List<Purchase_Order__c> purchaseOrderList;//SAL-6343

    // Default constructor (initializes lists to avoid null checks)
    public PEAC_BWInfoLeaseDataWrapper() {
        this.opp = new Opportunity();
		this.guarantorList = new List<Guarantor__c>();
		this.variablePayList = new List<Variable_Payment__c>();
        this.blendedIncomeItemList = new List<Blended_Income_Item__c>();
        this.assetList = new List<Asset__c>();
        this.miscBillableItemList = new List<Miscellaneous_Billable_Item__c>();
        this.miscInvoiceItemList = new List<Miscellaneous_Invoice_Item__c>();
        this.dealerList = new List<Dealer__c>();
        this.primaryBorkerList = new List<Broker__c>();
        this.franchisorList = new List<Franchisor__c>();
        this.contractList = new List<Contract__c>();//SAL-6343
        this.purchaseOrderList = new List<Purchase_Order__c>();//SAL-6343
    }
}