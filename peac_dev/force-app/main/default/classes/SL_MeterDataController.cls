public with sharing class SL_MeterDataController {

    @AuraEnabled
    public static string getMeterReadData(String dealerNumber){
      try {

        String response;
        //String dealerNumber;
        User currentUser =  [SELECT Id, Name,  Account.Dealer_Number__c FROM User WHERE Id=:UserInfo.getUserId()];  
        //if(currentUser.Account.Dealer_Number__c != null)  dealerNumber = currentUser.Account.Dealer_Number__c.replace('.', '');
        //Migration
       // String body ='{\"Header\": {\"NitroApi\": \"BW.RETURN.METER.READS\"},\"Request\": {\"ContDealer\": [\"9738124400\", \"9738122066\"]}}';


       //Fullcopy
      // String body ='{\"Header\": {\"NitroApi\": \"BW.RETURN.METER.READS\"},\"Request\": {\"ContDealer\": [\"7182369223\", \"9738122066\"]}}';


      String body ='{\"Header\": {\"NitroApi\": \"BW.RETURN.METER.READS\"},\"Request\": {\"ContDealer\": [\"'+dealerNumber+'\"]}}';
        response = sl_summaryandDetail.callBridgeware(body, currentUser.AccountId, true, false, true);
        System.debug('RESPONSE '+response);
        if(!Test.isRunningTest())response = response.substringBetween('{"MeterReadings":',',"Errors"');
  
        return response;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }



    @AuraEnabled
    public static List<Account> getAccountHierarchy(){
      try {
        User currentUser =  [SELECT Id, Name,  AccountID FROM User WHERE Id=:UserInfo.getUserId()];  
        List<Account> accountsList = SL_ExternalAccountHierarchyService.getAccountHierarchy(currentUser.AccountId);
        for (Integer i = (accountsList.size()-1) ; i>= 0 ; i--){
          Account acc  = accountsList[i];
          if(acc.Dealer_Number__c != null){
            acc.Dealer_Number__c = acc.Dealer_Number__c.replace('.', '');
          }
          else{
            accountsList.remove(i);
          }
      } 
    
  
        return accountsList;
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }

    
  
    @AuraEnabled
    public static string dwCSVtoJson(String base64){
      try {        
        Dataweave.Script dwscript = DataWeave.Script.createScript('meterData');
        DataWeave.Result result = dwscript.execute(new Map<String, Object>{'meterData' => EncodingUtil.base64Decode(base64)});
        return result.getValueAsString();
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }
      

  
    @AuraEnabled
    public static void sendMeterFile(String csv, String dealerNumber){

      try {
      //Get dealer number and date to set the file name
      //String dealerNumber;
      User currentUser =  [SELECT Id, Name,  Account.Dealer_Number__c FROM User WHERE Id=:UserInfo.getUserId()];      
      //if(currentUser.Account.Dealer_Number__c != null)  dealerNumber = currentUser.Account.Dealer_Number__c.replace('.', '');
   


      String dt = DateTime.now().format('YYYYMMdd_hhmm');
      //Set the file name
      String fileName = dt+'_mmrdata_'+dealerNumber+'.csv'; //format: yyyymmdd_hhmm_mmrdata_dealerid.csv
      String fileContent = csv;
      String separationString = '-----------------------------';

      // assemble the meter read file 
      String header = '--' + separationString + '\nContent-Disposition: form-data; name="file"; filename="' + fileName + '"\nContent-Type: text/plain\n\n';
    
      String footer = '\n--' + separationString + '--';
      String bodyMeterReads = header + fileContent + footer;

      // send out the request
      DP_API_Config__c mc = DP_API_Config__c.getOrgDefaults();
      HttpRequest req = new HttpRequest();
      req.setEndpoint('callout:DP_MCS'+'/UploadMeterRead?RequestType=DP');
      req.setHeader('x-api-key', mc.API_Key__c);
      req.setHeader('Content-Type', 'multipart/form-data; boundary=' + separationString);
      req.setMethod('POST');
      req.setBody(bodyMeterReads);  
      req.setTimeout(120000);

      Http http = new Http();
      if(!Test.isRunningTest()){
        HTTPResponse res = http.send(req);
      }

      }
      catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }      
    }

    @AuraEnabled
    public static string generateFileLink(String fileName, String dealerNumber, String requestType)
    {

        string folder;
        //string dealerNumber;

        if(fileName.contains('.pdf')) folder = 'pdf';
        if(fileName.contains('.csv')) folder = 'csv';
        if(fileName.contains('.txt')) folder = 'txt';
        if(fileName.contains('.csv') && fileName.contains('InvoiceData') ) folder = 'csv_invoiceData';
        if(fileName.contains('.csv') && fileName.contains('Success') ) folder = 'csvSuccess';
        if(fileName.contains('.csv') && fileName.contains('Failure') ) folder = 'csvFailure';
        if(fileName.contains('.csv') && fileName.contains('Exception') ) folder = 'csv_Exception';



        User currentUser =  [SELECT Id, Name,  Account.Dealer_Number__c FROM User WHERE Id=:UserInfo.getUserId()];  
        //if(currentUser.Account.Dealer_Number__c != null)  dealerNumber = currentUser.Account.Dealer_Number__c.replace('.', '');


        Azure_Blob_Storage_Setting__c absSetting = Azure_Blob_Storage_Setting__c.getOrgDefaults();
        string storageName = absSetting.Storage_Name__c;
        string storageContainer = absSetting.Storage_Container__c+ dealerNumber+ '/'+ folder;
        string storageKey = absSetting.Storage_Key__c;
        string storageUrl = absSetting.Storage_URL__c;
        
        //MISC
        if(requestType == 'MISC'){
          storageContainer = absSetting.MISC_Storage_Container__c+folder;
        }

        Datetime sasExpiry = Datetime.now();
        sasExpiry = sasExpiry.addMinutes(60);
        Datetime sasStart = Datetime.now();
        sasStart = sasStart.addMinutes(-5);


        string signedpermissions = 'r';
        String signedstart = sasStart.formatGMT('YYYY-MM-dd\'T\'HH:mm:ss\'Z\'');
        string signedexpiry = sasExpiry.formatGMT('YYYY-MM-dd\'T\'HH:mm:ss\'Z\'');
        string signedservice = 'b';
        String canonicalizedresource = '/blob/'+storageName+'/'+storageContainer+'/'+filename;

        string signedidentifier = '';
        string signedIP = '';
        string signedProtocol = '';
        string signedversion = '2015-04-05';
        string rscc='';
        string rscd='';
        string rsce='';
        string rscl='';
        string rsct='';


        string stringToSign =signedpermissions + '\n' +  
            signedstart + '\n' +  
            signedexpiry + '\n' +  
            canonicalizedresource + '\n' +  
            signedidentifier + '\n' +  
            signedIP + '\n' +  
            signedProtocol + '\n' +  
            signedversion + '\n' +  
            rscc + '\n' +  
            rscd + '\n' +  
            rsce + '\n' +  
            rscl + '\n' +  
            rsct;
        //System.debug('stringToSign--->'+stringToSign);
        string signedExpiryEncode = EncodingUtil.urlEncode(signedexpiry, 'UTF-8'); 
        string signedStartEncode = EncodingUtil.urlEncode(signedstart, 'UTF-8'); 
        String sasToken = '';
        Blob unicodeKey = EncodingUtil.base64Decode(storageKey);
        Blob data = Crypto.generateMac('HMACSHA256', Blob.valueOf(stringToSign), unicodeKey);
        sasToken = EncodingUtil.base64Encode(data);
        sasToken = EncodingUtil.urlEncode(sasToken, 'UTF-8');        
        String sasTokenString= '?sv=' + signedversion + '&se=' + signedexpiry +'&st='+signedstart+'&sr='+signedservice+'&sp=' + signedpermissions + '&sig=' + sasToken;

        string sasURL = storageUrl+'/'+ storageContainer+'/'+filename+sasTokenString;

        System.debug('sasURL'+sasURL);

        return sasURL;
    }

    @AuraEnabled
    public static string getLogFiles(String dealerNumber, String requestType){
      try {
        String testResponse = '{    \"status\": true,    \"msg\": [        {            \"_id\": \"66c60939e5e5c3728e5d3a34\",            \"date\": \"2024-08-21T15:35:21.000Z\",            \"csv\": \"20240821_113521_mmrdata_2484149955.csv\",            \"mmr_missing\": \"N/A\",            \"pdf\": \"N/A\",            \"txt_old\": \"N/A\",            \"txt\": \"20240821_113520_mmrdata_2484149955.txt\",            \"modifiedAt\": null,            \"modifiedBy\": null,            \"requestType\": \"DealerPortal\",            \"reran\": false,            \"uuid\": \"8104893046771323539\",            \"dealerNo\": \"2484149955\",            \"__v\": 0        },        {            \"_id\": \"66c4a98ad6d151bc63eeaf6f\",            \"date\": \"2024-08-20T14:34:50.000Z\",            \"csv\": \"20240820_103454_mmrdata_2484149955.csv\",            \"mmr_missing\": \"N/A\",            \"pdf\": \"20240820_103440_nmrdata_2484149955.pdf\",            \"txt_old\": \"N/A\",            \"txt\": \"20240820_103454_mmrdata_2484149955.txt\",            \"modifiedAt\": null,            \"modifiedBy\": null,            \"requestType\": \"DealerPortal\",            \"reran\": false,            \"uuid\": \"7012532820508489154\",            \"dealerNo\": \"2484149955\",            \"__v\": 0        }    ]}';
        String dataJSON='';
        String response;
        //String dealerNumber;
        String JSONResponse='';
        Azure_Blob_Storage_Setting__c absSetting = Azure_Blob_Storage_Setting__c.getOrgDefaults();
        System.debug('getLogFiles:  ' + dealerNumber);
        User currentUser =  [SELECT Id, Name,  Account.Dealer_Number__c FROM User WHERE Id=:UserInfo.getUserId()];  
        //if(currentUser.Account.Dealer_Number__c != null)  dealerNumber = currentUser.Account.Dealer_Number__c.replace('.', '');
        String body = '{\"type\": \"'+requestType+'\",\"dealerNo\": '+dealerNumber+'}';

        if(requestType == 'MISC') body = '{\"type\": [\"AP\", \"INE\"] ,\"dealerNo\": '+dealerNumber+'}';

        //Get the logs of the uploaded files
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(absSetting.Logs_URL__c);
        req.setBody(body);
        Http http = new Http();
        if(Test.isRunningTest()){
          JSONResponse = testResponse.replace('"date":', '"logDateString":');
        }
        else{
          HTTPResponse res = http.send(req);
          JSONResponse = res.getBody().replace('"date":', '"logDateString":');
        }


        LogResponseWrapper reqWrapper = (LogResponseWrapper)JSON.deserialize(JSONResponse, LogResponseWrapper.class);

        if(reqWrapper.status == 'true' && reqWrapper.msg.size()>0)
        {
        List<Log> logs = reqWrapper.msg;

        //Sort logs by date

        for(Log log : logs){
          String dtString = log.logDateString.replace('T', ' ');
          Datetime dt = DateTime.valueOfGMT(dtString);
          log.logDate = dt;

        }
        logs.sort();
        logs.sort(new LogComparator());
        //Extract the files from each log and create the link to download them from Azure Blob Storage

        List<File> files = new List<File>();
        for(Log log : logs){
          if(log.pdf != null && String.valueOf(log.pdf).contains('.pdf')){
            File pdfFile = new File();
            pdfFile.name = log.pdf;
            files.add(pdfFile);

          }
          if(log.csv != null && String.valueOf(log.csv).contains('.csv')){
            File csvFile = new File();
            csvFile.name = log.csv;
            files.add(csvFile);
          }

          if(log.txt != null && String.valueOf(log.txt).contains('.txt')){
            File txtFile = new File();
            txtFile.name = log.txt;
            files.add(txtFile);
          }

          if(log.csv_invoiceData != null && String.valueOf(log.csv_invoiceData).contains('.csv')){
            File csvFile = new File();
            csvFile.name = log.csv_invoiceData;
            files.add(csvFile);
          }

          if(log.csvSuccess != null && String.valueOf(log.csvSuccess).contains('.csv')){
            File csvFile = new File();
            csvFile.name = log.csvSuccess;
            files.add(csvFile);
          }

          if(log.csvFailure != null && String.valueOf(log.csvFailure).contains('.csv')){
            File csvFile = new File();
            csvFile.name = log.csvFailure;
            files.add(csvFile);
          }

          
          if(log.csv_Exception != null && String.valueOf(log.csv_Exception).contains('.csv')){
            File csvFile = new File();
            csvFile.name = log.csv_Exception;
            files.add(csvFile);
          }

        }

        dataJSON = JSON.serialize(files);


        }
        System.debug('getLogFiles dataJSON:  ' + dataJSON);

        return dataJSON;
  
        //return response;
      } catch (Exception e) {
        System.debug('ERROR: ' + e.getMessage() );
        throw new AuraHandledException(e.getMessage());
      }
    }

    class LogResponseWrapper {
      public String status;
      public List<Log> msg { get; set; }
    }

    public class Log implements Comparable {
        public String logDateString;
        public String uuid;
        public String csv;
        public String txt;
        public String pdf;
        public String csv_invoiceData;
        public String csvSuccess;
        public String csvFailure;
        public String csv_Exception;
        public Datetime logDate;

      // Implement the compareTo() method
        public Integer compareTo(Object compareTo) {
          Log compareToLog = (Log)compareTo;
          if (logDate == compareToLog.logDate) return 0;
          if (logDate < compareToLog.logDate) return 1;
          return -1;        
      }
      }

    class File {
        public String name;
        public String size;
        public String url;
    }

    class LogComparator implements Comparator<Log> {

      public Integer compare(Log log0, Log log1) {
          if(log0.logDate == null) return 1;
          if(log1.logDate == null) return -1;
          return log0.logDate > log1.logDate ? -1 : 1;
      }
  }


  }