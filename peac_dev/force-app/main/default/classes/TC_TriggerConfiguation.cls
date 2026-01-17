public class TC_TriggerConfiguation {
    // Custom metadata queries don't count against the limit
    // Also misspelled configuration :')
    
 /* public static List <String> getConfigs (TC_TriggerContext tc) {
        List <String> configurations = new List <String> ();
        
        String query = 'SELECT Class_Name__c, Order__c FROM Trigger_Action__mdt WHERE Sobject_API_Name__c = \'' + tc.getSobjectType() + '\' AND Is_Active__c = true';
        if (tc.isAfter ()) query += ' AND Is_After__c = ' + tc.isAfter();
        if (tc.isBefore ()) query += ' AND Is_Before__c = ' + tc.isBefore();
        if (tc.isInsert ()) query += ' AND Is_Insert__c = ' + tc.isInsert();
        if (tc.isUpdate ()) query += ' AND Is_Update__c = ' + tc.isUpdate();
        if (tc.isDelete ()) query += ' AND Is_Delete__c = ' + tc.isDelete(); 
        query += ' ORDER BY Order__c ASC';
        
        List <Trigger_Action__mdt> actions = new List <Trigger_Action__mdt> ();
        actions = Database.query(query);
        
        if (actions.isEmpty ()) return configurations; 
        
        
        for (Trigger_Action__mdt action : actions) {
            configurations.add (action.Class_Name__c);            
        }
        
        return configurations;
    } */
    
    
    public static List <String> getConfigs (TC_TriggerContext tc) {
        List <String> configurations = new List <String> ();
        
        /*String query = 'SELECT Class_Name__c, Order__c FROM Trigger_Action__mdt WHERE Sobject_API_Name__c = \'' + tc.getSobjectType() + '\' AND Is_Active__c = true';
        if (tc.isAfter ()) query += ' AND Is_After__c = ' + tc.isAfter();
        if (tc.isBefore ()) query += ' AND Is_Before__c = ' + tc.isBefore();
        if (tc.isInsert ()) query += ' AND Is_Insert__c = ' + tc.isInsert();
        if (tc.isUpdate ()) query += ' AND Is_Update__c = ' + tc.isUpdate();
        if (tc.isDelete ()) query += ' AND Is_Delete__c = ' + tc.isDelete(); 
        query += ' ORDER BY Order__c ASC';
        
        List <Trigger_Action__mdt> actions = new List <Trigger_Action__mdt> ();
        actions = Database.query(query);
        
        if (actions.isEmpty ()) return configurations; 
        
        
        for (Trigger_Action__mdt action : actions) {
            configurations.add (action.Class_Name__c);            
        }*/
        //system.debug('Trigger_Action__mdt.getAll().values():'+Trigger_Action__mdt.getAll());
        List<Trigger_Action__mdt> actions = Trigger_Action__mdt.getAll().values();
        system.debug('actions:'+actions);
        for (Trigger_Action__mdt action : actions) {
            system.debug(action);
            if(action.Sobject_API_Name__c == tc.getSobjectType() && ACTION.Is_Active__c && 
                (
                    (tc.isAfter () && action.Is_After__c && ((tc.isInsert () && action.Is_Insert__c) || (tc.isUpdate () && action.Is_Update__c)  || (tc.isDelete () && action.Is_Delete__c)))||
                    (tc.isBefore () && action.Is_Before__c && ((tc.isInsert () && action.Is_Insert__c) || (tc.isUpdate () && action.Is_Update__c)  || (tc.isDelete () && action.Is_Delete__c)))

                )
            ){
                
                configurations.add (action.Class_Name__c);  
            }         
        }
        
        return configurations;
    }
}