public class SL_RescoreOverToleranceQ implements Queueable{
    List<Id> idsToRescore = new List<Id>();

    public SL_RescoreOverToleranceQ(List<Id> idsToRescore){
        this.idsToRescore = idsToRescore;
    }

    public void execute(QueueableContext context) {
        if(idsToRescore.size() > 0){
            TC_GdsScoreCtrl.callGdsPb(idsToRescore);
        }
    }
}