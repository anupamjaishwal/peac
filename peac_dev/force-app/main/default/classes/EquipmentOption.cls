public class EquipmentOption {

    @AuraEnabled
    @InvocableVariable(label='Label')
    public String label;

    @AuraEnabled
    @InvocableVariable(label='Value')
    public String value;

    public EquipmentOption() {}
}