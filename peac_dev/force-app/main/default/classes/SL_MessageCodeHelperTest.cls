/**
 * Tests for SL_MessageCodeHelper 
 * Developed by Harsh@Silverline 05/07/2022
 */
@isTest
public with sharing class SL_MessageCodeHelperTest {
    @IsTest
    static void testMessageCodes(){
        Test.startTest();
        SL_MessageCodeHelper theHelper = new SL_MessageCodeHelper();
        String department = 'Collections';// SL-1832 Misael Romero
        String primaryCallOutcome = 'Weather Related Deferral Requested';
        Date followUpDate = theHelper.handleMessageCodes(department, primaryCallOutcome);
        Date testDate = theHelper.addBussinessDays(Date.today(), 20);
        testDate = theHelper.addBussinessDays(Date.today(), -1);
        Test.stopTest();
        Date expectedDate = theHelper.addBussinessDaysV2(Date.today(), 5);
        System.assertEquals(expectedDate, followUpDate);
        
    }
}