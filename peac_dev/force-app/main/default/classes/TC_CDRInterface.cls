/**
 * Created by andrewmayer on 1/8/20.
 */

public interface TC_CDRInterface {
    void runRule (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Set <id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords);

}