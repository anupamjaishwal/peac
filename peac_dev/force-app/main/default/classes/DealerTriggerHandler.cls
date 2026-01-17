/**************************************************************
Description: When a opportunity is associated with account through dealer object then then It will 
be associated to all Programs from Dealer Account 
**************************************************************/

public class DealerTriggerHandler extends SL_Trigger.baseHandler{


    //Before actions
    public override void beforeInsert(List<SObject> newList){
        TC_TriggerParams params = new TC_TriggerParams (null,null, newList);
        TC_LockRuleFactory.getLockRule('Dealer').doCheck (params);
    }

    
    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        TC_TriggerParams params = new TC_TriggerParams (oldMap,newMap, null);
        TC_LockRuleFactory.getLockRule('Dealer').doCheck (params);
    }


    public override void beforeDelete(Map<Id, SObject> oldMap) {
        // deleteDealerinfoOnOpportunity(oldMap.values());
        // deleteFieldsOnOpportunity(oldMap.values());
        TC_TriggerParams params = new TC_TriggerParams (oldMap,null, null);
        TC_LockRuleFactory.getLockRule('Dealer').doCheck (params);
    }

    //After Actions

    public override void afterInsert(Map<Id, SObject> newMap) {
        checkDealerOpty(newMap.values());
        addProgram(newMap.values());
        //DealerTriggerHandler.solicitEndUser(Trigger.new);
        populateFieldsOnOpportunity(newMap.values());
        Map<Id,Dealer__c> newDealerMap = (Map<Id,Dealer__c>)newMap;
        TC_CreditDecision.runRules(null, newDealerMap);   
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        checkDealerOpty(newMap.values());
        populateFieldsOnOpportunity(newMap.values());
        Map<Id,Dealer__c> newDealerMap = (Map<Id,Dealer__c>)newMap;
        Map<Id,Dealer__c> oldDealerMap = (Map<Id,Dealer__c>)oldMap;
        TC_CreditDecision.runRules(oldDealerMap, newDealerMap);
    }

    public override void afterDelete(Map<Id, SObject> oldMap){// DP-1860 Misael Romero
        // deleteDealerinfoOnOpportunity(oldMap.values());
        deleteFieldsOnOpportunity(oldMap.values());
    }

    public static void checkDealerOpty(list<Dealer__c> dlrList){
        set<Id> accIdSet = new set<Id>();
        set<Id> updateDealerAccounts = new set<Id>();
        for(Dealer__c dealer : dlrList){
            accIdSet.add(dealer.Dealer__c);
        }
        // User u = [SELECT Id, IsPartner from User WHERE Id = :UserInfo.getUserId()];
        // System.debug('Partner user? '+ u.IsPartner);
        if(accIdSet.size() > 0){
        List<Dealer__c> dealerLst = [Select Id, Name, CreatedDate,Dealer__c,Opportunity__c,Opportunity__r.Decision_Status__c, Opportunity__r.Equipment_Cost__c from Dealer__c where Dealer__r.Id =:accIdSet and Opportunity__r.Decision_Status__c = 'A' /*and Opportunity__r.Equipment_Cost__c >= 50000*/];
            if(dealerLst.size() > 0){
                for(Dealer__c dealerRec : dealerLst){
                    if(dealerLst.size() > 5){
                        if(dealerRec.Opportunity__r.Equipment_Cost__c >= 50000){
                        	updateDealerAccounts.add(dealerRec.Dealer__c);
                        }
                    }
        		}
                if(updateDealerAccounts.size() > 0){
                    List<Account> accLst = [Select id, Pre_Delivery_20k_Trial__c from account where id=:updateDealerAccounts];
                    System.debug('checkDealerOpty aaclst '+ accLst );
                    for(Account acc : accLst){
                        acc.Pre_Delivery_20k_Trial__c = false;
                    }
                    SL_DPImperative.updateDealerAccounts(accLst);
                }
            }
        }
        //Select Id, Name, CreatedDate,Dealer__c,Opportunity__c,Opportunity__r.Decision_Status__c, Opportunity__r.Equipment_Cost__c from Dealer__c where Dealer__r.Id = '00161000014nIlpAAE'
    }
    public static void addProgram(list<Dealer__c> dlrList){
        
        Set<id> accIdList = new Set<id>();
        Set<id> optyIdList = new Set<id>();
        //List<Opportunity> optyRecordList = new List<Opportunity>();
        List<Opportunity_Program__c> optyProgram = new List<Opportunity_Program__c>();
        
        for(Dealer__c dlr: dlrList){
            optyIdList.add(dlr.Opportunity__c);
            accIdList.add(dlr.Dealer__c);
        }               
        
        String accountRecordTypeIds = label.AccountRecordTypeId;
        list<String> accRecordTypeIdList = accountRecordTypeIds.split(',');
        Set<Id> accIds = new Set<Id>();
        
        List<Account> lAcc = [Select id, RecordType.DeveloperName from Account where id IN: accIdList AND RecordType.DeveloperName IN :accRecordTypeIdList];
        
        if(lAcc.size() > 0) {
            for(Account ac : lAcc) {
                accIds.add(ac.id);
            }
            List<Account_Program__c> AccProgramList = [select Id, Account__c, Program__c from Account_Program__c where Account__c IN :accIds];
            map<id,Set<Id>> optyprogramLst = new map<id,Set<Id>>();
            for(Opportunity_Program__c oppProg:[select Opportunity__c, id, Program__c from Opportunity_Program__c where Opportunity__c in :optyIdList]){
                System.debug('opportunity program----->'+oppProg.Opportunity__c);
                if(optyprogramLst.containsKey(oppProg.Opportunity__c)){
                    Set<Id> programSet = optyprogramLst.get(oppProg.Opportunity__c);
                    programSet.add(oppProg.Program__c);
                    optyprogramLst.put(oppProg.Opportunity__c, programSet);
                }
                else{
                    optyprogramLst.put(oppProg.Opportunity__c, new Set<Id> { oppProg.Program__c });
                }
            }
            System.debug('oppty with program List----->'+optyprogramLst);
            Map<id,Set<Id>> AccProgramLMap = new Map<id,Set<Id>>();
            if(AccProgramList.size()>0){
                for(Account_Program__c ap : AccProgramList) {
                    if(AccProgramLMap.containsKey(ap.Account__c)) {
                        Set<Id> programSet = AccProgramLMap.get(ap.Account__c);
                        programSet.add(ap.Program__c);
                        AccProgramLMap.put(ap.Account__c, programSet);
                    } else {
                        AccProgramLMap.put(ap.Account__c, new Set<Id> { ap.Program__c });
                    }
                    System.debug('AccProgramLMap---->'+AccProgramLMap);
                }
                
                
                System.debug('Account Program-----> '+AccProgramList);
                
                for(Dealer__c dlr: dlrList){
                    if(accIds.contains(dlr.Dealer__c)) {
                        
                        for(Account_Program__c accProg: AccProgramList){
                            System.debug('Opportunity name--->'+dlr.Opportunity__c);
                            
                                
                            if(optyprogramLst.isEmpty() || !(optyprogramLst.get(dlr.Opportunity__c).contains(accProg.Program__c)) ){
                                system.debug('optyprogramLst not empty---->'+ optyprogramLst);
                                if(AccProgramLMap.get(dlr.Dealer__c).contains(accProg.Program__c)){
                                    System.debug('Program name---->'+accProg);
                                    Opportunity_Program__c oppProg = new Opportunity_Program__c();
                                    oppProg.Opportunity__c = dlr.Opportunity__c;
                                    oppProg.Program__c = accProg.Program__c;
                                    
                                    optyProgram.add(oppProg);
                                }
                            }
                        }
                             
                    }        
                }
                System.debug('optyProgram---->'+optyProgram);
                
                if(optyProgram.size()>0) {
                    insert optyProgram;
                }
            }  
            
        }
    }
    
    
    // If in Dealer account Solicit_End_Users__c field is true then Solicitable1__c on End user account will be Unsolicitable
   /* public static void  solicitEndUser(list<Dealer__c> dlrList){
        list<id> optyId = new list<id>();
        list<id> accId = new list<id>();
		list<id> eOptyIdWithNoDealer = new list<id>();
        List<Account> accountLstToUpdate = new List<Account>();
        for(Dealer__c dlr : dlrList){
            optyId.add(dlr.Opportunity__c);
            accId.add(dlr.Dealer__c);
        }
		//list<Opportunity> aOptyListWithNoDealer = new list<Opportunity>([select id, (Select id from Brokers__r) from Opportunity where Id IN :optyId]);
		for(Opportunity optyIdInd : [select id, (Select id from Brokers__r) from Opportunity where Id IN :optyId]){
            System.debug('Dealer Size---->'+optyIdInd.Brokers__r.size());
			if(optyIdInd.Brokers__r.size() <= 1)
				eOptyIdWithNoDealer.add(optyIdInd.Id);
            System.debug('eOptyIdWithNoDealer list value----->' + eOptyIdWithNoDealer);
		}
		
		if(eOptyIdWithNoDealer.size() > 0){
			Map<id,Account> accountMap = new Map<id,Account>([select id,name, Solicit_End_Users__c from Account where id IN :accId]);
			Map<id,Opportunity> accFromOptyMap = new Map<id,Opportunity>([select id, name, AccountId, Account.Solicitable1__c from 
																		  Opportunity where id IN :eOptyIdWithNoDealer]);
			for(Dealer__c d : dlrList){
				if(accountMap.get(d.Dealer__c).Solicit_End_Users__c == true){
					System.debug('Solicit_End_Users__c true------>'+accountMap.get(d.Dealer__c).Solicit_End_Users__c);
					accFromOptyMap.get(d.Opportunity__c).Account.Solicitable1__c = 'Unsolicitable';
					Account acc = new Account();
					acc.id = accFromOptyMap.get(d.Opportunity__c).AccountId;
					acc.Solicitable1__c = accFromOptyMap.get(d.Opportunity__c).Account.Solicitable1__c;                
					accountLstToUpdate.add(acc);
				}
				else{
					accFromOptyMap.get(d.Opportunity__c).Account.Solicitable1__c = 'Solicitable';
					Account acc = new Account();
					acc.id = accFromOptyMap.get(d.Opportunity__c).AccountId;
					acc.Solicitable1__c = accFromOptyMap.get(d.Opportunity__c).Account.Solicitable1__c;                
					accountLstToUpdate.add(acc);
				}
			}
			System.debug('accountLstToUpdate---->'+accountLstToUpdate);
			if(accountLstToUpdate.size() > 0){
				update accountLstToUpdate;
			}
		}        
    } */
    
    public static void populateFieldsOnOpportunity(List<Dealer__c> newdealList){
        Set<id> idopportunitySet=new Set<id>();
        List<Opportunity> updateOpptyList = new List<Opportunity>();
        Integer lCounter = 1;
        for(Dealer__c deal:newdealList ){
            idopportunitySet.add(deal.Opportunity__c);
        }
       List<Opportunity> dealerOpportunityList=[select id, Name,(select id,Dealer__r.Name,Dealer__r.Business_Phone__c,Dealer__r.Business_Address__c,Dealer__r.Business_City__c,Dealer__r.Business_State__c,Dealer__r.Business_Zip__c from Brokers__r) from Opportunity where id in:idopportunitySet];
        for(Opportunity opps:dealerOpportunityList){
            
            opps.Put('Dealer_Name' + String.ValueOf(lCounter) +'__c',null);
            opps.Put('Dealer_Phone' + String.ValueOf(lCounter) +'__c',null);
            opps.Put('Dealer_Address' + String.ValueOf(lCounter) +'__c',null);
            
            for(Dealer__c deals:opps.Brokers__r){
                opps.Put('Dealer_Name'+String.ValueOf(lCounter) + '__c',deals.Dealer__r.Name);
                opps.Put('Dealer_Phone'+String.ValueOf(lCounter) + '__c',deals.Dealer__r.Business_Phone__c);
                opps.Put('Dealer_Address'+String.ValueOf(lCounter) + '__c',(deals.Dealer__r.Business_Address__c != null ? deals.Dealer__r.Business_Address__c : '') + ' '+  (deals.Dealer__r.Business_City__c != null ? deals.Dealer__r.Business_City__c : '')+' '+ (deals.Dealer__r.Business_State__c != null ? deals.Dealer__r.Business_State__c : '') +' '+ (deals.Dealer__r.Business_Zip__c != null ? deals.Dealer__r.Business_Zip__c : ''));
                 lCounter += 1;
                if(lCounter > 5)
                    break;
            }
           updateOpptyList.add(opps);
        } 
        system.debug('updateOpptyList----'+updateOpptyList);
         try{
            if(updateOpptyList.Size() > 0)
                update updateOpptyList;      
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }
    // DP-1860 Misael Romero
    // public static void deleteDealerinfoOnOpportunity(List<Dealer__c> oldealList){
    //     Set<id> oppIdset=new Set<id>();
    //     List<Opportunity> oppList=new List<Opportunity>();
    //     for(Dealer__c dls:oldealList){
    //         if(dls.Primary_Dealer__c==true)
    //         oppIdset.add(dls.Opportunity__c);
    //     }
    //     for(Opportunity opps:[select id,Vendor_Name__c,Vendor_Address__c from Opportunity where id in:oppIdset]){
    //         opps.Vendor_Name__c='';
    //         opps.Vendor_Address__c='';
    //         oppList.add(opps);
    //     }
    //     update oppList;
    // }
    public static void deleteFieldsOnOpportunity(List<Dealer__c> newdealList){
        Set<id> idopportunitySet=new Set<id>();
		Set<id> nameset=new Set<id>();
        List<Opportunity> updateOpptyList = new List<Opportunity>();
        Integer lCounter = 1;
        for(Dealer__c deal:newdealList ){
            idopportunitySet.add(deal.Opportunity__c);
			nameset.add(deal.id);
        }
       List<Opportunity> dealerOpportunityList=[SELECT id, Name,
        (SELECT id,Name,Dealer__r.Name,Dealer__r.Business_Phone__c,Dealer__r.Business_Address__c,Dealer__r.Business_City__c,Dealer__r.Business_State__c,Dealer__r.Business_Zip__c 
        FROM Brokers__r WHERE id NOT IN :nameset) 
       FROM Opportunity WHERE id in:idopportunitySet];
        for(Opportunity opps:dealerOpportunityList){
            //deleteDealerinfoOnOpportunity
            opps.Vendor_Name__c='';
            opps.Vendor_Address__c='';
            for(Integer i=1;i<=5;i++){
                opps.Put('Dealer_Name' + String.ValueOf(i) +'__c',null);
                opps.Put('Dealer_Phone' + String.ValueOf(i) +'__c',null);
                opps.Put('Dealer_Address' + String.ValueOf(i) +'__c',null);
            }
            for(Dealer__c deals:opps.Brokers__r){
                opps.Put('Dealer_Name'+String.ValueOf(lCounter) + '__c',deals.Dealer__r.Name);
                opps.Put('Dealer_Phone'+String.ValueOf(lCounter) + '__c',deals.Dealer__r.Business_Phone__c);
                opps.Put('Dealer_Address'+String.ValueOf(lCounter) + '__c',(deals.Dealer__r.Business_Address__c != null ? deals.Dealer__r.Business_Address__c : '') + ' '+  (deals.Dealer__r.Business_City__c != null ? deals.Dealer__r.Business_City__c : '')+' '+ (deals.Dealer__r.Business_State__c != null ? deals.Dealer__r.Business_State__c : '') +' '+ (deals.Dealer__r.Business_Zip__c != null ? deals.Dealer__r.Business_Zip__c : ''));
                 lCounter += 1;
                if(lCounter > 5)
                    break;
            }
           updateOpptyList.add(opps);
        } 
        system.debug('updateOpptyList----'+updateOpptyList);
         try{
            if(updateOpptyList.Size() > 0)
                update updateOpptyList;      
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }
}