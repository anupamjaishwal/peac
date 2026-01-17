/**
 * This class is provided open source under the MIT license
 * This class is used to create picklist options for the .design of the AuraRelatedRecordFieldSetDisplay
 * component
 */
global with sharing class AuraRelatedRecordFieldSetDspPicklistCont extends VisualEditor.DynamicPickList {
    private VisualEditor.DesignTimePageContext context {Get;Set;}
    private VisualEditor.DynamicPickListRows picklistRows {Get;Set;}

    global AuraRelatedRecordFieldSetDspPicklistCont(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        this.picklistRows = picklistRows == null ? setupRelatedObjectRows() : picklistRows;

        return picklistRows.get(0);
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        this.picklistRows = picklistRows == null ? setupRelatedObjectRows() : picklistRows;
        return picklistRows;
    }

    @TestVisible VisualEditor.DynamicPickListRows setupRelatedObjectRows() {
        VisualEditor.DynamicPickListRows  returnList = new VisualEditor.DynamicPickListRows();
        Map<String,List<Schema.FieldSet>> objectToFieldSetMap = new Map<String,List<Schema.FieldSet>>();
        Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();

        if (context != null && context.entityName != null) {
            fieldMap = Schema.getGlobalDescribe().get(context.entityName).getDescribe().Fields.getMap();
        }
        if (context.pageType == 'HomePage' || (context.pageType == null && context.entityName == null)) {
            fieldMap.putAll(Schema.getGlobalDescribe().get('Account').getDescribe().Fields.getMap());
        }

        for (Schema.SObjectField fld : fieldMap.values()) {
            Schema.DescribeFieldResult dfr = fld.getDescribe();

            if (String.isNotBlank(dfr.getRelationshipName()) && !dfr.isNamePointing() && !dfr.getReferenceTo().isEmpty()) {

                String relatedObjectName = dfr.getReferenceTo()[0].getDescribe().getName();

                if (!objectToFieldSetMap.containsKey(relatedObjectName)) {
                    List<Schema.FieldSet> nonNameSpaceFieldSets = new List<Schema.FieldSet>();
                    Map<String, Schema.FieldSet> fieldsetMap = dfr.getReferenceTo()[0].getDescribe().FieldSets.getMap();
                    for (Schema.FieldSet fs : fieldsetMap.values()) {
                        if(fs.getNameSpace() == null) nonNameSpaceFieldSets.add(fs);
                    }
                    objectToFieldSetMap.put(relatedObjectName,nonNameSpaceFieldSets);
                }

                for (Schema.FieldSet fs : objectToFieldSetMap.get(relatedObjectName)) {
                    returnList.addRow(new VisualEditor.DataRow(dfr.getLabel()+': '+fs.getLabel(),dfr.getName()+':'+fs.getName(),false));
                }
            }
        }

        String defaultLabel = returnList.getDataRows().isEmpty() ? 'No Reference Fields With Field Sets Defined for this object' : null;
        if (defaultLabel != null) returnList.addRow(new VisualEditor.DataRow(defaultLabel,'',true));

        return returnList;
    }
}