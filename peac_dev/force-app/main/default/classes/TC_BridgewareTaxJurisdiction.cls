public class TC_BridgewareTaxJurisdiction {
    
    public TC_BridgewareTaxJurisdiction(){}
    
    @AuraEnabled
    public String city;
    @AuraEnabled
    public String county;
    @AuraEnabled
    public String state;
    @AuraEnabled
    public String cityCode;
    @AuraEnabled
    public String countyCode;
    @AuraEnabled
    public String stateCode;
    @AuraEnabled
    public String zip;
    @AuraEnabled
    public String rateCodeDescription;
    @AuraEnabled
    public String rateCode;
    @AuraEnabled
    public Double stateTaxRate;
    @AuraEnabled
    public Double countyTaxRate;
    @AuraEnabled
    public Double countyTransTaxRate;
    @AuraEnabled
    public Double cityTaxRate;
    @AuraEnabled
    public Double cityTransTaxRate;
    @AuraEnabled
    public Boolean zipUpdated;
}