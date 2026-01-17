public class LeadConversion {
	@AuraEnabled
    public static String  leadValidation(Id id) {       
        String msg =' ';
        Lead objLead = [SELECT id,Name,Equipment_Type__c FROM Lead WHERE Id = :id];
     
        if(String.isBlank(objLead.Equipment_Type__c) || objLead.Equipment_Type__c == null){
            msg = 'fail';
        }
        else {
            msg = 'success';
        }
            return msg;
    }

}