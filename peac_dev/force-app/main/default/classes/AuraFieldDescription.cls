/**
 * This class is provided open source under the MIT license
 * Class for aura field description.used for translating apex field description results into
 * a generic object that can be serailzed for consumption by a lightning component
 */
global without sharing class AuraFieldDescription {
    @AuraEnabled public String fieldValue {Get;Set;}

    @AuraEnabled public String fieldName {Get;Set;}
    @AuraEnabled public String fieldLabel {Get;Set;}
    @AuraEnabled public String fieldFormat {Get;Set;}
    @AuraEnabled public String fieldType {Get;Set;}
    @AuraEnabled public String formInputType {Get;Set;}
    @AuraEnabled public String helpText {Get;Set;}
    @AuraEnabled public String targetSObjectName {Get;Set;}
    @AuraEnabled public String targetSObjectLabel {Get;Set;}
    @AuraEnabled public String targetSObjectPluralLabel {Get;Set;}
    @AuraEnabled public String relationshipName {Get;Set;}
    @AuraEnabled public String step {Get;Set;}
    @AuraEnabled public String max {Get;Set;}
    @AuraEnabled public String min {Get;Set;}

    @AuraEnabled public List<AuraSelectOption> selectOptions {Get;Set;}

    @AuraEnabled public Boolean isReadOnly {Get;Set;}
    @AuraEnabled public Boolean isRequired {Get;Set;}
    @AuraEnabled public Boolean isHidden {Get;Set;}
    @AuraEnabled public Boolean isNameField {Get;Set;}
    @AuraEnabled public Boolean isCurrency {Get;Set;}
    @AuraEnabled public Boolean isPercent {Get;Set;}
    @AuraEnabled public Boolean isInteger {Get;Set;}
    @AuraEnabled public Boolean isLong {Get;Set;}
    @AuraEnabled public Boolean isDecimal {Get;Set;}
    @AuraEnabled public Boolean isNumber {Get;Set;}
    @AuraEnabled public Boolean isIdField {Get;Set;}
    @AuraEnabled public Boolean isBoolean {Get;Set;}
    @AuraEnabled public Boolean isRefParentField {Get;Set;}
    @AuraEnabled public Boolean isPicklist {Get;Set;}
    @AuraEnabled public Boolean isDependentPicklist {Get;Set;}

    @AuraEnabled public Integer fieldLength {Get;Set;}
    @AuraEnabled public Integer fieldByteLength {Get;Set;}
    @AuraEnabled public Integer scale {Get;Set;}
    @AuraEnabled public Integer index {Get;Set;}
    @AuraEnabled public Integer precision {Get;Set;}

    public AuraFieldDescription() {}

    public AuraFieldDescription(Integer indexVal, String fieldNm, Object val) {
        this.index = indexVal;
        this.fieldName = fieldNm;
        this.fieldValue = String.valueOf(val);
    }

    public AuraFieldDescription(Integer indexVal, String fieldNm, SObject so) {
        getFieldValueFromSObject(fieldNm,so);
        this.fieldName = fieldNm;
        this.index = indexVal;
    }

    public AuraFieldDescription(Integer indexVal, DescribeFieldResult dfr, Object val) {
        this.index = indexVal == null ? 0 : indexVal;
        this.fieldValue = String.valueOf(val);
        if (dfr != null) {
            setupFromFieldResults(dfr,val);
        }
    }

    private void getFieldValueFromSObject(String fldNm, SObject so) {
        Object val;
        List<String> flds = fldNm.split('\\.');
        SObject tmp = so;
        DescribeFieldResult dfr;
        //If there are multiple field references (e.g. from Contact, Account.Name), we need to go through each level
        for (Integer i = 0; i < flds.size(); i++) {
            String currentField = flds.get(i);
            if (i+1 < flds.size()) {
                tmp = tmp.getSObject(currentField);
            } else {
                val = tmp != null ? tmp.get(currentField) : so.get(currentField);
                SObjectType sot = tmp != null ? tmp.getSObjectType() : so.getSObjectType();
                dfr = sot.getDescribe().fields.getMap().get(currentField).getDescribe();
                setupFromFieldResults(dfr,val);
                if (fldNm != null && fldNm.contains('.')) this.isReadOnly = true;
                if (String.valueOf(dfr.getType())=='DATETIME' && so != null && so.get(currentField) != null) val = Datetime.valueOf(so.get(currentField)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
        }

        this.fieldValue = this.fieldValue == null ? String.valueOf(val) : this.fieldValue;

    }

    public Object getFormattedValue() {
        Object returnObj = this.fieldValue;
        if (this.fieldValue != null && String.isNotBlank(this.fieldType)) {
            formInputType = String.isBlank(formInputType) ? apexTypeToInputTypeMap.get(this.fieldType) : formInputType;
            returnObj = this.fieldValue;
            if ((this.isNumber != null && this.isNumber) || (formInputType == 'number')) returnObj = formatNumber(this.fieldValue);
            if ((this.isBoolean != null && this.isBoolean )|| (formInputType == 'checkbox')) returnObj = formatBoolean(this.fieldValue);
            if (this.fieldType.startsWithIgnoreCase('DATE')) returnObj = formatDateType(this.fieldValue);
            //TODO: Figure out if multiselect picklists need to be reformatted or if select options need to be evaluated
        }
        return returnObj;
    }

    private void setupFromFieldResults(DescribeFieldResult dfr, Object val) {
        setStringProperties(dfr);
        if (dfr.getPicklistValues() != null) this.selectOptions = getSelectOptionsFromPicklistEntries(dfr.getPicklistValues(), String.valueOf(val));
        setBooleanProperties(dfr);
        setLimitProperties(dfr);
        setupMaxAndMin();
        setupNumberFormatting();
    }

    private void setupNumberFormatting() {
        this.fieldFormat = '';
        if (this.isNumber) {
            fieldFormat = this.isDecimal ? 'decimal' : fieldFormat;
            fieldFormat = this.isCurrency ? 'currency' : fieldFormat;
            fieldFormat = this.isPercent ?  'percent-fixed' : fieldFormat;
        }
    }

    private Object formatDateType(String strVal) {
        Object val;
        if (this.fieldType == 'DATE') val = Date.valueOf(strVal);
        if (this.fieldType == 'DATETIME') {
            if (strVal.contains('T')) {
                Integer cutOff = strVal.endsWith('Z') ? 1 : 5;
                val = DateTime.valueOfGmt(strVal.replace('T',' ').left(strVal.length()-cutOff));
            }
            if (!strVal.contains('T')) val = DateTime.valueOfGmt(strVal);
        }
        return val;
    }


    private Object formatNumber(String strVal) {
        Object val;
        if (this.isDecimal || this.isPercent || this.isCurrency) val = Decimal.valueOf(strVal.replaceAll('[^\\d\\.-]',''));
        if (this.isInteger) val = Integer.valueOf(strVal.replaceAll('[^\\d\\.-]',''));
        if (this.isLong) val = Long.valueOf(strVal.replaceAll('[^\\d\\.-]',''));
        return val;
    }

    private Object formatBoolean(String strVal) {
        return Boolean.valueOf(strVal);
    }

    private void setStringProperties(DescribeFieldResult dfr) {

        this.fieldLabel = dfr.getLabel();
        this.fieldName = dfr.getLocalName();
        this.relationshipName = dfr.getRelationshipName();
        this.fieldType = String.valueOf(dfr.getType());
        this.formInputType = apexTypeToInputTypeMap.containsKey(fieldType) ? apexTypeToInputTypeMap.get(fieldType) : this.formInputType;
        this.formInputType = String.isBlank(this.formInputType) ? this.fieldType.toLowerCase() : this.formInputType;
        this.helpText = dfr.getInlineHelpText();
        setReferenceProperties(dfr);
    }

    private void setLimitProperties(DescribeFieldResult dfr) {
        this.fieldLength = this.isNumber ? dfr.getPrecision() : dfr.getLength();
        this.fieldByteLength = dfr.getByteLength();
        this.scale = dfr.getScale();
        this.step = setupStep();
        this.precision = this.isNumber && this.fieldType != 'INTEGER' ? dfr.getPrecision() : dfr.getDigits();
    }

    private void setBooleanProperties(DescribeFieldResult dfr) {
        this.isCurrency = this.fieldType.equalsIgnoreCase('CURRENCY');
        this.isPercent = this.fieldType.equalsIgnoreCase('PERCENT');
        this.isDecimal = this.fieldType.equalsIgnoreCase('DOUBLE');
        this.isInteger = this.fieldType.equalsIgnoreCase('INTEGER');
        this.isBoolean = this.fieldType.equalsIgnoreCase('BOOLEAN');
        this.isLong = this.fieldType.equalsIgnoreCase('LONG');
        this.isNumber = apexTypeToInputTypeMap.get(this.fieldType) == 'number';
        this.isReadOnly = !dfr.isAutoNumber() && (!dfr.isUpdateable() || !dfr.isCreateable());
        this.isRequired = !dfr.isNillable();
        this.isHidden = !dfr.isAccessible();
        this.isNameField = dfr.isNameField();
        this.isRefParentField = this.fieldName != null && this.fieldName.contains('.');
        this.isPicklist = dfr.getPicklistValues() != null && !dfr.getPicklistValues().isEmpty();
        this.isDependentPicklist = dfr.isDependentPicklist();
    }

    private void setReferenceProperties(DescribeFieldResult dfr) {
        if (dfr.getReferenceTo() != null && !dfr.getReferenceTo().isEmpty()) {
            this.isIdField = true;
            DescribeSObjectResult dsr = dfr.getReferenceTo()[0].getDescribe();
            this.targetSObjectLabel = dsr.getLabel();
            this.targetSObjectPluralLabel = dsr.getLabelPlural();
            this.targetSObjectName = dsr.getLocalName();
        }
    }

    private void setupMaxAndMin() {
        if (this.isNumber && this.precision != null && this.precision > 0 && this.scale != null) {
            this.max = setupMinOrMax(false);
            this.min = setupMinOrMax(true);
        }
    }

    private String setupMinOrMax(Boolean isMin) {
        String returnString = isMin ? '-' : '';
        returnString += '9'.repeat(this.precision - this.scale);
        returnString += this.scale > 0 ? '.'+'9'.repeat(this.scale) : '';

        return returnString;
    }
    private String setupStep () {
        String returnString = '';
        if (this.scale != null && this.scale > 0) {
            returnString = '0.'+'0'.repeat(this.scale);
            returnString = returnString.left(returnString.length()-1)+'1';
        }
        return returnString;
    }

    private List<AuraSelectOption> getSelectOptionsFromPicklistEntries(List<PicklistEntry> ples, String strVal) {
        Set<String> selectedVals = strVal != null ? new Set<String>(strVal.split(';')) : new Set<String>();
        List<AuraSelectOption> returnList = new List<AuraSelectOption>{new AuraSelectOption('','--None--')};
        Boolean valFound = false;

        for (PicklistEntry ple : ples) {
            AuraSelectOption lso = new AuraSelectOption(ple);
            if (selectedVals.contains(lso.value)) {
                lso.isSelected = true;
                valFound = true;
            }
            returnList.add(lso);
        }
        if (!valFound) returnList[0].isSelected = true;

        return returnList;
    }

    private Map<String,String> apexTypeToInputTypeMap = new Map<String,String>{
            'DOUBLE' => 'number',
            'INTEGER' =>'number',
            'LONG' => 'number',
            'CURRENCY' => 'number',
            'PERCENT' => 'number',
            'PHONE'=>'tel',
            'BOOLEAN' => 'checkbox',
            'ADDRESS' => 'text',
            'ENCRYPTEDSTRING' => 'text',
            'ID'=>'text',
            'REFERENCE'=>'text',
            'STRING'=>'text'
    };
}