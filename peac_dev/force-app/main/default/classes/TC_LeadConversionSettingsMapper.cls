public class TC_LeadConversionSettingsMapper {
    
    public static List <TC_LeadConversionSetting> parseResponse (String xmlResp) {
        
        List <TC_LeadConversionSetting> leadConversionSettings = new List <TC_LeadConversionSetting> ();
        Dom.Document xmlDoc = new Dom.Document ();
        xmlDoc.load (xmlResp);
        
        for (Dom.XMLNode bodyNode : xmlDoc.getRootElement().getChildren()) {
            for (Dom.XMLNode metadataRespNode : bodyNode.getChildren()) {
                for (Dom.XMLNode resultNode : metadataRespNode.getChildren()) {
                    for (Dom.XMLNode recordsNode : resultNode.getChildren()) {
                        for (Dom.XMLNode recordItemsNode : recordsNode.getChildren()) {
                            System.debug (recordItemsNode.getName());
                        	if ('objectMapping' == recordItemsNode.getName()) {
                            	parseLeadConversionSettings (recordItemsNode, leadConversionSettings);
                        	}
                        }
                        
                    }
                }
            }
            
        }
        
        System.debug ('leadConversionSettings: ' + leadConversionSettings);
        return leadConversionSettings;
    }
    
    private static void parseLeadConversionSettings (Dom.XMLNode recordsNode, List <TC_LeadConversionSetting> leadConversionSettings) {
        
        TC_LeadConversionSetting conversionSetting = new TC_LeadConversionSetting ();
        List <TC_LeadConversionSetting.FieldMapping> fieldMappings = new List <TC_LeadConversionSetting.FieldMapping> ();
        
        for (Dom.XMLNode objectMappingNode : recordsNode.getChildren()) {

            if ('mappingFields' == objectMappingNode.getName()) {
                TC_LeadConversionSetting.FieldMapping fieldmapping = new TC_LeadConversionSetting.FieldMapping ();
                for (Dom.XMLNode mappingFieldsNode : objectMappingNode.getChildren()) {
                    if ('inputField' == mappingFieldsNode.getName()) {
                        fieldmapping.inputField = mappingFieldsNode.getText ();
                    } else if ('outputField' == mappingFieldsNode.getName()) {
                        fieldmapping.outputField = mappingFieldsNode.getText ();
                    }
                }
                conversionSetting.fieldMappings.add (fieldmapping);
            }
            if ('outputObject' == objectMappingNode.getName()) {
                conversionSetting.outputObject = objectMappingNode.getText ();
            }
        }
        leadConversionSettings.add (conversionSetting);
    }
}