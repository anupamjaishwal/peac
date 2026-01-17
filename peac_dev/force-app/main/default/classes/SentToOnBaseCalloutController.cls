public class SentToOnBaseCalloutController {
	
    public String selectedType {get;set;}
    public Boolean selectedAwesomeness {get;set;}
    public String description {get;set;}
    private Opportunity oppty {get;set;} 
    public String fileName {get;set;}
    public Blob fileBody {get;set;}
    
    public SentToOnBaseCalloutController(ApexPages.StandardController controller) { 
        this.oppty = (Opportunity)controller.getRecord();
        //processAttachments();
    }   
    
    // creates a new Contact_Attachment__c record
    public PageReference processAttachments() {
    	
        try {
                List<Opportunity_Attachment__c> lAttachmentList = [select id,Attachment__c,Name from Opportunity_Attachment__c 
                											where Opportunity__c = :oppty.Id 
                											And Sent_To_OnBase__c = False];
                											
				System.Debug('On Base List to process:' + lAttachmentList);
				
			//	for(Opportunity_Attachment__c att : lAttachmentList)
           //   		MARLIN_OnBaseCallout.sendDocToOnbase(att.Attachment__c);
           
            
        } catch (Exception e) {
            ApexPages.AddMessages(e);
        }    	
		return new PageReference('/'+oppty.Id);
		
    }
    
 
    
    public PageReference back() {
        return new PageReference('/'+oppty.Id);
    }  
    
    
}