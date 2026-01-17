/**
 * This class contains various utility methods which can be used by the job sequence functionality
 */
global without sharing class JobSequenceUtilities {
    private static final Set<String> DECIMAL_TYPES = new Set<String>{'DOUBLE','PERCENT','CURRENCY'};
    private static Set<String> FIELD_TYPES_TO_CAST = new Set<String> {'DATE','DATETIME','INTEGER','BOOLEAN','DOUBLE','PERCENT','CURRENCY'};

    /**
     * This method perform the DML operation specified to the records passed.
     *
     * This is different from the normal attempt DML because it will not be executed in a try catch, this way the
     * error log can be initiated from the job sequence handler
     *
     * @param records       The records to be adjusted
     * @param operationType The operation to be executed (Insert, Update, Delete and Upsert)
     * @param allOrNone     Whether or not it should allow partial success or fail the entire batch.
     *
     * @return              Any errors from the DML
     */
    global static List<Database.Error> attemptJobSequenceDML(List<SObject> records, String operationType, Boolean allOrNone) {
        return attemptJobSequenceDML(records,operationType,null,allOrNone,false);
    }

    /**
     * This method perform the DML operation specified to the records passed.
     *
     * This is different from the normal attempt DML because it will not be executed in a try catch, this way the
     * error log can be initiated from the job sequence handler
     *
     * @param records       The records to be adjusted
     * @param operationType The operation to be executed (Insert, Update, Delete and Upsert)
     * @param extIdField    The API name of the external Id field to be upserted against
     * @param allOrNone     Whether or not it should allow partial success or fail the entire batch.
     * @param permDelete    Whether or not the recycle bin should be purged after the delete operation takes place
     *
     * @return              Any errors from the DML
     */
    global static List<Database.Error> attemptJobSequenceDML(
            List<SObject> records,
            String operationType,
            String extIdField,
            Boolean allOrNone,
            Boolean permDelete
    ) {
        List<Database.Error> returnList = new List<Database.Error>();
        if (records != null && !records.isEmpty()) {
            switch on operationType.toUpperCase() {
                when 'INSERT' { returnList.addAll(getErrors(Database.insert(records,allOrNone)));}
                when 'UPDATE' { returnList.addAll(getErrors(Database.update(records,allOrNone)));}
                when 'DELETE' { returnList.addAll(handleDynamicDeletes(records,allOrNone,permDelete));}
                when 'UPSERT' { returnList.addAll(handleDynamicUpsert(records,extIdField));}
                when else {
                    throw new JobSequenceException('Could not preform the requested operation: '+operationType);
                }
            }
        }

        return returnList;
    }

    private static List<Database.Error> getErrors(List<Database.SaveResult> results) {
        List<Database.Error> errors = new List<Database.Error>();
        for (Database.SaveResult r : results) errors.addAll(r.getErrors());
        return errors;
    }

    private static List<Database.Error> getErrors(List<Database.DeleteResult> results) {
        List<Database.Error> errors = new List<Database.Error>();
        for (Database.DeleteResult r : results) errors.addAll(r.getErrors());
        return errors;
    }

    private static List<Database.Error> getErrors(List<Database.UpsertResult> results) {
        List<Database.Error> errors = new List<Database.Error>();
        for (Database.UpsertResult r : results) errors.addAll(r.getErrors());
        return errors;
    }


    /**
     * The params must be formatted as follows:
     *
     * fieldApiName:NewValue
     *
     * Multiple values can be done using commas to deliminate
     *
     * @param sobj      The sobject that will be changed
     * @param params    The parameters containing the field API name and the new value
     *
     * @return          The adjusted sobject
     */
    global static SObject changeSobjectValueFromParameters(
            SObject sobj,
            Map<String,Schema.SObjectField> fldMap,
            Map<String,String> params
    ) {
        //Going through each of the fields defined in the parameter map and swapping the value as needed
        for (String fldNm : params.keySet()) {
            if (fldMap.containsKey(fldNm)) {
                Schema.DescribeFieldResult field = fldMap.get(fldNm).getDescribe();
                if (field != null) {
                    Object val = params.get(fldNm);
                    String strVal = String.valueOf(val);
                    val = fldMap.containsKey(strVal) ? sobj.get(strVal) : val;
                    strVal = fldMap.containsKey(strVal) ? String.valueOf(sobj.get(strVal)) : strVal;
                    val = String.isNotBlank(strVal) && strVal.equalsIgnoreCase('null') ? null : val;

                    String fldType = String.valueOf(field.getType());

                    //If the value is not null, need to cast the value of the field appropriately if needed
                    if (val != null && fldType != null && FIELD_TYPES_TO_CAST.contains(fldType)) {
                        if (fldType == 'DATE') val = Date.valueOf(strVal);
                        if (fldType == 'DATETIME') val = Datetime.valueOfGmt(strVal.replace('T',' ').left(strVal.length()-5));
                        if (fldType == 'INTEGER') val = Integer.valueOf(strVal);
                        if (fldType == 'BOOLEAN') val = Boolean.valueOf(strVal);
                        if (DECIMAL_TYPES.contains(fldType)) val = Decimal.valueOf(strVal);
                    }

                    sobj.put(fldNm, val);
                }
                if (field == null) throw new JobSequenceException(fldNm+' is not a valid field!');
            }
        }
        return sobj;
    }

    /**
     * Will execute dynamic sobject deletes
     *
     * @param records       The records to be deleted
     * @param allOrNone     Whether or not it should allow partial success or fail the entire batch.
     * @param permDelete    If this option is selected the records will be removed from the recycle bin
     */
    global static List<Database.Error> handleDynamicDeletes(List<SObject> records, Boolean allOrNone, Boolean permDelete) {
        allOrNone = allOrNone == null ? false : allOrNone;
        permDelete = permDelete == null ? false : permDelete;
        List<Database.Error> returnList = getErrors((Database.delete(records,allOrNone)));
        if (permDelete != null && permDelete) Database.emptyRecycleBin(new List<Id> (new Map<Id,SObject>(records).keySet()));

        return returnList;
    }


    /**
     * Will execute a dynamic sobject upsert using the set of records passed as well as the other options
     *
     * Note, specifying an external Id field will negate the all or none setting
     *
     * @param records       The records to be upsert
     * @param extIdField    The external id to be used to upsert against. If a field is passed, all or none is negated!
     *
     * @return              The list of dynamically upserted records
     */
    global static List<Database.Error> handleDynamicUpsert(List<SObject> records, String extIdField) {
        Schema.DescribeSObjectResult sobjType = records[0].getSObjectType().getDescribe();
        List<Database.Error> returnList = new List<Database.Error>();
        if (sobjType != null) {
            String listType = 'List<' + sobjType.getName() + '>';
            Schema.SObjectField extId = sobjType.fields.getMap().containsKey(extIdField) ?
                    sobjType.fields.getMap().get(extIdField) : null;
            List<SObject> castRecords = (List<SObject>) Type.forName(listType).newInstance();
            castRecords.addAll(records);
            List<Database.UpsertResult> results;
            if (extId == null) returnList.addAll(getErrors(Database.upsert(castRecords)));
            if (extId != null) returnList.addAll(getErrors(Database.upsert(castRecords, extId)));

            records = castRecords;
        }

        return returnList;
    }

    /**
     * Method will log an error in the Job Sequence error object
     *
     * @param js    The job sequence object wrapper
     * @param scope The scope of records being worked with
     * @param e     The exception
     */
    global static void logError(JobSequence js, List<SObject> scope, Exception e) {
        Id jobId = js == null ? null : js.jobId;
        String jobName = js == null ? 'Unknown' : js.currentJob;
        String frequency = js == null ? 'Unknown' : js.jobFrequency;
        Set<Id> ids = scope == null ? null : new Map<Id,SObject>(scope).keySet();
        logError(jobId, jobName, frequency, e, ids);
    }

    global static void logErrors(JobSequence js, List<Database.Error> errors, Set<Id> idScope) {
        List<Job_Sequence_Error__c> jsErrors = new List<Job_Sequence_Error__c>();
        for (Database.Error err : errors) {
            jsErrors.add(
                    new Job_Sequence_Error__c(
                        BatchJobId__c=js.jobId,
                        Exception__c = err.getMessage(),
                        Scope__c = idScope != null ? String.valueOf(idScope) : 'None',
                        JobName__c = js.currentJob,
                        JobFrequency__c = js.jobFrequency
                    )
            );
        }
        insert jsErrors;
    }

    /**
     * Method will log an error in the Job Sequence error object
     *
     * @param jobId         The job Id to log against
     * @param currentJob    The name of the current job
     * @param jobFrequency  The frequency of hte current job
     * @param e             The exception
     * @param idScope       The ids that failed
     */
    global static void logError(Id jobId, String currentJob, String jobFrequency, Exception e, Set<Id> idScope) {
        String exceptionText = String.format(
                Label.Job_Sequence_Exception_Template,
                new List<String> {
                        String.valueOf(e.getCause()),
                        String.valueOf(e.getLineNumber()),
                        String.valueOf(e.getMessage()),
                        String.valueOf(e.getStackTraceString())
                }
        );

        Job_Sequence_Error__c jse = new Job_Sequence_Error__c(
                BatchJobId__c=jobId,
                Exception__c = exceptionText,
                Scope__c = idScope != null ? String.valueOf(idScope) : 'None',
                JobName__c = currentJob,
                JobFrequency__c = jobFrequency
        );
        insert jse;
    }

    global static void scheduleAllRuns() {
        scheduleHourlyRun();
        scheduleDailyRun();
        scheduleWeeklyRun();
        scheduleMonthlyRun();
        scheduleQuarterlyRun();
        scheduleYearlyRun();
    }

    /**
     * This function will schedule the hourly class
     */
    global static void scheduleHourlyRun() {
        setupScheduledRun('JobSequenceHourly',Label.Job_Sequence_Hourly_Cron);
    }

    /**
     * This function will schedule the daily class
     */
    global static void scheduleDailyRun() {
        setupScheduledRun('JobSequenceDaily',Label.Job_Sequence_Daily_Cron);
    }

    /**
     * This function will schedule the weekly class
     */
    global static void scheduleWeeklyRun() {
        setupScheduledRun('JobSequenceWeekly',Label.Job_Sequence_Weekly_Cron);
    }

    /**
     * This function will schedule the monthly class
     */
    global static void scheduleMonthlyRun() {
        setupScheduledRun('JobSequenceMonthly',Label.Job_Sequence_Monthly_Cron);
    }

    global static void scheduleQuarterlyRun() {
        setupScheduledRun('JobSequenceQuarterly',Label.Job_Sequence_Quarterly_Cron);
    }

    /**
     * This function will schedule the yearly class
     */
    global static void scheduleYearlyRun() {
        setupScheduledRun('JobSequenceYearly',Label.Job_Sequence_Yearly_Cron);
    }

    /**
     * Sends an email notification
     *
     * @param toAddresses Optional      - A list of email addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum number of email addresses allowed is 100.
     * @param ccAddresses Optional      - A list of carbon copy (CC) addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum allowed is 25.
     * @param whatId Optional           - If you specify a contact for the targetObjectId field, you can specify an optional whatId as well. This helps to further ensure that merge fields in the template contain the correct data.
     * @param whoId Required            - If using a template, optional otherwise. The ID of the contact, lead, or user to which the email will be sent. The ID you specify sets the context and ensures that merge fields in the template contain the correct data.
     * @param subject Optional          - The email subject line. If you are using an email template, the subject line of the template overrides this value.
     * @param body Optional             - The text version of the email, specified by the sender. You must specify a value for setTemplateId, setHtmlBody, or setPlainTextBody. Or, you can define both setHtmlBody and setPlainTextBody.
     * @param senderDisplayNm Optional  - The name that appears on the From line of the email. This cannot be set if the object associated with a setOrgWideEmailAddressId for a SingleEmailMessage has defined its DisplayName field.
     * @param priority Optional         - The priority of the email
     *
     * @return                          The list of resulting emails after sending
     */
    global static List<Messaging.SendEmailResult> sendEmailNotification(
            List<String> toAddresses,
            List<String> ccAddresses,
            String whatId,
            String whoId,
            String subject,
            String body,
            String senderDisplayNm,
            String priority
    ) {
        Messaging.SingleEmailMessage mail = setupSingleEmail(toAddresses, ccAddresses, whatId, whoId, subject, body, senderDisplayNm, priority);

        return Messaging.sendEmail(new List<Messaging.Email>{
                mail
        });
    }


    /**
     * This function will setup a scheduled run based on the class name passed and the schedule base don the cron string passed
     *
     * @param className     The name of the scheduled class to run
     * @param cronString    The cron schedule as a string
     */
    global static void setupScheduledRun(String className, String cronString) {
        List<AsyncApexJob> aajs =[SELECT ApexClassId FROM AsyncApexJob WHERE ApexClass.Name = :className AND (Status = 'Processing') ORDER BY CreatedDate DESC];
        try {if (aajs.isEmpty()) System.schedule(className + (Test.isRunningTest() ? String.valueOf(System.now()) : ''), cronString, (Schedulable) Type.forName(className).newInstance());} catch (Exception e) {System.debug(LoggingLevel.Error, '*** e: ' + e);}

    }

    /**
     * Creates an email notification
     *
     * @param toAddresses Optional      - A list of email addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum number of email addresses allowed is 100.
     * @param ccAddresses Optional      - A list of carbon copy (CC) addresses or object IDs of the contacts, leads, and users you’re sending the email to. The maximum allowed is 25.
     * @param whatId Optional           - If you specify a contact for the targetObjectId field, you can specify an optional whatId as well. This helps to further ensure that merge fields in the template contain the correct data.
     * @param whoId Required            - If using a template, optional otherwise. The ID of the contact, lead, or user to which the email will be sent. The ID you specify sets the context and ensures that merge fields in the template contain the correct data.
     * @param subject Optional          - The email subject line. If you are using an email template, the subject line of the template overrides this value.
     * @param body Optional             - The text version of the email, specified by the sender. You must specify a value for setTemplateId, setHtmlBody, or setPlainTextBody. Or, you can define both setHtmlBody and setPlainTextBody.
     * @param senderDisplayNm Optional  - The name that appears on the From line of the email. This cannot be set if the object associated with a setOrgWideEmailAddressId for a SingleEmailMessage has defined its DisplayName field.
     * @param priority Optional         - The priority of the email
     *
     * @return                          The constructed email notification
     */
    global static Messaging.SingleEmailMessage setupSingleEmail(
            List<String> toAddresses,
            List<String> ccAddresses,
            String whatId,
            String whoId,
            String subject,
            String body,
            String senderDisplayNm,
            String priority
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(toAddresses);
        mail.setCcAddresses(ccAddresses);
        mail.setSenderDisplayName(senderDisplayNm);
        mail.setSubject(subject);
        mail.setUseSignature(false);
        mail.setPlainTextBody(body);
        mail.setSaveAsActivity (false);
        mail.setEmailPriority(priority);
        mail.whatId = whatId;
        mail.targetObjectId = whoId;

        return mail;
    }

    /**
     * This function will trim the character from the beginning and end of the string
     *
     * @param value             The value to trim
     * @param character2Trim    The character to trim out of the beginning and end
     *
     * @return                  The string with the character trimmed out.
     */
    global static String trimCharacters(String value, String character2Trim) {
        value = value.startsWith(character2Trim) ? value.substringAfter(character2Trim) : value;
        value = value.endsWith(character2Trim) ? value.substringBeforeLast(character2Trim) : value;
        return value;
    }
}