public with sharing class SL_ManageRMCounties {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'getWarehouseCodes'{
                    result = getWarehouseCodes();
                }
                when 'getCounties'{
                    result = getCounties(parameters[0], parameters[1], parameters[2], parameters[3]);
                }
                when 'saveRMatrixes'{
                    result = saveRMatrixes(parameters[0], parameters[1], parameters[2], parameters[3], parameters[4]);
                }
            }
        } catch (Exception e) {
            system.debug('e: ' + e);
            system.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    public static String getWarehouseCodes(){
        String result = '';
        List<Schema.Location> existingLocations = [SELECT Id, Name FROM Location];
        return JSON.serialize(existingLocations);
    }

    public static String getCounties(String type, String subType, String state, String wareHouse){
        String result = '';
        String query = buildQuery('existingCounties', type, subType, state, wareHouse);
        List<County__c> existingCounties = new List<County__c>();
        for(AggregateResult ar : Database.query(query)){
            String countyId = String.valueOf(ar.get('countyId'));
            if(countyId != null){
                County__c uniqueCounty = new County__c(Id = countyId, Name = (String)ar.get('countyName'),
                    State__c = (String)ar.get('state'));
                existingCounties.add(uniqueCounty);
            }
        }
        List<County__c> stateCounties = new List<County__c>();
        if(String.isNotBlank(state)){
            
            for(County__c county : [SELECT Id, Name, State__c FROM County__c WHERE State__c = :state]){
                stateCounties.add(county);
            }
        }
        result = '{"existingCounties": ' + JSON.serialize(existingCounties)
            + ', "stateCounties": ' + JSON.serialize(stateCounties) + '}';
        return result;
    }

    public static String saveRMatrixes(String type, String subType, String state, String wareHouse, String counties){
        String result = 'success';
        List<CountyWrapper> selectedCounties = (List<CountyWrapper>)JSON.deserialize(counties, List<CountyWrapper>.class);
        String query = buildQuery('rMatrixes', type, subType, state, wareHouse);
        List<Remarketer_Matrix_Obj__c> rMatrixes = Database.query(query);
        Map<Id, List<Remarketer_Matrix_Obj__c>> rMatrixesByCountyId = new Map<Id, List<Remarketer_Matrix_Obj__c>>();
        List<Remarketer_Matrix_Obj__c> rMatrixesNoCounty = new List<Remarketer_Matrix_Obj__c>();
        for(Remarketer_Matrix_Obj__c anRMatrix :rMatrixes){
            if(anRMatrix.County__c != null){
                if(rMatrixesByCountyId.get(anRMatrix.County__c) == null){
                    rMatrixesByCountyId.put(anRMatrix.County__c, new List<Remarketer_Matrix_Obj__c>());
                }
                rMatrixesByCountyId.get(anRMatrix.County__c).add(anRMatrix);
            }else{
                rMatrixesNoCounty.add(anRMatrix);
            }
        }
        Map<Id, Remarketer_Matrix_Obj__c> rMatrixesToUpdate = new Map<Id, Remarketer_Matrix_Obj__c>();
        List<Remarketer_Matrix_Obj__c> rMatrixesToInsert = new List<Remarketer_Matrix_Obj__c>();
        Set<Id> selectedCountyIds = new Set<Id>();
        for(CountyWrapper selectedCounty :selectedCounties){
            Id countyId = (Id)selectedCounty.name;
            Boolean foundRMatrixToUpdate = false;
            selectedCountyIds.add(countyId);
            if(rMatrixesByCountyId.get(countyId) == null){
                for(Remarketer_Matrix_Obj__c emptyCounty :rMatrixesNoCounty){
                    if(rMatrixesToUpdate.get(emptyCounty.Id) == null){
                        emptyCounty.County__c = countyId;
                        rMatrixesToUpdate.put(emptyCounty.Id, emptyCounty);
                        foundRMatrixToUpdate = true;
                        break;
                    }
                }
                if(!foundRMatrixToUpdate){
                    Remarketer_Matrix_Obj__c newRMatrix = new Remarketer_Matrix_Obj__c(
                        Equipment_Type__c = type, Equipment_Subtype__c = subType, State__c = state, 
                        Return_Warehouse_Code__c = wareHouse, County__c = countyId
                    );
                    rMatrixesToInsert.add(newRMatrix);
                }
            }
        }
        List<Remarketer_Matrix_Obj__c> rMatrixesToDelete = new List<Remarketer_Matrix_Obj__c>();
        for(Id existingCountyId :rMatrixesByCountyId.keySet()){
            if(!selectedCountyIds.contains(existingCountyId)){
                rMatrixesToDelete.addAll(rMatrixesByCountyId.get(existingCountyId));
            }
        }
        if(rMatrixesToUpdate.values().size() > 0){
            update rMatrixesToUpdate.values();
        }
        if(rMatrixesToInsert.size() > 0){
            insert rMatrixesToInsert;
        }
        if(rMatrixesToDelete.size() > 0){
            delete rMatrixesToDelete;
        }
        return result;
    }

    static String buildQuery(String resultType, String type, String subType, String state, String wareHouse){
        String theQuery = '';
        switch on resultType {
            when 'existingCounties' {
                theQuery = 'SELECT County__r.State__c state, County__c countyId, County__r.Name countyName '
                    + ' FROM Remarketer_Matrix_Obj__c ';
            }
            when 'rMatrixes' {
                theQuery = 'SELECT Id, Equipment_Type__c, Equipment_Subtype__c, State__c, Return_Warehouse_Code__c, County__c '
                    + ' FROM Remarketer_Matrix_Obj__c ';
            }
        }
        Map<String, String> variableByFieldName = new Map<String, String>{'Equipment_Type__c' => 'type',
            'Equipment_Subtype__c' => 'subType', 'State__c' => 'state', 'Return_Warehouse_Code__c' => 'wareHouse'};
        List<String> allCriteria = new List<String>();
        String criteria = criteriaForQuery(type, 'Equipment_Subtype__c', variableByFieldName);
        if(String.isNotBlank(criteria)){
            allCriteria.add(criteria);
        }
        criteria = criteriaForQuery(subType, 'Equipment_Subtype__c', variableByFieldName);
        if(String.isNotBlank(criteria)){
            allCriteria.add(criteria);
        }
        criteria = criteriaForQuery(state, 'State__c', variableByFieldName);
        if(String.isNotBlank(criteria)){
            allCriteria.add(criteria);
        }
        criteria = criteriaForQuery(wareHouse, 'Return_Warehouse_Code__c', variableByFieldName);
        if(String.isNotBlank(criteria)){
            allCriteria.add(criteria);
        }
        if(allCriteria.size() > 0){
            theQuery += ' WHERE ' + String.join(allCriteria, ' AND ');
        }
        if(resultType == 'existingCounties'){
            theQuery += ' GROUP BY County__r.State__c, County__c, County__r.Name';
        }
        return theQuery;
    }

    public static String criteriaForQuery(String value, String fieldName, Map<String, String> variableByFieldName){
        String result = '';
        if(String.isNotBlank(value)){
            result = fieldName + ' = :' + variableByFieldName.get(fieldName);
        }
        return result;
    }

    public class CountyWrapper{
        public String name;
        public String label;
    }
}