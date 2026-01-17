public class PortalSignerStatusController {
    
  
    @AuraEnabled
    public static List<Signer_Portal_Status__c> getSignerStatusInfo(String parentRecordId){
        List<Signer_Portal_Status__c> signerRecs = new List<Signer_Portal_Status__c>();
            signerRecs = [select Id,Name,SignerNumber__c,Opportunity__c,contact__r.Name, Account_Setup_Complete__c,Account_Setup_Complete_Date__c, ID_Ver_Status__c, ID_Ver_Start__c, 
                            ID_Ver_Complete__c, Accept_Terms_Status__c, Accept_Terms_Start__c, Accept_Terms_Complete__c, 
                            Sign_Status__c, Sign_Start__c, Sign_Complete__c, Upload_Status__c, Upload_Start__c, Upload_Complete__c,
                             Bank_Details_Status__c, Bank_Details_Start__c, Bank_Details_Complete__c, Accept_Terms_Bus_Equip_Status__c, 
                             Accept_Terms_Bus_Equip_Start__c, Accept_Terms_Bus_Equip_Complete__c, Accept_Terms_Terms_Status__c, 
                             Accept_Terms_Terms_Status_Start__c, Accept_Terms_Terms_Status_Complete__c, Accept_Terms_Other_Terms_Status__c, 
                             Accept_Terms_Other_Terms_Start__c, Accept_Terms_Other_Terms_Complete__c from Signer_Portal_Status__c where Opportunity__c = :parentRecordId Order by SignerNumber__c ];
        system.debug('signer protal records===>'+signerRecs);
        return signerRecs;
    }
    @AuraEnabled
    public static List<SignerPortalStatusLabels__mdt> getSignerLabelsInfo(){
        List<SignerPortalStatusLabels__mdt> SignerLabels = [SELECT Id,MasterLabel,DeveloperName,FieldsLabel__c from SignerPortalStatusLabels__mdt order by MasterLabel];
        return SignerLabels;
    }
    @AuraEnabled
    public static String getFieldSet(String sObjectName, String fieldSetName) {
        String result = '';
        try{
            SObjectType objToken = Schema.getGlobalDescribe().get(sObjectName);
            Schema.DescribeSObjectResult d = objToken.getDescribe();
            Map<String, Schema.FieldSet> FsMap = d.fieldSets.getMap();
            system.debug('>>>>>>> FsMap >>> ' + FsMap);
            if(FsMap.containsKey(fieldSetName))
                for(Schema.FieldSetMember f : FsMap.get(fieldSetName).getFields()) {
                    if(result != ''){
                        result += ',';
                    }
                    String jsonPart = '{';
                    jsonPart += '"label":"' + f.getLabel() + '",';
                    jsonPart += '"required":"' + (f.getDBRequired() || f.getRequired()) + '",';
                    jsonPart += '"type":"' + (f.getType()) + '",';
                    jsonPart += '"name":"' + f.getFieldPath() + '"';
                    jsonPart += '}';
                    result += jsonPart;
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return '['+result+']';
    }
     @AuraEnabled
    public static String getRecords(String sObjectName, String recordIdName, String recordId, String fieldNameJson){

        List<sObject> lstResult = new List<sObject>();
        String result = '[]';
        try{
            List<String> fieldNames = (List<String>) JSON.deserialize(fieldNameJson, List<String>.class);
            fieldNames.sort();
            system.debug('fieldNames===>'+fieldNames);
            Set<String> setFieldNames = new Set<String>();
            String query = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + sObjectName ;
            if(recordIdName != NULL && recordIdName != '' && recordId != NULL){
                query += ' WHERE ' + recordIdName + '= \'' +  recordId + '\'';
            }
            for(sObject s : Database.query(query)){
                lstResult.add(s);
            }
            if(lstResult.size() > 0) {
                result = JSON.serialize(lstResult);
            }
        }
        catch(Exception e){
            result += e.getLineNumber() + ' : ' + e.getMessage();
        }
        return result;
    }
    
}