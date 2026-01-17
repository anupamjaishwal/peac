/**
* @description Bean for the Assign Signers Api. A list of these will be serialized into JSON and sent to the endpoint. 
* SAL-3249
*/
public with sharing class TC_AssignSignersBean {
    public String FirstName;
    public String LastName;
    public String EmailAddress;
    public String CCAN;
    public String CCID;
    public String OpportunityID;
    public String ContactID;
    public String AccountID;
    public String Zip;
    public String Signer;
    public String origin;
}