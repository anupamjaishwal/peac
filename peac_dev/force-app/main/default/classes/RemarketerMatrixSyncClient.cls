public with sharing class RemarketerMatrixSyncClient {
    public static void syncRemarketersToSandbox() {
          // Obtener registros modificados recientemente
          List<Remarketer_Matrix_Obj__c> recent = [
              SELECT Equipment_Type__c, Equipment_Subtype__c, State__c, Return_Warehouse_Code__c 
              FROM Remarketer_Matrix_Obj__c 
              WHERE Synced__c = false
          ];
  
          // Mapear a formato JSON
          List<RemarketerMatrixSyncService.RemarketerMatrixWrapper> payload = new List<RemarketerMatrixSyncService.RemarketerMatrixWrapper>();
          for (Remarketer_Matrix_Obj__c r : recent) {
              RemarketerMatrixSyncService.RemarketerMatrixWrapper record = new RemarketerMatrixSyncService.RemarketerMatrixWrapper();
              record.EquipmentType = r.Equipment_Type__c ;
              record.EquipmentSubType = r.Equipment_Subtype__c ;
              record.State = r.State__c ;
              record.WarehouseCode = r.Return_Warehouse_Code__c;
              r.Synced__c=true;
              payload.add(record);
          }
  
          // Enviar callout
          HttpRequest req = new HttpRequest();
          req.setEndpoint('callout:Lower_Sandbox/services/apexrest/RemarketerMatrixSync');
          req.setMethod('POST');
          req.setHeader('Content-Type', 'application/json');
          req.setBody(JSON.serialize(payload));
  
          Http http = new Http();
          try {
              HttpResponse res = http.send(req);
              System.debug('Req: ' + req.getBody());
              if(res.getBody().contains('Success')){
                  update recent;
              }
              System.debug('Respuesta: ' + res.getBody());
          } catch (Exception ex) {
              System.debug('Error en callout REST: ' + ex.getMessage());
          }
      }
  }