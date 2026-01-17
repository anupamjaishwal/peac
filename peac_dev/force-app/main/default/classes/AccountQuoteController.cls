public class AccountQuoteController {
    @AuraEnabled
    public static List<Account> getAccountRecord(Id recId){
        
        List<Account> lstACC = [SELECT Id , Account_Dealer_Status__c,Risk_Based_Pricing__c,Playbook_Status__c  FROM Account WHERE Id =: recId];
        return lstACC;
        
    }

  
    
    @AuraEnabled
    public static void getPortalCustCreditExpAndAutoPG(Id accId, Id LeadId){
        
        TC_DwhStoredProcedureRespBean objRespBean = new  TC_DwhStoredProcedureRespBean();
        if(accId != null){
            if(! Test.isRunningTest()){
                objRespBean = TC_DwhStoredProcedureApi.getPortalCustCreditExp (accId);
                if(objRespBean != null && objRespBean.results != null && LeadId != null){ 
                    System.debug('>>>>>>DWH objRespBean.results[0]'+objRespBean.results[0]);
                    TC_GdsAutoPgApi.runAutoPG(LeadId, objRespBean.results[0]);
                }
            }
        }
        
    }
    
    
    @AuraEnabled
    public static void callWebserviceGetXMLResponse(Id accId, Decimal EquipmentCost,String LeadId){
        Account objAcc = [SELECT Id, Risk_Based_Pricing__c,Account_Branch__c FROM Account WHERE Id=:accId ];
         Lead objLead = [Select Id,Name,Corp_Only_Risk_Grade__c  FROM Lead Where Id = : LeadId Limit 1];
        System.debug('>>>>objLead::'+objLead);
        List<TC_PossibleOffers.PossibleOffer> lstPossibleOffer = new List<TC_PossibleOffers.PossibleOffer> ();
         TC_RateCardRequestBean req = new TC_RateCardRequestBean();
        if(objAcc != null){
            if(objAcc.Account_Branch__c != null ){
                req.branch = objAcc.Account_Branch__c;
            }
            if(EquipmentCost != null){ 
                req.equipmentCost = EquipmentCost;
            }
            req.riskBasedPricing = objAcc.Risk_Based_Pricing__c;
            if(String.isNotBlank(objLead.Corp_Only_Risk_Grade__c)){
                 req.riskGrade = objLead.Corp_Only_Risk_Grade__c;
            }
            else{
               req.riskGrade = 'A3'; 
            }
        }

        // SAL-2602 update to use the new rules engine
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'STATIC ACCOUNT FOR RATE CARDS'];
        Opportunity opp = TC_SobjectRecordFactory.createOpportunity(acc);
        TC_RateCardMapper.mapOpportunityFields(opp, req);

        if(opp != null && objLead.Id != null){
          getPossibleOffer(opp,objLead.Id);

        }
     
    }

    // SAL-2602 updates to use the new rules engine
    // 1. Passes in an opp instead of an ID
    // 2. Calls the new Possible Offers method using an opp from memory
    // 3. No longer deletes the opp since it's never actually inserted
    // 4. No longer called asynchronously
    public static void getPossibleOffer(Opportunity opp, String leadId){
        System.debug('>>>>calling getPossibleOffer');
        List<TC_PossibleOffers.PossibleOffer> lstPossibleOffer = new List<TC_PossibleOffers.PossibleOffer> ();
        lstPossibleOffer =  TC_PossibleOffers.generatePossibleOffersFromOpp(opp);
        try{
            Lead objLead = new Lead(Id= leadId);
            Integer i = 1;
            for(TC_PossibleOffers.PossibleOffer objPO : lstPossibleOffer){
                if(i == 1){
                    objLead.QuoteTerm1__c= objPO.Term;
                    objLead.QuotePayment1__c = objPO.MonthlyPayment;
                }
                if(i == 2){
                    objLead.QuoteTerm2__c= objPO.Term;
                    objLead.QuotePayment2__c = objPO.MonthlyPayment;
                }
                if(i == 3){
                    objLead.QuoteTerm3__c= objPO.Term;
                    objLead.QuotePayment3__c = objPO.MonthlyPayment;
                }
                if(i == 4){
                    objLead.QuoteTerm4__c= objPO.Term;
                    objLead.QuotePayment4__c = objPO.MonthlyPayment;
                }
                if(i == 5){
                    objLead.QuoteTerm5__c= objPO.Term;
                    objLead.QuotePayment5__c = objPO.MonthlyPayment;
                }
                i++;
                
            }
           update objLead ;
            System.debug('>>>>>>objLead after update:'+objLead);
        }catch(Exception e){
           System.debug('>>>>>errorr in catch::'+ e.getMessage());
             System.debug('>>>>>errorr in catch::'+  e.getStackTraceString());
        }
        
    }
    
}