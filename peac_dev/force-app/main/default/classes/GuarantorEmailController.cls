public class GuarantorEmailController {

    public Id opportunityId { get; set; }
    public Guarantor__c guarantor { get; set; }

    public void setOpportunityId(Id id) {
        this.opportunityId = id;

        List<Guarantor__c> guarantors = [
            SELECT Id,Contact_First_Name__c, Contact_Last_Name__c, Email__c, Name, Business_Phone__c,  Contact_Name__c
            FROM Guarantor__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        System.debug('GUARANTOR ' + guarantors);

        if (!guarantors.isEmpty()) {
            guarantor = guarantors[0];
        }
    }

    public Guarantor__c getGuarantor() {
        return guarantor;
    }

}