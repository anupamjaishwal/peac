public with sharing class DocuSignPreviewController {
   /* @AuraEnabled
    public static String sendEnvelope(String template, String description, Id recordId) {
        Id mySourceId = recordId; // The ID of the initiating Salesforce object
        
        // Create an empty envelope and add a Salesforce Document and embedded signer  recipient
        // The embedded signer will be the current user with sequence and routing order 1 and role "Signer 1" by default
        dfsle.Envelope dsEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(
            new dfsle.Entity(mySourceId)) // The initiating Salesforce entity--current SF user (salesperson)
            .withDocuments(new List<dfsle.Document> {
                dfsle.Document.fromTemplate(dfsle.UUID.parse(template), description)
                    })
            .withRecipients(new List<dfsle.Recipient> {
                dfsle.Recipient.newEmbeddedSigner() // An embedded signer
                    }
                           );
        
        // Send the envelope.
        dsEnvelope = dfsle.EnvelopeService.sendEnvelope(
            dsEnvelope, // The envelope to send
            true // Send now?
        );
        // Return string value of DocuSign envelope ID
        return String.valueOf(dsEnvelope.docuSignId);
    }
    
    @AuraEnabled
    @future(callout=true)
    public static String getEmbeddedSigningUrl(String envId, String url) {
        Url mySigningUrl = dfsle.SigningService.getEmbeddedSigningUrl(
            dfsle.UUID.parse(envId), // envId value as a UUID
            new URL(url) // url value as a URL
        );
        // Return string value of url to controller
        return mySigningUrl.toExternalForm();
    }*/
    
}