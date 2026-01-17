public with sharing class SL_ReturnAuthorizationController {
    public List<FieldWrapper> headers { get; set; }
    public Map<String, List<FieldWrapper>> groupedFieldsByAddress { get; set; }
    public List<String> returnAddresses { get; set; }
    public Boolean isPartialBuyout { get; set; }
    public String logoResourceName { get; set; }
    public Map<String, String> formattedAddresses { get; set; }
    public Decimal assetTotalValue { get; set; }

    public SL_ReturnAuthorizationController() {
        String contractId = ApexPages.currentPage().getParameters().get('contractId');
        String buyoutSeq = ApexPages.currentPage().getParameters().get('buyoutSeq');
        this.setHeaders(contractId);
        this.setFieldsGroupedByAddress(contractId, buyoutSeq);
        this.setLogoResource(contractId);
    }

    public void setHeaders(String contractId) {
        List<FieldWrapper> allHeaders = new List<FieldWrapper>();
        Contract__c thisContract = [
            SELECT Name, Customer__r.Name, Address_1__c, City__c,
                   State__c, Zip_Code__c, Program__c, Branded_Phone__c
            FROM Contract__c
            WHERE Id = :contractId
        ];
        String addressString = thisContract.Address_1__c + '<br> ' +
                               thisContract.City__c + ', ' +
                               thisContract.State__c + ', ' +
                               thisContract.Zip_Code__c;
        allHeaders.add(new FieldWrapper('Contract#', thisContract.Name, false, true));
        allHeaders.add(new FieldWrapper('Customer Name', thisContract.Customer__r.Name, false, true));
        allHeaders.add(new FieldWrapper('Customer Address', addressString.replaceAll('null', ''), false, true));
        allHeaders.add(new FieldWrapper('Branded Phone', thisContract.Branded_Phone__c, false, true));
        this.headers = allHeaders;
    }

    public void setFieldsGroupedByAddress(String contractId, String buyoutSeq) {
        List<Buyout__c> buyouts = [
            SELECT Id, Name, Partial_Buyout__c, Date_Quoted__c, Contract__c
            FROM Buyout__c
            WHERE Contract__c = :contractId AND Quote_Sequence__c = :buyoutSeq
        ];
        this.groupedFieldsByAddress = new Map<String, List<FieldWrapper>>();
        this.returnAddresses = new List<String>();
        this.formattedAddresses = new Map<String, String>();
        this.assetTotalValue = 0;
        Map<String, String> locationAddressMap = new Map<String, String>();

        if(buyouts.isEmpty()){
            throw new applicationException('ERROR! The buyout record is missing on Salesforce.');
        }else{
            this.isPartialBuyout = buyouts[0].Partial_Buyout__c;
            
            List<Buyout_Asset__c> buyoutAssets = [
                SELECT Contract_Asset__r.Name, Contract_Asset__r.SP_Mfg_Make__c,
                       Contract_Asset__r.Model_Number__c, Contract_Asset__r.Serial_Number__c,
                       Contract_Asset__r.Return_Address__c, Contract_Asset__r.Asset_Cost__c, 
                       Contract_Asset__r.Location__r.Contact_Phone__c, Contract_Asset__r.Asset_Number__c,
                       Contract_Asset__r.Service_Provider__r.Name, Contract_Asset__r.Location__c, Contract_Asset__r.Manufacturer__c
                FROM Buyout_Asset__c
                WHERE Buyout__c = :buyouts[0].Id AND Contract_Asset__r.Asset_Cost__c > 0
            ];
    
            for (Buyout_Asset__c buyoutAsset : buyoutAssets) {
                Contract_Asset__c contractAsset = buyoutAsset.Contract_Asset__r;
                String returnAddress = contractAsset.Return_Address__c;
                
                if (!groupedFieldsByAddress.containsKey(returnAddress)) {
                    groupedFieldsByAddress.put(returnAddress, new List<FieldWrapper>());
                    returnAddresses.add(returnAddress);
                    locationAddressMap.put(contractAsset.Location__c, returnAddress);
                }

                List<FieldWrapper> fieldList = groupedFieldsByAddress.get(returnAddress);
                fieldList.add(new FieldWrapper('Asset ID', contractAsset.Asset_Number__c, false, true));
                fieldList.add(new FieldWrapper('Make/Mfg.', contractAsset.Manufacturer__c, false, true));
                fieldList.add(new FieldWrapper('Model', contractAsset.Model_Number__c, false, true));
                fieldList.add(new FieldWrapper('Serial', contractAsset.Serial_Number__c, false, true));
                fieldList.add(new FieldWrapper('Value', String.valueOf(contractAsset.Asset_Cost__c), false, true));
                fieldList.add(new FieldWrapper('Phone', contractAsset.Location__r.Contact_Phone__c, false, true));
                fieldList.add(new FieldWrapper('Service Provider Name', (contractAsset.Service_Provider__r.Name != null) ? contractAsset.Service_Provider__r.Name : 'N/A', false, true));
                
                // Add asset cost to total value
                this.assetTotalValue += contractAsset.Asset_Cost__c == null? 0 : contractAsset.Asset_Cost__c;
            }
        }
        // Formatting the addresses
        if (!locationAddressMap.isEmpty()) {
            Map<ID, Schema.Location> locationMap = new Map<ID, Schema.Location>([SELECT Id, Service_Provider__r.Name, Address_1__c, Address_2__c, State__c, City__c, Zip__c FROM Location WHERE Id IN :locationAddressMap.keySet()]);
            if (!locationMap.isEmpty()) {
                for (String s : locationAddressMap.keySet()) {
                    if (s == null) {
                        throw new applicationException('ERROR! Verify the following fields: Equipment type = Office Equipment(General). Equipment Subtype = Copiers. Asset state is not Blank.');
                    } else {
                        String addressString = '';
                        addressString = locationMap.get(s).Service_Provider__r.Name == null ? addressString + '' : addressString + locationMap.get(s).Service_Provider__r.Name + ' ';
                        addressString = locationMap.get(s).Address_1__c == null ? addressString + '' : addressString + locationMap.get(s).Address_1__c + ' ';
                        addressString = locationMap.get(s).Address_2__c == null ? addressString + '' : addressString + locationMap.get(s).Address_2__c + ' ';
                        addressString = locationMap.get(s).City__c == null ? addressString + '' : addressString + locationMap.get(s).City__c + ', ';
                        addressString = locationMap.get(s).State__c == null ? addressString + '' : addressString + locationMap.get(s).State__c + ' ';
                        addressString = locationMap.get(s).Zip__c == null ? addressString + '' : addressString + locationMap.get(s).Zip__c + ' ';
                        formattedAddresses.put(locationAddressMap.get(s), addressString);      
                    }          
                }
            }
            else {
                throw new applicationException('Return Authorization cannot be generated.');
            }
        }
        else{
            throw new applicationException('Return Authorization cannot be generated.');
        }
    }

    public void setLogoResource(String contractId) {
        Contract__c thisContract = [
            SELECT Program__c
            FROM Contract__c
            WHERE Id = :contractId
        ];
        if (thisContract.Program__c != null && thisContract.Program__c.contains('XBS')) {
            logoResourceName = 'XBSLogo';
        } else {
            logoResourceName = 'LeaseServicesLogo';
        }
    }

    public List<FieldWrapper> getHeaders() {
        return this.headers;
    }

    public Map<String, List<FieldWrapper>> getGroupedFieldsByAddress() {
        return this.groupedFieldsByAddress;
    }

    public List<String> getReturnAddresses() {
        return this.returnAddresses;
    }

    public String getLogoResourceName() {
        return logoResourceName;
    }

    public Boolean getIsPartialBuyout() {
        return this.isPartialBuyout;
    }

    public Decimal getAssetTotalValue() {
        return this.assetTotalValue;
    }

    public class FieldWrapper {
        public String label { get; set; }
        public String value { get; set; }
        public Boolean isCurrency { get; set; }
        public Boolean isPlain { get; set; }
        public FieldWrapper(String label, String value, Boolean isCurrency, Boolean isPlain) {
            this.label = label;
            this.value = value;
            this.isCurrency = isCurrency;
            this.isPlain = isPlain;
        }
    }

    public class applicationException extends Exception {}
}