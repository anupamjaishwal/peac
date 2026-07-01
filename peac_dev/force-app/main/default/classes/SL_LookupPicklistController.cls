/**
 * SL_LookupPicklistController
 * Generic Apex controller for searching records of any sObject,
 * with support for direct field filtering or junction object filtering.
 *
 * ─── FILTERING MODES ─────────────────────────────────────────────────────
 *
 * MODE 1 — Direct filter (lookup field on the target object itself):
 *   sObjectApiName : 'Program__c'
 *   filterField    : 'Account__c'
 *   filterValue    : '001XXXXXXXXXXXXXXX'
 *   → SELECT Id, Name FROM Program__c WHERE Account__c = 'filterValue'
 *
 * MODE 2 — Junction object filter (Many-to-Many):
 *   sObjectApiName      : 'Program__c'
 *   filterValue         : '001XXXXXXXXXXXXXXX'
 *   junctionObject      : 'Account_Program__c'
 *   junctionFilterField : 'Account__c'
 *   junctionTargetField : 'Program__c'
 *   → SELECT Id, Name FROM Program__c
 *       WHERE Id IN (
 *           SELECT Program__c FROM Account_Program__c WHERE Account__c = 'filterValue'
 *       )
 *
 * Both modes support optional text search via searchTerm.
 */
public with sharing class SL_LookupPicklistController {

    // ─── Result wrapper ───────────────────────────────────────────────────

    public class LookupResult {
        @AuraEnabled public String id;
        @AuraEnabled public String label;
        @AuraEnabled public Map<String, String> extraData;
    }

    /**
     * Describes how the lookup should behave based on how many
     * junction records exist for the given filter value.
     *
     * count = 0 → field is optional, no auto-selection
     * count = 1 → field is pre-filled and read-only
     * count > 1 → field is required, user must pick
     */
    public class ProgramRules {
        @AuraEnabled public Integer       count;
        @AuraEnabled public LookupResult  autoSelected; // populated only when count = 1
        @AuraEnabled public Boolean       isRequired;
        @AuraEnabled public Boolean       isReadOnly;
    }

    // ─── getProgramRules ──────────────────────────────────────────────────

    /**
     * Returns the display/validation rules for the Program lookup
     * based on how many Account_Program__c records exist for the Account.
     *
     * Called once when the AccountId is set or changes.
     *
     * @param accountId   Id of the Account on the Opportunity
     * @return            ProgramRules with count, autoSelected, isRequired, isReadOnly
     */
    @AuraEnabled(cacheable=true)
    public static ProgramRules getProgramRules(String accountId) {
        ProgramRules rules = new ProgramRules();
        rules.autoSelected = null;
        rules.count        = 0;
        rules.isRequired   = false;
        rules.isReadOnly   = false;

        if (String.isBlank(accountId)) return rules;

        List<Account_Program__c> junctions = [
            SELECT Program__c, Program__r.Name
            FROM   Account_Program__c
            WHERE  Account__c = :accountId
            WITH   SECURITY_ENFORCED
            LIMIT  200
        ];

        rules.count = junctions.size();

        if (rules.count == 1) {
            // Single program — pre-select and lock the field
            rules.isRequired   = false;
            rules.isReadOnly   = true;
            LookupResult lr    = new LookupResult();
            lr.id              = junctions[0].Program__c;
            lr.label           = junctions[0].Program__r.Name;
            lr.extraData       = new Map<String, String>();
            rules.autoSelected = lr;

        } else if (rules.count > 1) {
            // Multiple programs — mandatory, user must choose
            rules.isRequired = true;
            rules.isReadOnly = false;
        }
        // count = 0 → both false, field is optional

        return rules;
    }

    // ─── searchRecords ────────────────────────────────────────────────────

    /**
     * Searches records dynamically with optional text search and filter.
     *
     * @param sObjectApiName        API name of the object to search
     * @param displayField          Field to display in the dropdown
     * @param searchTerm            Text typed by the user (can be empty)
     * @param filterField           Field on the main object for direct filtering (Mode 1)
     * @param filterValue           Filter value — typically a parent record Id
     * @param extraFields           Comma-separated additional fields to return
     * @param maxResults            Maximum number of results (default 10)
     * @param junctionObject        API name of the junction object
     * @param junctionFilterField   Field on the junction that receives filterValue
     * @param junctionTargetField   Field on the junction pointing to sObjectApiName
     */
    @AuraEnabled(cacheable=true)
    public static List<LookupResult> searchRecords(
        String  sObjectApiName,
        String  displayField,
        String  searchTerm,
        String  filterField,
        String  filterValue,
        String  extraFields,
        Integer maxResults,
        String  junctionObject,
        String  junctionFilterField,
        String  junctionTargetField
    ) {
        if (String.isBlank(sObjectApiName) || String.isBlank(displayField)) {
            throw new AuraHandledException('sObjectApiName and displayField are required.');
        }

        validateApiName(sObjectApiName);
        validateApiName(displayField);
        if (String.isNotBlank(filterField))         validateApiName(filterField);
        if (String.isNotBlank(junctionObject))      validateApiName(junctionObject);
        if (String.isNotBlank(junctionFilterField)) validateApiName(junctionFilterField);
        if (String.isNotBlank(junctionTargetField)) validateApiName(junctionTargetField);
        if (String.isNotBlank(extraFields)) {
            for (String f : extraFields.split(',')) validateApiName(f.trim());
        }

        Integer lim = (maxResults != null && maxResults > 0) ? maxResults : 10;

        Set<String> fields = new Set<String>{ 'Id', displayField };
        if (String.isNotBlank(extraFields)) {
            for (String f : extraFields.split(',')) {
                if (String.isNotBlank(f)) fields.add(f.trim());
            }
        }
        String selectClause = 'SELECT ' + String.join(new List<String>(fields), ', ');

        List<String> conditions = new List<String>();

        if (String.isNotBlank(searchTerm)) {
            String safeTerm = String.escapeSingleQuotes(searchTerm.trim()) + '%';
            conditions.add(displayField + ' LIKE \'' + safeTerm + '\'');
        }

        if (String.isNotBlank(filterValue)) {
            Boolean useJunction = String.isNotBlank(junctionObject)
                               && String.isNotBlank(junctionFilterField)
                               && String.isNotBlank(junctionTargetField);
            if (useJunction) {
                String safeVal  = String.escapeSingleQuotes(filterValue.trim());
                String subquery = 'SELECT ' + junctionTargetField
                    + ' FROM '  + junctionObject
                    + ' WHERE ' + junctionFilterField
                    + ' = \''   + safeVal + '\'';
                conditions.add('Id IN (' + subquery + ')');
            } else if (String.isNotBlank(filterField)) {
                String safeVal = String.escapeSingleQuotes(filterValue.trim());
                conditions.add(filterField + ' = \'' + safeVal + '\'');
            }
        }

        String whereClause = conditions.isEmpty()
            ? '' : ' WHERE ' + String.join(conditions, ' AND ');

        String query = selectClause
            + ' FROM '     + sObjectApiName
            + whereClause
            + ' ORDER BY ' + displayField
            + ' LIMIT '    + lim;

        List<LookupResult> results = new List<LookupResult>();
        for (SObject record : Database.query(query)) {
            LookupResult lr = new LookupResult();
            lr.id        = (String) record.get('Id');
            lr.label     = (String) record.get(displayField);
            lr.extraData = new Map<String, String>();
            if (String.isNotBlank(extraFields)) {
                for (String f : extraFields.split(',')) {
                    String key = f.trim();
                    Object val = record.get(key);
                    lr.extraData.put(key, val != null ? String.valueOf(val) : '');
                }
            }
            results.add(lr);
        }
        return results;
    }

    // ─── getRecordById ────────────────────────────────────────────────────

    /**
     * Retrieves a single record by Id.
     * Used to pre-populate the lookup label when editing an existing record.
     */
    @AuraEnabled(cacheable=true)
    public static LookupResult getRecordById(
        String sObjectApiName,
        String displayField,
        String recordId
    ) {
        if (String.isBlank(sObjectApiName) || String.isBlank(displayField) || String.isBlank(recordId)) {
            return null;
        }
        validateApiName(sObjectApiName);
        validateApiName(displayField);

        String query = 'SELECT Id, ' + displayField
            + ' FROM '  + sObjectApiName
            + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\''
            + ' LIMIT 1';

        List<SObject> records = Database.query(query);
        if (records.isEmpty()) return null;

        LookupResult lr = new LookupResult();
        lr.id        = (String) records[0].get('Id');
        lr.label     = (String) records[0].get(displayField);
        lr.extraData = new Map<String, String>();
        return lr;
    }

    // ─── Security ─────────────────────────────────────────────────────────

    /**
     * Validates that an API name only contains safe characters.
     * Prevents SOQL injection when building dynamic queries.
     */
    private static void validateApiName(String name) {
        if (!Pattern.matches('[a-zA-Z0-9_]+', name)) {
            throw new AuraHandledException('Invalid field or object name: ' + name);
        }
    }
}