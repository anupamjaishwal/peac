/**
 * Created by jhber on 2/12/2019.
 */

public with sharing class TC_BWDealerRequestBean extends TC_BWRequestBean {

    //private static String NITRO_API = 'BW.CREATE.DEALER.UDO';
    public String NITRO_API;

    public Request Request;

    public TC_BWDealerRequestBean() {
        Header = new Header();
        Header.NitroApi = NITRO_API;
        Request = new Request();
    }

    public class Request {
        public String DealerNumber;
        public String DlrBranch;
        public String TbVdmAddr2;
        public String TbVdmCity;
        public String DlrCreditPhone;
        public String TbVdmAddr1;
        public String TbVdmState;
        public String TbVdmCountry;
        public String TbVdmZip;
        public String DlrUdTable1;
        public String DlrDealerId;
        public String DlrActiveDealer;
        public String DlrEquipCode;
        //public String DLRProgramMgr;
        public String TbVdmName;
        //public String DLRWebURL;
        public String DlrSalesperson;
        public String DlrMarketingRep;
        public String DlrCreditName;
        public String DlrCreditEmail;
        public String TbVdmTableType;
        public String DlrAReviewDate;
        public String DlrAFollowUpDate;
        public String DlrAComments;
        public String DlrMMRPaymentType;

        public String ApaMailAddr1;
        public String ApaMailAddr2;
        public String ApaMailAddr3;
        public String ApaMailCity;
        public String ApaMailState;
        public String ApaMailZip;

        public String DlrAFiscalYearEnd;
        public String DlrAStatementDate;
        public String DlrAExtentAudit;

        public String DlrUdTable2;
        public String DlrUdTable3;
        public String DlrUdAlphaNumeric1;
    }
}