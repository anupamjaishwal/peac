public without sharing class SL_OppContactsGuarantors { // need to ask if this is going to be used for internal uses, without sharing is included because the New application process needs full access
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'getAllContacts'{
                    result = getAllContacts(parameters[0], parameters[1]);
                }
                when 'saveOppContact'{
                    result = saveOppContact(parameters[0], parameters[1], parameters[2], parameters[3], parameters[4], parameters[5]);
                }
                when 'deleteOppContact'{
                    result = deleteOppContact(parameters[0], parameters[1], parameters[2]);
                }
            }
        } catch (Exception e) {
            system.debug('e: ' + e);
            system.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    public static String getAllContacts(String accountId, String opportunityId) {
        String result = '{}';
        Set<Id> oppContactIds = new Set<Id>();
        for(OpportunityContactRole ocr :[SELECT ContactId FROM OpportunityContactRole 
            WHERE Role != 'Dealer Primary Contact' AND OpportunityId = :opportunityId]){
            oppContactIds.add(ocr.ContactId);
        }
        Set<Id> guarantorIds = new Set<Id>();
        for(Guarantor__c ocr :[SELECT Contact__c FROM Guarantor__c WHERE Opportunity__c = :opportunityId]){
            oppContactIds.add(ocr.Contact__c);
            guarantorIds.add(ocr.Contact__c);
        }
        List<OppContactWrapper> allContacts = new List<OppContactWrapper>();
        for(Contact theContact : [SELECT Id, FirstName, LastName, Email, Phone, OtherAddress, OtherStreet, OtherCity, OtherStateCode, 
            OtherState, OtherPostalCode, OtherCountryCode, OtherCountry, MailingAddress, MailingCity, MailingCountryCode, 
            MailingCountry, MailingStreet, MailingStateCode, MailingState, MailingPostalCode, OK_to_Pull_Credit__c, AccountId 
            FROM Contact WHERE /*AccountId = :accountId OR*/ Id IN :oppContactIds]){
            OppContactWrapper theContactWrap = new OppContactWrapper();
            theContactWrap.contactId = theContact.Id;
            theContactWrap.FirstName = theContact.FirstName;
            theContactWrap.LastName = theContact.LastName;
            theContactWrap.Email = theContact.Email;
            theContactWrap.Phone = theContact.Phone;
            theContactWrap.OtherAddress = theContact.OtherAddress;
            theContactWrap.OtherStreet = theContact.OtherStreet;
            theContactWrap.OtherCity = theContact.OtherCity;
            theContactWrap.OtherStateCode = theContact.OtherStateCode;
            theContactWrap.OtherState = theContact.OtherState;
            theContactWrap.OtherPostalCode = theContact.OtherPostalCode;
            theContactWrap.OtherCountryCode = theContact.OtherCountryCode;
            theContactWrap.OtherCountry = theContact.OtherCountry;
            theContactWrap.MailingAddress = theContact.MailingAddress;
            theContactWrap.MailingCity = theContact.MailingCity;
            theContactWrap.MailingCountryCode = theContact.MailingCountryCode;
            theContactWrap.MailingCountry = theContact.MailingCountry;
            theContactWrap.MailingStreet = theContact.MailingStreet;
            theContactWrap.MailingStateCode = theContact.MailingStateCode;
            theContactWrap.MailingState = theContact.MailingState;
            theContactWrap.MailingPostalCode = theContact.MailingPostalCode;
            theContactWrap.isOkToPullCredit = theContact.OK_to_Pull_Credit__c;
            theContactWrap.AccountId = theContact.AccountId;
            theContactWrap.isGuarantor = guarantorIds.contains(theContact.Id);
            allContacts.add(theContactWrap);
        }
        
        AllContactsWrapper resultWrap = new AllContactsWrapper(oppContactIds, allContacts);
        result = JSON.serialize(resultWrap, true);
        return result;
    }

    public static String saveOppContact(String contactObj, String opportunityId, String isPG, String isAddressDif, String isMailingDif, String usedAccPhone) {
        String saveContactResult = 'success';
        // System.debug('contactObj: ' + contactObj);
        Contact theContact = (Contact)JSON.deserialize(contactObj, Contact.class);
        // system.debug('theContact parsed: ' + theContact);
        Boolean isGuarantor = Boolean.valueOf(isPG);
        Boolean isAddressDifferent = Boolean.valueOf(isAddressDif);
        Boolean isMailingDifferent = Boolean.valueOf(isMailingDif);
        Boolean usedAccountPhone = Boolean.valueOf(usedAccPhone);
        Id originalId = theContact.Id;
        List<Contact> resultList = SL_DealerPortalContactDupeCheck.EmailDuplicateCheck(new List<Contact>{theContact});
        theContact = resultList[0];
        Boolean isContactNewData = false;
        if(Test.isRunningTest() && SL_SCTestData.testDupeId != null){
            theContact.Id = SL_SCTestData.testDupeId;
        }
        if(theContact.Id != null){
            if(originalId != theContact.Id){
                Contact existingContact = [SELECT Id, SSNMain__c, SSN__c, Title, Phone, OtherStreet, OtherCity, OtherStateCode, OtherPostalCode,
                    MailingStreet, MailingCity, MailingStateCode, MailingPostalCode, AccountId
                    FROM Contact WHERE Id = :theContact.Id];
                if(!isGuarantor){
                    theContact.SSNMain__c = existingContact.SSNMain__c;
                    theContact.SSN__c = existingContact.SSN__c;
                }
                if(usedAccountPhone && String.isNotBlank(existingContact.Phone)){
                    theContact.Phone = null;
                }
                theContact.AccountId = existingContact.AccountId;
                SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'Title', false);
                SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'Phone', false);
                theContact.Title = existingContact.Title;
                theContact.Phone = existingContact.Phone;
                if(!isAddressDifferent){
                    theContact.OtherStreet = null;
                    theContact.OtherCity = null;
                    theContact.OtherStateCode = null;
                    theContact.OtherPostalCode = null;
                }
                if(!isMailingDifferent){
                    theContact.MailingStreet = null;
                    theContact.MailingCity = null;
                    theContact.MailingStateCode = null;
                    theContact.MailingPostalCode = null;
                }
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'OtherStreet', false);
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'OtherCity', isContactNewData);
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'OtherStateCode', isContactNewData);
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'OtherPostalCode', isContactNewData);
                theContact.OtherStreet = existingContact.OtherStreet;
                theContact.OtherCity = existingContact.OtherCity;
                theContact.OtherStateCode = existingContact.OtherStateCode;
                theContact.OtherPostalCode = existingContact.OtherPostalCode;
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'MailingStreet', false);
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'MailingCity', isContactNewData);
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'MailingStateCode', isContactNewData);
                isContactNewData = SL_DealerPortalCAGuarantor.checkUpdatedField(existingContact, theContact, 'MailingPostalCode', isContactNewData);
                theContact.MailingStreet = existingContact.MailingStreet;
                theContact.MailingCity = existingContact.MailingCity;
                theContact.MailingStateCode = existingContact.MailingStateCode;
                theContact.MailingPostalCode = existingContact.MailingPostalCode;
            }
            if(originalId != null && originalId != theContact.Id){
                deleteOppContact(originalId, opportunityId, isPG);
            }
        }
        Map<String, Schema.SObjectField> fieldsMap =Schema.getGlobalDescribe().get('Contact').getDescribe().Fields.getMap();
        if(String.isNotBlank(theContact.OtherCountryCode)){
            theContact.OtherCountry = getPicklistLabel(fieldsMap, 'OtherCountryCode', '', theContact.OtherCountryCode);
        }
        if(String.isNotBlank(theContact.MailingCountryCode)){
            theContact.MailingCountry = getPicklistLabel(fieldsMap, 'MailingCountryCode', '', theContact.MailingCountryCode);
        }
        if(String.isNotBlank(theContact.OtherStateCode)){
            theContact.OtherState = getPicklistLabel(fieldsMap, 'OtherStateCode', theContact.OtherCountryCode, theContact.OtherStateCode);
        }
        if(String.isNotBlank(theContact.MailingStateCode)){
            theContact.MailingState = getPicklistLabel(fieldsMap, 'MailingStateCode', theContact.MailingCountryCode, theContact.MailingStateCode);
        }
        if(theContact.Id != null){
            update theContact;
        }
        List<Contact> upsertList = SL_DealerPortalCAContact.upsertContactForApp(new List<Contact>{theContact});
        theContact = upsertList[0];
        
        List<OpportunityContactRole> oppContactRoles = new List<OpportunityContactRole>();
        Id currentUserContactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        if(currentUserContactId != null){
            OpportunityContactRole dealerOppContactRole = new OpportunityContactRole();
            List<OpportunityContactRole> existingOcr = [SELECT Id, ContactId, OpportunityId, Role, IsPrimary FROM OpportunityContactRole 
                WHERE ContactId = :currentUserContactId AND OpportunityId = :opportunityId];
            if(existingOcr.size() > 0){
                dealerOppContactRole.Id = existingOcr[0].Id;
            }else{
                dealerOppContactRole.ContactId = currentUserContactId;
                dealerOppContactRole.OpportunityId = opportunityId;
                dealerOppContactRole.Role = 'Dealer Primary Contact';
                oppContactRoles.add(dealerOppContactRole);
            }
        }
        if(isGuarantor){
            SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters parameters = new SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters();
            parameters.theOpportunityId = opportunityId;
            parameters.guarantorContact = theContact;
            List<SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters> packagedParams = new List<SL_DealerPortalCAGuarantor.CreateGuarantorContactParameters>();
            packagedParams.add(parameters);
            /* List<Guarantor__c> guarantorResult =*/ SL_DealerPortalCAGuarantor.createGuarantorContact(packagedParams);
        }else{
            OpportunityContactRole theOppContactRole = new OpportunityContactRole();
            List<OpportunityContactRole> existingOcr = [SELECT Id, ContactId, OpportunityId, Role, IsPrimary FROM OpportunityContactRole 
                WHERE ContactId = :theContact.Id AND OpportunityId = :opportunityId];
            if(existingOcr.size() > 0){
                theOppContactRole.Id = existingOcr[0].Id;
            }else{
                theOppContactRole.ContactId = theContact.Id;
                theOppContactRole.OpportunityId = opportunityId;
                theOppContactRole.Role = 'Primary Contact';
                theOppContactRole.IsPrimary = true;
                oppContactRoles.add(theOppContactRole);
            }
            if(originalId != null){
                removeGuarantor(originalId, opportunityId);
            }
        }
        
        if(oppContactRoles.size() > 0){
            insert oppContactRoles;
        }
        return saveContactResult;
    }

    public static String deleteOppContact(String contactId, String opportunityId, String isPG) {
        String deleteContactResult = 'success';
        Boolean isGuarantor = Boolean.valueOf(isPG);
        List<OpportunityContactRole> oppContactToDelete = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opportunityId AND ContactId =:contactId];
        if(oppContactToDelete.size() > 0){
            delete oppContactToDelete;
        }
        if(isGuarantor){
            removeGuarantor(contactId, opportunityId);
        }
        return deleteContactResult;
    }

    public static String getPicklistLabel(Map<String, Schema.SObjectField> fieldsMap, String picklistName, String controllingValue, String value){
        String picklistLabel = null;
        Schema.DescribeFieldResult dependToken = fieldsMap.get(picklistName).getDescribe();
        Map<String, List<Schema.PicklistEntry>> dependencyMap = getDependentPicklistEntries(fieldsMap.get(picklistName));
        list<Schema.PicklistEntry> entries = null;
        if(dependencyMap.keySet().size() == 0){
            entries = dependToken.getPickListValues();
        }else{
            entries = dependencyMap.get(controllingValue);
        }
        if(entries != null){
            for(Schema.PicklistEntry theEntry : entries){
                if(theEntry.getValue() == value){
                    picklistLabel = theEntry.getLabel();
                }
            }
        }
        return picklistLabel;
    }

    public static Map<String, List<Schema.PicklistEntry>> getDependentPicklistEntries(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<Schema.PicklistEntry>>();
        }
     
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
     
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<Schema.PicklistEntry>> dependentPicklistEntries = new Map<String,List<Schema.PicklistEntry>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                            );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistEntries.containsKey((String) controlValue)) {
                        dependentPicklistEntries.put((String) controlValue, new List<Schema.PicklistEntry>());
                    }
                    dependentPicklistEntries.get((String) controlValue).add(entry);
                }
            }
        }
        return dependentPicklistEntries;
    }

    static void removeGuarantor(String contactId, String opportunityId){
        List<Guarantor__c> pgToDelete = [SELECT Id FROM Guarantor__c WHERE Opportunity__c = :opportunityId AND Contact__c = :contactId];
        if(pgToDelete.size() > 0){
            delete pgToDelete;
        }
    }

    public class AllContactsWrapper {
        public Set<Id> oppContactIds { get; set; }
        public List<OppContactWrapper> allContacts { get; set; }
        
        public AllContactsWrapper(Set<Id> oppContactIds, List<OppContactWrapper> allContacts) {
            this.oppContactIds = oppContactIds;
            this.allContacts = allContacts;
        }
    }

    public class OppContactWrapper {
        public Id contactId { get; set; }
        public String FirstName { get; set; }
        public String LastName { get; set; }
        public String Email { get; set; }
		public String Phone { get; set; }
		public System.Address OtherAddress { get; set; }
        public String formattedAddress { get{
            return (String.isNotBlank(OtherAddress.street)? OtherAddress.street: '') 
                            + (String.isNotBlank(OtherAddress.city)? ' ' + OtherAddress.city: '')
                            + (String.isNotBlank(OtherAddress.stateCode)? ' ' + OtherAddress.stateCode: '')
                            + (String.isNotBlank(OtherAddress.postalCode)? ' ' + OtherAddress.postalCode: '')
                            + (String.isNotBlank(OtherAddress.countryCode)? ', ' + OtherAddress.countryCode: '');
        } set; }
        public String OtherStreet { get; set; } 
        public String OtherCity { get; set; } 
        public String OtherStateCode { get; set; } 
        public String OtherState { get; set; } 
        public String OtherPostalCode { get; set; } 
        public String OtherCountryCode { get; set; } 
        public String OtherCountry { get; set; } 
        public System.Address MailingAddress { get; set; }
        public String MailingCity { get; set; } 
        public String MailingCountryCode { get; set; } 
        public String MailingCountry { get; set; } 
        public String MailingStreet { get; set; } 
        public String MailingStateCode { get; set; } 
        public String MailingState { get; set; } 
        public String MailingPostalCode { get; set; }
        public Boolean isOkToPullCredit { get; set; }
		public Id AccountId { get; set; }
        public Boolean isGuarantor { get; set; }
    }
}