/**
 * This class is provided open source under the MIT license
 * This class is used to create picklist options for the .design of the AuraFieldSetDisplay
 * component
 */
global without sharing class AuraFieldSetObjSelectCont extends VisualEditor.DynamicPickList {
    private VisualEditor.DesignTimePageContext context {Get;Set;}
    private VisualEditor.DynamicPickListRows picklistRows {Get;Set;}

    public AuraFieldSetObjSelectCont(VisualEditor.DesignTimePageContext context) {
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
        VisualEditor.DynamicPickListRows returnVal = new VisualEditor.DynamicPickListRows();
        if (context.pageType == 'HomePage' || (context.pageType == null && context.entityName == null)) {
            returnVal.addRow(new VisualEditor.DataRow('Current User','UserInfo-User',true));
            returnVal.addRow(new VisualEditor.DataRow('Portal Account','UserInfo-Account'));
            returnVal.addRow(new VisualEditor.DataRow('Portal Contact','UserInfo-Contact'));
        }
        if (context.entityName != null) {
            DescribeSObjectResult dsr =Schema.getGlobalDescribe().get(String.valueOf(context.entityName)).getDescribe();
            returnVal.addRow(new VisualEditor.DataRow(dsr.getLabel(),dsr.getName(),true));
        }

        return returnVal;
    }

}