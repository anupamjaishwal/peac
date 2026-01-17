@isTest
public class PEAC_BPLetterPrintEmailControllerTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(Actual_Annual_Revenue__c = 3, Actual_Average_Daily_Balance__c = 4,
                    Annual_Revenue__c = 2, Appeal_Information_Provided__c = 'Additional Bank Reference', Application_Status__c = 'Manually Approved',
                    Approved_Amount__c = 1000, Approved_Document_Delivery_Method__c = 'DocuSign Only', Average_Daily_Balance__c = 5,
                    Billing_Attention_To__c = 'Accounts Payable', Broker_Book_Method__c = 'F',
                    Broker_Tax_Method__c = 'F', Business_Phone__c = '1234567898', CaseCenter__c = '321',
                    CloseDate = Date.today(), Contract_Status__c = 'Active', Custom_Stipulation__c = 'A1', 
                    Decision_Date__c = Datetime.now(), Docs_Out_Dollar__c = 13, Document_Delivery_Method__c = 'DocuSign',
                    Equip_Code1__c = 'Air Compressors', Equipment_Cost__c = 1201,
                    Equipment_Description__c = 'equipment 1', Final_Product_Loc__c = '1 stnarnia',
                    Funded_Amount__c = 14, Funded_Term__c = 15, Gross_Finance__c = -1201, Income_Method__c = 'E', Invoice_Code__c = 'A',
                    Invoice_Description__c = 'equipment 1', Late_Charge_Rate__c = 15, Lead_Invoice_Days__c = 22, Loan_Purpose__c = 'Other',
                    Loan_Score__c = 6, Oppt_FS_Use_Of_Funds__c = 'testing purposes', StageName = 'Application',Payment_Amount__c=1,
                    RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CVG Booking').getRecordTypeId(),
                    Primary_Source__c = 'LendingTree', Name = 'Test Opportunity', Tax_ID__c = '161753502');
        insert opp;

        // Create Contract
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = [SELECT Id FROM Contract__c];

        // Create Buyout
        Buyout__c buyout = new Buyout__c(
            Contract__c = contract.Id,
            Buyout_Type__c = 'Standard',
            Buyout_Description__c = 'Test Description',
            Buyout_Amount__c = 1000,
            Total_Buyout__c = 1000,
            Receivable_Balance__c = 200,
            Residual__c = 100,
            SalesTax__c = 50,
            LateCharges__c = 10,
            Early_Termination_Fee__c = 25,
            Security_Deposit__c = 30,
            Ending_Deposit__c = 15,
            Service_pass_through__c = 5,
            Property_tax__c = 8,
            Insurance__c = 12,
            Other_Lease_Charges__c = 20,
            Most_Recent_DP__c = true,
            Show_To_DP_Users__c = true,
            Date_Quoted__c = Date.today()
        );
        insert buyout;
        
    }

    @isTest
    static void testControllerInitialization() {
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];

        // Set page parameters
        Test.setCurrentPage(Page.PEAC_BPPrintEmail); 
        ApexPages.currentPage().getParameters().put('recId', contract.Id);
        ApexPages.currentPage().getParameters().put('isPartialChecked', 'false');

        // Instantiate controller
        PEAC_BPLetterPrintEmailController controller = new PEAC_BPLetterPrintEmailController();

        // Validate key properties
        System.assertNotEquals(null, controller.fields, 'Fields should be populated');
        System.assert(controller.fields.size() > 0, 'Fields list should not be empty');
        System.assert(controller.Buyouts.size() > 0, 'Buyouts should be populated');
        System.assert(controller.totalAmt > 0, 'Total Amount should be calculated');
        System.assertNotEquals(null, controller.getLogoResourceName(), 'Logo resource should be set');
    }

    @isTest
    static void testActionParameterAndLabelsFiltering() {
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];

        Test.setCurrentPage(Page.PEAC_BPPrintEmail);
        ApexPages.currentPage().getParameters().put('recId', contract.Id);
        ApexPages.currentPage().getParameters().put('action', 'print');

        PEAC_BPLetterPrintEmailController controller = new PEAC_BPLetterPrintEmailController();

        System.assert(controller.fieldsBuyoutLetter.size() > 0, 'Filtered fields should be populated based on metadata');
    }
}