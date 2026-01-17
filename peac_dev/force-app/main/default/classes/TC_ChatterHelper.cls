/** @author : Tamarack Consulting, Inc.
 * @date : 1/8/20
 * @description: 
 *
 */
public with sharing class TC_ChatterHelper {

    /**
     * Helper method that constructs a Chatter post
     * @param chatterMap The map containing a list of strings representing Chatter posts
     * @param recordId The record ID to add the Chatter post to, such as an opportunity ID
     * @param message The message to add to the list of strings
     */
    public static void addMessage(Map<Id, List<String>> chatterMap, Id recordId, String message) {
        /* If the opportunity already exists in the map,
        * then add the message to its list of strings,
        * else create a new list of strings for that record ID and add it to the map */
        if (chatterMap.get(recordId) <> null) {
            chatterMap.get(recordId).add(message);
        } else {
            chatterMap.put(recordId, new List<String>{message});
        }
    }

    /**
     * Constructs Chatter posts and uploads them to Salesforce
     * @param chatterMapping The inputted map of record IDs and lists of strings containing messages
     */
    public static void sendToChatter(Map<Id, List<String>> chatterMapping) {

        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

        for (Id recordId : chatterMapping.keySet()) {
            List<String> messages = chatterMapping.get(recordId);
            String message = String.join(messages, '\n');

            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.subjectId = recordId;
            ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
            body.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = message;
            body.messageSegments.add(textSegment);
            input.body = body;
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
            batchInputs.add(batchInput);
        }

        //ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
    }
}