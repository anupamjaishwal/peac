/**
 * Apex representation of the request
 * due to flows not supporting apex data types, using salesforce objects to represent the request for
 * users to map, then data gets stored here for easy apex manipulation
 */
public class PEAC_GDSScoreLoanReqRespBean {
    
    public Id oppId;
    public Gds_Score__c scoreReq; 
    public Gds_Score_Request_Company__c company1;
    public Gds_Score_Request_Company__c dealer;
    public Gds_Score_Request_Company__c broker;
    public Gds_Score_Request_Company__c cc;
    public List <Gds_Score_Request_Individual__c> pgs; 
    public String errorMessage;
    public String xmlResponse;

    public Opportunity opp;
    public Webservice_Field__c wsFields;
    public Webservice_Field__c wsFieldsFraud;
    public String Account_type;

    public PEAC_GDSScoreLoanReqRespBean () {
        this.scoreReq = new Gds_Score__c ();
        this.company1 = new Gds_Score_Request_Company__c ();
        this.dealer = new Gds_Score_Request_Company__c ();
        this.broker = new Gds_Score_Request_Company__c ();
        this.cc = new Gds_Score_Request_Company__c ();
        this.pgs = new List <Gds_Score_Request_Individual__c> ();
        this.errorMessage = '';
        this.xmlResponse = '';
    }
}