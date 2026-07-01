@isTest
private class tvalueQuotePickerController_Test{
    @isTest
    static void testControllerMethods(){
        // Create an Account with the Show_Yield flag true
        Account acc = new Account(
            Name = 'Test Account', 
            Show_Yield_in_Dealer_Portal__c = true
        );
        insert acc;

        // Create a Contact linked to the Account
        Contact c = new Contact(
            LastName = 'TestContact', 
            FirstName = 'Test', 
            AccountId = acc.Id, 
            phone = '4132221121'
        );
        insert c;


        // Create sample tval__TValue_Quote__c records
        List<tval__TValue_Quote__c> tvals = new List<tval__TValue_Quote__c>();
        for (Integer i = 0; i < 2; i++){
            tval__TValue_Quote__c tq = new tval__TValue_Quote__c(
                tval__Amount_Financed__c = 1000 + i, 
                tval__Term__c = 12
            );
            tvals.add(tq);
        }
        insert tvals;

        Test.startTest();

        // 1) Call getQuoteData with null to fetch all tvals
        tvalueQuotePickerController.QuoteDataWrapper allWrapper = tvalueQuotePickerController.getQuoteData(null);
        System.assertNotEquals(null, allWrapper, 'getQuoteData should return a wrapper');
        System.assertEquals(2, allWrapper.quotes.size(), 'Should return two tvalue quotes');

        // 2) Call getTValueQuotesByIds with the inserted IDs
        List<String> ids = new List<String>();
        for (tval__TValue_Quote__c t : tvals)
            ids.add(t.Id);
        tvalueQuotePickerController.QuoteDataWrapper byIdsWrapper = tvalueQuotePickerController.getTValueQuotesByIds(ids);
        System.assertNotEquals(null, byIdsWrapper, 'getTValueQuotesByIds should return wrapper');
        System.assertEquals(2, byIdsWrapper.quotes.size(), 'getTValueQuotesByIds should return the two requested quotes');

        // 2b) Call the private method getTValueQuotes (exposed to tests via @TestVisible) to cover that path
        List<tvalueQuotePickerController.QuoteWrapper> listFromPrivate = tvalueQuotePickerController.getTValueQuotes(null);
        System.assertEquals(2, listFromPrivate.size(), 'getTValueQuotes should return the inserted tvalue quotes when passed null');

        // 3) isPortalUser should return false for a Standard user
        Boolean isPortal = tvalueQuotePickerController.isPortalUser();
        System.assertEquals(false, isPortal, 'Standard user should not be portal user');

        // 4) getSessionId should return a non-null value (may be blank in some test contexts but not null)
        String sess = tvalueQuotePickerController.getSessionId();
        System.assertNotEquals(null, sess, 'getSessionId should return a value (may be empty)');

        // 5) sendEmail should not throw when provided valid inputs
        // Wrap in try/catch so we can assert failure if exception thrown
        try{
            tvalueQuotePickerController.sendEmail('recipient@example.com', '', 'Test Subject', 'Test Body');
        } catch (Exception ex){
            System.assert(false, 'sendEmail threw an exception: ' + ex.getMessage());
        }

        Test.stopTest();
    }

}