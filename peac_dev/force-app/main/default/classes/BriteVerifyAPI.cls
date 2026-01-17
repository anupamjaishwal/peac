public class BriteVerifyAPI {
    
    public static BriteVerifyResponse verifyEmail(String email) {
        BriteVerifyResponse response = BriteVerifyService.verifyCallout(email);
        return response;
    }

}