public class TC_UpdateLastUpdateField {
     public static user currentuser ;
        public static void updateLastUpdatedField (Map <Id, Account> oldMap, List <Account> newList) {
        List<DiscoveryFieldsLastUpdate__mdt> mcs = [select id,MasterLabel,DeveloperName, LastUpdateFieldApiName__c from DiscoveryFieldsLastUpdate__mdt];
        if(currentuser == null || currentuser.Id != userinfo.getuserId() ){ 
            currentuser=new User();
            currentuser=[Select Id,Name,Email from User where Id=:userinfo.getuserId()];
        }
        List<ChangeUserForLastUpdateFields__mdt> mdtUsr = [select id,MasterLabel,DeveloperName from ChangeUserForLastUpdateFields__mdt where MasterLabel =: currentuser.Name ];
        string lastUpdated = currentuser.Name + ' , ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        if(mdtUsr.size() > 0){
            lastUpdated =   ' Dealer, ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');   
        }
        for(Account accRec : newList ){
            for(DiscoveryFieldsLastUpdate__mdt mtdRec : mcs){
                if(oldMap == null){
                    if(accRec.get(mtdRec.MasterLabel) != null){
                        accRec.put(mtdRec.LastUpdateFieldApiName__c, lastUpdated );
                    }
                }
                else{
                    if(accRec.get(mtdRec.MasterLabel) != oldMap.get (accRec.Id).get(mtdRec.MasterLabel)){
                        accRec.put(mtdRec.LastUpdateFieldApiName__c, lastUpdated );
                    }
                }
            }
        }
    }
    //added for Sl trigger framwork to have a method that used newMap -Tyler
    public static void updateLastUpdatedField (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        List<DiscoveryFieldsLastUpdate__mdt> mcs = [select id,MasterLabel,DeveloperName, LastUpdateFieldApiName__c from DiscoveryFieldsLastUpdate__mdt];
        if(currentuser == null || currentuser.Id != userinfo.getuserId() ){ 
            currentuser=new User();
            currentuser=[Select Id,Name,Email from User where Id=:userinfo.getuserId()];
        }
        List<ChangeUserForLastUpdateFields__mdt> mdtUsr = [select id,MasterLabel,DeveloperName from ChangeUserForLastUpdateFields__mdt where MasterLabel =: currentuser.Name ];
        string lastUpdated = currentuser.Name + ' , ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        if(mdtUsr.size() > 0){
            lastUpdated =   ' Dealer, ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');   
        }
        for(Id i : newMap.keySet()){
            for(DiscoveryFieldsLastUpdate__mdt mtdRec : mcs){
                if(oldMap == null){
                    if(newMap.get(i).get(mtdRec.MasterLabel) != null){
                        newMap.get(i).put(mtdRec.LastUpdateFieldApiName__c, lastUpdated );
                    }
                }
                else{
                    if(newMap.get(i).get(mtdRec.MasterLabel) != oldMap.get (i).get(mtdRec.MasterLabel)){
                        newMap.get(i).put(mtdRec.LastUpdateFieldApiName__c, lastUpdated );
                    }
                }
            }
        }
    }
}