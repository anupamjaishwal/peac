@IsTest class ChildRecordDynPicklistContTests {
    @IsTest static void unitTest() {
        VisualEditor.DesignTimePageContext dtpc = new VisualEditor.DesignTimePageContext();
        dtpc.entityName = 'Account';
        ChildRecordDynPicklistCont crdpc = new ChildRecordDynPicklistCont(dtpc);
        System.assert(crdpc.getDefaultValue() != null);
        System.assert(!crdpc.getValues().getDataRows().isEmpty());
    }
}