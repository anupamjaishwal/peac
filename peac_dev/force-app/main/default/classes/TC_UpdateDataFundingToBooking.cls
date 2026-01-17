public class TC_UpdateDataFundingToBooking {
    public static void updateDataFundingToBooking(Opportunity opp, Set<Id> oppsMovedToBooking, Map <Id, Dealer__c> dealers,
    Map<Id, List<Miscellaneous_Invoice_Item__c>> miscInvoiceItems, List<Miscellaneous_Invoice_Item__c> upsertMiscInvoiceList, Set<Id> oppsChangedInterimRent) {
        Boolean interimCalculated = (opp.Interim_Rent__c > 0 || opp.Interim_Rent_To_Lessor__c > 0 || opp.Maintenance_Interim_Rent__c > 0);
        if(( (oppsMovedToBooking.contains(opp.Id) && interimCalculated) || oppsChangedInterimRent.contains(opp.Id)) && !TC_RecursiveTriggerHelper.oppsAlreadyMiiAdded.contains(opp.Id)){
            TC_RecursiveTriggerHelper.oppsAlreadyMiiAdded.add(opp.Id);
            // Map<String, List<Miscellaneous_Invoice_Item__c>> miisByGLCode = new Map<String, List<Miscellaneous_Invoice_Item__c>>();
            Account dealerAccount = null;
            dealerAccount = dealers.get(opp.Primary_Dealer__c)?.Dealer__r;
            Boolean isNewInterimUsed = false;
            Decimal percentageToDealer = dealerAccount?.Interim_Rent_Dealer_Percentage__c != null?
                            dealerAccount.Interim_Rent_Dealer_Percentage__c: 0;
            for (String x : new List<String>{
                'Delivery_Guarantee_Fee__c', 'Wire_Fee__c', 'UPS_Fee__c', 'Documentation_Fee__c',
                'Lease_Payment_Interim_Rent__c', 'Maintenance_Interim_Rent__c'}) {
                if (x != null && opp.get(x) != null && opp.get(x) != 0) {
                    Miscellaneous_Invoice_Item__c mii = new Miscellaneous_Invoice_Item__c (Opportunity__c = opp.Id);
                    mii.Amount__c = (Decimal) opp.get(x);
                    switch on x {
                        when 'Delivery_Guarantee_Fee__c' {
                            mii.GL_Code__c = '0040 - Progress Payment Fees';
                        }
                        when 'Wire_Fee__c', 'UPS_Fee__c' {
                            mii.GL_Code__c = '0042 - UPS SHIPPING FEE';
                        }
                        when 'Documentation_Fee__c' {
                            mii.GL_Code__c = '0003 - OneTime Documentation Fee';
                            mii.Pay_Code__c = '0';
                        }
                        when 'Lease_Payment_Interim_Rent__c' {
                            if(percentageToDealer > 0){
                                mii.GL_Code__c = '0001 - Interim Rent';
                                mii.Description__c = 'Lease Interim Rent';
                                mii.Interim_Percentage__c = percentageToDealer;
                                mii.Amount__c = opp.Lease_Payment_Interim_Rent__c * (mii.Interim_Percentage__c/100);
                                mii.Pay_Code__c = '1';
                            }
                            isNewInterimUsed = true;
                        }
                        when 'Maintenance_Interim_Rent__c' {
                            mii.GL_Code__c = '0017 - Service Contract';
                            mii.Description__c = 'Maintenance Interim Rent';
                            mii.Interim_Percentage__c = 100;
                            mii.Pay_Code__c = '1';
                            isNewInterimUsed = true;
                        }
                    }
                    if (mii.GL_Code__c != null){
                        mii.Generated_Code__c = mii.GL_Code__c.left(4)+ x + mii.Pay_Code__c;
                        upsertMiscInvoiceList.add(mii);
                    }
                }
            }
            if(isNewInterimUsed && opp.Lease_Payment_Interim_Rent__c != null && opp.Lease_Payment_Interim_Rent__c != 0){
                Decimal percentageToLessor = 100 - percentageToDealer;
                if(percentageToLessor > 0){
                    Miscellaneous_Invoice_Item__c miiInterimRentToLessor = new Miscellaneous_Invoice_Item__c (Opportunity__c = opp.Id);
                    miiInterimRentToLessor.GL_Code__c = '0001 - Interim Rent';
                    miiInterimRentToLessor.Description__c = 'Lease Interim Rent';
                    miiInterimRentToLessor.Interim_Percentage__c = percentageToLessor;
                    miiInterimRentToLessor.Amount__c = opp.Lease_Payment_Interim_Rent__c * (miiInterimRentToLessor.Interim_Percentage__c/100);
                    miiInterimRentToLessor.Pay_Code__c = '0';
                    miiInterimRentToLessor.Generated_Code__c = miiInterimRentToLessor.GL_Code__c.left(4)+ 'Lease_Payment_Interim_Rent__c' + miiInterimRentToLessor.Pay_Code__c;
                    upsertMiscInvoiceList.add(miiInterimRentToLessor);
                }
                addExtraMiis(opp, upsertMiscInvoiceList);// SAL-5466 Misael Romero
            }
            // the below replaces the action "Create Interim Rent" in PB: !TC Opportunity Actions
            if(!isNewInterimUsed && opp.Interim_Rent__c != null && opp.Interim_Rent__c != 0){
                Miscellaneous_Invoice_Item__c miiInterimRent = new Miscellaneous_Invoice_Item__c (Opportunity__c = opp.Id);
                miiInterimRent.Description__c = 'Interim Rent';
                miiInterimRent.GL_Code__c = '0001 - Interim Rent';
                miiInterimRent.Pay_Code__c = '0';
                miiInterimRent.Generated_Code__c = miiInterimRent.GL_Code__c.left(4)+ 'Interim_Rent__c' + miiInterimRent.Pay_Code__c;
                upsertMiscInvoiceList.add(miiInterimRent);
                addExtraMiis(opp, upsertMiscInvoiceList);// SAL-5466 Misael Romero
            }

            List<Miscellaneous_Invoice_Item__c> existingMiisList = miscInvoiceItems.get(opp.Id);
            if(existingMiisList != null && existingMiisList.size() > 0){
                List<Miscellaneous_Invoice_Item__c> miisToDelete = new List<Miscellaneous_Invoice_Item__c>();
                for(Miscellaneous_Invoice_Item__c existingMii :existingMiisList){
                    Boolean willDeleteMii = true;
                    for(Miscellaneous_Invoice_Item__c miiToUpsert : upsertMiscInvoiceList){
                        String sourceFieldName = miiToUpsert.Generated_Code__c.substring(4).substringBefore('__c') + '__c';
                        if((existingMii.Generated_Code__c != null && existingMii.Generated_Code__c == miiToUpsert.Generated_Code__c)
                            || (existingMii.GL_Code__c == miiToUpsert.GL_Code__c && existingMii.Amount__c == (Decimal)opp.get(sourceFieldName))){
                                miiToUpsert.Id = existingMii.Id;
                                willDeleteMii = false;
                                break;
                            }
                    }
                    if(willDeleteMii && existingMii.Generated_Code__c != null){
                        miisToDelete.add(existingMii);
                    }
                }
                if(miisToDelete.size() > 0){
                    delete miisToDelete;
                }
            }
        }   
    }

    public static void addExtraMiis(Opportunity opp, List<Miscellaneous_Invoice_Item__c> upsertMiscInvoiceList){// SAL-5466 Misael Romero
        if(opp.Program__c != null && (opp.Program__c.contains('XBS') || opp.Program__c.contains('XFS')) 
        && !opp.Waive_Interim_Rent__c){
            Miscellaneous_Invoice_Item__c miiInterimRentDealer = new Miscellaneous_Invoice_Item__c (Opportunity__c = opp.Id);
            miiInterimRentDealer.GL_Code__c = '0081 - Interim Rent Dealer';
            // miiInterimRentDealer.Description__c = 'Lease Interim Rent';
            miiInterimRentDealer.Amount__c = 0;
            miiInterimRentDealer.Pay_Code__c = '1';
            miiInterimRentDealer.Generated_Code__c = miiInterimRentDealer.GL_Code__c.left(4)+ 'Interim_Rent__c' + miiInterimRentDealer.Pay_Code__c;
            upsertMiscInvoiceList.add(miiInterimRentDealer);
            Miscellaneous_Invoice_Item__c miiInterimMaintenance = new Miscellaneous_Invoice_Item__c (Opportunity__c = opp.Id);
            miiInterimMaintenance.GL_Code__c = '0115 - Interim Maintenance';
            // miiInterimMaintenance.Description__c = 'Lease Maintenance Rent';
            miiInterimMaintenance.Amount__c = 0;
            miiInterimMaintenance.Pay_Code__c = '1';
            miiInterimMaintenance.Generated_Code__c = miiInterimMaintenance.GL_Code__c.left(4)+ 'Interim_Rent__c' + miiInterimMaintenance.Pay_Code__c;
            upsertMiscInvoiceList.add(miiInterimMaintenance);
        }
    }
}