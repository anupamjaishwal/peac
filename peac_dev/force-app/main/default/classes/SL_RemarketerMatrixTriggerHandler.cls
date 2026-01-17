public with sharing class SL_RemarketerMatrixTriggerHandler extends SL_Trigger.baseHandler {


    public override void beforeInsert(List<SObject> newList){
        List<Remarketer_Matrix_Obj__c> remarketerMatrixList = new List<Remarketer_Matrix_Obj__c>();
        for(SObject theObject :newList){
            remarketerMatrixList.add((Remarketer_Matrix_Obj__c)theObject);
        }
        setLocation(remarketerMatrixList);
    }


    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<Remarketer_Matrix_Obj__c> remarketerMatrixList = new List<Remarketer_Matrix_Obj__c>();
        for (Id id :newMap.keySet()){
            remarketerMatrixList.add((Remarketer_Matrix_Obj__c)newMap.get(id));
        }
        setLocation(remarketerMatrixList);
    }


    public void setLocation (List<Remarketer_Matrix_Obj__c> remarketerMatrixList){
        Set<String> locations = new Set<String>();
        for (Remarketer_Matrix_Obj__c rm : remarketerMatrixList){
            if (rm.Return_Warehouse_Code__c != null){
                locations.add(rm.Return_Warehouse_Code__c);
            }
        }

        if(locations.size() > 0){
            List<Schema.Location> locationsMap = [SELECT Id, Name, Service_Provider__c FROM Location WHERE Name IN :locations];
            Map<String, Schema.Location> locationByNameMap = new Map<String, Schema.Location>();
            for (Schema.Location l : locationsMap){
                locationByNameMap.put(l.Name.toUpperCase(), l);
            }

            if(!locationByNameMap.isEmpty()){
                for (Remarketer_Matrix_Obj__c rm : remarketerMatrixList){
                    String returnWarehouseCode = rm.Return_Warehouse_Code__c.toUpperCase();
                    rm.Service_Provider__c = locationByNameMap.get(returnWarehouseCode)?.Service_Provider__c == null ? null : locationByNameMap.get(returnWarehouseCode).Service_Provider__c;
                    rm.Location__c = locationByNameMap.get(returnWarehouseCode)?.Id == null ? null : locationByNameMap.get(returnWarehouseCode).Id ;
                }
            }

        }  
    }

}