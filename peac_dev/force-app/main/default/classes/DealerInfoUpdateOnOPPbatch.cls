global class  DealerInfoUpdateOnOPPbatch  implements Database.Batchable<sObject>{
    
   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator([select id, Name,Dealer_Name1__c,Dealer_Name2__c,Dealer_Name3__c,Dealer_Name4__c,Dealer_Name5__c,Dealer_Phone1__c,Dealer_Phone2__c,Dealer_Phone3__c,Dealer_Phone4__c,Dealer_Phone5__c,Dealer_Address1__c,Dealer_Address2__c,Dealer_Address3__c,Dealer_Address4__c,Dealer_Address5__c,(select id,Dealer__r.Name,Dealer__r.Business_Phone__c,Dealer__r.Business_Address__c,Dealer__r.Business_City__c,Dealer__r.Business_State__c,Dealer__r.Business_Zip__c from Brokers__r) from Opportunity where   StageName in ('Decision', 'Application','Docs' ,'Quote', 'Proposal') ]);
   }
   global void execute(Database.BatchableContext BC, List<Opportunity> scope){
      
        
        List<Opportunity> updateOpptyList = new List<Opportunity>();
       
      for(Opportunity opps:scope){
           Integer lCounter = 1;
            System.debug('scope'+scope);
          if(String.isBlank(opps.Dealer_Name1__c) && String.isBlank(opps.Dealer_Name2__c) && String.isBlank(opps.Dealer_Name3__c) && String.isBlank(opps.Dealer_Name4__c) && String.isBlank(opps.Dealer_Name5__c) &&String.isBlank(opps.Dealer_Phone1__c) && String.isBlank(opps.Dealer_Phone2__c) && String.isBlank(opps.Dealer_Phone3__c) && String.isBlank(opps.Dealer_Phone4__c) && String.isBlank(opps.Dealer_Phone5__c)&& String.isBlank(opps.Dealer_Address1__c) &&String.isBlank(opps.Dealer_Address2__c) && String.isBlank(opps.Dealer_Address3__c)&& String.isBlank(opps.Dealer_Address4__c)&&String.isBlank(opps.Dealer_Address5__c)&& opps.Brokers__r.Size()==0)
              Continue;
          for(Integer i=1;i<=5;i++){
                opps.Put('Dealer_Name' + String.ValueOf(i) +'__c',null);
                opps.Put('Dealer_Phone' + String.ValueOf(i) +'__c',null);
                opps.Put('Dealer_Address' + String.ValueOf(i) +'__c',null);
            }
          
            for(Dealer__c deals:opps.Brokers__r){
                if(lCounter<6){
                    opps.Put('Dealer_Name'+String.ValueOf(lCounter) + '__c',deals.Dealer__r.Name);
                    opps.Put('Dealer_Phone'+String.ValueOf(lCounter) + '__c',deals.Dealer__r.Business_Phone__c);
                    opps.Put('Dealer_Address'+String.ValueOf(lCounter) + '__c',(deals.Dealer__r.Business_Address__c != null ? deals.Dealer__r.Business_Address__c : '') + ' '+  (deals.Dealer__r.Business_City__c != null ? deals.Dealer__r.Business_City__c : '')+' '+ (deals.Dealer__r.Business_State__c != null ? deals.Dealer__r.Business_State__c : '') +' '+ (deals.Dealer__r.Business_Zip__c != null ? deals.Dealer__r.Business_Zip__c : ''));
                	  lCounter += 1;
                	
                
            		}
               
           		}    
            updateOpptyList.add(opps);    
           
        } 
        
       // try{
            if(updateOpptyList.Size() > 0)
                update updateOpptyList; 
             
        //}
       //catch(Exception e){
           //System.debug(e.getMessage());
        //}
       
   }
   global void finish(Database.BatchableContext BC){
       
   }    

}