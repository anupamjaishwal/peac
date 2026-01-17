public with sharing class TC_Asset {

    // A new field Equipment Sub Category was added
    // InfoLease and GDS scoring need the most specific version of the code
    // Ensure calling logic queries Equipment_Sub_Category__c and Equipment_Code__c
    public static String getMostGranularAssetCode (Asset__c asset) {
        if (asset == null) return null;
        return String.isBlank(asset.Equipment_Sub_Category__c) ? asset.Equipment_Code__c : asset.Equipment_Sub_Category__c;
    }

}