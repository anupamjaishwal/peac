/** @author : Tamarack Consulting, Inc.
 * @date : 12/21/20
 * @description: 
 *
 */
public with sharing class TC_DwhStoredProcedureReqBean {

    Public class CreditExposureBean{
        public String CustomerTaxID;
        public String DealerNumber;
        public String CustomerCCAN;
        public String CustomerCCID;
    }


    public class FraudBean{
        public String Customer_CCAN;
        public String Federal_Tax_Id;
        public String BizCity;
        public String BizState;
        public String BizZip;
        public String BizPhone;
        public String PG1SSN;
        public String PG2SSN;
        public String PG1Email;
        public String PG2Email;
        public String PG1LastName;
        public String PG2LastName;
    }

    public class PGBean{
        public String Customer_CCAN;
        public String Federal_Tax_Id;
        public String PG1SSN;
        public String PG2SSN;
        public String PG1Email;
        public String PG2Email;
        public String PG1LastName;
        public String PG2LastName;
    }
}