public class TC_DateTimeFormatter {
    public static Datetime gdsFormat (String dateString) {        
        if (String.isBlank(dateString)) return null;
        List <String> stringSplit = dateString.split('T');
        if (stringSplit.size() < 3) return null;

        List <String> dateSplit = stringSplit[0].split ('-');
        List <String> timeSplit = stringSplit[1].split (':');

        Datetime toBeFormatted = Datetime.newInstance (Integer.valueOf (dateSplit[0]),Integer.valueOf (dateSplit[1]),Integer.valueOf (dateSplit[2]),Integer.valueOf (timeSplit[0]),Integer.valueOf (timeSplit[1]),Integer.valueOf (timeSplit[2].remove('Z')));
		return toBeFormatted;
    }
    
    public static Datetime gdsFormatPlatformEvent (String dateString) {

        if (!String.isBlank(dateString)) {
            List <String> stringSplit = dateString.split('T');
            if (stringSplit.size() < 3) return null;
            List <String> dateSplit = stringSplit[0].split ('-');
            List <String> timeSplit = stringSplit[1].split (':');

            Datetime toBeFormatted = Datetime.newInstance (Integer.valueOf (dateSplit[0]),Integer.valueOf (dateSplit[1]),Integer.valueOf (dateSplit[2]),Integer.valueOf (timeSplit[0]),Integer.valueOf (timeSplit[1]),Integer.valueOf (timeSplit[2].remove('Z')));
            toBeFormatted = toBeFormatted.addHours(-3);
            return toBeFormatted;
        } else {
            return null;
        }
    }

}