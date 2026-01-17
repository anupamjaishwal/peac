global class BatchToDeleteLeadsScheduler implements Schedulable {
    global void execute(SchedulableContext sc)
     {
      if(!test.isRunningTest())  if(!test.isRunningTest()) database.executebatch(new BatchToDeleteLeads(false));
     }
}