trigger PrimaryContactOnOpportunity on Opportunity (before insert,before update) {
    /*
   if(Trigger.new <> null)
   {
   List<OpportunityContactRole> contactRoleArray = new  List<OpportunityContactRole>();
   Set <Id> oppIds = new Set <Id> ();
   for (Opportunity opp : Trigger.new) {
       if (opp.Probability <= 50 && opp.Primary_Contact__c == null) {
           oppIds.add (opp.Id);
       }
   }
   if (!oppIds.isEmpty ())
   
   contactRoleArray = [select ContactID, isPrimary from OpportunityContactRole where OpportunityId IN :oppIds];

   for (Opportunity o : Trigger.new) {

       if (contactRoleArray.size() > 0 && contactRoleArray != null) {

           o.Primary_Contact__c = contactRoleArray[0].ContactID;

       }
   }
   }*/


}