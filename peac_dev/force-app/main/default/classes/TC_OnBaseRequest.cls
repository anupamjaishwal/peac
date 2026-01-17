public class TC_OnBaseRequest {
    
    private static OnBase_Credentials__c creds = OnBase_Credentials__c.getOrgDefaults ();
    
    public static String getAddDocumentUrl () {
        return creds.Gateway_Url__c + creds.Add_Document__c;
    }
    
    public static String getHeader () {
        
        String credString = '{0},{1},{2},{3}';
        
        credString = String.format (credString
                                    , new List <String> {
                                         creds.Username__c
                                        , creds.Password__c
                                        , creds.App_Server_Url__c
                                        , creds.Data_Source__c});

		Blob bval = Blob.valueOf (EncodingUtil.base64Encode (Blob.valueOf (credString)));
        
		Blob input  = Crypto.encrypt('AES256', Blob.valueOf(creds.Secret_Key__c), Blob.valueOf (creds.Initialization_Vector__c), bval);
        return EncodingUtil.base64Encode (input);
    }

}