public with sharing class SL_PaymentHistoryDPController {

    @AuraEnabled
    public static String sendPaymentsToApex(List<Map<String, Object>> payments, Boolean isIL10, Integer pageNumber) {
        Decimal limitCallouts = Decimal.valueOf(System.Limits.getLimitCallouts());
        List<Map<String, Object>> processedPayments = new List<Map<String, Object>>();
		Set<String> glDescriptionSet = getGLDescription();
        Integer startIndex = pageNumber * Integer.valueOf(limitCallouts) - Integer.valueOf(limitCallouts);
        Integer endIndex = Integer.valueOf(pageNumber * limitCallouts) - 1;
        // Collect PymtKey values
        for(Integer i = startIndex; i <= endIndex && i < payments.size(); i++) {
            Map<String, Object> payment = payments[i];
            Integer remainingCallouts = Integer.valueOf(limitCallouts) - System.Limits.getCallouts();
            if (payment.containsKey('PymtKey') && remainingCallouts > 0) {
                String pymtKey = (String) payment.get('PymtKey');
                String response;

                try {
                    // If running in test mode, use a mock response
                    if (Test.isRunningTest()) {
                        response = '{"Response": { "StateTaxes": "10", "CountyTaxes": "5", "CityTaxes": "3", "TCountyTaxes": "2", "TCityTaxes": "1", "LateChargeAmt": "1", "LcStateTaxes": "0", "LcCountyTaxes": "0", "LcCityTaxes": "0", "LcTCountyTaxes": "0", "LcTCityTaxes": "0", "MiscCharges": [ {"MiscDesc": "Misc Charge 1", "MiscRcvd": "100"}, {"MiscDesc": "Service", "MiscRcvd": "50"} ] } }';
                    } else {
                        response = SL_SummaryAndDetail.getDetailByPymtKeyDP(pymtKey, isIL10);
                    }

                    // Parse the response JSON
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response);
                    Map<String, Object> responseData1 = (Map<String, Object>) parsedResponse.get('response') ??
                        (Map<String, Object>) parsedResponse.get('Response');
                    if (responseData1 != null) {
                        
                        Map<String, Object> responseData = (Map<String, Object>) responseData1.get('Response') ?? responseData1;
                        // Safely extract and sum all tax fields using the helper method
                        Decimal stateTaxes = getDecimalValue(responseData.get('StateTaxes'));
                        Decimal countyTaxes = getDecimalValue(responseData.get('CountyTaxes'));
                        Decimal cityTaxes = getDecimalValue(responseData.get('CityTaxes'));
                        Decimal tCountyTaxes = getDecimalValue(responseData.get('TCountyTaxes'));
                        Decimal tCityTaxes = getDecimalValue(responseData.get('TCityTaxes'));
                        Decimal lcStateTaxes = getDecimalValue(responseData.get('LcStateTaxes'));
                        Decimal lcCountyTaxes = getDecimalValue(responseData.get('LcCountyTaxes'));
                        Decimal lcCityTaxes = getDecimalValue(responseData.get('LcCityTaxes'));
                        Decimal lcTCountyTaxes = getDecimalValue(responseData.get('LcTCountyTaxes'));
                        Decimal lcTCityTaxes = getDecimalValue(responseData.get('LcTCityTaxes'));

                        // Sum all the tax-related fields
                        Decimal totalTaxes = stateTaxes + countyTaxes + cityTaxes + tCountyTaxes + tCityTaxes +
                                             lcStateTaxes + lcCountyTaxes + lcCityTaxes + lcTCountyTaxes + lcTCityTaxes;

                        // Extract Late Charge Amount separately
                        Decimal lateChargeAmt = getDecimalValue(responseData.get('LateChargeAmt'));

                        // Calculate Misc Fees and Pass-Through
                        Decimal miscFees = 0;
                        Decimal passThrough = 0;
						System.debug(logginglevel.error,'MiscCharges... ' + responseData);
                        if (responseData.containsKey('MiscCharges')) {
                            List<Object> miscCharges = (List<Object>) responseData.get('MiscCharges');

                            for (Object miscChargeObj : miscCharges) {
                                Map<String, Object> miscCharge = (Map<String, Object>) miscChargeObj;

                                String miscDesc = (String) miscCharge.get('MiscDesc');
                                Decimal miscAmount = getDecimalValue(miscCharge.get('MiscRcvd'));

                                if (miscDesc != null && glDescriptionSet!=Null && glDescriptionSet.contains(miscDesc)) {
                                    passThrough += miscAmount;
                                } else {
                                    system.debug('miscDesc outside passthrough: ' + miscDesc);
                                    miscFees += miscAmount;
                                }
                            }
                        }

                        // Add calculated values to the payment map
                        Map<String, Object> processedPayment = new Map<String, Object>();
                        processedPayment.put('PymtKey', pymtKey);
                        processedPayment.put('Taxes', totalTaxes);
                        processedPayment.put('LateChargeAmt', lateChargeAmt);  // Send LateChargeAmt separately
                        processedPayment.put('MiscFees', miscFees);
                        processedPayment.put('PassThrough', passThrough);

                        processedPayments.add(processedPayment);
                        System.debug('processedPayment: ' + JSON.serialize(processedPayment));
                    }
                        
                } catch (Exception e) {
                    System.debug('Error calling getDetailByPymtKey for PymtKey ' + pymtKey + ': ' + e.getMessage());
                }
            }
        }
        
        Integer maxPages = Integer.valueOf((Decimal.valueOf(payments.size()) / limitCallouts).round(System.RoundingMode.CEILING));
        Integer nextPage = payments.size() > limitCallouts && pageNumber < maxPages? ++pageNumber: pageNumber;
        // Return the list of processed payments as a JSON string
        return '{"processedPayments": ' + JSON.serialize(processedPayments) + ', "nextPage": ' + JSON.serialize(nextPage) 
            + ', "startIndex": ' + JSON.serialize(startIndex) + ', "endIndex": ' + JSON.serialize(endIndex) + '}';
    }

    // Helper method to safely convert string to Decimal
    public static Decimal getDecimalValue(Object value) {
        if (value != null && value != '') {
            try {
                return Decimal.valueOf((String)value);
            } catch (Exception e) {
                System.debug('Error converting value to Decimal: ' + value);
            }
        }
        return 0;
    }
    /**************************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
	@Description:Get GL Descriptions
	@Param:None
	@Return:List of GL Descriptions
    **************************************************************************************************************************/
    public static Set<String> getGLDescription()
    {
        Set<String> glDescriptionSet = new Set<String>();
        List<GL_Code_Description__mdt> glDescriptionList = new List<GL_Code_Description__mdt>();
        glDescriptionList = [SELECT Label FROM GL_Code_Description__mdt];
        for(GL_Code_Description__mdt glcode: glDescriptionList)
        {
            glDescriptionSet.add(glcode.Label);
        }
        return glDescriptionSet;
    }
}