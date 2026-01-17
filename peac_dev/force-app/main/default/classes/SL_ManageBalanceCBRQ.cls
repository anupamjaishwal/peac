public class SL_ManageBalanceCBRQ implements Queueable {
    Decimal previousMaxBalance, currentMaxBalance, previousMaxBalance_XBS_ADR, currentMaxBalance_XBS_ADR;
    Boolean allXBS;
    public SL_ManageBalanceCBRQ(Decimal previousMaxBalance, Decimal currentMaxBalance, Decimal previousMaxBalance_XBS_ADR, Decimal currentMaxBalance_XBS_ADR, Boolean allXBS) {
        this.previousMaxBalance = previousMaxBalance;
        this.currentMaxBalance = currentMaxBalance;
        this.previousMaxBalance_XBS_ADR = previousMaxBalance_XBS_ADR;
        this.currentMaxBalance_XBS_ADR = currentMaxBalance_XBS_ADR;
        this.allXBS = allXBS;
    }

    public void execute(QueueableContext context) {
        Database.executeBatch(new SL_ManageBalanceCBRBatch(previousMaxBalance, currentMaxBalance, previousMaxBalance_XBS_ADR, currentMaxBalance_XBS_ADR, allXBS));
    }
}