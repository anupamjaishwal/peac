public without sharing class SL_DealerPortalCAAllowSave {
    @invocableMethod(label='Update Opportunity')
    public static List<Opportunity> updateOpp(List<Opportunity> opportunities){
        Opportunity theOpp = opportunities[0];
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        if(theOpp.Id == null){
            Database.SaveResult sr = Database.insert(theOpp,dml);
        }else{
            Database.SaveResult sr = Database.update(theOpp,dml);
        }
        return new List<Opportunity>{theOpp};
    }
}