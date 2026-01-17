public with sharing class SL_ReprintAction {
    @AuraEnabled
    public static string updateReprintFields(String recordId, Boolean userConfirmed){
        try {
            String result = '';
            Boolean okToUpdate = true;
            List<Contract__c> toUpdate = new List<Contract__c>();
            Contract__c currentContract = [SELECT Id, Reprint_Invoice__c, Customer__c, Invoice_Code__c,
            Total_Amount_Due__c, Lead_Invoice_Days__c, Delinquency_Status_Code__c FROM Contract__c WHERE Id = :recordId];
            if(currentContract.Invoice_Code__c == 'S' || currentContract.Invoice_Code__c == 'N'){
                result = 'Not Eligible for Reprint - Not Invoicing';
                okToUpdate = false;
            }
            if(okToUpdate && (currentContract.Total_Amount_Due__c == 0 || currentContract.Total_Amount_Due__c == null)){
                result = 'Not Eligible for Reprint - Zero Due';
                okToUpdate = false;
            }
            if(okToUpdate && (currentContract.Lead_Invoice_Days__c == 8 || currentContract.Lead_Invoice_Days__c == 3)){
                result = 'Not Eligible for Reprint - IL ACH or CC';
                okToUpdate = false;
            }
            if(okToUpdate && currentContract.Delinquency_Status_Code__c != '00' && currentContract.Delinquency_Status_Code__c != null
                && !userConfirmed){
                result = 'Confirm reprint on a delinquent contract';
                okToUpdate = false;
            }
            if(okToUpdate || userConfirmed){
                currentContract.Reprint_Invoice__c = true;
                Date todayDate = Date.today();
                if(Test.isRunningTest()){
                    todayDate = SL_SCTestData.testNow.date();
                }
                Date nextScheduledReprint = calculateNextInvoiceReprintDate(todayDate);
                if(nextScheduledReprint == todayDate){
                    nextScheduledReprint = calculateNextInvoiceReprintDate(nextScheduledReprint.addDays(1));
                }
                currentContract.Invoice_Reprint_Date__c = nextScheduledReprint;
                toUpdate.Add(currentContract);
                if(currentContract.Invoice_Code__c == 'A'){
                    List<Contract__c> sibblings = [SELECT Id, Reprint_Invoice__c, Customer__c, Invoice_Code__c FROM Contract__c 
                                                    WHERE Customer__c = :currentContract.Customer__c AND Invoice_Code__c = 'A' AND Id != :recordId];
                    for(Contract__c sibbling : sibblings){
                        sibbling.Reprint_Invoice__c = true;
                        sibbling.Invoice_Reprint_Date__c = nextScheduledReprint;
                        toUpdate.add(sibbling);
                    }
                }
                update toUpdate;
                result = 'success';
            }
                
            return result;
        } catch (Exception e) {
            System.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Date calculateNextInvoiceReprintDate(Date startingDate){
        Date nextScheduledReprint = startingDate.addDays(22);
        List<Integer> scheduledReprintDays = new List<Integer>{1, 5, 10, 15, 20, 25};
        if(nextScheduledReprint.day() > 25){
            nextScheduledReprint = Date.newInstance(nextScheduledReprint.year(), nextScheduledReprint.month() + 1, 1);
        }else{
            for(Integer dayOfMonth : scheduledReprintDays){
                Date reprintDate = Date.newInstance(nextScheduledReprint.year(), nextScheduledReprint.month(), dayOfMonth);
                Integer numberOfDays = nextScheduledReprint.daysBetween(reprintDate);
                if(numberOfDays > 0 && numberOfDays < 5){
                    nextScheduledReprint = reprintDate;
                    break;
                }
            }
        }
        nextScheduledReprint = nextScheduledReprint.addDays(-22);
        SL_MessageCodeHelper msgCodeHelper = new SL_MessageCodeHelper();
        nextScheduledReprint = msgCodeHelper.getNextWorkingDay(Datetime.newInstance(nextScheduledReprint.year(),
            nextScheduledReprint.month(), nextScheduledReprint.day(), 11, 59, 59)).date();
        return nextScheduledReprint;
    }
}