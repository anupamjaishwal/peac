trigger xct_t_PriorPayee on Payee__c (before insert, before update) {

    if (trigger.isInsert) {
        for (Payee__c payee: Trigger.new) {
           
            if (payee.isClone()) {
               payee.SL_Vendor_ID__c = '';
            }
           
           payee.Is_New__c = true;
           if (String.isBlank(payee.Payee_ID__c) && String.isBlank(payee.Dealer__c) == false) {
               Account thisAccount = [SELECT Id, Name, Dealer_Number__c, Business_Address__c, Business_City__c,Business_State__c, Business_Zip__c,Business_Phone__c, Fax, Contact_Email__c FROM Account WHERE Id = :payee.Dealer__c];
               if (!String.isBlank(thisAccount.Dealer_Number__c)) { payee.Payee_ID__c = thisAccount.Dealer_Number__c.replace('.', ''); }
               if (!String.isBlank(thisAccount.Name)) { payee.Payee_Name__c = thisAccount.Name.left(60); }
               if (!String.isBlank(thisAccount.Business_Address__c)) { payee.Address1__c = thisAccount.Business_Address__c.left(60); }
               if (!String.isBlank(thisAccount.Business_Address__c)) { payee.Address2__c = thisAccount.Business_Address__c.mid(60,60); }
               if (!String.isBlank(thisAccount.Business_City__c)) { payee.City__c = thisAccount.Business_City__c.left(30); }
               if (!String.isBlank(thisAccount.Business_State__c)) { payee.State__c = thisAccount.Business_State__c; }
               if (!String.isBlank(thisAccount.Business_Zip__c)) { payee.Zip__c = thisAccount.Business_Zip__c.left(10); }
               if (!String.isBlank(thisAccount.Business_Phone__c)) { payee.Phone__c = thisAccount.Business_Phone__c; }
               if (!String.isBlank(thisAccount.Fax)) { payee.Fax__c = thisAccount.Fax; }
               if (!String.isBlank(thisAccount.Contact_Email__c)) { payee.Email__c =  thisAccount.Contact_Email__c; }
           }
           if (!String.isBlank(payee.Contact__c)) {
               Contact thisContact  = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Id = :payee.Contact__c];
               if (String.isBlank(payee.Email__c ) && !String.isBlank(thisContact.Email)) { payee.Email__c =  thisContact.Email; }

               if (!String.isBlank(thisContact.AccountId)) {
               
                   Account thisAccount = [SELECT Id, Name, Dealer_Number__c, Business_Address__c, Business_City__c,Business_State__c, Business_Zip__c,Business_Phone__c, Fax FROM Account WHERE Id = :thisContact.AccountId];
               
                   if (String.isBlank(payee.Payee_Name__c ) && !String.isBlank(thisAccount.Name )) { payee.Payee_Name__c =  thisAccount.Name.left(60); }
                   if (String.isBlank(payee.Address1__c ) && !String.isBlank(thisAccount.Business_Address__c )) { payee.Address1__c =  thisAccount.Business_Address__c.left(60); }
                   if (String.isBlank(payee.Address2__c ) && !String.isBlank(thisAccount.Business_Address__c )) { payee.Address2__c =  thisAccount.Business_Address__c.mid(60,60); }
                   if (String.isBlank(payee.City__c ) && !String.isBlank(thisAccount.Business_City__c )) { payee.City__c =  thisAccount.Business_City__c.left(30); }
                   if (String.isBlank(payee.State__c ) && !String.isBlank(thisAccount.Business_State__c )) { payee.State__c =  thisAccount.Business_State__c; }
                   if (String.isBlank(payee.Zip__c ) && !String.isBlank(thisAccount.Business_Zip__c )) { payee.Zip__c =  thisAccount.Business_Zip__c.left(10); }
                   if (String.isBlank(payee.Phone__c ) && !String.isBlank(thisAccount.Business_Phone__c )) { payee.Phone__c =  thisAccount.Business_Phone__c; }
                   if (String.isBlank(payee.Fax__c ) && !String.isBlank(thisAccount.Fax )) { payee.Fax__c =  thisAccount.Fax; }
               }
           }
           if ( payee.ACH_Available__c == true) {
               payee.Default_Pay_Type__c = 'ACH';
           }
           else if ( payee.Wire_Available__c == true) {
               payee.Default_Pay_Type__c = 'Wire';
           }
        }
    }
    else {

        for (Payee__c payee: Trigger.new) {
        
          
           if (String.isBlank(payee.Payee_ID__c) && String.isBlank(payee.Dealer__c) == false) {
               Account thisAccount = [SELECT Id, Name, Dealer_Number__c, Business_Address__c, Business_City__c,Business_State__c, Business_Zip__c,Business_Phone__c, Fax, Contact_Email__c  FROM Account WHERE Id = :payee.Dealer__c];
               if (!String.isBlank(thisAccount.Dealer_Number__c)) { payee.Payee_ID__c = thisAccount.Dealer_Number__c.replace('.', ''); }
               if (!String.isBlank(thisAccount.Name)) { payee.Payee_Name__c = thisAccount.Name.left(60); }
               if (!String.isBlank(thisAccount.Business_Address__c)) { payee.Address1__c = thisAccount.Business_Address__c.left(60); }
               if (!String.isBlank(thisAccount.Business_Address__c)) { payee.Address2__c = thisAccount.Business_Address__c.mid(60,60); }
               if (!String.isBlank(thisAccount.Business_City__c)) { payee.City__c = thisAccount.Business_City__c.left(30); }
               if (!String.isBlank(thisAccount.Business_State__c)) { payee.State__c = thisAccount.Business_State__c; }
               if (!String.isBlank(thisAccount.Business_Zip__c)) { payee.Zip__c = thisAccount.Business_Zip__c.left(10); }
               if (!String.isBlank(thisAccount.Business_Phone__c)) { payee.Phone__c = thisAccount.Business_Phone__c; }
               if (!String.isBlank(thisAccount.Fax)) { payee.Fax__c = thisAccount.Fax; }
               if (!String.isBlank(thisAccount.Contact_Email__c)) { payee.Email__c =  thisAccount.Contact_Email__c; }
           }
           if (!String.isBlank(payee.Contact__c)) {
               Contact thisContact  = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Id = :payee.Contact__c];
               if (String.isBlank(payee.Email__c ) && !String.isBlank(thisContact.Email)) { payee.Email__c =  thisContact.Email; }

               if (!String.isBlank(thisContact.AccountId)) {
               
                   Account thisAccount = [SELECT Id, Name, Dealer_Number__c, Business_Address__c, Business_City__c,Business_State__c, Business_Zip__c,Business_Phone__c,Fax  FROM Account WHERE Id = :thisContact.AccountId];
               
                   if (String.isBlank(payee.Payee_Name__c ) && !String.isBlank(thisAccount.Name )) { payee.Payee_Name__c =  thisAccount.Name.left(60); }
                   if (String.isBlank(payee.Address1__c ) && !String.isBlank(thisAccount.Business_Address__c )) { payee.Address1__c =  thisAccount.Business_Address__c.left(60); }
                   if (String.isBlank(payee.Address2__c ) && !String.isBlank(thisAccount.Business_Address__c )) { payee.Address2__c =  thisAccount.Business_Address__c.mid(60,60); }
                   if (String.isBlank(payee.City__c ) && !String.isBlank(thisAccount.Business_City__c )) { payee.City__c =  thisAccount.Business_City__c.left(30); }
                   if (String.isBlank(payee.State__c ) && !String.isBlank(thisAccount.Business_State__c )) { payee.State__c =  thisAccount.Business_State__c; }
                   if (String.isBlank(payee.Zip__c ) && !String.isBlank(thisAccount.Business_Zip__c )) { payee.Zip__c =  thisAccount.Business_Zip__c.left(10); }
                   if (String.isBlank(payee.Phone__c ) && !String.isBlank(thisAccount.Business_Phone__c )) { payee.Phone__c =  thisAccount.Business_Phone__c; }
                   if (String.isBlank(payee.Fax__c ) && !String.isBlank(thisAccount.Fax )) { payee.Fax__c =  thisAccount.Fax; }
               }
           }
        }
         
    }
    for (Payee__c payee: Trigger.new) {
        if (String.isBlank(payee.Payee_Name__c )) {
               payee.adderror('Payee requires Payee Name.');
        }
        if (String.isBlank(payee.Remittance_Name__c )) { payee.Remittance_Name__c =  payee.Payee_Name__c; }
        if (String.isBlank(payee.Remittance_Address1__c )) { payee.Remittance_Address1__c =  payee.Address1__c; }
        if (String.isBlank(payee.Remittance_Address2__c )) { payee.Remittance_Address2__c =  payee.Address2__c; }
        if (String.isBlank(payee.Remittance_City__c )) { payee.Remittance_City__c =  payee.City__c; }
        if (String.isBlank(payee.Remittance_State__c )) { payee.Remittance_State__c =  payee.State__c; }
        if (String.isBlank(payee.Remittance_Zip__c )) { payee.Remittance_Zip__c =  payee.Zip__c; }
        if (String.isBlank(payee.Remittance_Country__c )) { payee.Remittance_Country__c =  payee.Country__c; }
        if (String.isBlank(payee.Remittance_Phone__c )) { payee.Remittance_Phone__c =  payee.Phone__c; }
        if (String.isBlank(payee.Remittance_Fax__c )) { payee.Remittance_Fax__c =  payee.Fax__c; }
        
        if (!String.isBlank(payee.Tax_ID_type__c)) {
            if ( payee.Tax_ID_type__c == 'EIN') {
                String tempTIN;
                tempTIN = payee.Tax_ID_Nbr__c.replace('-', '');
                payee.Tax_ID_Nbr__c = tempTIN.left(2) + '-' + tempTIN.mid(2, 7);
            }
            if ( payee.Tax_ID_type__c == 'SSN') {
                String tempTIN;
                tempTIN = payee.Tax_ID_Nbr__c.replace('-', '');
                payee.Tax_ID_Nbr__c = tempTIN.left(3) + '-' + tempTIN.mid(3, 2) + '-' + tempTIN.mid(5, 4);
            }
        
        }
        
        if ( payee.Wire_Available__c == true && (String.isBlank(payee.Qualifier__c) || (payee.Qualifier__c != 'SWIFT' && payee.Qualifier__c != 'FedWire' )) ) {
            payee.Qualifier__c = 'FedWire';
        }
        if ( payee.ACH_Available__c == true && (String.isBlank(payee.ACH_Account_Type__c) || (payee.ACH_Account_Type__c != 'Savings' && payee.ACH_Account_Type__c != 'Checking' && payee.ACH_Account_Type__c != 'Financial Institution GL' && payee.ACH_Account_Type__c != 'Loan Account')) ) {
            payee.ACH_Account_Type__c = 'Checking';
        }
       
        if ( payee.update__c == false ) {
            payee.Update_Sequence__c = 0;
            payee.Sent_to_Solomon__c = System.now(); 
        }
        else {
            if ( payee.Update_Sequence__c == 0) {
                payee.Update_Sequence__c = 1;
            }
            else {
               payee.Update_Sequence__c = 2;
               if ( !String.isBlank(payee.SL_Vendor_ID__c) && ( payee.ACH_Available__c == true || payee.Wire_Available__c == true)) {
                   payee.Is_New__c = false;
               }
            }
            payee.update__c= false;
        }
         
   }


}