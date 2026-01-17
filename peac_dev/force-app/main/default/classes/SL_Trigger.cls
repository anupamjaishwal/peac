/**
* @date 11/9/2014
* @description This factory creates the correct handler and dispatches the trigger event(s) to the appropriate 
*				event handler(s). The handlers are automatically created using the Type API, hence handler 
*				registration is not required for each handler.
*/
public with sharing class SL_Trigger {

/**===BEGIN trigger factory===**/
    /**
    * @date 3/2/2018
    * @description Creates a trigger handler from either the object type or the class passed from the trigger.
    */
    public static void createHandler(Schema.sObjectType soType) {
        SL_Trigger_ITriggerHandler handler = getTriggerHandler(soType);
        dispatchHandler(soType, handler);
    }

    /** 
	* @date 11/9/2014
	* @description Creates the appropriate handler and dispatches the trigger event to the handler's event handler method.
	* @param Schema.sObjectType Object type to process (SObject.sObjectType)
	*/
    public static void dispatchHandler(Schema.sObjectType soType, SL_Trigger_ITriggerHandler handler){
        String soTypeName = soType.getDescribe().getName();
        Set<String> deactivatedObjects = new Set<String>();
        //TODO: add unit tests for killList and killSwitch functionality
        if (KillList != null && KillList != '') {
            deactivatedObjects = new Set<String>(KillList.split('\n'));
        }
        Set<String> deactivatedObjectsNoWhitespace = new Set<String>();
        for (String s : deactivatedObjects) {
            deactivatedObjectsNoWhitespace.add(s.deleteWhitespace());
        }

        if (!(KillSwitchEnabled || (KillList != null ? deactivatedObjectsNoWhitespace.contains(soTypeName) : false))) {
            try {
                if (handler == null) throw new FrameworkException('No Trigger handler registered for Object Type: ' + soType);
                execute(handler, soTypeName);
                // Final Pop from Diagnostic Log
                Pop();
            } catch (Exception ex) {
                DebugException(ex);
                PopAll();
                //GG: should always throw exception.
                throw ex;
            }
        }
    }

    /** 
    * @date 11/9/2014
    * @description Dispatches to the handler's event handlers.
    * @param ITriggerhandler A Trigger handler that dispatches to the appropriate handlers
    */
    @TestVisible
    private static Parameters testContext; //used to set trigger context variables in test methods.

    private static void execute(SL_Trigger_ITriggerHandler handler, String soTypeName) {
        Parameters tp;
        if(Trigger.isExecuting){
           tp = new Parameters(
                   Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.isBefore, Trigger.isAfter,
                   Trigger.isDelete, Trigger.isInsert, Trigger.isUpdate, Trigger.isUnDelete, Trigger.isExecuting);
        }
        //GG: should only be called from trigger framework tests.
        else {
            system.assert(testContext!=null,'trigger parameters must be specified in test framework tests.');
            tp = testContext;
        }

        String context =  tp.tEvent.name();
        Push(context + ' Trigger for ' + soTypeName + ' Object');

        // Handle before trigger events
        if (tp.tEvent.name().startsWith('before')) {
            Push(soTypeName + 'Triggerhandler.bulkBefore');
            handler.bulkBefore();
            Pop();
        }
        // Handle after trigger events
        else {
            Push(soTypeName + 'Triggerhandler.bulkAfter');
            handler.bulkAfter();
            Pop();
        }

        handler.execute(tp, context);
    }

    /** 
    * @date 11/9/2014
    * @description Gets the appropriate handler based on the SObject. It constructs the instance of the handler
    *               dynamically using the Type API. The name of the handler has to follow this format:
    *               <ObjectName>Triggerhandler. For e.g. for the Account object, the handler has to be named
    *               as AccountTriggerhandler. For the custom object Custom__c, the name should be CustomTriggerhandler.
    * @param Schema.sObjectType Object type to create the handler
    * @return SL_Trigger_ITriggerHandler A trigger handler if one exists, otherwise null.
    */
    private static SL_Trigger_ITriggerHandler getTriggerHandler(Schema.sObjectType soType) {
        String originalTypeName = soType.getDescribe().getName();
        String handlerTypeName = null;
        String handlerName;
        if (originalTypeName.toLowerCase().endsWith('__c')) {
            Integer index = originalTypeName.toLowerCase().indexOf('__c');
            handlerName = originalTypeName.substring(0, index);
        } else {
            handlerName = originalTypeName;
        }
        if (handlerName.length() > 23) {
            handlerName = handlerName.substring(0, 23);
        }
        handlerTypeName = 'SL_' + handlerName + 'TriggerHandler';

        Type obType = Type.forName(handlerTypeName);

        SL_Trigger_ITriggerHandler handler = (obType == null) ? null : (SL_Trigger_ITriggerHandler) obType.newInstance();
        return handler;
    }

/**===END trigger factory===**/

/**===BEGIN Parameters===**/
    /**
    * @date 11/9/2014
    * @description This class holds the trigger parameters.
    */
    public Enum TriggerEvent {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}

    public class Parameters {

        @TestVisible public List<SObject> oldList { get; private set; }
        @TestVisible public List<SObject> newList { get; private set; }
        @TestVisible public Map<Id, SObject> oldMap { get; private set; }
        @TestVisible public Map<Id, SObject> newMap { get; private set; }
        @TestVisible public String triggerObject { get; private set; }
        @TestVisible public Boolean isExecuting { get; private set; }

        public TriggerEvent tEvent;

        /**
        * @date 11/9/2014
        * @description Constructs the TriggerParameter object.
        * @param List<SObject> A list of records with the state of 'before' event.
        * @param List<SObject> A list of records with the state of 'after' event.
        * @param Map<Id, SObject> A map of records with the state of 'before' event.
        * @param Map<Id, SObject> A map of records with the state of 'after' event.
        * @param Boolean A flag to indicate 'isBefore' event.
        * @param Boolean A flag to indicate 'isAfter' event.
        * @param Boolean A flag to indicate 'isDelete' event.
        * @param Boolean A flag to indicate 'isInsert' event.
        * @param Boolean A flag to indicate 'isUpdate' event.
        * @param Boolean A flag to indicate 'isUnDelete' event.
        * @param Boolean A flag to indicate 'isExecuting'.
        */
        public Parameters(List<SObject> olist, List<SObject> nlist, Map<Id, SObject> omap, Map<Id, SObject> nmap,
                Boolean ib, Boolean ia, Boolean id, Boolean ii, Boolean iu, Boolean iud, Boolean ie) {
            this.oldList = olist;
            this.newList = nlist;
            this.oldMap = omap;
            this.newMap = nmap;
            this.triggerObject = ((this.oldList != null && this.oldList.size() > 0) ? this.oldList[0] : this.newList[0]).getSObjectType().getDescribe().getName();
            if (ib) {
                if (ii) tEvent = TriggerEvent.beforeInsert; else if (iu) tEvent = TriggerEvent.beforeUpdate; else if (id) tEvent = TriggerEvent.beforeDelete;
            } else if (ia) {
                if (ii) tEvent = TriggerEvent.afterInsert; else if (iu) tEvent = TriggerEvent.afterUpdate; else if (id) tEvent = TriggerEvent.afterDelete; else if (iud) tEvent = TriggerEvent.afterUndelete;
            }
            isExecuting = ie;
        }
    }
/**===END Parameters===**/


/**===BEGIN TRIGGER SETTINGS SUPPORT===**/

    /**
    * @date 12/20/2015
    * @description Called to lazy load config options for the execution context via the SL_Trigger_Settings custom setting.
    */
    @TestVisible
    public static SL_Trigger_Settings__c getConfiguration() {

        SL_Trigger_Settings__c orgdefaults = SL_Trigger_Settings__c.getOrgDefaults();
        if(orgdefaults == null) orgdefaults = new SL_Trigger_Settings__c();
        if(orgdefaults.Id == null) {
            orgdefaults.EnableDiagnostics__c = false;
            orgdefaults.KillSwitch__c = false;
            orgdefaults.KillList__c = '';
            orgdefaults.EmailDebugInfoLog__c = false;
            orgdefaults.DebugInfoRecipientEmails__c = '';
        }
        boolean missingDefaults = false;
        if(orgdefaults.MaxDebugInfoRecords__c == null){
            orgdefaults.MaxDebugInfoRecords__c = 100;
            missingDefaults = true;
        }
        if(orgdefaults.MaxDebugInfoAge__c == null){
            orgdefaults.MaxDebugInfoAge__c = 365; //store for a maximum of 365 days.
            missingDefaults = true;
        }
        if(orgdefaults.Id == null) Database.insert(orgdefaults);
        else if(missingDefaults) Database.update(orgdefaults);

        return SL_Trigger_Settings__c.getInstance();
    }

    public static Boolean DiagnosticsEnabled {
        get { return getConfiguration().EnableDiagnostics__c;}
    }

    public static Boolean KillSwitchEnabled {
        get {return getConfiguration().KillSwitch__c;}
    }

    public static String KillList {
        get {return getConfiguration().KillList__c;}
    }

    public static Boolean EmailDebugInfoEnabled {
        get {return getConfiguration().EmailDebugInfoLog__c;}
    }

    public static String DebugInfoEmailRecipients {
        get {return getConfiguration().DebugInfoRecipientEmails__c;}
    }

    public static Integer DebugInfoMaxNum {
        get {return (Integer) getConfiguration().MaxDebugInfoRecords__c;}
    }

    public static Integer DebugInfoMaxAge {
        get {return (Integer) getConfiguration().MaxDebugInfoAge__c;}
    }
/**===END TRIGGER SETTINGS SUPPORT===**/


/**===BEGIN SL_Trigger_DiagnosticsInstrumentation===**/
    /**
    * @date 11/9/2014
    * @description This class implements diagnostics for the application
    */

    private static List<DiagnosticEntry> DiagnosticLog;
    private static Integer CurrentLevel = 0;
    private static List<String> StackTrace = new List<String>();

    private class DiagnosticEntry {
        Integer level;
        String description;

        private DiagnosticEntry(String entrydescription) {
            level = CurrentLevel;
            description = '[' + System.now().format('HH:mm:ss.SSS') + '] {' + UserInfo.getName() + '} ' + entrydescription;
        }
    }

    /**
    * @date 11/9/2014
    * @description Should be called at the start of every function to increment and update the current execution context level.
    */
    public static void Push(String functionname) {
        Debug(functionname);
        CurrentLevel += 1;
        StackTrace.add(functionname);
    }

    /**
    * @date 11/9/2014
    * @description Adds new diagnostic entry to the diagnostic log (if diagnostics are enabled)
    */
    private static void Debug(String debugstring) {
        if (!DiagnosticsEnabled && !EmailDebugInfoEnabled) return;
        if (DiagnosticLog == null) DiagnosticLog = new List<DiagnosticEntry>();
        DiagnosticLog.add(new DiagnosticEntry(debugstring));
    }

    /**
    * @date 11/9/2014
    * @description Called prior to PopAll to add exception info to diagnostic log and object
    */
    private static void DebugException(Exception ex) {
        if (!DiagnosticsEnabled && !EmailDebugInfoEnabled) return;

        String ExceptionTrace = ' Exception occurred line ' + ex.getLineNumber() + ' - ' + ex.getMessage();
        String exceptioninfo = ExceptionTrace + ' stack: ' + ex.getStackTraceString();
        Debug(exceptioninfo);

        SL_Debug_Info__c dbg = new SL_Debug_Info__c(DebugData__c = CurrentLog());
        for (String st : StackTrace) ExceptionTrace += ' | ' + st;
        ExceptionTrace += ' |\n ';

        if (DiagnosticsEnabled) {
            insert dbg;
            if (DebugInfoMaxNum != null || DebugInfoMaxAge != null) CheckDebugInfoLog();
        }
        if (EmailDebugInfoEnabled && DebugInfoEmailRecipients != null && DebugInfoEmailRecipients != '') {
            EmailDebugInfoLog(new List<SL_Debug_Info__c>{
                    dbg
            }, 'The following exception occured, see attached CSV:\n' + dbg.DebugData__c);
        }
    }

    /**
    * @date 11/9/2014
    * @description Should be called on the exit of every function to decrement and update the current execution context level.
    */
    public static void Pop() {
        if (CurrentLevel > 0) CurrentLevel -= 1;
        if (CurrentLevel == 0 && DiagnosticsEnabled) System.Debug(LoggingLevel.Info, 'Diagnostic Log\n' + CurrentLog());
        if (StackTrace.size() > 0) StackTrace.remove(StackTrace.size() - 1);
    }

    /**
    * @date 11/9/2014
    * @description Used for exception handling
    */
    private static void PopAll() {
        CurrentLevel = 0;
        Pop();
    }

    /**
    * @date 11/9/2014
    * @description Returns multi-line string representation of diagnostic log
    */
    @TestVisible
    private static String CurrentLog() {
        if (DiagnosticLog == null) return null;
        String spaces = '                                                                        ';
        String result = '';
        for (DiagnosticEntry de : DiagnosticLog) {
            Integer endindex = 3 * de.level;
            if (endindex >= spaces.length()) endindex = spaces.length() - 1;
            result += spaces.substring(0, endindex) + de.description + '\n';
        }
        return result;
    }

    /**
    * @date 11/9/2014
    * @description Checks if DebugInfo log needs clearing
    */
    @TestVisible
    private static void CheckDebugInfoLog() {
        list<SL_Debug_Info__c> debugInfoLog = [SELECT Id, CreatedDate, Name, DebugData__c FROM SL_Debug_Info__c ORDER BY CreatedDate ASC limit 100];
        if (!debugInfoLog.isEmpty() && DebugInfoMaxNum != null && debugInfoLog.size() >= DebugInfoMaxNum) {
            ClearDebugInfoLog(debugInfoLog);
        }
        //TODO: update this to use the new ability to set CreatedDate in tests and take out Test.isRunningTest().
        if (!debugInfoLog.isEmpty() && DebugInfoMaxAge != null && (debugInfoLog[0].CreatedDate <= System.now().addDays(-1 * DebugInfoMaxAge))) {
            list<SL_Debug_Info__c> debugInfoToDelete = new list<SL_Debug_Info__c>();
            DateTime maxAge = System.now().addDays(-1 * DebugInfoMaxAge);
            for (SL_Debug_Info__c di : debugInfoLog) {
                if (di.CreatedDate <= maxAge)
                    debugInfoToDelete.add(di);
            }
            ClearDebugInfoLog(debugInfoToDelete);
        }
    }

    /**
    * @date 11/9/2014
    * @description Deletes DebugInfo log records
    * @param list<SL_Debug_Info__c> List of debug info records to be deleted
    */
    private static void ClearDebugInfoLog(list<SL_Debug_Info__c> expiredDebugInfoLog) {
        if (EmailDebugInfoEnabled && DebugInfoEmailRecipients != null && DebugInfoEmailRecipients != '') {
            EmailDebugInfoLog(expiredDebugInfoLog);
        }
        delete expiredDebugInfoLog;
    }

    private static void EmailDebugInfoLog(list<SL_Debug_Info__c> debugInfoLog) {
        EmailDebugInfoLog(debugInfoLog, 'Attached is the DebugInfo log that was cleared for ' + UserInfo.getOrganizationName() + '(' + UserInfo.getOrganizationId() + ')');
    }


    private static Boolean getCanSendEmails() {
            // An attempt to reserve some email capacity is the only means available for determining permissions
            // or limits issues. In the case of a lack of permissions, System.NoAccessException is thrown. If
            // limits are exhausted then System.HandledException is thrown
            try {
                Messaging.reserveSingleEmailCapacity(1);
            } catch (Exception e) {
                return false;
            }
        return true;
    }
    /**
    * @date 11/9/2014
    * @description Emails DebugInfo log
    * @param list<SL_Debug_Info__c> List of debug info records to be emailed
    */
    private static void EmailDebugInfoLog(list<SL_Debug_Info__c> debugInfoLog, String emailMessage) {
        //Define email settings
        Messaging.SingleEmailMessage debugInfoEmail = new Messaging.SingleEmailMessage();
        debugInfoEmail.setToAddresses(DebugInfoEmailRecipients.split(';'));
        debugInfoEmail.setSubject('DebugInfo Log for ' + UserInfo.getOrganizationName() + '(' + UserInfo.getOrganizationId() + ')');
        debugInfoEmail.setPlainTextBody(emailMessage);
        debugInfoEmail.setHtmlBody(emailMessage);
        //Generate attachment
        String csvString = new DebugInfoLogAttachment().generate(debugInfoLog);
        transient Blob csvAttachment = Blob.valueOf(csvString);
        transient Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setBody(csvAttachment);
        efa.setContentType('text/csv');
        efa.setFileName(System.today().format() + '_' + UserInfo.getOrganizationName() + '_DebugInfoLog.csv');
        efa.setInline(false);
        debugInfoEmail.setFileAttachments(new Messaging.EmailFileAttachment[]{
                efa
        });
        //Send email
        if(getCanSendEmails()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    debugInfoEmail
            });
        }

    }

    private class DebugInfoLogAttachment {

        private String generate(list<SL_Debug_Info__c> diLog) {
            String s = line(new String[]{
                    format('DebugInfo Entry'),
                    format('Created Date'),
                    format('Debug Data')
            });
            for (SL_Debug_Info__c di : diLog) {
                s += line(new String[]{
                        format(di.Name),
                        format(di.CreatedDate),
                        format(di.DebugData__c)
                });
            }
            return s;
        }
        private String line(String[] cells) {
            return String.join(cells, ',') + '\n';
        }
        private String format(DateTime dt) {
            return dt != null ? '"' + dt.format().escapeCsv() + '"' : '""';
        }
        private String format(String s) {
            return s != null ? '"' + s.escapeCsv() + '"' : '""';
        }
    }
/**===END SL_Trigger_DiagnosticsInstrumentation===**/


/**===BEGIN base trigger handler===**/
    /**
    * @date 11/9/2014
    * @description This class implements the ITriggerDispatcher and acts as an adapter to avoid implementing all the
    *				ITriggerDispatcher methods.
    */
    private static Map<String, Boolean> isProcessing = new Map<String, Boolean>();
    public abstract class baseHandler implements SL_Trigger_ITriggerHandler {
        /**
        * @date 11/9/2014
        * @description This method is called prior to execution of a before trigger event. If you want
        *				to load any lookup data or cache the data, then this is the place that you need
        *				to put your code.
        */
        public virtual void bulkBefore() {
        }

        /**
        * @date 11/9/2014
        * @description This method is called prior to execution of an after trigger event.
        */
        public virtual void bulkAfter() {
        }

        /**
        * @date 3/28/2018
        * @description These methods correspond to each of the various DML operations.
        * NOTE: Make sure to override all methods for DML operations trigger is running on.
        */
        public virtual void beforeInsert(List<SObject> newList){ system.assert(false,unimplementedDMLMessage('beforeInsert'));}
        public virtual void afterInsert(Map<Id, SObject> newMap){ system.assert(false,unimplementedDMLMessage('afterInsert'));}
        public virtual void beforeDelete(Map<Id, SObject> oldMap){ system.assert(false,unimplementedDMLMessage('beforeDelete'));}
        public virtual void afterDelete(Map<Id, SObject> oldMap){ system.assert(false,unimplementedDMLMessage('afterDelete'));}
        public virtual void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){ system.assert(false,unimplementedDMLMessage('afterUpdate'));}
        public virtual void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){ system.assert(false,unimplementedDMLMessage('beforeUpdate'));}
        public virtual void afterUndelete(Map<Id, SObject> newMap){ system.assert(false,unimplementedDMLMessage('afterUndelete'));}

        /**
        * @date 11/9/2014
        * @description optional. Allows you to define custom handlers if DML operation is being run recursively.
        */
        public virtual void beforeInsertRecursive(List<SObject> newList) { beforeInsert(newList);}
        public virtual void afterInsertRecursive(Map<Id, SObject> newMap) { afterInsert(newMap);}
        public virtual void beforeUpdateRecursive(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) { beforeUpdate(oldMap, newMap);}
        public virtual void afterUpdateRecursive(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) { afterUpdate(oldMap, newMap);}
        public virtual void beforeDeleteRecursive(Map<Id, SObject> oldMap) { beforeDelete(oldMap);}
        public virtual void afterDeleteRecursive(Map<Id, SObject> oldMap) { afterDelete (oldMap);}
        public virtual void afterUndeleteRecursive(Map<Id, SObject> newMap) { afterUndelete (newMap);}

        /**
        * @date 11/9/2014
        * @description Called by the event handlers. If this is the first call in the context, then this method will create a new
        *				instance of the appropriate handler and execute the mainEntry method. If there is an existing call runing
        *				on the same context, then this method will use the existing handler instance created by the original call
        *				and execute the inProgressEntry method.
        * @param ITriggerHandler The trigger handler instance. The dispatcher need to pass an instance of the trigger handler, such
        *							as AccountAfterInsertTriggerHandler if this is the first call in a given context. If it is retry,
        *							then the dispatcher will need to pass null.
        * @param SL_Trigger_Parameters The trigger parameters passed by the framework.
        * @param SL_Trigger_Parameters.TriggerEvent The trigger event.
        */
        public void execute(SL_Trigger.Parameters tp, String context) {
            Boolean inProgress = isProcessing.get(tp.triggerObject + context);
            // Standard Entry
            if (inProgress != true) {
                isProcessing.put(tp.triggerObject + context, true);
                SL_Trigger.Push(tp.triggerObject + 'TriggerDispatcher.' + context);
                if (context == 'beforeInsert') {
                    beforeInsert(tp.newList);
                } else if (context == 'beforeUpdate') {
                    beforeUpdate(tp.oldMap, tp.newMap);
                } else if (context == 'beforeDelete') {
                    beforeDelete(tp.oldMap);
                } else if (context == 'afterInsert') {
                    afterInsert(tp.newMap);
                } else if (context == 'afterUpdate') {
                    afterUpdate(tp.oldMap, tp.newMap);
                } else if (context == 'afterDelete') {
                    afterDelete(tp.oldMap);
                } else if (context == 'afterUndelete') {
                    afterUndelete(tp.newMap);
                }
                SL_Trigger.Pop();
                isProcessing.put(tp.triggerObject + context, false);
            }
            // Recursive Entry
            else {
                SL_Trigger.Push(tp.triggerObject + 'TriggerDispatcher.' + context + 'Recursion');
                if (context == 'beforeInsert') {
                    beforeInsertRecursive(tp.newList);
                } else if (context == 'beforeUpdate') {
                    beforeUpdateRecursive(tp.oldMap, tp.newMap);
                } else if (context == 'beforeDelete') {
                    beforeDeleteRecursive(tp.oldMap);
                } else if (context == 'afterInsert') {
                    afterInsertRecursive(tp.newMap);
                } else if (context == 'afterUpdate') {
                    afterUpdateRecursive(tp.oldMap, tp.newMap);
                } else if (context == 'afterDelete') {
                    afterDeleteRecursive(tp.oldMap);
                } else if (context == 'afterUndelete') {
                    afterUndeleteRecursive(tp.newMap);
                }
                SL_Trigger.Pop();
            }
        }

        private String unimplementedDMLMessage(String dmlOperation){
            return String.format('This trigger runs on {0} but the trigger handler has not implemented {0} method.',new list<String>{dmlOperation});
        }
    }
/**===END base trigger handler===**/

    public class FrameworkException extends Exception {}

}