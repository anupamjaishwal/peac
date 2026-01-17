/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: http://docs.bridgewaretamarack.apiary.io
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public with sharing class TC_BridgewareBookContractRespBean {
    @AuraEnabled 
	public String statusMessage;
    @AuraEnabled
	public String responseMessageDesc;
    @AuraEnabled
	public String contractNbr;
    @AuraEnabled
	public String opportunityStage;
	
	public static TC_BridgewareBookContractRespBean createResponseBeanFromJson (String jsonString) {
		TC_BridgewareBookContractRespBean respBean = (TC_BridgewareBookContractRespBean) JSON.deserialize(
               jsonString, TC_BridgewareBookContractRespBean.class);
		return respBean;
	}
}