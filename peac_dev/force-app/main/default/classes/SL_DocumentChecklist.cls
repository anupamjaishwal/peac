public class SL_DocumentChecklist {

	 public class ResultsWrapper
    {
        @AuraEnabled
        public map<Id,Id> lstcontentDocID       				{get;set;}
        @AuraEnabled
        public list<DocumentStatus__c> lstDocumentStatus     	{get;set;}
       
        //Constructor
        public ResultsWrapper(map<Id,Id> lstcontentDocID ,list<DocumentStatus__c> lstDocumentStatus ) {
            this.lstcontentDocID= lstcontentDocID;
            this.lstDocumentStatus= lstDocumentStatus;
        }
    }

	@AuraEnabled 
    public static String linkFileToRelatedRec(String caseID, String OppId, String DocId, String DocStatusID){
        list<ContentDocumentLink> lstConDockLink = new List<ContentDocumentLink>();
        if( caseID != null && caseID != ''){
            ContentDocumentLink objConDocLink = new ContentDocumentLink();
            objConDocLink.ContentDocumentId = DocId;
            objConDocLink.LinkedEntityId = caseID;
            objConDocLink.ShareType = 'V';
            lstConDockLink.add(objConDocLink);
        }
        if( OppId != null && OppId != ''){
            ContentDocumentLink objConDocLink = new ContentDocumentLink();
            objConDocLink.ContentDocumentId = DocId;
            objConDocLink.LinkedEntityId = OppId;
            objConDocLink.ShareType = 'V';
            lstConDockLink.add(objConDocLink);
        }
        if(! lstConDockLink.isEmpty()){
            try{
            INSERT lstConDockLink;
            // fill the Document_Status_Record__c  
            updateLookUp(DocId, DocStatusID);
            }catch (Exception e){
                return 'FAILED';
            }
        }
       return 'SUCCESS';
    }
    @AuraEnabled
     public static void updateLookUp(String DocId,String DocStatusID){
        
        ContentVersion objCV = [Select Id,Document_Status_Record__c from ContentVersion where ContentDocumentId =: DocId ];
        ContentVersion obJNewCv = new ContentVersion();
        obJNewCv.Id = objCV.Id;
        obJNewCv.Document_Status_Record__c = DocStatusID;
        
        update obJNewCv;
        
    }

	@AuraEnabled 
	public static String updateFile(ID DocID, ID ObjId){
        
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = DocID;
		cdl.LinkedEntityId = ObjId;
		cdl.ShareType = 'V';
		insert cdl;
		return 'SUCCESS';
	}
	
    @AuraEnabled 
	public static String SaveRecord(String name, String descption, String status, ID contentID, 
									ID recordId, String ObjectName) {
		DocumentStatus__c objDoc = new DocumentStatus__c();
		objDoc.Name = name;
		objDoc.Description__c = descption;
		objDoc.Status__c = status;
		if(ObjectName.equals('Case')){
			objDoc.Case__c = recordId;
		}else if(ObjectName.equals('Opportunity')){
			objDoc.Opportunity__c = recordId;
		}else if(ObjectName.equals('Contract_Asset__c')){
			objDoc.Contract_Asset__c = recordId;
		}
		insert objDoc;

		if( contentID != null){
            updateLookUp(contentID,objDoc.Id);
            
			String res = updateFile(contentID, objDoc.Id);
		}
		return 'SUCCESS';
	}

	@AuraEnabled
    public static String updateRecord( String jsonObjArr) {
        try {
            //System.debug('jsonObjArr::::::'+jsonObjArr);
            String jsonObj = '['+jsonObjArr+']';
            Type listType = Type.forName('List<DocumentStatus__c>');
            List<SObject> objs = (List<SObject>)JSON.deserialize(jsonObj, listType);
            //System.debug('objs::::>>'+objs);
            update objs;
        } catch (Exception e) {
            return '[{"data":' + jsonObjArr + ',"message":"' + e.getMessage() + '","cause":"' + e.getCause() + '","typeName":"' + e.getTypeName() + '"}]';
        }
        return 'success';
    }
    public class fieldsWrapper{
    	@AuraEnabled
        public String label       				{get;set;}
        @AuraEnabled
        public String fieldApi  				{get;set;}
        @AuraEnabled
        public String order 					{get;set;}
        @AuraEnabled
        public Boolean readOnly 				{get;set;}
        @AuraEnabled 
        public Boolean sortable					{get;set;}
        @AuraEnabled 
        public String type						{get;set;}
        @AuraEnabled
        public Boolean isEditable               {get;set;}
        @AuraEnabled 
        public list<map<string,string>> fldValue {get;set;}

        public fieldsWrapper(String label, String fieldApi, String order, Boolean readOnly, Boolean sortable, String type, Boolean isEditable, list<map<string,string>> fldValue){
        	this.label = label;
        	this.fieldApi = fieldApi;
        	this.order = order;
        	this.readOnly = readOnly;
        	this.sortable = sortable;
        	this.type = type;
        	this.fldValue = fldValue;
            this.isEditable = isEditable;
        }
    }
     public class fieldResultWrapper{
    	@AuraEnabled
        public List<fieldsWrapper> lstFields			{get;set;}
        @AuraEnabled
        public List<String> lstQuryFields				{get;set;}       

        public fieldResultWrapper(List<fieldsWrapper> lstFields, List<String> lstQuryFields){
        	this.lstFields = lstFields;
        	this.lstQuryFields = lstQuryFields;
        }
    }
    @AuraEnabled
    public static fieldResultWrapper getColumns() {
    	list<fieldsWrapper> lstFields = new list<fieldsWrapper>();
    	List<String> lstQuryFields = new List<String>();
    	lstFields.add(new fieldsWrapper('','ICON', '0', false, false, 'ICON', true, NULL));
    	Map<String, Schema.SObjectType> gdMap = Schema.getGlobalDescribe();
        Schema.Describesobjectresult rootObj = gdMap.get('DocumentStatus__c').getDescribe();
        Map<String, Schema.SObjectField> rootFldMap = rootObj.fields.getMap();
        
        Set<String> setEditableFields = getCreatableFields('DocumentStatus__c');

    	list<DocumentStatusColumn__mdt> lstColumns = [SELECT DisplayName__c, DocumentStatusAPIname__c, Order__c, ReadOnly__c, Sort__c
														FROM  DocumentStatusColumn__mdt 
														ORDER BY Order__c ASC];
															
		for(DocumentStatusColumn__mdt objCol : lstColumns){
			String type;
            String fieldApi = objCol.DocumentStatusAPIname__c;
			if(rootFldMap.containsKey(objCol.DocumentStatusAPIname__c)){
				type = String.valueOf(rootFldMap.get( objCol.DocumentStatusAPIname__c).getDescribe().getType());
			}else{
				type = '';
			}
			if(type == 'PICKLIST'){
				lstFields.add(new fieldsWrapper(objCol.DisplayName__c, objCol.DocumentStatusAPIname__c, objCol.Order__c, objCol.ReadOnly__c, objCol.Sort__c, type, setEditableFields.contains(fieldApi),getselectOptions(objCol.DocumentStatusAPIname__c)));
				lstQuryFields.add(objCol.DocumentStatusAPIname__c);
			}else if(type == 'REFERENCE'){
				if(objCol.DocumentStatusAPIname__c.endsWith('__c')){
                    String objApi = objCol.DocumentStatusAPIname__c.replace('__c','__r.Name');
                   	lstFields.add(new fieldsWrapper(objCol.DisplayName__c,objApi, objCol.Order__c, objCol.ReadOnly__c, objCol.Sort__c, type, setEditableFields.contains(fieldApi),null));
                	lstQuryFields.add(objApi);

                }else if(objCol.DocumentStatusAPIname__c.endsWith('Id')){
                   	String objApi = objCol.DocumentStatusAPIname__c.replace('Id','.Name');
                   	lstFields.add(new fieldsWrapper(objCol.DisplayName__c,objApi, objCol.Order__c, objCol.ReadOnly__c, objCol.Sort__c, type, setEditableFields.contains(fieldApi), null));
                   	lstQuryFields.add(objApi);
                   	
                }else{
                	lstFields.add(new fieldsWrapper(objCol.DisplayName__c, objCol.DocumentStatusAPIname__c, objCol.Order__c, objCol.ReadOnly__c, objCol.Sort__c, type, setEditableFields.contains(fieldApi), null));
					lstQuryFields.add(objCol.DocumentStatusAPIname__c);
                }
            }else{
                	lstFields.add(new fieldsWrapper(objCol.DisplayName__c, objCol.DocumentStatusAPIname__c, objCol.Order__c, objCol.ReadOnly__c, objCol.Sort__c, type, setEditableFields.contains(fieldApi), null));
					lstQuryFields.add(objCol.DocumentStatusAPIname__c);
            }
		}
        lstFields.add(new fieldsWrapper('Document', 'documentReview', '999', true, false, 'REVIEW', false, null));
		return new fieldResultWrapper(lstFields, lstQuryFields);
	}
	@AuraEnabled 
	public static list<map<string,string>> getselectOptions(String fieldApi) {
        
        list<map<string,string>> options = new list<map<string,string>>();

        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get('DocumentStatus__c').getDescribe().Fields.getMap();
        list<Schema.PicklistEntry> values = fieldMap.get(fieldApi).getDescribe().getPickListValues();

        options.add(new map<string,string>{'class' => 'optionClass', 'label' => '--None--', 'value' => ''});
       
        for (Schema.PicklistEntry a: values) {
            options.add(new map<string,string>{'class' => 'optionClass', 'label' => a.getLabel(), 'value' => a.getValue()});
        }
        return options;
    }

    @AuraEnabled 
	public static ResultsWrapper getrecords(Id recordId,String ObjectName, List<String> lstFields){
		list<DocumentStatus__c> lstDocumentStatus = new list<DocumentStatus__c>();
		if(lstFields.indexOf('Case__c') == -1){
            lstFields.add('Case__c');
        }
        if(lstFields.indexOf('Opportunity__c') == -1){
            lstFields.add('Opportunity__c');
        }
        if(lstFields.indexOf('Contract_Asset__c') == -1){
            lstFields.add('Contract_Asset__c');
        }

		String strQuery = 'SELECT '+String.join(lstFields,',');
		strQuery += ' FROM DocumentStatus__c ';

		if(ObjectName.equals('Case')){
			//lstDocumentStatus = [SELECT Id, Name,Case__c, Opportunity__c, Required__c, LastModifiedDate, Status__c, Type__c, Description__c, Year__c 
			//					FROM DocumentStatus__c
			//					WHERE Case__c =: recordId];
			strQuery += 'WHERE Case__c =\''+recordId+'\'';

		}else if(ObjectName.equals('Opportunity')){
			strQuery += 'WHERE Opportunity__c =\''+recordId+'\'';
			//lstDocumentStatus = [SELECT Id, Name,Case__c, Opportunity__c, Required__c, LastModifiedDate, Status__c, Type__c, Description__c, Year__c 
			//					FROM DocumentStatus__c
			//					WHERE Opportunity__c =: recordId];
		}else if(ObjectName.equals('Contract_Asset__c')){
			strQuery += 'WHERE Contract_Asset__c =\''+recordId+'\'';
		}
		//System.debug('strQuery>>>>>'+strQuery);
		lstDocumentStatus = Database.query(strQuery);
		set<ID> setIds = new set<Id>();
		for(Sobject obj :lstDocumentStatus){
			setIds.add(obj.Id);
		}
		list<ContentDocumentLink> lstrecord = [SELECT id, ContentDocumentId, LinkedEntityId
												FROM ContentDocumentLink 
												WHERE LinkedEntityId =:setIds];
		
		map<Id,Id> lstcontentDocID = new map<Id,Id>();
		for(ContentDocumentLink objRec : lstrecord){
			lstcontentDocID.put(objRec.LinkedEntityId,objRec.ContentDocumentId);
		} 
		return new ResultsWrapper(lstcontentDocID, lstDocumentStatus);
	}

    @TestVisible
    private static Set<String> getCreatableFields(String objectName) {
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName).getDescribe().Fields.getMap();
        
        Set<String> setEditableFields = new Set<String>();
        for (Schema.SObjectField ft : fMap.values()){
            Schema.DescribeFieldResult fd = ft.getDescribe();
            
            if (fd.isCreateable() && fd.isUpdateable())
                setEditableFields.add(fd.getName());
        }
        return setEditableFields;
    }	
    @AuraEnabled
    public static void  deleteFile(String DocId){
   
    ContentDocument objCV = [SELECT id from ContentDocument where id =: DocId];
    
    Delete objCV;
    }						
}