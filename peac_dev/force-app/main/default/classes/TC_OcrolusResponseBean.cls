/**
 * Created by tamarack on 2019-07-26.
 */

public with sharing class TC_OcrolusResponseBean {

    public String status;
    public String message;
    public Response response;
    //public IntegrationLog log;

    // Add Book: Successfully created
    public class Response {
        public String name;
        public String pk;
        public String status;
        public String message;
        public String created;
    }

    /*public class IntegrationLog {
        public String logName;
        public String parentId;
        public Boolean error;
        public String reqBody;
        public String respStr;
        public String status;
        public String message;

        public IntegrationLog(String name, Id id, Boolean bool, String req, String resp, String status, String msg) {

            this.logName = name;
            this.parentId = id;
            this.error = bool;
            this.reqBody = req;
            this.respStr = resp;
            this.status = status;
            this.message = msg;

        }

    }*/

}