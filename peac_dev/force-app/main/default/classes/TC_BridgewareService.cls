/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: http://docs.bridgewaretamarack.apiary.io
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public interface TC_BridgewareService {
	TC_BridgewareBookContractRespBean bookContract (TC_BridgewareBookContractRequestUCI uci);
	TC_BridgewareSelectZipGeoCodeRespBean selectZipGeoCode (TC_BridgewareSelectZipGeoCodeRequestBean bean);
}