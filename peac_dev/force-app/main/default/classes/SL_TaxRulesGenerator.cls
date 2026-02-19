public without sharing class SL_TaxRulesGenerator {
    public static void generateFromCsv(Boolean justCheck) {
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = 'SAL_5860'];
        String csvData = resource.Body.toString();
        Map<String, List<List<String>>> rulesByState = new Map<String, List<List<String>>>();
        Map<String, String> stateLabelsByCode = new Map<String, String>{
            'AL' => 'Alabama',
            'AK' => 'Alaska',
            'AZ' => 'Arizona',
            'AR' => 'Arkansas',
            'CA' => 'California',
            'CO' => 'Colorado',
            'CT' => 'Connecticut',
            'DC' => 'District of Columbia',
            'DE' => 'Delaware',
            'FL' => 'Florida',
            'GA' => 'Georgia',
            'HI' => 'Hawaii',
            'ID' => 'Idaho',
            'IL' => 'Illinois',
            'IN' => 'Indiana',
            'IA' => 'Iowa',
            'KS' => 'Kansas',
            'KY' => 'Kentucky',
            'LA' => 'Louisiana',
            'ME' => 'Maine',
            'MD' => 'Maryland',
            'MA' => 'Massachusetts',
            'MI' => 'Michigan',
            'MN' => 'Minnesota',
            'MS' => 'Mississippi',
            'MO' => 'Missouri',
            'MT' => 'Montana',
            'NE' => 'Nebraska',
            'NV' => 'Nevada',
            'NH' => 'New Hamphsire',
            'NJ' => 'New Jersey',
            'NM' => 'New Mexico',
            'NY' => 'New York',
            'NC' => 'North Carolina',
            'ND' => 'North Dakota',
            'OH' => 'Ohio',
            'OK' => 'Oklahoma',
            'OR' => 'Oregon',
            'PA' => 'Pennsylvania',
            'RI' => 'Rhode Island',
            'SC' => 'South Carolina',
            'SD' => 'South Dakota',
            'TN' => 'Tennessee',
            'TX' => 'Texas',
            'UT' => 'Utah',
            'VT' => 'Vermont',
            'VA' => 'Virginia',
            'WA' => 'Washington',
            'WV' => 'West Virginia',
            'WI' => 'Wisconsin',
            'WY' => 'Wyoming'
        };
        for(String stateCode :stateLabelsByCode.keySet()){
            String stateLabel = stateLabelsByCode.get(stateCode);
            stateLabel = stateLabel.toUpperCase();
            rulesByState.put(stateLabel, new List<List<String>>());
            stateLabelsByCode.put(stateCode, stateLabel);
        }
        List<String> csvTaxKeys = new List<String>{'late charges','IR', 'INS', 'DOC', 'UPS, WIRE  ,  PROG PYMNT PENALTY FEE,   DELV GUAR FEE',
            'CONV FEE', 'PPTX', 'FLA DOC STAMP TAX', 'Maintenance Billed As Misc Billable or Invoiced'};
        Map<String, List<String>> glCodesBillInvoice = new Map<String, List<String>>{
            'late charges' => new List<String>{ /* 'Misc_GL_Code__c=0039 - PA Sales Tax - Late Fees', 'Misc_GL_Code__c=1050 - Late Fees Other',
                'GL_Code__c=0039 - PA Sales Tax - Late Fees', 'GL_Code__c=1050 - Late Fees Other' */ },
            'IR' => new List<String>{'Misc_GL_Code__c=0001 - Interim Rent',
                'GL_Code__c=0001 - Interim Rent', 'GL_Code__c=0081 - Interim Rent Dealer', 'GL_Code__c=0115 - Interim Maintenance'},
            'INS' => new List<String>{ /* */ },
            'DOC' => new List<String>{'Misc_GL_Code__c=0003 - OneTime Documentation Fee',
                'Misc_GL_Code__c=0083 - Shared Doc Fee Dealer',
                'GL_Code__c=0003 - OneTime Documentation Fee',
                'GL_Code__c=0083 - Shared Doc Fee Dealer'},
            'UPS, WIRE  ,  PROG PYMNT PENALTY FEE,   DELV GUAR FEE' => new List<String>{'Misc_GL_Code__c=0040 - Progress Payment Fees',
                'Misc_GL_Code__c=0042 - UPS SHIPPING FEE',
                'GL_Code__c=0040 - Progress Payment Fees',
                'GL_Code__c=0042 - UPS SHIPPING FEE'},
            'CONV FEE' => new List<String>{'Misc_GL_Code__c=0090 - Convenience Fee',
                'GL_Code__c=0090 - Convenience Fee'},
            'PPTX' => new List<String>{'Misc_GL_Code__c=0018 - Property Tax',
                'GL_Code__c=0018 - Property Tax'},
            'FLA DOC STAMP TAX' => new List<String>{'Misc_GL_Code__c=0019 - Fla Doc Stamp Tax',
                'GL_Code__c=0019 - Fla Doc Stamp Tax'},
            'Maintenance Billed As Misc Billable or Invoiced' => new List<String>{ 'Misc_GL_Code__c=0017 - Service Contract', 'Misc_GL_Code__c=0085 - Supply Freight Fee',
                 'GL_Code__c=0017 - Service Contract', 'GL_Code__c=0085 - Supply Freight Fee' }
        };
        Map<String, Map<String, TCRE__Rule_Condition__c>> conditionTemplates = new Map<String, Map<String, TCRE__Rule_Condition__c>>{
            'Miscellaneous_Billable_Item__c' => new Map<String, TCRE__Rule_Condition__c>{
                'Misc_GL_Code__c=0001 - Interim Rent' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0001 - Interim Rent'),
                'Misc_GL_Code__c=0003 - OneTime Documentation Fee' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0003 - OneTime Documentation Fee'),
                'Misc_GL_Code__c=0083 - Shared Doc Fee Dealer' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0083 - Shared Doc Fee Dealer'),
                'Misc_GL_Code__c=0040 - Progress Payment Fees' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0040 - Progress Payment Fees'),
                'Misc_GL_Code__c=0042 - UPS SHIPPING FEE' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0042 - UPS SHIPPING FEE'),
                'Misc_GL_Code__c=0090 - Convenience Fee' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0090 - Convenience Fee'),
                'Misc_GL_Code__c=0018 - Property Tax' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0018 - Property Tax'),
                'Misc_GL_Code__c=0019 - Fla Doc Stamp Tax' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0019 - Fla Doc Stamp Tax'),
                'Misc_GL_Code__c=0017 - Service Contract' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0017 - Service Contract'),
                'Misc_GL_Code__c=0085 - Supply Freight Fee' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Misc_GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0085 - Supply Freight Fee')
            },
            'Miscellaneous_Invoice_Item__c' => new Map<String, TCRE__Rule_Condition__c>{
                'GL_Code__c=0001 - Interim Rent' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0001 - Interim Rent'),
                'GL_Code__c=0081 - Interim Rent Dealer' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0081 - Interim Rent Dealer'),
                'GL_Code__c=0115 - Interim Maintenance' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0115 - Interim Maintenance'),
                'GL_Code__c=0003 - OneTime Documentation Fee' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0003 - OneTime Documentation Fee'),
                'GL_Code__c=0083 - Shared Doc Fee Dealer' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0083 - Shared Doc Fee Dealer'),
                'GL_Code__c=0040 - Progress Payment Fees' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0040 - Progress Payment Fees'),
                'GL_Code__c=0042 - UPS SHIPPING FEE' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0042 - UPS SHIPPING FEE'),
                'GL_Code__c=0090 - Convenience Fee' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0090 - Convenience Fee'),
                'GL_Code__c=0018 - Property Tax' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0018 - Property Tax'),
                'GL_Code__c=0019 - Fla Doc Stamp Tax' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0019 - Fla Doc Stamp Tax'),
                'GL_Code__c=0017 - Service Contract' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0017 - Service Contract'),
                'GL_Code__c=0085 - Supply Freight Fee' => new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'GL_Code__c', TCRE__Operator__c = '=', TCRE__Value__c = '0085 - Supply Freight Fee')
            }
        };
        Map<String, TCRE__Rule_Config__c> ruleConfigsToInsert = new Map<String, TCRE__Rule_Config__c>();
        Map<String, List<TCRE__Rule_Condition__c>> conditionsToInsert = new Map<String, List<TCRE__Rule_Condition__c>>();
        Map<String, Tax_Rule__c> taxRulesToInsert = new Map<String, Tax_Rule__c>();

        for(String csvRow : csvData.trim().split('\r\n')){
            if(csvRow.containsIgnoreCase('State,State,Infolease  Tax Codes,Rapport Tax Codes,late charges,IR,INS,DOC,"UPS, WIRE  ,  PROG PYMNT PENALTY FEE,   DELV GUAR FEE",CONV FEE,PPTX,FLA DOC STAMP TAX,Maintenance Billed As Misc Billable or Invoiced,Soft Cost          See Note ')){
                continue;// not doing anything with header, but make sure the header is exactly like this, any change could stop the script from working
            }else{
                List<String> csvConvertedCells = new List<String>();
                String[] csvRawCells = csvRow.trim().split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');
                for(String cell:csvRawCells){
                    csvConvertedCells.add(cell.unescapeCsv().removeStart('"').removeEnd('"').trim());
                }
                String stateLabel = stateLabelsByCode.get(csvConvertedCells[0]);
                if(rulesByState.containsKey(stateLabel)){
                    rulesByState.get(stateLabel).add(csvConvertedCells);
                }
            }
        }
        System.debug('rulesByState: ' + rulesByState);
        Map<Id, TCRE__Rule_Config__c> allRuleConfigs = new Map<Id, TCRE__Rule_Config__c>([SELECT Id, TCRE__Rule_Name__c, TCRE__SObject_Name__c, TCRE__Evaluation_Logic_Picklist__c, TCRE__Custom_Rule_Evaluation_Logic__c 
            FROM TCRE__Rule_Config__c
            WHERE TCRE__SObject_Name__c IN ('Miscellaneous_Billable_Item__c', 'Miscellaneous_Invoice_Item__c') ]);
        Map<Id, TCRE__Rule_Condition__c> allRuleConditions = new Map<Id, TCRE__Rule_Condition__c>([SELECT Id, TCRE__Rule_Config__c, TCRE__Field_Name__c, TCRE__Operator__c, TCRE__Value__c
            FROM TCRE__Rule_Condition__c
            WHERE TCRE__Rule_Config__r.TCRE__SObject_Name__c IN ('Miscellaneous_Billable_Item__c', 'Miscellaneous_Invoice_Item__c') ]);
        Map<String, List<TCRE__Rule_Condition__c>> conditionsByKey = new Map<String, List<TCRE__Rule_Condition__c>>();
        for(TCRE__Rule_Condition__c theRuleCond:allRuleConditions.values()){
            String conditionKey = theRuleCond.TCRE__Rule_Config__c+(theRuleCond.TCRE__Field_Name__c+theRuleCond.TCRE__Operator__c+theRuleCond.TCRE__Value__c).toUpperCase();
            List<TCRE__Rule_Condition__c> existingRuleCond = conditionsByKey.get(conditionKey);
            if(existingRuleCond == null){
                existingRuleCond = new List<TCRE__Rule_Condition__c>();
            }
            existingRuleCond.add(theRuleCond);
            conditionsByKey.put(conditionKey, existingRuleCond);
        }
        Map<Id, Tax_Rule__c> allTaxRules = new Map<Id, Tax_Rule__c>([SELECT Id, Rule_Config__c, Tax_Type__c, Tax_Basis_Field__c, Tax_Basis_Object__c, State__c, Rate_Code_to_Use__c, Description__c
            FROM Tax_Rule__c
            WHERE Rule_Config__r.TCRE__SObject_Name__c IN ('Miscellaneous_Billable_Item__c', 'Miscellaneous_Invoice_Item__c') ]);
        Map<String, List<Tax_Rule__c>> taxRulesByStateNCode = new Map<String, List<Tax_Rule__c>>();
        for(Tax_Rule__c theRule:allTaxRules.values()){
            String stateNTax = (theRule.State__c + theRule.Rate_Code_to_Use__c).toUpperCase();
            List<Tax_Rule__c> existingRules = taxRulesByStateNCode.get(stateNTax);
            if(existingRules == null){
                existingRules = new List<Tax_Rule__c>();
            }
            existingRules.add(theRule);
            taxRulesByStateNCode.put(stateNTax, existingRules);
        }
        for(String stateLabel :rulesByState.keySet()){
            for(List<String> csvCells :rulesByState.get(stateLabel)){
                String taxCode= csvCells[2];
                String oppConditions = csvCells[1];
                List<String> conditionsToFind = new List<String>();
                Integer mutuallyExclusive = 0;
                List<TCRE__Rule_Condition__c> baseConditions = new List<TCRE__Rule_Condition__c>();
                baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Amount__c', TCRE__Operator__c = '>', TCRE__Value__c = '0'));
                baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity__r.Tax_State__c', TCRE__Operator__c = '=', TCRE__Value__c = stateLabel));
                if(oppConditions.contains('TL') || oppConditions.contains('OL') || oppConditions.contains('CS')){
                    baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity__r.Purchase_Options__c', TCRE__Operator__c = '!=', TCRE__Value__c = 'Customer Owned'));
                }
                if(oppConditions.contains('TL') || oppConditions.contains('OL')){
                    conditionsToFind.add('Opportunity__r.Is_TL_RL_or_OL__c=TRUE'.toUpperCase());
                    baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity__r.Is_TL_RL_or_OL__c', TCRE__Operator__c = '=', TCRE__Value__c = 'TRUE'));
                    mutuallyExclusive++;// depends on Contract_Type__c, so not mutually exclusive but still optional
                }
                if(oppConditions.contains('CS')){
                    conditionsToFind.add('Opportunity__r.Contract_Type__c=CS'.toUpperCase());
                    baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity__r.Contract_Type__c', TCRE__Operator__c = '=', TCRE__Value__c = 'CS'));
                    mutuallyExclusive++;// depends on Contract_Type__c, so not mutually exclusive but still optional
                }
                if(oppConditions.containsIgnoreCase('Assign Resid')){
                    conditionsToFind.add('Opportunity__r.Purchase_Options__c=Assigned Residual'.toUpperCase());
                    baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity__r.Purchase_Options__c', TCRE__Operator__c = '=', TCRE__Value__c = 'Assigned Residual'));
                    mutuallyExclusive++;
                }
                if(oppConditions.containsIgnoreCase('$101')){
                    conditionsToFind.add('Opportunity__r.Purchase_Options__c=$101 Purchase Option'.toUpperCase());
                    baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity__r.Purchase_Options__c', TCRE__Operator__c = '=', TCRE__Value__c = '$101 Purchase Option'));
                    mutuallyExclusive++;
                }
                if(oppConditions.containsIgnoreCase('$1.00')){
                    conditionsToFind.add('Opportunity__r.Purchase_Options__c=1.00 Out'.toUpperCase());
                    baseConditions.add(new TCRE__Rule_Condition__c(TCRE__Field_Name__c = 'Opportunity__r.Purchase_Options__c', TCRE__Operator__c = '=', TCRE__Value__c = '1.00 Out'));
                    mutuallyExclusive++;
                }
                System.debug('conditionsToFind: ' + conditionsToFind);
                List<Boolean> taxableGlCodes = new List<Boolean>();
                for(Integer i = 4; i < 13; i++){
                    taxableGlCodes.add(csvCells[i].trim() == 'Y');
                }
                List<Tax_Rule__c> existingRulesGLCodes = new List<Tax_Rule__c>();// still not sure to use this
                Boolean isNewTaxRule = false;
                Set<String> missingConditionKeys = new set<String>();
                List<Tax_Rule__c> foundRules = taxRulesByStateNCode.get(stateLabel+taxCode);
                if(foundRules != null && foundRules.size()>0){
                    Boolean oneRuleExists = false;
                    for(Tax_Rule__c foundRule :foundRules){
                        if(conditionsToFind.size() > 0){
                            Map<String, Integer> conditionsFoundByConfigId = new Map<String, Integer>();
                            for(String conditionKey :conditionsToFind){
                                List<TCRE__Rule_Condition__c> foundConditions = conditionsByKey.get(foundRule.Rule_Config__c+conditionKey);
                                if(foundConditions != null && foundConditions.size() > 0){
                                    Integer foundConds = conditionsFoundByConfigId.get(foundRule.Rule_Config__c) ?? 0;
                                    conditionsFoundByConfigId.put(foundRule.Rule_Config__c, foundconds);
                                }
                            }
                            if((conditionsFoundByConfigId.get(foundRule.Rule_Config__c) ?? 0) == conditionsToFind.size()){
                                System.debug('Rule found by conditions for State: ' + stateLabel + ' Tax Rate code to use: ' + taxCode + '\r\n' + foundRule);
                            }else{
                                isNewTaxRule = true;// need to create new rule with all of the conditions
                            }
                        }else{
                            System.debug('Rule found only by State: ' + stateLabel + ' Tax Rate code to use: ' + taxCode + '\r\n' + foundRule);
                        }
                        Integer taxableCategories = 0;
                        Integer taxableCategoriesMet = 0;
                        for(Integer i = 0; i < 9; i++){
                            Boolean isTaxable = taxableGlCodes[i];
                            if(isTaxable){
                                taxableCategories++;
                                Boolean hasAtLeastOneCode = false;
                                List<String> codesToFind = glCodesBillInvoice.get(csvTaxKeys[i]);
                                if(codesToFind != null && codesToFind.size() > 0){
                                    for(String codeToFind :codesToFind){
                                        String conditionKey = codeToFind.toUpperCase();
                                        List<TCRE__Rule_Condition__c> foundConditions = conditionsByKey.get(foundRule.Rule_Config__c+conditionKey);
                                        if(foundConditions != null && foundConditions.size() > 0){
                                            hasAtLeastOneCode = true;
                                        }else{
                                            missingConditionKeys.add(codeToFind);// not upperCase
                                        }
                                    }
                                }
                                if(hasAtLeastOneCode){
                                    taxableCategoriesMet++;
                                }
                            }
                        }
                        System.debug('taxableCategories: ' + taxableCategories);
                        System.debug('taxableCategoriesMet: ' + taxableCategoriesMet);
                        isNewTaxRule = isNewTaxRule || taxableCategories > taxableCategoriesMet;
                        if(taxableCategories == taxableCategoriesMet){
                            oneRuleExists = true;
                        }
                    }
                    isNewTaxRule = isNewTaxRule && !oneRuleExists;
                }else{
                    System.debug('No Rule exists yet For State: ' + stateLabel + ' Tax Rate code to use: ' + taxCode );
                    isNewTaxRule = true;
                }
                System.debug('isNewTaxRule: ' + isNewTaxRule);
                /// now for creating the tax rules rule configs and rule conditions
                if(isNewTaxRule){
                    //List<String> objApi = ;
                    for(String objName :new List<String>{'Miscellaneous_Billable_Item__c', 'Miscellaneous_Invoice_Item__c'}){
                        List<TCRE__Rule_Condition__c> glCodeConditions = new List<TCRE__Rule_Condition__c>();
                        List<TCRE__Rule_Condition__c> unifiedConds = new List<TCRE__Rule_Condition__c>();
                        for(TCRE__Rule_Condition__c baseCond :baseConditions){
                            unifiedConds.add(baseCond.clone(false,false,false));
                        }
                        Map<String, TCRE__Rule_Condition__c> condByMissingKey = conditionTemplates.get(objName);
                        for(String missingCond :missingConditionKeys){
                            TCRE__Rule_Condition__c templateCond = condByMissingKey.get(missingCond);
                            if(templateCond != null){
                                TCRE__Rule_Condition__c toAdd = templateCond.clone(false,false,false);
                                glCodeConditions.add(toAdd);
                            }
                        }
                        unifiedConds.addAll(glCodeConditions);
                        String evaLogic = '';
                        for(Integer i = 1; i <= baseConditions.size() - mutuallyExclusive; i++){
                            evaLogic += i.toString() + ' AND ';
                        }
                        evaLogic = evaLogic.removeEnd(' AND ');
                        if(String.isNotBlank(evaLogic) && mutuallyExclusive > 0){
                            evaLogic += ' AND (';
                        }
                        for(Integer i = baseConditions.size() - mutuallyExclusive + 1; i <= baseConditions.size(); i++){
                            evaLogic += i.toString() + ' OR ';
                        }
                        evaLogic = evaLogic.removeEnd(' OR ');
                        if(mutuallyExclusive > 0){
                            evaLogic += ')';
                        }
                        if(String.isNotBlank(evaLogic) && glCodeConditions.size() > 0){
                            evaLogic += ' AND (';
                        }
                        for(Integer i = baseConditions.size() + 1; i <= baseConditions.size() + glCodeConditions.size(); i++){
                            evaLogic += i.toString() + ' OR ';
                        }
                        evaLogic = evaLogic.removeEnd(' OR ');
                        if(glCodeConditions.size() > 0){
                            evaLogic += ')';
                        }
                        String configKey = stateLabel + taxCode + objName;
                        String description = stateLabel+ ' ' + taxCode + ' Taxable Fees';
                        ruleConfigsToInsert.put(configKey, new TCRE__Rule_Config__c(TCRE__Rule_Name__c = description,
                            TCRE__SObject_Name__c = objName, TCRE__Evaluation_Logic_Picklist__c = 'Custom', TCRE__Custom_Rule_Evaluation_Logic__c = evaLogic
                            ));
                        conditionsToInsert.put(configKey, unifiedConds);
                        taxRulesToInsert.put(configKey, new Tax_Rule__c(Tax_Type__c = 'Regular', Tax_Basis_Field__c = 'Amount__c', State__c = stateLabel,
                             Rate_Code_to_Use__c = taxCode, Description__c = description
                            ));
                    }

                }else{
                    System.debug('Rule already exists for State: ' + stateLabel + ' Tax Rate code to use: ' + taxCode);
                }
            }
        }
        // System.debug('Rules to be created: ' + ruleConfigsToInsert);
        System.debug('Rules to be created: ' + ruleConfigsToInsert.values().size());
        // now for the real DML
        if(!justCheck && ruleConfigsToInsert.values().size() > 0){
            insert ruleConfigsToInsert.values();
            List<TCRE__Rule_Condition__c> finalToInsert = new List<TCRE__Rule_Condition__c>();
            for(String configKey :ruleConfigsToInsert.keySet()){
                Id configId = ruleConfigsToInsert.get(configKey).Id;
                for(TCRE__Rule_Condition__c oneCondition :conditionsToInsert.get(configKey)){
                    oneCondition.TCRE__Rule_Config__c = configId;
                    finalToInsert.add(oneCondition);
                }
                taxRulesToInsert.get(configKey).Rule_Config__c = configId;
            }
            if(finalToInsert.size() > 0){
                insert finalToInsert;
            }
            if(taxRulesToInsert.values().size() > 0){
                insert taxRulesToInsert.values();
            }
            System.debug('created Rules: ' + ruleConfigsToInsert);
        }
    }
}