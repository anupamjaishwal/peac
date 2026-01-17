@IsTest
private without sharing class AuraFieldSetObjSelectContTests {

    @IsTest static void AuraFieldSetObjSelectContTests() {

        VisualEditor.DesignTimePageContext dtpc = new VisualEditor.DesignTimePageContext();
        dtpc.entityName = 'Account';
        dtpc.pageType = 'RecordPage';

        AuraFieldSetObjSelectCont afsdplc = new AuraFieldSetObjSelectCont(dtpc);
        VisualEditor.DataRow defaultDr = afsdplc.getDefaultValue();
        System.assert(defaultDr != null,'The default data row came back as null!');
        System.assert(String.isNotBlank(String.valueOf(defaultDr.getValue())),'The default data row came back as blank!');

        VisualEditor.DynamicPickListRows dprs = afsdplc.getValues();
        System.assert(!dprs.getDataRows().isEmpty(),'There were no data rows present!');

    }

    @IsTest static void AuraFieldSetObjSelectContTestsWithNoContext() {

        VisualEditor.DesignTimePageContext dtpc = new VisualEditor.DesignTimePageContext();

        AuraFieldSetObjSelectCont afsdplc = new AuraFieldSetObjSelectCont(dtpc);
        VisualEditor.DataRow defaultDr = afsdplc.getDefaultValue();
        System.assert(defaultDr != null,'The default data row came back as null!');
        System.assert(String.isNotBlank(String.valueOf(defaultDr.getValue())),'The default data row came back as blank!');

        VisualEditor.DynamicPickListRows dprs = afsdplc.getValues();
        System.assert(!dprs.getDataRows().isEmpty(),'There were no data rows present!');

    }
}