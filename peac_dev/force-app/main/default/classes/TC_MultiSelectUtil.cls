public class TC_MultiSelectUtil {
    public static String getFirstValue (String str) {
        if (String.isBlank(str)) return '';
        
        if (str.contains(';')){
            return str.split(';')[0];
        } else {
            return str; // only one value in multi-select
        }
    }
    
    public static Object getFirstValue (Object str) {
        if (str == null) return null;
        return (Object) getFirstValue ((String) str);
    }
}