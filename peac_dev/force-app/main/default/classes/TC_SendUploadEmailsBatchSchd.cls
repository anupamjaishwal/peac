//SAL-3221

public class TC_SendUploadEmailsBatchSchd implements Schedulable{
    public void execute(SchedulableContext sc) { 
       // Database.executebatch (new TC_SendUploadEmailsBatch (), 10);
    }
}