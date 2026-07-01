/**************************************************************************************************************
@Author:D Balakrishna(LTIMindtree)
@Description:This class contains the business logic to generate the file name for the uploaded file and Save to Contract Object.
@User Story:SL-2897
@Created Date:December-02-2025
**************************************************************************************************************/
public without sharing class PEAC_FileUploadController {
    public class SaveFileResult {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String fileName;
        @AuraEnabled public String usedPrefix; // for quick verification
    }
    @AuraEnabled
    public static SaveFileResult saveXlsxToContractStrict(Id contractId, String base64Data) {
        if (contractId == null || String.isBlank(base64Data)) {
            throw new AuraHandledException('ContractId and file content are required.');
        }

        // Read business Contract Number from Contract__c.Name
        Contract__c c = [
            SELECT Id, Name
            FROM Contract__c
            WHERE Id = :contractId
            LIMIT 1
        ];
        if (String.isBlank(c.Name)) {
            throw new AuraHandledException('Contract__c.Name is blank; cannot compose filename.');
        }
        String prefix = c.Name.trim(); // e.g., "211-345600"

        // IST timestamp (yyyy-MM-dd_HH-mm-ss)
        String istStamp = formatIST(System.now());

        // Final filename
        //String finalName = prefix + '_' + istStamp + '.xlsx';
        String finalName = 'MassUpload_'+ prefix + '_' + System.now() + '.xlsx';

        // Create the file (ContentVersion)
        Blob b = EncodingUtil.base64Decode(base64Data);
        ContentVersion cv = new ContentVersion();
        cv.Title        = finalName;
        cv.PathOnClient = finalName; // Excel type inferred from .xlsx extension
        cv.VersionData  = b;
        cv.Origin       = 'H';
        insert cv;

        // Link to the Contract__c record
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId    = contractId;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;

        // Download URL for (API ≥59)
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String downloadUrl = baseUrl + '/sfc/servlet.shepherd/document/download/' + cv.ContentDocumentId;

        SaveFileResult res = new SaveFileResult();
        res.contentDocumentId = cv.ContentDocumentId;
        res.fileName          = finalName;    // server-composed, not client
        res.downloadUrl       = downloadUrl;
        res.usedPrefix        = prefix;       // for quick troubleshooting
        return res;
    }

    // Helper: format current time in IST as yyyy-MM-dd_HH-mm-ss
    private static String formatIST(Datetime dtGmt) {
        TimeZone tz = TimeZone.getTimeZone('Asia/Kolkata');
        Integer offsetSecs = tz.getOffset(dtGmt) / 1000;
        Datetime dtIst = dtGmt.addSeconds(offsetSecs);
        return dtIst.format('yyyy-MM-dd_HH-mm-ss');
    }
}