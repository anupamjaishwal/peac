/**
 * @description This controller is responsible for managing the auto follow up itesm related to a campaign
 * @see         SAL-1877
 */
public without sharing class ManageAutoFollowUpsCont {

    public Id campId {
        get;
        set {
            if (this.campId != value) {
                this.campId = value;
                System.assert(this.campId == camp.Id);
            }
        }
    }

    public Boolean canSave {
        get {
            if (this.canSave == null) {
                User u = [SELECT Id, UserRole.DeveloperName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
                this.canSave = String.isNotBlank(u.UserRole.DeveloperName) && u.UserRole.DeveloperName.containsIgnoreCase('Manager') || u.Profile.Name.contains('Administrator');
            }
            return this.canSave;
        }
        private set;
    }

    public Campaign camp {
        get {
            System.debug('camp:'+camp);
            if (this.camp == null) this.camp = queryCampaign();

            return this.camp;
        }
        set;
    }

    public void actionSupport(){}

    public PageReference pgChange() {
        //Grabbing the pertinent page changes
        Integer indexToChange = Integer.valueOf(ApexPages.currentPage().getParameters().get('indexToChange'));
        String pgChangeType = ApexPages.currentPage().getParameters().get('pgChangeType');

        if (indexToChange != null && String.isNotBlank(pgChangeType)) {
            //Correcting the index
            if (indexToChange < 1) indexToChange = 1;
            if (indexToChange > this.autoFollowUps.size()) indexToChange = this.autoFollowUps.size();
            indexToChange--;

            //Getting the auto follow up wrapper
            AutoFollowUpWrap afuw = this.autoFollowUps[indexToChange];
            //Doing the requested action
            if (pgChangeType.equalsIgnoreCase('moveUp') || pgChangeType.equalsIgnoreCase('moveDown')) {
                for (Integer i = 0; i < this.autoFollowUps.size(); i++) System.debug('i:'+i+', step:'+this.autoFollowUps[i].stepNumber+', Subject: '+this.autoFollowUps[i].autoFollowUp.TaskSubject__c);
                Integer changeType = pgChangeType.equalsIgnoreCase('moveUp') ? -1 : 1;
                System.debug(changeType);
                AutoFollowUpWrap old = this.autoFollowUps[indexToChange+changeType];

                old.stepNumber -= changeType;
                afuw.stepNumber+= changeType;

                this.autoFollowUps[old.stepNumber-1] = old;
                this.autoFollowUps[afuw.stepNumber-1] = afuw;

                for (Integer i = 0; i < this.autoFollowUps.size(); i++) System.debug('i:'+i+', step:'+this.autoFollowUps[i].stepNumber+', Subject: '+this.autoFollowUps[i].autoFollowUp.TaskSubject__c);
            }

            if (pgChangeType.equalsIgnoreCase('removeItem') && afuw.autoFollowUpId == null) {
                this.autoFollowUps.remove(indexToChange);
                this.autoFollowUps = doAutoFollowUpSort(autoFollowUps);
            }

            if (pgChangeType.equalsIgnoreCase('undoRemoveItem')) afuw.removeMe = false;
            System.debug(JSON.serializePretty(this.autoFollowUps));

            //Re-setting the page params
            /*ApexPages.currentPage().getParameters().put('indexToChange',null);
            ApexPages.currentPage().getParameters().put('pgChangeType',null);*/
        }

        return null;
    }

    public PageReference doReOrder() {
        this.autoFollowUps = doAutoFollowUpSort(autoFollowUps);
        return null;
    }

    public List<AutoFollowUpWrap> autoFollowUps {

        get {

            if (this.autoFollowUps == null) this.autoFollowUps = new List<AutoFollowUpWrap>();

            return this.autoFollowUps;
        }

        set;
    }

    public Integer numAutoFollowUps {
        get {
            return this.autoFollowUps.size();
        }
    }

    //Default constructor
    public ManageAutoFollowUpsCont() {
        System.debug('constructor');
    }

    //Constructor with a standard controller
    public ManageAutoFollowUpsCont(ApexPages.StandardController sc) {
        if (sc == null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No standard controller was passed!'));
        Id scId = sc.getId();
        Boolean hadNoId = scId == null;
        //Accounting for clicking on the new button from Campaign related list
        if (hadNoId) {
            for (String key : ApexPages.currentPage().getParameters().keySet()) {
                if (key.endsWith('_lkid')) scId = ApexPages.currentPage().getParameters().get(key);
            }
        }

        String sobjType = scId != null ? scId.getSobjectType().getDescribe().getName() : '';
        if (sobjType.equalsIgnoreCase('Campaign')) this.campId = scId;
        if (sobjType.equalsIgnoreCase('CampaignMember')) this.campId = [SELECT CampaignId FROM CampaignMember WHERE Id = :scId][0].CampaignId;
        if (sobjType.equalsIgnoreCase('Auto_Follow_Up__c')) this.campId = [SELECT Campaign__c FROM Auto_Follow_Up__c WHERE Id = :scId][0].Campaign__c;

        if (this.campId == null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The campaign Id was not located!'));
        //Adding an extra step since there was no id passed, which means the "New" button was clicked
        if (hadNoId) addStep();
    }

    /**
     * @description This function will add a step to the auto follow up list
     *
     * @return      The page reference
     */
    public PageReference addStep() {
        System.debug('addStep');
        this.autoFollowUps.add(new AutoFollowUpWrap(this.autoFollowUps.size()+1));

        return null;
    }

    /**
     * @description This function will save the auto follow ups
     *
     * @return      The page reference
     */
    public PageReference doSave() {
        System.debug('doSave');
        PageReference pr;
        if (this.canSave) {
            //Process the auto follow up and do upserts and deletes
            List<Auto_Follow_Up__c> autoFollowUps2Upsert = processAutoFollowUps();
            List<AutoFollowUpWrap> afuws = new List<AutoFollowUpWrap>();

            //Sorting the records post upsert and delete
            for (Auto_Follow_Up__c afu : autoFollowUps2Upsert) afuws.add(new AutoFollowUpWrap(afu));
            afuws = doAutoFollowUpSort(afuws);
            //Going through the upserted records to check for errors
            for (Database.UpsertResult ur : Database.upsert(autoFollowUps2Upsert)) {

                if (!ur.success) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ur.errors[0].message));
            }
            //If there are no errors present, connect the auto follow up records to the previous records
            if (ApexPages.getMessages().isEmpty()) {

                for (Integer i = 0; i < autoFollowUps.size(); i++) processUpsertResult(autoFollowUps2Upsert, i);
                //Checking the update results fro any errors
                for (Database.SaveResult sr : Database.update(autoFollowUps2Upsert)) {

                    if (!sr.success) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sr.errors[0].message));
                }
            }

            if (ApexPages.getMessages().isEmpty()) pr = new PageReference('/'+campId).setRedirect(true);
        }

        return pr;
    }

    /**
     * @description This function will return the user back to the originating campaign
     *
     * @return      The page reference re-directing to the campaign
     */
    public PageReference cancel() {

        return new PageReference('/'+this.campId).setRedirect(true);
    }

    /**
     * @description This function will process the auto follow up steps
     *
     * @return      The list of auto follow up steps before saving
     */
    private List<Auto_Follow_Up__c> processAutoFollowUps() {
        System.debug('processAutoFollowUps');
        List<Auto_Follow_Up__c> returnList = new List<Auto_Follow_Up__c>();
        List<Id> afus2Delete = new List<Id>();
        //Going through the wrapped auto follow ups and determining how they need to be processed
        for (Integer i = 0; i < autoFollowUps.size(); i++) {

            AutoFollowUpWrap afuw = this.autoFollowUps[i];
            Auto_Follow_Up__c afu = afuw.autoFollowUp;
            if (afu.Id == null) afu.Campaign__c = this.campId;

            if (afuw.removeMe && afu.Id != null) afus2Delete.add(afu.Id);

            if (!afuw.removeMe) returnList.add(afu);
        }
        //Deleting any that were flagged as deletion
        Database.delete(afus2Delete);

        return returnList;
    }

    /**
     * @description                 This function will process the upsert results when saving the auto follow up records
     *
     * @param autoFollowUps2Upsert  The auto follow up upsert results
     * @param i                     The index of the iteration
     *
     * @return                      The updated auto follow up record
     */
    private Auto_Follow_Up__c processUpsertResult(List<Auto_Follow_Up__c> autoFollowUps2Upsert, Integer i) {

        Auto_Follow_Up__c auf = autoFollowUps2Upsert[i];
        auf.StepNumber__c = i+1;
        auf.Name = 'Step '+auf.StepNumber__c;

        if (i == 0) auf.PreviousAutoFollowUp__c = null;

        if (i != 0) auf.PreviousAutoFollowUp__c = autoFollowUps2Upsert[i-1].Id;

        return auf;
    }

    /**
     * @description This function will query the campaign and the auto follow up steps that are present
     *
     * @return      The queried campaign record
     */
    private Campaign queryCampaign() {
        System.debug('queryCampaign');
        List<Campaign> camps = [
                SELECT  Id, Name,
                       (SELECT Id, Name, Campaign__c, StepNumber__c, PreviousAutoFollowUp__c, TaskSubject__c, TaskComment__c, DefaultDaysUntilNextFollowup__c, DefaultHoursUntilNextFollowUp__c FROM Auto_Follow_Ups__r ORDER BY StepNumber__c)
                FROM    Campaign WHERE Id = :campId
        ];

        Campaign camp = !camps.isEmpty() ? camps[0] : new Campaign();
        //Wrapping the auto follow up records (if any)
        if (camp != null && camp.Id == campId) {
            for (Auto_Follow_Up__c afu : camp.Auto_Follow_Ups__r) autoFollowUps.add(new AutoFollowUpWrap(afu));
        }
        //If there are no steps based on the query, a step will be added by default
        if (this.autoFollowUps.size() == 0) addStep();

        return camp;
    }

    /**
     * @description This function will sort the auto follow ups and re-set the step number
     *
     * @param afuws The auto follow up wraps to sort
     *
     * @return      The sorted and updated list of auto follow up wrapped records
     */
    private List<AutoFollowUpWrap> doAutoFollowUpSort(List<AutoFollowUpWrap> afuws) {
        System.debug('about to sort');
        afuws.sort();
        System.debug('sort done');

        for (Integer i = 0; i < afuws.size(); i++) afuws[i].stepNumber = i + 1;

        return afuws;
    }

    //This class contains the information to create a wrapper for processing the auto follow up records
    public class AutoFollowUpWrap implements Comparable {

        public Integer stepNumber {
            get;
            set {
                if (value != null) {
                    this.autoFollowUp.StepNumber__c = value;
                    this.stepNumber = value;
                }
            }
        }

        public Boolean removeMe {
            get {

                if (this.removeMe == null) this.removeMe = false;

                return this.removeMe;
            }
            set;
        }

        public Id autoFollowUpId {
            get {
                if (this.autoFollowUpId == null && autoFollowUp != null) this.autoFollowUpId = autoFollowUp.Id;
                return this.autoFollowUpId;
            }
            set;
        }

        public Auto_Follow_Up__c autoFollowUp {
            get {

                if (this.autoFollowUp == null) this.autoFollowUp = new Auto_Follow_Up__c();

                return this.autoFollowUp;
            }

            set;
        }

        //This constructor will create the object based on the auto follow up record
        public AutoFollowUpWrap(Auto_Follow_Up__c afu) {

            this.autoFollowUp = afu;
            this.stepNumber = afu != null ? Integer.valueOf(afu.StepNumber__c) : null;
        }

        //This constructor will create the object with the step number set
        public AutoFollowUpWrap(Integer stepNum) {

            this.stepNumber = stepNum;
            this.autoFollowUp.StepNumber__c = stepNum;
            //this.autoFollowUp.DefaultDaysUntilNextFollowup__c = 1;
            this.autoFollowUp.DefaultHoursUntilNextFollowUp__c = 48;
        }

        /**
         * @description     This function will sort the wrapped record
         *
         * @param compareTo The record to compare this record against
         *
         * @return          Whether or not the record should be above, below or at the same level
         */
        public Integer compareTo(Object compareTo) {
            Integer returnNum = -1;
            AutoFollowUpWrap afuw = (AutoFollowUpWrap) compareTo;
            System.debug(LoggingLevel.Error, '*** this.stepNumber: ' + this.stepNumber + ', '+this.autoFollowUp.TaskSubject__c);
            System.debug(LoggingLevel.Error, '*** afuw.stepNumber: ' + afuw.stepNumber + ', '+afuw.autoFollowUp.TaskSubject__c);
            if (afuw.stepNumber == this.stepNumber) returnNum = 0;
            if (afuw.stepNumber < this.stepNumber) returnNum = 1;
            System.debug(LoggingLevel.Error, '*** returnNum: ' + returnNum);
            return returnNum;
        }
    }
}