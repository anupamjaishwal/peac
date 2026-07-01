/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 05/24/2018
* @description: http://docs.bridgewaretamarack.apiary.io
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public with sharing class TC_BridgewareBookContractRequestUCI {
	private String uciConfig;
	private String uciRecord;
	private String uciKey;
    private String appNumber;//SAL-5692 Expo: Opportunity Refactor
    private Decimal assetCount;//SAL-5692 Expo: Opportunity Refactor

	public String getUciConfig() {
		return uciConfig;
	}

	public void setUciConfig(String uciConfig) {
		this.uciConfig = uciConfig;
	}

	public String getUciRecord() {
		return uciRecord;
	}

	public void setUciRecord(String uciRecord) {
		this.uciRecord = uciRecord;
	}

	public String getUciKey() {
		return uciKey;
	}

	public void setUciKey(String uciKey) {
		this.uciKey = uciKey;
	}
    
    //SAL-5692 Expo: Opportunity Refactor
    public void setAssetCount(Decimal assetCount) {
        System.debug(LoggingLevel.ERROR, 'UCI Asset Count = ' + assetCount);
		this.assetCount = assetCount;
	}
    
    //SAL-5692 Expo: Opportunity Refactor
    public Decimal getAssetCount() {
		return assetCount;
	} 
    
    //SAL-5692 Expo: Opportunity Refactor
    public void setAppNumber(String appNumber) {
        this.appNumber = appNumber;
	}
    
    //SAL-5692 Expo: Opportunity Refactor
    public String getAppNumber() {
		return appNumber;
	}

	public String getIL10Json(){
        String finalIL10Json = null;
        System.debug(LoggingLevel.ERROR, 'ASSET COUNT while sending = ' + this.assetCount);
        
		finalIL10Json = '{'
						+ '"uci.Config": "SALESFORCE",'
						+ '"uci.Record": "' + this.uciRecord + '",'
						+ '"uci.Key": "' + this.uciKey + '"';
        //SAL-5692 Expo: Opportunity Refactor-Added logic to send AppNumber if AssetCount > 50
        if((this.assetCount ?? 0) > Integer.valueOf(System.Label.PEAC_ILSendAssetLimit)){
            finalIL10Json += ','+'"uci.App": "' + this.appNumber + '"';
        }else{
            finalIL10Json += ','+'"uci.App": ""';
        }
		finalIL10Json += '}';
        
        return finalIL10Json;
	}
}