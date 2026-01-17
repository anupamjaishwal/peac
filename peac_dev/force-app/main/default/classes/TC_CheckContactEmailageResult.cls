public class TC_CheckContactEmailageResult {
public static Boolean checkContactEmailageResult (String emailageResult, Boolean overrideEmailageResult) {
        return (emailageResult == 'FAIL' && !overrideEmailageResult);
    }
}