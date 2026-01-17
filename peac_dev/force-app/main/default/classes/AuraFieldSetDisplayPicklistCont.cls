/**
 * This class is provided open source under the MIT license
 * This class is used to create picklist options for the .design of the AuraFieldSetDisplay component
 */
global without sharing class AuraFieldSetDisplayPicklistCont extends VisualEditor.DynamicPickList {
    private VisualEditor.DesignTimePageContext context {Get;Set;}
    private VisualEditor.DynamicPickListRows picklistRows {Get;Set;}

    global AuraFieldSetDisplayPicklistCont(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    global override VisualEditor.DataRow getDefaultValue() {
        this.picklistRows = picklistRows == null ? setupFieldSetValues() : picklistRows;

        return picklistRows.get(0);
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        this.picklistRows = picklistRows == null ? setupFieldSetValues() : picklistRows;
        return picklistRows;
    }

    private VisualEditor.DynamicPickListRows setupFieldSetValues() {
        VisualEditor.DynamicPickListRows  returnList = new VisualEditor.DynamicPickListRows();
        List<String> objectTypes = new List<String>();
        if (context.entityName != null) objectTypes.add(context.entityName);
        if (objectTypes.isEmpty() && (context.pageType == 'HomePage' || (context.pageType == null && context.entityName == null))) objectTypes.addAll(new List<String>{'User','Account','Contact'});
        Boolean noFsFound = true;
        for (String objType : objectTypes) {
            DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(objType).getDescribe();
            Map<String, Schema.FieldSet> fieldSetMap = dsr.FieldSets.getMap();
            Set<String> nonNameSpaceFs = new Set<String>(fieldSetMap.keySet());

            for (Schema.FieldSet fs : fieldSetMap.values()) {
                if(fs.getNameSpace() == null) returnList.addRow(new VisualEditor.DataRow((objectTypes.size() > 1) ? dsr.getLabel()+':'+fs.getLabel() : fs.getName(),fs.getName(),false));
                if(fs.getNameSpace() == null && noFsFound) noFsFound = false;
                if(fs.getNameSpace() != null) nonNameSpaceFs.remove(fs.getName());
            }
        }

        String defaultLabel = noFsFound ?
                'No Field Sets found for ' : '-- None --';

        returnList.addRow(new VisualEditor.DataRow(defaultLabel,'',true));

        return returnList;
    }
}