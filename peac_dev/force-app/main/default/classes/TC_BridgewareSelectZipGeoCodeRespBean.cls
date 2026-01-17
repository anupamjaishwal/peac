public with sharing class TC_BridgewareSelectZipGeoCodeRespBean {
	private ContentHeader contentHeader;
	private ContentMessage contentMessage;
	private UniDataZipGeoCodeContentData contentData;
	
	public ContentHeader getContentHeader() {
		return contentHeader;
	}

	public void setContentHeader(ContentHeader contentHeader) {
		this.contentHeader = contentHeader;
	}

	public ContentMessage getContentMessage() {
		return contentMessage;
	}

	public void setContentMessage(ContentMessage contentMessage) {
		this.contentMessage = contentMessage;
	}
	
	public UniDataZipGeoCodeContentData getContentData() {
		return contentData;
	}

	public void setContentData(UniDataZipGeoCodeContentData contentData) {
		this.contentData = contentData;
	}
    
	public class ContentHeader {
		private String contentVersion;
		private String status;
		
		public String getContentVersion() {
			return contentVersion;
		}
        
		public void setContentVersion(String contentVersion) {
			this.contentVersion = contentVersion;
		}
        
		public String getStatus() {
			return status;
		}
		
		public void setStatus(String status) {
			this.status = status;
		}
	}
	
	public class ContentMessage {
		private List <String> warnings;
		private List <String> errors;
		
		public List<String> getWarnings() {
			return warnings;
		}
		
		public void setWarnings(List<String> warnings) {
			this.warnings = warnings;
		}
        
		public List<String> getErrors() {
			return errors;
		}
		
		public void setErrors(List<String> errors) {
			this.errors = errors;
		}
	}
    
    public class UniDataZipGeoCodeContentData {
        private UniDataVtZipState[] vtZipStateList;
        
        public UniDataVtZipState[] getVtZipStateList() {
            return vtZipStateList;
        }
        
        public void setVtZipStateList(UniDataVtZipState[] vtZipStateList) {
            this.vtZipStateList = vtZipStateList;
        }
    }

    public class UniDataVtZipState {
        private String description;
        private String code;
        private UniDataVtZipCounty[] vtZipCountyList;
    
        public String getDescription() {
            return description;
        }
        
        public void setDescription(String description) {
            this.description = description;
        }
    
        public String getCode() {
        	return code;
        }
        
        public void setCode(String code) {
            this.code = code;
        }
    
        public UniDataVtZipCounty[] getVtZipCountyList() {
            return vtZipCountyList;
        }
        
        public void setVtZipCountyList(UniDataVtZipCounty[] vtZipCountyList) {
            this.vtZipCountyList = vtZipCountyList;
        }
    }
    
    public class UniDataVtZipCounty {
        private String description;
        private String code;
        private UniDataVtZipCity[] vtZipCityList;
        
        public String getDescription() {
        	return description;
        }
        
        public void setDescription(String description) {
            this.description = description;
        }
        
        public String getCode() {
        	return code;
        }
        
        public void setCode(String code) {
            this.code = code;
        }
        
        public UniDataVtZipCity[] getVtZipCityList() {
            return vtZipCityList;
        }
        
        public void setVtZipCityList(UniDataVtZipCity[] vtZipCityList) {
            this.vtZipCityList = vtZipCityList;
        }
    }

    public class UniDataVtZipCity {
        private String description;
        private String code;
        private UniDataTaxType[] taxTypeList;
    
        public String getDescription() {
        	return description;
        }
        
        public void setDescription(String description) {
            this.description = description;
        }
    
        public String getCode() {
        	return code;
        }
        
        public void setCode(String code) {
            this.code = code;
        }
    
        public UniDataTaxType[] getTaxTypeList() {
            return taxTypeList;
        }
        
        public void setTaxTypeList(UniDataTaxType[] taxTypeList) {
            this.taxTypeList = taxTypeList;
        }
    }
    
    public class UniDataTaxType {
        private String description;
        private String code;
        private double stateTaxRate;
        private double countyTaxRate;
        private double countyTransTaxRate;
        private double cityTaxRate;
        private double cityTransTaxRate;
    
        public String getDescription() {
        	return description;
        }
        
        public void setDescription(String description) {
            this.description = description;
        }
    
        public String getCode() {
        	return code;
        }
        
        public void setCode(String code) {
            this.code = code;
        }
    
        public double getStateTaxRate() {
            return stateTaxRate;
        }
        
        public void setStateTaxRate(double stateTaxRate) {
            this.stateTaxRate = stateTaxRate;
        }
    
        public double getCountyTaxRate() {
            return countyTaxRate;
        }
        
        public void setCountyTaxRate(double countyTaxRate) {
            this.countyTaxRate = countyTaxRate;
        }
    
        public double getCountyTransTaxRate() {
            return countyTransTaxRate;
        }
        
        public void setCountyTransTaxRate(double countyTransTaxRate) {
            this.countyTransTaxRate = countyTransTaxRate;
        }
    
        public double getCityTaxRate() {
            return cityTaxRate;
        }
        
        public void setCityTaxRate(double cityTaxRate) {
            this.cityTaxRate = cityTaxRate;
        }
    
        public double getCityTransTaxRate() {
            return cityTransTaxRate;
        }
        
        public void setCityTransTaxRate(double cityTransTaxRate) {
            this.cityTransTaxRate = cityTransTaxRate;
        }
    }
    
	public static TC_BridgewareSelectZipGeoCodeRespBean createResponseBeanFromJson (String jsonString) {
		TC_BridgewareSelectZipGeoCodeRespBean respBean = (TC_BridgewareSelectZipGeoCodeRespBean) JSON.deserialize(
               jsonString, TC_BridgewareSelectZipGeoCodeRespBean.class);
		return respBean;
	}

    public static TC_BridgewareSelectZipGeoCodeRespBean createResponseBeanFromXml (String jsonString) {
		TC_BridgewareSelectZipGeoCodeRespBean respBean = new TC_BridgewareSelectZipGeoCodeRespBean();
        Map<String, String> il10Object = (Map<String, String>)JSON.deserialize(
               jsonString, Map<String, String>.class);
        String xmlString = il10Object.get('taxCode');
        System.debug('xml String: '+ xmlString);
        if(xmlString != null){
            xmlString = xmlString.replaceAll('\\\\/', '/').replaceAll('\\\\r\\\\n', '\r\n').replaceAll('\\\\"', '"');
            Dom.Document docx = new Dom.Document();
            docx.load(xmlString);
            
            dom.XmlNode xroot = docx.getrootelement();
            System.debug('XML root: '+ xroot);
            Dom.XmlNode contentHeaderElement = xroot.getChildElement('ContentHeader', null); 
            String contentVersion = contentHeaderElement.getChildElement('MethodVersion', null).getText();
            String status = contentHeaderElement.getChildElement('Status', null).getText();
            ContentHeader contentHeaderObj = new ContentHeader();
            contentHeaderObj.setContentVersion(contentVersion);
            contentHeaderObj.setStatus(status);
            respBean.setContentHeader(contentHeaderObj);
            Dom.XmlNode contentMessageElement = xroot.getChildElement('ContentMessage', null);
            Dom.XmlNode errorsNode = contentMessageElement.getChildElement('Errors', null);
            List<String> errors = new List<String>();
            if(errorsNode != null){
                for(Dom.XmlNode errorElement :errorsNode.getChildElements()){
                    errors.add(errorElement.getText());
                }
            }
            Dom.XmlNode warningsNode = contentMessageElement.getChildElement('Warnings', null);
            List<String> warnings = new List<String>();
            if(warningsNode != null){
                for(Dom.XmlNode warningElement :warningsNode.getChildElements()){
                    errors.add(warningElement.getText());
                }
            }
            ContentMessage contentMessageObj = new ContentMessage();
            contentMessageObj.setErrors(errors);
            contentMessageObj.setWarnings(warnings);
            respBean.setContentMessage(contentMessageObj);
            List<UniDataVtZipState> vtZipStateList = new List<UniDataVtZipState>();
            List<UniDataVtZipCounty> vtZipCountyList = new List<UniDataVtZipCounty>();
            List<UniDataVtZipCity> vtZipCityList = new List<UniDataVtZipCity>();
            List<UniDataTaxType> taxTypeList = new List<UniDataTaxType>();
            Dom.XmlNode contentDataElement = xroot.getChildElement('ContentData', null);
            Dom.XmlNode vtZipStateElement = contentDataElement?.getChildElement('VtZipState', null);
            if(vtZipStateElement != null){
                UniDataVtZipState vtZipStateObj = new UniDataVtZipState();
                vtZipStateObj.setCode(vtZipStateElement.getAttributeValue('Code', null));
                vtZipStateObj.setDescription(vtZipStateElement.getAttributeValue('Description', null));
                Dom.XmlNode vtZipCountyElement = vtZipStateElement.getChildElement('VtZipCounty', null);
                if(vtZipCountyElement != null){
                    UniDataVtZipCounty vtZipCountyObj = new UniDataVtZipCounty();
                    vtZipCountyObj.setCode(vtZipCountyElement.getAttributeValue('Code', null));
                    vtZipCountyObj.setDescription(vtZipCountyElement.getAttributeValue('Description', null));
                    List<Dom.XmlNode> vtZipCityElement = vtZipCountyElement.getChildElements();
                    System.Debug('System List Elements City: '+ vtZipCountyElement.getChildElements());
                    System.debug('Zip City Element: '+ vtZipCityElement);
                    if(vtZipCityElement != null){
                        for(Dom.XmlNode cityChild : vtZipCityElement){
                            UniDataVtZipCity vtZipCityObj = new UniDataVtZipCity();
                        	vtZipCityObj.setCode(cityChild.getAttributeValue('Code', null));
                        	vtZipCityObj.setDescription(cityChild.getAttributeValue('Description', null));
                        	for(Dom.XmlNode childElement :cityChild.getChildElements()){
                            	if(childElement.getName() == 'TaxType'){
                                	UniDataTaxType taxTypeItem = new UniDataTaxType();
                                	taxTypeItem.setCode(childElement.getAttributeValue('Code', null));
                                	taxTypeItem.setDescription(childElement.getAttributeValue('Description', null));
                                	taxTypeItem.setStateTaxRate(Double.valueOf(childElement.getChildElement('StateTaxRate', null).getText()));
                                	taxTypeItem.setCountyTaxRate(Double.valueOf(childElement.getChildElement('CountyTaxRate', null).getText()));
                                	taxTypeItem.setCountyTransTaxRate(Double.valueOf(childElement.getChildElement('CountyTransTaxRate', null).getText()));
                                	taxTypeItem.setCityTaxRate(Double.valueOf(childElement.getChildElement('CityTaxRate', null).getText()));
                                	taxTypeItem.setCityTransTaxRate(Double.valueOf(childElement.getChildElement('CityTransTaxRate', null).getText()));
                                	taxTypeList.add(taxTypeItem);
                            	}
                        	}
                        	vtZipCityObj.setTaxTypeList(taxTypeList);
                        	vtZipCityList.add(vtZipCityObj);
                        } 
                        
                    }
                    vtZipCountyObj.setVtZipCityList(vtZipCityList);
                    vtZipCountyList.add(vtZipCountyObj);
                }
                vtZipStateObj.setVtZipCountyList(vtZipCountyList);
                vtZipStateList.add(vtZipStateObj);
            }
            UniDataZipGeoCodeContentData contentDataObj = new UniDataZipGeoCodeContentData();
            contentDataObj.setVtZipStateList(vtZipStateList);
            
            respBean.setContentData(contentDataObj);
        }
		return respBean;
	}
}