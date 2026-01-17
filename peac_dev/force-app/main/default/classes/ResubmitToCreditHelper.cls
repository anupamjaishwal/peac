public class ResubmitToCreditHelper {
    //https://marlinbusiness.atlassian.net/browse/SAL-2048
    public static void validateReSubmit (List<Resubmission_to_Credit_Details__c> submitCreditList){
        Id userId = userinfo.getUserId();
        User userDetails =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id=:userId ];
        if(userDetails.UserRole == null) return; 
        Set <Id> Ids = new Set<Id>();
        Map<Id, Id> MapRCWithOpp = new Map<Id, Id>();
        Map<id, boolean>oppHas1stSubmision = new Map<id, boolean>();
        Map<id, boolean>oppHas2ndSubmision = new Map<id, boolean>();
        
        for(Resubmission_to_Credit_Details__c rc : submitCreditList) {
            Ids.add(rc.Opportunity__c);
            MapRCWithOpp.put(rc.id, rc.Opportunity__c);
        }
        
        List<Opportunity> oppsWithRC = new List<Opportunity>([ SELECT Id, ( SELECT Id,Appeal_Type__c FROM Resubmission_to_Credit_Details__r  ) FROM Opportunity  WHERE Id IN :Ids ]);
        
        for(Opportunity opp : oppsWithRC) {
            oppHas1stSubmision.put(opp.id, false);  
            oppHas2ndSubmision.put(opp.id, false);  
            for(Resubmission_to_Credit_Details__c rCRec : opp.Resubmission_to_Credit_Details__r) {
                if(rCRec.Appeal_Type__c == '1st')
                    oppHas1stSubmision.put(opp.id, true);  
                
                if(rCRec.Appeal_Type__c == '2nd')
                    oppHas2ndSubmision.put(opp.id, true);  
            }
        }
        
        for(Resubmission_to_Credit_Details__c rc : submitCreditList) {
            If(oppHas1stSubmision.get(MapRCWithOpp.get(rc.id)) && rc.Appeal_Type__c =='1st'){
                 rc.addError('Resubmit to credit is already having 1st Appeal type');
                //system.debug('======'+ oppHas1stSubmision.get(MapRCWithOpp.get(rc.id)));
            }
            else If(oppHas2ndSubmision.get(MapRCWithOpp.get(rc.id)) && rc.Appeal_Type__c =='2nd'){
                 rc.addError('Resubmit to credit is already having 2nd Appeal type');
            }
            else if(!oppHas1stSubmision.get(MapRCWithOpp.get(rc.id))  && rc.Appeal_Type__c =='2nd'){
                //error
                rc.addError('You are not allowed to select 2nd appeal if there is no 1st appeal');
            }            
        }   
    }
}