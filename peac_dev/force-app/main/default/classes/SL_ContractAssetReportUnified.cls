public class SL_ContractAssetReportUnified implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    List<Messaging.SingleEmailMessage> emailsToSend;
    private Set<ID> providers = new Set<ID>();
    private Map<String,String> providersToDocMap = new Map<String,String>();
    private String columnHeaders='Dealer Name, Contract Name, Customer Name, Address, Manufacturer, Model#, Serial#, Partner Location, Return Authorization Created Date, Service Provider\n';
    private List<Account> providersAcc = new List<Account>();
    private Map<String,String>contentDocumentIds = new Map<String,String>();
    private Map<String,String>contentVersions = new Map<String,String>();
    private Map<String,String> providerName = new Map<String,String>();
    public Database.QueryLocator start(Database.BatchableContext bc){        
        for(AggregateResult ar:[Select Service_Provider__c from Contract_Asset__c Where Return_Authorization__c = true AND Service_Provider__c != NULL Group by Service_Provider__c]){
            this.providers.add(String.ValueOf(ar.get('Service_Provider__c')));
        }
        System.debug('provider Ids:');
        System.debug(providers);
        providersAcc = [Select Id, Name from Account Where Id In:providers];
        String query = 'Select Id, Service_Provider__c, Model_Number__c, Serial_Number__c, Return_Auth_Create_Date__c, Asset_Address_1__c, Asset_City__c, Asset_Zip_Code__c, Asset_State__c, Location__c, Location__r.Name, Contract__c, Contract__r.Dealer_Name__c, Contract__r.Dealer_Name__r.Name, Contract__r.Name, Contract__r.Customer__c, Contract__r.Customer__r.Name, Manufacturer__c From Contract_Asset__c Where Service_Provider__c IN:providers AND Return_Authorization__c = true AND Return_Auth_Create_Date__c =YESTERDAY';
        return Database.getQueryLocator(query);   
    }
    
    public void execute(Database.BatchableContext bc, List<sObject>ContractAssets){        
        //Map<String,List<Contract_Asset__c>> assetsByProviders = new Map<String,List<Contract_Asset__c>>();
        System.debug('Contract Assets:');
        System.debug(ContractAssets);
        List<ContentVersion> documents = new List<ContentVersion>();
        List<String>cvIds = new List<String>();
        System.debug('Providers in execute');
        System.debug(providers);
        for(String providerId:this.providers){
            String ProviderAccNAme;
            for(Account ac: this.providersAcc){
                if(ac.Id == providerId){
                    ProviderAccNAme = ac.Name.escapeCsv();
                    providerName.put(ac.Id,ProviderAccNAme);
                }
            }
        }
            String ReturnAddress;
        	ContentVersion doc = new ContentVersion();
            List<Contract_Asset__c> assets = new List<Contract_Asset__c>();
            List<String>rowValues=new List<String>();
            for(SObject obj:ContractAssets){
                Contract_Asset__c ca = (Contract_Asset__c)obj;
                assets.add(ca);                               
            }
            System.debug('Asset Size');
            System.debug(assets.size());
            if(assets.size()>0){
                for(Contract_Asset__c cons:assets){
                    String servProv = providerName.get(cons.Service_Provider__c);
                	String formatedDate = String.valueOf(cons.Return_Auth_Create_Date__c);
                	String addressString = cons.Asset_Address_1__c + ' ' + cons.Asset_City__c + ' ' + cons.Asset_State__c + ' '+ cons.Asset_Zip_Code__c ;
                    String rowData;
                    String manufacturer ='';
                    if(cons.Manufacturer__c != NULL){
                        manufacturer = cons.Manufacturer__c.escapeCsv();
                    }
                    if(cons.Location__c<>null){
                        // SL-2683 - Carlos Herrera
                        if(cons.Contract__r.Customer__c <> null){
                      rowData=cons.Contract__r.Dealer_Name__r.Name.escapeCsv()+','+cons.Contract__r.Name+','+cons.Contract__r.Customer__r.Name.escapeCsv()+','+addressString.escapeCsv()+ ',' + manufacturer+','+cons.Model_Number__c+','+cons.Serial_Number__c+','+cons.Location__r.Name.escapeCsv()+','+formatedDate+','+servProv;  
                    }else{
                            rowData=cons.Contract__r.Dealer_Name__r.Name.escapeCsv()+','+' '+','+addressString.escapeCsv()+ ',' + manufacturer+','+cons.Model_Number__c+','+cons.Serial_Number__c+','+cons.Location__r.Name.escapeCsv()+','+formatedDate+','+servProv;
                        }
                        
                    }else{
                        // SL-2683 - Carlos Herrera
                        if(cons.Contract__r.Customer__c <> null){
                        rowData=cons.Contract__r.Dealer_Name__r.Name.escapeCsv()+','+cons.Contract__r.Name+','+cons.Contract__r.Customer__r.Name.escapeCsv()+','+addressString.escapeCsv()+ ',' + manufacturer+','+cons.Model_Number__c+','+cons.Serial_Number__c+','+' '+','+formatedDate+','+servProv;
                        }else{
                            rowData=cons.Contract__r.Dealer_Name__r.Name.escapeCsv()+','+cons.Contract__r.Name+','+' '+','+addressString.escapeCsv()+ ',' + manufacturer+','+cons.Model_Number__c+','+cons.Serial_Number__c+','+' '+','+formatedDate+','+servProv;
                        }
                        
                    }
                	
                	rowValues.add(rowData);                
            	}
                System.debug('Doc Content');
                System.debug(rowValues);
            	doc.Title = 'Unified'+' Contract Asset Report '+String.valueOf(Date.Today())+'.csv';
            	String content = columnHeaders + String.join(rowValues,'\n');
            	doc.VersionData = Blob.valueOf(content);
            	doc.ContentLocation = 'S';
				doc.PathOnClient = doc.Title;
                System.debug('Document:');
                System.debug(doc);
				documents.add(doc);
				providersToDocMap.put('providerId',doc.Title);                
                
            }     
            
			            
        
        Database.insert (documents,false);
        System.debug('Documents:');
        System.debug(documents);
        for(ContentVersion cv: documents){
            cvIds.add(cv.Id);
        }
        for(ContentVersion contV:[Select Id, Title, ContentDocumentId from ContentVersion Where Id In:cvIds]){
            contentDocumentIds.put(contV.Title,contV.ContentDocumentId);
            contentVersions.put(contV.Title,contV.Id);
        }
        
        
        
        
    }
    
    public void finish(Database.BatchableContext bc){
        //ContentFolder folders = [Select Id, Name from ContentFolder Where Name ='Remarketer Autoreporting' Limit 1];
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        OrgWideEmailAddress noReply = [select Id from OrgWideEmailAddress where Address = 'noreply@peacsolutions.com' Limit 1];
        /*for(String porvider:this.providers){
            ContentDocumentLink cl = new ContentDocumentLink();
            String DocTitle = providersToDocMap.get(porvider);
            if(DocTitle<>null){
                String DocumentId = contentDocumentIds.get(DocTitle);
            	cl.ContentDocumentId = DocumentId;
            	cl.LinkedEntityId = porvider;
            	cl.ShareType = 'I';
            	cl.Visibility = 'AllUsers';
            	documentLinks.add(cl);
            	ContentDocumentLink cl2 = new ContentDocumentLink();
            	cl2.ContentDocumentId = DocumentId;
            	cl2.LinkedEntityId = folders.Id;
            	cl2.ShareType = 'I';
            	cl2.Visibility = 'AllUsers';
            	documentLinks.add(cl2);
            }  
        }*/
        //insert documentLinks;
        //System.debug('Document Links');
        //System.debug(documentLinks);
        String body = 'Please find the attached report of pending returns.';
        System.debug('providers in Finish');
        System.debug(providers);
        System.debug('contentVersions: ');
        System.debug(contentVersions);
        
            List<ID> attachmentList = new List<ID>();            
            String Title = this.providersToDocMap.get('providerId');
            String contentVersion = this.contentVersions.get(Title);
            System.debug(contentVersion);
            attachmentList.add(contentVersion);            
            Messaging.SingleEmailMessage returnMail = new Messaging.SingleEmailMessage(); //customSendMailUtil.SetCustomSingleEmail(toAddress,'Return Assets',body,null,noReply);
            Messaging.EmailFileAttachment efa = new messaging.EmailFileAttachment();            
            //returnMail.setWhatId(provider);
            List<String> toAddresses = new List<String>{'PeacAssetManagement@peacsolutions.com'};
            //Testing Addresses
            //String testaddress1 = 'carlos.herrera@silverlinecrm.com';
            returnMail.setToAddresses(toAddresses);
            returnMail.setOrgWideEmailAddressId(noReply.Id);
            returnMail.setSubject('Return Assets');
            returnMail.setPlainTextBody(body);
            returnMail.setEntityAttachments(attachmentList);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{returnMail});
            
        
        //Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);
    }
    
    public void execute(SchedulableContext sc){
       String Id = Database.ExecuteBatch(new SL_ContractAssetReportUnified(),500);
    }
}