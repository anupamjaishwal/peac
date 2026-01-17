public with sharing class xctSF2SLLogs {

    public xctSF2SLLogs(ApexPages.StandardSetController controller) {

    }

    public Id owner {get;set;}
    public SF2SLLog__c sf2SLLogs {get;set;}
    public Id Id {get;set;}
    
    //constructor to retrieve account record
    public xctSF2SLLogs(ApexPages.StandardController controller) {
        System.debug('Retrieving account');
        
    // get the account and stuff it into a public property
    sf2SLLogs=  (SF2SLLog__c) controller.getRecord();
        
    // the ID is always handy to have
    Id = sf2SLLogs.Id;
}
    
    public PageReference clearSF2SLLogs(){
        
        List<SF2SLLog__c> sf2SLLogs = [select id from SF2SLLog__c];
        delete sf2SLLogs;
        
        // lets redirect back to the calling page
        PageReference pageRef = new PageReference('/'+Id);
        pageRef.setRedirect(true);
        return pageRef;
    }

}