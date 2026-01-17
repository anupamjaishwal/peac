public with sharing class SL_EmailRoutingProcessor implements Queueable, Database.AllowsCallouts {
    private List<Id> emailIds;
    String step;

    public SL_EmailRoutingProcessor(List<Id> emailIds, String step) {
        this.emailIds = emailIds;
        this.step = step;
    }

    public void execute(QueueableContext ctx) {
        switch on step {
            when 'triggered' {
                processEmails();
            }
            when 'committed' {
                deleteClosedCaseEmails();
            }
        }
    }

    public void processEmails(){
        TC_RecursiveTriggerHelper.emailsAlreadyRoutingProcessed.addAll(emailIds);
        Set<String> uniqueAssignment = new Set<String>();
        Map<Id, String> msgIdentifierByEmailId = new Map<Id, String>();
        Map<String, EmailMessage> firstMessages = new Map<String, EmailMessage>();
        for(EmailMessage email :[SELECT Id, MessageIdentifier, Parent.OwnerId, ParentId, Parent.SourceId, Parent.Status
        FROM EmailMessage WHERE Id IN :emailIds AND MessageIdentifier != null]){
            if(email.Id == email.Parent.SourceId){
                firstMessages.put(email.MessageIdentifier, email);
            }
            if(!firstMessages.containsKey(email.MessageIdentifier)){
                uniqueAssignment.add(email.MessageIdentifier + email.Parent.OwnerId);
                msgIdentifierByEmailId.put(email.Id, email.MessageIdentifier);
            }
        }
        if(firstMessages.keySet().size() > 0){
            setParentCaseForNewEmails(firstMessages);
        }
        if(msgIdentifierByEmailId.values().size() > 0){
            Set<String> alreadyClonedMsgIds = new Set<String>();
            for(EmailMessage alreadyCloned :[SELECT Id, Cloned_FromMsg__c
            FROM EmailMessage WHERE Cloned_FromMsg__c IN :msgIdentifierByEmailId.values()]){
                alreadyClonedMsgIds.add(alreadyCloned.Cloned_FromMsg__c);
            }
            for(Id idToProcess : emailIds){
                String msgIdToProcess = msgIdentifierByEmailId.get(idToProcess) ?? '';
                if(alreadyClonedMsgIds.contains(msgIdToProcess)){
                    msgIdentifierByEmailId.remove(idToProcess);
                }
            }
        }
        List<EmailMessage> emails = [
            SELECT Id, ParentId, ToAddress, CcAddress, BccAddress, FromAddress, Subject, TextBody,
                   Incoming, Status, RelatedToId, MessageIdentifier
              FROM EmailMessage
             WHERE Id IN :msgIdentifierByEmailId.keySet()
        ];
        if (emails.isEmpty()) {
            return;
        }

        Map<Id, EmailMessage> originalEmails = new Map<Id, EmailMessage>();
        //    Collect the set of Parent Case Ids
        Set<Id> caseIds = new Set<Id>();
        for (EmailMessage em : emails) {
            originalEmails.put(em.Id, em);
            if (em.ParentId != null) {
                caseIds.add(em.ParentId);
            }
        }
        Map<Id, Case> parentCases = loadParentCases(caseIds);
        
        List<Case> toInsert = new List<Case>();
        // Loop through each emails EmailMessage and decide if we should route for closed vs. open
        for (EmailMessage em : emails) {
            // If there's no parent Case, skip
            Case origCase = parentCases.get(em.ParentId);
            if (origCase == null) {
                continue;
            }

            // If this parent Case is closed (or Status='Closed') → use the existing “closed” logic
            if (origCase.IsClosed || origCase.Status == 'Closed') {
                if (em.TextBody != null && em.TextBody.trim() == '[EXTERNAL]') {
                    em.TextBody = '';
                }
                List<Case> newCasesFromClosed = createCasesFromEmailAddresses(em, origCase, true);
                if (!newCasesFromClosed.isEmpty()) {
                    toInsert.addAll(newCasesFromClosed);
                }
            }
            // If the parent Case is still open → apply “new open‐case” logic
            else {
                List<Case> newCasesFromOpen = createCasesFromEmailAddresses(em, origCase, false);
                if (!newCasesFromOpen.isEmpty()) {
                    toInsert.addAll(newCasesFromOpen);
                }
            }
        }   
        if (toInsert.isEmpty()) {
            return;
        }

        // Filter out any Cases whose (MessageIdentifier + OwnerId) already exists
        List<Case> finalToInsert = new List<Case>();
        Set<String> reOpenedAssignment = new Set<String>();
        for (Case c : toInsert) {
            Case origCase = parentCases.get(c.ParentId);// SL-2793 Misael Romero so closed cases can create new cases with the same Queue
            Boolean isCaseClosed = origCase.IsClosed || origCase.Status == 'Closed';
            String assignmentKey = msgIdentifierByEmailId.get(c.SourceId) + c.OwnerId;
            if ((isCaseClosed && !reOpenedAssignment.contains(assignmentKey)) 
                || (!isCaseClosed && !uniqueAssignment.contains(assignmentKey))){
                finalToInsert.add(c);
                uniqueAssignment.add(assignmentKey);
                if (isCaseClosed) {
                    reOpenedAssignment.add(assignmentKey);
                }
            }
        }
        if (!finalToInsert.isEmpty()) {
            Database.DMLOptions dmlo = new Database.DMLOptions();
            dmlo.EmailHeader.triggerAutoResponseEmail = true;
            dmlo.EmailHeader.triggerOtherEmail = true;
            Database.insert(finalToInsert, dmlo);
        }

        // For each inserted Case, clone the original EmailMessage into that Case
        Map<Id, List<Case>> casesByEmail = new Map<Id, List<Case>>();
        Map<Id, Case> newCasesById = new Map<Id, Case>();
        for (Case c : finalToInsert) {
            if (!casesByEmail.containsKey(c.SourceId)) {
                casesByEmail.put(c.SourceId, new List<Case>());
            }
            casesByEmail.get(c.SourceId).add(c);
            newCasesById.put(c.Id, c);
        }

        Map<Id, List<EmailMessage>> messagesToInsert = new Map<Id, List<EmailMessage>>();
        List<EmailMessage> allMessagesToInsert = new List<EmailMessage>();
        List<Id> afterClosureEmailIds = new List<Id>();
        for (Id originalEmailId : casesByEmail.keySet()) {
            EmailMessage orig = originalEmails.get(originalEmailId);
            Case origCase = parentCases.get(orig.ParentId);
            for (Case newCase : casesByEmail.get(originalEmailId)) {
                if((origCase.IsClosed || origCase.Status == 'Closed')){
                    afterClosureEmailIds.add(orig.Id);
                }
                EmailMessage cloneMsg = new EmailMessage(
                    ParentId    = newCase.Id,
                    FromAddress = orig.FromAddress,
                    ToAddress   = orig.ToAddress,
                    CcAddress   = orig.CcAddress,
                    BccAddress  = orig.BccAddress,
                    Subject     = orig.Subject,
                    TextBody    = orig.TextBody,
                    Status      = orig.Status,
                    RelatedToId = orig.RelatedToId,
                    Incoming = orig.Incoming,
                    Cloned_From__c = originalEmailId,
                    Cloned_FromMsg__c = orig.MessageIdentifier.left(255)
                );
                if(messagesToInsert.get(originalEmailId) == null){
                    messagesToInsert.put(originalEmailId, new List<EmailMessage>());
                }
                messagesToInsert.get(originalEmailId).add(cloneMsg);
                allMessagesToInsert.add(cloneMsg);
            }
        }
        if(!allMessagesToInsert.isEmpty()){
            insert allMessagesToInsert;
        }
        Map<Id, List<Attachment>> attachmentsByMailId = new Map<Id, List<Attachment>>();
        for(Attachment att : [SELECT Id, Name, Body, ContentType, ParentId 
        FROM Attachment WHERE ParentId IN :originalEmails.keySet()]){
            if(attachmentsByMailId.get(att.ParentId) == null){
                attachmentsByMailId.put(att.ParentId, new List<Attachment>());
            }
            attachmentsByMailId.get(att.ParentId).add(att);
        }
        List<Attachment> attachmentsToInsert = new List<Attachment>();
        for(Id origEmailId :messagesToInsert.keySet()){
            List<Attachment> origEmailAttachments = attachmentsByMailId.get(origEmailId);
            if(origEmailAttachments != null && origEmailAttachments.size() > 0){
                for(EmailMessage newMessage :messagesToInsert.get(origEmailId)){
                    for(Attachment origAttachment : origEmailAttachments){
                        Attachment clonedAttachment = origAttachment.clone(false, true, true, true);
                        clonedAttachment.ParentId = newMessage.Id;
                        attachmentsToInsert.add(clonedAttachment);
                    }
                }
            }
        }
        if(attachmentsToInsert.size() > 0){
            insert attachmentsToInsert;
        }
        for(EmailMessage insertedMsg :allMessagesToInsert){// update cases sourceId to new emailMessage id
            Case insertedCase = newCasesById.get(insertedMsg.ParentId);
            insertedCase.SourceId = insertedMsg.Id;
        }
        if(newCasesById.values().size() > 0){
            update newCasesById.values();
        }
        if(!afterClosureEmailIds.isEmpty()){
            if(!Test.isRunningTest()){
            System.enqueueJob(new SL_EmailRoutingProcessor(afterClosureEmailIds, 'committed'));
            }else{
                emailIds = afterClosureEmailIds;
                deleteClosedCaseEmails();
            }
            
        }
    }

    public void deleteClosedCaseEmails(){
        Set<String> msgIdentifiers = new Set<String>();
        for(EmailMessage anEmail :[SELECT Id, Parent.SourceId, MessageIdentifier, Incoming
            FROM EmailMessage WHERE Incoming = true AND Id IN :emailIds]){
            if(anEmail.Id != anEmail.Parent.SourceId && String.isNotBlank(anEmail.MessageIdentifier)){
                msgIdentifiers.add(anEmail.MessageIdentifier);
            }
        }
        List<EmailMessage> messagesToDelete = [SELECT Id, Parent.SourceId, MessageIdentifier, Incoming
            FROM EmailMessage WHERE Incoming = true AND (Id IN :emailIds OR MessageIdentifier IN :msgIdentifiers)];
        if(!messagesToDelete.isEmpty()){// delete original emailMessage on Closed parent Case
            delete messagesToDelete;
        }
    }

    private List<Object> getRoutingViaTooling(Set<String> cleanedEmails) {
        if (cleanedEmails.isEmpty()) {
            return new List<Object>();
        }
        List<String> quoted = new List<String>();
        for (String e : cleanedEmails) {
            quoted.add('\'' + String.escapeSingleQuotes(e) + '\'');
        }
        String toolingQuery =
            'SELECT EmailAddress, CaseOwner, CaseOrigin ' +
            'FROM EmailToCaseRoutingAddress ' +
            'WHERE EmailAddress IN (' + String.join(quoted, ',') + ')';

        String endpoint = 'callout:ToolingAPI/services/data/v58.0/tooling/query/?q=' +
                          EncodingUtil.urlEncode(toolingQuery, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            return new List<Object>();
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (List<Object>) payload.get('records');
    }


    public List<Case> createCasesFromEmailAddresses(EmailMessage email, Case origCase, Boolean isClosedCase){
        List<Case> newCases = new List<Case>();
        Set<String> allEmails = new Set<String>();
        if(email.ToAddress  != null){
            allEmails.addAll(email.ToAddress.split('[,;]'));
        }
        if(email.CcAddress != null) {
            allEmails.addAll(email.CcAddress.split('[,;]'));
        }
        // if (email.BccAddress != null) {
        //     allEmails.addAll(email.BccAddress.split('[,;]'));
        // }

        // Clean/dedupe (trim + toLowerCase)
        Set<String> cleaned = new Set<String>();
        for (String raw : allEmails) {
            if (String.isNotBlank(raw)) {
                cleaned.add(raw.trim().toLowerCase());
            }
        }
        cleaned = addLegacyDomains(cleaned);
        if (!cleaned.isEmpty()) {
            // Call the same routing table via Tooling API to see which queue owns each of these addresses
            List<Object> rawRoutingRecs = getRoutingViaTooling(cleaned);
            Map<String, RoutingWrapper> routingByEmailAddress = new Map<String, RoutingWrapper>();
            Set<String> ownerDevNames = new Set<String>();
            for (Object o : rawRoutingRecs) {
                Map<String, Object> rec = (Map<String, Object>) o;
                String emailAddr = ((String) rec.get('EmailAddress')).toLowerCase().trim();
                RoutingWrapper etcRouting = new RoutingWrapper((String) rec.get('CaseOwner'),
                    (String) rec.get('CaseOrigin'));
                if (!routingByEmailAddress.containsKey(emailAddr)) {
                    routingByEmailAddress.put(emailAddr, etcRouting);
                    ownerDevNames.add(etcRouting.caseOwner);
                }
            }
            if (!routingByEmailAddress.isEmpty()) {
                Map<String, Id> devNameToQueueId = new Map<String, Id>();
                for (Group q : [
                    SELECT Id, DeveloperName
                        FROM Group
                        WHERE Type = 'Queue'
                        AND DeveloperName IN :ownerDevNames
                ]) {
                    devNameToQueueId.put(q.DeveloperName, q.Id);
                }

                //Build one Case per queue, but only if that queue ≠ the existing open Case's owner
                //     Also avoid duplicates if two different emailAddrs map to the same queue.
                Set<Id> queuesUsed = new Set<Id>();
                for (String addr : routingByEmailAddress.keySet()) {
                    RoutingWrapper etcRouting = routingByEmailAddress.get(addr);
                    String devName = etcRouting.caseOwner;
                    Id queueId = devNameToQueueId.get(devName);
                    if (queueId != null && !queuesUsed.contains(queueId) && 
                    ((isClosedCase && queueId == origCase.OwnerId) || queueId != origCase.OwnerId)){
                        queuesUsed.add(queueId);
                        Case c = origCase.clone(false, false, false, false);
                        c.ParentId            = email.ParentId; // keep same parent reference
                        c.Subject             = (email.Subject != null) ? email.Subject.left(255) : '';
                        c.Description         = (email.TextBody != null) ? email.TextBody.left(32000) : '';
                        c.Status              = 'New';
                        c.SourceId            = email.Id;
                        c.Closed_Reason__c    = '';
                        c.Resolution_Notes__c = '';
                        c.OwnerId             = queueId;
                        c.Origin              = etcRouting.CaseOrigin;
                        c.SuppliedEmail       = email.FromAddress;
                        newCases.add(c);
                    }
                }
            }
        }
        return newCases;
    }

    Set<String> addLegacyDomains(Set<String> cleaned){
        List<String> legacyDomains = Label.SL_LegacyDomains.split(',');
        Set<String> legacyAdded = new Set<String>();
        legacyAdded.addAll(cleaned);
        for(String aDomain :legacyDomains){
            for(String original : cleaned){
                legacyAdded.add(original.substringBeforeLast('@') + '@' + aDomain);
            }
        }
        return legacyAdded;
    }

    Map<Id, Case> loadParentCases(Set<Id> caseIds){
        return new Map<Id, Case>([
            SELECT Id, OwnerId, Status, IsClosed, SourceId, AccountId, Contract_custom__c, Reason, secondary_Reasons__c, Comments,
                ContactId, Priority, SuppliedCompany, SuppliedEmail, SuppliedName, SuppliedPhone, Web_Contracts__c
                FROM Case
                WHERE Id IN :caseIds
        ]);
    }
    public void setParentCaseForNewEmails(Map<String, EmailMessage> firstMessages){
        Map<String, Id> parentCaseByMsgId = new Map<String, Id>();
        List<EmailMessage> allFirstMessages = new List<EmailMessage>();
        for(EmailMessage sameMessageRecord :[SELECT Id, MessageIdentifier, ParentId, Parent.Status, Parent.OwnerId, Parent.ParentId, Incoming
        FROM EmailMessage WHERE MessageIdentifier IN :firstMessages.keySet()]){
            if(!sameMessageRecord.Incoming){
                parentCaseByMsgId.put(sameMessageRecord.MessageIdentifier, sameMessageRecord.ParentId);
            }else{
                if(sameMessageRecord.Parent.ParentId == null){
                    allFirstMessages.add(sameMessageRecord);
                }
            }
        }
        Map<Id, Case> parentCases = loadParentCases(new Set<Id>(parentCaseByMsgId.values()));
        List<Case> casesToUpdate = new List<Case>();
        for(EmailMessage firstMessage :allFirstMessages){
            Id parentCaseId = parentCaseByMsgId.get(firstMessage.MessageIdentifier);
            if(parentCaseId != null){
                Case parentCase = parentCases.get(parentCaseId);
                // if(!parentCase.IsClosed && parentCase.Status != 'Closed'){
                    Case toAdopt = parentCase.clone(false, false, false);
                    toAdopt.Id = firstMessage.ParentId;
                    toAdopt.ParentId = parentCaseId;
                    toAdopt.Status = firstMessage.Parent.Status;
                    toAdopt.OwnerId = firstMessage.Parent.OwnerId;
                    casesToUpdate.add(toAdopt);
                // }
            }
        }
        if(casesToUpdate.size() > 0){
            update casesToUpdate;
        }
    }

    public class RoutingWrapper{
        public String caseOwner;
        public String CaseOrigin;
        public RoutingWrapper(String caseOwner, String CaseOrigin){
            this.caseOwner = caseOwner;
            this.CaseOrigin = CaseOrigin;
        }
    }
}