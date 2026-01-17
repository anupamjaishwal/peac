public class attachmentTriggerHandler {
	
    public Static void processNewAttachment(List<Attachment> newList) {
    	System.Debug('Onbaes: List:' + newList);
	    List<Opportunity> accountList = new List<Opportunity>();
	    Set<Id> opptyIds = new Set<Id>();
	    Set<Id> attIds = new Set<Id>();
	    for(Attachment att : newList){
	         if(att.ParentId.getSobjectType() == Opportunity.SobjectType){
	              opptyIds.add(att.ParentId);
	              attIds.Add(att.ID);
	         }
	    }
        System.Debug('Onbaes: Selected Attachments:' + attIds);
	
	//	for(String attID : attIds)
     //       MARLIN_OnBaseCallout.sendDocToOnbase(attID);
        
      //  MARLIN_OnBaseCallout.sendDocToOnbase('00P0S000000GJdpUAG');
    }	
    
}