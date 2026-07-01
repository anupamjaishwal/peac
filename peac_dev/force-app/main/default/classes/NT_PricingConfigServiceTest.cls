/**
 * @description  Unit tests for NT_PricingConfigService parent-record mapping.
 *               SAL-7244 regression guard: the Opportunity (Calculate Pricing)
 *               path must map Down Payment, Buydown, and Subsidy into the pricing
 *               context so they reduce the financed amount sent to TValue, while
 *               equipment cost stays gross.
 * @author       Northteq
 * @date         2026-06-24
 */
@IsTest
private class NT_PricingConfigServiceTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Northteq Config Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(),
            Business_Address__c = '123 Main St',
            Account_Billing_Street__c = '123 Main St',
            Business_City__c = 'Austin',
            Account_Billing_City__c = 'Austin',
            Business_State__c = 'TX',
            Account_Billing_State_Province__c = 'TX',
            Business_Zip__c = '78701',
            Account_Billing_Zip_Postal_Code__c = '78701'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Northteq Config Opp',
            AccountId = acc.Id,
            StageName = 'Application',
            CloseDate = Date.today().addDays(30),
            Primary_Source__c = 'Customer Inbound - Call',
            Equipment_Description__c = 'Test Equipment',
            Equipment_Cost__c = 50000,
            Terms__c = 36,
            Funded_Amount__c = 50000,
            Payment_Frequency__c = 'Monthly',
            Purchase_Options__c = '1.00 Out',
            Points__c = 2,
            Down_Payment__c = 1000,
            Buydown__c = 500,
            Subsidy__c = 250
        );
        insert opp;
    }

    /**
     * @description  SAL-7244 — Down Payment, Buydown, and Subsidy from the
     *               Opportunity are mapped into the context (they were previously
     *               dropped, so the Calculate Pricing button ignored them), while
     *               equipment cost stays gross and independent of the deductions.
     */
    @IsTest
    static void populateFromOpportunity_mapsDownBuydownSubsidy() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Northteq Config Opp' LIMIT 1];

        Test.startTest();
        NT_PricingContext ctx = new NT_PricingContext(opp.Id);
        new NT_PricingConfigService().loadConfiguration(ctx);
        Test.stopTest();

        System.assertEquals(1000, ctx.downPayment, 'Down Payment must be mapped from the Opportunity.');
        System.assertEquals(500, ctx.buyDown, 'Buydown (Opp field Buydown__c) must be mapped.');
        System.assertEquals(250, ctx.subsidy, 'Subsidy must be mapped from the Opportunity.');
        System.assertEquals(2, ctx.points, 'Points must be mapped from the Opportunity.');
        System.assertEquals(50000, ctx.equipmentCost, 'Equipment cost stays gross, independent of the deductions.');
        System.assertEquals(50000, ctx.financedAmount, 'Financed amount starts gross; deductions are applied in NT_TValueService.');
    }
}