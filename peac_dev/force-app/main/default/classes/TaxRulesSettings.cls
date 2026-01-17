public with sharing class TaxRulesSettings {
    private Tax_Rules_Settings__c settings;
    private List<Tax_Object__mdt> parentTaxObjects;
    private List<Tax_Object__mdt> childTaxObjects;
    private List<Tax_Object__mdt> childTaxObjectsRegular;
    private Map<String, Map<String, Tax_Object__mdt>> taxObjectTypeMap;
    
    public TaxRulesSettings() {
        settings = Tax_Rules_Settings__c.getInstance();
        
        parentTaxObjects = [
            SELECT Object__r.QualifiedApiName,
            Lookup_Field_to_Parent__r.QualifiedApiName,
            Tax_State_Field__r.QualifiedApiName,
            Tax_County_Field__r.QualifiedApiName,
            Tax_City_Field__r.QualifiedApiName,
            City_Tax_Rate_Amount_Field__r.QualifiedApiName,
            City_Tax_Rate_Code_Field__r.QualifiedApiName,
            City_Tax_Rate_Field__r.QualifiedApiName,
            County_Tax_Rate_Amount_Field__r.QualifiedApiName,
            County_Tax_Rate_Code_Field__r.QualifiedApiName,
            County_Tax_Rate_Field__r.QualifiedApiName,
            State_Tax_Rate_Amount_Field__r.QualifiedApiName,
            State_Tax_Rate_Code_Field__r.QualifiedApiName,
            State_Tax_Rate_Field__r.QualifiedApiName,
            TCity_Tax_Rate_Amount_Field__r.QualifiedApiName,
            TCity_Tax_Rate_Code_Field__r.QualifiedApiName,
            TCity_Tax_Rate_Field__r.QualifiedApiName,
            TCounty_Tax_Rate_Amount_Field__r.QualifiedApiName,
            TCounty_Tax_Rate_Code_Field__r.QualifiedApiName,
            TCounty_Tax_Rate_Field__r.QualifiedApiName,
            Taxable_Field__r.QualifiedApiName,
            Date_Time_Taxes_Calculated_Field__r.QualifiedApiName,
            Tax_Type__c,
            State_Misc_Code_Field__r.QualifiedApiName,
            County_Misc_Code_Field__r.QualifiedApiName,
            City_Misc_Code_Field__r.QualifiedApiName,
            State_Late_Charge_Code_Field__r.QualifiedApiName,
            County_Late_Charge_Code_Field__r.QualifiedApiName,
            City_Late_Charge_Code_Field__r.QualifiedApiName
            FROM Tax_Object__mdt
            WHERE Object__r.QualifiedApiName = :getParentObject()
        ];
        
        childTaxObjects = [
            SELECT Object__r.QualifiedApiName,
            Lookup_Field_to_Parent__r.QualifiedApiName,
            Tax_State_Field__r.QualifiedApiName,
            Tax_County_Field__r.QualifiedApiName,
            Tax_City_Field__r.QualifiedApiName,
            City_Tax_Rate_Amount_Field__r.QualifiedApiName,
            City_Tax_Rate_Code_Field__r.QualifiedApiName,
            City_Tax_Rate_Field__r.QualifiedApiName,
            County_Tax_Rate_Amount_Field__r.QualifiedApiName,
            County_Tax_Rate_Code_Field__r.QualifiedApiName,
            County_Tax_Rate_Field__r.QualifiedApiName,
            State_Tax_Rate_Amount_Field__r.QualifiedApiName,
            State_Tax_Rate_Code_Field__r.QualifiedApiName,
            State_Tax_Rate_Field__r.QualifiedApiName,
            TCity_Tax_Rate_Amount_Field__r.QualifiedApiName,
            TCity_Tax_Rate_Code_Field__r.QualifiedApiName,
            TCity_Tax_Rate_Field__r.QualifiedApiName,
            TCounty_Tax_Rate_Amount_Field__r.QualifiedApiName,
            TCounty_Tax_Rate_Code_Field__r.QualifiedApiName,
            TCounty_Tax_Rate_Field__r.QualifiedApiName,
            Taxable_Field__r.QualifiedApiName,
            Date_Time_Taxes_Calculated_Field__r.QualifiedApiName,
            Tax_Type__c,
            State_Misc_Code_Field__r.QualifiedApiName,
            County_Misc_Code_Field__r.QualifiedApiName,
            City_Misc_Code_Field__r.QualifiedApiName,
            State_Late_Charge_Code_Field__r.QualifiedApiName,
            County_Late_Charge_Code_Field__r.QualifiedApiName,
            City_Late_Charge_Code_Field__r.QualifiedApiName
            FROM Tax_Object__mdt
            WHERE Object__r.QualifiedApiName != :getParentObject()
        ];
        
        taxObjectTypeMap = new Map<String, Map<String, Tax_Object__mdt>>();
        
        for (Tax_Object__mdt parentTaxObject : parentTaxObjects) {
            Map<String, Tax_Object__mdt> taxTypeMap = taxObjectTypeMap.get(parentTaxObject.Object__r.QualifiedApiName);
            
            if (taxTypeMap == null) {
                taxTypeMap = new Map<String, Tax_Object__mdt>();
                taxObjectTypeMap.put(parentTaxObject.Object__r.QualifiedApiName, taxTypeMap);
            }
            
            taxTypeMap.put(parentTaxObject.Tax_Type__c, parentTaxObject);
        }
        
        childTaxObjectsRegular = new List<Tax_Object__mdt>();
        
        for (Tax_Object__mdt childTaxObject : childTaxObjects) {
            Map<String, Tax_Object__mdt> taxTypeMap = taxObjectTypeMap.get(childTaxObject.Object__r.QualifiedApiName);
            
            if (taxTypeMap == null) {
                taxTypeMap = new Map<String, Tax_Object__mdt>();
                taxObjectTypeMap.put(childTaxObject.Object__r.QualifiedApiName, taxTypeMap);
            }
            
            taxTypeMap.put(childTaxObject.Tax_Type__c, childTaxObject);
            
            if (childTaxObject.Tax_Type__c == 'Regular')
                childTaxObjectsRegular.add(childTaxObject);
        }
    }

    public String getParentObject() {
        return settings.Parent_Object__c;
    }

    public String getRateObject() {
        return settings.Rate_Object__c;
    }

    public String getRateStateField() {
        return settings.Rate_State_Field__c;
    }

    public String getRateCountyField() {
        return settings.Rate_County_Field__c;
    }

    public String getRateCityField() {
        return settings.Rate_City_Field__c;
    }

    public String getRateCodeField() {
        return settings.Rate_Code_Field__c;
    }

    public String getStateTaxRateField() {
        return settings.State_Tax_Rate_Field__c;
    }

    public String getCountyTaxRateField() {
        return settings.County_Tax_Rate_Field__c;
    }

    public String getTCountyTaxRateField() {
        return settings.TCounty_Tax_Rate_Field__c;
    }

    public String getCityTaxRateField() {
        return settings.City_Tax_Rate_Field__c;
    }

    public String getTCityTaxRateField() {
        return settings.TCity_Tax_Rate_Field__c;
    }

    public String getTaxParentObjectField() {
        return settings.Tax_Parent_Object_Field__c;
    }

    public String getParentGenerateTaxMatrixMessageField() {
        return settings.Parent_Generate_Tax_Matrix_Message_Field__c;
    }

    public String getParentTaxCalculationBeginField() {
        return settings.Parent_Tax_Calculation_Begin_Field__c;
    }

    public String getParentTaxCalculationCompleteField() {
        return settings.Parent_Tax_Calculation_Complete_Field__c;
    }

    public String getParentTaxCalculationSuccessfulField() {
        return settings.Parent_Tax_Calculation_Successful_Field__c;
    }

    public String getParentTaxCalculationErrorField() {
        return settings.Parent_Tax_Calculation_Error_Field__c;
    }

    public String getParentTaxCalculationInProgressField() {
        return settings.Parent_Tax_Calculation_In_Progress_Field__c;
    }
    
    public Boolean getUsePlatformEventInsteadOfFuture () {
        return settings.Use_Platform_Event_Instead_of_Future__c == null ? false : settings.Use_Platform_Event_Instead_of_Future__c;
    }

    public Decimal getTaxCalculationCompletionAlertSeconds() {
        return settings.Tax_Calculation_Completion_Alert_Seconds__c;
    }
    
    public Tax_Object__mdt getParentTaxObject() {
        return getTaxObject(getParentObject(), 'Regular');
    }
    
    public List<Tax_Object__mdt> getChildTaxObjects() {
        return childTaxObjectsRegular;
    }
    
    public Tax_Object__mdt getTaxObject(String objectType, String taxType) {
        Tax_Object__mdt taxObject = null;
        
        if (String.isEmpty(taxType))
            throw new TaxRulesSettingsException('Please ensure all Tax Rules have Tax Type selected.');
        
        if (taxObjectTypeMap.get(objectType) != null)
            taxObject = taxObjectTypeMap.get(objectType).get(taxType);
        
        return taxObject;
    }
    
    public List<Tax_Object__mdt> getTaxObjects(String objectType) {
        List<Tax_Object__mdt> taxObjects = new List<Tax_Object__mdt>();
        Map<String, Tax_Object__mdt> taxTypeMap = taxObjectTypeMap.get(objectType);
        
        if (taxTypeMap != null) {
            for (String taxType : taxTypeMap.keySet()) {
                taxObjects.add(taxTypeMap.get(taxType));
            }
        }
        
        return taxObjects;
    }
    
    public class TaxRulesSettingsException extends Exception {}
}