public with sharing class xctPayee {
    public Id owner {get;set;}
    public Payee__c payee {get;set;}
    public Id Id {get;set;}
    
    //constructor to retrieve payee record
    public xctPayee(ApexPages.StandardController controller) {
        System.debug('Retrieving payee');
        
        // get the payee and stuff it into a public property
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> fieldMap =gd.get('Payee__c').getDescribe().fields.getMap(); 
        List<String> fields = new List<String>();
        for(Schema.SObjectField ft : fieldMap.values()){
            fields.add(ft.getDescribe().getName());
        }
        
        controller.addFields(fields);
        
        payee =  (Payee__c) controller.getRecord();
        
        // the ID is always handy to have
        Id = payee.Id;
        
        // System.debug('The payee record: ' + payee);
    }
    
    public PageReference sendPayee(){
        
        
        /* String s = JSON.serialize(payee);
        
        if (String.isBlank(payee.Payee_Name__c)) { 
            payee.adderror('Payee Name is required to send to Solomon');
            return null;
        }
        else {
            
           
            // send the data to the queue
            // Vendor Case:
            if (String.isBlank(payee.SL_Vendor_ID__c)) { 
                xctDataClass.makeCallout('SFPAYEE', payee.Id, 'ADD', s);
            }
            else {
                xctDataClass.makeCallout('SFPAYEE', payee.Id, 'UPDATE', s);
            }
            payee.Sent_to_Solomon__c = System.now();   
            upsert payee;  
      
        } */
        
        // lets redirect back to the calling page
        // PageReference pageRef = new PageReference('/'+Id);
        PageReference pageRef = new ApexPages.StandardController(payee).view();
        pageRef.setRedirect(true);
        return pageRef;       

    }
   

}