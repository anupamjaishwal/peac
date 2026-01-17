public class TC_CreateThresholdKey {
public static String createThresholdKey (Id accId, String thresh) {
        return accId + '-' + thresh;
    }
}