/************************************************************************************************************************
 @Description: Serializes object representation of the request/response to and from xml
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 06/16/2025
 ************************************************************************************************************************/

public with sharing class PEAC_GdsScoreLoanXmlUtil{
    
    public static String handleNull (String str) {
        return str == null ? '' : str.escapeXml();
    }
    public static String handleNull (Decimal decValue) {
        return decValue == null ? '' : String.valueOf (decValue).escapeXml();
    }
    public static String handleNull (Date str) {
        return str == null ? '' : String.valueOf (str).escapeXml();
    }
     
    public static string handleBooleanWithYN (Boolean boolValue) {
        return boolValue == true ? 'Y' : 'N';
    }
    
    // added a company type param, because Marlin doesn't want to send the empty tags for DBDUNSNUMBER for CC, BV, and company1
    private static String serializeCompanyRequest (Gds_Score_Request_Company__c company, String nodePath) {
        
        String comXML = getXMLMapping(nodePath, company);
        comXML += '<ACCOUNTINFOCHANGED>' + handleBooleanWithYN(company.Is_Company_Changed__c) + '</ACCOUNTINFOCHANGED>';
        return comXml;
    }
    private static String serializeOrignators (Gds_Score_Request_Company__c broker, String nodePath) {
        
        String comXML = getXMLMapping(nodePath, broker);
        return comXml;
    }
    
    private static String serializeIndividualRequest (Gds_Score_Request_Individual__c ind, Integer i) {
        String indXml = getXMLMapping('PG', ind);
        
         indXml += '<PG'+String.ValueOf(i)+'_PGINFOCHANGED>' + handleBooleanWithYN(ind.Is_PG_Changed__c) + '</PG'+String.ValueOf(i)+'_PGINFOCHANGED>';
         indXml += '<PG'+String.ValueOf(i)+'_PGDELETED>' + handleBooleanWithYN(ind.Is_PG_Deleted__c) + '</PG'+String.ValueOf(i)+'_PGDELETED>';
        indXml += '<PG'+String.ValueOf(i)+'_VALIDITYVERIFY_RESULT>' + handleNull(ind.Validity_Verify_Status__c) + '</PG'+String.ValueOf(i)+'_VALIDITYVERIFY_RESULT>';
        indXml += '<PG'+String.ValueOf(i)+'_FINALEMAILVALIDITY>' + handleNull(ind.Final_Email_Validity_Result__c) + '</PG'+String.ValueOf(i)+'_FINALEMAILVALIDITY>';
        

        return indXml;
    }

    public static String serializeApplicationData(Gds_Score__c req ,String nodePath)
    {
        return getXMLMapping(nodePath, req);
    }
    public static String serializeDWHGetCusCredExp(Webservice_Field__c wsFields ,String nodePath)
    {
        return getXMLMapping(nodePath, wsFields);
    }
    public static String serializeGetFraudFlags(Webservice_Field__c wsFields ,String nodePath)
    {
        return getXMLMapping(nodePath, wsFields);
    }
    public static String serializeThreatMetrix(Gds_Score__c req ,String nodePath)
    {
        return getXMLMapping(nodePath, req);
    }
    public static String serializeGDSScore(Gds_Score__c req ,String nodePath)
    {
        return getXMLMapping(nodePath, req);
    }

    public static String serializeRequest (PEAC_GDSScoreLoanReqRespBean reqBean) {

        Gds_Score__c req = reqBean.scoreReq;// main request
        Gds_Score_Request_Company__c company1 = reqBean.company1;
        Gds_Score_Request_Company__c broker = reqBean.broker;
        List <Gds_Score_Request_Individual__c> pgs = reqBean.pgs;
        Opportunity opp = reqBean.opp;
        Webservice_Field__c wsFields = reqBean.wsFields;
        Webservice_Field__c fraudWSFields = reqBean.wsFieldsFraud;
        

        String xml = '<?xml version="1.0"?><APPLICATIONDATA>';
        xml += serializeApplicationData(req ,'APPLICATIONDATA');
        
        
        xml += '<COMPANY1>' + serializeCompanyRequest (company1, 'COMPANY1') + '</COMPANY1>';
        
            
        // up to 4 pgs can be sent
        for (Integer i = 0; i < pgs.size () && i < 4; i++) {
            Integer pgTagNumber = Integer.valueOf(pgs[i].PG_Number__c);
            xml += '<PG'+ pgTagNumber + '>' + serializeIndividualRequest (pgs[i], Integer.valueOf(pgs[i].PG_Number__c)) + '</PG' + pgTagNumber + '>';
        }
        
        //ORIGINATORS
        xml += '<ORIGINATORS>'  + serializeOrignators(broker,'ORIGINATORS') + '</ORIGINATORS>';
        
        // threatmetrix
        xml += '<THREATMETRIX>'  + serializeThreatMetrix(req,'THREATMETRIX') + '</THREATMETRIX>';
        
        //DWH_GetCustomerCreditExposure
        xml += '<DWH_GetCustomerCreditExposure>'  + serializeDWHGetCusCredExp(wsFields,'DWH_GetCustomerCreditExposure') + '</DWH_GetCustomerCreditExposure>';
        //GetFraudFlags
        xml += '<GetFraudFlags>'  + serializeDWHGetCusCredExp(fraudWSFields,'GetFraudFlags') + '</GetFraudFlags>';
       
        //Get Banks
        xml += '<BANKS>'  + serializeGDSScore(req,'BANKS') + '</BANKS>';
        
        //Get LP_PREQUALDATA
        xml += '<LP_PREQUALDATA>'  + serializeGDSScore(req,'LP_PREQUALDATA') + '</LP_PREQUALDATA>';
        //Get lsc
        xml += '<lsc>'  + serializeGDSScore(req,'lsc') + '</lsc>';
        xml += '</APPLICATIONDATA>';
        return xml;
    }

    //get gds_score related field mapping from custom metadata
    public static string getXMLMapping(String nodePathName, sObject objectInstance){
        list<GDS_Mapping__mdt> gdsMappingList = [SELECT label,Field_Mapping_Details__c,Object_Name__c FROM GDS_Mapping__mdt WHERE developerName =:nodePathName];

        String numberStr = 'Number';
        String xmlValue = '';
        if(!gdsMappingList.isEmpty() && objectInstance!=Null)
        {
            list<String> gdsTagWithFieldsList = gdsMappingList[0].Field_Mapping_Details__c.split('\\r?\\n');
            
            if(!gdsTagWithFieldsList.isEmpty() )
            {

                for(String gdsTagWithFieldMap : gdsTagWithFieldsList)
                {
                    List<String> gdsTagAndFieldList = gdsTagWithFieldMap.split('-');
                    String fieldValue = handleNull(String.valueOf(objectInstance.get(gdsTagAndFieldList[1])));
                    String dataType = getFieldType(gdsMappingList[0].Object_Name__c,gdsTagAndFieldList[1]);
                    
                    xmlValue += '<'+gdsTagAndFieldList[0]+'>'+ fieldValue +'</'+gdsTagAndFieldList[0]+'>';
                }
            }
        }
         return xmlValue;
        

    }
       

    public static String getFieldType(String sobjectname,String fieldapiName){
        return string.valueOf(Schema.getGlobalDescribe().get(sobjectname).getDescribe().fields.getMap().get(fieldApiName).getDescribe().getType().name().toUpperCase());
    }
    

    private static String xmlDecode (String xmlValue) {
        return xmlValue == null ? '': xmlValue.unescapeXml ();
    }

}