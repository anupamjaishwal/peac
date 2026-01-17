/**
 * @description Controller for re-assigning tasks
 * @see         SAL-1875
 */
public without sharing class TC_MassReAssignTasks {

    private List<Task> tasksToReAssign {get;set;}
    private String retUrl {get;set;}

    public TC_MassReAssignTasks(ApexPages.StandardSetController ssc) {
        this.tasksToReAssign = (List<Task>) [SELECT Id, OwnerId FROM Task WHERE Id IN :ssc.getSelected()];
        this.retUrl = ApexPages.currentPage().getParameters().get('vfRetURLInSFX') != null ? ApexPages.currentPage().getParameters().get('vfRetURLInSFX') : ApexPages.currentPage().getParameters().get('retURL');
        this.retUrl = String.isNotBlank(this.retUrl) ? this.retUrl.substringAfter('.com/') : this.retUrl;
        if (this.tasksToReAssign.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There were no tasks selected!'));
    }

    public Boolean canSave {
        get {
            if (this.canSave == null) {
                User u = [SELECT Id, UserRole.DeveloperName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
                this.canSave = String.isNotBlank(u.UserRole.DeveloperName) && u.UserRole.DeveloperName.containsIgnoreCase('Manager') || u.Profile.Name.contains('Administrator');
            }
            return this.canSave;
        }
        private set;
    }

    public Task tempTask {
        get {

            if (this.tempTask == null) {

                if (this.tasksToReAssign.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There were no tasks selected!'));

                if (!this.tasksToReAssign.isEmpty()) this.tempTask = this.tasksToReAssign[0].clone(false,false,false,false);

            }

            return this.tempTask;
        }
        set;
    }

    public PageReference reAssignOwnership() {
        PageReference pr;

        if (this.canSave) {
            if (!tasksToReAssign.isEmpty() && tasksToReAssign[0].OwnerId == null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A new owner Id must be defined'));

            if (!tasksToReAssign.isEmpty() && tasksToReAssign[0].OwnerId != null) {

                for (Task t : tasksToReAssign) t.OwnerId = tempTask.OwnerId;

                List<Database.SaveResult> drs = Database.update(tasksToReAssign);

                for (Database.SaveResult dr :drs) {

                    if (!dr.errors.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dr.errors[0].message));
                }
            }

            if (ApexPages.getMessages().isEmpty()) pr = new PageReference('/' + (String.isNotBlank(retUrl) ? retUrl : ''));
            if (pr != null) System.debug(pr.getUrl());
            if (pr != null) pr.setRedirect(true);
        }

        return pr;
    }

    public PageReference doCancel() {
        PageReference pr = new PageReference('/'+(String.isNotBlank(retUrl) ? retUrl : ''));
        pr.setRedirect(true);
        return pr;
    }
}