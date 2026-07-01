public class PEAC_SummaryAndDetail {

public static final String NITROAPI_BW_CREATE_BUYOUT_QUOTE = 'BW.CREATE.BUYOUT.QUOTE';
    public static final String BUYOUT_TYPE = 'BuyoutType';
    public static final String DISCOUNT_RATE = 'DiscountRate';
        
		//Helper Method to Fix the Null Restricted Picklist Values while creating Buyouts
        public static Decimal getDiscountRateForTemplate(Contract__c c, String templateId) {
        
        List<Lessor_Code_Buyout_Map__mdt> rows = [
            SELECT TemplateId__c, Discount_Type__c, Send_Discount_To_IL__c, Originating_Business__c
            FROM Lessor_Code_Buyout_Map__mdt
            WHERE TemplateId__c = :templateId
              AND Send_Discount_To_IL__c = true
              AND (
                    Originating_Business__c = :c.Originating_Business__c
                 OR Originating_Business__c = :c.Opportunity__r.Originating_Business__c
              )
        ];
		Decimal dr = 0;
        if (!rows.isEmpty()) 
        {
            Lessor_Code_Buyout_Map__mdt r = rows[0];
        if (r.Discount_Type__c == PEAC_ConstantClass.CUSTOMER_DISCOUNT) {
            dr = safeDecimal(c.Customer__r?.Discount_for_Upgrade_to_Keep__c);
        } else if (r.Discount_Type__c == PEAC_ConstantClass.DEALER_DISCOUNT) {
            dr = safeDecimal(c.Dealer_Name__r?.Discount_for_Upgrade_to_Keep__c);
        }

        }
        
        return dr.setScale(3);
    }

    // Helper Safely parse Decimal regardless of underlying type (String/Decimal/Boolean/etc.)--To Fix Deployment Boolean Data Type issues
    private static Decimal safeDecimal(Object v) {
        if (v == null) return 0;

        // If it's already numeric
        if (v instanceof Decimal) return (Decimal)v;
        if (v instanceof Integer) return Decimal.valueOf((Integer)v);
        if (v instanceof Long)    return Decimal.valueOf(String.valueOf(v));
        if (v instanceof Double)  return Decimal.valueOf(String.valueOf(v));

        // If it's boolean (checkbox), treat true as 1.000 and false as 0.000 (or return 0 always)
        if (v instanceof Boolean) return ((Boolean)v) ? 1 : 0;

        // Treat everything else as string and parse
        String s = String.valueOf(v).trim();
        if (String.isBlank(s)) return 0;

        try {
            return Decimal.valueOf(s);
        } catch (Exception e) {
            return 0;
        }
	}

}