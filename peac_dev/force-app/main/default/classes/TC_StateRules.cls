public class TC_StateRules {
    
    public static Opportunity opportunityFortest = new Opportunity();
    public static Boolean isRunTest = false;
    
    public static boolean stateFinder(Id op){
        boolean valid = false;
        Opportunity opp = [SELECT id,Personal_Guarantors__c,Account_Business_State_Province__c,Business_Type__c,Equipment_Cost__c,Branch__c,Terms__c,Max_Rate__c,Yield__c,Loan_Amount__c,Purchase_Options__c,AccountId, Loan_Record_Type__c FROM Opportunity WHERE id = :op LIMIT 1];
        
            if(isRunTest){
                opp = opportunityFortest;
            }
            if(!opp.Loan_Record_Type__c){
                Id acc = opp.AccountId;
                
                Account acct = [SELECT id,Business_State__c,Business_Type__c FROM Account WHERE id = :acc LIMIT 1];
                //special case for dc because it does not use Opportunity.Account_Business_State_Province__c
                if(!Test.isRunningTest() && dc(opp, acct)){
                    return true;
                }
                
                switch on opp.Account_Business_State_Province__c{
                    when 'CA'{
                        valid = california(opp);
                    }
                    when 'VT'{
                        valid = vermont(opp,acct);
                    }
                    when 'AL'{
                        valid = alabama(opp);
                    }
                    when 'MS'{
                        valid = mississippi(opp);
                    }
                    when 'NM'{
                        valid = newmexico(opp);
                    }
                    when 'VA'{
                        valid = virginia(opp);
                    }
                    when 'CT'{
                        valid = connecticut(opp);
                    }
                    when 'MN'{
                        valid = minnesota(opp,acct);
                    }
                    when 'DE'{
                        valid = delaware(opp,acct);
                    }
                    when 'GA'{
                        valid = georgia(opp,acct);
                    }
                    when 'ND'{
                        valid = northDakota(opp,acct);
                    }
                    when 'SD'{
                        valid = southDakota(opp);
                    }
                    when 'AK'{
                        valid = alaska(opp);
                    }
                    when 'OR'{
                        valid = oregon(opp);
                    }
                    when 'MT'{
                        valid = montana(opp);
                    }
                    when 'NY'{
                        valid = newYork(opp,acct);
                    }
                    when 'NE'{
                        valid = nebraska(opp,acct);
                    }
                    when 'NJ'{
                        valid = newJersey(opp,acct);
                    }
                    when 'FL'{
                        valid = florida(opp);
                    }
                    when 'TX'{
                        valid = texas(opp);
                    }
                    when 'RI'{
                        valid = rhodeIsland(opp);
                    }
                    when 'MI'{
                        valid = michigan(opp);
                    }
                    when 'OK'{
                        valid = oklahoma(opp);
                    }
                    when 'CO'{
                        valid = colorado(opp);
                    }
                    when 'NV'{
                        valid = nevada(opp);
                    }
                    when else{
                        valid = false;
                    }
                }
        }
        return valid;
    }
    
    //SAL-3497
    public static boolean california(Opportunity opp){
        if(((opp.Equipment_Cost__c) < 5000) && (opp.Purchase_Options__c <> 'FMV' && opp.Purchase_Options__c <> 'Assigned Residual' && opp.Purchase_Options__c <> 'Assign Resid No Renewal')){
            return true;
        }else{
            return false;
        }
    }
    
    
    //SAL-3498
    public static boolean vermont(Opportunity opp,Account acct){
        if((opp.Purchase_Options__c <> 'FMV' && opp.Purchase_Options__c <> 'Assigned Residual' && opp.Purchase_Options__c <> 'Assign Resid No Renewal') && (opp.Max_Rate__c > 18 || opp.Yield__c > 18)){
            return true;
        }else if((opp.Purchase_Options__c <> 'FMV' && opp.Purchase_Options__c <> 'Assigned Residual' && opp.Purchase_Options__c <> 'Assign Resid No Renewal') && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        }else if((opp.Purchase_Options__c <> 'FMV' && opp.Purchase_Options__c <> 'Assigned Residual' && opp.Purchase_Options__c <> 'Assign Resid No Renewal') && (opp.Branch__c == 'IFP - Indirect Funding Pl') && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 20000){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3499
    public static boolean alabama(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) < 2000){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3500
    public static boolean mississippi(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) < 2000){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3501
    public static boolean newmexico(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 5000){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3502
    public static boolean virginia(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) < 5000){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3503
    public static boolean connecticut(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 10000 && (opp.Max_Rate__c > 1.12 || opp.Yield__c > 12)){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) > 10000 && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 250000 && (opp.Max_Rate__c > 1.17 || opp.Yield__c > 17)){
            return true;
        }else if((opp.Max_Rate__c == 0 || opp.Max_Rate__c == null) && (opp.Yield__c == 0 || opp.Yield__c == null) && opp.Branch__c == 'SNAP (National Accounts)' && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 10000 && opp.Terms__c <= 12){
            return true;
        }else if((opp.Max_Rate__c == 0 || opp.Max_Rate__c == null) && (opp.Yield__c == 0 || opp.Yield__c == null) && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 2999){
            return true;
        }else if((opp.Max_Rate__c == 0 || opp.Max_Rate__c == null) && (opp.Yield__c == 0 || opp.Yield__c == null) && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Equipment_Cost__c + opp.Loan_Amount__c) > 2999 && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 10000 && (opp.Purchase_Options__c == '1.00 Out' || opp.Purchase_Options__c == 'Customer Owned') && opp.Terms__c <= 36){
            return true;
        }else if((opp.Max_Rate__c == 0 || opp.Max_Rate__c == null) && (opp.Yield__c == 0 || opp.Yield__c == null) && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Equipment_Cost__c + opp.Loan_Amount__c) > 2999 && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 10000 && opp.Purchase_Options__c == 'FMV' && opp.Terms__c <= 24){
            return true;
        }else if((opp.Max_Rate__c == 0 || opp.Max_Rate__c == null) && (opp.Yield__c == 0 || opp.Yield__c == null) && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Equipment_Cost__c + opp.Loan_Amount__c) > 10000 && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 250000 && opp.Terms__c <= 24){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 20000 && opp.Branch__c == 'IFP - Indirect Funding Pl'){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3504
    public static boolean minnesota(Opportunity opp,Account acct){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 100000 && acct.Business_Type__c == 'Proprietorship'){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3505
    public static boolean delaware(Opportunity opp,Account acct){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 100000 && acct.Business_Type__c == 'Proprietorship'){
                        
                                                                                                                      
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3506
    public static boolean georgia(Opportunity opp,Account acct){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 3000 && acct.Business_Type__c == 'Proprietorship'){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3507
    public static boolean dc(Opportunity opp,Account acct){
       if(( opp.Purchase_Options__c <> 'FMV' && opp.Purchase_Options__c <> 'Assigned Residual' && opp.Purchase_Options__c <> 'Assign Resid No Renewal') && acct.Business_Type__c == 'Proprietorship' &&(opp.Max_Rate__c > 24 || opp.Yield__c > 24)){
            return true;
        } else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 5000 && opp.Branch__c == 'IFP - Indirect Funding Pl'){ 
           return true; 
        }else{
            Id oppid = opp.Id;
            List<Guarantor__c> pgs = [SELECT id, Type__c,Opportunity__c,Home_State__c FROM Guarantor__c WHERE Type__c = 'Personal Guarantor' AND Opportunity__c = :oppid AND Home_State__c = 'DC'];
            if(!pgs.isEmpty()){
                return true;
            }else if(opp.Max_Rate__c > 24 || opp.Yield__c > 24){
                return true;
            }else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
                return true;
            }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 5000 && opp.Branch__c == 'IFP - Indirect Funding Pl'){
                return true;    
            }else{
                return false;
            }
        }
    }
    
    //SAL-3508
    public static boolean northDakota(Opportunity opp,Account acct){
        if(acct.Business_Type__c == 'Proprietorship' && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 35000 && (opp.Max_Rate__c > 1.07 || opp.Yield__c > 7)){
            return true;
        }else if(opp.Max_Rate__c > 1.33 || opp.Yield__c > 33){
            return true;
        }else if(acct.Business_Type__c == 'Proprietorship' && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 35000 && (opp.Branch__c == 'SNAP (National Accounts)' || opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG' || opp.Branch__c == 'IFP - Indirect Funding Pl' || opp.Branch__c == 'Commercial Vehicle Group' || opp.Branch__c == 'TFG-Transportation Financ')){
            return true;
        }else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG' || opp.Branch__c == 'IFP - Indirect Funding Pl' || opp.Branch__c == 'Commercial Vehicle Group' || opp.Branch__c == 'TFG-Transportation Financ') && opp.Terms__c <= 12){
            return true;
        }
        else{
            return false;
        }
    }
    
    public static boolean southDakota(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 5000 || (opp.Yield__c > 36)){
            return true; // it wont include
        }else{
            return false;
        }
    }
    
    
    //SAL-3509
    public static boolean alaska(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && (opp.Max_Rate__c > 1.10 || opp.Yield__c > 10)){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && opp.Branch__c == 'SNAP (National Accounts)' && opp.Terms__c <= 39){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 2999 && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) > 2999 && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Purchase_Options__c == '1.00 Out' || opp.Purchase_Options__c == 'Customer Owned')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) > 2999 && (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Purchase_Options__c == 'FMV' && opp.Terms__c <=24){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && opp.Branch__c == 'IFP - Indirect Funding Pl'){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3510
    public static boolean oregon(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 50000 && (opp.Max_Rate__c > 1.12 || opp.Yield__c > 12) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 50000 && opp.Branch__c == 'SNAP (National Accounts)' && (opp.Terms__c <= 12) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 2999 && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) > 2999 && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Purchase_Options__c == '1.00 Out' || opp.Purchase_Options__c == 'Customer Owned') && (opp.Terms__c <= 39) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) > 2999 && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Purchase_Options__c == 'FMV' && (opp.Terms__c <= 24) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 50000 && opp.Branch__c == 'IFP - Indirect Funding Pl' && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else{
                         
          
             
            return false;
        }
    }
    
    //SAL-3511
    public static boolean montana(Opportunity opp){
        if(opp.Max_Rate__c > 1.15 || opp.Yield__c > 15){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 2999 && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Purchase_Options__c == '1.00 Out' || opp.Purchase_Options__c == 'Customer Owned')){
            return true;
        }else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        }else if(opp.Branch__c == 'IFP - Indirect Funding Pl' && (opp.Terms__c <= 39 || (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 20000)){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3512
    public static boolean newYork(Opportunity opp,Account acct){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 50000 && acct.Business_Type__c == 'Proprietorship' && (opp.Max_Rate__c > 1.16 || opp.Yield__c > 16)){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 2999 && acct.Business_Type__c == 'Proprietorship' && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Purchase_Options__c == '1.00 Out' || opp.Purchase_Options__c == 'Customer Owned')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 50000 && acct.Business_Type__c == 'Proprietorship' && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        } else if(((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 20000 || opp.Terms__c <= 39) && acct.Business_Type__c == 'Proprietorship' && opp.Branch__c == 'IFP - Indirect Funding Pl'){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3513
    public static boolean nebraska(Opportunity opp, Account acct){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && acct.Business_Type__c == 'Proprietorship' && (opp.Max_Rate__c > 1.16 || opp.Yield__c > 16)){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 2999 && acct.Business_Type__c == 'Proprietorship' && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Purchase_Options__c == '1.00 Out' || opp.Purchase_Options__c == 'Customer Owned')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && acct.Business_Type__c == 'Proprietorship' && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 25000 && acct.Business_Type__c == 'Proprietorship' && opp.Branch__c == 'IFP - Indirect Funding Pl'){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3514
    public static boolean newJersey(Opportunity opp, Account acct){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) < 50000 && acct.Business_Type__c == 'Proprietorship' && (opp.Max_Rate__c > 1.16 || opp.Yield__c > 16)){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) >= 50000 && acct.Business_Type__c == 'Proprietorship' && (opp.Max_Rate__c > 1.30 || opp.Yield__c > 30)){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) >= 50000 && acct.Business_Type__c == 'Proprietorship' && (opp.Max_Rate__c > 1.50 || opp.Yield__c > 50)){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 2999 && acct.Business_Type__c == 'Proprietorship' && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Purchase_Options__c == '1.00 Out' || opp.Purchase_Options__c == 'Customer Owned')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) < 50000 && acct.Business_Type__c == 'Proprietorship' && (opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        }else if(opp.Branch__c == 'IFP - Indirect Funding Pl' && acct.Business_Type__c == 'Proprietorship' &&  (opp.Equipment_Cost__c + opp.Loan_Amount__c) < 50000){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3515
    public static boolean florida(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 500000 && (opp.Max_Rate__c > 1.18 || opp.Yield__c > 18) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Equipment_Cost__c + opp.Loan_Amount__c) > 500000 && (opp.Max_Rate__c > 1.25 || opp.Yield__c > 25) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Terms__c <= 24) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if(opp.Branch__c == 'IFP - Indirect Funding Pl' &&  (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 20000 && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true; 
                                                                                                                                                              
                           
        }
        else{
            return false;
        }
    }
    
    //SAL-3516
    public static boolean texas(Opportunity opp){
        if((opp.Max_Rate__c > 1.18 || opp.Yield__c > 18) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && (opp.Terms__c <= 24) && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;
        }else if(opp.Branch__c == 'IFP - Indirect Funding Pl' &&  (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 20000 && (opp.Purchase_Options__c != 'FMV' && opp.Purchase_Options__c != 'Assigned Residual' && opp.Purchase_Options__c != 'Assign Resid No Renewal')){
            return true;   
                                                                                                                                                             
                            
        }
        else{
            return false;
        }
    }
    
    //SAL-3517
    public static boolean rhodeIsland(Opportunity opp){
        if((opp.Equipment_Cost__c + opp.Loan_Amount__c) < 1000000 && (opp.Max_Rate__c > 1.21 || opp.Yield__c > 21)){
            return true;
        }else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        }else if(opp.Branch__c == 'IFP - Indirect Funding Pl' &&  (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 5000){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3518
    public static boolean michigan(Opportunity opp){
        if(opp.Max_Rate__c > 1.24 || opp.Yield__c > 24){
            return true;
        }else if((opp.Branch__c == 'HKF Horizon Keystone Fin' || opp.Branch__c == 'Office Equip Group-OEG') && opp.Terms__c <= 24){
            return true;
        }else if(opp.Branch__c == 'IFP - Indirect Funding Pl' &&  (opp.Equipment_Cost__c + opp.Loan_Amount__c) <= 5000){
            return true;
        }
        else{
            return false;
        }
    }
    
    //SAL-3519
    public static boolean oklahoma(Opportunity opp){
        if(opp.Max_Rate__c > 1.45 || opp.Yield__c > 45){
            return true;
        }else{
            return false;
        }
    }
    
    //SAL-3520
    public static boolean colorado(Opportunity opp){
        if(opp.Max_Rate__c > 1.45 || opp.Yield__c > 45){
            return true;
        }else{
            return false;
        }
    }
    

    public static boolean nevada(Opportunity opp){
        if(opp.Purchase_Options__c == 'FMV' || opp.Purchase_Options__c == 'Assigned Residual' || opp.Purchase_Options__c == 'Assign Resid No Renewal'){
            return false;
        }else{
            return true;
        }
    }
}