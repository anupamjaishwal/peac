public with sharing class Solomon {

    // Transaction
    public class AptranSF {   
        public String TranDesc{ get; set; }
        public String ExtRefNbr{ get; set; }                                               
        public decimal Qty{ get; set; }
        public String UnitDesc{ get; set; }
        public decimal CuryUnitPrice{ get; set; }
        public decimal CuryTranAmt{ get; set; }
        public decimal UnitPrice{ get; set; }
        public decimal TranAmt { get; set; }
        public String CpnyID{ get; set; }
        public String Sub{ get; set; }
        public String Acct{ get; set; }
        // public String TaxCalced{ get; set; }
        public String BoxNbr { get; set; }
        public string Crtd_Prog{ get; set; }
        public string LUpd_Prog{ get; set; }
        public String PC_Flag { get; set; }
        public String VendId{ get; set; }

    }
    // Document
    public class ApdocSF {
        public String CpnyID{ get; set; }
        public String CashAcct{ get; set;}
        public String DocType{ get; set; }
        public String VendId{ get; set; }
        public String User1{ get; set; }
        public String User2{ get; set; }
        public String User5{ get; set; }
        public string User6 { get; set; }
        public String S4Future01{ get; set; }
        public String PmtMethod { get; set; }
        public String Sub{ get; set; }
        public String notes{ get; set; }
        public string Crtd_Prog{ get; set; }
        public string InvcNbr{ get; set; }
        public string LUpd_Prog{ get; set; }
        public decimal CuryDocBal{ get; set; }
        public decimal DocBal{ get; set; }
        public decimal CuryOrigDocAmt{ get; set; }
        public decimal OrigDocAmt{ get; set; }
        public string Econfirm{ get; set; }
        public string Estatus{ get; set; }
    }
    // Batch
    public class BatchSF {
        public String CpnyID{ get; set; }
        public string Crtd_Prog{ get; set; }
        public string LUpd_Prog{ get; set; }
        public string User5 { get; set; }
        public string User6 { get; set; }
 //       public string BatNbr { get; set; }
 //       public decimal CtrlTot { get; set; }
 //       public decimal CuryCtrlTot { get; set; }
 //       public decimal CuryCrTot { get; set; }
 //       public decimal CrTot { get; set; }
 //       public decimal CuryDrTot { get; set; }
 //       public decimal DrTot { get; set; }
    }
    // Voucher for sending to Solomon
    public class VoucherSF {
        public BatchSF myBatch { get; set; }
        public ApdocSF myAPDoc{ get; set; }
        public List<AptranSF> myAPTran{ get; set; }
        public String batchNote { get; set; }
    }
    
     public static void SendPayments(Payment__c[] paymentList){
                
        // System.debug('!!!!!!SendPayments');
        //System.debug('Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getLimitQueries());
        //System.debug('SOQL Queries Consumed: ' +  Limits.getQueries());
        // Get GL Codes
        Gl_Code__c[] glCodes = Database.query('Select Id, Payment_Field_Source__c, SL_Account__c, Type__c, Payment_Type__c from Gl_Code__c');
       
        for(Payment__c payline: paymentList){
        
            System.debug(payline.Id);

            // Get local Payment fields used
            Id PaymentID = payline.Id;
            String queryString = 'SELECT id,Name,Payee__c,Opportunity__c,Type__c,Invoice_Number__c,Payment_Status__c,Payment_Method__c, Less_Advance_Funding__c, Overnight__c  FROM Payment__c where id = :PaymentID';
            Payment__c thisPayment = Database.query(queryString);
          
            if ( thisPayment.Payment_Status__c == 'Ready to Send' ) {
                
            
                // Get Payee vendor field
                Id payeeID = thisPayment.Payee__c;
                // queryString = 'SELECT id,SL_Vendor_ID__c,Payee_Name__c,X1099__c,Last_Sales_Email__c,Last_Sales_Name__c FROM Payee__c where id = :payeeID';
                queryString = 'SELECT id,SL_Vendor_ID__c,Payee_Name__c,X1099__c FROM Payee__c where id = :payeeID';
                Payee__c payee = Database.query(queryString);
                System.debug('Payee = ' + payee.SL_Vendor_ID__c);
                
                // Get Opportunity fields
                Id OpportunityID = thisPayment.Opportunity__c;
                // queryString = 'SELECT id,Application__c,Name,Contract__c,AccountId,Owner.Email,Owner.Name FROM Opportunity where id = :OpportunityID';
                queryString = 'SELECT id,Application__c,Name,Contract__c,AccountId,SL_Company__c,CaseCenter__c FROM Opportunity where id = :OpportunityID';
                Opportunity thisOpportunity  = Database.query(queryString);
                                   
                // Get Account fields
                Id AccountID = thisOpportunity.AccountId;
                queryString = 'SELECT id,Name FROM Account where id = :AccountID';
                Account thisAccount  = Database.query(queryString);
                
                // System.debug(thisPayee.Id);
                
                // System.debug(thisPayment.Type__c);

                VoucherSF voucher = new VoucherSF();
                BatchSF batch = new BatchSF();
                ApdocSF APDoc = new ApdocSF();
                //APDoc.CpnyID = thisOpportunity.SL_Company__c;
                APDoc.DocType = 'VO';
                APDoc.CpnyID = '1000';   //per request 1-07-2022 - Jira - SAL-462  ALex
                APDoc.VendId = payee.SL_Vendor_ID__c;
                String regExp = '[^a-zA-Z0-9\']';
                
                // Jira SAL-3034, Service Request #94910 - 8/20/2021

                if ( thisPayment.Type__c == 'Lease_Payment') {
                    APDoc.User1 = thisOpportunity.Application__c + ' ' + thisAccount.Name.replaceAll(regExp ,' ').left(15);
                }
                else {
                    APDoc.User1 = thisOpportunity.CaseCenter__c;
                }
                
                if (String.isBlank(thisPayment.Invoice_Number__c)) { APdoc.User2 = ''; } else { APdoc.User2 = thisPayment.Invoice_Number__c; }
                APDoc.InvcNbr = APDoc.User1;
                APdoc.S4Future01 = thisPayment.id;
                APdoc.User5 = thisPayment.Name;
                APDoc.CashAcct = '110300';
                APDoc.notes= '';
                APDoc.Sub = '0400000000';
                if ( APDoc.CpnyID == '1000') {
                    APDoc.Sub = '0000000000';
                }
                
                APDoc.PmtMethod = 'C';
                APDoc.Crtd_Prog = '03PAY';
                APDoc.LUpd_Prog = 'SFPAY';
                
                batch.User5 = 'OPEN';
                
                // System.debug( 'Payment_Method__c = ' + thisPayment.Payment_Method__c);
                
                if ( thisPayment.Payment_Method__c == 'ACH') {
                    APDoc.Econfirm = 'MAIN';
                    APDoc.Estatus = 'O';
                    batch.User6 = 'ACHCHECK';
                    APDoc.User6 = 'ACHCHECK';
                } else if ( thisPayment.Payment_Method__c == 'Wire') {
                    APDoc.Econfirm = 'MAIN';
                    APDoc.Estatus = 'M';
                    batch.User6 = 'WIRE';
                    APDoc.User6 = 'WIRE';
                }
                else {
                    APDoc.Econfirm = '';
                    APDoc.Estatus = '';
                    batch.User6 = 'ACHCHECK';
                    APDoc.User6 = 'ACHCHECK';
               }
               if ( thisPayment.Less_Advance_Funding__c != null) {
                    batch.User6 = 'FUND';
                    APDoc.User6 = 'FUND';
                    batch.User5 = 'CLOSE';
                }
                else if ( thisPayment.Overnight__c == true) {
                    batch.User6 = 'OVERNIGHT';
                    APDoc.User6 = 'OVERNIGHT';
                    // like wire now 9-11-2019 - batch.User5 = 'CLOSE';
                }
               
                voucher.myAPTran = GetAPTransactions(glCodes, PaymentID, thisPayment.Type__c);
                decimal apdocAmt = 0;
                for ( AptranSF APTran: voucher.myAPTran) {
                
                    //APTran.CpnyID = thisOpportunity.SL_Company__c;
                    APTran.CpnyID = '1000';  // per request 2-08-2022 - Jira - SAL-462  ALex
                
                    // APTran.x1099 = '7';
                    String description = payee.SL_Vendor_ID__c + ' ' + payee.Payee_Name__c;
                    APTran.TranDesc = description.left(30);
                     APTran.ExtRefNbr = APDoc.User1;
                    System.debug(APTran.ExtRefNbr);
                    if ( thisPayment.Type__c == 'Lease_Payment') {
                        // Lease
                        //APTran.Sub = '0400000000';  per request 1-07-2022 - Jira - SAL-462  ALex
                        //if ( APTran.CpnyID == '1000') {
                        APTran.Sub = '0000000000';     // moved inside lease so not to squash loan  01-11-22 alex hatcher debanking.  per request 1-07-2022 - Jira - SAL-462  ALex
                    	//}
                    }
                    else {
                        // Loan
                        APTran.Sub = '0000024000';   // changed from 0400024000  01-11-22 alex hatcher  debanking.
                        APDoc.InvcNbr = thisOpportunity.Contract__c;
                    }
                    

                    if ( APTran.Acct == '133011' && payee.X1099__c == true ) {
                        APTran.BoxNbr = '7';
                    }
                    APTran.Crtd_Prog = 'SFPAY';
                    APTran.LUpd_Prog = 'SFPAY';
                    APTran.PC_Flag = '';
                    APTran.VendId = APDoc.VendId;
                    apdocAmt = apdocAmt + APTran.CuryUnitPrice;
                }

                //SAL-869 Need to make sure data is rounded to two digits, in some cases SF saves
                //with additional precision.
                apdocAmt = apdocAmt.setScale(2, System.RoundingMode.HALF_UP);
                APDoc.CuryDocBal = apdocAmt;
                APDoc.DocBal = apdocAmt;
                APDoc.CuryOrigDocAmt = apdocAmt;
                APDoc.OrigDocAmt = apdocAmt;
               
                // batch.CpnyID = thisOpportunity.SL_Company__c;
                batch.CpnyID = '1000';  // per request 1-07-2022 - Jira - SAL-462  ALex
                batch.Crtd_Prog = 'SFPAY';
                batch.LUpd_Prog = 'SFPAY';
                
                voucher.batchNote = '';
                voucher.myApdoc = APDoc;
                voucher.myBatch = batch;
                
                String s = JSON.serialize(voucher);
                
                System.debug(s);
                // send the data to the queue
                xctDataClass.makeCallout('SFPAYMENT', thisPayment.Id, 'ADD', s);
                
                //if ( payee.Last_Sales_Email__c != thisOpportunity.Owner.Email) {
                //     payee.Last_Sales_Email__c = thisOpportunity.Owner.Email;
                //     payee.Last_Sales_Name__c = thisOpportunity.Owner.Name;
                //     update payee;
                //      System.debug('Email = ' + thisOpportunity.Owner.Email);
                //     System.debug('Name= ' + thisOpportunity.Owner.Name);
                //}
               
                
            }
       
        }
        //System.debug('Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getLimitQueries());
        //System.debug('SOQL Queries consumed: ' +  Limits.getQueries());
       
    }
   
    private static List<AptranSF> GetAPTransactions( Gl_Code__c[] theGLCodes, Id PaymentID, String ThisType) {
    
        List<AptranSF> APTrans;
        APTrans = new List<AptranSF>();
        
        DescribeSObjectResult describeResult = PaymentID.getSObjectType().getDescribe();    
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );

        String queryString = 'SELECT ' + String.join( fieldNames, ',' ) + ' FROM Payment__c where id = :PaymentID';
        System.debug(queryString);
        Payment__c thisPayment = Database.query(queryString);   
        
        // Loop through GL Codes and see which fields are set and not zero for creating a transaction line.
        for(Gl_Code__c c: theGLCodes){
        
            if ( c.Payment_Type__c == 'Both' || (c.Payment_Type__c == 'Lease' && ThisType == 'Lease_Payment') || (c.Payment_Type__c == 'Loan' && ThisType == 'Loan_Payment')) {
                 // default the transaction
                AptranSF APTran = new AptranSF();
                APTran.UnitDesc = '';
                APTran.Qty= 1.0;
                APTran.Acct = '232900';
                APTran.CuryUnitPrice = 0;
                
                try {
                    System.debug(c.Payment_Field_Source__c);
     
                    Object o = thisPayment.get(c.Payment_Field_Source__c);
                    
                    String s = String.valueOf(o);
                    System.debug(s + ' ' + c.Type__c + ' ' + c.SL_Account__c);
                    
                    Decimal result = Decimal.valueOf(s);
                    //SAL-869 Need to make sure data is rounded to two digits, in some cases SF saves
                    //with additional precision.
                    result = result.setScale(2, System.RoundingMode.HALF_UP);
                    if ( result >= 0 ) {
                        
                        if ( c.Type__c == '-') {
                            APTran.CuryUnitPrice = 0 - result;
                        }
                        else 
                        {
                            APTran.CuryUnitPrice = result;
                        }
                        APTran.CuryTranAmt = APTran.CuryUnitPrice;
                        APTran.TranAmt = APTran.CuryUnitPrice;
                        APTran.UnitPrice = APTran.CuryUnitPrice;
                        APTran.Acct = c.SL_Account__c;
                        APTrans.Add(APTran);
                    }

                } catch(exception e) {
                }
            }
        }
        return (APTrans);

    }

 }