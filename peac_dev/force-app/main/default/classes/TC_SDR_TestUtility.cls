@IsTest
public without sharing class TC_SDR_TestUtility {
    
    /**
     * @description       This function will create auto follow up steps
     *
     * @param campaignId  The campaign to create the auto follow up steps for
     * @param numSteps    The number of steps to create
     * 
     * @return            The new auto follow up steps  
     */
    public static List<Auto_Follow_Up__c> createAutoFollowUpSteps(Id campaignId, Integer numSteps) {
        List<Auto_Follow_Up__c> afus = constructNewAutoFollowups(numSteps, campaignId);

        insert afus;

        update connectNewAutoFollowUps(afus);
        
        return afus;
    }

    /**
     * @description         Constructs new auto follow ups
     *
     * @param numSteps      The number of steps to create
     * @param campaignId    The campaign to create the auto follow up steps for
     *
     * @return              The constructed auto follow up steps
     */
    public static List<Auto_Follow_Up__c> constructNewAutoFollowups(Integer numSteps, Id campaignId) {
        List<Auto_Follow_Up__c> returnList = new List<Auto_Follow_Up__c>();

        for (Integer i = 0; i < numSteps; i++) {
            returnList.add(
                new Auto_Follow_Up__c(
                    StepNumber__c = (i + 1),
                    Campaign__c = campaignId,
                    TaskSubject__c = 'Task '+i+1,
                    TaskComment__c = 'Comment '+i+1,
                    DefaultDaysUntilNextFollowup__c = 1+i,
                    Name='Step '+(i + 1)
                )
            );
        }
        
        return returnList;
    }

    /**
     * @description This function connects the auto follow up steps with each other
     *
     * @param afus  The auto follow up steps to connect
     *
     * @return      The connected auto follow up steps
     */
    public static List<Auto_Follow_Up__c> connectNewAutoFollowUps(List<Auto_Follow_Up__c> afus) {
        for (Integer i = 0; i < afus.size(); i++) {
            if (i == 0) continue;
            afus[i].PreviousAutoFollowUp__c = afus[i-1].Id;
        }
        
        return afus;
    }

    /**
     * @description Constructs the campaign
     *
     * @param name  The name of the campaign
     *
     * @return      The constructed campaign
     */
    public static Campaign constructCampaign(String name) {
        return new Campaign(
                Name = name,
                IsActive = true
        );
    }

    public static List<CampaignMemberStatus> constructCampaignMemberStatuses(Id campaignId) {
        List<CampaignMemberStatus> returnList = new List<CampaignMemberStatus>();

        returnList.add(new CampaignMemberStatus(CampaignId = campaignId, HasResponded = false, IsDefault = true, Label = 'isSent', SortOrder=3));
        returnList.add(new CampaignMemberStatus(CampaignId = campaignId, HasResponded = true, IsDefault = false, Label = 'hasResponded', SortOrder=4));

        return returnList;
    }

    /**
     * @description         Constructs a new account
     *
     * @param name          The name of the account
     * @param campaignName  The name of the campaign
     * @param recordTypeId  The record type (optional)
     *
     * @return              The constructed account
     */
    public static Account constructAccount(String name, String campaignName, Id recordTypeId) {
        Account acct = new Account(
                Name = name,
                Target_SDR_Campaign__c = campaignName
        );
        if (recordTypeId != null) acct.RecordTypeId = recordTypeId;
        return acct;
    }

    /**
     * @description             Constructs a new lead
     *
     * @param lastName          The last name of the lead
     * @param firstName         The first name of the lead
     * @param companyName       The company name of the lead
     * @param primaryAccountId  The primary account id of the lead
     *
     * @return                  The constructed lead
     */
    public static Lead constructLead(String lastName, String firstName, String companyName, Id primaryAccountId) {
        return new Lead(
                LastName = lastName,
                FirstName = firstName,
                Company = companyName,
                PrimaryAccount__c = primaryAccountId
        );
    }

    /**
     * @description     This function will create a campaign and auto follow up records
     *
     * @param name      The name of the campaign
     * @param numSteps  The number of follow up steps to create
     *
     * @return          The created campaign
     */
    public static Campaign createCampaignAndAutoFollowUps(String name, Integer numSteps) {
        Campaign camp = constructCampaign(name);
        insert camp;
        insert constructCampaignMemberStatuses(camp.Id);
        List<Auto_Follow_Up__c> afus = createAutoFollowUpSteps(camp.Id, (numSteps == null ? 5 : numSteps));

        return camp;
    }

    public static User constructNewUser(Id profileId, String classNm) {
        return new User(Alias = 'aaaa', Email = classNm+'@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = classNm,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profileId,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = classNm+'@testorg.com'
        );
    }

    public static List<String> getClosedStatuses() {
        List<String> returnList = new List<String>();
        for (TaskStatus ts :[SELECT Id, ApiName FROM TaskStatus WHERE IsClosed = true]) {
            returnList.add(ts.ApiName);
        }
        return returnList;
    }

    public static Opportunity constructOpportunity(String name, Id acctId) {
        return new Opportunity(
                Name = name,
                AccountId = acctId,
                StageName = 'Stage 1',
                CloseDate = Date.today()
        );
    }

    public static Contact constructContact(String firstName, String lastName, String email, Id accountId) {
        return new Contact(
                FirstName = firstName,
                LastName = lastName,
                Email = email,
                AccountId = accountId
        );
    }
}