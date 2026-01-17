public class TC_RecursiveTriggerHelper {
    // TC_AssetTriggerHelper
    public static Boolean setOpportunityTaxStateRan = false;
    public static Boolean calculateAssetRentalAmount = false;
    //OpportunityTriggerHandler
    public static Boolean oppAfterTrigger = false;
    public static Boolean oppBeforeTrigger = false;
    public static Boolean oppAfterTriggerAddFranchisor = false;
    public static Boolean triggerOnBaseAPI = false;
    public static Boolean oppAlreadyShared = false;
    public static List<Id> oppsAlreadyTaxMatrixRan = new List<Id>();
    public static List<Id> oppsAlreadyMiiAdded = new List<Id>();
    public static List<Id> oppsAlreadyBiiAdded = new List<Id>();
    public static List<Id> oppsAlreadyEmailAlerted = new List<Id>();
    public static List<Id> oppsAlreadyRescoredOver = new List<Id>();
    public static Boolean isToTrackUser = true;
    // assetTriggerHandler
    public static Boolean populateEquipmentAddress = false;
    public static Boolean copyOptyDescAndCostToAsset = false;
    public static Boolean populateAssetInfoOnOpp = false;
    public static Boolean populateOwnerOpportunity = false;
    
    // email notifications
    public static Boolean sentApprovedEmail = false;
    public static Boolean sentSubmittedEmail = false;
    
    public static Boolean sendLoanNotifications = false;

    public static Boolean updateChildAccountsOfDealerBefore = false;
    public static Boolean updateChildAccountsOfDealerAfter = false;
    
    public static Boolean avoidUpdateChildDealerRecursion = false;


    public static Boolean createApprovedOffers = false;

    //commented by Raja
   // public static Boolean simpleComplexRuleEvaluator = false;

    public static Boolean cdrRules = false;


    public static Boolean rollUpCalculations =false;
    // SL_EmailMessageTriggerHandler
    public static List<Id> emailsAlreadyRoutingProcessed = new List<Id>();
    public static List<Id> casesAlreadyInitialResponseTime = new List<Id>();

}