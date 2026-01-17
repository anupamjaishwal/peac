public class TC_DocumentDeliveryMethodValidation {
public static void documentDeliveryMethodValidation (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap,Map<Id, List<Dealer__c>> dealers) {
        
        Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ();
        
        for (Opportunity opp : newMap.values()) {
            if (opp.Document_Delivery_Method__c != oldMap.get (opp.Id).Document_Delivery_Method__c && opp.Document_Delivery_Method__c == 'PDF' && opp.Branch__c != null && !opp.Branch__c.toLowerCase ().contains ('ifp') && !opp.Branch__c.toLowerCase ().contains ('oeg')) {
                oppMap.put (opp.Id, opp);
            }
        }
        
        if (!oppMap.isEmpty ()) {
            // check current user, doc fee exception users are excluded from rule
            List <User> user = new List <User> ([SELECT Id FROM User WHERE Id =:UserInfo.getUserId() AND Doc_Fee_Exception_Approver__c = true]);
            if (!user.isEmpty ()) return;
            
            //added by Rajasirivella
            if (!oppMap.isEmpty()) {
                for(Id oppId : oppMap.keySet()){
                    Boolean nonDocusignOrPdf = false;
                    if(!dealers.isEmpty()){
                        List<Dealer__c> dealerLst = dealers.get(oppId);
                        for(Dealer__c dealer : dealerLst){
                            if(dealer.Dealer__r.Approved_Document_Delivery_Method__c != 'DocuSign or .pdf'){
                                nonDocusignOrPdf = true;
                                } //if                               
                            }// dealerLst   
                           // throw exception
                            if (nonDocusignOrPdf)
                            {
                            oppMap.get(oppId).Document_Delivery_Method__c.addError ('All related Dealers must have the Approved Document Deliver Method equal to Docusign or PDF'); 
                            } //if                                        
                        } //dealers empty
                        else {
                            // no broker to define approved document method throw error
                            oppMap.get(oppId).Document_Delivery_Method__c.addError ('All related Dealers must have the Approved Document Deliver Method equal to Docusign or PDF');
                        } //else
                                          
                    }//opp keys
                }//oppMapempty
            //end
            // check dealers
           /* List <Opportunity> oppsWithDealers = new List <Opportunity> ([SELECT Id, (SELECT Dealer__r.Approved_Document_Delivery_Method__c FROM Brokers__r) FROM Opportunity WHERE Id IN :oppMap.keySet ()]);
            
            
            for (Opportunity opp : oppsWithDealers) {
                if (!opp.Brokers__r.isEmpty ()) {
                    Boolean nonDocusignOrPdf = false;
                    for (Dealer__c dealer : opp.Brokers__r) {
                        if (dealer.Dealer__r.Approved_Document_Delivery_Method__c != 'DocuSign or .pdf') nonDocusignOrPdf = true;
                    }
                    // throw exception
                    if (nonDocusignOrPdf) oppMap.get (opp.Id).Document_Delivery_Method__c.addError ('All related Dealers must have the Approved Document Deliver Method equal to Docusign or PDF');
                    
                } else {
                    // no broker to define approved document method throw error
                    oppMap.get (opp.Id).Document_Delivery_Method__c.addError ('All related Dealers must have the Approved Document Deliver Method equal to Docusign or PDF');
                }
            }*/
            
        }
    }
}