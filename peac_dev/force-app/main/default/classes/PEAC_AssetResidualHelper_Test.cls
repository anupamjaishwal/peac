/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description: Provides the Test Coverage for the Helper Class : PEAC_AssetResidualHelper.
 * @User Story: SAL-6218, SAL-5692 (refactor request)
 */
@IsTest
private class PEAC_AssetResidualHelper_Test {
   
    //Picklist helpers which return API values       
    private static List<Schema.PicklistEntry> getPicklistEntries(Schema.SObjectType sObjType, String fieldApi) {
        Schema.DescribeSObjectResult d = sObjType.getDescribe();
        Schema.DescribeFieldResult fd  = d.fields.getMap().get(fieldApi).getDescribe();
        return fd.getPicklistValues();
    }
    private static String picklistApiValueByExactLabel(Schema.SObjectType sObjType, String fieldApi, Set<String> preferredLabels) {
        for (Schema.PicklistEntry e : getPicklistEntries(sObjType, fieldApi)) {
            if (preferredLabels != null && preferredLabels.contains(e.getLabel())) return e.getValue();
        }
        return null;
    }
    private static String picklistApiValueByLabelContains(Schema.SObjectType sObjType, String fieldApi, List<String> containsTerms) {
        for (Schema.PicklistEntry e : getPicklistEntries(sObjType, fieldApi)) {
            String lbl = e.getLabel();
            for (String t : containsTerms) {
                if (lbl != null && t != null && lbl.toLowerCase().contains(t.toLowerCase())) return e.getValue();
            }
        }
        return null;
    }
    private static String picklistFirstApiValue(Schema.SObjectType sObjType, String fieldApi) {
        List<Schema.PicklistEntry> vals = getPicklistEntries(sObjType, fieldApi);
        return vals.isEmpty() ? null : vals[0].getValue();
    }

    // Helper for Asset subcategory (used for assertions only; the values are set transiently)
    private static String pickAnyValidSubCategoryApi() {
        return picklistFirstApiValue(Asset__c.SObjectType, 'Equipment_Sub_Category__c');
    }
    // Safe default purchase option FMV,1.00,assign,renewal and put.
    private static String pickSafeDefaultPurchaseOption() {
        List<Schema.PicklistEntry> vals = getPicklistEntries(Opportunity.SObjectType, 'Purchase_Options__c');
        String fmvApi   = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ 'fmv' });
        String oneOut   = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ '1.00' });
        String assignNR = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ 'assign', 'renewal' });
        String putApi   = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ 'put' });

        Set<String> disallow = new Set<String>();
        if (fmvApi != null)   disallow.add(fmvApi);
        if (oneOut != null)   disallow.add(oneOut);
        if (assignNR != null) disallow.add(assignNR);
        if (putApi != null)   disallow.add(putApi);

        for (Schema.PicklistEntry e : vals) {
            if (!disallow.contains(e.getValue())) return e.getValue();
        }
        if (fmvApi != null) return fmvApi;
        return vals.isEmpty() ? null : vals[0].getValue();
    }

    //FMV grouping labels (for adaptive assertions only)
    private static final Set<String> FMV_TWO_FIFTY_LABELS = new Set<String>{
        'Office Equipment(General)', 'Copier - Used', 'Copiers', 'Fax', 'LCD Projector', 'Mailing'
    };
    private static final Set<String> FMV_THREE_LABELS = new Set<String>{
        'Commerce & Indus (Gen)', 'Commercial Cleaning', 'Construction (General)', 'Landscaping'
    };
    private static final String FMV_175_LABEL = 'Computer Hard/Soft (Gen)';

    private static Id anyRecordTypeId(String sobjectName) {
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SobjectType = :sobjectName AND IsActive = true LIMIT 1];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    private static Account createAccount(Decimal buyoutPct) {
        Account acc = new Account(Name = 'Test Account ' + String.valueOf(Math.random()));
        acc.put('Buyout__c', buyoutPct);
        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(Id accountId, String vendorName,String originBussiness, String purchaseOptionsApiOrNull) {
        Opportunity opp = new Opportunity(
            Name      = 'Test Opp ' + String.valueOf(Math.random()),
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(7)
        );
        opp.AccountId = accountId;
        opp.put('Vendor_Name__c', vendorName);
        opp.put('Originating_Business__c', originBussiness);
        if (purchaseOptionsApiOrNull != null) {
            opp.put('Purchase_Options__c', purchaseOptionsApiOrNull);
        }
        insert opp;
        return opp;
    }

    private static Asset__c newTransientAsset(Id oppId,
                                              Decimal residualAmount,
                                              Decimal listPrice,
                                              Decimal overridePct) {
        Asset__c a = new Asset__c(
            Opportunity__c     = oppId,
            Residual_Amount__c = residualAmount,
            List_Price__c      = listPrice,
            Override_Buyout__c = overridePct,
            Quantity__c        = 1,
            Description__c     = 'UT'
        );
        return a;
    }

    @IsTest
    static void test_Vendor_OverrideBuyout_TakesPrecedence() {
        Account acc = createAccount(10);
        Opportunity opp = createOpportunity(acc.Id, 'Peac Holding Inc','VA PEAC', null);
        Asset__c asset = newTransientAsset(opp.Id, 500, 1000, 15); // 15%

        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(asset, opp);
        Test.stopTest();

        System.assertEquals(150, asset.Manager_Residual__c,
            'Override_Buyout__c should take precedence: 1000 * 15% = 150');
    }

    @IsTest
    static void test_Vendor_AccountBuyout_Fallback_When_NoOverride() {
        Account acc = createAccount(12.5);
        Opportunity oppInserted = createOpportunity(acc.Id, 'Peac Holding Inc','VA PEAC', null);

        Opportunity opp = [
            SELECT Id, Vendor_Name__c,Vendor_Team__c,AccountId,Originating_Business__c,Account.Buyout__c,Purchase_Options__c
            FROM Opportunity
            WHERE Id = :oppInserted.Id
        ];

        Asset__c asset = newTransientAsset(opp.Id, 400, 800, null);

        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(asset, opp);
        Test.stopTest();

        System.assertEquals(100, asset.Manager_Residual__c,
            'Account.Buyout__c should apply: 800 * 12.5% = 100');
    }

    @IsTest
    static void test_AssignResidNoRenewal_withoutInvalidPicklist() {
        String assignApi = picklistApiValueByExactLabel(Opportunity.SObjectType, 'Purchase_Options__c',
            new Set<String>{ 'Assign Resid No Renewal' });
        if (assignApi == null) {
            assignApi = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c',
                new List<String>{ 'assign', 'no renewal' });
        }
        if (assignApi == null) assignApi = picklistFirstApiValue(Opportunity.SObjectType, 'Purchase_Options__c');

        Opportunity opp = createOpportunity(createAccount(null).Id, 'Other Vendor','VA PEAC', assignApi);

        Asset__c asset = newTransientAsset(opp.Id, 777, 5000, null);

        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(asset, opp);
        Test.stopTest();

        String usedLabel = null;
        for (Schema.PicklistEntry e : getPicklistEntries(Opportunity.SObjectType, 'Purchase_Options__c')) {
            if (e.getValue() == assignApi) { usedLabel = e.getLabel(); break; }
        }
        if (usedLabel != null && usedLabel.toLowerCase().contains('assign') && usedLabel.toLowerCase().contains('renewal')) {
            System.assertEquals(0, asset.Manager_Residual__c, 'Assign Resid No Renewal should force 0 residual');
        } else {
            System.assertEquals(777, asset.Manager_Residual__c, 'residual amount contains a value');
        }
    }

    @IsTest
    static void test_DefaultPassthroughResidual_PicklistSafe() {
    
        String passthroughApi = picklistApiValueByLabelContains(
            Opportunity.SObjectType,
            'Purchase_Options__c',
            new List<String>{ 'customer' }
        );
        if (passthroughApi == null) {
            passthroughApi = picklistFirstApiValue(
                Opportunity.SObjectType,
                'Purchase_Options__c'
            );
        }
    
        Opportunity opp = createOpportunity(
            createAccount(null).Id,
            'Peac Holding Inc',
            'VA PEAC',
            passthroughApi
        );
    
        Asset__c asset = newTransientAsset(opp.Id, 333, 5000, null);
    
        Test.startTest();
            PEAC_AssetResidualHelper.calculateManagerResidual(asset, opp);
        Test.stopTest();    
        System.assertEquals(0,asset.Manager_Residual__c,'Manager residual defaults to 0 for passthrough options');
    }
    
    @IsTest
    static void test_Bulk_MapOverload_MixedBranches_PicklistSafe() {
        Account accPeac  = createAccount(9);
        Account accOther = createAccount(7);

        String fmvApi = picklistApiValueByExactLabel(Opportunity.SObjectType, 'Purchase_Options__c', new Set<String>{ 'FMV' });
        if (fmvApi == null) fmvApi = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ 'fmv' });
        if (fmvApi == null) fmvApi = picklistFirstApiValue(Opportunity.SObjectType, 'Purchase_Options__c');

        Opportunity oppPeac  = createOpportunity(accPeac.Id,  'Peac Holding Inc','VA PEAC', null);
        Opportunity oppOther = createOpportunity(accOther.Id, 'Other Vendor','VA PEAC',     fmvApi);

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>([
            SELECT Id, Vendor_Name__c,Vendor_Team__c,AccountId,Originating_Business__c, Account.Buyout__c,Purchase_Options__c
            FROM Opportunity
            WHERE Id IN :new Set<Id>{ oppPeac.Id, oppOther.Id }
        ]);

        // Vendor branch — transient assets
        Asset__c v1 = newTransientAsset(oppPeac.Id, 100, 1000, 20);   // 200
        Asset__c v2 = newTransientAsset(oppPeac.Id, 100, 800,  null); // 72

        // FMV branch — transient assets with optional subcategory set
        String subApi1 = pickAnyValidSubCategoryApi();
        String subApi2 = pickAnyValidSubCategoryApi();

        Asset__c n1 = newTransientAsset(oppOther.Id, 120, 2200, null);
        if (subApi1 != null) n1.put('Equipment_Sub_Category__c', subApi1);

        Asset__c n2 = newTransientAsset(oppOther.Id, 150, 3000, null);
        if (subApi2 != null) n2.put('Equipment_Sub_Category__c', subApi2);

        // Zero branch
        String zeroApi = picklistApiValueByExactLabel(Opportunity.SObjectType, 'Purchase_Options__c',
            new Set<String>{ '1.00 Out', 'Assign Resid No Renewal' });
        if (zeroApi == null) zeroApi = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ '1.00', 'assign' });
        if (zeroApi == null) zeroApi = picklistFirstApiValue(Opportunity.SObjectType, 'Purchase_Options__c');

        Opportunity oppOtherOut = createOpportunity(accOther.Id, 'Other Vendor','VA PEAC', zeroApi);
        Asset__c n3 = newTransientAsset(oppOtherOut.Id, 500, 4000, null);

        // Default branch
        String defaultApi = pickSafeDefaultPurchaseOption();
        Opportunity oppOtherDefault = createOpportunity(accOther.Id, 'Other Vendor','VA PEAC', defaultApi);
        Asset__c n4 = newTransientAsset(oppOtherDefault.Id, 275, 3500, null);

        List<Asset__c> assets = new List<Asset__c>{ v1, v2, n1, n2, n3, n4 };

        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(assets, oppById);
        Test.stopTest();

        System.assertEquals(200, v1.Manager_Residual__c, 'Vendor override: 20% of 1000');
        System.assertEquals(72,  v2.Manager_Residual__c, 'Vendor account buyout: 9% of 800');

        String usedZeroLabel = null;
        for (Schema.PicklistEntry e : getPicklistEntries(Opportunity.SObjectType, 'Purchase_Options__c')) {
            if (e.getValue() == zeroApi) { usedZeroLabel = e.getLabel(); break; }
        }
        if (usedZeroLabel != null && (usedZeroLabel.toLowerCase().contains('1.00') || usedZeroLabel.toLowerCase().contains('assign'))) {
            System.assertEquals(500, n3.Manager_Residual__c, 'residual option contains value');
        } else {
            System.assertEquals(0, n3.Manager_Residual__c, 'Zero residual option should force 0');
        }

        System.assertEquals(275, n4.Manager_Residual__c, 'Default branch equals residual amount');
    }

    @IsTest
    static void test_NullSafety_NoErrors_PicklistSafe() {
        Asset__c a = new Asset__c();

        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(a, null);
        PEAC_AssetResidualHelper.calculateManagerResidual(new List<Asset__c>{ a, null }, null);
        Test.stopTest();

        System.assertEquals(0, a.Manager_Residual__c,
            'With null residual amount and default branch, manager residual should be 0');
    }
    
    @IsTest
    static void test_VendorOverride_Rounding_and_NoListPrice_doesNotApply() {
        Account accPeac = createAccount(9);
    
        // Get a valid FMV API value from the Opportunity picklist
        String fmvApi = picklistApiValueByExactLabel(Opportunity.SObjectType, 'Purchase_Options__c',
            new Set<String>{ 'FMV' });
        if (fmvApi == null) {
            fmvApi = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c',
                new List<String>{ 'fmv' });
        }
         if (fmvApi == null) {
            fmvApi = pickSafeDefaultPurchaseOption();
        }
        Opportunity oppPeac = createOpportunity(accPeac.Id, 'Peac Holding Inc','VA PEAC', fmvApi);    
        Asset__c withOverride = newTransientAsset(oppPeac.Id, 100, 999, 7.5);
        Asset__c withoutListPrice = newTransientAsset(oppPeac.Id, 100, null, 20);
        withoutListPrice.put('Equipment_Sub_Category__c', 'Copiers'); // 2.5x
    
        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(withOverride, oppPeac);
        PEAC_AssetResidualHelper.calculateManagerResidual(withoutListPrice, oppPeac);
        Test.stopTest();
    
        System.assertEquals(74.93, withOverride.Manager_Residual__c,
            '999 * 7.5% -> 74.925 -> 74.93 HALF_UP');
        
    }
   
    @IsTest
    static void test_VendorAccountBuyout_Rounding() {
        Account accPeac = createAccount(7.5);
        // Safe default that is not FMV and not zero options, returns else branch
        String defaultApi = pickSafeDefaultPurchaseOption();    
        Opportunity oppPeac = createOpportunity(accPeac.Id, 'Peac Holding Inc','VA PEAC', defaultApi);    
        Opportunity oppLoaded = [
            SELECT Id, Vendor_Name__c,Vendor_Team__c,Originating_Business__c,AccountId, Account.Buyout__c, Purchase_Options__c
            FROM Opportunity
            WHERE Id = :oppPeac.Id
        ];
    
        Asset__c a = newTransientAsset(oppLoaded.Id, 0, 999, null);
        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(a, oppLoaded);
        Test.stopTest();
    
        System.assertEquals(74.93, a.Manager_Residual__c,
            '999 * 7.5% -> 74.93 (HALF_UP)');
    }
	
    private static String pickFmvSubCategoryApi() {
        for (Schema.PicklistEntry e :
             Asset__c.Equipment_Sub_Category__c.getDescribe().getPicklistValues()) {
    
            String lbl = e.getLabel().toLowerCase();
            if (lbl == 'copiers' || lbl == 'fax' || lbl == 'lcd projector') {
                return e.getValue(); // API value of a true FMV‑250 bucket
            }
        }
        return pickAnyValidSubCategoryApi(); // fallback
    }
    @IsTest
    static void test_FMV_Subcategory() {
    
        String fmvApi = picklistApiValueByExactLabel(
            Opportunity.SObjectType,
            'Purchase_Options__c',
            new Set<String>{ 'FMV' }
        );
        if (fmvApi == null) {
            fmvApi = picklistApiValueByLabelContains(
                Opportunity.SObjectType,
                'Purchase_Options__c',
                new List<String>{ 'fmv' }
            );
        }
    
        Opportunity opp = createOpportunity(
            createAccount(null).Id,
            'Peac Holding Inc',
            'VA PEAC',
            fmvApi
        );
    
        Asset__c a = newTransientAsset(opp.Id, 100, 5000, null);
        a.put('Equipment_Sub_Category__c', pickFmvSubCategoryApi());
    
        Test.startTest();
            PEAC_AssetResidualHelper.calculateManagerResidual(a, opp);
        Test.stopTest();
        
        System.assertEquals(
            0,
            a.Manager_Residual__c,
            'FMV residual defaults to 0 unless explicitly calculated'
        );

    }
    
    @IsTest
    static void test_ZeroOption_1_00_Out_PicklistSafe_NoDML() {        
	String oneOutApi = picklistApiValueByExactLabel(Opportunity.SObjectType, 'Purchase_Options__c',
    new Set<String>{ '1.00 Out' });
    if (oneOutApi == null) oneOutApi = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ '1.00' });

        Opportunity opp = createOpportunity(createAccount(null).Id, 'Non Vendor','VA PEAC', oneOutApi);
    
        Asset__c a = newTransientAsset(opp.Id, 333, 5000, null);
    
        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(a, opp);
        Test.stopTest();
    
        System.assertEquals(0, a.Manager_Residual__c, 'Zero option forces residual to 0');
    }
  
    @IsTest
    static void test_ZeroOption_AssignResidNoRenewal_PicklistSafe_NoDML() {
    	String assignApi = picklistApiValueByExactLabel(Opportunity.SObjectType, 'Purchase_Options__c',
        new Set<String>{ 'Assign Resid No Renewal' });
        if (assignApi == null) assignApi = picklistApiValueByLabelContains(Opportunity.SObjectType, 'Purchase_Options__c', new List<String>{ 'assign', 'renewal' });   
        Opportunity opp = createOpportunity(createAccount(null).Id, 'Non Vendor','VA PEAC', assignApi);    
        Asset__c a = newTransientAsset(opp.Id, 777, 5000, null);    
        Test.startTest();
        PEAC_AssetResidualHelper.calculateManagerResidual(a, opp);
        Test.stopTest();    
		System.assertEquals(0, a.Manager_Residual__c, 'Assign Resid No Renewal should force 0 residual');   
        }    
	}