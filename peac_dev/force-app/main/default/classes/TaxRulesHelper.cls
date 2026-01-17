/**
 * @description       : This helper class is used to provide utility methods for the Tax Rules Engine to use.
 * @author            : lvang@northteq.com
 * @group             :
 * @last modified on  : 02-20-2025
 * @last modified by  : lvang@northteq.com
 **/
public class TaxRulesHelper {

    private static TaxRulesSettings settings;

    public static TaxRulesSettings getSettings() {
        if (settings == null)
            settings = new TaxRulesSettings();

        return settings;
    }

    static Map<String, Set<String> > sObjectToFieldDurableIds;
    static Map<String, Set<String> > sObjectToQualifiedFieldNames;

    static Set<String> rateCodes = new Set<String> {'001', '100', '150', '060'};

    static List<String> fields = new List<String> {
        'Tax_State_Field__c',
        'Tax_County_Field__c',
        'Tax_City_Field__c',
        'City_Tax_Rate_Amount_Field__c',
        'City_Tax_Rate_Code_Field__c',
        'City_Tax_Rate_Field__c',
        'County_Tax_Rate_Amount_Field__c',
        'County_Tax_Rate_Code_Field__c',
        'County_Tax_Rate_Field__c',
        'State_Tax_Rate_Amount_Field__c',
        'State_Tax_Rate_Code_Field__c',
        'State_Tax_Rate_Field__c',
        'TCity_Tax_Rate_Amount_Field__c',
        'TCity_Tax_Rate_Code_Field__c',
        'TCity_Tax_Rate_Field__c',
        'TCounty_Tax_Rate_Amount_Field__c',
        'TCounty_Tax_Rate_Code_Field__c',
        'TCounty_Tax_Rate_Field__c',
        'State_Misc_Code_Field__c',
        'County_Misc_Code_Field__c',
        'City_Misc_Code_Field__c',
        'State_Late_Charge_Code_Field__c',
        'County_Late_Charge_Code_Field__c',
        'City_Late_Charge_Code_Field__c'
    };

    /**
     * @description : Creates a query string based on the fields, object name, and record id provided.
     * @author lvang@northteq.com | 02-20-2025
     * @param recordId
     * @param objectQueryFieldsMap
     * @param to
     * @return String
     **/
    public static String createQueryString(String recordId, Map<String, Set<String> > objectQueryFieldsMap, Tax_Object__mdt to) {
        Set<String> recordQueryFields = new Set<String>();
        recordQueryFields.add(to.Lookup_Field_to_Parent__r.QualifiedApiName);
        Set<String> qualifiedApiFieldNames = getQualifiedFieldNames(to.Object__r.QualifiedApiName);
        for (String field : qualifiedApiFieldNames){
            recordQueryFields.add(field);
        }
        for (String field : objectQueryFieldsMap.get(to.Object__r.QualifiedApiName)){
            recordQueryFields.add(field);
        }
        String recordQuery = createQueryString(recordQueryFields, to.Object__r.QualifiedApiName, to.Lookup_Field_to_Parent__r.QualifiedApiName, recordId);

        return recordQuery;
    }

    /**
     * @description clears related tax object fields
     * @TODO: Refactor this method to be more efficient
     * @author lvang@northteq.com | 02-20-2025
     * @param record
     * @param taxObjects
     **/
    public static void clearTaxObjectFields(SObject record, List<Tax_Object__mdt> taxObjects) {
        for (Tax_Object__mdt taxObject : taxObjects) {
            String rateCode;
            Boolean upfront = taxObject.Tax_Type__c == 'Upfront';

            if (String.isNotEmpty(taxObject.State_Tax_Rate_Code_Field__c)) {
                rateCode = (String) record.get(taxObject.State_Tax_Rate_Code_Field__r.QualifiedApiName);

                if (rateCodes.contains(rateCode)) {
                    record.put(taxObject.State_Tax_Rate_Code_Field__r.QualifiedApiName, null);

                    if (String.isNotEmpty(taxObject.State_Tax_Rate_Amount_Field__c)) record.put(taxObject.State_Tax_Rate_Amount_Field__r.QualifiedApiName, null);
                    
                    if (String.isNotEmpty(taxObject.State_Tax_Rate_Field__c)) record.put(taxObject.State_Tax_Rate_Field__r.QualifiedApiName, null);
                    
                }else{
                    upfront = false;
                }
            }else{
                upfront = false;
            }

            rateCode = String.isNotEmpty(taxObject.City_Tax_Rate_Code_Field__c) ? (String) record.get(taxObject.City_Tax_Rate_Code_Field__r.QualifiedApiName) : '';

            if (rateCodes.contains(rateCode) || upfront) {
                if (String.isNotEmpty(taxObject.City_Tax_Rate_Amount_Field__c)) record.put(taxObject.City_Tax_Rate_Amount_Field__r.QualifiedApiName, null);

                if (String.isNotEmpty(taxObject.City_Tax_Rate_Field__c)) record.put(taxObject.City_Tax_Rate_Field__r.QualifiedApiName, null);
                
            }


            rateCode = String.isNotEmpty(taxObject.County_Tax_Rate_Code_Field__c) ? (String) record.get(taxObject.County_Tax_Rate_Code_Field__r.QualifiedApiName) : '';

            if (rateCodes.contains(rateCode) || upfront) {
                if (String.isNotEmpty(taxObject.County_Tax_Rate_Amount_Field__c)) record.put(taxObject.County_Tax_Rate_Amount_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.County_Tax_Rate_Field__c)) record.put(taxObject.County_Tax_Rate_Field__r.QualifiedApiName, null);
                
            }

            rateCode = String.isNotEmpty(taxObject.State_Tax_Rate_Code_Field__c) ? (String) record.get(taxObject.State_Tax_Rate_Code_Field__r.QualifiedApiName) : '';

            if (rateCodes.contains(rateCode) || upfront) {
                if (String.isNotEmpty(taxObject.State_Tax_Rate_Code_Field__c)) record.put(taxObject.State_Tax_Rate_Code_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.State_Tax_Rate_Amount_Field__c)) record.put(taxObject.State_Tax_Rate_Amount_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.State_Tax_Rate_Field__c)) record.put(taxObject.State_Tax_Rate_Field__r.QualifiedApiName, null);
                
            }


            rateCode = String.isNotEmpty(taxObject.City_Tax_Rate_Code_Field__c) ? (String) record.get(taxObject.City_Tax_Rate_Code_Field__r.QualifiedApiName) : '';

            if (rateCodes.contains(rateCode) || upfront) {
                if (String.isNotEmpty(taxObject.City_Tax_Rate_Code_Field__c)) record.put(taxObject.City_Tax_Rate_Code_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.TCity_Tax_Rate_Code_Field__c)) record.put(taxObject.TCity_Tax_Rate_Code_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.TCity_Tax_Rate_Amount_Field__c)) record.put(taxObject.TCity_Tax_Rate_Amount_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.TCity_Tax_Rate_Field__c)) record.put(taxObject.TCity_Tax_Rate_Field__r.QualifiedApiName, null);
                
            }

            rateCode = String.isNotEmpty(taxObject.County_Tax_Rate_Code_Field__c) ? (String) record.get(taxObject.County_Tax_Rate_Code_Field__r.QualifiedApiName) : '';

            if (rateCodes.contains(rateCode) || upfront) {
                if (String.isNotEmpty(taxObject.County_Tax_Rate_Code_Field__c)) record.put(taxObject.County_Tax_Rate_Code_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.TCounty_Tax_Rate_Code_Field__c)) record.put(taxObject.TCounty_Tax_Rate_Code_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.TCounty_Tax_Rate_Amount_Field__c)) record.put(taxObject.TCounty_Tax_Rate_Amount_Field__r.QualifiedApiName, null);
                

                if (String.isNotEmpty(taxObject.TCounty_Tax_Rate_Field__c)) record.put(taxObject.TCounty_Tax_Rate_Field__r.QualifiedApiName, null);
                
            }

            if (String.isNotEmpty(taxObject.Taxable_Field__c)){
                record.put(taxObject.Taxable_Field__r.QualifiedApiName, false);
            }

            if (String.isNotEmpty(taxObject.Date_Time_Taxes_Calculated_Field__c)){
                record.put(taxObject.Date_Time_Taxes_Calculated_Field__r.QualifiedApiName, System.now());
            }

            rateCode = String.isNotEmpty(taxObject.State_Misc_Code_Field__c) ? (String) record.get(taxObject.State_Misc_Code_Field__r.QualifiedApiName) : '';

            if ((rateCodes.contains(rateCode) || upfront) && String.isNotEmpty(taxObject.State_Misc_Code_Field__c)) record.put(taxObject.State_Misc_Code_Field__r.QualifiedApiName, null);
            

            rateCode = String.isNotEmpty(taxObject.County_Misc_Code_Field__c) ? (String) record.get(taxObject.County_Misc_Code_Field__r.QualifiedApiName) : '';

            if ((rateCodes.contains(rateCode) || upfront) && String.isNotEmpty(taxObject.County_Misc_Code_Field__c)) record.put(taxObject.County_Misc_Code_Field__r.QualifiedApiName, null);
            

            rateCode = String.isNotEmpty(taxObject.City_Misc_Code_Field__c) ? (String) record.get(taxObject.City_Misc_Code_Field__r.QualifiedApiName) : '';

            if ((rateCodes.contains(rateCode) || upfront) && String.isNotEmpty(taxObject.City_Misc_Code_Field__c)) record.put(taxObject.City_Misc_Code_Field__r.QualifiedApiName, null);
            

            rateCode = String.isNotEmpty(taxObject.State_Late_Charge_Code_Field__c) ? (String) record.get(taxObject.State_Late_Charge_Code_Field__r.QualifiedApiName) : '';

            if ((rateCodes.contains(rateCode) || upfront) && String.isNotEmpty(taxObject.State_Late_Charge_Code_Field__c)) record.put(taxObject.State_Late_Charge_Code_Field__r.QualifiedApiName, null);
            

            rateCode = String.isNotEmpty(taxObject.County_Late_Charge_Code_Field__c) ? (String) record.get(taxObject.County_Late_Charge_Code_Field__r.QualifiedApiName) : '';

            if ((rateCodes.contains(rateCode) || upfront) && String.isNotEmpty(taxObject.County_Late_Charge_Code_Field__c)) record.put(taxObject.County_Late_Charge_Code_Field__r.QualifiedApiName, null);
            

            rateCode = String.isNotEmpty(taxObject.City_Late_Charge_Code_Field__c) ? (String) record.get(taxObject.City_Late_Charge_Code_Field__r.QualifiedApiName) : '';

            if ((rateCodes.contains(rateCode) || upfront) && String.isNotEmpty(taxObject.City_Late_Charge_Code_Field__c)) record.put(taxObject.City_Late_Charge_Code_Field__r.QualifiedApiName, null);
            
        }
    }



    /**
     * @description : Create a Tax Matrix record from a Tax Rule and Tax Values
     * @TODO: Refactor this method to be more efficient
     * @author lvang@northteq.com | 02-20-2025
     * @param record
     * @param taxRule
     * @param taxValues
     * @param rateMap
     * @return Tax_Matrix__c
     **/
    public static Tax_Matrix__c createTaxMatrix(SObject record, Tax_Rule__c taxRule, TaxValues taxValues, Map<String, Map<String, Map<String, Map<String, SObject> > > > rateMap) {
        System.debug(rateMap);
        Map<String, Map<String, Map<String, SObject> > > countyMap = rateMap.get(taxValues.state);
        System.debug(countyMap);
        System.debug(taxValues.county);
        Map<String, Map<String, SObject> > cityMap = countyMap.get(taxValues.county);
        Map<String, SObject> taxCodeMap = cityMap.get(taxValues.city);
        system.debug(cityMap);
        System.debug(taxValues.city);
        System.debug(taxRule.Rate_Code_to_Use__c);
        System.debug(taxCodeMap);
        SObject rate = taxCodemap.get(taxRule.Rate_Code_to_Use__c);
        
        Tax_Matrix__c taxMatrix = new Tax_Matrix__c(
            Tax_Object__c = record.getSObjectType().getDescribe().getLabel(),
            State_Rate__c = (Decimal) rate.get(getSettings().getStateTaxRateField()),
            County_Rate__c = (Decimal) rate.get(getSettings().getCountyTaxRateField()),
            TCounty_Rate__c = (Decimal) rate.get(getSettings().getTCountyTaxRateField()),
            City_Rate__c = (Decimal) rate.get(getSettings().getCityTaxRateField()),
            TCity_Rate__c = (Decimal) rate.get(getSettings().getTCityTaxRateField()),
            Tax_Record_Name__c = taxValues.recordName,
            Tax_Record_Id__c = record.Id
            );

        taxMatrix.put(getSettings().getTaxParentObjectField(), taxValues.parentId == null ? record.Id : taxValues.parentId);

        if (taxRule.Tax_Basis_Field__c.contains('.')) {
            String[] rField = taxRule.Tax_Basis_Field__c.split('\\.', 2);
            taxMatrix.Tax_Basis__c = (Decimal) record.getSObject(rField[0]).get(rField[1]);
        }
        else{
            taxMatrix.Tax_Basis__c = (Decimal) record.get(taxRule.Tax_Basis_Field__c);
        }

        if (String.isNotEmpty(taxRule.State_Rate_Code_to_Use__c)) taxMatrix.State_Rate__c = (Decimal) taxCodemap.get(taxRule.State_Rate_Code_to_Use__c).get(getSettings().getStateTaxRateField());

        if (String.isNotEmpty(taxRule.County_Rate_Code_to_Use__c)) taxMatrix.County_Rate__c = (Decimal) taxCodemap.get(taxRule.County_Rate_Code_to_Use__c).get(getSettings().getCountyTaxRateField());

        if (String.isNotEmpty(taxRule.TCounty_Rate_Code_to_Use__c)) taxMatrix.TCounty_Rate__c = (Decimal) taxCodemap.get(taxRule.TCounty_Rate_Code_to_Use__c).get(getSettings().getTCountyTaxRateField());

        if (String.isNotEmpty(taxRule.City_Rate_Code_to_Use__c)) taxMatrix.City_Rate__c = (Decimal) taxCodemap.get(taxRule.City_Rate_Code_to_Use__c).get(getSettings().getCityTaxRateField());

        if (String.isNotEmpty(taxRule.TCity_Rate_Code_to_Use__c)) taxMatrix.TCity_Rate__c = (Decimal) taxCodemap.get(taxRule.TCity_Rate_Code_to_Use__c).get(getSettings().getTCityTaxRateField());

        Tax_Object__mdt taxObject = getSettings().getTaxObject(record.getSObjectType().getDescribe().getName(), taxRule.Tax_Type__c);

        if (taxObject == null) {
            throw new TaxRules.TaxRulesException('Please set up a Taxable Object with Object = "' + record.getSObjectType().getDescribe().getLabel() + '" and Tax Type = "' + taxRule.Tax_Type__c + '".');
        }

        if (String.isNotEmpty(taxObject.City_Tax_Rate_Amount_Field__c) && (record.get(taxObject.City_Tax_Rate_Amount_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.City_Tax_Rate_Amount_Field__r.QualifiedApiName) == 0))
            record.put(taxObject.City_Tax_Rate_Amount_Field__r.QualifiedApiName, (taxMatrix.Tax_Basis__c * taxMatrix.City_Rate__c * 0.01).setScale(2, RoundingMode.HALF_UP));

        if (String.isNotEmpty(taxObject.City_Tax_Rate_Code_Field__c) && (record.get(taxObject.City_Tax_Rate_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.City_Tax_Rate_Code_Field__r.QualifiedApiName))))
            record.put(taxObject.City_Tax_Rate_Code_Field__r.QualifiedApiName,
                       String.isNotEmpty(taxRule.City_Rate_Code_to_Use__c) ? taxRule.City_Rate_Code_to_Use__c : taxRule.Rate_Code_to_Use__c);

        if (String.isNotEmpty(taxObject.City_Tax_Rate_Field__c) && (record.get(taxObject.City_Tax_Rate_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.City_Tax_Rate_Field__r.QualifiedApiName) == 0))  record.put(taxObject.City_Tax_Rate_Field__r.QualifiedApiName, taxMatrix.City_Rate__c);

        if (String.isNotEmpty(taxObject.County_Tax_Rate_Amount_Field__c) && (record.get(taxObject.County_Tax_Rate_Amount_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.County_Tax_Rate_Amount_Field__r.QualifiedApiName) == 0)) record.put(taxObject.County_Tax_Rate_Amount_Field__r.QualifiedApiName, (taxMatrix.Tax_Basis__c * taxMatrix.County_Rate__c * 0.01).setScale(2, RoundingMode.HALF_UP));

        if (String.isNotEmpty(taxObject.County_Tax_Rate_Code_Field__c) && (record.get(taxObject.County_Tax_Rate_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.County_Tax_Rate_Code_Field__r.QualifiedApiName))))
            record.put(taxObject.County_Tax_Rate_Code_Field__r.QualifiedApiName,
                       String.isNotEmpty(taxRule.County_Rate_Code_to_Use__c) ? taxRule.County_Rate_Code_to_Use__c : taxRule.Rate_Code_to_Use__c);

        if (String.isNotEmpty(taxObject.County_Tax_Rate_Field__c) && (record.get(taxObject.County_Tax_Rate_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.County_Tax_Rate_Field__r.QualifiedApiName) == 0))  record.put(taxObject.County_Tax_Rate_Field__r.QualifiedApiName, taxMatrix.County_Rate__c);

        if (String.isNotEmpty(taxObject.State_Tax_Rate_Amount_Field__c) && (record.get(taxObject.State_Tax_Rate_Amount_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.State_Tax_Rate_Amount_Field__r.QualifiedApiName) == 0)) record.put(taxObject.State_Tax_Rate_Amount_Field__r.QualifiedApiName, (taxMatrix.Tax_Basis__c * taxMatrix.State_Rate__c * 0.01).setScale(2, RoundingMode.HALF_UP));

        if (String.isNotEmpty(taxObject.State_Tax_Rate_Code_Field__c) && (record.get(taxObject.State_Tax_Rate_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.State_Tax_Rate_Code_Field__r.QualifiedApiName))))
            record.put(taxObject.State_Tax_Rate_Code_Field__r.QualifiedApiName,
                       String.isNotEmpty(taxRule.State_Rate_Code_to_Use__c) ? taxRule.State_Rate_Code_to_Use__c : taxRule.Rate_Code_to_Use__c);

        if (String.isNotEmpty(taxObject.State_Tax_Rate_Field__c) && (record.get(taxObject.State_Tax_Rate_Field__r.QualifiedApiName) == null  || (Decimal) record.get(taxObject.State_Tax_Rate_Field__r.QualifiedApiName) == 0)) record.put(taxObject.State_Tax_Rate_Field__r.QualifiedApiName, taxMatrix.State_Rate__c);

        if (String.isNotEmpty(taxObject.TCity_Tax_Rate_Amount_Field__c) && (record.get(taxObject.TCity_Tax_Rate_Amount_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.TCity_Tax_Rate_Amount_Field__r.QualifiedApiName) == 0)) record.put(taxObject.TCity_Tax_Rate_Amount_Field__r.QualifiedApiName, (taxMatrix.Tax_Basis__c * taxMatrix.TCity_Rate__c * 0.01).setScale(2, RoundingMode.HALF_UP));

        if (String.isNotEmpty(taxObject.TCity_Tax_Rate_Code_Field__c) && (record.get(taxObject.TCity_Tax_Rate_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.TCity_Tax_Rate_Code_Field__r.QualifiedApiName))))
            record.put(taxObject.TCity_Tax_Rate_Code_Field__r.QualifiedApiName,
                       String.isNotEmpty(taxRule.TCity_Rate_Code_to_Use__c) ? taxRule.TCity_Rate_Code_to_Use__c : taxRule.Rate_Code_to_Use__c);

        if (String.isNotEmpty(taxObject.TCity_Tax_Rate_Field__c) && (record.get(taxObject.TCity_Tax_Rate_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.TCity_Tax_Rate_Field__r.QualifiedApiName) == 0)) record.put(taxObject.TCity_Tax_Rate_Field__r.QualifiedApiName, taxMatrix.TCity_Rate__c);

        if (String.isNotEmpty(taxObject.TCounty_Tax_Rate_Amount_Field__c) && (record.get(taxObject.TCounty_Tax_Rate_Amount_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.TCounty_Tax_Rate_Amount_Field__r.QualifiedApiName) == 0)) record.put(taxObject.TCounty_Tax_Rate_Amount_Field__r.QualifiedApiName, (taxMatrix.Tax_Basis__c * taxMatrix.TCounty_Rate__c * 0.01).setScale(2, RoundingMode.HALF_UP));

        if (String.isNotEmpty(taxObject.TCounty_Tax_Rate_Code_Field__c) && (record.get(taxObject.TCounty_Tax_Rate_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.TCounty_Tax_Rate_Code_Field__r.QualifiedApiName))))
            record.put(taxObject.TCounty_Tax_Rate_Code_Field__r.QualifiedApiName,
                       String.isNotEmpty(taxRule.TCounty_Rate_Code_to_Use__c) ? taxRule.TCounty_Rate_Code_to_Use__c : taxRule.Rate_Code_to_Use__c);

        if (String.isNotEmpty(taxObject.TCounty_Tax_Rate_Field__c) && (record.get(taxObject.TCounty_Tax_Rate_Field__r.QualifiedApiName) == null || (Decimal) record.get(taxObject.TCounty_Tax_Rate_Field__r.QualifiedApiName) == 0)) record.put(taxObject.TCounty_Tax_Rate_Field__r.QualifiedApiName, taxMatrix.TCounty_Rate__c);

        if (String.isNotEmpty(taxObject.Taxable_Field__c)) record.put(taxObject.Taxable_Field__r.QualifiedApiName, true);

        if (String.isNotEmpty(taxObject.Date_Time_Taxes_Calculated_Field__c)) record.put(taxObject.Date_Time_Taxes_Calculated_Field__r.QualifiedApiName, System.now());

        if (String.isNotEmpty(taxObject.State_Misc_Code_Field__c) && (record.get(taxObject.State_Misc_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.State_Misc_Code_Field__r.QualifiedApiName)))) record.put(taxObject.State_Misc_Code_Field__r.QualifiedApiName, taxRule.State_Misc_Code__c);

        if (String.isNotEmpty(taxObject.County_Misc_Code_Field__c) && (record.get(taxObject.County_Misc_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.County_Misc_Code_Field__r.QualifiedApiName)))) record.put(taxObject.County_Misc_Code_Field__r.QualifiedApiName, taxRule.County_Misc_Code__c);

        if (String.isNotEmpty(taxObject.City_Misc_Code_Field__c) && (record.get(taxObject.City_Misc_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.City_Misc_Code_Field__r.QualifiedApiName)))) record.put(taxObject.City_Misc_Code_Field__r.QualifiedApiName, taxRule.City_Misc_Code__c);

        if (String.isNotEmpty(taxObject.State_Late_Charge_Code_Field__c) && (record.get(taxObject.State_Late_Charge_Code_Field__r.QualifiedApiName) == null|| String.isEmpty((String) record.get(taxObject.State_Late_Charge_Code_Field__r.QualifiedApiName)))) record.put(taxObject.State_Late_Charge_Code_Field__r.QualifiedApiName, taxRule.State_Late_Charge_Code__c);

        if (String.isNotEmpty(taxObject.County_Late_Charge_Code_Field__c) && (record.get(taxObject.County_Late_Charge_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.County_Late_Charge_Code_Field__r.QualifiedApiName)))) record.put(taxObject.County_Late_Charge_Code_Field__r.QualifiedApiName, taxRule.County_Late_Charge_Code__c);

        if (String.isNotEmpty(taxObject.City_Late_Charge_Code_Field__c) && (record.get(taxObject.City_Late_Charge_Code_Field__r.QualifiedApiName) == null || String.isEmpty((String) record.get(taxObject.City_Late_Charge_Code_Field__r.QualifiedApiName)))) record.put(taxObject.City_Late_Charge_Code_Field__r.QualifiedApiName, taxRule.City_Late_Charge_Code__c);

        return taxMatrix;
    }

    /**
     * @description : Creates a query string based on the fields, object name, and key provided.
     * @author lvang@northteq.com | 02-20-2025
     * @param queryFields
     * @param objectType
     * @param keyField
     * @param key
     * @return String
     **/
    public static String createQueryString(Set<String> queryFields, String objectType, String keyField, String key) {
        if (queryFields.contains(null)){
            queryFields.remove(null);
        }
        String query = 'SELECT ';
        Integer counter = 1;

        for (String field : queryFields) {
            query += field;

            if (counter < queryFields.size())
                query += ', ';

            counter++;
        }
        query += ' FROM ' + objectType;
        if (keyField != null && key != null){
            query += ' WHERE '+ keyField + ' = \'' + key + '\'';
        }
        return query;
    }

    /**
     * @description : Generates a rate map based on the rates provided.
     * @author lvang@northteq.com | 02-20-2025
     * @param rates
     * @return Map<String, Map<String, Map<String, Map<String, SObject>>>>
     **/
    public static Map<String, Map<String, Map<String, Map<String, SObject> > > > generateRateMap(List<SObject> rates) {
        Map<String, Map<String, Map<String, Map<String, SObject> > > > rateMap = new Map<String, Map<String, Map<String, Map<String, SObject> > > >();
	System.debug(rates);
        for (SObject rate : rates) {
            String state = (String) rate.get(getSettings().getRateStateField());
            Map<String, Map<String, Map<String, SObject> > > countyMap = rateMap.get(state);

            if (countyMap == null) {
                countyMap = new Map<String, Map<String, Map<String, SObject> > >();
                rateMap.put(state, countyMap);
            }

            String county = (String) rate.get(getSettings().getRateCountyField());
            Map<String, Map<String, SObject> > cityMap = countyMap.get(county);

            if (cityMap == null) {
                cityMap = new Map<String, Map<String, SObject> >();
                countyMap.put(county, cityMap);
            }

            String city = (String) rate.get(getSettings().getRateCityField());
            Map<String, SObject> taxCodeMap = cityMap.get(city);

            if (taxCodeMap == null) {
                taxCodeMap = new Map<String, SObject>();
                cityMap.put(city, taxCodeMap);
            }

            taxCodeMap.put((String) rate.get(getSettings().getRateCodeField()), rate);
        }

        return rateMap;
    }

    /**
     * @description : This method is used to get the qualified field names based on the fields collection at top
     * @author lvang@northteq.com | 02-20-2025
     * @param taxObjectApiName
     * @return Set<String>
     **/
    static Set<String> getQualifiedFieldNames(String taxObjectApiName){
        Set<String> fieldDurableIds = getFieldDurableIds(taxObjectApiName);
        if(sObjectToQualifiedFieldNames == null || sObjectToQualifiedFieldNames.get(taxObjectApiName) == null){
            sObjectToQualifiedFieldNames = new Map<String, Set<String> >();
            Set<String> qualifiedFieldNames = new Set<String>();
            for(FieldDefinition fd : [SELECT QualifiedApiName FROM FieldDefinition WHERE DurableId IN :fieldDurableIds]){
                qualifiedFieldNames.add(fd.QualifiedApiName);
            }
            sObjectToQualifiedFieldNames.put(taxObjectApiName, qualifiedFieldNames);
        }
        return sObjectToQualifiedFieldNames.get(taxObjectApiName);
    }

    /**
     * @description : This method is used to get the field Durable Ids based on the fields collection at top
     * @author lvang@northteq.com | 02-20-2025
     * @param taxObjectApiName
     * @return Set<Id>
     **/
    static Set<String> getFieldDurableIds(String taxObjectApiName){
        if(sObjectToFieldDurableIds == null || sObjectToFieldDurableIds.get(taxObjectApiName) == null){
            sObjectToFieldDurableIds = new Map<String, Set<String> >();
            Set<String> fieldDurableIds = new Set<String>();
            for (Tax_Object__mdt taxObject : getSettings().getTaxObjects(taxObjectApiName)) {
                for(String field : fields){
                    if (taxObject.get(field) != null && String.isNotEmpty((String) taxObject.get(field))) {
                        fieldDurableIds.add((String) taxObject.get(field));
                    }
                }
            }
            sObjectToFieldDurableIds.put(taxObjectApiName, fieldDurableIds);
        }
        return sObjectToFieldDurableIds.get(taxObjectApiName);
    }


    /**
     * @description : This method is used to fire a platform event to notify record Id of tax rule job status
     * @author lvang@northteq.com | 02-20-2025
     * @param recordId
     * @param status
     **/
    public static void generateTaxMatrixPlatformEvent (String recordId, String status) {
        EventBus.publish (new Run_Tax_Rules__e  (Record_Id__c = recordId, Status__c = status));
    }

}