/**
 * @description This controller is used by various pul task buttons
 * @see         SAL-1875
 */
public without sharing class TC_PullTaskCont {

    public Integer numToPull {
        get {
            if (this.numToPull == null) this.numToPull = 1;

            return this.numToPull;
        }

        set {
            if (value != null) this.numToPull = (Math.min(value, maxToPull));
        }
    }

    private TC_ListViewUtil lvu {
        get {
            if (this.lvu == null) this.lvu = new TC_ListViewUtil('Task');
            return this.lvu;
        }
        set;
    }

    public Integer maxToPull {
        get {
            if (this.maxToPull == null) this.maxToPull = Integer.valueOf(sdrProspectingSettings.TaskPullLimit__c);
            return this.maxToPull;
        }
        set;
    }

    private SDR_Prospecting_Settings__c sdrProspectingSettings {
        get {
            if (sdrProspectingSettings == null) {
                sdrProspectingSettings = SDR_Prospecting_Settings__c.getInstance();
                if (sdrProspectingSettings.Name == null) sdrProspectingSettings = (SDR_Prospecting_Settings__c) SDR_Prospecting_Settings__c.SObjectType.newSObject(null, true);
            }
            return sdrProspectingSettings;
        }
        set;
    }

    private String retUrl {
        get;
        set;
    }

    public Boolean pullAnyCampaign {
        get {
            if (pullAnyCampaign == null && ApexPages.currentPage().getUrl().contains('?')) this.pullAnyCampaign = ApexPages.currentPage().getUrl().substringBetween('apex/', '?').contains('Any');
            if (pullAnyCampaign == null && !ApexPages.currentPage().getUrl().contains('?')) this.pullAnyCampaign = ApexPages.currentPage().getUrl().substringAfter('apex/').contains('Any');
            return this.pullAnyCampaign;
        }
        set;
    }

    public List<Task> tasks {
        get {
            if (this.tasks == null) queryTasks(true);

            return this.tasks;
        }
        set;
    }

    private ListView lv {get; set;}

    private ListViews__c lvs {
        get {
            if (this.lvs == null && lv != null) this.lvs = getTheListViewCs(lv);
            return lvs;
        }
        set;
    }

    Map<String, String> fieldToCondMap {
        get {
            if (this.fieldToCondMap == null) this.fieldToCondMap = mapFieldsToConds(this.lvs);
            return this.fieldToCondMap;
        }
        set;
    }

    public TC_PullTaskCont(ApexPages.StandardSetController ssc) {
        system.debug('******getFilterId'+ ssc.getFilterId());
        this.lv = [SELECT Id, SobjectType, LastModifiedDate FROM ListView WHERE Id = :ssc.getFilterId()];
        this.retUrl = ApexPages.currentPage().getParameters().get('vfRetURLInSFX') != null ? ApexPages.currentPage().getParameters().get('vfRetURLInSFX') : ApexPages.currentPage().getParameters().get('retURL');
        this.retUrl = String.isNotBlank(this.retUrl) ? this.retUrl.substringAfter('.com/') : this.retUrl;
    }

    public TC_PullTaskCont(ApexPages.StandardController sc) {
        this.pullAnyCampaign = true;
        this.retUrl = ApexPages.currentPage().getParameters().get('vfRetURLInSFX') != null ? ApexPages.currentPage().getParameters().get('vfRetURLInSFX') : ApexPages.currentPage().getParameters().get('retURL');
        this.retUrl = String.isNotBlank(this.retUrl) ? this.retUrl.substringAfter('.com/') : this.retUrl;
    }

    public TC_PullTaskCont() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        for (String key : params.keySet()) System.debug(key+'=>'+params.get(key));
    }

    /**
     * @description         This function will query leads based on properties
     *
     * @param singlePull    If a single lead should be pulled
     *
     * @return              The list of tasks
     */
    public List<Task> queryTasks(Boolean singlePull) {
        List<Task> returnList;
        String campaignName = fieldToCondMap != null && fieldToCondMap.get('fml_PrimaryAccountCampaign__c') != null ? fieldToCondMap.get('fml_PrimaryAccountCampaign__c').trim().removeStart('\'').removeEnd('\'') : '';
        String query = 'SELECT Id FROM Task WHERE fml_Is_SDR_QueueOrMine__c = true AND IsClosed = false AND AutoFollowUp__c <> NULL ';
        query += String.isBlank(campaignName) || this.pullAnyCampaign ? '' : ' AND fml_PrimaryAccountCampaign__c = :campaignName';
        system.debug('=====campaignName'+ campaignName);
        system.debug('=====this.pullAnyCampaign'+ this.pullAnyCampaign);
        
        
        Id userId = UserInfo.getUserId();
        query += numToPull != null && numToPull > 1 ? ' AND OwnerId != :userId' : '';
        query +=  ' ORDER BY fml_PrimaryLeadScore__c DESC, ActivityDate';
        if (singlePull) query += ' LIMIT 1';
        if (!singlePull) query += ' LIMIT '+numToPull;
        system.debug('======query'+ query);
        returnList = (List<Task>) Database.query(query);
        system.debug('======returnList'+ returnList);
        return returnList;

    }

    /**
     * @description Button action, will re-direct the user to the task that was pulled
     *
     * @return      The re-direct page reference
     */
    public PageReference goToTask() {
        PageReference pr;
        this.tasks = queryTasks(true);
        if (this.tasks != null && !this.tasks.isEmpty()) {
            pr = new PageReference('/'+this.tasks[0].Id);
            reAssignTasks();
        }
        if (this.tasks.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'No tasks were found in queue or assigned to you '+ ((!pullAnyCampaign && fieldToCondMap.get('fml_PrimaryAccountCampaign__c') != null) ? 'for the '+fieldToCondMap.get('fml_PrimaryAccountCampaign__c')+' campaign.' : '.')));
        if (pr != null) pr.setRedirect(true);
        return pr;
    }

    /**
     * @description This function will attempt to pull multiple tasks
     *
     * @return      The re-direct to the return URL based on the button that was pushed
     */
    public PageReference pullTasks() {
        PageReference pr;

        try {
            this.tasks = queryTasks(false);
            system.debug('this.tasks ======' + this.tasks);
            if (this.tasks != null && !this.tasks.isEmpty()) {
                reAssignTasks();
                pr = new PageReference('/' + (String.isNotBlank(this.retUrl) ? this.retUrl : ''));
            }
            if (this.tasks.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'No tasks were found in queue or assigned to you '+ ((!pullAnyCampaign && fieldToCondMap.get('fml_PrimaryAccountCampaign__c') != null) ? 'for the '+fieldToCondMap.get('fml_PrimaryAccountCampaign__c')+' campaign.' : '.')));
            if (pr != null) pr.setRedirect(true);
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error:'+e.getMessage()));
            System.debug(e.getStackTraceString());
        }

        return pr;
    }

    /**
     * @description This function will re assign the tasks property with the current user as the owner
     */
    private void reAssignTasks() {
        for (Task t : this.tasks) {
            t.OwnerId = UserInfo.getUserId();
        }
        update this.tasks;
    }

    /**
     * @description This function will get the list view custom setting which will store the conditions
     * This is needed because the only way to pull conditions from a list view is to hit the SFDC REST API, to prevent
     * excessive API usage and in creae performance, this we'll update the custom setting once a day.
     *
     * @param lv    The list view
     *
     * @return      The list view custom setting
     */
    private ListViews__c getTheListViewCs(ListView lv) {
        ListViews__c lvCs;
        System.debug('================LV189'+lv);
        if (lv != null) {
            List<ListViews__c> lvs = [SELECT Name, Condition1__c, Condition2__c, Condition3__c, Condition4__c, Condition5__c, Condition6__c, Condition7__c, Condition8__c, Condition9__c, Condition10__c, LastModifiedDate,OrderBy__c FROM ListViews__c WHERE Name = :lv.Id];
            lvCs = lvs.isEmpty() ? new ListViews__c(Name = lv.Id) : lvs[0];

            if (lvs.isEmpty() || lvs[0].LastModifiedDate < lv.LastModifiedDate) {
                String query = getListViewConditions(lv);
                String whereConds = query.substringAfter(' WHERE ').substringBefore(' ORDER BY ');
                List<String> conditions = whereConds.replaceAll('\\(|\\)','').split('\\sAND\\s|\\sOR\\s');
                for (Integer i = 0; i < conditions.size(); i++) {
                    lvCs.put('Condition'+(i+1)+'__c',conditions[i]);
                }

                lvCs.OrderBy__c = query.substringAfter(' ORDER BY ');
                upsert lvCs;
            }
        }
        system.debug('===lvCs'+ lvCs);
        return lvCs;
    }

    /**
     * @description This function will map fields to conditions
     *
     * @param lvs   The list view custom setting
     *
     * @return      The map of fields and conditions
     */
    private Map<String, String> mapFieldsToConds(ListViews__c lvs) {
        Map<String, String> returnMap = new Map<String, String>();
        if (lvs != null) {
            for (Integer i = 0; i < 10; i++) {
                String cond = String.valueOf(lvs.get('Condition'+(i+1)+'__c'));
                System.debug(cond);
                if (String.isNotBlank(cond)) {
                    List<String> fieldAndCond = cond.split('\\b >= \\b|\\b <= \\b|\\b > \\b|\\b < \\b|\\s=\\s|\\b LIKE \\b|\\b NOT \\b|\\b IN \\b');
                    if (fieldAndCond.size() == 2) {
                        System.debug(fieldAndCond[0]+':'+fieldAndCond[1]);
                        returnMap.put(fieldAndCond[0], fieldAndCond[1]);
                    }
                }
            }
        }
        system.debug('====returnMap'+ returnMap);
        return returnMap;
    }

    /**
     * @description This function will get the list view conditions via the REST API
     *
     * @param lv    The list view to query
     *
     * @return      The list view conditions
     */
    private String getListViewConditions(ListView lv) {
        return this.lvu.getListViewConditions(lv);
    }
}