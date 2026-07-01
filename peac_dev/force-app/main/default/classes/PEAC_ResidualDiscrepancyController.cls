/********************************************************************************************************************
 * Developed by Suraj Harichandan(LTIMindtree) as a part of BugFix for SAL-5654
 * Modified by Suraj Harichandan(LTM) on 2026-03-27 — Refactored to async @future pattern for
 *     non-blocking UX. Added DeactivateTriggers__c bypass alongside ORE__c.
 * @Description: Controller class for the Residual Discrepancy Banner LWC.
 *               Provides a lightweight @AuraEnabled dispatcher that validates the discrepancy
 *               and enqueues an @future method to re-query Assets, sum Residual_Amount__c,
 *               and update Residual__c on the Opportunity asynchronously.
 *               Temporarily enables ORE__c and DeactivateTriggers__c bypasses to prevent
 *               validation rule and trigger interference during the update.
 ********************************************************************************************************************/
public with sharing class PEAC_ResidualDiscrepancyController {

    /**
     * Added by Suraj Harichandan(LTM) on 2026-03-27
     * Lightweight dispatcher: validates discrepancy exists, then enqueues @future for async resolution.
     * Returns immediately with status = 'processing' so the LWC can show an in-progress toast.
     * @param opportunityId  The Id of the Opportunity to resolve
     * @return Map with 'status' (String: 'processing' | 'no_discrepancy' | 'error'), 'message' (String)
     */
    @AuraEnabled
    public static Map<String, Object> resolveResidualDiscrepancy(Id opportunityId) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            // 1. Quick-check: query Opportunity for current values
            Opportunity opp = [
                SELECT Id, Residual__c, Total_Asset_Residual__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            Decimal rollup = (opp.Total_Asset_Residual__c ?? 0).setScale(2, RoundingMode.HALF_UP);
            Decimal current = (opp.Residual__c ?? 0).setScale(2, RoundingMode.HALF_UP);

            // 2. Early exit if no discrepancy
            if (rollup == current) {
                result.put('status', 'no_discrepancy');
                result.put('message', 'No discrepancy found. Residual ($' + current + ') already matches.');
                return result;
            }

            // 3. Enqueue async resolution — runs in its own transaction with fresh governor limits
            resolveResidualAsync(opportunityId);

            result.put('status', 'processing');
            result.put('message', 'Recalculation in progress.');
        } catch (Exception ex) {
            result.put('status', 'error');
            result.put('message', 'Error: ' + ex.getMessage());
        }

        return result;
    }

    /**
     * Added by Suraj Harichandan(LTM) on 2026-03-27
     * Asynchronous worker: re-queries child Asset__c records, sums rollup fields,
     * and updates the Opportunity with bypass settings enabled.
     * Runs in a separate transaction with its own governor limits.
     * Bypasses ORE__c.Bypass__c and DeactivateTriggers__c for both TC_OpportunityTrigger
     * and PEAC_AssetTrigger to prevent validation rule and trigger interference during the update.
     * All settings are restored in finally blocks regardless of success or failure.
     * @param opportunityId  The Id of the Opportunity to resolve
     */
    @future
    public static void resolveResidualAsync(Id opportunityId) {
        // Bypass setting references — declared outside try so finally can restore them
        ORE__c oreSetting = ORE__c.getInstance();
        Boolean originalOreBypass = oreSetting.Bypass__c;

        DeactivateTriggers__c dtOppSetting = DeactivateTriggers__c.getInstance('TC_OpportunityTrigger');
        Boolean dtOppExisted = (dtOppSetting != null && dtOppSetting.Id != null);
        Boolean originalDtOppBypass = dtOppExisted ? dtOppSetting.IsDeactived__c : false;

        // Added by Suraj Harichandan(LTM) on 2026-03-27 — PEAC_AssetTrigger bypass
        DeactivateTriggers__c dtAssetSetting = DeactivateTriggers__c.getInstance('PEAC_AssetTrigger');
        Boolean dtAssetExisted = (dtAssetSetting != null && dtAssetSetting.Id != null);
        Boolean originalDtAssetBypass = dtAssetExisted ? dtAssetSetting.IsDeactived__c : false;

        try {
            // 1. Query Opportunity for current values
            Opportunity opp = [
                SELECT Id, Residual__c, Total_Asset_Residual__c,
                       Gross_Contract__c, Equipment_Cost__c, Number_of_Units__c, Gross_Finance__c
                FROM Opportunity
                WHERE Id = :opportunityId
            ];

            // 2. Re-query all child Assets and sum (mirrors rollupFields logic)
            Decimal sumResidual = 0;
            Decimal sumCost = 0;
            Decimal sumQuantity = 0;
            for (Asset__c a : [
                SELECT Residual_Amount__c, Cost__c, Quantity__c
                FROM Asset__c
                WHERE Opportunity__c = :opportunityId
            ]) {
                sumResidual += (a.Residual_Amount__c ?? 0);
                sumCost += (a.Cost__c ?? 0);
                sumQuantity += (a.Quantity__c ?? 0);
            }

            // 3. Enable ORE__c bypass to prevent validation rule interference
            oreSetting.Bypass__c = true;
            upsert oreSetting;

            // 4. Enable DeactivateTriggers__c bypass to prevent TC_OpportunityTrigger from firing
            if (dtOppExisted) {
                dtOppSetting.IsDeactived__c = true;
                update dtOppSetting;
            } else {
                dtOppSetting = new DeactivateTriggers__c(
                    Name = 'TC_OpportunityTrigger',
                    IsDeactived__c = true
                );
                insert dtOppSetting;
            }

            // 5. Enable DeactivateTriggers__c bypass to prevent PEAC_AssetTrigger from firing
            if (dtAssetExisted) {
                dtAssetSetting.IsDeactived__c = true;
                update dtAssetSetting;
            } else {
                dtAssetSetting = new DeactivateTriggers__c(
                    Name = 'PEAC_AssetTrigger',
                    IsDeactived__c = true
                );
                insert dtAssetSetting;
            }

            try {
                // 6. Update Opportunity fields
                opp.Residual__c = sumResidual;
                opp.Number_of_Units__c = sumQuantity;
                opp.Equipment_Cost__c = sumCost;
                opp.Gross_Finance__c = (opp.Gross_Contract__c ?? 0) - sumCost;

                update opp;
            } finally {
                // 7. Always restore PEAC_AssetTrigger bypass
                if (dtAssetExisted) {
                    dtAssetSetting.IsDeactived__c = originalDtAssetBypass;
                    update dtAssetSetting;
                } else {
                    delete dtAssetSetting;
                }

                // 8. Always restore TC_OpportunityTrigger bypass
                if (dtOppExisted) {
                    dtOppSetting.IsDeactived__c = originalDtOppBypass;
                    update dtOppSetting;
                } else {
                    delete dtOppSetting;
                }
            }
        } finally {
            // 9. Always restore ORE__c bypass (separate finally to guarantee execution)
            oreSetting.Bypass__c = originalOreBypass;
            upsert oreSetting;
        }
    }
}