/*******************************
* @Name         SL_CaseTriggerHelper 
* @Author       Jonathan Munguia
* @Date         07/26/24
* @Group        Silverline
* @Description  This class is to add more functionalities to the SL_CaseTriggerHelper class 
*				Additional comments 
*******************************/
/* MODIFICATION LOG
* Version          Developer          Date          Group           Description
*-------------------------------------------------------------------------------------------
*  1.0             Jonathan Munguia   07/26/24    Silverline     Initial Version SL-2090.                                      
*******************************/
public with sharing class SL_CaseTriggerHelper {
    private static final String PROGRAM_XBS_TYPE = 'XBS';

    /**
     * @Description SL-2090: Gets the Contracts Names from the String separated by commas or semicolons.
     * @param String contractNumbersBundle (Contract Names separated by comma or semicolons).
     * @return Set<String> set of Contract Names.
    */
    public static Set<String> getContractNumber(String contractNumbersBundle){
        Set<String> setContractNumbers = new Set<String>();
        if(contractNumbersBundle == null){
            return setContractNumbers;
        }

        String contractNumbersBundleTrimmed = contractNumbersBundle.replaceAll(' ', '');

        if(contractNumbersBundleTrimmed.contains(',')){
            setContractNumbers.addAll(contractNumbersBundleTrimmed.split(','));
        }else if(contractNumbersBundleTrimmed.contains(';')){
            setContractNumbers.addAll(contractNumbersBundleTrimmed.split(';'));
        }else{
            setContractNumbers.add(contractNumbersBundleTrimmed);
        }

        return setContractNumbers;
    }

    /**
     * @Description SL-2090: Gets the Contract__c with the Program__c as XBS.
     * @param Set<String> set of Contract Names.
     * @return Map<String, Contract__c> Map of Contract__c with the Contract Name as Key.
    */
    public static Map<String, Contract__c> getRelatedContract(Set<String> lstContractNumber){
        Map<String, Contract__c> mapContracts = new Map<String, Contract__c>();

        if(lstContractNumber.isEmpty()){
            return mapContracts;
        }

        for(Contract__c contract :[SELECT Id, Name FROM Contract__c WHERE Name IN :lstContractNumber AND Program__c INCLUDES (:PROGRAM_XBS_TYPE)]){
            mapContracts.put(contract.Name, contract);
        }
        return mapContracts;
    }

    /**
     * @Description SL-2090: Set the Case.XBS__c as true if the Contract on Contracts__c field has that value on Program__c, otherwise it will be false.
     * @param Case Case record.
     * @param Map<String, Contract__c> Map of Contract__c with the Contract Name as Key.
     * @return void will mutate the Case record.
    */
    public static void setXBSValue(Case caseRec, Map<String, Contract__c> mapContracts) {
        if (caseRec.XBS_Contract__c || mapContracts.values().size()>0) {
            caseRec.XBS__c = true;
        } else {
            caseRec.XBS__c = false;
        }
    }
}