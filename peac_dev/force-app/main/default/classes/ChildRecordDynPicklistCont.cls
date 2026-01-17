global without sharing class ChildRecordDynPicklistCont extends VisualEditor.DynamicPickList {
    private VisualEditor.DesignTimePageContext context {get;set;}
    private VisualEditor.DynamicPickListRows picklistRows {get;set;}

    /**
     * @description     Constructs a child record dynamic picklist wrapper
     *
     * @param context   The context passed in from the lightning component
     */
    global ChildRecordDynPicklistCont(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    /**
     * @description Gets the default value for the data row object
     *
     * @return      The default value for the data picklist rows
     */
    global override VisualEditor.DataRow getDefaultValue() {
        this.picklistRows = picklistRows == null ? setupRelatedObjectRows() : picklistRows;

        return picklistRows.get(0);
    }

    /**
     * @description Gets the values for the dynamic picklist rows
     *
     * @return      The dynamic picklist rows
     */
    global override VisualEditor.DynamicPickListRows getValues() {
        this.picklistRows = picklistRows == null ? setupRelatedObjectRows() : picklistRows;

        return picklistRows;
    }

    /**
     * @description Sets up the related object rows
     *
     * @return      THe dynamic picklist rows
     */
    @TestVisible VisualEditor.DynamicPickListRows setupRelatedObjectRows() {
        VisualEditor.DynamicPickListRows  returnList = new VisualEditor.DynamicPickListRows();

        if (context != null && context.entityName != null) {
            List<ChildRelationship> childRels =  Schema.getGlobalDescribe().get(context.entityName).getDescribe().getChildRelationships();
            for (ChildRelationship cr : childRels) {
                String lbl = cr.getChildSObject().getDescribe().getLabel()+' - '+cr.getRelationshipName();
                String val = cr.getChildSObject().getDescribe().getLocalName()+':'+cr.getField().getDescribe().getLocalName();
                for (FieldSet fs : cr.childSObject.getDescribe().fieldSets.getMap().values()) {
                    if(fs.getNameSpace() == null) returnList.addRow(new VisualEditor.DataRow(lbl+' - '+fs.getLabel(), val+':'+fs.getName()));
                }
            }
        }

        return returnList;
    }
}