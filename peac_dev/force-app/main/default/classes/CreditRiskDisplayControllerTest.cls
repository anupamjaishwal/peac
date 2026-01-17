@isTest
public class CreditRiskDisplayControllerTest {
    
    @testSetup
    static void setupData() {
        List<Opportunity> opps = new List<Opportunity>();
        for (String grade : new List<String>{'A', 'B', 'C', 'D', 'E1', null}) {
            opps.add(new Opportunity(
                Name = 'Test Opp ' + grade,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Credit_Risk_Grade__c = grade
            ));
        }
        insert opps;
    }

    @isTest
    static void testApprovalTypeByGrade() {
        List<Opportunity> opps = [SELECT Id, Credit_Risk_Grade__c FROM Opportunity];

        Test.startTest();
        for (Opportunity opp : opps) {
            // Simular el parámetro de página "id"
            PageReference pageRef = Page.CreditRiskDisplayPage; 
            pageRef.getParameters().put('id', opp.Id);
            Test.setCurrentPage(pageRef);

            // Instanciar el controlador
            CreditRiskDisplayController controller = new CreditRiskDisplayController();

            // Calcular el tier esperado
            String expectedTier;
            switch on (opp.Credit_Risk_Grade__c) {
                when 'A' { expectedTier = 'Tier 1'; }
                when 'B' { expectedTier = 'Tier 2'; }
                when 'C' { expectedTier = 'Tier 3'; }
                when 'D' { expectedTier = 'Tier 4'; }
                when 'E1' { expectedTier = 'Tier 5'; }
                when null { expectedTier = 'Unknown'; }
                when else { expectedTier = 'Unknown'; }
            }

            System.assertEquals(expectedTier, controller.ApprovalType,
                'ApprovalType incorrecto para grade ' + opp.Credit_Risk_Grade__c);
        }
        Test.stopTest();
    }
}