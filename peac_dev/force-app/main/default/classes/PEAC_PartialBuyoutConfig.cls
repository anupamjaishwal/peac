/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description: 
	configuration helper that determines whether a contract is eligible for Partial Buyout (OEG eligibility) based on:
        Contract Branch Code (Contract__c.Branch_Code__c) — if present, it takes priority
        Dealer/Account Branch Text (Account.Account_Branch__c) — used only when contract branch code is blank
	The configuration is stored in Custom Metadata (Partial_Buyout_Config__mdt), but because tests can’t insert CMDT records, the class supports test injection (so tests can provide config without CMDT DML).	
 * @User Story: SL-2953
 */
public class PEAC_PartialBuyoutConfig {

	private static Set<String> contractCodes;
    private static Set<String> accountBranches;
	
    // To fix the CMDT test class data issue --- Test injection support ----
    // DML operation Insert not allowed on Partial_Buyout_Config__mdt
    @TestVisible private static Boolean useInjected = false;
    @TestVisible private static Set<String> injectedContractCodes;
    @TestVisible private static Set<String> injectedAccountBranches;
	
	@TestVisible
    public static void setTestConfig(Set<String> contractCodesCsv, Set<String> accountBranchTexts) {
        useInjected = true;
        injectedContractCodes = (contractCodesCsv == null) ? new Set<String>() : new Set<String>(contractCodesCsv);
        injectedAccountBranches = (accountBranchTexts == null) ? new Set<String>() : new Set<String>(accountBranchTexts);
        contractCodes = null;
        accountBranches = null;
    }

    @TestVisible
    public static void clearTestConfig() {
        useInjected = false;
        injectedContractCodes = null;
        injectedAccountBranches = null;
        contractCodes = null;
        accountBranches = null;
        // also reset provider to default (safety)
        provider = new CmdtProvider();
    }
	// -------- End existing injection support --------

    // Provider to support the Coverage specific to Custom Metadata using a ConfigDTO (Data Transfer Object)
    public class ConfigDTO {
        public Boolean active;
        public String contractCodesCsv;
        public String accountBranchCsv;

        public ConfigDTO(Boolean active, String contractCodesCsv, String accountBranchCsv) {
            this.active = active;
            this.contractCodesCsv = contractCodesCsv;
            this.accountBranchCsv = accountBranchCsv;
        }
    }

    public interface IConfigProvider {
        ConfigDTO get();
    }

   
    private class CmdtProvider implements IConfigProvider {
        public ConfigDTO get() {
            Partial_Buyout_Config__mdt cfg =
                Partial_Buyout_Config__mdt.getInstance('OEG_Partial_Buyout_Config');

            if (cfg == null) return new ConfigDTO(false, null, null);

            // NOTE: Using your field names exactly as in your class:
            return new ConfigDTO(cfg.Active__c, cfg.Contract_Branch_Codes__c, cfg.Account_Branch_Text__c);
        }
    }

    @TestVisible private static IConfigProvider provider = new CmdtProvider();

    @TestVisible
    static void setProviderForTest(IConfigProvider p) {
        provider = (p == null) ? new CmdtProvider() : p;
        resetForTest();
    }

    private static void load() {
        // Cache guard
        if (contractCodes != null && accountBranches != null) return;

        contractCodes = new Set<String>();
        accountBranches = new Set<String>();

        // If test injected (existing approach), use injected sets and return
        if (useInjected) {
            contractCodes.addAll(injectedContractCodes);
            accountBranches.addAll(injectedAccountBranches);
            return;
        }

        // Fetch config using provider (for TestClass Validation purpose itslf)
        ConfigDTO dto = provider.get();
        if (dto == null || dto.active != true) return;

        // Parse Contract Branch Codes CSV
            if (!String.isBlank(dto.contractCodesCsv)) {
                for (String s : dto.contractCodesCsv.split(',')) {
                    if (!String.isBlank(s)) contractCodes.add(s.trim());
                }
            }

        // Parse Account Branch Text CSV
            if (!String.isBlank(dto.accountBranchCsv)) {
                for (String s : dto.accountBranchCsv.split(',')) {
                    if (!String.isBlank(s)) accountBranches.add(s.trim());
                }
            }
    	}

    /*** RULE:
     * 1) If Contract Branch Code exists → evaluate ONLY contract codes
     * 2) If Contract Branch Code is blank → fallback to Account branch text
     */
    public static Boolean isOEGEligible(String contractBranchCode, String accountBranchText) {
        load();

        if (!String.isBlank(contractBranchCode)) {
            return contractCodes.contains(contractBranchCode.trim());
        }

        if (!String.isBlank(accountBranchText)) {
            return accountBranches.contains(accountBranchText.trim());
        }

        return false;
    }
    
	@TestVisible
    static void resetForTest() {
        contractCodes = null;
        accountBranches = null;
    }

}