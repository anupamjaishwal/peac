public class TC_LeadConversionSetting {
    public String outputObject;
	public List <FieldMapping> fieldMappings;
    
    public TC_LeadConversionSetting () {
        outputObject = '';
        fieldMappings = new List <FieldMapping> ();
    }
    
    public class FieldMapping {
        
        public String inputField;
        public String outputField;
        
        public FieldMapping () {
            inputField = '';
            outputField = '';
        }
    }
}