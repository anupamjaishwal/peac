global class DocGenQueuePurgeBatch implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext bc){
        date d=system.today().adddays(-30);        
        return Database.getQueryLocator( 'Select id from Loop__Document_Request__c where CreatedDate <=:d' );
    }
    
    global void execute(Database.BatchableContext BC, list<sObject> scope)
    {     
    	system.debug('records fetched are'+scope);
        	delete scope;   
            //DataBase.emptyRecycleBin(scope); 
    }
    
    
    global void finish(Database.BatchableContext BC) 
    {                 
        
        
       
    }
}