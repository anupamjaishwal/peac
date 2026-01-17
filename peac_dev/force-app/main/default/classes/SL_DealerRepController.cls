/*******************************
* @Author       Jonathan Munguia
* @Date         06/23/23
* @Group        Silverline
* @TestClass    SL_DealerRepController_Test.
* @Description  Controller of LWC SL_DealerReps
*				Additional comments 
*******************************/
/* MODIFICATION LOG
* Version     Developer          Date      Description
*  1.0.0   Jonathan Munguia    06/23/23   Initial Version                                    
*******************************/
public without sharing class SL_DealerRepController {

  /**
   * @Description: Method to fetch the Dealers Reps assign to an Account.
   * @param   accountId      Account Id.
   * @param   fieldAPINames  API Names of fields to retrieve.
   * @return  List<Account>.
   * History
   *<Date>      <Authors Name>      Description
    06/23/23   Jonathan Munguia    Initial Version.
  */
  @AuraEnabled(cacheable=true)
  public static List<Account> getDealerRep(Id accountId, String fieldAPINames) {
    
    if(fieldAPINames == null || fieldAPINames == ''){
      return null;
    }

    String fields = String.escapeSingleQuotes(fieldAPINames);
    List<String> fieldsToRetrieve = fields.split(',');
    String query = 'SELECT ';
    
    for(String field :fieldsToRetrieve){
      query += String.escapeSingleQuotes(field) + ',';
    }
    query = query.removeEnd(',') + ' FROM Account WHERE Id = :accountId';

    return Database.query(query);
  }
}