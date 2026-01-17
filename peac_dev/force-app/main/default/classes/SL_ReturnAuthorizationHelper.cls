/**
*
* Summary:       This helper contains methods used in the LWC sL_BiewBuyout
* Author:        -
* Created:       -
* Test Class:    SL_ReturnAuthorizationHelperTest
* History
* <Date>        <Authors Name>          <Jira#>      <Brief Description of Change>
* 09/27/2024     Paul Trujillo          SL-2242       Adding method to create returnAuthorization pdf and attach it to the buyout and contract
**/
public without sharing class SL_ReturnAuthorizationHelper {

    @AuraEnabled
    public static String updateContractAssets(String recordId, String quoteSeq)
    {
        SL_PartialBuyout.checkExistingFullBAssets(recordId, quoteSeq);
        String result = '';
        Contract__c contract = [SELECT ID, IsXBS__c  FROM Contract__c WHERE Id = :recordId LIMIT 1];
        List<Contract_Asset__c> contractAssets = [SELECT Id, Equipment_Type__c, Equipment_Subtype__c, Asset_State__c, Location__c, Service_Provider__c, Asset_Disposed_Date__c FROM Contract_Asset__c WHERE Contract__c = :recordId AND Asset_Disposed_Date__c=null];
        List<Remarketer_Matrix_Obj__c> remarketers = [SELECT Id, Equipment_Type__c, Equipment_Subtype__c, State__c, Return_Warehouse_Code__c, Service_Provider__c, Location__c FROM Remarketer_Matrix_Obj__c];

        List<String> locationCodes = new List<String>();
        Boolean isUpdateNeeded = false;
        //Is needed to create this data here as Custom Metadata Type cannot be created from test class.
        if(Test.isRunningTest()){
            locationCodes.add('TestLocation');
            Schema.Location testLocation = new Schema.Location(Name='TestLocation');
            insert testLocation;
        }        
        //getLocationCodes
        try{
            for(Contract_Asset__c ca : contractAssets)
            {         
    
                for(Remarketer_Matrix_Obj__c rmkt : remarketers)
                {
                    if(ca.Equipment_Subtype__c == rmkt.Equipment_Subtype__c && ca.Asset_State__c == rmkt.State__c && ca.Equipment_Type__c == rmkt.Equipment_Type__c)
                    {
                                isUpdateNeeded = true;//Indicates if there are matching values in the remarketer matrix
                        if(ca.Location__c == null)ca.Location__c = rmkt.Location__c;
                        if(ca.Service_Provider__c != rmkt.Service_Provider__c)ca.Service_Provider__c = rmkt.Service_Provider__c;
                                ca.Return_Authorization__c = true;
                                if(ca.Asset_Disposed_Date__c == null)ca.Return_Auth_Create_Date__c = Date.today();
                            } 
                    
                }
            }
    
        if(isUpdateNeeded)
        {
            update contractAssets;
            result = 'OK';
        }
        else {
            if(contractAssets.size()>0 ){
                result = 'Verify the following fields: '
                + 'Equipment type = Office Equipment(General).  '
                + 'Equipment Subtype = Copiers.  '
                + 'Asset state is not Blank.';
            }
            else{
                result = 'OK';
            }

        }
    }catch(Exception e){
            System.debug('ERROR ' + e.getMessage());
        }
        
        return result;
    }


    @AuraEnabled
    public static void checkReturnAuthorizationContractAssets(String contractId, String buyoutSeq)
    {
        System.debug('In checkReturnAuthorizationContractAssets - contractId: ' + contractId);
        System.debug('In checkReturnAuthorizationContractAssets - buyoutSeq: ' + buyoutSeq);
        Map<Id, Contract_Asset__c> contractAssetsToUpdate = new Map<Id, Contract_Asset__c>();
        Contract__c contract = [SELECT Id, Name FROM Contract__c WHERE Id = :contractId];
        List<Buyout__c> buyouts = [
            SELECT Id, Name, Partial_Buyout__c, Contract__r.Name
            FROM Buyout__c
            WHERE Contract__c = :contractId AND Quote_Sequence__c = :buyoutSeq
        ];


        System.debug('In checkReturnAuthorizationContractAssets - buyouts: ' + buyouts);
        addReturnAuthorizationPDFToBuyout(contractId, contract.Name, buyoutSeq);
        

        if (!buyouts.isEmpty() && buyouts[0].Partial_Buyout__c) {

            List<Buyout_Asset__c> buyoutAssets = [
                SELECT Contract_Asset__c, Contract_Asset__r.Return_Authorization__c, Contract_Asset__r.Return_Auth_Create_Date__c, Contract_Asset__r.Asset_Disposed_Date__c
                FROM Buyout_Asset__c
                WHERE Buyout__c = :buyouts[0].Id
            ];

            for (Buyout_Asset__c buyoutAsset : buyoutAssets) {
                if(!contractAssetsToUpdate.containsKey(buyoutAsset.Contract_Asset__c)) {

                    Contract_Asset__c contractAsset = new Contract_Asset__c(Id = buyoutAsset.Contract_Asset__c);
                    contractAsset.Return_Authorization__c = true;
                    if(buyoutAsset.Contract_Asset__r.Asset_Disposed_Date__c == null){
                    contractAsset.Return_Auth_Create_Date__c = Date.today();
                    contractAsset.Status2__c = 'Pending Return';
                    }

                    contractAssetsToUpdate.put(buyoutAsset.Contract_Asset__c, contractAsset);
                }

            }
        } else {
            Map<ID, Contract_Asset__c> m = new Map<ID, Contract_Asset__c>([SELECT Id, Return_Authorization__c, Return_Auth_Create_Date__c, Status2__c, Asset_Disposed_Date__c
            FROM Contract_Asset__c
            WHERE Contract__c = :contractId]);       
            contractAssetsToUpdate = m;            
            for (Id contractAssetId : contractAssetsToUpdate.keySet()) {
                contractAssetsToUpdate.get(contractAssetId).Return_Authorization__c = true;
                if(contractAssetsToUpdate.get(contractAssetId).Asset_Disposed_Date__c == null){
                    contractAssetsToUpdate.get(contractAssetId).Return_Auth_Create_Date__c = Date.today();
                    contractAssetsToUpdate.get(contractAssetId).Status2__c = 'Pending Return';
                }

            }
        }
        System.debug('contractAssetsToUpdate ' + contractAssetsToUpdate);
        if(!contractAssetsToUpdate.isEmpty()) update contractAssetsToUpdate.values();
    }

    /**
    *
    * Summary:       Create the Return Authorization PDF and related it to the buyout and the contract.
    * Inputs:        String contractId, String contractName, String buyoutSeq, Id buyoutID
    * Returns:       void
    * Author:        Paul Trujillo 
    * Created:       10/17/2024
    * History
    * <Date>        <Authors Name>          <Jira#>      <Brief Description of Change>
    * 09/27/2024     Paul Trujillo          SL-2242          Initial version.
    */
    public static void addReturnAuthorizationPDFToBuyout(Id contractId, String contractName, String buyoutSeq)
    {
        System.debug('addReturnAuthorizationPDFToBuyout contractId::'+contractId+' contractName::'+contractName+' buyoutSeq::'+buyoutSeq);
        if (contractId != null) {
            PageReference reportPage = (PageReference) Page.SL_ReturnAuthorization;
            reportPage.getParameters().put('contractId', contractId);
            reportPage.getParameters().put('buyoutSeq', buyoutSeq);
            Blob reportPdf;
            try {
                if(Test.isRunningTest()){
                    reportPdf = Blob.valueOf('Test');
                } else {
                    reportPdf = reportPage.getContentAsPDF();
                }
                //Check if document already exist
                String fileTitle = 'Return_Authorization_'+contractName+'_'+buyoutSeq+'.pdf';
                
                Contract_Attachment__c relatedContractAttachment = new Contract_Attachment__c();
                relatedContractAttachment.Contract__c = contractId;
                relatedContractAttachment.Type_Group__c = 'Asset Management';
                relatedContractAttachment.Type__c = 'AM - Return Authorization';
                relatedContractAttachment.Name = fileTitle;
                insert relatedContractAttachment;
                

                String result = SL_UploadAttachment.saveAttachment(relatedContractAttachment.Id, fileTitle, EncodingUtil.urlEncode(EncodingUtil.base64Encode(reportPdf), 'UTF-8'));
                System.debug('result::'+result);
                SL_OnBaseCallout.sendRapportAttachmentToOnBase(contractId, true);
            } catch(Exception ex) {
                System.debug('Exception::message::'+ex.getMessage());
                System.debug('Exception::stackTrace::'+ex.getStackTraceString());
            }
        }
    }


    @AuraEnabled
    public static string returnAuthorizationRequest(String buyoutId){
        try {
            User currentUser = [SELECT Id, ContactId FROM User WHERE Id=:UserInfo.getUserId()];
            Group queue = new Group();
            Buyout__c buyout = [SELECT Id, Name, Contract__c, Contract__r.Customer_name__c, Buyout_Amount__c, Buyout_Type__c, Contract__r.Name, Contract__r.IsXBS__c, Date_Quoted__c, Expiration_Date__c FROM Buyout__c WHERE Id =:buyoutId];
            System.debug('buyout type '+ buyout.Buyout_Type__c);

            List<PEAC_BuyoutPrettyNames__mdt> buyoutPrettyName = [SELECT DeveloperName, Buyout_Type__c, Pretty_Name__c, Type__c FROM PEAC_BuyoutPrettyNames__mdt WHERE Type__c = :buyout.Buyout_Type__c LIMIT 1];

            if(!buyout.Contract__r.IsXBS__c)
            {
                queue = [SELECT Id, Name FROM Group WHERE Name = 'Vendor Servicing' AND Type = 'Queue'];
            }
            else
            {
                queue = [SELECT Id, Name FROM Group WHERE Name = 'XBS Vendor Support' AND Type = 'Queue'];
            }    
            String buyoutType =  buyoutPrettyName.size() > 0? buyoutPrettyName[0].Buyout_Type__c: buyout.Name;       
            Case RArequest = new Case();
            RArequest.ContactId = currentUser.ContactId;
            RArequest.Buyout__c = buyoutId;
            RArequest.Contract_custom__c = buyout.Contract__c;
            RArequest.Subject = 'Dealer Return Instruction Request for ' + buyout.Contract__r.Customer_name__c;
            RArequest.Description = 'Contract Number: '+ buyout.Contract__r.Name +' \n'
            +'Buyout Type: '+  buyoutType  +' \n'
            +'Quote Type: '+ buyout.Buyout_Type__c +' \n'
            +'Quote total: $'+String.valueOf(buyout.Buyout_Amount__c)+' \n'            
            +'Buyout Date: '+  String.valueOf(buyout.Date_Quoted__c.month())+ '/'+ +  String.valueOf(buyout.Date_Quoted__c.day())+ '/'+ +  String.valueOf(buyout.Date_Quoted__c.year())+ '/'+ ' \n'
            +'Expired Date: '+ String.valueOf(buyout.Expiration_Date__c.month())+ '/'+ +  String.valueOf(buyout.Expiration_Date__c.day())+ '/'+ +  String.valueOf(buyout.Expiration_Date__c.year())+ '/'+ ' \n'
            + 'Please see request for return instructions. Please review account to validate if return instructions can be provided to dealership. All term payments must be made, LOI must be submitted on time or Customer buyout to return payment has been received.';
            if(!Test.isRunningTest())RArequest.OwnerId = queue.Id;
            insert RArequest;
            return RArequest.Id;

        } catch (Exception e) {
            System.debug('ERROR '+ e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}