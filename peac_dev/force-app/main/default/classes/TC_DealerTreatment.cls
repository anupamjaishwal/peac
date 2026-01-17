/**
 * Created by andrewmayer on 9/2/20.
 */

public with sharing class TC_DealerTreatment {

    public Boolean sendBrokerAsDealer = false;
    public Boolean sendFranchisorAsDealer = false;
    public Boolean sendDealerasDealer = true;

    public TC_DealerTreatment (Opportunity opp) {
        if (!opp.Brokers1__r.isEmpty()) {
            this.sendBrokerAsDealer = true;
        } else if (!opp.Franchisors__r.isEmpty()) {
            this.sendFranchisorAsDealer = true;
        }
    }


}