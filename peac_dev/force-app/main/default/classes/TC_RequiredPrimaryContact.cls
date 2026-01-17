public class TC_RequiredPrimaryContact {
    public static void requiredPrimaryContact (Map<Id, Account> oldMap, List<Account> newList,
        String profileName, Map<Id, RecordType> recordTypes, Map<Id, AccountContactRelation> primaryContacts) {

        profileName = profileName != null? profileName: '';
        for (Account acc : newList) {
            if (String.isEmpty(acc.Review_For__c) || !acc.Review_For__c.contains('Approval') ||
                profileName.contains('DLG') || profileName.contains('Franchise') || profileName.contains('IFP')) {
                continue;
            }
            String recordTypeName = recordTypes.get(acc.RecordTypeId) != null? recordTypes.get(acc.RecordTypeId).Name: '';
            if ((recordTypeName == 'Dealer Account' || recordTypeName == 'Franchisor Account' || recordTypeName == 'Broker Account') 
                && primaryContacts.get(acc.Id) == null) {
                acc.addError('“Review For = Approval” requires a Primary Contact Role on the Account');
            }
        }
    }
    public static void requiredPrimaryContact (Map<Id, Account> oldMap, Map<Id, Account> newMap,
        String profileName, Map<Id, RecordType> recordTypes, Map<Id, AccountContactRelation> primaryContacts) {

        profileName = profileName != null? profileName: '';

        for (Id i : newMap.keySet()) {
            if (String.isEmpty(newMap.get(i).Review_For__c) || !newMap.get(i).Review_For__c.contains('Approval') || newMap.get(i).Review_For__c == oldMap.get(i).Review_For__c ||
                profileName.contains('DLG') || profileName.contains('Franchise') || profileName.contains('IFP')) {
                continue;
            }
            String recordTypeName = recordTypes.get(newMap.get(i).RecordTypeId) != null? recordTypes.get(newMap.get(i).RecordTypeId).Name: '';
            if ((recordTypeName == 'Dealer Account' || recordTypeName == 'Franchisor Account' || recordTypeName == 'Broker Account') 
                && primaryContacts.get(newMap.get(i).Id) == null) {
                newMap.get(i).addError('“Review For = Approval” requires a Primary Contact Role on the Account');
            }
        }
    }
}