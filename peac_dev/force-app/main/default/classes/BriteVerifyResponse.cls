public class BriteVerifyResponse {
    
    // https://support.briteverify.com/en/articles/766617-real-time-email-api
    public String address;
    public String account;
    public String domain;
    public String status;
    public String disposable;
    public String role_address;
    public String duration;
    
    public String error_code;
    public String error;
    
    public BriteVerifyResponse() {}
    
/*
SUCCESS
{
    "address": "johndoe@briteverify.com",
    "account": "johndoe",
    "domain": "briteverify.com",
    "status": "valid",
    "disposable": false,
    "role_address": false,
    "duration": 0.104516605
}

ERROR
{
    "address": "james@yahoo.com",
    "account": "james",
    "domain": "yahoo.com",
    "status": "invalid",
    "error_code": "email_account_invalid",
    "error": "Email account invalid",
    "disposable": false,
    "role_address": false,
    "duration": 0.141539548
}
*/

}