/**
* @description Class will map Salesforce objects to beans that we can send via TC_AssignSignersService
* SAL-3249
*/
public with sharing class TC_AssignSignersMapper {

    private static Map<String, Contact> associatedContactMap = new Map<String, Contact>();

    /**
    * @description Class will map Salesforce objects to beans that we can send via TC_AssignSignersService
    * SAL-3249
    *@param docusignStatusId takes in the Id of a Docusign Status Object and returns a list of TC_AssignSignersBean
    *@return beans List of TC_AssignSignersBean objects
    */
    public static List<TC_AssignSignersBean> mapSalesforceToBean(Id docusignStatusId){
        List<TC_AssignSignersBean> beans = new List<TC_AssignSignersBean>();
        dsfs__DocuSign_Status__c status;
        Contact con;

        if(docusignStatusId != null){
            status = [SELECT Id, dsfs__Opportunity__c, dsfs__Opportunity__r.Id, dsfs__Opportunity__r.CCAN__c, 
            dsfs__Opportunity__r.CCID__c, dsfs__Opportunity__r.AccountId, 
            dsfs__Opportunity__r.Account_Business_Zip_Postal_Code__c, dsfs__Opportunity__r.Tax_ID__c, 
            (SELECT Id, Name, dsfs__Contact__r.FirstName, dsfs__Contact__r.LastName, dsfs__Contact__r.Email, dsfs__Contact__r.Id, dsfs__Contact__c
            FROM dsfs__R00NS0000000WUO2MAO__r WHERE (dsfs__DocuSign_Routing_Order__c = 1 OR dsfs__DocuSign_Routing_Order__c = 2)
            ORDER BY dsfs__DocuSign_Routing_Order__c)
            FROM dsfs__DocuSign_Status__c WHERE Id = :docusignStatusId LIMIT 1];

            if(status?.dsfs__Opportunity__c != null) {
                getOpportunitySignerMap(status.dsfs__Opportunity__c);
            }
        }

        if(status != null){
            if(status.dsfs__R00NS0000000WUO2MAO__r.size() > 0){
                con = status.dsfs__R00NS0000000WUO2MAO__r[0].dsfs__Contact__c != null ? status.dsfs__R00NS0000000WUO2MAO__r[0].dsfs__Contact__r : (associatedContactMap.get(status.dsfs__R00NS0000000WUO2MAO__r[0].Name) != null ? associatedContactMap.get(status.dsfs__R00NS0000000WUO2MAO__r[0].Name) : new Contact());
                System.debug(con);
                TC_AssignSignersBean bean1 = new TC_AssignSignersBean();
                bean1.FirstName = con.FirstName != null ? con.FirstName : '';
                bean1.LastName = con.LastName != null ? con.LastName : '';
                bean1.EmailAddress = con.Email != null ? con.Email : '';
                bean1.CCAN = status.dsfs__Opportunity__r.CCAN__c != null ? status.dsfs__Opportunity__r.CCAN__c : '';
                bean1.CCID = status.dsfs__Opportunity__r.CCID__c != null ? status.dsfs__Opportunity__r.CCID__c : '';
                bean1.OpportunityID = status.dsfs__Opportunity__r.Id != null ? status.dsfs__Opportunity__r.Id : '';
                if(con.Id != null) {
                    bean1.ContactID = con.Id;
                } else {
                    bean1.ContactID = '';
                }
                bean1.AccountID = status.dsfs__Opportunity__r.AccountId != null ? status.dsfs__Opportunity__r.AccountId : '';
                bean1.Zip = status.dsfs__Opportunity__r.Account_Business_Zip_Postal_Code__c != null ? status.dsfs__Opportunity__r.Account_Business_Zip_Postal_Code__c : '';
                bean1.Signer = '1';
                bean1.origin = 'SF';
                system.debug('StatusObject1: ' + status.dsfs__R00NS0000000WUO2MAO__r[0]);
                beans.add(bean1);

                /*if(status.dsfs__R00NS0000000WUO2MAO__r.size() > 1){
                    con = status.dsfs__R00NS0000000WUO2MAO__r[1].dsfs__Contact__c != null ? status.dsfs__R00NS0000000WUO2MAO__r[1].dsfs__Contact__r : (associatedContactMap.get(status.dsfs__R00NS0000000WUO2MAO__r[1].Name) != null ? associatedContactMap.get(status.dsfs__R00NS0000000WUO2MAO__r[1].Name) : new Contact());
                    System.debug(con);
                    TC_AssignSignersBean bean2 = new TC_AssignSignersBean();
                    bean2.FirstName = con.FirstName != null ? con.FirstName : '';
                    bean2.LastName = con.LastName != null ? con.LastName : '';
                    bean2.EmailAddress = con.Email != null ? con.Email : '';
                    bean2.CCAN = status.dsfs__Opportunity__r.CCAN__c != null ? status.dsfs__Opportunity__r.CCAN__c : '';
                    bean2.CCID = status.dsfs__Opportunity__r.CCID__c != null ? status.dsfs__Opportunity__r.CCID__c : '';
                    bean2.OpportunityID = status.dsfs__Opportunity__r.Id != null ? status.dsfs__Opportunity__r.Id : '';
                    if(con.Id != null) {
                        bean2.ContactID = con.Id;
                    } else {
                        bean2.ContactID = '';
                    }
                    bean2.AccountID = status.dsfs__Opportunity__r.AccountId != null ? status.dsfs__Opportunity__r.AccountId : '';
                    bean2.Zip = status.dsfs__Opportunity__r.Account_Business_Zip_Postal_Code__c != null ? status.dsfs__Opportunity__r.Account_Business_Zip_Postal_Code__c : '';
                    bean2.Signer = '2';
                    bean2.origin = 'SF';
                    system.debug('StatusObject2: ' + status.dsfs__R00NS0000000WUO2MAO__r[1]);
                    beans.add(bean2);
                }*/
            }
            
        }

        return beans;
    }

    private static Contact generateContactObject(dsfs__DocuSign_Recipient_Status__c recStatus) {
        return new Contact(Id = recStatus.dsfs__Contact__r.Id, FirstName = recStatus.dsfs__Contact__r.FirstName, LastName = recStatus.dsfs__Contact__r.LastName, Email = recStatus.dsfs__Contact__r.Email);
    }

    private static void getOpportunitySignerMap(Id oppId) {
        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id,
                                                                    Primary_Contact__c,
                                                                    Primary_Contact__r.Name, 
                                                                    Primary_Contact__r.FirstName,
                                                                    Primary_Contact__r.LastName,
                                                                    Primary_Contact__r.Email,
                                                                    (SELECT Id,
                                                                            Contact__c,
                                                                            Contact_Name__c, 
                                                                            Contact_First_Name__c,
                                                                            Contact_Last_Name__c,
                                                                            Email__c
                                                                    FROM Guarantor__r
                                                                    WHERE RecordTypeId = :Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId()
                                                                    ORDER BY CreatedDate ASC) 
                                                            FROM Opportunity 
                                                            WHERE Id = :oppId]);
        if(oppList?.isEmpty() == false) {
            opp = oppList[0];
        }
        if(opp.Guarantor__r?.size() > 0) {
            for(Guarantor__c g : opp.Guarantor__r) {
                if(g.Contact__c != null) {
                    associatedContactMap.put(g.Contact_Name__c, new Contact(Id = g.Contact__c, FirstName = g.Contact_First_Name__c, LastName = g.Contact_Last_Name__c, Email = g.Email__c));
                }
            }
        }
        if(opp.Primary_Contact__c != null) {
            associatedContactMap.put(opp.Primary_Contact__r.Name, new Contact(Id = opp.Primary_Contact__c, FirstName = opp.Primary_Contact__r.FirstName, LastName = opp.Primary_Contact__r.LastName));
        }
    }
}