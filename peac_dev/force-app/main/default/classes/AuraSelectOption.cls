/**
 * This class is provided open source under the MIT license
 * Class for aura select options from Apex PicklistEntries
 */
public with sharing class AuraSelectOption {
    @AuraEnabled public String value {Get;Set;}
    @AuraEnabled public String label {Get;Set;}
    @AuraEnabled public Boolean isDisabled {Get;Set;}
    @AuraEnabled public Boolean isSelected {Get;Set;}

    public AuraSelectOption() {

    }

    public AuraSelectOption(String val, String lbl, Boolean active, Boolean selected) {
        this.value = val;
        this.label = lbl;
        this.isDisabled = !active;
        this.isSelected = selected;
    }

    public AuraSelectOption(SelectOption so) {
        this(so.getValue(), so.getLabel(), !so.getDisabled(), false);
    }

    public AuraSelectOption(PicklistEntry ple) {
        this(ple.getValue(), ple.getLabel(), ple.isActive(), ple.isDefaultValue());
    }

    public AuraSelectOption(String val, String lbl) {
        this(val,lbl,true,false);
    }
}