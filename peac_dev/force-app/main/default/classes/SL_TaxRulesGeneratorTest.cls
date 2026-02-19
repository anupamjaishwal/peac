@isTest
public with sharing class SL_TaxRulesGeneratorTest {
    @isTest
    public static void scenario1() {
        Test.startTest();
        SL_TaxRulesGenerator.generateFromCsv(false);
        Test.stopTest();
    }
}