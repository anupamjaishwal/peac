@isTest
public class PEAC_PrintSendBuyoutControllerTest {

    @isTest
    static void testSendEmailSuccess() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = [SELECT Id FROM Contract__c];
        List<EmailTemplate> emailTemplateList = PEAC_PrintSendBuyoutController.getEmailTemplates(contract.Id);
        
        // Create EmailWrapper
        PEAC_PrintSendBuyoutController.EmailWrapper emailWrap = new PEAC_PrintSendBuyoutController.EmailWrapper();
        emailWrap.recordId = contract.Id;
        emailWrap.emailTemplateId = emailTemplateList[0].Id;
        emailWrap.emailList = 'testuser@example.com';
        
        // Create PDFWrapper with required data
        PEAC_PrintSendBuyoutController.PDFWrapper pdfWrap = new PEAC_PrintSendBuyoutController.PDFWrapper();
        pdfWrap.pdfName = 'TestPDF';
        pdfWrap.apexVFPageName = 'SL_PrintBuyout'; // Assuming this VF page exists in your org
        
        // Create PDFAttributeWrapper and add it to PDFWrapper
        PEAC_PrintSendBuyoutController.PDFAttributeWrapper attributeWrap = new PEAC_PrintSendBuyoutController.PDFAttributeWrapper();
        attributeWrap.key = 'testKey';
        attributeWrap.value = 'testValue';
        pdfWrap.pdfAttributeList = new List<PEAC_PrintSendBuyoutController.PDFAttributeWrapper>{attributeWrap};
        
        emailWrap.pdfList = new List<PEAC_PrintSendBuyoutController.PDFWrapper>{pdfWrap};

        // Test the sendEmail method
        Test.startTest();
        String result = PEAC_PrintSendBuyoutController.sendEmail(emailWrap);
        Test.stopTest();
        
        // Verify that email was sent successfully
        System.assertEquals('Success', result);
    }

    @isTest
    static void testSendEmailErrorHandling() {
        // Call sendEmail with null EmailWrapper to test error handling
        Test.startTest();
        String result = PEAC_PrintSendBuyoutController.sendEmail(null);
        Test.stopTest();
        
        // Verify that it returns 'Error'
        System.assertEquals('Error', result);
    }

    @isTest
    static void testGetEmailAttachment() {
        // Create PDFWrapper with necessary data
        PEAC_PrintSendBuyoutController.PDFWrapper pdfWrap = new PEAC_PrintSendBuyoutController.PDFWrapper();
        pdfWrap.pdfName = 'TestPDF';
        pdfWrap.apexVFPageName = 'SL_PrintBuyout'; // Assuming this VF page exists in your org

        // Create PDFAttributeWrapper and add it to the PDFWrapper
        PEAC_PrintSendBuyoutController.PDFAttributeWrapper attributeWrap = new PEAC_PrintSendBuyoutController.PDFAttributeWrapper();
        attributeWrap.key = 'testKey';
        attributeWrap.value = 'testValue';
        pdfWrap.pdfAttributeList = new List<PEAC_PrintSendBuyoutController.PDFAttributeWrapper>{attributeWrap};
        
        List<PEAC_PrintSendBuyoutController.PDFWrapper> pdfList = new List<PEAC_PrintSendBuyoutController.PDFWrapper>{pdfWrap};

        // Test the getEmailAttachment method
        Test.startTest();
        List<Messaging.EmailFileAttachment> attachments = PEAC_PrintSendBuyoutController.getEmailAttachment(pdfList);
        Test.stopTest();
        
        // Verify that one attachment is returned
        System.assertEquals(1, attachments.size());
    }
}