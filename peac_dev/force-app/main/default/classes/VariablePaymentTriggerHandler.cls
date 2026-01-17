public class VariablePaymentTriggerHandler{

 public static void populateVPdetailsonOpp(List<Variable_Payment__c> newList) {
        
      
      Set<String> lVarPayOpptyID = new Set<String>();
      List<Opportunity> lUpdateOpptyList = new List<Opportunity>();
      Integer lCounter = 1;
      
      for(Variable_Payment__c vp : newList){
        
        if(vp.Opportunity__c != null)
          lVarPayOpptyID.Add(vp.Opportunity__c);
      }

    if(lVarPayOpptyID.Size()  == 0)
      return;
    
    List<Opportunity> lOpptyVarPay = [SELECT ID,NAME,(SELECT ID,of_payments__c,Payment_Amount__c FROM Variable_Payments__r)
                     FROM OPPORTUNITY WHERE ID IN: lVarPayOpptyID];
                     
     for(Opportunity opty : lOpptyVarPay)  {
       
       for(Integer i=1; i<6; i++){

         opty.Put('Payment_Amount_VP' + String.ValueOf(i) + '__c',null);
         opty.Put('Number_of_Payments_VP' + String.ValueOf(i) + '__c',null);
       }
         
       for(Variable_Payment__c varpay : opty.Variable_Payments__r) {
         
         opty.Put('Payment_Amount_VP' + String.ValueOf(lCounter) + '__c',varpay.Payment_Amount__c);
         opty.Put('Number_of_Payments_VP' + String.ValueOf(lCounter) + '__c',varpay.of_payments__c);

         lCounter += 1;
         if(lCounter > 5)
           break;         
       }
       lUpdateOpptyList.Add(opty);
       
     }
    
    System.Debug(lUpdateOpptyList);
    
    try{
      if(lUpdateOpptyList.Size() > 0)
        update lUpdateOpptyList;      
    }
    catch(Exception e){
      System.debug(e.getMessage());
    }

      
 
    }
    
    
     public static void populateVPdetailsonOppdelete(List<Variable_Payment__c> vpList) {
        
      
      Set<String> lVarPayOpptyID = new Set<String>();
      List<Opportunity> lUpdateOpptyList = new List<Opportunity>();
      Integer lCounter = 1;
      
      for(Variable_Payment__c vp : vpList){
        
        if(vp.Opportunity__c != null)
          lVarPayOpptyID.Add(vp.Opportunity__c);
      }
      
      system.debug('vpList***' + vpList);

    if(lVarPayOpptyID.Size()  == 0)
      return;
    
    List<Opportunity> lOpptyVarPay = [SELECT ID,NAME,(SELECT ID,of_payments__c,Payment_Amount__c FROM Variable_Payments__r)
                     FROM OPPORTUNITY WHERE ID IN: lVarPayOpptyID];
                     
     
     system.debug('lOpptyVarPay ***' + lOpptyVarPay );
     for(Opportunity opty : lOpptyVarPay)  {
       
       for(Integer i=1; i<6; i++){

         opty.Put('Payment_Amount_VP' + String.ValueOf(i) + '__c',null);
         opty.Put('Number_of_Payments_VP' + String.ValueOf(i) + '__c',null);
       }
         
       for(Variable_Payment__c varpay : opty.Variable_Payments__r) {
         
         opty.Put('Payment_Amount_VP' + String.ValueOf(lCounter) + '__c',varpay.Payment_Amount__c);
         opty.Put('Number_of_Payments_VP' + String.ValueOf(lCounter) + '__c',varpay.of_payments__c);

         lCounter += 1;
         if(lCounter > 5)
           break;         
       }
       lUpdateOpptyList.Add(opty);
       
     }
    
    System.Debug('***' + lUpdateOpptyList);
    
    try{
      if(lUpdateOpptyList.Size() > 0)
        update lUpdateOpptyList;      
    }
    catch(Exception e){
      System.debug(e.getMessage());
    }

      
 
    }
}