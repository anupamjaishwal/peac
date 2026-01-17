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
                                                            Label.PEAC_Teaser_Initial_Submission => 'SF'
                                                        };
        
        
    
    
    
    
}