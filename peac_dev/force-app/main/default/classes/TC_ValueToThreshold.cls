public class TC_ValueToThreshold {
public static String valueToThreshold (Decimal value) {
        if (value == null || value < 250000) {
            return null;
        } else if (value < 500000) {
            return '$250K';
        } else if (value < 1000000) {
            return '$500K';
        } else if (value < 2500000) {
            return '$1MM';
        } else if (value < 5000000) {
            return '$2.5MM';
        } else if (value < 10000000) {
            return '$5MM';
        } else {
            return '$10MM';
        }
    }
}