/**
 * @description Service class for loading pricing configuration.
 *              Loads Programs, Rate Cards, Residuals, and Modifiers.
 * @author Northteq
 */
public without sharing class NT_PricingConfigService {
    
    /**
     * @description Loads all configuration for a pricing context
     * @param ctx The pricing context to populate
     * @return NT_PricingContext The populated context
     */
    public NT_PricingContext loadConfiguration(NT_PricingContext ctx) {
        // Load parent record data
        loadParentRecord(ctx);
        
        // Check for program
        loadProgram(ctx);
        
        // Load rate cards based on program or generic
        loadRateCards(ctx);
        
        // Load residuals
        loadResiduals(ctx);
        
        // Load modifiers for eligible rate cards
        loadModifiers(ctx);
        
        // Load TValue Template based on Purchase Option
        loadTValueTemplate(ctx);
        
        return ctx;
    }
    
    /**
     * @description Reloads configuration using generic rate cards (fallback when program rate cards fail).
     *              Clears existing rate cards and modifiers, loads generic ones.
     * @param ctx The pricing context
     * @return NT_PricingContext The updated context with generic rate cards
     */
    public NT_PricingContext loadGenericFallback(NT_PricingContext ctx) {
        ctx.eligibleRateCards = new List<RateCard__c>();
        ctx.eligibleModifiers = new List<Modifier__c>();
        loadGenericRateCards(ctx);
        loadModifiers(ctx);
        return ctx;
    }
    
    /**
     * @description Loads the parent record (Opportunity or Quote)
     * @param ctx The pricing context
     */
    private void loadParentRecord(NT_PricingContext ctx) {
        if (ctx.isOpportunity()) {
            ctx.opportunity = queryOpportunity(ctx.parentId);
            populateFromOpportunity(ctx);
        } else if (ctx.isQuote()) {
            ctx.quote = queryQuote(ctx.parentId);
            populateFromQuote(ctx);
        }
    }
    
    /**
     * @description Queries Opportunity with pricing-related fields
     * @param oppId The Opportunity Id
     * @return Opportunity The queried record
     */
    private Opportunity queryOpportunity(Id oppId) {
        return [
            SELECT Id, Name, AccountId, Amount, Equipment_Cost__c, 
                   Risk_Based_Pricing__c, Credit_Risk_Grade__c, Points__c,
                   Deferral_Payments__c, Lessor__c, Purchase_Options__c,
                   Terms__c, Funded_Amount__c, Payment_Amount__c, 
                   Payment_Frequency__c, Residual__c, Program_Lookup__c,
                   Pricing_Status__c,
                   (SELECT Id, Program__c FROM Quotes WHERE Program__c != null LIMIT 1)
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
    }
    
    /**
     * @description Queries Quote with pricing-related fields
     * @param quoteId The Quote Id
     * @return Quote The queried record
     */
    private Quote queryQuote(Id quoteId) {
        return [
            SELECT Id, Name, OpportunityId, Program__c, Term__c, Rate__c,
                   Total_Financed_Amount__c, Payment__c, Residual__c,
                   Advance_Payments__c, Points__c, Down_Payment__c, Buy_Down__c,
                   Requested_Payment_Frequency__c,
                   Payment_Frequency__c, End_of_Term_Option__c, Equipment_Type__c,
                   Requested_Term__c, Pricing_Term__c
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
    }
    
    /**
     * @description Populates context from Opportunity
     * @param ctx The pricing context
     */
    private void populateFromOpportunity(NT_PricingContext ctx) {
        Opportunity opp = ctx.opportunity;
        if (opp != null) {
            ctx.programId = opp.Program_Lookup__c;
            if (opp.Terms__c != null) {
                ctx.requestedTerms.add(opp.Terms__c);
            }
            ctx.financedAmount = opp.Equipment_Cost__c;
            ctx.equipmentCost = opp.Equipment_Cost__c;
            ctx.points = opp.Points__c;
            ctx.paymentFrequencies.add(opp.Payment_Frequency__c);
            ctx.endOfTermOption = opp.Purchase_Options__c;
            ctx.baseResidual = opp.Residual__c;
            
            // If no program on Opportunity, check if any Quote has one
            if (ctx.programId == null && opp.Quotes != null && !opp.Quotes.isEmpty()) {
                ctx.programId = opp.Quotes[0].Program__c;
            }
        }
    }
    
    /**
     * @description Populates context from Quote
     * @param ctx The pricing context
     */
    private void populateFromQuote(NT_PricingContext ctx) {
        Quote q = ctx.quote;
        if (q != null) {
            ctx.programId = q.Program__c;
            ctx.financedAmount = q.Total_Financed_Amount__c;
            ctx.points = q.Points__c;
            ctx.downPayment = q.Down_Payment__c;
            ctx.buyDown = q.Buy_Down__c;
            ctx.advancePayments = q.Advance_Payments__c;
            if (String.isBlank(q.Requested_Payment_Frequency__c)) {
                ctx.setError('Requested Payment Frequency is required on the Quote.');
                return;
            }
            ctx.paymentFrequencies = q.Requested_Payment_Frequency__c.split(';');
            ctx.endOfTermOption = q.End_of_Term_Option__c;
            ctx.equipmentType = q.Equipment_Type__c;
            ctx.baseResidual = q.Residual__c;
            
            // Parse Requested_Term__c multi-select picklist for multiple TValue quotes
            if (String.isNotBlank(q.Requested_Term__c)) {
                ctx.requestedTerms = new List<Decimal>();
                for (String termStr : q.Requested_Term__c.split(';')) {
                    try {
                        ctx.requestedTerms.add(Decimal.valueOf(termStr.trim()));
                    } catch (Exception e) {
                        System.debug('Invalid term value: ' + termStr);
                    }
                }
            }
            
        }
    }
    
    /**
     * @description Loads Program configuration if available
     * @param ctx The pricing context
     */
    private void loadProgram(NT_PricingContext ctx) {
        if (ctx.programId != null) {
            List<Program__c> programs = [
                SELECT Id, Name, Program_Code__c, Start_Date__c, End_Date__c,
                       Minimum_Term__c, Maximum_Term__c, Minimum_Financed_Amount__c,
                       Maximum_Financed_Amount__c, Channel__c, Industry__c
                FROM Program__c
                WHERE Id = :ctx.programId
                AND Start_Date__c <= TODAY
                AND (End_Date__c = null OR End_Date__c >= TODAY)
                LIMIT 1
            ];
            
            if (!programs.isEmpty()) {
                ctx.program = programs[0];
                ctx.hasProgram = true;
            }
        }
    }
    
    /**
     * @description Loads Rate Cards - either program-specific or generic
     * @param ctx The pricing context
     */
    private void loadRateCards(NT_PricingContext ctx) {
        if (ctx.hasProgram) {
            loadProgramRateCards(ctx);
            System.debug(ctx);
        } else {
            loadGenericRateCards(ctx);
        }
    }
    
    /**
     * TODO: Per SAL-6542 includes scenario where Program is used to determine Rate Cards, but this is not implemented on the UI side.
     * @description Loads Rate Cards associated with a Program
     * @param ctx The pricing context
     */
    private void loadProgramRateCards(NT_PricingContext ctx) {
        System.debug('loadProgramRateCards ctx: ' + ctx.programId);
        // Get Rate Card IDs from Program_Rate_Card__c junction
        List<Program_Rate_Card__c> programRateCards = [
            SELECT Id, Rate_Card__c, Rate_Card__r.Id, Rate_Card__r.Name,
                   Rate_Card__r.Rate_Card_Type__c, Rate_Card__r.Entry_Criteria__c,
                   Rate_Card__r.Quote_Entry_Config__c,
                   Rate_Card__r.Active__c, Rate_Card__r.Effective_Start_Date__c,
                   Rate_Card__r.Effective_End_Date__c, Rate_Card__r.Base_Rate__c
            FROM Program_Rate_Card__c
            WHERE Program__c = :ctx.programId
            AND Rate_Card__r.Active__c = true
            AND Rate_Card__r.Effective_Start_Date__c <= TODAY
            AND (Rate_Card__r.Effective_End_Date__c = null OR Rate_Card__r.Effective_End_Date__c >= TODAY)
        ];
        
        for (Program_Rate_Card__c prc : programRateCards) {
            ctx.eligibleRateCards.add(prc.Rate_Card__r);
        }
        System.debug('loadProgramRateCards ctx.eligibleRateCards: ' + ctx.eligibleRateCards);
    }
    
    /**
     * TODO: Need better understanding of generic rate cards criteria, currently just loading all active rate cards.
     * @description Loads generic Rate Cards (when no Program) 
     * @param ctx The pricing context
     */
    private void loadGenericRateCards(NT_PricingContext ctx) {
        ctx.eligibleRateCards = [
            SELECT Id, Name, Rate_Card_Type__c, Entry_Criteria__c, Quote_Entry_Config__c,
                   Active__c, Effective_Start_Date__c, Effective_End_Date__c, Base_Rate__c
            FROM RateCard__c
            WHERE Active__c = true
            AND Effective_Start_Date__c <= TODAY
            AND (Effective_End_Date__c = null OR Effective_End_Date__c >= TODAY)
        ];
    }
    
    /**
     * @description Loads Residual configuration.
     *              For program-based deals, loads Program_Residual__c records linked to the Program.
     *              For generic (no-program) deals, loads Program_Residual__c records with no Program.
     * @param ctx The pricing context
     */
    private void loadResiduals(NT_PricingContext ctx) {
        if (ctx.hasProgram) {
            ctx.programResiduals = [
                SELECT Id, Program__c, Residual_Balloon_Table__c,
                       Residual_Balloon_Table__r.Id, Residual_Balloon_Table__r.Name,
                       Residual_Balloon_Table__r.Rate_Card_Type__c,
                       Residual_Balloon_Table__r.Entry_Criteria__c
                FROM Program_Residual__c
                WHERE Program__c = :ctx.programId
                AND Residual_Balloon_Table__r.Active__c = true
                AND Residual_Balloon_Table__r.Effective_Start_Date__c <= TODAY
                AND (Residual_Balloon_Table__r.Effective_End_Date__c = null
                     OR Residual_Balloon_Table__r.Effective_End_Date__c >= TODAY)
            ];
        } else {
            // Generic residuals: Program_Residual__c records not tied to any Program
            ctx.programResiduals = [
                SELECT Id, Program__c, Residual_Balloon_Table__c,
                       Residual_Balloon_Table__r.Id, Residual_Balloon_Table__r.Name,
                       Residual_Balloon_Table__r.Rate_Card_Type__c,
                       Residual_Balloon_Table__r.Entry_Criteria__c
                FROM Program_Residual__c
                WHERE Program__c = null
                AND Residual_Balloon_Table__r.Active__c = true
                AND Residual_Balloon_Table__r.Effective_Start_Date__c <= TODAY
                AND (Residual_Balloon_Table__r.Effective_End_Date__c = null
                     OR Residual_Balloon_Table__r.Effective_End_Date__c >= TODAY)
            ];
        }
    }
    
    /**
     * @description Loads Modifiers for eligible Rate Cards
     * @param ctx The pricing context
     */
    private void loadModifiers(NT_PricingContext ctx) {
        if (ctx.eligibleRateCards.isEmpty()) {
            return;
        }
        
        Set<Id> rateCardIds = new Set<Id>();
        for (RateCard__c rc : ctx.eligibleRateCards) {
            rateCardIds.add(rc.Id);
        }
        
        ctx.eligibleModifiers = [
            SELECT Id, Name, Rate_Card__c, Residual_Balloon_Table__c,
                   Modifier_Table_Type__c, Modifier_Rate_Card__c,
                   Rate_Card__r.Entry_Criteria__c,
                   Rate_Card__r.Quote_Entry_Config__c,
                   Rate_Card__r.Rate_Card_Type__c,
                   Rate_Card__r.Base_Rate__c,
                   Residual_Balloon_Table__r.Residual_Balloon_Table__c,
                   Modifier_Rate_Card__r.Entry_Criteria__c,
                   Modifier_Rate_Card__r.Quote_Entry_Config__c,
                   Modifier_Rate_Card__r.Rate_Card_Type__c,
                   Modifier_Rate_Card__r.Base_Rate__c
            FROM Modifier__c
            WHERE Rate_Card__c IN :rateCardIds
        ];
    }
    
    // Lease Purchase Options → Lease template (per Jennifer Fanz, confirmed Feb 4 2026)
    private static final Set<String> LEASE_TEMPLATE_OPTIONS = new Set<String>{
        'FMV', '$1.00 Buyout', '1.00 Out', 'Put', 'Assigned Residual',
        'Guaranteed Residual', 'Assign Resid No Renewal', '26-Rental-No'
    };

    /**
     * @description Loads TValue Template based on Purchase Option.
     *              Lease template for FMV/1.00 Out/PUT/Residual options;
     *              EFA/IPA (Loan) template for Customer Owned.
     * @param ctx The pricing context
     */
    private void loadTValueTemplate(NT_PricingContext ctx) {
        System.debug('loadTValueTemplate ctx: ' + ctx.parentType);
        String purchaseOption = ctx.endOfTermOption;

        String templateName = LEASE_TEMPLATE_OPTIONS.contains(purchaseOption)
            ? 'Lease'
            : 'EFA/IPA';

        List<tval__TValue_Template__c> templates = [
            SELECT Id, tval__Template_Name__c
            FROM tval__TValue_Template__c
            WHERE tval__Template_Name__c = :templateName
            AND tval__Active__c = true 
            AND tval__Object_API_Name__c =: ctx.parentType
            LIMIT 1
        ];

        if (!templates.isEmpty()) {
            ctx.templateId = templates[0].Id;
        }
    }
}