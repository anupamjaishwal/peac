public class CreditRiskDisplayController {
    public String ApprovalType { get; set; }
    public Id recordId { get; set; }

    public CreditRiskDisplayController() {
       
        if (ApexPages.currentPage().getParameters().containsKey('id')) {
            setRecordId(ApexPages.currentPage().getParameters().get('id'));
        }
    }

    public void setRecordId(Id recordId) {
        if (recordId == null) return;
        Opportunity opp = [
            SELECT Credit_Risk_Grade__c
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];
        ApprovalType = getTier(opp.Credit_Risk_Grade__c);
    }

      private String getTier(String grade) {
        if (String.isBlank(grade)) {
            return 'Unknown';
        }

        String normalized = grade.trim().toUpperCase();

        if (normalized.contains('A')) {
            return 'Tier 1';
        } else if (normalized.contains('B')) {
            return 'Tier 2';
        } else if (normalized.contains('C')) {
            return 'Tier 3';
        } else if (normalized.contains('D')) {
            return 'Tier 4';
        } else if (normalized.contains('E')) {
            return 'Tier 5';
        } else {
            return 'Unknown';
        }
    }
}