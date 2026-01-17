/**
 * Created by corycafferty on 2019-08-08.
 */

@IsTest
public with sharing class TC_Marlin_CaseCenterCalloutTest {

    @IsTest
    static void testApplicationStatusUpdate(){

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('TC_Marlin_CaseCenterCalloutTest1');
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus('testOppId', 'testAppNumber', null);
        Test.stopTest();

    }

    @IsTest
    static void testPKNumberUpdate(){

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('TC_Marlin_CaseCenterCalloutTest1');
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        MARLIN_CaseCenterCallout.updateCaseCenterApplicationStatus('testOppId', ' testAppNumber', 'testPKNumber');
        Test.stopTest();

    }

}