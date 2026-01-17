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

	public String getIL10Json(){
		return '{'
			+ '"uci.Config": "SALESFORCE",'
			+ '"uci.Record": "' + this.uciRecord + '",'
			+ '"uci.Key": "' + this.uciKey + '"'
		+'}';
	}
}