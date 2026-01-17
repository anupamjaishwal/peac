/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: Mock class.
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

global class TC_BridgewareSelectZipGeoCalloutMockImpl implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        if(req.getEndpoint().contains('/selectZipGeoCode') && il10Setting.use_IL10__c){
            resp.setBody('{"taxCode":"<Body>\\r\\n<ContentHeader>\\r\\n<MethodVersion>6.5.30<\\/MethodVersion>\\r\\n<ZipCode>55378<\\/ZipCode>\\r\\n<RequestUserId><![CDATA[]]><\\/RequestUserId>\\r\\n<Status>Success<\\/Status>\\r\\n<\\/ContentHeader>\\r\\n<ContentData>\\r\\n<VtZipState Code=\\"24\\" Description=\\"MINNESOTA\\">\\r\\n<VtZipCounty Code=\\"139\\" Description=\\"SCOTT\\">\\r\\n<VtZipCity Code=\\"1300\\" Description=\\"SAVAGE\\">\\r\\n<TaxType Code=\\"001\\" Description=\\"USE TAX\\">\\r\\n<StateTaxRate>6.875<\\/StateTaxRate>\\r\\n<CountyTaxRate>0.000<\\/CountyTaxRate>\\r\\n<CountyTransTaxRate>1.500<\\/CountyTransTaxRate>\\r\\n<CityTaxRate>0.000<\\/CityTaxRate>\\r\\n<CityTransTaxRate>0.000<\\/CityTransTaxRate>\\r\\n<\\/TaxType><TaxType Code=\\"100\\" Description=\\"SALES TAX\\">\\r\\n<StateTaxRate>6.875<\\/StateTaxRate>\\r\\n<CountyTaxRate>0.000<\\/CountyTaxRate>\\r\\n<CountyTransTaxRate>1.500<\\/CountyTransTaxRate>\\r\\n<CityTaxRate>0.000<\\/CityTaxRate>\\r\\n<CityTransTaxRate>0.000<\\/CityTransTaxRate>\\r\\n<\\/TaxType><TaxType Code=\\"150\\" Description=\\"RENTAL TAX\\">\\r\\n<StateTaxRate>6.875<\\/StateTaxRate>\\r\\n<CountyTaxRate>0.000<\\/CountyTaxRate>\\r\\n<CountyTransTaxRate>1.500<\\/CountyTransTaxRate>\\r\\n<CityTaxRate>0.000<\\/CityTaxRate>\\r\\n<CityTransTaxRate>0.000<\\/CityTransTaxRate>\\r\\n<\\/TaxType><\\/VtZipCity>\\r\\n<\\/VtZipCounty>\\r\\n<\\/VtZipState>\\r\\n<\\/ContentData>\\r\\n<ContentMessage>\\r\\n<\\/ContentMessage>\\r\\n<\\/Body>\\r\\n"}');
        }else{
            resp.setBody('{"responseMessageDesc":"Successful","statusMessage":"Success","contentHeader":{"contentVersion":"contentVersion","status":"status"},"contentMessage":null,"contentData":{"vtZipStateList":[{"description":"MINNESOTA","code":"24","vtZipCountyList":[{"description":"RAMSEY","code":"123","vtZipCityList":[{"description":"PARKWAY JUNCTION","code":"2884","taxTypeList":[{"description":"Use Tax","code":"001","stateTaxRate":6.875,"countyTaxRate":0.0,"countyTransTaxRate":0.25,"cityTaxRate":0.0,"cityTransTaxRate":0.0},{"description":"Sales Tax","code":"100","stateTaxRate":6.875,"countyTaxRate":0.0,"countyTransTaxRate":0.25,"cityTaxRate":0.0,"cityTransTaxRate":0.0},{"description":"Rental Tax","code":"150","stateTaxRate":6.875,"countyTaxRate":0.0,"countyTransTaxRate":0.25,"cityTaxRate":0.0,"cityTransTaxRate":0.0}]}]},{"description":"WASHINGTON","code":"163","vtZipCityList":[{"description":"WOODBURY","code":"1740","taxTypeList":[{"description":"Use Tax","code":"001","stateTaxRate":6.875,"countyTaxRate":0.0,"countyTransTaxRate":0.25,"cityTaxRate":0.0,"cityTransTaxRate":0.0},{"description":"Sales Tax","code":"100","stateTaxRate":6.875,"countyTaxRate":0.0,"countyTransTaxRate":0.25,"cityTaxRate":0.0,"cityTransTaxRate":0.0},{"description":"Rental Tax","code":"150","stateTaxRate":6.875,"countyTaxRate":0.0,"countyTransTaxRate":0.25,"cityTaxRate":0.0,"cityTransTaxRate":0.0}]}]}]}]}}');
        }
        
        return resp;
    }
}