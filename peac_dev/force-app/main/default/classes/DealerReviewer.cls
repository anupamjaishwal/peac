// Andrew
// Responsible for reviewing dealers based on models
// https://marlinbusiness.atlassian.net/browse/SAL-1590

// models should always be exclusive

public class DealerReviewer {
    
    private List <Dealer_Surveillance_Model__c > models;
    private Map <String, Id> modelMap;
    
    public DealerReviewer () {
        this.models = new List < Dealer_Surveillance_Model__c > ([SELECT Actual_Vs_Project_Max__c 
                                                                    , Delinquency_Max__c
                                                                    , Net_Investment_Maximum__c 
                                                                    , Net_Investment_Minimum__c 
                                                                    , Name
                                                                  	, Id
                                                                  FROM Dealer_Surveillance_Model__c
                                                                  ORDER BY Name ASC]);
        this.modelMap = new Map <String, Id> ();
        
        for (Dealer_Surveillance_Model__c model : this.models) {
            this.modelMap.put (model.Name, model.Id);
        }
    }
    
    public Map <Id, String> review (List <Account> dealers) {
        
        Map <Id, String> reviewResults = new Map <Id, String> ();
        if (dealers == null || dealers.isEmpty ()) return reviewResults;

        for (Account dealer : dealers) {
            for (Dealer_Surveillance_Model__c model : this.models) {
                if (modelCompare(dealer, model)) {
                    System.debug ('!!!!! hit');
                    System.debug ('!!!!! hit dealer.Id ' + dealer.Id);
                    System.debug ('!!!!! hit model.Name ' + model.Name);


                    reviewResults.put (dealer.Id, model.Name);
                    break;
                }
            }
        }
        System.debug ('!!!!! hit reviewResults ' + reviewResults);

        return reviewResults;
    }
    
    public Id getModelIdByName (String name) {
        return this.modelMap.get (name);
    }
    
    public Boolean modelCompare (Account dealer, Dealer_Surveillance_Model__c model) {
        return dealer.Net_Investment__c >= model.Net_Investment_Minimum__c
           && dealer.Net_Investment__c <= model.Net_Investment_Maximum__c
           && dealer.Actual_Vs_Projected_Loss__c  < model.Actual_Vs_Project_Max__c
           && dealer.Account_Total_Past_Due_Percentage__c < model.Delinquency_Max__c
           && dealer.X1_app_in_the_last_12_months__c >= 1;// ask jeff about this one. model says number of months with an app which is only tracked at 12 and 24
    }



    public void reviewSurveillances (List<Dealer_Surveillance__c> surveillances) {
                        System.debug ('!!!!! reviewSurveillances');

        Set <Id> accIds = new Set <Id> ();        
        
        for (Dealer_Surveillance__c suv : surveillances) {
            accIds.add (suv.Account__c);
        }

        Map <Id, Account> accs = new Map <Id, Account> ([SELECT Id, Actual_Vs_Projected_Loss__c, Account_Total_Past_Due_Percentage__c, X1_app_in_the_last_12_months__c   FROM Account WHERE Id IN :accIds]);

        for (Dealer_Surveillance__c suv : surveillances) {
            if(suv.Review_Type__c == 'Portfolio Threshold' && suv.Status__c !='Completed'){
                for (Dealer_Surveillance_Model__c model : this.models) {
                    if (modelCompareSurveillances(suv, model, accs.get(suv.Account__c))) {
                        System.debug ('!!!!! hit reviewSurveillances');
                        suv.Model_Hit__c = model.Id;
                        break;
                    }
                }
            }
        }
    }

        public Boolean modelCompareSurveillances (Dealer_Surveillance__c suv, Dealer_Surveillance_Model__c model, Account dealer) {
            return suv.Net_Investment__c >= model.Net_Investment_Minimum__c
            && suv.Net_Investment__c <= model.Net_Investment_Maximum__c
            && suv.Actual_Vs_Projected_Loss__c  < model.Actual_Vs_Project_Max__c
            && suv.Total_Past_Due__c  < model.Delinquency_Max__c
            && dealer.X1_app_in_the_last_12_months__c >= 1;// ask jeff about this one. model says number of months with an app which is only tracked at 12 and 24
        }



}