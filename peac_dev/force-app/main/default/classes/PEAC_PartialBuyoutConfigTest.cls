/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description: Provides the Test Coverage for the Helper Class : PEAC_PartialBuyoutConfig.
 * @User Story: SL-2953
 */
@IsTest
public class PEAC_PartialBuyoutConfigTest {   	
	
    @IsTest
    static void testCSVConfig_withoutCmdtInsert() {
        PEAC_PartialBuyoutConfig.setTestConfig(
            new Set<String>{ '00004', '00040', '00044' },
            new Set<String>{ 'Office Equip Group-OEG' }
        );

        System.assertEquals(true,
            PEAC_PartialBuyoutConfig.isOEGEligible('00040', 'Other')
        );

        System.assertEquals(false,
            PEAC_PartialBuyoutConfig.isOEGEligible('99999', 'Office Equip Group-OEG')
        );

        System.assertEquals(true,
            PEAC_PartialBuyoutConfig.isOEGEligible(null, 'Office Equip Group-OEG')
        );

        // extra assertions to cover blank inputs
        System.assertEquals(false,
            PEAC_PartialBuyoutConfig.isOEGEligible(null, null)
        );
        System.assertEquals(false,
            PEAC_PartialBuyoutConfig.isOEGEligible('', '')
        );

        PEAC_PartialBuyoutConfig.clearTestConfig();
    }

    // Fake provider for provider seam coverage (covers parsing lines)
    private class FakeProvider implements PEAC_PartialBuyoutConfig.IConfigProvider {
        private PEAC_PartialBuyoutConfig.ConfigDTO dto;
        FakeProvider(PEAC_PartialBuyoutConfig.ConfigDTO dto) { this.dto = dto; }
        public PEAC_PartialBuyoutConfig.ConfigDTO get() { return dto; }
    }

    @IsTest
    static void testProviderParsingAndRules() {
        // Covers: dto.active true, split/trim, ignores blanks
        PEAC_PartialBuyoutConfig.setProviderForTest(
            new FakeProvider(
                new PEAC_PartialBuyoutConfig.ConfigDTO(
                    true,
                    ' 00004,00040 , ,00044  ',                   // spaces + empty token
                    ' Office Equip Group-OEG , Another Branch ,'  // trailing comma
                )
            )
        );

        // Contract present -> contract-only check
        System.assertEquals(true,  PEAC_PartialBuyoutConfig.isOEGEligible('00044', 'NoMatter'));
        System.assertEquals(false, PEAC_PartialBuyoutConfig.isOEGEligible('99999', 'Office Equip Group-OEG')); // no fallback

        // Contract blank -> fallback to account
        System.assertEquals(true,  PEAC_PartialBuyoutConfig.isOEGEligible(null, 'Office Equip Group-OEG'));
        System.assertEquals(true,  PEAC_PartialBuyoutConfig.isOEGEligible('', 'Another Branch'));

        // Not in list
        System.assertEquals(false, PEAC_PartialBuyoutConfig.isOEGEligible(null, 'Unknown'));

        // reset cache path
        PEAC_PartialBuyoutConfig.resetForTest();
        System.assertEquals(true, PEAC_PartialBuyoutConfig.isOEGEligible('00004', null));
    }

    @IsTest
    static void testInactiveOrNullConfig() {
        // Inactive config -> always false
        PEAC_PartialBuyoutConfig.setProviderForTest(
            new FakeProvider(
                new PEAC_PartialBuyoutConfig.ConfigDTO(false, '00004', 'Office Equip Group-OEG')
            )
        );
        System.assertEquals(false, PEAC_PartialBuyoutConfig.isOEGEligible('00004', null));
        System.assertEquals(false, PEAC_PartialBuyoutConfig.isOEGEligible(null, 'Office Equip Group-OEG'));
    }       
    
}