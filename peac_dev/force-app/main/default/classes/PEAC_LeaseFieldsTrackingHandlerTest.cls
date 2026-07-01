@isTest
public class PEAC_LeaseFieldsTrackingHandlerTest {

    @testSetup
    static void setupData() {
        User adminUser = SL_SCTestData.createTestUser();

        System.runAs(adminUser) {
            SL_SCTestData.createAccountAndContracts(1, 1);

            insert new RescoreIsMandatoryForLoan__c(
                Name = 'Lease Calculate Pricing',
                StageName__c = 'Docs Requested;Docs Out;Docs In;Review for Booking;Funding;Booking;Funded/Booked',
                ProfileName__c = ''
            );

            Account testAccount = [SELECT Id FROM Account LIMIT 1];

            Opportunity leaseOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'Lease Pricing Tracking Test Opp',
                StageName = 'Proposal',
                CloseDate = Date.today().addDays(30),
                Equipment_Cost__c = 1200,
                Payment_Amount__c = 100,
                Purchase_Options__c = 'FMV'
            );

            Id leaseRecordTypeId = getLeaseOpportunityRecordTypeId();
            if (leaseRecordTypeId != null) {
                leaseOpp.RecordTypeId = leaseRecordTypeId;
            }

            insert leaseOpp;
        }
    }

    @isTest
    static void testTrackedLeaseFieldChangeCreatesTrackerAndSetsFlag() {
        String trackedFieldApi = getUsableTrackedFieldApi();

        Opportunity baseOpp = getTestOpportunityWithTrackedField();

        Opportunity setupOpp = new Opportunity(
            Id = baseOpp.Id,
            StageName = 'Proposal',
            Scored_Field_Modified__c = false,
            Payment_Amount__c = 100
        );

        setInitialValue(setupOpp, trackedFieldApi);
        update setupOpp;

        Opportunity oldOpp = getTestOpportunityWithTrackedField();

        System.assertNotEquals(
            null,
            oldOpp.get(trackedFieldApi),
            'Old tracked field value must not be blank because handler ignores blank-to-populated changes.'
        );

        Opportunity newOpp = oldOpp.clone(false, true, false, false);
        newOpp.Id = oldOpp.Id;
        newOpp.StageName = 'Proposal';
       // newOpp.Loan_Record_Type__c = false;
        newOpp.Scored_Field_Modified__c = false;
        newOpp.Payment_Amount__c = 100;

        setDifferentValue(newOpp, oldOpp, trackedFieldApi);

        System.assertNotEquals(
            oldOpp.get(trackedFieldApi),
            newOpp.get(trackedFieldApi),
            'Tracked field value must actually change for the handler to set Scored_Field_Modified__c.'
        );

        Test.startTest();
        PEAC_LeaseFieldsTrackingHandler.beforeUpdate(
            new Map<Id, Opportunity>{ oldOpp.Id => oldOpp },
            new Map<Id, Opportunity>{ newOpp.Id => newOpp },
            new Set<Id>()
        );
        Test.stopTest();

        System.assertEquals(
            true,
            newOpp.Scored_Field_Modified__c,
            'Scored_Field_Modified__c should be set to true when a configured Lease pricing field changes.'
        );

        System.assertEquals(
            null,
            newOpp.Payment_Amount__c,
            'Payment_Amount__c should be cleared when a configured Lease pricing field changes.'
        );

        List<Field_Tracker__c> trackers = [
            SELECT Id, Opportunity__c, Object_Name__c, Field_Name__c, Action__c
            FROM Field_Tracker__c
            WHERE Opportunity__c = :oldOpp.Id
            AND Object_Name__c = 'Opportunity'
            AND Field_Name__c = :trackedFieldApi
        ];

        System.assertEquals(
            1,
            trackers.size(),
            'Expected one Field_Tracker__c record for the changed Lease pricing field.'
        );

        System.assertEquals('Modified', trackers[0].Action__c);
    }

    @isTest
    static void testForwardStageMoveIsBlockedWhenTrackerExists() {
        Opportunity oldOpp = getTestOpportunityWithTrackedField();
        String trackedFieldApi = getUsableTrackedFieldApi();

        insert new Field_Tracker__c(
            Object_Name__c = 'Opportunity',
            Opportunity__c = oldOpp.Id,
            Record_Id__c = oldOpp.Id,
            Field_Label__c = trackedFieldApi,
            Field_Name__c = trackedFieldApi,
            Action__c = 'Modified',
            Old_Value__c = 'Old',
            New_Value__c = 'New'
        );

        Opportunity newOpp = oldOpp.clone(false, true, false, false);
        newOpp.Id = oldOpp.Id;
        newOpp.StageName = 'Docs Requested';

        Test.startTest();
        PEAC_LeaseFieldsTrackingHandler.beforeUpdate(
            new Map<Id, Opportunity>{ oldOpp.Id => oldOpp },
            new Map<Id, Opportunity>{ newOpp.Id => newOpp },
            new Set<Id>{ newOpp.Id }
        );
        Test.stopTest();

        System.assertEquals(
            true,
            newOpp.hasErrors(),
            'Forward movement into a configured stage should be blocked when Lease pricing tracking exists.'
        );
    }

    @isTest
    static void testBackwardStageMoveIsAllowedWhenTrackerExists() {
        Opportunity baseOpp = getTestOpportunityWithTrackedField();
        String trackedFieldApi = getUsableTrackedFieldApi();

        insert new Field_Tracker__c(
            Object_Name__c = 'Opportunity',
            Opportunity__c = baseOpp.Id,
            Record_Id__c = baseOpp.Id,
            Field_Label__c = trackedFieldApi,
            Field_Name__c = trackedFieldApi,
            Action__c = 'Modified',
            Old_Value__c = 'Old',
            New_Value__c = 'New'
        );

        Opportunity oldOpp = baseOpp.clone(false, true, false, false);
        oldOpp.Id = baseOpp.Id;
        oldOpp.StageName = 'Docs Out';

        Opportunity newOpp = baseOpp.clone(false, true, false, false);
        newOpp.Id = baseOpp.Id;
        newOpp.StageName = 'Docs Requested';

        Test.startTest();
        PEAC_LeaseFieldsTrackingHandler.beforeUpdate(
            new Map<Id, Opportunity>{ oldOpp.Id => oldOpp },
            new Map<Id, Opportunity>{ newOpp.Id => newOpp },
            new Set<Id>()
        );
        Test.stopTest();

        System.assertEquals(
            false,
            newOpp.hasErrors(),
            'Backward movement should not be blocked even when Lease pricing tracking exists.'
        );
    }

    @isTest
    static void testClearLeasePricingTrackingDeletesTrackersAndClearsFlag() {
        Opportunity opp = getTestOpportunityWithTrackedField();
        String trackedFieldApi = getUsableTrackedFieldApi();

        insert new Field_Tracker__c(
            Object_Name__c = 'Opportunity',
            Opportunity__c = opp.Id,
            Record_Id__c = opp.Id,
            Field_Label__c = trackedFieldApi,
            Field_Name__c = trackedFieldApi,
            Action__c = 'Modified',
            Old_Value__c = 'Old',
            New_Value__c = 'New'
        );

        update new Opportunity(
            Id = opp.Id,
            Scored_Field_Modified__c = true
        );

        Test.startTest();
        PEAC_LeaseFieldsTrackingHandler.clearLeasePricingTracking(
            new Set<Id>{ opp.Id }
        );
        Test.stopTest();

        Integer trackerCount = [
            SELECT COUNT()
            FROM Field_Tracker__c
            WHERE Opportunity__c = :opp.Id
            AND Object_Name__c = 'Opportunity'
            AND Field_Name__c = :trackedFieldApi
        ];

        Opportunity refreshedOpp = [
            SELECT Id, Scored_Field_Modified__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(
            0,
            trackerCount,
            'Lease pricing Field_Tracker__c records should be deleted after successful pricing.'
        );

        System.assertEquals(
            false,
            refreshedOpp.Scored_Field_Modified__c,
            'Scored_Field_Modified__c should be cleared after successful pricing.'
        );
    }

    private static Opportunity getTestOpportunityWithTrackedField() {
        Set<String> trackedFields = getAllValidTrackedFields();

        String soql = 'SELECT Id, StageName, Loan_Record_Type__c, Scored_Field_Modified__c, Payment_Amount__c, Opportunity_CurrentUser_Profile__c';

        for (String fieldApi : trackedFields) {
            soql += ', ' + fieldApi;
        }

        soql += ' FROM Opportunity LIMIT 1';

        Opportunity opp = Database.query(soql);

        System.assertNotEquals(
            true,
            opp.Loan_Record_Type__c,
            'Test Opportunity must be a Lease Opportunity. Please confirm Lease record type setup.'
        );

        return opp;
    }

    private static Set<String> getAllValidTrackedFields() {
        Set<String> trackedFields = new Set<String>();

        FieldTrackingForLoan__mdt config =
            FieldTrackingForLoan__mdt.getInstance('Lease_Opportunity');

        System.assertNotEquals(
            null,
            config,
            'Missing FieldTrackingForLoan__mdt record: Lease_Opportunity.'
        );

        System.assert(
            String.isNotBlank(config.FieldNames__c),
            'Lease_Opportunity.FieldNames__c must contain at least one Opportunity field API name.'
        );

        Map<String, Schema.SObjectField> oppFieldMap =
            Schema.SObjectType.Opportunity.fields.getMap();

        for (String rawFieldApi : config.FieldNames__c.split(';')) {
            String fieldApi = rawFieldApi != null ? rawFieldApi.trim() : null;

            if (String.isNotBlank(fieldApi) && oppFieldMap.containsKey(fieldApi)) {
                trackedFields.add(fieldApi);
            }
        }

        System.assert(
            !trackedFields.isEmpty(),
            'No valid Opportunity fields found in Lease_Opportunity.FieldNames__c.'
        );

        return trackedFields;
    }

    private static String getUsableTrackedFieldApi() {
        Set<String> trackedFields = getAllValidTrackedFields();

        Map<String, Schema.SObjectField> oppFieldMap =
            Schema.SObjectType.Opportunity.fields.getMap();

        if (trackedFields.contains('Equipment_Cost__c')
            && oppFieldMap.containsKey('Equipment_Cost__c')
            && oppFieldMap.get('Equipment_Cost__c').getDescribe().isUpdateable()) {
            return 'Equipment_Cost__c';
        }

        for (String fieldApi : trackedFields) {
            if (oppFieldMap.get(fieldApi).getDescribe().isUpdateable()) {
                return fieldApi;
            }
        }

        System.assert(false, 'No updateable Opportunity fields found in Lease_Opportunity.FieldNames__c.');
        return null;
    }

    private static void setInitialValue(Opportunity opp, String fieldApi) {
        Schema.DescribeFieldResult fieldDescribe =
            Schema.SObjectType.Opportunity.fields.getMap().get(fieldApi).getDescribe();

        Schema.DisplayType fieldType = fieldDescribe.getType();

        if (fieldType == Schema.DisplayType.Boolean) {
            opp.put(fieldApi, false);
        } else if (fieldType == Schema.DisplayType.Date) {
            opp.put(fieldApi, Date.today());
        } else if (fieldType == Schema.DisplayType.DateTime) {
            opp.put(fieldApi, System.now());
        } else if (
            fieldType == Schema.DisplayType.Currency ||
            fieldType == Schema.DisplayType.Double ||
            fieldType == Schema.DisplayType.Integer ||
            fieldType == Schema.DisplayType.Percent
        ) {
            opp.put(fieldApi, 100);
        } else if (fieldType == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry pe : fieldDescribe.getPicklistValues()) {
                if (pe.isActive()) {
                    opp.put(fieldApi, pe.getValue());
                    return;
                }
            }
        } else if (fieldType == Schema.DisplayType.MultiPicklist) {
            for (Schema.PicklistEntry pe : fieldDescribe.getPicklistValues()) {
                if (pe.isActive()) {
                    opp.put(fieldApi, pe.getValue());
                    return;
                }
            }
        } else {
            opp.put(fieldApi, 'Initial Test Value');
        }
    }

    private static void setDifferentValue(
        Opportunity newOpp,
        Opportunity oldOpp,
        String fieldApi
    ) {
        Schema.DescribeFieldResult fieldDescribe =
            Schema.SObjectType.Opportunity.fields.getMap().get(fieldApi).getDescribe();

        Schema.DisplayType fieldType = fieldDescribe.getType();
        Object oldValue = oldOpp.get(fieldApi);

        if (fieldType == Schema.DisplayType.Boolean) {
            Boolean oldBoolean = oldValue == null ? false : (Boolean)oldValue;
            newOpp.put(fieldApi, !oldBoolean);
        } else if (fieldType == Schema.DisplayType.Date) {
            newOpp.put(fieldApi, Date.today().addDays(7));
        } else if (fieldType == Schema.DisplayType.DateTime) {
            newOpp.put(fieldApi, System.now().addDays(1));
        } else if (
            fieldType == Schema.DisplayType.Currency ||
            fieldType == Schema.DisplayType.Double ||
            fieldType == Schema.DisplayType.Integer ||
            fieldType == Schema.DisplayType.Percent
        ) {
            Decimal newValue = oldValue == null ? 1000 : Decimal.valueOf(String.valueOf(oldValue)) + 100;
            newOpp.put(fieldApi, newValue);
        } else if (fieldType == Schema.DisplayType.Picklist) {
            String currentValue = oldValue == null ? null : String.valueOf(oldValue);

            for (Schema.PicklistEntry pe : fieldDescribe.getPicklistValues()) {
                if (pe.isActive() && pe.getValue() != currentValue) {
                    newOpp.put(fieldApi, pe.getValue());
                    return;
                }
            }

            System.assert(false, 'No alternate active picklist value available for ' + fieldApi);
        } else if (fieldType == Schema.DisplayType.MultiPicklist) {
            for (Schema.PicklistEntry pe : fieldDescribe.getPicklistValues()) {
                if (pe.isActive()) {
                    newOpp.put(fieldApi, pe.getValue());
                    return;
                }
            }

            System.assert(false, 'No active multipicklist value available for ' + fieldApi);
        } else {
            newOpp.put(fieldApi, 'Updated Test Value ' + String.valueOf(System.now().getTime()));
        }
    }

    private static Id getLeaseOpportunityRecordTypeId() {
        Map<String, Schema.RecordTypeInfo> rtByName =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        if (rtByName.containsKey('Lease Opportunity')) {
            return rtByName.get('Lease Opportunity').getRecordTypeId();
        }

        if (rtByName.containsKey('Lease Booking')) {
            return rtByName.get('Lease Booking').getRecordTypeId();
        }

        return null;
    }
}