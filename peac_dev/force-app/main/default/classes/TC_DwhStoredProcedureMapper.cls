/** @author : Tamarack Consulting, Inc.
 * @date : 12/21/20
 * @description: 
 *
 */
public with sharing class TC_DwhStoredProcedureMapper {

    public static TC_DwhStoredProcedureReqBean.CreditExposureBean mapSalesforceToBean (Id accId) {

        Account acc = [SELECT Id, Tax_ID__c, Dealer_Number__c, CCAN__c, CCID__c, RecordType.Name FROM Account WHERE Id=:accId LIMIT 1];

        TC_DwhStoredProcedureReqBean.CreditExposureBean req = new TC_DwhStoredProcedureReqBean.CreditExposureBean ();
        req.CustomerTaxID = acc.Tax_ID__c != null ? acc.Tax_ID__c : '';
        req.DealerNumber = acc.Dealer_Number__c != null ? acc.Dealer_Number__c : '';
        req.CustomerCCAN = acc.CCAN__c != null && acc.RecordType.Name <> 'Dealer Account' ? acc.CCAN__c : '';
        req.CustomerCCID = acc.CCID__c != null ? acc.CCID__c : '';

        return req;
    }

    public static TC_DwhStoredProcedureReqBean.CreditExposureBean mapSalesforceToBean(Id accId, Id oppId){
        //This is made for the quick app call to TC_DwhStoredProcedureApi per SAL-2496

        Account acc = [SELECT Id, Tax_ID__c, Dealer_Number__c, CCAN__c, CCID__c FROM Account WHERE Id=:accId LIMIT 1];
        Opportunity opp = [SELECT Id, Primary_Dealer__r.Dealer__r.Dealer_Number__c FROM Opportunity WHERE Id=:oppId LIMIT 1];

        TC_DwhStoredProcedureReqBean.CreditExposureBean req = new TC_DwhStoredProcedureReqBean.CreditExposureBean ();
        req.CustomerTaxID = acc.Tax_ID__c != null ? acc.Tax_ID__c : '';
        req.DealerNumber = opp.Primary_Dealer__r.Dealer__r.Dealer_Number__c != null ? opp.Primary_Dealer__r.Dealer__r.Dealer_Number__c : '';
        req.CustomerCCAN = acc.CCAN__c != null ? acc.CCAN__c : '';
        req.CustomerCCID = acc.CCID__c != null ? acc.CCID__c : '';

        return req;
    }

    public static TC_DwhStoredProcedureReqBean.FraudBean mapAccountFraudInfoToBean(Id oppId){

        Opportunity opp = [SELECT Id, Account.Id, Account.Tax_ID__c, Account.Business_City__c, Account.Business_State__c, Account.Business_Zip__c, Account.Business_Phone__c, Account.CCAN__c,
        (SELECT Id, SSN__c, Email__c, Contact__r.LastName FROM Guarantor__r ORDER BY CreatedDate ASC)
        FROM Opportunity WHERE Id=:oppId LIMIT 1];

        TC_DwhStoredProcedureReqBean.FraudBean req = new TC_DwhStoredProcedureReqBean.FraudBean();
        req.Customer_CCAN = opp.Account.CCAN__c != null ? opp.Account.CCAN__c : '';
        req.Federal_Tax_Id = opp.Account.Tax_ID__c != null ? opp.Account.Tax_ID__c : '';
        req.BizCity = opp.Account.Business_City__c != null ? opp.Account.Business_City__c : '';
        req.BizState = opp.Account.Business_State__c != null ? opp.Account.Business_State__c : '';
        req.BizZip = opp.Account.Business_Zip__c != null ? opp.Account.Business_Zip__c : '';
        req.BizPhone = opp.Account.Business_Phone__c != null ? opp.Account.Business_Phone__c.replace(')', '').replace('(', '').replace('-', '') : '';

        if(opp.Guarantor__r.size() > 0){
            req.PG1SSN = opp.Guarantor__r[0].SSN__c != null ? opp.Guarantor__r[0].SSN__c : '';
            req.PG1Email = opp.Guarantor__r[0].Email__c != null ? opp.Guarantor__r[0].Email__c : '';
            req.PG1LastName = opp.Guarantor__r[0].Contact__r.LastName != null ? opp.Guarantor__r[0].Contact__r.LastName : '';

            if(opp.Guarantor__r.size() > 1){
                req.PG2SSN = opp.Guarantor__r[1].SSN__c != null ? opp.Guarantor__r[1].SSN__c : '';
                req.PG2Email = opp.Guarantor__r[1].Email__c != null ? opp.Guarantor__r[1].Email__c : '';
                req.PG2LastName = opp.Guarantor__r[1].Contact__r.LastName != null ? opp.Guarantor__r[1].Contact__r.LastName : '';
            }
            else {
                req.PG2SSN = '';
                req.PG2Email = '';
                req.PG2LastName = '';
            }
        }
        else {
            req.PG1SSN = '';
            req.PG1Email = '';
            req.PG1LastName = '';
            req.PG2SSN = '';
            req.PG2Email = '';
            req.PG2LastName = '';
        }
        
        return req;
    }
    /**
     * @param oppId this is the Id of the opportunity being referenced in the quickapp
     * @param businessFraudResponseBean this will be a TC_DwhStoredProcedureRespBean.resultBean returned from the TC_DwhStoredProcedureApi.businessFraudQuery, null is also a valid input
     *
     * This is a class to map responses from 2 stored procedures to a webservice field object part of a solution connecting components for SAL-2730
     */
    public static void mapBeansToWebserviceField(Id oppId, TC_DwhStoredProcedureRespBean businessFraudResponseBean){

        Webservice_Field__c wsf;
        if(businessFraudResponseBean != null){

            Boolean updateRecords = false;

	
            List<Webservice_Field__c> webserviceFields = [
                SELECT Id, 
                Opportunity__c, 
                CustomerDealerDistance__c,
                BizCityMatch__c,
                BizStateMatch__c,
                BizZipMatch__c,
                BizPhoneMatch__c,
                BizInfoMatch__c,
                RunNewCustomerFlow__c,
                PG1SSNMatch__c,
                PG2SSNMatch__c,
                PG1EmailMatch__c,
                PG2EmailMatch__c,
                PG1LastNameMatch__c,
                PG2LastNameMatch__c,
                PersonalInfoMatch__c
                FROM Webservice_Field__c 
                WHERE Opportunity__c = :oppId];

            if(webserviceFields.isEmpty()){
                wsf = new Webservice_Field__c();
                wsf.Opportunity__c = oppId;
                system.debug('======wsf empty'+ wsf);
            }else {
                wsf = new Webservice_Field__c();
                wsf = webserviceFields[0];
                system.debug('======wsf inside'+ wsf);
            }
            system.debug('======wsf Before'+ wsf);
            Opportunity opp = new Opportunity(Id=oppId);
            system.debug('===========businessFraudResponseBean'+ businessFraudResponseBean);
            //DWH Fraud Response Fields
            if(businessFraudResponseBean.results.size() > 0){
                wsf.BizCityMatch__c = businessFraudResponseBean.results[0].BizCityMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].BizCityMatch) : wsf.BizCityMatch__c;
                wsf.BizStateMatch__c = businessFraudResponseBean.results[0].BizStateMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].BizStateMatch) : wsf.BizStateMatch__c;
                wsf.BizZipMatch__c = businessFraudResponseBean.results[0].BizZipMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].BizZipMatch) : wsf.BizZipMatch__c;
                wsf.BizPhoneMatch__c = businessFraudResponseBean.results[0].BizPhoneMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].BizPhoneMatch) : wsf.BizPhoneMatch__c;
                wsf.BizInfoMatch__c = businessFraudResponseBean.results[0].BizInfoMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].BizInfoMatch) : wsf.BizInfoMatch__c;
                wsf.CustomerDealerDistance__c = businessFraudResponseBean.results[0].DealerDistance != null ? businessFraudResponseBean.results[0].DealerDistance : wsf.CustomerDealerDistance__c;
                wsf.RunNewCustomerFlow__c = businessFraudResponseBean.results[0].RunNewCustomerFlow != null ? Decimal.valueOf(businessFraudResponseBean.results[0].RunNewCustomerFlow) : wsf.RunNewCustomerFlow__c;
                wsf.PG1SSNMatch__c = businessFraudResponseBean.results[0].PG1SSNMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].PG1SSNMatch) : wsf.PG1SSNMatch__c;
                wsf.PG2SSNMatch__c = businessFraudResponseBean.results[0].PG2SSNMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].PG2SSNMatch) : wsf.PG2SSNMatch__c;
                wsf.PG1EmailMatch__c = businessFraudResponseBean.results[0].PG1EmailMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].PG1EmailMatch) : wsf.PG1EmailMatch__c;
                wsf.PG2EmailMatch__c = businessFraudResponseBean.results[0].PG2EmailMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].PG2EmailMatch) : wsf.PG2EmailMatch__c;
                wsf.PG1LastNameMatch__c = businessFraudResponseBean.results[0].PG1LastNameMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].PG1LastNameMatch) : wsf.PG1LastNameMatch__c;
                wsf.PG2LastNameMatch__c = businessFraudResponseBean.results[0].PG2LastNameMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].PG2LastNameMatch) : wsf.PG2LastNameMatch__c;
                wsf.PersonalInfoMatch__c = businessFraudResponseBean.results[0].PersonalInfoMatch != null ? Decimal.valueOf(businessFraudResponseBean.results[0].PersonalInfoMatch) : wsf.PersonalInfoMatch__c;
                opp.CustomerType__c = businessFraudResponseBean.results[0].CustomerType != null ? businessFraudResponseBean.results[0].CustomerType : opp.CustomerType__c;
                opp.Fraud_Review_Status__c = businessFraudResponseBean.results[0].FraudReviewStatus != null ? businessFraudResponseBean.results[0].FraudReviewStatus : opp.Fraud_Review_Status__c;
                opp.FraudReviewFlag__c = businessFraudResponseBean.results[0].Fraud_Review_Flag != null ? Decimal.valueOf(businessFraudResponseBean.results[0].Fraud_Review_Flag) : opp.FraudReviewFlag__c;
               // wsf.Reason_PG_Required__c = businessFraudResponseBean.results[0].PGRequired_Reason != null ? string.valueOf(businessFraudResponseBean.results[0].PGRequired_Reason) : wsf.Reason_PG_Required__c;
                updateRecords = true;
            }

            system.debug('======wsf After'+ wsf);
            if(updateRecords){
                Opportunity op = [SELECT Id, Portal_User_ID__c FROM Opportunity WHERE Id = :oppId ];
               
                if(op.Portal_User_ID__c.contains('PUDA-') || op.Portal_User_ID__c.contains('UDA-') || op.Portal_User_ID__c.contains('SF-')){
                    update wsf;
                	update opp;
                }else{
                    upsert wsf;
                    update opp;
                }
            }
        }
    }
}