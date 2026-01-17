public class TC_BridgewareSelectZipGeoCodeCtrl {
    @AuraEnabled
    public static TC_BridgewareTaxJurisdiction getCurrentValues(String recordId) {
        try {
            String objectType = String.valueOf(((Id) recordId).getSobjectType());
            Tax_Jurisdiction_Mapping__mdt mapping = TC_BridgewareUtility.getTaxJurisdictionMapping(objectType);
            
            Set<String> recordQueryFields = new Set<String>();
            recordQueryFields.add(mapping.City_Field__r.QualifiedApiName);
            recordQueryFields.add(mapping.County_Field__r.QualifiedApiName);
            recordQueryFields.add(mapping.State_Field__r.QualifiedApiName);
            recordQueryFields.add(mapping.Zip_Field__r.QualifiedApiName);
            recordQueryFields.add(mapping.Zip_Updated_Field__r.QualifiedApiName);
            
            String recordQuery = TC_BridgewareUtility.createQueryString(recordQueryFields, objectType, 'Id', recordId);
            System.debug('recordQuery ' + recordQuery);
            SObject record = Database.query(recordQuery);
            
            TC_BridgewareTaxJurisdiction taxJurisdiction = new TC_BridgewareTaxJurisdiction();
            taxJurisdiction.city = (String) record.get(mapping.City_Field__r.QualifiedApiName);
            taxJurisdiction.county = (String) record.get(mapping.County_Field__r.QualifiedApiName);
            taxJurisdiction.state = (String) record.get(mapping.State_Field__r.QualifiedApiName);
            taxJurisdiction.zip = (String) record.get(mapping.Zip_Field__r.QualifiedApiName);
            taxJurisdiction.zipUpdated = (Boolean) record.get(mapping.Zip_Updated_Field__r.QualifiedApiName);
            System.debug('taxJurisdiction ' + taxJurisdiction);
            
            return taxJurisdiction;
        } catch(Exception ex) {  handleException(ex); return null;
        }
    }
    
    @AuraEnabled
    public static Decimal getOpportunityProbability(String recordId) {
        try {
            Decimal opportunityProbability = 0;
            String objectType = String.valueOf(((Id) recordId).getSobjectType());
            
            if (objectType == 'Asset__c') {
                Set<String> recordQueryFields = new Set<String>();
                recordQueryFields.add('Opportunity__r.Probability');
                
                String recordQuery = TC_BridgewareUtility.createQueryString(recordQueryFields, objectType, 'Id', recordId);
                System.debug('recordQuery ' + recordQuery);
                SObject record = Database.query(recordQuery);
                opportunityProbability = ((Asset__c) record).Opportunity__r.Probability;
            }
            
            return opportunityProbability;
        } catch(Exception ex) {handleException(ex);return null;
        }
    }
    
    @AuraEnabled
    public static List<TC_BridgewareTaxJurisdiction> search(String recordId, String zip) {
        List<TC_BridgewareTaxJurisdiction> taxJurisdictions = null;
        if(recordId != null){
            try {
            TC_BridgewareSelectZipGeoCodeRespBean resp = TC_BridgewareUtility.selectZipGeoCode(zip, '', '');
            taxJurisdictions = TC_BridgewareUtility.getTaxJurisdictions(resp);
            String taxJurisdictionString;
            
            if (taxJurisdictions.size() == 1) save(recordId, JSON.serialize(taxJurisdictions[0]));
                
            } catch(Exception ex) {handleException(ex);return null;}
        }
        return taxJurisdictions;
    }
    
    @AuraEnabled
    public static void save(String recordId, String taxJurisdictionString) {
        try {
            String objectType = String.valueOf(((Id) recordId).getSobjectType());
            SObject record = Schema.getGlobalDescribe().get(objectType).newSObject();
            record.Id = recordId;
            
            Tax_Jurisdiction_Mapping__mdt mapping = TC_BridgewareUtility.getTaxJurisdictionMapping(objectType);
            TC_BridgewareTaxJurisdiction taxJurisdiction = (TC_BridgewareTaxJurisdiction) JSON.deserialize(taxJurisdictionString, TC_BridgewareTaxJurisdiction.class);
            
            if (String.isNotEmpty(mapping.City_Field__c))
                record.put(mapping.City_Field__r.QualifiedApiName, taxJurisdiction.city);
            
            if (String.isNotEmpty(mapping.City_Code_Field__c))
                record.put(mapping.City_Code_Field__r.QualifiedApiName, taxJurisdiction.cityCode);
            
            if (String.isNotEmpty(mapping.County_Field__c))
                record.put(mapping.County_Field__r.QualifiedApiName, taxJurisdiction.county);
            
            if (String.isNotEmpty(mapping.County_Code_Field__c))
                record.put(mapping.County_Code_Field__r.QualifiedApiName, taxJurisdiction.countyCode);
            
            if (String.isNotEmpty(mapping.State_Field__c))
                record.put(mapping.State_Field__r.QualifiedApiName, taxJurisdiction.state);
            
            if (String.isNotEmpty(mapping.State_Code_Field__c))
                record.put(mapping.State_Code_Field__r.QualifiedApiName, taxJurisdiction.stateCode);
            
            if (String.isNotEmpty(mapping.Zip_Updated_Field__c))
                record.put(mapping.Zip_Updated_Field__r.QualifiedApiName, false);
            
            update record;
        } catch(Exception ex) { handleException(ex);
        }
    }
    
    public class TC_BridgewareSelectZipGeoCodeCtrlException extends Exception {}

    public static void handleException(Exception ex) {
            if(System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled() || Trigger.isExecuting){
                throw ex;
            }else{
                throw new AuraHandledException(ex.getMessage());
            }
        }
    }