@isTest public class TC_OnBaseRequestTest {
    
    @isTest public static void testOnBaseHeader () {
        insert new OnBase_Credentials__c (Add_Document__c = 'test'
                                          , App_Server_Url__c = 'test'
                                          , Data_Source__c = 'tet'
                                          , Gateway_Url__c = 'test'
                                          , Initialization_Vector__c = 'Ki01di908lGdQ8ot'
                                          , Password__c = 'te'
                                          , Secret_Key__c = 'Ki0+di908lGdQ8otxkzyKHxqF3ciK411'
                                          , Username__c = 'test');
        TC_OnBaseRequest.getHeader();
        TC_OnBaseRequest.getAddDocumentUrl ();
    }

}