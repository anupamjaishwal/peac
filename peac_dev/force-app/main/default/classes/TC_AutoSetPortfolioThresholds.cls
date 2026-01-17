public class TC_AutoSetPortfolioThresholds {
    public static void autoSetPortfolioThresholds (Map <Id, Account> oldMap,List <Account> newList, Map<Id, User> owners) {

        Set <Id> ownerIds = new Set <Id> ();
        List <Account> updateList = new List <Account> ();
        for (Account acc : newList) {
            if (acc.OwnerId != null && acc.DM_Review_Status__c == 'Submitted for Review' && (oldMap == null || oldMap.get (acc.Id).DM_Review_Status__c != acc.DM_Review_Status__c)) {
                ownerIds.add (acc.OwnerId);
                updateList.add (acc);
            }
        }

        if (!ownerIds.isEmpty()) {
            Map <Id, User> userMap = new Map <Id, User>();
            for(Id userId : owners.keySet()){
                if(ownerIds.contains(userId)){
                    userMap.put(userId, owners.get(userId));
                }
            }

            for (Account acc : updateList) {
                String team = userMap.get (acc.OwnerId) != null ? userMap.get (acc.OwnerId).Profile.Name: null;
                System.debug('team>>>' + team);
                if (team != null) {
                    if (!team.contains('IFP') && !team.contains('Express') && !team.contains('DataAdmin') && acc.Authorized_Seller__c == '2') {
                        acc.Portfolio_Review_Threshold__c = '500,000';
                    } else {
                        acc.Portfolio_Review_Threshold__c = '250,000';
                    }
                } else {
                    acc.Portfolio_Review_Threshold__c = '250,000';
                }

            }
        }
    }
    public static void autoSetPortfolioThresholds (Map <Id, Account> oldMap,Map <Id, Account> newMap, Map<Id, User> owners) {

        Set <Id> ownerIds = new Set <Id> ();
        Set <Id> updateList = new Set <Id> ();
        for (Id i : newMap.keySet()) {
            if (newMap.get(i).OwnerId != null && newMap.get(i).DM_Review_Status__c == 'Submitted for Review' && (oldMap == null || oldMap.get (i).DM_Review_Status__c != newMap.get(i).DM_Review_Status__c)) {
                ownerIds.add (newMap.get(i).OwnerId);
                updateList.add (i);
            }
        }

        if (!ownerIds.isEmpty()) {
            Map <Id, User> userMap = new Map <Id, User>();
            for(Id userId : owners.keySet()){
                if(ownerIds.contains(userId)){
                    userMap.put(userId, owners.get(userId));
                }
            }

            for (Id i : updateList) {
                String team = userMap.get (newMap.get(i).OwnerId) != null ? userMap.get (newMap.get(i).OwnerId).Profile.Name: null;
                System.debug('team>>>' + team);
                if (team != null) {
                    if (!team.contains('IFP') && !team.contains('Express') && !team.contains('DataAdmin') && newMap.get(i).Authorized_Seller__c == '2') {
                        newMap.get(i).Portfolio_Review_Threshold__c = '500,000';
                    } else {
                        newMap.get(i).Portfolio_Review_Threshold__c = '250,000';
                    }
                } else {
                    newMap.get(i).Portfolio_Review_Threshold__c = '250,000';
                }

            }
        }
    }
}