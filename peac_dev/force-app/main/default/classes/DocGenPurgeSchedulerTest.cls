@istest
class DocGenPurgeSchedulerTest{
	public static testMethod void testschedule() {
		Test.StartTest();
        Loop__Document_Request__c dq = new Loop__Document_Request__c ();
        dq.createddate = system.today().addDays(-30);
		insert dq;
		DocGenQueuePurgeSchedule testsche = new DocGenQueuePurgeSchedule();
		//String sch = '0 0 23 * * ?';
		//system.schedule('Test status Check', sch, testsche );
        DocGenQueuePurgeSchedule.scheduleIt();
		Test.stopTest();
	}
}