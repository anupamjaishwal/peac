/*
  @description       : Dynamic DataTable Controller
  @author            : 
  @group             : SL
  @last modified on  : 06/30/23
  @last modified by  : Jonathan Munguia
  @test class        : SL_DataTableController_Test
  Modifications Log 
  Ver   Date       Author             Modification
  1.0   06/30/23   Jonathan Munguia   Initial Version updates.
*/
public with sharing class SL_DataTableController {
  @AuraEnabled(cacheable=true)        
  public static DataTableResponse getSobjectRecords(String sObjectName, String fieldSetName, String sObjectLookupIDField, 
                                                    String additionalWhereClause, String recordId, Boolean includeName,String orderBy){
  //List to hold table headers
  List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
  //Fields to be queried from fieldset
  List<String> lstFieldsToQuery = new List<String>();
  //Final wrapper response to return to component
  DataTableResponse response = new DataTableResponse();    
  //Get the fields from FieldSet
  Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(sObjectName);
  Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();                 
  Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);  
  //Replace NOW() with current datetime                
  if( !String.isEmpty( additionalWhereClause ) ){
    if(additionalWhereClause.contains( 'NOW()' )){
      DateTime currentDateTime  = Datetime.now();
      additionalWhereClause     = additionalWhereClause.replace( 'NOW()' , ':currentDateTime' );
    }
  }
  
  for(Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields()){
    String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
    //This way we can set the type of a column 
    //We do not get the exact type from schema object which matches to lightning-datatable component structure.
    if(dataType == 'datetime'){
      dataType = 'date';
    }
    //Create a wrapper instance and store label, fieldname and type. 
    DataTableColumns datacolumns = new DataTableColumns(String.valueOf(eachFieldSetMember.getLabel()), 
                                                        String.valueOf(eachFieldSetMember.getFieldPath()),
                                                        String.valueOf(eachFieldSetMember.getType()).toLowerCase());
    lstDataColumns.add(datacolumns);
    lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
  }

  String queryStartsWith ='';
  //if Name field is included(option on component)
  if(includeName){
    queryStartsWith = 'SELECT ID, Name, ';
  }else{
    queryStartsWith = 'SELECT ID, ';
  }
  //SOQL Queries for different lists: lists, related lists,filtered lists, and filtered related lists
  String query = '';
    
  if(!lstDataColumns.isEmpty() && String.isEmpty(recordId) && String.isEmpty(additionalWhereClause) && String.isEmpty(sObjectLookupIDField)){ 
    //List                        
    query = queryStartsWith + String.join(lstFieldsToQuery, ',') + ' FROM ' + sObjectName;
  }else if (!lstDataColumns.isEmpty() && String.isEmpty(additionalWhereClause)){
    //Related List
    query = queryStartsWith + String.join(lstFieldsToQuery, ',') + ' FROM ' + sObjectName + ' WHERE ' + 
    sObjectLookupIDField +' = \'' + recordId + '\'';
  }else if (!lstDataColumns.isEmpty() && String.isEmpty(recordId)){
    //Filtered List 
    query = queryStartsWith + String.join(lstFieldsToQuery, ',') + ' FROM ' + sObjectName + ' WHERE ' + additionalWhereClause; 
  }else{ 
    //Filtered Related List
    query = queryStartsWith + String.join(lstFieldsToQuery, ',');

    if(lstFieldsToQuery.isEmpty()){
      query = query.trim().removeEnd(',');
    }
    
    query += ' FROM ' + sObjectName + ' WHERE ' + sObjectLookupIDField + '= \'' +recordId + '\'';
    
    if(!String.isBlank(additionalWhereClause)){
      query +=  ' AND ( '+ additionalWhereClause + ' )';
    }
  }

  query +=  ' WITH SECURITY_ENFORCED';

  if (!String.isEmpty(orderBy)){
    query += ' ORDER BY ' + orderBy;
  }

  response.dataTableData = Database.query(query); 
  response.listColumns = lstDataColumns;
  return response;
  }        
  
  //Wrapper class to hold Columns with headers        
  public class DataTableColumns{
    @AuraEnabled public String label {get;set;}     
    @AuraEnabled public String fieldName {get;set;}
    @AuraEnabled public String type {get;set;} 
    @AuraEnabled public String typeAttributes {get;set;}

    //Create and set variables required by lightning-datatable (label, fieldname, and type)
    public DataTableColumns(String label, String fieldName, String type){
      this.label      = label;
      this.fieldName  = fieldName;
      if(type == 'datetime'){
        this.type = 'date';
      }else if(type == 'date'){
        this.type = 'date-local';
      }
      else{
        this.type = type;
      }
    }
  }

  //Wrapper calss to hold response
  public class DataTableResponse {
    @AuraEnabled
    public List<DataTableColumns> listColumns {get;set;}
    @AuraEnabled
    public List<sObject> dataTableData {get;set;}

    public DataTableResponse(){
      listColumns   = new List<DataTableColumns>();
      dataTableData = new List<sObject>();
    }
  }
}