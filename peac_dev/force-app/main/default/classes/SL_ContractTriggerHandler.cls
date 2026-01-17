public with sharing class SL_ContractTriggerHandler extends SL_Trigger.baseHandler {
    private Set<Id> contractsChangedDelinquency = new Set<Id>();
    private Set<Id> contractsChangedStatus = new Set<Id>();
    private Set<Id> contractsChangedInsurance = new Set<Id>();
    private Set<Id> contractsChangedName = new Set<Id>();
    private Set<Id> contractsChangedPayArrangement = new Set<Id>();
    private Set<Id> contractsChangedAgentLock = new Set<Id>();
    private Set<Id> contractsChangedReprintInvoice = new Set<Id>();
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    private Map<Id, Account> customerAccounts = new Map<Id, Account>();
    private Map<Id, User> dealerUsers = new Map<Id, User>();
    private Map<Id, Insurance__c> insurances = new Map<Id, Insurance__c>();
    private Map<Id, List<Contract_Account_Role__c>> contractAccountRoles = new Map<Id, List<Contract_Account_Role__c>>();
    private Map<Id, List<Contract_Asset__c>> contractAssets = new Map<Id, List<Contract_Asset__c>>();
    private Map<Id, List<Contract_Misc_Billable__c>> contractMiscBillables = new Map<Id, List<Contract_Misc_Billable__c>>();
    private Boolean alreadyInQ;
    static Boolean alreadyShareInQ = false;
    public Map<Id, Account> accountUpdateList = new Map<Id, Account>();
    public List<Contract__c> contractUpdateList = new List<Contract__c>();
    public Map<Id, Contract_Misc_Billable__c> cmbToDeleteById = new Map<Id, Contract_Misc_Billable__c>();
    private Map<Id, Id> mapRecordsToShare = new Map<Id, Id>();
    private Map<Id, set<Id>> mapRecordsToShare1 = new Map<Id, set<Id>>();
    private Map<Id, Id> mapRecordsToRemoveSharing = new Map<Id, Id>();
    private static final String CONTRACT_SHARE_API_NAME = 'Contract__share';
    SL_SharingCustomRecord shareContract;

    public override void beforeInsert(List<SObject> newList){
        SL_InfoleaseUtils.isRecursive = true;
        List<Contract__c> contractList = new List<Contract__c>();
        Set <String> uniqueContractNames = new Set <String>();
        for(SObject theObject :newList){
            contract__c cntrct = (Contract__c)theObject;
            getLookupMaps(theObject);
            if (uniqueContractNames.contains(cntrct.name)) { // {SL-2817} preventing duplicate contracts with same name from been inserted in bulk insert
                cntrct.addError('duplicates contract ' + cntrct.name + ' skipped during bulk insert');
                //System.debug('duplicates contract skipped during bulk insertp::' +cntrct.name);
        }
            uniqueContractNames.add(cntrct.name);
            contractList.add(cntrct);      
           // contractList.add((Contract__c)theObject);
        }
        
        getInfoFromOthers(new Map<Id, SObject>());
        beforeChangesToSelf(new Map<Id, SObject>(), contractList, true);
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        checkUpdatedFields(oldMap, newMap);
        List<Contract__c> contractList = new List<Contract__c>();
        for(Id ContractId :newMap.keySet()){
            getLookupMaps(newMap.get(ContractId));
            contractList.add((Contract__c)newMap.get(ContractId));
        }
        getInfoFromOthers(newMap);
        beforeChangesToSelf(oldMap, contractList, false);
        checkForNintextFlags(contractList, oldMap);
    }

    private void beforeChangesToSelf(Map<Id, SObject> oldMap, List<Contract__c> newList, Boolean isNew){
        Contract_Account_Role__c primaryDealer = new Contract_Account_Role__c();
        Contract_Criteria__c criteriaSetting = Contract_Criteria__c.getInstance();
        List<String> noGoLessorCodes31 = new List<string>{'005', '006', '150', '160', '405', '406'};
        List<String> varadOrSyndLessorCodes = new List<string>{'150', '160'};
        List<String> lessorCodesForTV = new List<string>{'005', '006', '405', '406'};
        String staumannDealer = '800448.8168';
        String arrowDealer = '303790.2330';
        String hAndADealer = '707523.1112';
        Id workingCLoan = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Working_Capital_Loan').getRecordTypeId();
        Id endUserId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        Map<Id, Contract_Account_Role__c> primaryDealerPerContract = new Map<Id, Contract_Account_Role__c>();
        for(Id contractId :this.contractAccountRoles.keySet()){
            for(Contract_Account_Role__c car : this.contractAccountRoles.get(contractId)){
                if(car.Primary_Dealer__c){
                    primaryDealerPerContract.put(contractId, car);
                    break;
                }
            }
        }
        List<Warehouse_Mapping__mdt> warehouseMappings = new List<Warehouse_Mapping__mdt>();
        for(List<Contract_Asset__c> assets :this.contractAssets.values()){
            if(assets.size() > 0){
                warehouseMappings = [SELECT Id, QualifiedApiName, Warehouse__c, Location__c, Territory__c, Residual_Amount__c FROM Warehouse_Mapping__mdt];
                break;
            }
        }
        for(Contract__c contract :newList){
            Boolean isDisposed = contract.Status__c.contains('Disposed');
            Account customerAccount = this.customerAccounts.get(contract.Customer__c);
            User dealerUser = this.dealerUsers.get(contract.Dealer_User__c);
            if(customerAccount != null )contract.Customer_Filter__c = customerAccount.Name;
            System.debug('contract.Customer_Filter__c ' + contract.Customer_Filter__c);
            primaryDealer = primaryDealerPerContract.get(contract.Id);
            if(primaryDealer == null){
                primaryDealer = new Contract_Account_Role__c();
            }
            if(!isDisposed
                && contract.RecordTypeId == workingCLoan
                && contract.Current_Days_Delinquent__c > 0){
                contract.Collection_Group__c = 'Working Capital Delinquency';
            }else{
                if(String.isNotEmpty(contract.Delinquency_Status_Code__c) 
                    && contract.Delinquency_Status_Code__c != '00'
                    && primaryDealer.Account__r.Dealer_Number__c == staumannDealer){
                    contract.Collection_Group__c = 'Staumann';
                }else{
                    switch on contract.Delinquency_Status_Code__c {
                        when '00' {
                            this.assignDefaultAgent(contract, criteriaSetting.Default_Agent_Id__c, isDisposed);// SL-2871 Misael Romero
                        }
                        when '01' {

                            // New conditions SL-2698
                            if(contract.IsXBS__c == true 
                            && contract.First_Payment_Default__c == false && contract.Contract_Balance_Remaining__c >= criteriaSetting.Maximum_CBR_XBS_ADR__c){
                            contract.Collection_Group__c = 'XBS Dialer Team Assigned';
                            } 

                            else if(contract.IsXBS__c == true 
                            && contract.First_Payment_Default__c == false && contract.Contract_Balance_Remaining__c < criteriaSetting.Maximum_CBR_XBS_ADR__c && contract.Net_Investment__c >= 5000){
                            contract.Collection_Group__c = 'XBS Dialer Regular';
                            } 

                            else if(contract.IsXBS__c == true 
                            && contract.First_Payment_Default__c == false && contract.Contract_Balance_Remaining__c < criteriaSetting.Maximum_CBR_XBS_ADR__c && contract.Net_Investment__c < 5000){
                            contract.Collection_Group__c = 'XBS Low Balance';
                            } 
                            // New conditions SL-2698

                            // New condition for XBS Dialer Regular
                            else if(contract.IsXBS__c == true 
                                && contract.First_Payment_Default__c == false){
                                contract.Collection_Group__c = 'XBS Dialer Regular';
                            // New condition for XBS Dialer First Payment Default
                            } else if(contract.IsXBS__c == true 
                                && contract.First_Payment_Default__c == true) {
                                contract.Collection_Group__c = 'XBS Dialer First Payment Default';
                            //SL-2551 - Carlos Herrera
                            }else if(contract.Lessor_Code__c == '101'||contract.Lessor_Code__c=='102'||contract.Lessor_Code__c=='471'){
                                if(contract.First_Payment_Default__c==true){
                                    contract.Collection_Group__c = 'ADR Dialer First Payment Default';
                                }else if(contract.First_Payment_Default__c== false){

                            // New conditions SL-2698
                                    if(contract.Contract_Balance_Remaining__c >= criteriaSetting.Maximum_CBR_XBS_ADR__c){contract.Collection_Group__c='ADR Dialer Team Assigned';}
                                    else if(contract.Contract_Balance_Remaining__c < criteriaSetting.Maximum_CBR_XBS_ADR__c && contract.Net_Investment__c >= 5000){contract.Collection_Group__c='ADR Dialer Regular';}
                                    else if(contract.Contract_Balance_Remaining__c < criteriaSetting.Maximum_CBR_XBS_ADR__c && contract.Net_Investment__c < 5000){contract.Collection_Group__c='ADR Low Balance';}
                            // New conditions SL-2698
                                }                                        
                            // Existing conditions
                            } else if(contract.First_Payment_Default__c) {
                                contract.Collection_Group__c = 'Dialer First Payment Default';
                            
                            } else {
                                if(contract.Facility_Code__c == '2.27') {
                                    contract.Collection_Group__c = 'Dialer TCF';
                                } else {
                                    if(primaryDealer.Account__r.Dealer_Number__c == arrowDealer
                                    || primaryDealer.Account__r.Dealer_Number__c == hAndADealer) {
                                    contract.Collection_Group__c = 'Dialer Special';
                                    } else {
                                        if(primaryDealer.Account__r.Dealer_Number__c != arrowDealer 
                                        && primaryDealer.Account__r.Dealer_Number__c != hAndADealer
                                        && contract.Contract_Balance_Remaining__c <= criteriaSetting.Maximum_Balance_CBR__c) {
                                        contract.Collection_Group__c = 'Dialer Regular';
                                        } else {
                                            if(contract.Contract_Balance_Remaining__c > criteriaSetting.Maximum_Balance_CBR__c){
                                                contract.Collection_Group__c = 'Dialer Team Assigned';
                                            } else {
                                                contract.Collection_Group__c = 'Dialer Do Not Call';
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        when '31' {
                            // New condition for XBS 31 Regular
                            if(contract.Status__c == 'Active'  
                                && contract.IsXBS__c == true 
                                && contract.First_Payment_Default__c == false) {
                                
                                contract.Collection_Group__c = 'XBS 31 Regular';
                        
                            // New condition for XBS 31 First Payment Default
                            } else if(contract.Status__c == 'Active' 
                                && contract.IsXBS__c == true 
                                && contract.First_Payment_Default__c == true) {
                                
                                contract.Collection_Group__c = 'XBS 31 First Payment Default';
                        
                            // New condition for XBS 31 EOT
                            } else if(contract.Status__c == 'Renewal' 
                                && contract.IsXBS__c == true) {
                                
                                contract.Collection_Group__c = 'XBS 31 EOT';
                        
                        //SL-2551 - Carlos Herrera
                            }else if(contract.Lessor_Code__c=='101'||contract.Lessor_Code__c=='102'||contract.Lessor_Code__c=='471'){
                                if(contract.Status__c == 'Active' && contract.First_Payment_Default__c== false){
                                    contract.Collection_Group__c='ADR 31 Regular';
                                }else if(contract.Status__c == 'Active'&&contract.First_Payment_Default__c== true){
                                    contract.Collection_Group__c = 'ADR 31 First Payment Default';
                                }else if(contract.Status__c=='Renewal'&&contract.First_Payment_Default__c== true){
                                    contract.Collection_Group__c = 'ADR 31 EOT';
                                }
                            // Existing logic
                            }else{
                                if(lessorCodesForTV.contains(contract.Lessor_Code__c)) {
                                    contract.Collection_Group__c = 'Titled Vehicles';
                                }else{
                                    if(contract.Facility_Code__c != '2.99'){
                                        if(!noGoLessorCodes31.contains(contract.Lessor_Code__c)){
                                            if(!contract.First_Payment_Default__c){
                                                if(primaryDealer.Account__r.Dealer_Number__c != staumannDealer){
                                                    if(contract.Contract_Balance_Remaining__c < 21000){
                                                        contract.Collection_Group__c = '31 Regular';
                                                        }else{
                                                        contract.Collection_Group__c = '31 High Balance';
                                                    }
                                                }
                                            }else{
                                                contract.Collection_Group__c = '31 First Payment Default';
                                            }
                                        }
                                        if(varadOrSyndLessorCodes.contains(contract.Lessor_Code__c)) {
                                            contract.Collection_Group__c = '31 Syndication';
                                        }else{
                                            if(contract.Renewal_Status__c == 'A' || contract.Renewal_Status__c == 'E'){
                                                contract.Collection_Group__c = '31 EOT';
                                            }
                                        }
                                    }else{
                                        if(varadOrSyndLessorCodes.contains(contract.Lessor_Code__c)) {
                                            contract.Collection_Group__c = '31 Varadero';
                                        }else{
                                            if(contract.Renewal_Status__c == 'A' || contract.Renewal_Status__c == 'E'){
                                                contract.Collection_Group__c = '31 EOT';
                                            }
                                        }
                                    }
                                }
                            }              
                        }
                        when '61' {
                            // New condition for XBS 61
                            if(contract.Status__c == 'Active' 
                                && contract.IsXBS__c == true) {
                                
                                contract.Collection_Group__c = 'XBS 61';
                            
                            // New condition for XBS 61 EOT
                            } else if(contract.Status__c == 'Renewal' 
                                && contract.IsXBS__c == true) {
                                
                                contract.Collection_Group__c = 'XBS 61 EOT';
                        
                        //SL-2551 - Carlos Herrera
                            }else if(contract.Lessor_Code__c=='101'||contract.Lessor_Code__c=='102'||contract.Lessor_Code__c=='471'){
                                if(contract.Status__c == 'Active'){
                                    contract.Collection_Group__c = 'ADR 61';
                                }else if(contract.Status__c == 'Renewal'){
                                    contract.Collection_Group__c = 'ADR 61 EOT';
                                }
                            // Existing logic
                            }else{
                                if(varadOrSyndLessorCodes.contains(contract.Lessor_Code__c)) {
                                    contract.Collection_Group__c = '61 Syndication';
                                }else{
                                    if(contract.Renewal_Status__c == 'A' || contract.Renewal_Status__c == 'E'){
                                        contract.Collection_Group__c = '61 EOT';
                                    }else{
                                        contract.Collection_Group__c = '61';
                                    }
                                }
                            }
                        }
                        when '91' {
                            // New condition for XBS 91
                            if(contract.Status__c == 'Active' 
                                && contract.IsXBS__c == true) {
                                
                                contract.Collection_Group__c = 'XBS 91';
                        
                            // New condition for XBS 91+ EOT
                            } else if(contract.Status__c == 'Renewal' 
                                && contract.IsXBS__c == true) {
                                
                                contract.Collection_Group__c = 'XBS 91+ EOT';
                        
                        //SL-2551 - Carlos Herrera
                            }else if(contract.Lessor_Code__c=='101'||contract.Lessor_Code__c=='102'||contract.Lessor_Code__c=='471'){
                                if(contract.Status__c == 'Active'){
                                    contract.Collection_Group__c = 'ADR 91';
                                }else if(contract.Status__c == 'Renewal'){
                                    contract.Collection_Group__c = 'ADR 91 EOT';// 'ADR 91+ EOT' ?
                                }
                            // Existing logic
                            }else{
                                if(varadOrSyndLessorCodes.contains(contract.Lessor_Code__c)) {
                                    contract.Collection_Group__c = '91 Syndication';
                                }else{
                                    if(contract.Renewal_Status__c == 'A' || contract.Renewal_Status__c == 'E'){
                                        contract.Collection_Group__c = '91+ EOT';
                                    }else{
                                        contract.Collection_Group__c = '91';
                                    }
                                }
                            }
                        }
                        when '121', '151', '181' {
                            // New condition for XBS Pre-Charge Off
                            if(contract.Status__c == 'Active'
                                && contract.IsXBS__c == true) {
                                
                                contract.Collection_Group__c = 'XBS Pre-Charge Off';
                        
                            } else if(contract.Status__c == 'Renewal' && contract.IsXBS__c == true && 
                                        (contract.Delinquency_Status_Code__c == '121' ||
                                        contract.Delinquency_Status_Code__c == '151' ||
                                        contract.Delinquency_Status_Code__c == '181')) {
                                            
                                        contract.Collection_Group__c = 'XBS 91+ EOT';
                        
                //SL-2551 - Carlos Herrera
                            }else if(contract.Lessor_Code__c=='101'||contract.Lessor_Code__c=='102'||contract.Lessor_Code__c=='471'){
                                if(contract.Status__c == 'Active'){
                                    contract.Collection_Group__c = 'ADR Pre-Charge Off';
                                }else if(contract.Status__c == 'Renewal'){
                                    contract.Collection_Group__c = 'ADR 91 EOT';// 'ADR 91+ EOT' ?
                                }
                            // SL-2586-Carlos Herrera
                            }else if((contract.Delinquency_Status_Code__c=='121'||contract.Delinquency_Status_Code__c=='151')&&contract.Status__c=='Active'){
                                contract.Collection_Group__c='121 Regular';
                            // Existing logic for other conditions
                            }else{
                                if(contract.Renewal_Status__c == 'A' || contract.Renewal_Status__c == 'E') {
                                    contract.Collection_Group__c = '91+ EOT';
                                    // SL-2586-Carlos Herrera
                                }else if(contract.Delinquency_Status_Code__c=='181'){
                                    contract.Collection_Group__c = 'Pre-Charge Off';
                                }
                            }
                        }
                        when else {
                            this.assignDefaultAgent(contract, criteriaSetting.Default_Agent_Id__c, isDisposed);// SL-2871 Misael Romero
                        }
                    }
                }
            }
            if(!contract.Agent_Lock__c 
                && (contract.Id == null || this.contractsChangedStatus.contains(contract.Id))
                && isDisposed){
                contract.OwnerId = criteriaSetting.Default_Agent_Id__c;
            }
            
            if(customerAccount != null){
                if((contract.Id == null || this.contractsChangedAgentLock.contains(contract.Id)) 
                    && customerAccount.Collection_Agent__c != null    
                    && !contract.Agent_Lock__c && !isDisposed
                    && contract.Delinquency_Status_Code__c != '00' && String.isNotEmpty(contract.Delinquency_Status_Code__c)){
                    contract.OwnerId = customerAccount.Collection_Agent__c;
                }
                if(customerAccount.CCAN__c != '' && contract.CCAN__c != customerAccount.CCAN__c){
                    contract.CCAN__c = customerAccount.CCAN__c;
                }
                if(contract.Id == null && String.isBlank(contract.Insurance__c)
                    && String.isNotBlank(customerAccount.Active_Insurance__c)
                    && customerAccount.Active_Insurance__r.Account_Level__c == true
                    && customerAccount.Active_Insurance__r.Expiration_Date__c > Date.today()){
                    contract.Insurance__c = customerAccount.Active_Insurance__c;
                }
            }
            if(this.contractsChangedName.contains(contract.Id)){
                String latestName = ((Contract__c)oldMap.get(contract.Id)).Name.replace(';', '');
                String history = String.isNotEmpty(contract.Previous_Contract_Numbers__c)? contract.Previous_Contract_Numbers__c + ';': '';
                contract.Previous_Contract_Numbers__c = history + latestName;
            }
            if(this.contractsChangedReprintInvoice.contains(contract.Id) && !contract.Reprint_Invoice__c){
                contract.Invoice_Reprint_Date__c = null;
            }
            if(this.contractAssets.containsKey(contract.Id) && this.contractAssets.get(contract.Id).size() > 0){
                Contract_Asset__c firstAsset = this.contractAssets.get(contract.Id)[0];
                if(firstAsset.Asset_Code__c != '014.004' && firstAsset.Asset_Code__c != 'Copiers'){
                    contract.Recommended_Warehouse__c = 'Omni';
                    contract.Dealer_Recommended_Warehouse__c = 'Omni';
                }else{
                    String residualAmountRule = '';
                    if(firstAsset.Residual_Amount__c >= 750.00){
                        residualAmountRule = '$750.00+';
                    }else{
                        residualAmountRule = '$749.99-';
                    }
                    contract.Recommended_Warehouse__c = getWarehouse(warehouseMappings, firstAsset.Asset_State__c, residualAmountRule);
                    contract.Dealer_Recommended_Warehouse__c = getWarehouse(warehouseMappings, primaryDealer.Account__r.Business_State__c, residualAmountRule);
                }
            }
            // DP-1615 Misael Romero
            if(dealerUser != null && !dealerUser.IsActive){
                contract.Dealer_User__c = null;
            }
        }
    }

    public override void afterInsert(Map<Id, SObject> newMap){
        SL_InfoleaseUtils.isRecursive = true;
        this.alreadyInQ = false;
        List<Contract__c> newList = new List<Contract__c>();
        shareContract = new SL_SharingCustomRecord();
        PEAC_SuperPartnerDealerChange.contractShare((Map<id, Contract__c>)newMap);
        

        for(Contract__c obj : (List<Contract__c>) newMap.values()){
          getLookupMaps(obj);
          newList.add((Contract__c)obj);
           system.debug('Iam here'+this.mapRecordsToShare);
        }
        afterChangesToOthers(newMap, true, false);
  
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        //send the updates to Infolease
        if(!SL_InfoleaseUtils.isRecursive && !System.isFuture() && !System.isBatch()){
            SL_InfoleaseUtils.isRecursive = true;
            Map <Id, Contract__c> oldMapContract = new Map <Id, Contract__c>();
            Map <Id, Contract__c> newMapContract = new Map <Id, Contract__c>();
            for(SObject theObj : oldMap.values()){
                oldMapContract.put(theObj.Id, (Contract__c)theObj);
                newMapContract.put(theObj.Id, ((Contract__c)newMap.get(theObj.Id)));
            }
            SL_InfoleaseContractController.updateContract(oldMapContract, newMapContract);
            //Added by Rajesh(LTIMindtree)
            //Call the method to share contracts with dealer accounts and parents as well
            PEAC_SuperPartnerDealerChange.removeContractShare(newMapContract,oldMapContract); 
        }
        
        this.alreadyInQ = false;
        List<Contract__c> newList = new List<Contract__c>();
        checkUpdatedFields(oldMap, newMap);
        for(SObject obj : newMap.values()){
            getLookupMaps(obj);
            newList.add((Contract__c)obj);
        }
        afterChangesToOthers(newMap, false, false);
    }

    public override void afterDelete(Map<Id, SObject> oldMap){
        SL_InfoleaseUtils.isRecursive = true;
        this.alreadyInQ = false;
        List<Contract__c> oldList = new List<Contract__c>();
        for(SObject obj : oldMap.values()){
            getLookupMaps(obj);
            oldList.add((Contract__c)obj);
        }
        afterChangesToOthers(oldMap, false, true);
    }

    private void getLookupMaps(SObject obj){
        Contract__c contract = (Contract__c)obj;
        if(contract.Customer__c != null){
            this.customerAccounts.put(contract.Customer__c, new Account());
        }
        if(contract.Insurance__c != null){
            this.insurances.put(contract.Insurance__c, new Insurance__c());
        }
        if(contract.Dealer_User__c != null){
            this.dealerUsers.put(contract.Dealer_User__c, new User());
        }
        if(contract.Id != null){
            this.contractAccountRoles.put(contract.Id, new List<Contract_Account_Role__c>());
            this.contractAssets.put(contract.Id, new List<Contract_Asset__c>());
            this.contractMiscBillables.put(contract.Id, new List<Contract_Misc_Billable__c>());
        }
        
    }
    
    private void getInfoFromOthers(Map<Id, SObject> newMap){
        if(newMap.size() > 0){
            for(Contract__c related :[SELECT Id, Customer__r.CCAN__c, Customer__r.Name, Customer__r.Tax_ID__c, Customer__r.Active_Insurance__c, Customer__r.Collection_Agent__c,
                    Customer__r.Active_Insurance__r.Account_Level__c, Customer__r.Active_Insurance__r.Expiration_Date__c,
                    Customer__r.Account_Total_Active_Contracts__c, Customer__r.Multiples__c, Customer__r.RecordTypeId,
                    Insurance__r.Account_Level__c, Insurance__r.Expiration_Date__c, Dealer_User__r.Contact.AccountId, Dealer_User__r.IsActive, 
                    Dealer_User__r.IsPortalEnabled, 
                    (SELECT Id, Primary_Dealer__c, Account__c, Account__r.Dealer_Number__c, 
                        Account__r.Business_State__c, Contract__c 
                        FROM Contract_Account_Roles__r),
                    (SELECT Id, Asset_State__c, Asset_Code__c, Residual_Amount__c, Contract__c 
                        FROM Contract_Assets__r  ORDER BY Name),
                    (SELECT Id, Misc_Key__c FROM Contract_Misc_Billables__r)
                FROM Contract__c WHERE Id IN :newMap.keySet()]){
                if(related.Customer__c != null){
                    this.customerAccounts.put(related.Customer__c, related.Customer__r);
                }
                if(related.Insurance__c != null){
                    this.insurances.put(related.Insurance__c, related.Insurance__r);
                }
                if(related.Dealer_User__c != null){
                    this.dealerUsers.put(related.Dealer_User__c, related.Dealer_User__r);
                }
                for(Contract_Account_Role__c theCAR : related.Contract_Account_Roles__r){
                    this.contractAccountRoles.get(related.Id).add(theCAR);
                }
                for(Contract_Asset__c theAsset : related.Contract_Assets__r){
                    // System.debug('theAsset: ' + theAsset);
                    this.contractAssets.get(related.Id).add(theAsset);
                }
                List<Contract_Misc_Billable__c> relatedCMB = new List<Contract_Misc_Billable__c>();
                for(Contract_Misc_Billable__c theCMB:related.Contract_Misc_Billables__r){
                    relatedCMB.add(theCMB);
                }
                this.contractMiscBillables.get(related.Id).addAll(relatedCMB);
            }
        }
        if(newMap.size() == 0 && this.customerAccounts.keySet().size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.customerAccounts.values())){
            this.customerAccounts.putAll([SELECT Id, Name, CCAN__c, Tax_ID__c, Active_Insurance__c, Collection_Agent__c,
                Active_Insurance__r.Account_Level__c, Active_Insurance__r.Expiration_Date__c, Multiples__c, RecordTypeId FROM Account WHERE Id IN : this.customerAccounts.keySet()]);
        }
        if(this.dealerUsers.keySet().size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.dealerUsers.values())){
            this.dealerUsers.putAll([SELECT Id, Contact.AccountId, IsActive, IsPortalEnabled FROM User WHERE Id IN : this.dealerUsers.keySet()]);
        }
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNewContract, Boolean isDelete){
        getInfoFromOthers(newMap);
        List<String> dealerAccountIds = new List<String>();
        for(SObject obj : newMap.values()){
            Contract__c contract = (Contract__c)obj;
            Account customerAccount = this.customerAccounts.get(contract.Customer__c);
            User dealerUser = this.dealerUsers.get(contract.Dealer_User__c);
            List<String> fieldsChanged = this.fieldsChangedById.get(contract.Id);

            if(!this.alreadyInQ && contract.Customer__c != null
                && (!contract.Status__c.contains('Disposed')
                && (this.contractsChangedDelinquency.contains(contract.Id)
                || isNewContract))){
                SL_ContractTriggerHandler.callCollectionAssignment();
                this.alreadyInQ = true;
            }
            if(isNewContract && contract.Insurance__c != null){// on new Contract
                this.contractsChangedInsurance.add(contract.Id);
            }
            if(contract.Payment_Arrangement__c && Contract__c.Customer__c != null
                && (this.contractsChangedPayArrangement.contains(contract.Id) || isNewContract)){
                customerAccount.Payment_Arrangement_Contract__c = contract.Id;
                customerAccount.Payment_Arrangement__c = true;

                this.accountUpdateList.put(customerAccount.Id, customerAccount);
            }
            if(fieldsChanged != null && fieldsChanged.contains('Infolease_Environment__c') 
                && TC_BWUtility.isIL10Record(contract)){
                for(Contract_Misc_Billable__c il9CMB: this.contractMiscBillables.get(contract.Id)){
                    if(il9CMB.Misc_Key__c != null && Integer.valueOf(il9CMB.Misc_Key__c) < 4000000){
                        this.cmbToDeleteById.put(il9CMB.Id, il9CMB);
                    }
                }
            }
            shareCustomerAccountDP(contract, isNewContract, fieldsChanged, dealerUser, dealerAccountIds);
        }
        passDownInsurance();
        if(!isDelete){
            setNewActiveInsurance(newMap);
        }
        if(this.accountUpdateList.values().size() > 0){
            update this.accountUpdateList.values();
        }
        if(this.cmbToDeleteById.values().size() > 0){
            delete this.cmbToDeleteById.values();
        }
    }

    private void passDownInsurance(){
        if(this.contractsChangedInsurance.size() > 0){
            List<Contract_Asset__c> assets = [SELECT Id, Contract__r.Insurance__c, Insurance__c FROM Contract_Asset__c WHERE Titled_Asset__c != 'Y' AND Contract__c IN :this.contractsChangedInsurance];
            for(Contract_Asset__c asset : assets){
                asset.Insurance__c = asset.Contract__r.Insurance__c;
            }
            update assets;
        }
    }

    private void setNewActiveInsurance(Map<Id, SObject> newMap){
        List<Account> customersToUpdate = new List<Account>();
        for(Id contractId : this.contractsChangedInsurance){
            Contract__c contract = (Contract__c)newMap.get(contractId);
            if(contract.Customer__c != null && contract.Insurance__c != null){
                Account customerBefore = this.customerAccounts.get(contract.Customer__c);
                if(customerBefore.Active_Insurance__c != contract.Insurance__c){
                    Account customer = SL_InsuranceTriggerHandler.newActiveInsuranceToAccount(this.customerAccounts.get(contract.Customer__c), this.insurances.get(contract.Insurance__c));
                    if(customer != null){
                        customersToUpdate.add(customer);
                    }
                }
            }
        }
        update customersToUpdate;
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        shareContract = new SL_SharingCustomRecord();
        Id workingCLoan = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
            .get('Working_Capital_Loan').getRecordTypeId();
        List<String> fieldsToCheck = new List<String>{'Dealer_Name__c', 'Dealer_User__c', 'Infolease_Environment__c', 'OwnerId'};
        for(Id contractId :newMap.keySet()){
            Contract__c contract = (Contract__c)newMap.get(contractId);
            Contract__c oldContract = (Contract__c)oldMap.get(contractId);
            if((contract.Delinquency_Status_Code__c != oldContract.Delinquency_Status_Code__c
                && contract.RecordTypeId != workingCLoan)
                || (contract.RecordTypeId == workingCLoan
                && contract.Current_Days_Delinquent__c != oldContract.Current_Days_Delinquent__c
                && contract.Current_Days_Delinquent__c > 0)){
                this.contractsChangedDelinquency.add(contractId);
            }
            if(contract.Insurance__c != null && contract.Insurance__c != oldContract.Insurance__c){
                this.contractsChangedInsurance.add(contractId);
            }
            if(contract.Name != oldContract.Name){
                this.contractsChangedName.add(contractId);
            }
            if(contract.Payment_Arrangement__c != oldContract.Payment_Arrangement__c){
                this.contractsChangedPayArrangement.add(contractId);
            }
            if(contract.Status__c != oldContract.Status__c){
                this.contractsChangedStatus.add(contractId);
            }
            if(contract.Agent_Lock__c != oldContract.Agent_Lock__c){
                this.contractsChangedAgentLock.add(contractId);
            }
            if(contract.Reprint_Invoice__c != oldContract.Reprint_Invoice__c){
                this.contractsChangedReprintInvoice.add(contractId);
            }
            SL_TriggerUtil.findChangedFields(contractId, contract, oldContract, fieldsChangedById, fieldsToCheck);

            shareContract.checkRecordToShareOrRemove(contract, oldContract, false, this.mapRecordsToShare, this.mapRecordsToRemoveSharing);
        }
    }

    private void assignDefaultAgent(Contract__c contract, String defaultAgentId, Boolean isDisposed){
        contract.Collection_Group__c = null;
        if(!contract.Agent_Lock__c && !isDisposed /* SL-2871 Misael Romero */
        && (contract.Id == null || this.contractsChangedDelinquency.contains(contract.Id))){
            contract.OwnerId = defaultAgentId;
        }
    }

    public static void callCollectionAssignment(){
        if(!System.isBatch()){
            Integer alreadyQueuedJobs = [SELECT COUNT() FROM asyncapexjob 
                WHERE ApexClass.Name LIKE 'SL_CollectionAssignment%' AND (NOT Status IN ('Aborted', 'Completed', 'Failed')) AND ParentJobId = null];
            if(alreadyQueuedJobs == 0){
                System.enqueueJob(new SL_CollectionAssignmentQ());
            }
        }
    }

    void shareCustomerAccountDP(Contract__c contract, Boolean isNewContract, List<String> fieldsChanged, User dealerUser, List<String> dealerAccountIds){
        if((isNewContract || (fieldsChanged != null && (fieldsChanged.contains('Dealer_Name__c')
        || fieldsChanged.contains('Dealer_User__c') /*|| fieldsChanged.contains('OwnerId')*/))) 
        && (contract.Dealer_Name__c != null || contract.Dealer_User__c != null)){
            Id dealerAccountId = contract.Dealer_Name__c != null? contract.Dealer_Name__c: 
                dealerUser != null && dealerUser.Contact != null && dealerUser.Contact.AccountId != null? dealerUser.Contact.AccountId: null;
            if(dealerAccountId != null && !dealerAccountIds.contains(String.valueOf(dealerAccountId))){
                dealerAccountIds.add(dealerAccountId);
            }
        }
    }

    String getWarehouse(List<Warehouse_Mapping__mdt> warehouseMappings, String state, String residualAmountRule){
        String result = 'Omni';
        for(Warehouse_Mapping__mdt warehouseMapping : warehouseMappings){
            if(warehouseMapping.Territory__c == state && warehouseMapping.Residual_Amount__c == residualAmountRule){
                result = warehouseMapping.Warehouse__c;
                break;
            }
        }
        if(result == 'Omni'){
            for(Warehouse_Mapping__mdt warehouseMapping : warehouseMappings){
                if(warehouseMapping.Territory__c == state && warehouseMapping.Residual_Amount__c == null){
                    result = warehouseMapping.Warehouse__c;
                    break;
                }
            }
        }
        return result;
    }

    private static void checkForNintextFlags(List<Contract__c> lstContract, Map<Id, SObject> mapOldContract){
        List<String> lstContractId = new List<String>();
        for(Contract__c contract :lstContract){
            Contract__c oldContract = (Contract__c) mapOldContract.get(contract.Id);
            if(contract.Process_Next_Location__c && !oldContract.Process_Next_Location__c && contract.Locations_Ids__c == null){
                contract.Process_Next_Location__c = false;
                contract.Location_Id__c = null;
            }

            if(contract.Process_Next_Location__c && !oldContract.Process_Next_Location__c && contract.Locations_Ids__c != null){
                List<String> lstLocationIds = contract.Locations_Ids__c.replaceAll(' ', '').split(',');
                contract.Process_Next_Location__c = false;
                contract.Location_Id__c = lstLocationIds[0];
                lstLocationIds.remove(0);
                contract.Locations_Ids__c = String.join(lstLocationIds, ',');
                
                lstContractId.add(contract.Id);
            }
        }

        if(lstContractId.isEmpty()){
            return;
        }

    }

}