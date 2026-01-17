/**
 * Created by andrewmayer on 10/25/18.
 */

public without sharing class TC_LeadMappingToCustMetadata {

    public static void updateMetadata () {
        List <TC_LeadConversionSetting> conversionSettings = new List <TC_LeadConversionSetting> ();
        conversionSettings = TC_LeadConversionSettingsService.sendLeadConversionSettingsRequest ();

        List <Standard_Mapping_Auto_Lead_Conversion__c> stndMapingDeletes = new List <Standard_Mapping_Auto_Lead_Conversion__c> ([SELECT Id FROM Standard_Mapping_Auto_Lead_Conversion__c]);
        List <Standard_Mapping_Auto_Lead_Conversion__c> stndMaping = new List <Standard_Mapping_Auto_Lead_Conversion__c> ();
        Map <String, Integer> dupeNameChecker = new Map <String, Integer> ();

        for (TC_LeadConversionSetting setting : conversionSettings) {

            for (TC_LeadConversionSetting.FieldMapping field : setting.fieldMappings) {

                // need to make sure names of the custom metadata don't collide. Custom metadata name has a max width of 38, which can cause collisions if there is a long field api name

                String name = (field.inputField + '-' + field.outputField + ' on ' + setting.outputObject).left (37);

                if (dupeNameChecker.get (name) == null) {
                    dupeNameChecker.put (name, 1);
                } else {
                    dupeNameChecker.put (name, dupeNameChecker.get (name) + 1);
                }

                stndMaping.add (new Standard_Mapping_Auto_Lead_Conversion__c (Output_Object__c = setting.outputObject, Input_Field__c = field.inputField, Output_Field__c = field.outputField, Name = name + dupeNameChecker.get (name)));
            }
        }

        stndMaping.add (new Standard_Mapping_Auto_Lead_Conversion__c (Output_Object__c = 'Contact', Input_Field__c = 'FirstName', Output_Field__c = 'FirstName', Name = 'FirstName_to_FirstName'));
        stndMaping.add (new Standard_Mapping_Auto_Lead_Conversion__c (Output_Object__c = 'Contact', Input_Field__c = 'LastName', Output_Field__c = 'LastName', Name = 'LastName_to_LastName'));
        stndMaping.add (new Standard_Mapping_Auto_Lead_Conversion__c (Output_Object__c = 'Contact', Input_Field__c = 'Email', Output_Field__c = 'Email', Name = 'Email_to_EmailCon'));
        stndMaping.add (new Standard_Mapping_Auto_Lead_Conversion__c (Output_Object__c = 'Contact', Input_Field__c = 'Phone', Output_Field__c = 'Phone', Name = 'Phone_to_PhoneCon'));
        stndMaping.add (new Standard_Mapping_Auto_Lead_Conversion__c (Output_Object__c = 'Account', Input_Field__c = 'Company', Output_Field__c = 'Name', Name = 'Company_to_NameAcc'));
        stndMaping.add (new Standard_Mapping_Auto_Lead_Conversion__c (Output_Object__c = 'Opportunity', Input_Field__c = 'Company', Output_Field__c = 'Name', Name = 'Company_to_NameOpp'));

        // adding standard mappings that aren't specified in the standard mapping


        if (!stndMapingDeletes.isEmpty()) delete stndMapingDeletes;
        if (!stndMaping.isEmpty()) insert stndMaping;
    }


}