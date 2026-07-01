/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description: Helper to compute Manager_Residual__c; supports bulk and single record flows.
 * @User Story: SAL-6218, SAL-5692 (refactor request)
 */
public with sharing class PEAC_AssetResidualHelper {
    // Static sets to avoid repeated allocations across bulk operations
    private static final Set<String> FMV_TWO_FIFTY = new Set<String>{
        'office equipment (general)', 'copier - used', 'copiers', 'fax', 'lcd projector', 'mailing'
        //'Office Equipment(General)', 'Copier - Used', 'Copiers', 'Fax', 'LCD Projector', 'Mailing'
    };
    private static final Set<String> FMV_THREE = new Set<String>{
        'commerce & indus (gen)', 'commercial cleaning', 'construction (general)', 'landscaping'
        //'Commerce & Indus (Gen)', 'Commercial Cleaning', 'Construction (General)', 'Landscaping'
    };
    //Bulk method: computes Manager_Residual__c for all assets based on related opportunities.
    public static void calculateManagerResidual(List<Asset__c> assets, Map<Id, Opportunity> oppById) {
        if (assets == null || assets.isEmpty()) return;
        for (Asset__c a : assets) {
            if (a == null) continue;
            Opportunity opp = (a.Opportunity__c != null && oppById != null)
                ? oppById.get(a.Opportunity__c)
                : null;
            applyManagerResidual(a, opp);
        }
    }
    public static void calculateManagerResidual(Asset__c asset, Opportunity relatedOpp) {
        if (asset == null) return;
        applyManagerResidual(asset, relatedOpp);
    }     
    private static void applyManagerResidual(Asset__c asset, Opportunity opp) {
        Decimal residualAmount = (asset.Residual_Amount__c == null) ? 0 : asset.Residual_Amount__c;		
        //derive effective purchase option from Asset first, then fallback to Opportunity
        String purchaseOpt = (String)asset.get('Purchase_Options__c');
        if (purchaseOpt == null && opp != null) {
            purchaseOpt = (String)opp.get('Purchase_Options__c');
        }
        Decimal managerResidual;
        // Base logic by Purchase Option
        switch on purchaseOpt {
            when '1.00 Out', 'Assign Resid No Renewal' {
                managerResidual = 0;
            }
            when 'FMV' {				
				String subCatLbl = labelForValue(Asset__c.SObjectType, 'Equipment_Sub_Category__c', asset.Equipment_Sub_Category__c);
                String eqCodeLbl = labelForValue(Asset__c.SObjectType, 'Equipment_Code__c', (String)asset.get('Equipment_Code__c'));

                String nSub = norm(subCatLbl);
                String nCode = norm(eqCodeLbl);

                // Exact 1.75× branch
                if (nSub == norm('Computer Hard/Soft (Gen)') || nCode == norm('Computer Hard/Soft (Gen)')) {
                    managerResidual = residualAmount * 1.75;
                }
                // 2.5× branch (if either label matches the group)
                else if (FMV_TWO_FIFTY.contains(nSub) || FMV_TWO_FIFTY.contains(nCode)) {
                    managerResidual = residualAmount * 2.50;
                }
                // 3.0× branch
                else if (FMV_THREE.contains(nSub) || FMV_THREE.contains(nCode)) {
                    managerResidual = residualAmount * 3;
                }
                // Default FMV multiplier
                else {
                    managerResidual = residualAmount * 1.5;
                }

				System.debug('Label Values :: ' + labelForValue(Asset__c.SObjectType, 'Equipment_Sub_Category__c', asset.Equipment_Sub_Category__c));
                
                /*if (subCat == 'Computer Hard/Soft (Gen)') {
                    managerResidual = residualAmount * 1.75;
                } else if (FMV_TWO_FIFTY.contains(subCat)) {
                    managerResidual = residualAmount * 2.50;
                } else if (FMV_THREE.contains(subCat)) {
                    managerResidual = residualAmount * 3;
                } else {
                    managerResidual = residualAmount * 1.5;
                }*/
            }
            when else {
                managerResidual = residualAmount;
            }
        }
        Boolean isPeacVendor = (opp != null && opp.Originating_Business__c == 'VA PEAC');
    	//Boolean isPeacVendor = (opp != null && opp.Originating_Business__c == 'VA PEAC' && (opp.Vendor_Name__c == 'Peac Holding Inc' || opp.Vendor_Team__c == 'Peac Holding Inc'));
		if (isPeacVendor) {
            // Override takes precedence if present and List Price available
            if (asset.Override_Buyout__c != null && asset.List_Price__c != null) {
                managerResidual = (asset.List_Price__c * (asset.Override_Buyout__c / 100)).setScale(2, RoundingMode.HALF_UP);
            }
            // Else use Account.Buyout__c if present and List Price available
            else if (asset.Override_Buyout__c == null
                && asset.List_Price__c != null
                && opp != null
                && opp.Account != null
                && opp.Account.Buyout__c != null) {
                managerResidual = (asset.List_Price__c * (opp.Account.Buyout__c / 100)).setScale(2, RoundingMode.HALF_UP);
            }
            
			//If PEAC vendor + List Price exists but BOTH buyout % values are missing => Manager Residual must be 0
            else if (asset.List_Price__c != null) {
                managerResidual = 0;
            }
        }
        asset.Manager_Residual__c = managerResidual;
    }    
        
    /** Returns the picklist LABEL for a given API value. Safe for nulls. */	
	private static String labelForValue(Schema.SObjectType sObjType, String fieldApi, String valueApi) {
        if (valueApi == null) return null;
        try {
            Schema.DescribeSObjectResult d = sObjType.getDescribe();
            Schema.DescribeFieldResult fd  = d.fields.getMap().get(fieldApi).getDescribe();
            for (Schema.PicklistEntry e : fd.getPicklistValues()) {
                if (e.getValue() == valueApi) return e.getLabel();
            }
        } catch (Exception ignore) { /* describe failures → return null */ }
        return null;
    }

    /** Normalizes a label: trim + lowercase, safe for nulls. */
    private static String norm(String s) {
        return (s == null) ? null : s.trim().toLowerCase();
    }

}