/** @author : Northteq Consulting, Inc.
 * @date : 11/10/20
 * @description: Do Not Sync to Marketo
 *
 */
global class TC_DNSMarketoSchedulable implements Schedulable {


    global void execute(SchedulableContext ctx) {

        TC_DNSMarketoBatchable batchable = new TC_DNSMarketoBatchable();
        Database.executeBatch(batchable, 1);
    }
}