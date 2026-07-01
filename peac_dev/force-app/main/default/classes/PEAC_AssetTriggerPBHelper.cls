/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to implement apex for the Process builders which were converted to Apex
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: Jan-07-2026
**************************************************************************************************************/
public class PEAC_AssetTriggerPBHelper {
	/************************************************************************************************************
	 * @Author:Rajesh Kumar(LTM)
	 * @Description: Reset the Asset fields for tax calculation
	 * @Param: List of Assets
	 * **********************************************************************************************************/
    
    public static void stateTaxCodeChanged(List<Asset__c> assets)
    {
        for(Asset__c oppAsset: assets)
        {
           resetTaxFields(oppAsset);
        }
    }
    /* Start: SAL-6445 - Vinod Rathod
     * Logic migrated from TC Asset: Sets Tax Code, Amt, & Percentages if 036, 060 And Set Tax Fields to Null Process Builder.
     */
    public static void setsTaxCodeAmtPercentages(List<Asset__c> assets, Boolean isNew){
        for(Asset__c asset : assets){
            
            //Tax Exempt Equipment = YES
            if(asset.Tax_Exempt_Equipment__c == 'Yes'){
                asset.City_Tax_Code__c = '036';
                asset.County_Tax_Code__c = '036';
                asset.Responsibility_Code__c = null;
                asset.State_Tax_Code__c = '036';
                asset.Tax_Date_Time__c = System.now();
                asset.Upfront_City_Tax_Amount__c = 0;
                asset.Upfront_City_Transit_Tax_Amount__c = 0;
                asset.Upfront_County_Tax_Amount__c = 0;
                asset.Upfront_County_Transit_Tax_Amount__c = 0;
                asset.Upfront_State_Tax_Amount__c = 0;
                asset.Upfront_Tax_Code__c = '036';
                asset.Upfront_Tax_Method__c = null;
                asset.Usage_User_Table__c = '3'; 
				asset.Responsibility_Code__c = Null;
                asset.Upfront_Responsibility_Code__c = Null;
				//asset.Federal_Method__c = '21';                
            }
            //Upfront Tax Vendor (State Tax Code = 050)
            if(asset.State_Tax_Code__c == '050'){
                asset.City_Tax_Amount__c = 0;
                asset.City_Tax_Code__c = '050';
                asset.City_Tax_Percentage__c = 0;
                asset.City_Transit_Tax_Amount__c = 0;
                asset.City_Transit_Tax_Percentage__c = 0;
                asset.County_Tax_Amount__c = 0;
                asset.County_Tax_Code__c = '050';
                asset.County_Tax_Percentage__c = 0;
                asset.County_Transit_Tax_Amount__c = 0;
                asset.County_Transit_Tax_Percentage__c = 0;
                asset.LC_City_Tax_Code__c = '050';
                asset.LC_County_Tax_Code__c = '050';
                asset.LC_State_Tax_Code__c = '050';
                asset.Misc_City_Tax_Code__c = '050';
                asset.Misc_County_Tax_Code__c = '050';
                asset.Misc_State_Tax_Code__c = '050';
                asset.Responsibility_Code__c = null;
                asset.State_Tax_Amount__c = 0;
                asset.State_Tax_Percentage__c = 0;
                asset.Tax_Date_Time__c = System.now();
                asset.Upfront_City_Tax_Amount__c = 0;
                asset.Upfront_City_Transit_Tax_Amount__c = 0;
                asset.Upfront_County_Tax_Amount__c = 0;
                asset.Upfront_County_Transit_Tax_Amount__c = 0;
                asset.Upfront_Responsibility_Code__c = null;
                asset.Upfront_State_Tax_Amount__c = 0;
                asset.Upfront_Tax_Code__c = '050';
                asset.Upfront_Tax_Method__c = null;
            }
            //Switched off tax exempt
            if(!isNew && asset.Tax_Exempt_Equipment__c == 'No' && asset.State_Tax_Code__c == '036'){
                resetTaxFields(asset);
            }
            //State Tax moved to 031
            if(!isNew && asset.State_Tax_Code__c == '031'){
                if (asset.LC_County_Tax_Code__c != null)
                    asset.LC_County_Tax_Code__c = '031';
                if (asset.LC_State_Tax_Code__c != null)
                    asset.LC_State_Tax_Code__c = '031';
                if (asset.LC_City_Tax_Code__c != null)
                    asset.LC_City_Tax_Code__c = '031';
            }
        }        
    }
        
    //Sets all tax fields to null when it needs to reset values
    private static void resetTaxFields(Asset__c a) {
        a.City_Tax_Amount__c = 0;
        a.City_Tax_Code__c = null;
        a.City_Tax_Percentage__c = 0;
        a.City_Transit_Tax_Amount__c = 0;
        a.City_Transit_Tax_Percentage__c = 0;
        a.County_Tax_Amount__c = 0;
        a.County_Tax_Code__c = null;
        a.County_Tax_Percentage__c = 0;
        a.County_Transit_Tax_Amount__c = 0;
        a.County_Transit_Tax_Percentage__c = 0;
        a.LC_City_Tax_Code__c = null;
        a.LC_County_Tax_Code__c = null;
        a.LC_State_Tax_Code__c = null;    
        a.Misc_City_Tax_Code__c = null;
        a.Misc_County_Tax_Code__c = null;
        a.Misc_State_Tax_Code__c = null;
        a.Misc_GST__c = 0;
        a.Responsibility_Code__c = null;
        a.State_Tax_Amount__c = 0;
        a.State_Tax_Code__c = null;
        a.State_Tax_Percentage__c = 0;   
        a.Upfront_City_Tax_Amount__c = 0;
        a.Upfront_City_Transit_Tax_Amount__c = 0;
        a.Upfront_County_Tax_Amount__c = 0;
        a.Upfront_County_Transit_Tax_Amount__c = 0;
        a.Upfront_Responsibility_Code__c = null;
        a.Upfront_State_Tax_Amount__c = 0;
        a.Upfront_Tax_Code__c = null;
        a.Upfront_Tax_Method__c = null;
        a.Usage_User_Table__c = null;
    }
    /* End:
     * Process Builder:TC Asset: Sets Tax Code, Amt, & Percentages if 036, 060 And Set Tax Fields to Null.
    /* END: SAL-6445 - Vinod Rathod */
    //SAL-6445 -Vinod Rathod
    //Logic migrated from Process Builder TC Asset -- Tax Exempt Certificate Requested
    public static void tCAssetTaxExemptCertificateRequested(List<Asset__c> assets){
        for(Asset__c asset : assets){
            asset.City_Tax_Code__c = asset.Misc_City_Tax_Code__c;
            asset.County_Tax_Code__c = asset.Misc_County_Tax_Code__c;
            asset.Financed_Trigger__c = false;
            asset.Responsibility_Code__c = null;
            asset.State_Tax_Code__c = asset.Misc_State_Tax_Code__c;
            asset.Upfront_City_Tax_Amount__c = null;
            asset.Upfront_City_Transit_Tax_Amount__c = null;
            asset.Upfront_County_Tax_Amount__c = null;
            asset.Upfront_County_Transit_Tax_Amount__c = null;
            asset.Upfront_State_Tax_Amount__c = null;
            asset.Upfront_Tax_Code__c = null;
            asset.Upfront_Tax_Method__c = null;
        }        
    }
    
    /* Start: SAL-6284 - Manish */
    /* Start:
     * Process Builder: TC Asset Booking Default – Tax Method & Responsibility Code
	 * Apex Trigger Implementation for TC Asset Booking Default – Tax Method & Responsibility Code
	*/

    public static void tcAssetBookingDefaultTaXMethodResponsibilityCode(List<Asset__c> assets){
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        for(Asset__c obj : assets){
            if(obj.Opportunity__c != Null){
                opportunityIds.add(obj.Opportunity__c);
            }
        }
        if(!opportunityIds.isEmpty()){
			opportunityMap = getOpportunityMapByIds(opportunityIds);
        }
        for(Asset__c asset : assets){
            // Null Tax Code Logic
            if(asset.Upfront_Tax_Code__c == null) {
                asset.Responsibility_Code__c = null;
                asset.Upfront_Responsibility_Code__c = null;
                asset.Upfront_Tax_Method__c = null;
                //return;
            }            
            // Responsibility Code Logic
            // Below code has been commented as this is overriding the logic for SAL-6445
            /*if(asset.Upfront_Tax_Code__c != null ) {
            	asset.Responsibility_Code__c = 'L';
               	asset.Upfront_Responsibility_Code__c = 'L'; 
            } */         
            // Tax Method Logic
            if(asset.Upfront_Tax_Code__c != null && asset.State_Tax_Code__c != '050' && asset.State_Tax_Code__c != '036'){
                //Added by Rajesh- Should be defaulted
                asset.Responsibility_Code__c = 'L';
                asset.Upfront_Responsibility_Code__c = 'L';
                if(isPPMState(asset)) {
                    asset.Upfront_Tax_Method__c = 'PPM';
                } else if(isGRMState(asset)) {
                    asset.Upfront_Tax_Method__c = 'GRM';
                }            
            // California Logic
            if(asset.Equipment_Location_State__c == 'CALIFORNIA' && asset.Opportunity__c != null && opportunityMap.containskey(asset.Opportunity__c)) {
                if(opportunityMap.get(asset.Opportunity__c).Purchase_Options__c == '1.00 Out') {
                    asset.Upfront_Tax_Method__c = 'PPM';
                } /*else if(opportunityMap.get(asset.Opportunity__c).Purchase_Options__c == '$101 Purchase Option') { // SAL-6284: $101 Purchase Option is inactive value, hence commenting code. Confirmed with business
                    asset.Upfront_Tax_Method__c = 'GRM';
                }*/
            }            
            // Maine Logic
            if(asset.Equipment_Location_State__c == 'MAINE' && asset.Opportunity__c != null && opportunityMap.containskey(asset.Opportunity__c)) {
                if(opportunityMap.get(asset.Opportunity__c).Purchase_Options__c == 'FMV') {
                    asset.Upfront_Tax_Method__c = 'PPM';
                } else if(opportunityMap.get(asset.Opportunity__c).Purchase_Options__c == '1.00 Out'
                          /* || opportunityMap.get(asset.Opportunity__c).Purchase_Options__c == '$101 Purchase Option'*/ ) { // SAL-6284: $101 Purchase Option is inactive value, hence commenting code. Confirmed with business
                  	asset.Upfront_Tax_Method__c = 'GRM';
                }
            }            
            }
            // Reset Trigger Asset Recalc
            /*if(asset.Trigger_Asset_PB__c == true) {
            asset.Trigger_Asset_PB__c = false;
            }*/
        }        
    }
	@TestVisible
    private static Boolean isCaliforniaOrMaine(String state) {
        return state == 'CALIFORNIA' || state == 'MAINE';
    }

    private static Boolean isPPMState(Asset__c asset) {
        List<String> ppmStates = new List<String>{'ALABAMA','IDAHO','ILLINOIS','NEVADA','TENNESSEE'};
        return ppmStates.contains(asset.Equipment_Location_State__c);
    }

    private static Boolean isGRMState(Asset__c asset) {
        List<String> grmStates = new List<String>{
            'DISTRICT OF COLUMBIA','FLORIDA','GEORGIA','HAWAII','INDIANA','IOWA','KANSAS','KENTUCKY',
                'LOUISIANA','MASSACHUSETTS','MICHIGAN','MINNESOTA','NEBRASKA','NEW JERSEY','NEW MEXICO',
                'NORTH CAROLINA','NORTH DAKOTA','OHIO','OKLAHOMA','RHODE ISLAND','SOUTH DAKOTA','TEXAS',
                'UTAH','VERMONT','WISCONSIN','WASHINGTON','WEST VIRGINIA'
                };
        return grmStates.contains(asset.Equipment_Location_State__c);
    }

    private static Map<Id, Opportunity> getOpportunityMapByIds(Set<Id> ids) {
        return new Map<Id, Opportunity>(
            [SELECT Id, Purchase_Options__c FROM Opportunity WHERE Id IN :ids]
        );
    }
    /* End:
     * Process Builder: TC Asset Booking Default – Tax Method & Responsibility Code
	 * Apex Trigger Implementation for TC Asset Booking Default – Tax Method & Responsibility Code
	*/
	/* END: SAL-6284 - Manish */
}