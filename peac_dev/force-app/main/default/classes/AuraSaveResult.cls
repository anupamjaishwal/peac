/**
 * This class is provided open source under the MIT license
 * Class for aura save result.
 */
global without sharing class AuraSaveResult {

    @AuraEnabled global List<ErrorResult> errors {Get;Set;}
    @AuraEnabled global Id resultId {Get;Set;}
    @AuraEnabled public Boolean isSuccessful {Get;Set;}

    global AuraSaveResult(){}
    global AuraSaveResult(Database.SaveResult sr) {
        this.resultId = sr.getId();
        this.isSuccessful = sr.isSuccess();
        this.errors = new List<ErrorResult>();
        if (sr.getErrors() != null) {
            for (Database.Error error : sr.getErrors()) errors.add(new ErrorResult(error));
        }
    }

    global AuraSaveResult(Exception e) {
        this.isSuccessful = false;
        this.errors = new List<ErrorResult>();
        this.errors.add(new ErrorResult(e.getMessage(),e.getTypeName()));
    }

    /**
     * Adds a custom error message to the save results
     *
     * @param      errorMessage  The error message
     * @param      sobjectName   The sobject name
     *
     * @return     The activity save result
     */
    global static AuraSaveResult customSaveResultError(String errorMessage, String sobjectName) {
        AuraSaveResult returnObject = new AuraSaveResult();
        returnObject.isSuccessful = false;
        returnObject.errors = new List<ErrorResult>();
        ErrorResult error = new ErrorResult();

        if (String.isNotBlank(sobjectName)) error.message = String.format(errorMessage, new List<String>{sobjectName});
        if (String.isBlank(sobjectName)) error.message = errorMessage;
        returnObject.errors.add(error);
        return returnObject;
    }

    global static List<AuraSaveResult> getSaveResults(List<Database.SaveResult> srs) {
        List<AuraSaveResult> returnList = new List<AuraSaveResult>();

        for (Database.SaveResult sr : srs) {
            returnList.add(new AuraSaveResult(sr));
        }

        return returnList;
    }

    /**
     * Class for error result.
     * Contains the errors that are reported after a save result
     */
    global class ErrorResult {
        @AuraEnabled global List<String> fields {Get;Set;}
        @AuraEnabled global String message {Get;Set;}
        @AuraEnabled global String statusCode {Get;Set;}

        global ErrorResult() {}
        global ErrorResult(Database.Error error) {
            this.fields = error.getFields();
            this.message = error.getMessage();
            this.statusCode = String.valueOf(error.getStatusCode());
        }
        global ErrorResult(String msg, String code) {
            this.message = msg;
            this.statusCode = code;
        }
    }
}