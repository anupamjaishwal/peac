public with sharing class EquipmentByBranchService {

    @InvocableMethod(label='Get Equipment By Branch')
    public static List<List<EquipmentOption>> getEquipment(List<String> dummy) {

        String branch = getUserBranch();
        List<EquipmentOption> options = new List<EquipmentOption>();

        if (branch == null) {
            return new List<List<EquipmentOption>> { options };
        }

        
        Equipment_By_Branch__mdt config = [
            SELECT Equipment_Value__c
            FROM Equipment_By_Branch__mdt
            WHERE Branch__c = :branch
            LIMIT 1
        ];

        if (config == null || String.isBlank(config.Equipment_Value__c)) {
            return new List<List<EquipmentOption>> { options };
        }

        
        Set<String> allowedValues = new Set<String>();

        for (String val : config.Equipment_Value__c.split(',')) {
            allowedValues.add(val.trim());
        }

        Schema.DescribeFieldResult fieldResult =
            Asset__c.Equipment_Code__c.getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {

            if (entry.isActive() &&
                allowedValues.contains(entry.getLabel())) {

                EquipmentOption opt = new EquipmentOption();
                opt.label = entry.getLabel();
                opt.value = entry.getValue();

                options.add(opt);
            }
        }

        return new List<List<EquipmentOption>> { options };
    }

    private static String getUserBranch() {

        User u = [
            SELECT Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        if (u.Profile.Name.contains('OEG')) return 'OEG';
        if (u.Profile.Name.contains('CT&I')) return 'CT&I';
        if (u.Profile.Name.contains('HC')) return 'HC';

        return null;
    }
}