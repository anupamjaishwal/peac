@IsTest
private class AuraFieldSetDisplayPicklistContTests {
    @IsTest static void AuraFieldSetDisplayPicklistContTest() {

        VisualEditor.DesignTimePageContext dtpc = new VisualEditor.DesignTimePageContext();
        dtpc.entityName = 'Account';
        dtpc.pageType = 'RecordPage';

        AuraFieldSetDisplayPicklistCont afsdplc = new AuraFieldSetDisplayPicklistCont(dtpc);
        VisualEditor.DataRow defaultDr = afsdplc.getDefaultValue();
        System.assert(defaultDr != null,'The default data row came back as null!');
        System.assert(String.isNotBlank(String.valueOf(defaultDr.getValue())),'The default data row came back as blank!');

        VisualEditor.DynamicPickListRows dprs = afsdplc.getValues();
        System.assert(!dprs.getDataRows().isEmpty(),'There were no data rows present!');

        Boolean testFsPresent = false;
        for (VisualEditor.DataRow row : dprs.getDataRows()) {
            testFsPresent = !testFsPresent ? String.valueOf(row.getValue()).containsIgnoreCase('Test_FS') : testFsPresent;
            if (testFsPresent) break;
        }
        System.assert(testFsPresent,'The default test field set was not found!');
    }

    @IsTest static void AuraRelatedRecordFieldSetDspPicklistContTest() {

        VisualEditor.DesignTimePageContext dtpc = new VisualEditor.DesignTimePageContext();
        dtpc.entityName = 'Account';
        dtpc.pageType = 'RecordPage';

        AuraRelatedRecordFieldSetDspPicklistCont arrfsdplc = new AuraRelatedRecordFieldSetDspPicklistCont(dtpc);
        VisualEditor.DataRow defaultDr = arrfsdplc.getDefaultValue();

        System.assert(defaultDr != null,'The default data row came back as null!');
        System.assert(String.isNotBlank(String.valueOf(defaultDr.getValue())),'The default data row came back as blank!');

        VisualEditor.DynamicPickListRows dprs = arrfsdplc.getValues();
        System.assert(!dprs.getDataRows().isEmpty(),'There were no data rows present!');

        Boolean testFsPresent = false;

        for (VisualEditor.DataRow row : dprs.getDataRows()) {
            testFsPresent = !testFsPresent ? String.valueOf(row.getValue()).equalsIgnoreCase('ParentId:Test_FS') : testFsPresent;
            if (testFsPresent) break;
        }
        System.assert(testFsPresent,'The default test field set was not found!');


    }
}