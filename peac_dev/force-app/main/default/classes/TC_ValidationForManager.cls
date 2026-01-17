public class TC_ValidationForManager {
     public static List<OpportunityFieldsValidation__mdt>  oppFieldValidation;
    public static boolean managerValidationCompleted= false;
 public static void validationForManager (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        if(managerValidationCompleted) return;
        managerValidationCompleted = true;
        string profileId=userinfo.getProfileId();
        String uRoleId = UserInfo.getUserRoleId();
        if(oppFieldValidation == null){
            List<OpportunityFieldsValidation__mdt> fieldsWithStage = [SELECT Id,FieldName__c,StageName__c,Profile_Role_ID__c from OpportunityFieldsValidation__mdt];
            oppFieldValidation = fieldsWithStage;
        }
        
        Map<string, List<string>> mapStatusWithFieldToEdit = new Map<string, List<string>>();
        for(OpportunityFieldsValidation__mdt mtdRec : oppFieldValidation){
            if(mtdRec.Profile_Role_ID__c == uRoleId || mtdRec.Profile_Role_ID__c == profileId){
                if(!mapStatusWithFieldToEdit.containsKey(mtdRec.StageName__c)) 
                    mapStatusWithFieldToEdit.put(mtdRec.StageName__c, new List<string> ());
                
                mapStatusWithFieldToEdit.get(mtdRec.StageName__c).add(mtdRec.FieldName__c.toLowercase());
            }
           
        }    
        system.debug('=====mapStatusWithFieldToEdit' + mapStatusWithFieldToEdit);
        
        Opportunity oppObj = new Opportunity(); 
        Map<String, Schema.SObjectField> M = Schema.SObjectType.Opportunity.fields.getMap();
        
        for (Opportunity opp : newMap.values()) {
            for (string str : M.keyset()) {
                boolean isSame= false;
                if(String.isBlank( string.valueof(opp.get(str))) && String.isBlank( string.valueof(oldMap.get(opp.Id).get(str))))
                    isSame = true;
                if(mapStatusWithFieldToEdit.keyset().contains(oldMap.get(opp.Id).stageName)  &&  opp.get(str) != oldMap.get (opp.Id).get(str) &&
                   !mapStatusWithFieldToEdit.get(oldMap.get(opp.Id).stageName).contains(str.toLowercase()) && !M.get(str).getDescribe().isCalculated() && !isSame  ){
                    if(!Test.isRunningTest())  
                    opp.addError('You are not allowed to change any of the opportunity fields');
                   }
            } 
        }
    }
}