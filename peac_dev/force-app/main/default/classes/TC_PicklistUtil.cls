public with sharing class TC_PicklistUtil {

    public static Map <String, String> getLabelMap (Schema.sObjectField field) {
        Map <String, String> labelMap = new Map <String, String> ();

        for (Schema.PicklistEntry f : field.getDescribe().getPicklistValues()) {
            labelMap.put(f.getValue(),f.getLabel());
        }
        return labelMap;
    }

}