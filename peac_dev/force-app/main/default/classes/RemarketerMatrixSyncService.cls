@RestResource(urlMapping='/RemarketerMatrixSync')
global with sharing class RemarketerMatrixSyncService {

    @HttpPost
    global static String upsertRemarketers() {
        String requestBody = RestContext.request.requestBody.toString();
        System.debug('requestBody  ' + requestBody);

        List<RemarketerMatrixWrapper> remarketers = (List<RemarketerMatrixWrapper>) JSON.deserializeStrict(requestBody, List<RemarketerMatrixWrapper>.class);
        System.debug('upsertRemarketers ' + remarketers);
        List<Remarketer_Matrix_Obj__c> toUpsert = new List<Remarketer_Matrix_Obj__c>();

        for (RemarketerMatrixSyncService.RemarketerMatrixWrapper wrapper : remarketers) {
            toUpsert.add(new Remarketer_Matrix_Obj__c(
                Equipment_Type__c = wrapper.EquipmentType,
                Equipment_Subtype__c = wrapper.EquipmentSubType,
                Return_Warehouse_Code__c = wrapper.WarehouseCode,
                State__c = wrapper.State
            ));
        }

        upsert toUpsert;
        return 'Success: ' + toUpsert.size() + ' records upserted';
    }

    global class RemarketerMatrixWrapper {
        public String EquipmentType;
        public String EquipmentSubType;
        public String State;
        public String WarehouseCode;
    }
}