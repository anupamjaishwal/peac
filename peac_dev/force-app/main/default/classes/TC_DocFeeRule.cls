public interface TC_DocFeeRule {
	
    Map <Id, Decimal> runDocFeeRule (Set <Id> oppIds);
}