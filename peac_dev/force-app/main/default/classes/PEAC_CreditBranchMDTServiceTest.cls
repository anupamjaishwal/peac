@IsTest
public class PEAC_CreditBranchMDTServiceTest {
    @IsTest
    static void test_noRowsGracefully() {
        Test.startTest();
        List<PEAC_CreditBranchMDTService.MatrixDTO> result = PEAC_CreditBranchMDTService.getAllBranchMatrix();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Method should return a non-null list even when empty');
        // With setup data present, size > 0. If you remove @testSetup for this test, it would be 0 and still OK.
    }
}