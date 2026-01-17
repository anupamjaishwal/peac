/**
 * Created by andrewmayer on 9/15/20.
 * Actually calculates rate factor
 * can be called by after opportunity trigger or before ef approved offer
 */
//Deferral_Payments__c
public with sharing class TC_EfOfferRateFactorCalculator {
  private static String FMV_VALUE = 'FMV';
  public static List <EF_Approved_Offers__c> calculate(List <EF_Approved_Offers__c> efs, Map <Id, Opportunity> relatedOpp) {
    //=(1+21.75/12)^1*(21.75%/12)/(1-(1+(21.75/12))^-24)
    // =(1+yield/12)^Deferral*(yield/12)/(1-(1+(yield/12))^-term)
    List<EF_Approved_Offers__c> lstEfsUpdated = new List<EF_Approved_Offers__c>();
    for (EF_Approved_Offers__c ef : efs) {
      Boolean IS_PORTAL_APP = TC_CreateApprovedOffers.isPortalOpp(relatedOpp.get(ef.Opportunity__c));
      if(relatedOpp.get(ef.Opportunity__c).Purchase_Options__c == FMV_VALUE && IS_PORTAL_APP){
        CONTINUE;
      }

      // both yield and term are required. Deferral can be 0
      if (ef.Yield__c != null && ef.Yield__c != 0 && ef.Term_in_Months__c != null && ef.Term_in_Months__c != 0) {
        Double yield = ef.Yield__c.doubleValue()/100;
        Double term = ef.Term_in_Months__c.doubleValue();

        // SAL-2884 If Advance Rental is selected, a revised rate factor should be calculated for the Opportunity
        if (ef.Advanced_Rental__c=='First Payment') {
            term--;
        } else if (ef.Advanced_Rental__c=='First & Last Payment') {
          term = term - 2;
        }

        Double deferral = relatedOpp.get(ef.Opportunity__c).Deferral_Payments__c != null ? deferralMapping.get (relatedOpp.get(ef.Opportunity__c).Deferral_Payments__c) : 0;
        //Double rateFactor = Math.pow((1+yield/12),deferral)*(yield/12)/(1-Math.pow((1+(yield/12)),-term));
        //DP-214
        Double rateFactor = 0;
        if(relatedOpp.get(ef.Opportunity__c).Required_Adv_Payments__c == 1 && IS_PORTAL_APP){
          rateFactor = Math.abs(
                        ((yield / 12) * (-1 / (1 + (yield / 12)) * (Math.pow(1 + (yield / 12), term))))
                        / (Math.pow(1 + (yield / 12), term) -1)
                      );
        }else{
          rateFactor = Math.pow((1+yield/12),deferral)*(yield/12)/(1-Math.pow((1+(yield/12)),-term));
        }

        ef.Rate_Factor__c = Decimal.valueOf(rateFactor).setScale(6);
      } else {
        ef.Rate_Factor__c = 0;
      }

      lstEfsUpdated.add(ef);
    }
    system.debug('lstEfsUpdated ' + lstEfsUpdated);
    return lstEfsUpdated;
  }

  public static Map <String, Double> deferralMapping = new Map <String, Double> {'30 days' => 1, '60 days' => 2, '90 days' => 3};

  //DP-80 new method to Calculate the Rate using the Residual for FMV.
  public static List<EF_Approved_Offers__c> calculateFMV(List<EF_Approved_Offers__c> efs, Map <Id, Opportunity> relatedOpp) {
    List<EF_Approved_Offers__c> lstEfsUpdated = new List<EF_Approved_Offers__c>();
    for (EF_Approved_Offers__c ef : efs) {
      Boolean IS_PORTAL_APP = TC_CreateApprovedOffers.isPortalOpp(relatedOpp.get(ef.Opportunity__c));
      //FMV is only needed for Portal Apps so if the current opp is not a portal app we are going to the next record in the list. DP-214
      if(!IS_PORTAL_APP || relatedOpp.get(ef.Opportunity__c).Purchase_Options__c != FMV_VALUE ){
        CONTINUE;
      }
      // both yield and term are required.
      if (ef.Yield__c != null && ef.Yield__c != 0 && ef.Term_in_Months__c != null && ef.Term_in_Months__c != 0) {
        Double yield = ef.Yield__c.doubleValue()/100;
        Double term = ef.Term_in_Months__c.doubleValue();
        Double residual = ef.Residual__c == null ? 0 : ef.Residual__c.doubleValue()/100;
        if (ef.Advanced_Rental__c=='First Payment') {
          term--;
        } else if (ef.Advanced_Rental__c=='First & Last Payment') {
          term = term - 2;
        }
        //Double rateFactor = Math.abs( ( (yield /12) * (-1 * (1 + Math.pow((yield/12),term)) + residual  ) ) / ( Math.pow((1 + yield / 12), term) -1 ));
        //DP-214
        Double rateFactor = 0;
        if(relatedOpp.get(ef.Opportunity__c).Required_Adv_Payments__c == 1){
          rateFactor = Math.abs( 
                        ( (yield /12) * ( (-1 / (1 + (yield/12))) * (Math.pow(1 + (yield/12),term)) + (residual * ( 1 - (yield/12)) )  ) )
                        / ( Math.pow(1 + (yield / 12), term) -1 )
                      );
        }else{
          rateFactor = Math.abs( 
                        ( (yield /12) * (-1 * (Math.pow(1 + (yield/12),term)) + residual ) ) 
                        / ( Math.pow(1 + (yield / 12), term) -1 )
                      );
        }
        ef.Rate_Factor__c = Decimal.valueOf(rateFactor).setScale(6);

      } else {
        ef.Rate_Factor__c = 0;
      }
      lstEfsUpdated.add(ef);
    }
    return lstEfsUpdated;
  }
}