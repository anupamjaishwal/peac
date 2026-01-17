@isTest
public class SL_UpdateTaskTest {
    @isTest
    static void testUpdateTasks() {
        // Create test tasks
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 5; i++) {
            Task t = new Task(
                Subject = 'Test Task ' + i,
                Status = 'Not Started',
                Priority = 'Normal'
            );
            tasks.add(t);
        }
        insert tasks;

        // Update tasks
        for (Task t : tasks) {
            t.Status = 'Completed';
        }

        Test.startTest();
        SL_UpdateTasks.updateTasks(tasks);
        Test.stopTest();

        // Verify tasks were updated
        List<Task> updatedTasks = [SELECT Id, Status FROM Task WHERE Id IN :tasks];
        for (Task t : updatedTasks) {
            System.assertEquals('Completed', t.Status);
        }
    }
}