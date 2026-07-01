/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to call create Zip Geo Code to process multiple assets at once.
@User Story: SAL-5692 Expo: Opportunity Refactor
@Created Date: 01-Sep-2025
**************************************************************************************************************/

public class PEAC_BridgewareSelectZipGeoCodes {

	public PEAC_BridgewareSelectZipGeoCodes() {

	}

	public static void searchMultipleAssets(List<Asset__c> assetsList) {
		List<Asset__c> assetsToUpdate = new List<Asset__c>();
		List<Rate__c> ratesToUpsert = new List<Rate__c>();
		List<Rate__c> ratesToInsert = new List<Rate__c>();
		Set<String> uniqueZipsSet = new Set<String>();
		Map<Id, Rate__c> ratesToUpdate = new Map<Id, Rate__c>();
		Map<String, String> fieldsConfig = new Map<String, String>();
		List<TC_BridgewareTaxJurisdiction> ratesRespList = new List<TC_BridgewareTaxJurisdiction>();

		for(PEAC_BulkAssetsUpload__mdt mdt : [SELECT DeveloperName,Value__c FROM PEAC_BulkAssetsUpload__mdt WHERE DeveloperName IN ('AssetFieldsRespDataMapping','RateFieldsRespDataMapping')]){
			fieldsConfig.put(mdt.DeveloperName, mdt.Value__c);
		}
		for(Asset__c asset :assetsList){
			if(String.isNotEmpty(asset.Equipment_Zip__c)){
				uniqueZipsSet.add(asset.Equipment_Zip__c);
			}
		}
		Map<String, Map<String, List<TC_BridgewareTaxJurisdiction>>> zipRespsMap = getZipTaxCodes(uniqueZipsSet);
		for(String zip : uniqueZipsSet){
			if(zipRespsMap?.get(zip)?.get('Rates')?.isEmpty() == false)
				ratesRespList.addAll(zipRespsMap?.get(zip)?.get('Rates'));
		}
		if(!ratesRespList.isEmpty())
			saveRates(ratesRespList, fieldsConfig.get('RateFieldsRespDataMapping'));

		//try {
			for(Asset__c asset :assetsList){
				if(zipRespsMap?.get(asset?.Equipment_Zip__c)?.get('Assets')?.isEmpty() == false){
					assetsToUpdate.addAll(updateAssets(asset, zipRespsMap.get(asset.Equipment_Zip__c).get('Assets'), fieldsConfig.get('AssetFieldsRespDataMapping')));
				}
				/*if(zipRespsMap.get(asset.Equipment_Zip__c).get('Rates').size() > 0){
					ratesToUpsert.addAll(saveRates(zipRespsMap.get(asset.Equipment_Zip__c).get('Rates'), fieldsConfig.get('RateFieldsRespDataMapping')));
				}*/
			}
			system.debug(LoggingLevel.error,'assetsToUpdate size : '+ assetsToUpdate.size());
			system.debug(LoggingLevel.error,'ratesToUpsert size : '+ ratesToUpsert.size());
			update assetsToUpdate;

			/*if(ratesToUpsert.size() > 0){
				for(Rate__c rate : ratesToUpsert){
					if(rate.Id == null){
						ratesToInsert.add(rate);
					}else if(!ratesToUpdate.containsKey(rate.Id)){
						ratesToUpdate.put(rate.Id, rate);
					}
				}
			}
			system.debug(LoggingLevel.error,'ratesToInsert size : '+ ratesToInsert.size());
			system.debug(LoggingLevel.error,'ratesToUpdate size : '+ ratesToUpdate.values().size());
			if(ratesToInsert.size() > 0){
				insert ratesToInsert;
			}
			if(ratesToUpdate.values().size() > 0){
				update ratesToUpdate.values();
			}*/
		//} catch(Exception ex) {
			//handleException(ex);return null;
		//}
	}

	public static Map<String, Map<String, List<TC_BridgewareTaxJurisdiction>>> getZipTaxCodes(Set<String> uniqueZips){
		TC_BridgewareUtility serviceUtil = TC_BridgewareUtility.getInstance();
		TC_BridgewareSelectZipGeoCodeRespBean respBean;
		Boolean isIL10 = IL10_Flag__c.getValues('GeneralSetting').use_IL10__c;
		Boolean mockCallout = serviceUtil.getServiceSettings().Mock_Callout__c;
		String mockEndpoint = serviceUtil.getServiceSettings().Mock_Endpoint__c;
		String configName = serviceUtil.getServiceSettings().Config_Name__c;
		Blob headerValue = Blob.valueOf('username' + ':' + 'password');
		String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
		Map<String, Map<String, List<TC_BridgewareTaxJurisdiction>>> zipResps = new Map<String, Map<String, List<TC_BridgewareTaxJurisdiction>>>();

		for(String zipCode : uniqueZips){
			TC_BridgewareSelectZipGeoCodeRequestBean bean = new TC_BridgewareSelectZipGeoCodeRequestBean();
			bean.setZipCode(zipCode);
			bean.setTaxCode('');
			bean.setRequestUserId('');

			Http h = new Http ();
			HttpRequest req = new HttpRequest ();
			if(mockCallout && !String.isEmpty(mockEndpoint)){
				req.setHeader('Authorization', authorizationHeader);
				req.setEndpoint(mockEndpoint + '/selectZipGeoCode');
			}else{
				if(isIL10){
					TC_BWUtility.requestToIL10(req, 'ZIP');
				}else{
					req.setEndpoint('callout:Bridgeware/selectZipGeoCode');
				}
			}
			req.setMethod('POST');
			req.setHeader('CONFIG-NAME', configName);
			req.setHeader('Content-Type','application/json');
			req.setBody(JSON.serialize(bean));
			req.setTimeout(120000);

			HttpResponse resp = h.send(req);
			String responseJson = TC_BWResponseBean.unWrap(resp.getBody());
			if(resp.getStatusCode() == 200) {
				if(isIL10){
					respBean = TC_BridgewareSelectZipGeoCodeRespBean.createResponseBeanFromXml(responseJson);
				}else{
					respBean = TC_BridgewareSelectZipGeoCodeRespBean.createResponseBeanFromJson(responseJson);
				}
			}else{
				respBean = TC_BridgewareSelectZipGeoCodeRespBean.createResponseBeanFromJson(responseJson);
			}
			Map<String, List<TC_BridgewareTaxJurisdiction>> respAssetsRates = getTaxJurisdictions(respBean);
			zipResps.put(zipCode, respAssetsRates);
		}
		return zipResps;
	}

	public static Map<String, List<TC_BridgewareTaxJurisdiction>> getTaxJurisdictions(TC_BridgewareSelectZipGeoCodeRespBean selectZipGeoCodeResp) {
		List<TC_BridgewareTaxJurisdiction> taxJurisdictionList = new List<TC_BridgewareTaxJurisdiction>();
		Map<String,TC_BridgewareTaxJurisdiction> rateMap = new Map<String,TC_BridgewareTaxJurisdiction>();
		Map<String, List<TC_BridgewareTaxJurisdiction>> respAssetsRates = new Map<String, List<TC_BridgewareTaxJurisdiction>>();
		
		if (selectZipGeoCodeResp.getContentData() != null) {
			TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState[] uniDataVtZipStateList = selectZipGeoCodeResp.getContentData().getVtZipStateList();
			
			if (uniDataVtZipStateList != null) {
				for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipState uniDataVtZipState : uniDataVtZipStateList) {
					String state = uniDataVtZipState.getDescription();
					String stateCode = uniDataVtZipState.getCode();
					TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty[] uniDataVtZipCountyList = uniDataVtZipState.getVtZipCountyList();
					
					if (uniDataVtZipCountyList != null) {
						for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCounty uniDataVtZipCounty : uniDataVtZipCountyList) {
							String county = uniDataVtZipCounty.getDescription();
							String countyCode = uniDataVtZipCounty.getCode();
							TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity[] uniDataVtZipCityList = uniDataVtZipCounty.getVtZipCityList();
							
							if (uniDataVtZipCityList != null) {
								for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataVtZipCity uniDataVtZipCity : uniDataVtZipCityList) {
									String city = uniDataVtZipCity.getDescription();
									String cityCode = uniDataVtZipCity.getCode();
									TC_BridgewareTaxJurisdiction taxJurisdiction = new TC_BridgewareTaxJurisdiction();
									taxJurisdiction.city = city;
									taxJurisdiction.county = county;
									taxJurisdiction.state = state;
									taxJurisdiction.cityCode = cityCode;
									taxJurisdiction.countyCode = countyCode;
									taxJurisdiction.stateCode = stateCode;
									taxJurisdictionList.add(taxJurisdiction);
									
									TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType[] uniDataTaxTypeList = uniDataVtZipCity.getTaxTypeList();
									if (uniDataTaxTypeList != null) {
										for (TC_BridgewareSelectZipGeoCodeRespBean.UniDataTaxType uniDataTaxType : uniDataTaxTypeList) {
											TC_BridgewareTaxJurisdiction rate = new TC_BridgewareTaxJurisdiction();
											rate.city = city;
											rate.county = county;
											rate.state = state;
											rate.cityCode = cityCode;
											rate.countyCode = countyCode;
											rate.stateCode = stateCode;
											rate.rateCodeDescription = uniDataTaxType.getDescription();
											rate.rateCode = uniDataTaxType.getCode();
											rate.stateTaxRate = uniDataTaxType.getStateTaxRate();
											rate.countyTaxRate = uniDataTaxType.getCountyTaxRate();
											rate.countyTransTaxRate = uniDataTaxType.getCountyTransTaxRate();
											rate.cityTaxRate = uniDataTaxType.getCityTaxRate();
											rate.cityTransTaxRate = uniDataTaxType.getCityTransTaxRate();
											String mapKey = city+rate.rateCode;
											rateMap.put(mapKey,rate);
										}
									}
								}
							}
						}
					}
				}
			}
		}
		if(taxJurisdictionList.size() > 0)
			respAssetsRates.put('Assets', taxJurisdictionList);

		if(rateMap != null && rateMap.Values().size() > 0)
			respAssetsRates.put('Rates', rateMap.Values());
		
		return respAssetsRates;
	}

	public static List<Asset__c> updateAssets(Asset__c asset, List<TC_BridgewareTaxJurisdiction> taxJurisdictionList, String fields) {
		try {
			if(taxJurisdictionList.size() == 1){
				Map<String, Object> taxJdr = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(taxJurisdictionList[0]));
				for(String fieldName: fields.split(', ')){
					asset.put(fieldName.split('\\|\\|')[0], taxJdr.get(fieldName.split('\\|\\|')[1]));
				}
			}else if(taxJurisdictionList.size() > 1){
				asset.Multiple_Counties__c = true;
			}
			asset.Tax_Zip_Updated__c = false;
		} catch(Exception ex) { 
			//handleException(ex);
			return null;
		}
		return new List<Asset__c>{asset};
	}

	public static void saveRates(List<TC_BridgewareTaxJurisdiction> rateList, String fields) {
		Set<String> respCodes = new Set<String>();
		List<Rate__c> ratesToInsert = new List<Rate__c>();
		Map<Id, Rate__c> ratesToUpdate = new Map<Id, Rate__c>();
		Map<String, String> existingRates = new Map<String, String>();
		
		for(TC_BridgewareTaxJurisdiction taxJdx : rateList){
			respCodes.add(taxJdx.rateCode+'~'+taxJdx.state+'~'+taxJdx.stateCode+'~'+taxJdx.county+'~'+taxJdx.countyCode+'~'+taxJdx.city+'~'+taxJdx.cityCode);
		}
		for(Rate__c rate : [SELECT Id,Rate_Code__c,State__c,State_Code__c,County__c,County_Code__c,City__c,City_Code__c FROM Rate__c WHERE GeoCodes__c IN :respCodes]){
			existingRates.put(rate.Rate_Code__c+'~'+rate.State__c+'~'+rate.State_Code__c+'~'+rate.County__c+'~'+rate.County_Code__c+'~'+rate.City__c+'~'+rate.City_Code__c, rate.Id);
		}
		for(TC_BridgewareTaxJurisdiction taxJdx : rateList){
			String taxCodesKey = taxJdx.rateCode+'~'+taxJdx.state+'~'+taxJdx.stateCode+'~'+taxJdx.county+'~'+taxJdx.countyCode+'~'+taxJdx.city+'~'+taxJdx.cityCode;
			Map<String, Object> taxJdxMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(taxJdx));
			Rate__c rate = new Rate__c();

			if(existingRates.containsKey(taxCodesKey) && existingRates.get(taxCodesKey) != null){
				rate.Id = existingRates.get(taxCodesKey);
			}
			for(String fieldName: fields.split(', ')){
				rate.put(fieldName.split('\\|\\|')[0], taxJdxMap.get(fieldName.split('\\|\\|')[1]));
			}
			if(rate.Id == null)
				ratesToInsert.add(rate);
			else if(!ratesToUpdate.containsKey(rate.Id)){
				ratesToUpdate.put(rate.Id, rate);
			}
		}
		if(!ratesToInsert.isEmpty())
			insert ratesToInsert;
		if(!ratesToUpdate.values().isEmpty())
			update ratesToUpdate.values();
	}
}