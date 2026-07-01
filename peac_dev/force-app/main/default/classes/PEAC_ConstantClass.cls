/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is used to declare constant variables and use these variables in actual classes
@User Story:SAL-5019
@Created Date:July-21-2024   
**************************************************************************************************************/
public class PEAC_ConstantClass {
    public static final string PRIMARY_CONTACT = System.label.Primary_Contact;
    public static final string NULL_VALUE = null;
    public static final string QUEUE = 'queue';
    public static final string FIXED = 'Fixed';
    public static final string DOT = '.';
    public static final string PERCENTAGE = '%';
    public static final string MANUFACTURER = 'M';
    public static final string DOT_SPLIT = '\\.';
    public static final string EMPTY = '';
    public static final string ZEROS = '0';
    public static final string HYPHEN = '-';
    public static final Integer MANUFATURER_FIRST_NUMBER = 6;
    public static final Integer MANUFATURER_LAST_NUMBER = 4;
    public static final String ID = 'id';
    public static final String OTHER = 'Other';
    public static final String MANUAL = 'Manual';
    public static final String PARTNER_COMMUNITY = 'Partner Community';
    public static final String CUSTOMER_COMMUNITY = 'Customer Community';
    public static final String READ_ACCESS = 'Read';
    public static final Id  END_ACCOUNT_RECORDTYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('End_User').getRecordTypeId(); 
    public static final Id  FRANCHISEE_ACCOUNT_RECORDTYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Franchisee').getRecordTypeId(); 
    public static Map<String,String> actionCallTypeMap = new Map<String,String> {
                                                            Label.PEAC_Rescore => 'RS',
                                                            Label.PEAC_Portal_Loan_APP => 'LP',
                                                            Label.PEAC_Initial_Submission => 'SF',
                                                            Label.PEAC_Pull_Bank_Details_Action =>'Ocrolus',
                                                            Label.PEAC_Initiate_Loan_App_to_GDS =>'SF', 
                                                            Label.PEAC_Teaser_Initial_Submission =>'SF' 
                                                        };

    /* Yes, No String Literals */
    public static final String Yes = 'Yes';
    public static final String No = 'No';
    
    /* Opportunity Object Related Literals */
    /* StageName*/
	public static final String OPPORTUNITY_STAGENAME_PROPOSAL = 'Proposal';
    public static final String OPPORTUNITY_STAGENAME_FUNDING = 'Funding';
    public static final String OPPORTUNITY_STAGENAME_BOOKING = 'Booking';
    public static final String OPPORTUNITY_STAGENAME_APPLICATION    = 'Application';
    public static final String OPPORTUNITY_STAGENAME_DECISION       = 'Decision';
    public static final String OPPORTUNITY_STAGENAME_DOCS_REQUESTED = 'Docs Requested';
    public static final String OPPORTUNITY_STAGENAME_DOCS_OUT       = 'Docs Out';
    public static final String OPPORTUNITY_STAGENAME_DOCS_IN        = 'Docs In';
    public static final String OPPORTUNITY_STAGENAME_LOST           = 'Lost';
    public static final String OPPORTUNITY_STAGENAME_QUOTE          = 'Quote';
    
    public static final String OPPORTUNITY_PURCHASEOPTION_CUSTOMER_OWNED          = 'Customer Owned';
	public static final String OPPORTUNITY_PURCHASEOPTION_RENTAL          = '26-Rental-No';
	
    /*Opportunity_Status__c*/
    public static final String OPPORTUNITY_STATUS_APPLICATION_IN_PROGRESS = 'Application In Progress';//Opportunity_Status__c
    public static final String OPPORTUNITY_STATUS_CREDIT_IN_QUEUE         = 'Credit - In Queue';
    public static final String OPPORTUNITY_STATUS_CREDIT_IN_REVIEW        = 'Credit - In Review';
    public static final String OPPORTUNITY_STATUS_CREDIT_MORE_INFO        = 'Credit - More Info Requested';
    public static final String OPPORTUNITY_STATUS_CREDIT_DECLINED         = 'Credit - Declined';
    public static final String OPPORTUNITY_STATUS_DOCS_REQUESTED          = 'Docs Requested';
    public static final String OPPORTUNITY_STATUS_ASSIGNED_TO_CMS         = 'Assigned to CMS';
    public static final String OPPORTUNITY_STATUS_DOCS_OUT                = 'Docs Out';
    public static final String OPPORTUNITY_STATUS_DOCS_IN_PENDING_REVIEW  = 'Docs in - Pending review';
    public static final String OPPORTUNITY_STATUS_LOST                    = 'Lost';
    public static final String OPPORTUNITY_STATUS_FRAUD_REVIEW            = 'Fraud Review';
    public static final String OPPORTUNITY_STATUS_FRAUD_MORE_INFO         = 'Fraud More Info Requested';
    public static final String OPPORTUNITY_STATUS_SUSPICIOUS_DECLINED     = 'Suspicious activity - Declined';
    public static final String OPPORTUNITY_STATUS_DOCS_IN                 = 'Docs In';
    
    /*Originating_Business__c*/
    public static final String OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC = 'VA PEAC';

    
    public static final String OPPORTUNITY_BANK_ACCOUNT_TYPE_CHECKINGS = 'Checkings';// putting dummy comment for commit
    public static final String OPPORTUNITY_BANK_CODE_100 = '100';// putting dummy comment for commit
    
    
    /* User Object Related Literals */
    public static final String PEAC_HOLDING_INC_VENDOR = 'Peac Holding Inc';
   // public static final String USER_VENDOR_TEAM_PEAC_HOLDING_INC = 'Peac Holding Inc';
    public static final String USER_INFORMATICA = 'User Informatica';
    public static final String USER_PROFILE_USER_INFORMATICA = 'User Informatica';
    //Added by rahul
    public static final String USER_PROFILE_SYSTEM_ADMINISTRATOR ='System Administrator';
    public static final String SYSTEM_ADMINISTRATOR ='System Administrator'; /*Added By Rahul*/    
    
    /*Miscellaneous Invoice Item Literals*/
    public static final String GL_CODE_0005_SECURITY_DEPOSIT = '0005 - Security Deposit'; 

    /*Account Branch*/
    public static final String ACCOUNT_BRANCH_PEAC_HOLDINGS_INC = '00231';

    /*Contract Lessor Codes*/
    public static final String CONTRACT_LESSOR_CODE_160 = '160';

    /*Contract QUOTE BUYOUT TYPES*/
    public static final String CONTRACT_BUYOUT_EPLUS_BOK_IN_TERM = '83';
    
    /*Miscellaneous Invoice Items GL Codes*/
    public static final String GLCODE_EWASTEDISPOSALFEE = '0041 - E-Waste Disposal Fee';
    
    /*ePlus*/
    public static final String VA_PEAC = 'VA PEAC';
    
    /**************************************************************************************************************
    @Author: Manish Suwalka (LTIMindtree)
	@Description:Purchase Order Related Literals
	**************************************************************************************************************/
    public static final String PURCHASE_ORDER_STATUS_FUNDED = 'Funded';
    
    
    
    /**************************************************************************************************************
    @Author: Manish Suwalka (LTIMindtree)
	@Description:Payment Related Literals
	**************************************************************************************************************/
    public static final String PAYMENT_STATUS_PAYMENT_ANKNOWLEDGED = 'Payment Confirmed';//Payment Acknowledged label and API name different
    public static final String PAYMENT_STATUS_PAYMENT_RELEASED = 'Payment Released'; // putting dummy comment for commit

    /**************************************************************************************************************
    @Author: Rahul
	@Description: Contract Discount Types Consideration
	**************************************************************************************************************/
    public static final String CUSTOMER_DISCOUNT = 'Customer';
    public static final String DEALER_DISCOUNT = 'Dealer';// putting dummy comment for commit

	 /**************************************************************************************************************
    @Author: Rahul
	@Description: Asset State and Country fields for ICELAND
	**************************************************************************************************************/
    public static final String ASSET_EQUIPMENT_ZIP_00000 = '00000';
    public static final String ASSET_EQUIPMENT_STATE_NON_US_STATES = 'ICE';
	public static final String ASSET_EQUIPMENT_LOCATION = 'ICE';
    public static final String ASSET_ICELAND_TAXCODE = '103';
	public static final String ASSET_STATE_LOCATION_CODE_98 = '98';
	public static final String ASSET_CITY_LOCATION_CODE_8855 = '8855';
    public static final String ASSET_COUNTY_LOCATION_CODE_855 = '855';
    
    // Added By Rajesh for State Property Status
    Public Static final Map<String,String> STATE_PROPERTY_STATUS = new Map<String,String>{
                                                    'ALABAMA'=> '11',
                                                    'ALASKA'=> '11',
                                                    'ARIZONA'=> '11',
                                                    'ARKANSAS'=> '11',
                                                    'CALIFORNIA'=> '12',
                                                    'COLORADO'=> '11',
                                                    'CONNECTICUT'=> '11',
                                                    'DELAWARE'=> '10',
                                                    'DISTRICT OF COLUMBIA'=> '11',
                                                    'FLORIDA'=> '11',
                                                    'GEORGIA'=> '11',
                                                    'HAWAII'=> '10',
                                                    'IDAHO'=> '11',
                                                    'ILLINOIS'=> '10',
                                                    'INDIANA'=> '11',
                                                    'IOWA'=> '10',
                                                    'KANSAS'=> '10',
                                                    'KENTUCKY'=> '11',
                                                    'LOUISIANA'=> '11',
                                                    'MAINE'=> '11',
                                                    'MARYLAND'=> '11',
                                                    'MASSACHUSETTS'=> '10',
                                                    'MICHIGAN'=> '11',
                                                    'MINNESOTA'=> '10',
                                                    'MISSISSIPPI'=> '11',
                                                    'MISSOURI'=> '11',
                                                    'MONTANA'=> '11',
                                                    'NEBRASKA'=> '11',
                                                    'NEVADA'=> '11',
                                                    'NEW HAMPSHIRE'=> '10',
                                                    'NEW JERSEY'=> '10',
                                                    'NEW MEXICO'=> '11',
                                                    'NEW YORK'=> '10',
                                                    'NORTH CAROLINA'=> '11',
                                                    'NORTH DAKOTA'=> '10',
                                                    'OKLAHOMA'=> '11',
                                                    'OREGON'=> '11',
                                                    'OHIO'=> '10',
                                                    'PENNSYLVANIA'=> '10',
                                                    'RHODE ISLAND'=> '11',
                                                    'SOUTH CAROLINA'=> '11',
                                                    'SOUTH DAKOTA'=> '10',
                                                    'TENNESSEE'=> '12',
                                                    'TEXAS'=> '11',
                                                    'UTAH'=> '11',
                                                    'VERMONT'=> '11',
                                                    'VIRGINIA'=> '11',
                                                    'WASHINGTON'=> '11',
                                                    'WEST VIRGINIA'=> '11',
                                                    'WISCONSIN'=> '11',
                                                    'WYOMING'=> '11',
                                                    'ICE'=> '10'
                                                    };
                                                        
	Public Static Final String OPERATING_LEASE = 'OL';
    Public Static Final String TRUE_LEASE = 'TL';
    Public Static Final Set<String> TRUE_AND_OPERATING_LEASE = new Set<String>{'TL','OL'};
    
    //No Tax Generation
    Public Static Final Set<String> NO_TAX_ZIP = new Set<String>{'00000'};
    
    /*Blended Income Codes*/
    public static final String BLENDED_INCOME_ITEM_CODE_0011 = '0011';
    
    /*Blended Income payment Status*/
    public static final String BLENDED_INCOME_ITEM_PAYMENT_STATUS_VOID_CANCELLED = 'Void/Cancelled';
    
    public static final Id  ORDERING_RECORDTYPE = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Ordering_Period').getRecordTypeId();
    
    /*Profile Name*/
    public static final String PROFILE_NAME_BOOKING = 'Booking';
    public static final String PROFILE_NAME_CMS = 'CMS';
    public static final String PROFILE_NAME_DATAADMIN = 'DataAdmin';
    public static final String PROFILE_NAME_PARTNER_AMBASSADOR = 'Partner Ambassador';
    public static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR = 'System Administrator';
    public static final String PROFILE_NAME_SERVICES_ADMIN =  'Services Admin';
    
}