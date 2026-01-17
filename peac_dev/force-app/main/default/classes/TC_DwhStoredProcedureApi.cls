/** @author : Tamarack Consulting, Inc.
 * @date : 12/21/20
 * @description: 
 *
 */
public with sharing class TC_DwhStoredProcedureApi {

    public static String errorMessage = '';

    public static TC_DwhStoredProcedureRespBean getPortalCustCreditExp (Id accId) {

        try {

            // Map Salesforce fields to a bean
            TC_DwhStoredProcedureReqBean.CreditExposureBean reqBean = TC_DwhStoredProcedureMapper.mapSalesforceToBean (accId);

            // Serialize the bean into JSON
            String reqStr = JSON.serialize(reqBean);

            System.debug('request string:' + reqStr);
            // do callout
            String respStr = TC_DwhStoredProcedureService.doCallout(reqStr, accId, 'Default');
            System.debug('Response string:' + respStr);

            // Deserialize the JSON response into a bean
            TC_DwhStoredProcedureRespBean respBean = TC_DwhStoredProcedureJSONUtil.deserializeResponse(respStr);

            System.debug('reqBean: ' + reqBean);
            System.debug('respBean:' + respBean);

            // if map bean to salesforce needed use the below method, the method still needs to be written 
            //TC_DwhStoredProcedureMapper.mapBeanToSalesforce(respBean, accId);

            return respBean;

        } catch (Exception e) {
            System.debug(e.getMessage());
        } 
        return null;
    }

    public static TC_DwhStoredProcedureRespBean getPortalCustCreditExp (Id accId, Id oppId) {
        //This Version is for the quick app it will take in an opportunity Id per SAL-2496
        try {

            // Map Salesforce fields to a bean
            TC_DwhStoredProcedureReqBean.CreditExposureBean reqBean = TC_DwhStoredProcedureMapper.mapSalesforceToBean (accId, oppId);

            // Serialize the bean into JSON
            String reqStr = JSON.serialize(reqBean);

            System.debug('request string:' + reqStr);
            // do callout
            String respStr = TC_DwhStoredProcedureService.doCallout(reqStr, oppId, 'Default');
            System.debug('Response string:' + respStr);

            // Deserialize the JSON response into a bean
            TC_DwhStoredProcedureRespBean respBean = TC_DwhStoredProcedureJSONUtil.deserializeResponse(respStr);

            System.debug('reqBean: ' + reqBean);
            System.debug('respBean:' + respBean);

            // if map bean to salesforce needed use the below method, the method still needs to be written
            //TC_DwhStoredProcedureMapper.mapBeanToSalesforce(respBean, accId);

            return respBean;

        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        return null;
    }

    /**
     * @param oppId opportunity Id to be passed in
     *New Dwh call added per SAL-2770
     * @return returns a response bean that maps response json to object.
     */
    public static TC_DwhStoredProcedureRespBean businessFraudQuery(Id oppId){

        try{
            // Map Salesforce fields to a bean
            TC_DwhStoredProcedureReqBean.FraudBean reqBean = TC_DwhStoredProcedureMapper.mapAccountFraudInfoToBean(oppId);

            // Serialize the bean into JSON
            String reqStr = JSON.serialize(reqBean);

            System.debug('request string:' + reqStr);
            // do callout
            String respStr = TC_DwhStoredProcedureService.doCallout(reqStr, oppId, 'Fraud');

            System.debug('Response String: ' + respStr);

            // Deserialize the JSON response into a bean
            TC_DwhStoredProcedureRespBean respBean = TC_DwhStoredProcedureJSONUtil.deserializeResponse(respStr);

            System.debug('respBean:' + respBean);

            return respBean;
        }
        catch (Exception e){
            System.debug(e.getMessage());
        }

        return null;
    }
}