global with sharing class SL_DealerRepurchaseController {

    @AuraEnabled
    public static List<Contract_Asset__c> getContractAssets(String contractId){
        List<Contract_Asset__c> contractAssetList = new List<Contract_Asset__c>();
        try {
          contractAssetList = [SELECT Id, Name, Asset_Number__c, Serial_Number__c, Status2__c, Model_Number__c, Invoice_Amount__c, Total_Invoice_Amount__c FROM Contract_Asset__c WHERE Contract__c=:contractId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return contractAssetList;
    }

    @AuraEnabled
public static void updateContractAssets(List<Contract_Asset__c> contractAssets) {
    System.debug('Contract Assets to Update: ' + contractAssets);
    try {
        update contractAssets;
        System.debug('Records updated successfully');
    } catch (Exception e) {
        System.debug('Error updating records: ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}

    @AuraEnabled
    public static String generateInvoice(String contractId, String invoiceAssetsJSON){
        try {

            Contract__c contract = [SELECT Id, Customer__c, Dealer_Name__c, Name, Customer__r.Name, Dealer_Name__r.Name FROM Contract__c WHERE Id = :contractId LIMIT 1];
            //Create Repurchase Invoice record
            Repurchase_Invoice__c newInvoice = new Repurchase_Invoice__c();
            newInvoice.Contract__c=contractId;
            newInvoice.Invoice_Date__c= Date.today();
            newInvoice.Memo__c='Dealer Invoicing';
            newInvoice.Term__c='Net 15';
            newInvoice.Date_Due__c= Date.today().addDays(15);
            newInvoice.Status__c = 'Open';
            newInvoice.Customer2__c = contract.Customer__c;
            newInvoice.Dealer_Account2__c = contract.Dealer_Name__c;
            //insert newInvoice;

            Double amountInvoiced = 0;
            Set<Id> contractAssetIds = new Set<Id>();
            //Create Invoice Asset record for each asset selected on screen. 
            List<contractAssetInvoiceWrapper> contractAssetWrapperList = (List<contractAssetInvoiceWrapper>) JSON.deserialize(invoiceAssetsJSON, List<contractAssetInvoiceWrapper>.class);
            List<Invoice_Asset__c> invoiceAssets = new List<Invoice_Asset__c>();
            for(contractAssetInvoiceWrapper contractAssetWrapper : contractAssetWrapperList){
                Invoice_Asset__c newInvoiceAsset = new Invoice_Asset__c();
                newInvoiceAsset.Invoice__c = newInvoice.Id;
                newInvoiceAsset.Asset__c = contractAssetWrapper.Id;
                newInvoiceAsset.Unit_Price__c = Double.valueOf(contractAssetWrapper.UnitPrice);
                invoiceAssets.add(newInvoiceAsset);
                amountInvoiced = amountInvoiced + newInvoiceAsset.Unit_Price__c;
                contractAssetIds.add(newInvoiceAsset.Asset__c);
            }

            if(invoiceAssets.size()>0){
                //insert invoiceAssets;
            }

            //Update invoice amounts
            List<AggregateResult> results = [SELECT SUM(Net_Sale_Price__c) sumSalesPrice  FROM Contract_Asset__c  WHERE Id IN :contractAssetIds];
            newInvoice.Amount_Invoiced__c = amountInvoiced;
            newInvoice.Amount_Received__c = Double.valueOf(results[0].get('sumSalesPrice')) == null ? 0.00 : Double.valueOf(results[0].get('sumSalesPrice'));
            //update newInvoice;

            Map<ID, Contract_Asset__c> caMap = new Map<ID, Contract_Asset__c>([SELECT Id, Serial_Number__c, Manufacturer__c, Model_Number__c FROM Contract_Asset__c WHERE Id IN:contractAssetIds]);
            //Repurchase_Invoice__c invoice = [SELECT Id, Name,Contract__r.Customer_name__c,  Contract__r.Dealer_Name__r.Name,  Contract__r.Name, Amount_Due__c FROM Repurchase_Invoice__c WHERE ID=:newInvoice.Id LIMIT 1];
            //List<Invoice_Asset__c> invoiceAssetsList = [SELECT Id, Asset__r.Serial_Number__c, Asset__r.Manufacturer__c, Asset__r.Model_Number__c, Unit_Price__c FROM Invoice_Asset__c WHERE Invoice__c = :newInvoice.Id ];
            List<invoiceAssetWrapper> invoiceAssetWrapperList = new List<invoiceAssetWrapper>();

            for(Invoice_Asset__c invoiceAsset : invoiceAssets )
            {
                invoiceAssetWrapper wrapper = new invoiceAssetWrapper();
                //wrapper.Id = invoiceAsset.Id;
                wrapper.Serial = caMap.get(invoiceAsset.Asset__c).Serial_Number__c;
                wrapper.Manufacturer = caMap.get(invoiceAsset.Asset__c).Manufacturer__c;
                wrapper.Model = caMap.get(invoiceAsset.Asset__c).Model_Number__c;
                wrapper.UnitPrice = invoiceAsset.Unit_Price__c;
                wrapper.Asset = invoiceAsset.Asset__c;
                invoiceAssetWrapperList.add(wrapper);
            }


            invoiceWrapper invWrapper = new invoiceWrapper();
            //invWrapper.Id = invoice.Id;
            invWrapper.Customer = contract.Customer__r.Name;
            invWrapper.Dealer = contract.Dealer_Name__r.Name;
            invWrapper.ContractNumber = contract.Name;
            invWrapper.ContractId = contract.Id;
            invWrapper.CustomerId = contract.Customer__c;
            invWrapper.DealerId = contract.Dealer_Name__c;
            invWrapper.Amount = amountInvoiced;
            invWrapper.AmountInvoiced = newInvoice.Amount_Invoiced__c;
            invWrapper.AmountReceived = newInvoice.Amount_Received__c;
            //invWrapper.Name = invoice.Name;
            invWrapper.InvoiceAssets = invoiceAssetWrapperList;

            String serializedInvoice = JSON.serialize(invWrapper);
            return serializedInvoice;


        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public  static string generateInvoiceDocument(String invoiceId, String emails, Boolean ACH, String invoiceJSON, String assetsJSON){

    System.debug('invoiceJSON ' + invoiceJSON  );
    System.debug('assetsJSON: ' + assetsJSON );
    Repurchase_Invoice__c invoice = insertData(invoiceJSON, assetsJSON, emails) ;

      generateInvoiceDocumentService(invoice.Id, 'AttachFile', ACH);
      generateInvoiceDocumentService(invoice.Id, 'Email', ACH); 

      return invoice.Name;
    }



    private static Repurchase_Invoice__c insertData (String invoiceJSON, String assetsJSON, String emails){

      invoiceWrapper invoice = (invoiceWrapper)JSON.deserialize(invoiceJSON, invoiceWrapper.class);
      System.debug('insertData  '  + invoice);
      System.debug('insertData  '  + invoice.ContractNumber);

      //Create Repurchase Invoice record
      Repurchase_Invoice__c newInvoice = new Repurchase_Invoice__c();
      newInvoice.Contract__c=invoice.ContractId;
      newInvoice.Invoice_Date__c= Date.today();
      newInvoice.Memo__c='Dealer Invoicing';
      newInvoice.Term__c='Net 15';
      newInvoice.Date_Due__c= Date.today().addDays(15);
      newInvoice.Status__c = 'Open';
      newInvoice.Customer2__c = invoice.CustomerId;
      newInvoice.Dealer_Account2__c = invoice.DealerId;
      newInvoice.Amount_Received__c = invoice.AmountReceived;
      newInvoice.Amount_Invoiced__c = invoice.AmountInvoiced;
      if(emails.length()>0){
        newInvoice.Email_Recipients__c=emails+','+UserInfo.getUserEmail();
      }
      else{
        newInvoice.Email_Recipients__c=UserInfo.getUserEmail();
      } 
      newInvoice.Repurchase_Invoice_Email__c = emails;
      insert newInvoice;


      List<invoiceAssetWrapper> invoiceAssetWrappers = invoice.InvoiceAssets;
      System.debug('invoiceAssets deserialized ' + invoiceAssetWrappers);
      List<Invoice_Asset__c> invoiceAssets = new List<Invoice_Asset__c>();

      //Create the invoice assets 
      for(invoiceAssetWrapper iaWrapper : invoiceAssetWrappers) {
        Invoice_Asset__c newInvoiceAsset = new Invoice_Asset__c();
        newInvoiceAsset.Invoice__c = newInvoice.Id;
        newInvoiceAsset.Asset__c = iaWrapper.Asset;
        newInvoiceAsset.Unit_Price__c = Double.valueOf(iaWrapper.UnitPrice);
        invoiceAssets.add(newInvoiceAsset);
      }

      insert invoiceAssets;

      //Retrieve Invoice name 
      Repurchase_Invoice__c insertedInvoice = [SELECT Id, Name, Contract_Attachment__c, Contract__r.Customer__c FROM Repurchase_Invoice__c WHERE Id=:newInvoice.Id LIMIT 1];
      //Create the Related Contract Attachment record
      Contract_Attachment__c relatedContractAttachment = new Contract_Attachment__c();
      relatedContractAttachment.Contract__c = newInvoice.Contract__c;
      relatedContractAttachment.Type_Group__c = 'Asset Management';
      relatedContractAttachment.Type__c = 'AM - Dealer Repurchase Invoices';
      relatedContractAttachment.Name = 'Repurchase Invoice '+insertedInvoice.Name;
      insert relatedContractAttachment;


      //Link Contract Attachment with Repurchase Invoice
      insertedInvoice.Contract_Attachment__c = relatedContractAttachment.Id;
      update insertedInvoice;


      //Creating task for automatic notation as requested in SL-2204
      Task taskRecord =  new Task();
      taskRecord.Contract__c =invoice.ContractId;
      taskRecord.WhatId = insertedInvoice.Contract__r.Customer__c;
      taskRecord.Type ='Other';
      taskRecord.ActivityDate =Date.today();
      taskRecord.Description ='Repurchase Invoice #' + insertedInvoice.Name +' has been created and $' +  newInvoice.Amount_Invoiced__c +' is due.';
      taskRecord.Status ='Completed';
      insert taskRecord;


      return insertedInvoice;

    }






    @Future(callout=true)
    webservice static void generateInvoiceDocumentService(String invoiceId, String deliveryOption, Boolean ACH) {
      List<string> lstResult = new List<string>();
      try {
      String packageName =  '';
      Dealer_Repurchase_Settings__c repurchaseSettings= Dealer_Repurchase_Settings__c.getOrgDefaults();
      // CHANGE ANY FILTER (the WHERE clause) CRITERIA NECESSARY
      if(ACH){
        packageName = repurchaseSettings.ACH_Docgen_Package_Name__c;
      }
      else{
        packageName = repurchaseSettings.Docgen_Package_Name__c;
      }
      List<Loop__DDP__c> lstDdps = [SELECT Id, (SELECT Id FROM Loop__Custom_Integration_Options__r WHERE Name = :deliveryOption) FROM Loop__DDP__c WHERE Name=:packageName];
      List<Repurchase_Invoice__c> lstInvoice = [SELECT Id, Email_Recipients__c, Contract__c, Name FROM Repurchase_Invoice__c WHERE Id =:invoiceId];
      
      if (lstDdps.isEmpty()) {
        // CHANGE THE EXCEPTION MESSAGE IF DESIRED
        System.debug('ERROR: A DDP specified was not found.');
        //throw new MissingDDPInfoException('A DDP specified was not found.');
      }
      Loop.loopMessage lm = new Loop.loopMessage();      
      // SESSION ID NEEDED IF IT CANNOT BE DETERMINED FROM UserInfo.getSessionId()
      lm.sessionId = UserInfo.getSessionId();      
      // SET DESIRED BATCH NOTIFICATION. IF THIS IS NOT DONE, THE DEFAULT IS 'NONE'
      // THIS IS AVAILABLE IN LOOP 6.7 / 9.56 AND ABOVE
      //lm.batchNotification = Loop.loopMessage.Notification.BEGIN_AND_COMPLETE;
      //lm.batchNotification = Loop.loopMessage.Notification.ON_ERROR;
      //lm.batchNotification = Loop.loopMessage.Notification.ON_COMPLETE;     

      for(Loop__DDP__c ddp : lstDdps){
        if (ddp.Loop__Custom_Integration_Options__r == null || ddp.Loop__Custom_Integration_Options__r.size() < 1) {
          // CHANGE THE EXCEPTION MESSAGE IF DESIRED
          System.debug('ERROR: A Delivery Option specified was not found.');

          //throw new MissingDDPInfoException('A Delivery Option specified was not found.');
        }
        System.debug('ddpId '+ ddp.Id);


        Id deliveryId = ddp.Loop__Custom_Integration_Options__r[0].Id;
          for(Repurchase_Invoice__c invoice :lstInvoice){
              lm.requests.add(new Loop.loopMessage.loopMessageRequest(
              invoice.Id, // MAIN RECORD ID - SAME OBJECT AS THE DDP RECORD TYPE SPECIFIES
              ddp.Id, // DDP ID
              new Map<string, string>{
                'deploy' => deliveryId,
                'SFRepurchase_Invoice__c' => invoice.Id,
                'SFContact' => repurchaseSettings.ContactId__c,
                'SFContract__c' => invoice.Contract__c
                // THESE PARAMETERS ARE THE SAME AS THOSE FOUND IN OUR OUTBOUND MESSAGE DOCUMENTATION
                // PLEASE REFERENCE THAT DOCUMENTATION FOR ADDITIONAL OPTIONS
                // 'SFObject_Name__c' => recordId
                //,'attachIds' => invoice.Id
                // 'deploytype' => 'autodocusign' // IF deploy IS A DOCUSIGN DELIVERY OPTION ID
                //, 'deploytype' => 'autoemail' // IF deploy IS AN EMAIL DELIVERY OPTION ID
              }
            ));
          }

      }
      // ADD RETRY LOGIC TO HANDLE TRANSIENT ERRRORS
      Integer attempts = 1;
      Boolean success = false;
      while(!success && attempts <= 3) {
        try {
          // SEND ALL DDP RUN REQUESTS IN A SINGLE CALL OUT
          String requestResponse = lm.sendAllRequests();
          success = true;        
        } catch (CalloutException e) {
          System.debug('loopMessage request failed. Cause: ' + e.getMessage());
        }
        attempts ++;
      }
      
      lstResult.add('Your requests are being processed.');
      lstResult.add('Repurchase');

        
      } catch (Exception e) {
        System.debug('EXECPTION ' +  e.getLineNumber() + ' ' + e.getMessage());
      }
      
      //return lstResult;
  }


    public with sharing class contractAssetInvoiceWrapper {        
        public String Id { get; set; }        
        public String UnitPrice { get; set; }
    }  


    public with sharing class invoiceWrapper {        
        public String Id { get; set; }        
        public String Customer { get; set; }
        public String Dealer { get; set; }
        public String ContractNumber { get; set; }
        public Double Amount { get; set; }
        public Double AmountInvoiced { get; set; }
        public Double AmountReceived { get; set; }
        public String Name { get; set; }
        public String ContractId { get; set; }
        public String CustomerId { get; set; }
        public String DealerId { get; set; }

        public List<invoiceAssetWrapper> InvoiceAssets { get; set; }
    } 
    
    public with sharing class invoiceAssetWrapper {        
        public String Id { get; set; }        
        public String Serial { get; set; }
        public String Manufacturer { get; set; }
        public String Model { get; set; }
        public String Asset { get; set; }
        public Double UnitPrice { get; set; }
    }  



}