public with sharing class SolomonEBanking {
    // XDD
    public class DepositorSF {
        public String VendID{ get; set; }
        public string Crtd_Prog{ get; set; }
        public string LUpd_Prog{ get; set; }
        public string AcctType { get; set; }
        public string BankTransit { get; set; }
        public string BankAcct { get; set; }
        public string EM1Vendor { get; set; }
        public string EM2ToCcBc { get; set; }
        public string EM3ToCcBc { get; set; }
        public string EM4ToCcBc { get; set; }
        public string EM4Addr { get; set; }
        public string EM4Name { get; set; }
        public string FormatID { get; set; }
        public string VendAcct { get; set; }
        public string WBenBankQualifier { get; set; }
        public string WBenBankID { get; set; }
        public string WBeneAcct { get; set; }
        public string WBeneAcctType { get; set; }
        public string WBeneName { get; set; }
        public string WBeneAddr { get; set; }
        public string WBeneAddr2 { get; set; }
        public string WBeneCity { get; set; }
        public string WBeneState { get; set; }
        public string WBeneZipPostal { get; set; }
        public string WBeneISOCntry { get; set; }
        public string PNTaxPmt {get; set; }
        public string Record {get; set; }
        public string EntryClass {get; set; }
        public integer EntryClassCanChg {get; set; }
        public string SKFuture01 {get; set; }
        public integer SKFuture09 {get; set; }
    }
    public class TxnTypeDeps {
        public string VendID { get; set; }
        public string VendCust { get; set; }
        public string VendAcct { get; set; }
        public string eStatus { get; set; }
        public string Selected { get; set; }
    
    }
    public class TopWrapper {
        public DepositorSF myDepositor  { get; set; }
        public List <TxnTypeDeps> myTxnTypeDeps { get; set; }
    }
        
 
    public static void Depositor(Payee__c payee, string type){
                    
            System.debug('!!!!!!SendEbanking');
            
            DepositorSF myDepositor = new DepositorSF();
            
        myDepositor.VendID = payee.SL_Vendor_ID__c;
        myDepositor.Record = 'V';
        myDepositor.EM1Vendor = 'Y'; // N?
        if ( payee.Default_Pay_Type__c == 'Check' ) {
            myDepositor.EntryClass = 'SLCK'; 
        }
        else if ( payee.Default_Pay_Type__c == 'ACH' ) {
            myDepositor.EntryClass = 'ACCP'; 
        }
        else {
            myDepositor.EntryClass = 'MTS'; 
        }  
        myDepositor.EntryClassCanChg = 1;
          
        if ( payee.ACH_Account_Type__c == 'Checking' ) {
            myDepositor.AcctType  = 'C'; 
        }
        else if ( payee.ACH_Account_Type__c == 'Savings' ) {
            myDepositor.AcctType  = 'S'; 
        }
        else if ( payee.ACH_Account_Type__c == 'Loan Account' ) {
            myDepositor.AcctType  = 'L'; 
        }
        else {
            myDepositor.AcctType  = 'F'; 
        }    
        
        myDepositor.Crtd_Prog = 'SFPAY';
        myDepositor.LUpd_Prog = 'SFPAY';
        myDepositor.BankTransit  = payee.ACH_Bank_Transit__c;
        myDepositor.BankAcct  = payee.ACH_Account_Number__c;
        myDepositor.EM2ToCcBc  = 'B';
        myDepositor.EM3ToCcBc  = 'B';
        myDepositor.EM4ToCcBc  = 'B';
        // myDepositor.EM4Addr  = 'FakeAPPaymentNotifications@marlinleasing.com';
        myDepositor.EM4Addr  = 'APPaymentNotifications@marlinleasing.com';
        myDepositor.EM4Name  = 'Ap Payment Notification';
        myDepositor.FormatID  = 'US-WFARGO-PMSV9';
        myDepositor.VendAcct  = 'MAIN';
        if ( payee.Qualifier__c == 'SWIFT' ) {
            myDepositor.WBenBankQualifier  = 'IS';
        }
        else if ( payee.Qualifier__c == 'FedWire' ) {
            myDepositor.WBenBankQualifier  = 'FW';
        }
        else {
            myDepositor.WBenBankQualifier  = '';
        }
        myDepositor.WBenBankID  = payee.Wire_ID__c;
        myDepositor.WBeneAcct  = payee.Wire_Account_Number__c;
        myDepositor.WBeneAcctType = 'D';
        myDepositor.WBeneName  = payee.Payee_Name__c;
        myDepositor.WBeneAddr  = payee.Address1__c;
        myDepositor.WBeneAddr2  = payee.Address2__c;
        myDepositor.WBeneCity  = payee.City__c;
        myDepositor.WBeneState  = payee.State__c;
        myDepositor.WBeneZipPostal  = payee.Zip__c;
        myDepositor.WBeneISOCntry  = payee.Country__c;
        myDepositor.SKFuture01 = payee.Id;
        
        if ( payee.EbankingExists__c == true ) {
            myDepositor.SKFuture09 = 1;
        }
        else {
            myDepositor.SKFuture09 = 0;
        }

        TopWrapper t = new TopWrapper();
        t.myDepositor = myDepositor;
        
        t.myTxnTypeDeps = new List<TxnTypeDeps>();
        TxnTypeDeps thisTxnTypeDeps = new TxnTypeDeps();
        thisTxnTypeDeps.VendID = payee.SL_Vendor_ID__c;
        thisTxnTypeDeps.VendAcct = 'MAIN';
        thisTxnTypeDeps.VendCust = 'V';
        thisTxnTypeDeps.eStatus = ' ';
        thisTxnTypeDeps.Selected = '1';
        t.myTxnTypeDeps.Add(thisTxnTypeDeps);
        TxnTypeDeps thisTxnTypeDepsO = new TxnTypeDeps();
        thisTxnTypeDepsO.VendID = payee.SL_Vendor_ID__c;
        thisTxnTypeDepsO.VendAcct = 'MAIN';
        thisTxnTypeDepsO.VendCust = 'V';
        thisTxnTypeDepsO.eStatus = 'O';
        if ( payee.ACH_Available__c == true) {
            thisTxnTypeDepsO.Selected = '1';
        }
        else {
            thisTxnTypeDepsO.Selected = '0';
        }
        t.myTxnTypeDeps.Add(thisTxnTypeDepsO);
        TxnTypeDeps thisTxnTypeDepsM = new TxnTypeDeps();
        thisTxnTypeDepsM.VendID = payee.SL_Vendor_ID__c;
        thisTxnTypeDepsM.VendAcct = 'MAIN';
        thisTxnTypeDepsM.VendCust = 'V';
        thisTxnTypeDepsM.eStatus = 'M';
        if ( payee.Wire_Available__c == true) {
            thisTxnTypeDepsM.Selected = '1';
        }
        else {
            thisTxnTypeDepsM.Selected = '0';
        }
        t.myTxnTypeDeps.Add(thisTxnTypeDepsM);
        
        
        String s = JSON.serialize(t);
        
        System.debug(s);
        // send the data to the queue
           xctDataClass.makeCallout('SFEBANK', payee.Id, type, s);
        
    }

}