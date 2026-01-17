// Extension to delete all of the selected objects
public without sharing class MassDeleteExtension {

    ApexPages.StandardSetController setCon;
    public String error { get; set; }
    public PageReference originalUrl { get; set; }

    public MassDeleteExtension(ApexPages.StandardSetController controller) {
        setCon = controller;
    }

    public String getMySelectedSize() {
        return setCon.getSelected().size() + '';
    }
    
    public PageReference deleteRecords(){
        List<String> managerRoles = new List<String>{
            'Collections Manager',
            'Collections Supervisor',
            'Customer Service Management',
            'Insurance Management',
            'Operations Management',
            'System Admin',
            'VP of Collections'
        };
        List<UserRole> currentRole = [SELECT Id, Name FROM UserRole WHERE Id = :System.UserInfo.getUserRoleId()];
        if(currentRole.size() > 0 && managerRoles.contains(currentRole[0].Name)){
            List<SObject> toDelete =setCon.getSelected();
            Boolean gotUnhandledError = false;
            if(toDelete.size() > 0){
                String objectApiName = String.valueOf(toDelete[0].Id.getSobjectType());
                String idList = '';
                for(SObject record : toDelete){
                    idList += record.Id + '\',\'';
                }
                idList = idList.removeEnd('\',\'');
                List<SObject> existing = Database.query('SELECT Id FROM ' + objectApiName + ' WHERE Id IN (\'' + idList + '\')');
                try{
                    List<Database.DeleteResult> results = Database.delete(existing, false);
                    for(Database.DeleteResult oneResult :results){
                        if(!oneResult.isSuccess() && oneResult.getErrors()[0].getStatusCode() != System.StatusCode.ENTITY_IS_DELETED){
                            gotUnhandledError = true;
                            for(Database.Error err: oneResult.getErrors()){
                                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                    err.getStatusCode() + ': ' + err.getMessage()));
                            }
                        }
                    }
                }catch(Exception e){}
                
            }
            if(!gotUnhandledError){
                originalUrl = setCon.cancel();
            }
        }else{
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                    'Cases couldn\'t be deleted. Only Managers have the necessary permission to delete Cases.'));
            originalUrl = ApexPages.currentPage();
        }
        return originalUrl;
    }

}