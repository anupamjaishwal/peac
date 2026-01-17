/**
 * @description Calls the account setup and assign signers api. Contacts included in this call will get an email to set up.
 * SAL-3249
 */
public with sharing class TC_AssignSignersAPI {
    
     /**
     * @description Sends callout to the online doc portal which in turn will set up accounts for the signers and send them an email
     * SAL-3249
     * @param statusId this is the id of a docusign status object
     */
    public static void callAssignSignersAPI(Id statusId){

        List<TC_AssignSignersBean> beans = TC_AssignSignersMapper.mapSalesforceToBean(statusId);

        String requestString = JSON.serialize(beans);
        System.debug(JSON.serializePretty(beans));
        TC_AssignSignersService.doCallout(statusId, requestString);
    }
}