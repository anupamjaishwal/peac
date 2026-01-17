public without sharing class TC_ListViewUtil {
    public String sobjectName {get;set;}
    public List<ListView> listViews {
        get {
            if (this.listViews == null && sobjectName != null) this.listViews = Database.query(getListViewQuery());
            return listViews;
        }
        set;
    }

    public List<SelectOption> listViewsAsSelectOptions {
        get {
            if (this.listViewsAsSelectOptions == null) {
                List<SelectOption> selectOptions = new List<SelectOption>();
                selectOptions.add(new SelectOption('','-- None --'));
                for (ListView lv : this.listViews) {
                    selectOptions.add(new SelectOption(lv.DeveloperName, lv.Name));
                }
                this.listViewsAsSelectOptions = selectOptions;
            }
            return this.listViewsAsSelectOptions;
        }
        set;
    }

    public TC_ListViewUtil(String sobjectName) {
        this.sobjectName = sobjectName;
    }

    public TC_ListViewUtil() {}

    /**
     * @description This function will get the list view conditions via the REST API
     *
     * @param lv    The list view to query
     *
     * @return      The list view conditions
     */
    public String getListViewConditions(ListView lv) {
        HttpRequest req = createRequest(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v50.0/sobjects/'+lv.SobjectType+'/listviews/'+lv.Id+'/describe');
        HttpResponse resp = getResponse(req);
        QueryWrapper qw = (QueryWrapper) json.deserialize(resp.getBody(), QueryWrapper.class);
        return qw.query;
    }

    /**
     * @description     Creates the HTTP request for the REST API
     *
     * @param endPoint  The end point to go to (includes the list view Id and sobject ype)
     *
     * @return          The HTTP request
     */
    public HttpRequest createRequest(String endPoint) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer '+UserInfo.getSessionId());
        req.setEndpoint(endPoint);
        return req;
    }

    /**
     * @description     This function will get the response from the REST API with the conditions
     *
     * @param req       The HTTP Request to send
     *
     * @return          The HTTP Response
     */
    public HttpResponse getResponse(HttpRequest req) {
        HttpResponse resp;
        resp = Test.isRunningTest() ? new HttpResponse() : new Http().send(req);
        if (Test.isRunningTest()) resp.setBody(JSON.serializePretty(new QueryWrapper()));
        return resp;
    }

    /**
     * @description                     This function will get a map of list views by the developer name of the list view
     *
     * @param listViewDeveloperNames    The Developer Names of the List Views to query
     *
     * @return                          The Map of DeveloperName to ListView record
     */
    public Map<String, ListView> getListViewMap(Set<String> listViewDeveloperNames) {
        Map<String, ListView> returnMap = new Map<String, ListView>();

        for (ListView lv : (List<ListView>) Database.query(getListViewQuery() + ' AND DeveloperName IN :listViewDeveloperNames')) {
            returnMap.put(lv.DeveloperName, lv);
        }

        return returnMap;
    }

    /**
     * @description Contains the base ListView query
     *
     * @return      The base ListView query
     */
    private String getListViewQuery() {
        return 'SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE SobjectType = :sobjectName AND IsSoqlCompatible = TRUE';
    }

    //This wrapper class enables the easy translation of an HTTP response from salesforce based on the list view
    public class QueryWrapper {
        public String query{get; set;}
        public queryWrapper() {
            if (Test.isRunningTest()) this.query = 'SELECT Id FROM Campaign WHERE CampaignId = xyz';
        }
    }

}