/**
 * Created on 12/11/17.
 */

public with sharing class TC_GetPicklistOptionsCtrl {
    @AuraEnabled
    public static List <String> getSelectOptions (sObject objObject, String fld) {
        List <String> allOpts = new list <String> ();

        // Get the object type of the SObject.
        Schema.sObjectType objType = objObject.getSObjectType ();

        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe ();

        // Get a map of fields for the SObject
        Map <String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap ();

        // Get the list of picklist values for this field.
        List <Schema.PicklistEntry> values = fieldMap.get(fld).getDescribe().getPickListValues();

        if (fld == 'BillingStateCode' || fld == 'MailingStateCode' || fld == 'OtherStateCode') {
            // validFor property cannot be accessed via a method or a property,
            // so we need to serialize the PicklistEntry object and then deserialize into a wrapper.
            String contrEntriesKey = '';

            if (fld == 'BillingStateCode') {
                contrEntriesKey = 'BillingCountryCode';
            } else if (fld == 'MailingStateCode') {
                contrEntriesKey = 'MailingCountryCode';
            } else if (fld == 'OtherStateCode') {
                contrEntriesKey = 'OtherCountryCode';
            }

            List<Schema.PicklistEntry> contrEntries = fieldMap.get(contrEntriesKey).getDescribe().getPicklistValues();
            List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(values);

            // Set up the return container - Map<ControllingValue, List<DependentValues>>
            Map<String, List<String>> objResults = new Map<String, List<String>>();
            List<String> controllingValues = new List<String>();

            for (Schema.PicklistEntry ple : contrEntries) {
                String label = ple.getLabel();
                objResults.put(label, new List<String>());
                controllingValues.add(label);
            }

            for (PicklistEntryWrapper plew : depEntries) {
                String label = plew.label;
                String validForBits = base64ToBits(plew.validFor);
                for (Integer i = 0; i < validForBits.length(); i++) {
                    // For each bit, in order: if it's a 1, add this label to the dependent list for the corresponding controlling value
                    String bit = validForBits.mid(i, 1);
                    if (bit == '1') {
                        objResults.get(controllingValues.get(i)).add(plew.value);
                    }
                }
            }

            allOpts = objResults.get('United States');
        }
        else {
            // Add these values to the selectoption list.
            for (Schema.PicklistEntry a: values)
                allOpts.add(a.getValue());
        }

        allOpts.sort();
        return allOpts;
    }

    @AuraEnabled
    public static sObject setPickListVal (sObject objObject, String fld, String value) {
        objObject.put(fld, value);
        System.debug(objObject);
        return objObject;
    }

    // Convert decimal to binary representation (alas, Apex has no native method :-(
    //    eg. 4 => '100', 19 => '10011', etc.
    // Method: Divide by 2 repeatedly until 0. At each step note the remainder (0 or 1).
    // These, in reverse order, are the binary.
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    // Convert a base64 token into a binary/bits representation
    // e.g. 'gAAA' => '100000000000000000000'
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';

        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    private static final String base64Chars = '' +
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
            'abcdefghijklmnopqrstuvwxyz' +
            '0123456789+/';

    public static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
                JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    public class PicklistEntryWrapper {
        public String active {get; set;}
        public String defaultValue {get; set;}
        public String label {get; set;}
        public String value {get; set;}
        public String validFor {get; set;}
    }
}