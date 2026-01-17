public with sharing class TC_EquipmentCodeUtil {
    
    // this is needed to check against the label of a picklist
    public static Boolean isMedical (String value, Map <String, String> labelMap) {
        if(labelMap<>null) {
            // return value == null && labelMap.get (value) != null ? false : labelMap.get (value) == 'Medical';
            // Updated this back to previous code
            return value == null || labelMap.get (value) == null ? false : labelMap.get (value).containsIgnoreCase('Medical');
            // Release 3.2 and SAL-2675 fix starts
            // return value != null && labelMap.get (value) != null ? labelMap.get (value).Contains('Medical') : false;
            // Release 3.2 and SAL-2675 fix ends
        }
        else{
            return false;
        }
    }
    
    // Infolease Dealer equipment codes don't have a dot
    // Infolease Asset equipment codes do
    // They are saved with a dot
    public static String removeDot (String code) {
        if (String.isBlank (code)) return null;
        
        if (code.contains('.')) {
            String newCode = '';
            for (String str : code.split('\\.')) {
                newCode += str;
            }
            return newCode;
        } else {
            return code;
        }
    }
    
}