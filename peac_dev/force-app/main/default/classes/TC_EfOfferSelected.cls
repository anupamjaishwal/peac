// /**
//  * Created by andrewmayer on 9/15/20.
//  * If ef approved offer is selected, begin the process to see if user
//  * has the authority to do so
//  *
//  * Thinking this code has too much in it, might split it up
//  */

// public with sharing class TC_EfOfferSelected implements TC_TriggerActionI{

//     public static final Id SYSTEM_GEN_RT = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId();

//     public void doAction(TC_TriggerContext tc) {
//         system.debug('1025 - 0');

//         Map <Id, EF_Approved_Offers__c> oldMap = (Map <Id, EF_Approved_Offers__c>) tc.getOldMap ();
//         List <EF_Approved_Offers__c> newList = (List <EF_Approved_Offers__c>) tc.getNewList ();

//         Map <Id, EF_Approved_Offers__c> selected = new Map <Id, EF_Approved_Offers__c> ();
//         Set <Id> oppIds = new Set <Id> ();
//         Map <Id, EF_Approved_Offers__c> approvalProcessValidation = new Map <Id,EF_Approved_Offers__c> ();


//         for (EF_Approved_Offers__c offer : newList) {

//             if (offer.Is_Selected_Offer__c && (oldmap == null || !oldMap.get (offer.Id).Is_Selected_Offer__c)) {
//                 selected.put (offer.Id, offer);
//                 oppIds.add (offer.Opportunity__c);
//             } else if (offer.Offer_Selected__c == 'Exception Approved' && oldMap.get (offer.Id).Offer_Selected__c == 'Pending Exception Approval'){
//                 selected.put (offer.Id, offer);
//                 oppIds.add (offer.Opportunity__c);
//                 approvalProcessValidation.put (offer.Id, offer);

//             }
//         }
// 		System.debug ('@@@@!@ selected' + selected);
//         if (selected.isEmpty()) return;
        

//         List <EF_Approved_Offers__c> deSelctList = new List <EF_Approved_Offers__c> ();
//         for (EF_Approved_Offers__c offer : [SELECT Id, Is_Selected_Offer__c FROM EF_Approved_Offers__c WHERE Id NOT IN :selected.keySet() AND Opportunity__c IN :oppIds AND Is_Selected_Offer__c = TRUE]) {
//             deSelctList.add (new EF_Approved_Offers__c (Id = offer.Id, Is_Selected_Offer__c = false));
//         }
//         if (!deSelctList.isEmpty()) update deselctList;

//         Map <String, EF_Approved_Offers__c> systemOffers = new Map <String,EF_Approved_Offers__c> ();
//         for (EF_Approved_Offers__c offer : [SELECT Id, Term_in_Months__c,Yield__c, Opportunity__c FROM EF_Approved_Offers__c WHERE Opportunity__c IN :oppIds AND RecordTypeId = :SYSTEM_GEN_RT]) {
//             systemOffers.put (efKey (offer), offer);
//         }
// 		Offers_Pricing_Authority__c userAuth = Offers_Pricing_Authority__c.getInstance (UserInfo.getUserId());
//         System.debug('1025: userAuth - '+ userAuth);
    

//         // todo: strategy pattern would be good for this
//         system.debug('1025 - 0');
//         for (EF_Approved_Offers__c offer : selected.values ()) {
            
//             /* 
//                 Concession amount calculation: 
//                 Offer_Yield < System_Yield - (Rate_Concession * System_Yield) / 100 

//                 Example 1: 
//                 Sales Rep is quoting a 60 month EF deal.  The RBP Matrix provides a rate of 6.15%
//                 Sales Rep: 
//                     6.15% x 3.00% = 0.18% lower quote NOT allowed by Rep as it violates the minimum.  A max 0.16% lower is allowed (~5.99% Yield)

//                 Manager/Leader: 
//                     6.15% x 9.00% = 0.55% lower quote allowed by Leader (~5.60% Yield)
//             */
//             //Boolean yieldBelowAllowedConcession = userAuth.RBP_Rate_Concession__c * offer.Yield__c < systemOffers.get (efKey (offer)).Yield__c;
//             // System.debug('1025: userAuth.RBP_Rate_Concession__c - '+ userAuth.RBP_Rate_Concession__c);
//             // System.debug('1025: offer.Yield__c - '+ offer.Yield__c);
//             // System.debug('1025: systemOffers.get(efKey (offer)).Yield__c - '+ systemOffers.get (efKey (offer)).Yield__c);

//             if(!systemOffers.containsKey(efKey (offer))){
//               systemOffers.put (efKey (offer), offer);
//             }
           
//             Double systemYield = systemOffers.get (efKey (offer)).Yield__c;
			
//             Boolean yieldBelowAllowedConcession = offer.Yield__c <  systemYield - (userAuth.RBP_Rate_Concession__c * systemYield) / 100;
//             System.debug('1025: yieldBelowAllowedConcession - '+ yieldBelowAllowedConcession);


//             if (offer.Term_in_Months__c >= 60) {
//                 if (userAuth.Minimum_Yield_60_months__c > offer.Yield__c || yieldBelowAllowedConcession) {
//                     handleInsufficientAuthority (offer, approvalProcessValidation);
//                     system.debug('1025 - 1');
//                 } else if (approvalProcessValidation.isEmpty ()) {
//                     selectIt (offer);
//                     system.debug('1025 - 2');
//                 }
//             } else if (offer.Term_in_Months__c <60 && offer.Term_in_Months__c>= 36) {
//                 if (userAuth.Minimum_Yield_36_59_months__c > offer.Yield__c || yieldBelowAllowedConcession) {
//                     handleInsufficientAuthority (offer, approvalProcessValidation);
//                     system.debug('1025 - 3');
//                 } else if (approvalProcessValidation.isEmpty ()) {
//                     selectIt (offer);
//                     system.debug('1025 - 4');
//                 }
//             } else if (offer.Term_in_Months__c <36 && offer.Term_in_Months__c>= 12) {

//                 if (userAuth.Minimum_Yield_12_35_months__c > offer.Yield__c || yieldBelowAllowedConcession) {
//                     handleInsufficientAuthority (offer, approvalProcessValidation);
//                     system.debug('1025 - 5');
//                 } else if (approvalProcessValidation.isEmpty ()) {
//                     selectIt (offer);
//                     system.debug('1025 - 6');
//                 }
//             } else {
//                 // too small of a term
//                 offer.addError ('Term ' + offer.Term_in_Months__c + ' must be 12 or greater');
//             }

//         }
//     }

//     private String efKey (EF_Approved_Offers__c offer) {
//         return offer.Opportunity__c + '-' + offer.Term_in_Months__c;
//     }

//     private void handleInsufficientAuthority (EF_Approved_Offers__c offer, Map <Id, EF_Approved_Offers__c> approvalProcessValidation) {
//         if (approvalProcessValidation != null && approvalProcessValidation.get (offer.Id) != null) {
//             offer.addError('Approver doesn\'t have authority');
//         } else {
//             offer.Offer_Selected__c = 'Pending Exception Approval';
//         }
//     }

//     private void selectIt (EF_Approved_Offers__c offer) {
//         offer.Offer_Selected__c = 'Selected';
//     }
// }

/**
 * Created by andrewmayer on 9/15/20.
 * If ef approved offer is selected, begin the process to see if user
 * has the authority to do so
 *
 * Thinking this code has too much in it, might split it up
 */

public with sharing class TC_EfOfferSelected implements TC_TriggerActionI{

    public static final Id SYSTEM_GEN_RT = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId();

    public void doAction(TC_TriggerContext tc) {
        system.debug('1025 - 0');

        Map <Id, EF_Approved_Offers__c> oldMap = (Map <Id, EF_Approved_Offers__c>) tc.getOldMap ();
        List <EF_Approved_Offers__c> newList = (List <EF_Approved_Offers__c>) tc.getNewList ();

        Map <Id, EF_Approved_Offers__c> selected = new Map <Id, EF_Approved_Offers__c> ();
        Set <Id> oppIds = new Set <Id> ();
        Map <Id, EF_Approved_Offers__c> approvalProcessValidation = new Map <Id,EF_Approved_Offers__c> ();


        for (EF_Approved_Offers__c offer : newList) {

            if (offer.Is_Selected_Offer__c && (oldmap == null || !oldMap.get (offer.Id).Is_Selected_Offer__c)) {
                selected.put (offer.Id, offer);
                oppIds.add (offer.Opportunity__c);
            } else if (offer.Offer_Selected__c == 'Exception Approved' && oldMap.get (offer.Id).Offer_Selected__c == 'Pending Exception Approval'){
                selected.put (offer.Id, offer);
                oppIds.add (offer.Opportunity__c);
                approvalProcessValidation.put (offer.Id, offer);
            }
        }
        System.debug ('@@@@!@ selected' + selected);
        if (selected.isEmpty()) return;
        

        List <EF_Approved_Offers__c> deSelctList = new List <EF_Approved_Offers__c> ();
        for (EF_Approved_Offers__c offer : [SELECT Id, Is_Selected_Offer__c FROM EF_Approved_Offers__c WHERE Id NOT IN :selected.keySet() AND Opportunity__c IN :oppIds AND Is_Selected_Offer__c = TRUE]) {
            deSelctList.add (new EF_Approved_Offers__c (Id = offer.Id, Is_Selected_Offer__c = false));
        }
        if (!deSelctList.isEmpty()) update deselctList;

        Map <String, EF_Approved_Offers__c> systemOffers = new Map <String,EF_Approved_Offers__c> ();
        for (EF_Approved_Offers__c offer : [SELECT Id, Term_in_Months__c,Yield__c, Opportunity__c FROM EF_Approved_Offers__c WHERE Opportunity__c IN :oppIds AND RecordTypeId = :SYSTEM_GEN_RT]) {
            systemOffers.put (efKey (offer), offer);
        }

        // Query Opportunity->Program to get Max_Points_Percent__c for each Opp in scope
        Map <Id, Decimal> oppMaxPointsMap = new Map <Id, Decimal> ();
        for (Opportunity opp : [SELECT Id, Program_Lookup__r.Max_Points_Percent__c FROM Opportunity WHERE Id IN :oppIds]) {
            oppMaxPointsMap.put (opp.Id, opp.Program_Lookup__r.Max_Points_Percent__c);
        }

        Offers_Pricing_Authority__c userAuth = Offers_Pricing_Authority__c.getInstance (UserInfo.getUserId());
        System.debug('1025: userAuth - '+ userAuth);

        if (userAuth == null) {
            for (EF_Approved_Offers__c offer : selected.values ()) {
                offer.addError ('No pricing authority record found for your user. Please contact your administrator.');
            }
            return;
        }
    

        // todo: strategy pattern would be good for this
        system.debug('1025 - 0');

        // Collect offers that need to be submitted to the Points Exception approval process
        // after DML (approval submissions must happen after the trigger's DML completes)
        List <Id> pendingPointsExceptionIds = new List <Id> ();

        for (EF_Approved_Offers__c offer : selected.values ()) {
            
            /* 
                Concession amount calculation: 
                Offer_Yield < System_Yield - (Rate_Concession * System_Yield) / 100 

                Example 1: 
                Sales Rep is quoting a 60 month EF deal.  The RBP Matrix provides a rate of 6.15%
                Sales Rep: 
                    6.15% x 3.00% = 0.18% lower quote NOT allowed by Rep as it violates the minimum.  A max 0.16% lower is allowed (~5.99% Yield)

                Manager/Leader: 
                    6.15% x 9.00% = 0.55% lower quote allowed by Leader (~5.60% Yield)
            */

            if(!systemOffers.containsKey(efKey (offer))){
              systemOffers.put (efKey (offer), offer);
            }
           
            Double systemYield = systemOffers.get (efKey (offer))?.Yield__c;
            Boolean yieldBelowAllowedConcession = false;
            if (systemYield != null && userAuth.RBP_Rate_Concession__c != null && offer.Yield__c != null) {
                yieldBelowAllowedConcession = offer.Yield__c < systemYield - (userAuth.RBP_Rate_Concession__c * systemYield) / 100;
            }
            System.debug('1025: yieldBelowAllowedConcession - '+ yieldBelowAllowedConcession);

            // ── Points limit check ──────────────────────────────────────────────
            // Only evaluate when the offer isn't already being routed for a yield/residual exception.
            // If a points limit exists and the offer's points exceed it, route to Points Exception approval.
            Decimal maxPoints = oppMaxPointsMap.get (offer.Opportunity__c);
            Boolean pointsOverLimit = maxPoints != null && offer.Points__c != null && offer.Points__c > maxPoints;

            if (pointsOverLimit && !approvalProcessValidation.containsKey (offer.Id)) {
                offer.Offer_Selected__c = 'Pending Points Exception';
                pendingPointsExceptionIds.add (offer.Id);
                System.debug('1025 - points over limit, routing to Points Exception approval. Offer Points: ' + offer.Points__c + ', Max: ' + maxPoints);
                continue; // skip yield/term checks for this offer — points exception takes precedence
            }
            // ────────────────────────────────────────────────────────────────────

            if (offer.Term_in_Months__c >= 60) {
                if (userAuth.Minimum_Yield_60_months__c > offer.Yield__c || yieldBelowAllowedConcession) {
                    handleInsufficientAuthority (offer, approvalProcessValidation);
                    system.debug('1025 - 1');
                } else if (approvalProcessValidation.isEmpty ()) {
                    selectIt (offer);
                    system.debug('1025 - 2');
                }
            } else if (offer.Term_in_Months__c <60 && offer.Term_in_Months__c>= 36) {
                if (userAuth.Minimum_Yield_36_59_months__c > offer.Yield__c || yieldBelowAllowedConcession) {
                    handleInsufficientAuthority (offer, approvalProcessValidation);
                    system.debug('1025 - 3');
                } else if (approvalProcessValidation.isEmpty ()) {
                    selectIt (offer);
                    system.debug('1025 - 4');
                }
            } else if (offer.Term_in_Months__c <36 && offer.Term_in_Months__c>= 12) {

                if (userAuth.Minimum_Yield_12_35_months__c > offer.Yield__c || yieldBelowAllowedConcession) {
                    handleInsufficientAuthority (offer, approvalProcessValidation);
                    system.debug('1025 - 5');
                } else if (approvalProcessValidation.isEmpty ()) {
                    selectIt (offer);
                    system.debug('1025 - 6');
                }
            } else {
                // too small of a term
                offer.addError ('Term ' + offer.Term_in_Months__c + ' must be 12 or greater');
            }

        }

        // Submit points exception approvals after all in-memory field changes are done.
        // Approval.process() calls must happen in the same transaction but after field stamps above.
        if (!pendingPointsExceptionIds.isEmpty()) {
            submitPointsExceptionApprovals (pendingPointsExceptionIds, oppMaxPointsMap, selected);
        }
    }

    /**
     * Programmatically submits each offer to the Points_Exception approval process.
     * Comments include actual vs limit values for approver context.
     */
    private void submitPointsExceptionApprovals (
            List <Id> offerIds,
            Map <Id, Decimal> oppMaxPointsMap,
            Map <Id, EF_Approved_Offers__c> selectedOffers) {

        List <Approval.ProcessSubmitRequest> requests = new List <Approval.ProcessSubmitRequest> ();

        for (Id offerId : offerIds) {
            EF_Approved_Offers__c offer = selectedOffers.get (offerId);
            Decimal maxPoints = oppMaxPointsMap.get (offer.Opportunity__c);

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest ();
            req.setObjectId (offerId);
            req.setProcessDefinitionNameOrId ('Points_Exception');
            req.setSkipEntryCriteria (true);
            req.setComments (
                'Points Exception Required: Offer points (' + offer.Points__c +
                '%) exceed the Program limit (' + maxPoints + '%). ' +
                'Submitted automatically on offer selection.'
            );
            requests.add (req);
        }

        if (!requests.isEmpty()) {
            List <Approval.ProcessResult> results = Approval.process (requests, false); // false = do not throw on first error
            for (Approval.ProcessResult result : results) {
                if (!result.isSuccess()) {
                    // Surface approval submission errors back onto the triggering offer record
                    // so the user sees a meaningful message rather than a silent failure.
                    Id failedId = result.getEntityId ();
                    if (selectedOffers.containsKey (failedId)) {
                        selectedOffers.get (failedId).addError (
                            'Unable to submit Points Exception approval: ' +
                            (result.getErrors ().isEmpty () ? 'Unknown error' : result.getErrors ()[0].getMessage ())
                        );
                    }
                }
            }
        }
    }

    private String efKey (EF_Approved_Offers__c offer) {
        return offer.Opportunity__c + '-' + offer.Term_in_Months__c;
    }

    private void handleInsufficientAuthority (EF_Approved_Offers__c offer, Map <Id, EF_Approved_Offers__c> approvalProcessValidation) {
        if (approvalProcessValidation != null && approvalProcessValidation.get (offer.Id) != null) {
            offer.addError('Approver doesn\'t have authority');
        } else {
            offer.Offer_Selected__c = 'Pending Exception Approval';
        }
    }

    private void selectIt (EF_Approved_Offers__c offer) {
        offer.Offer_Selected__c = 'Selected';
    }
}