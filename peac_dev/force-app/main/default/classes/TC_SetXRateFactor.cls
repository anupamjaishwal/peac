public class TC_SetXRateFactor {
public static void setXRateFactor (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
    //START: SAL-7237
    Set<String> allowedStagesForXRateFactorCalculation = new Set<String>{PEAC_ConstantClass.OPPORTUNITY_STATUS_DOCS_IN,
        PEAC_ConstantClass.OPPORTUNITY_STATUS_DOCS_OUT,PEAC_ConstantClass.OPPORTUNITY_STATUS_DOCS_REQUESTED };
    //END: SAL-7237
        for (Opportunity opp : newMap.values ()) {

            // TODO SAL-2884 removed from 3.4 release - uncomment this when 2884 is in current release
            if (opp.EF_Approved_Offers__c != null 
                && oldMap.get (opp.Id).EF_Approved_Offers__c != opp.EF_Approved_Offers__c) 
            {
                // SAL-2884 When Offer is selected then update rate 
               opp.X_Rate_Factor__c = opp.Offer_Rate_Factor__c;

            } else 
            
            if (!opp.Override_XRate_Factor__c &&
                ( oldMap.get (opp.Id).StageName != opp.StageName
                    && opp.StageName == 'Docs In'
                    //&& oldMap.get(opp.Id).X_Rate_Factor__c == null
                )
                ||
                (
                    oldMap.get (opp.Id).Payment_Amount__c != opp.Payment_Amount__c
                    && oldMap.get(opp.Id).X_Rate_Factor__c == opp.X_Rate_Factor__c
                    && oldMap.get (opp.Id).Equipment_Cost__c == opp.Equipment_Cost__c
                    && opp.Probability.round() >= 90 
                )
            ) {
                opp.X_Rate_Factor__c = opp.Equipment_Cost__c != null && opp.Equipment_Cost__c != 0 && opp.Payment_Amount__c != null ? opp.Payment_Amount__c/opp.Equipment_Cost__c : 0;
            
            } else if (opp.Probability < 90 && opp.EF_Approved_Offers__c == null ) {
                opp.X_Rate_Factor__c = null;
            }
            if(opp.X_Rate_Factor__c != null){
                opp.X_Rate_Factor__c = opp.X_Rate_Factor__c.setscale(10);
            }
        }
    }

        /**
        * Method Name : setForXRateManualOverrideFlag
        * Description:
        *  This method is responsible for automatically setting the
        *  Override_XRate_Factor__c flag on Opportunity records during update operations.
        *
        *  The method evaluates specific business conditions to determine whether
        *  a manual override of the X Rate Factor has been performed and should
        *  be explicitly marked.
        *
        *  The logic ensures that overrides are only allowed for authorized users
        *  whose Profile Ids are configured via Custom Metadata.
        *
        *  Business Rules:
        *   - The Opportunity Stage must remain unchanged.
        *   - The X_Rate_Factor__c field must be modified.
        *   - The Stage must be one of the following values:
        *       • Docs In
        *       • Docs Out
        *       • Docs Requested
        *   - The logged-in user's Profile Id must be from selected profiels
        *
        *  Design Considerations:
        *   - Bulk-safe: Processes multiple Opportunity records efficiently.
        *   - Avoids redundant map lookups by caching old record reference.
        *   - Designed for use in BEFORE UPDATE triggers.
        *
        * Parameters:
        *   oldMap → Map of Opportunity records before update (Trigger.oldMap)
        *   newMap → Map of Opportunity records after update (Trigger.newMap)
        *
        * Usage:
        *   Call from Opportunity BEFORE UPDATE trigger handler:
        *
        * Author       : Manish Suwalka
        * Created Date : (Add your date)
        */
    
    public static void setForXRateManualOverrideFlag(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap){
        
        Set<String> allowedProfileName = new Set<String>{
            PEAC_ConstantClass.PROFILE_NAME_BOOKING,
                PEAC_ConstantClass.PROFILE_NAME_CMS,
                PEAC_ConstantClass.PROFILE_NAME_DATAADMIN,
                PEAC_ConstantClass.PROFILE_NAME_PARTNER_AMBASSADOR,
                PEAC_ConstantClass.PROFILE_NAME_SYSTEM_ADMINISTRATOR,
                PEAC_ConstantClass.PROFILE_NAME_SERVICES_ADMIN
                };
                    
                    for (Opportunity opp : newMap.values()) {
                        Opportunity oldOpp = oldMap.get(opp.Id);
                        String opportunityCurrentUserProfile = opp.Opportunity_CurrentUser_Profile__c;
                        
                        if ((opp.Override_XRate_Factor__c == false || opp.Override_XRate_Factor__c == null) &&
                            allowedProfileName.contains(opportunityCurrentUserProfile) &&
                            oldOpp.StageName == opp.StageName &&
                            oldOpp.X_Rate_Factor__c != opp.X_Rate_Factor__c &&
                            opp.Originating_Business__c == PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC &&
                            (
                                opp.StageName == 'Docs In' ||
                                opp.StageName == 'Docs Out' ||
                                opp.StageName == 'Docs Requested'
                            )
                           ) {
                               opp.Override_XRate_Factor__c = true;
                           }
                    }
    }
}