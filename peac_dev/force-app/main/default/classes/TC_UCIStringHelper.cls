/*
 * @author : sfdcdev, Tamarack Consulting, Inc.
 * @date : 03/09/2015
 * @description: 
 *
 * © Copyright 2003 - 2015 Tamarack Consulting, Inc.  All Rights Reserved.
 * 
 */

public class TC_UCIStringHelper {
	public static final String fieldSeparator = '|';
	private static final String multipleValueSeparator = '^';
	//private static final SimpleDateFormat dateFormat = new SimpleDateFormat('MM-dd-yyyy');
	
	public static String value(Object field) {
		String value = fieldSeparator;
		
		if (field != null) {
			if (field instanceof List<Object>) {
				List<Object> fieldList = (List<Object>) field;
				
				if (fieldList != null && fieldList.size() > 0) {
					for (Object f : fieldList) {
						if (f != null) {
                            if (f instanceof Date) {
                                Date d = (Date) f;
                                value += d.month() + '/' + d.day() + '/' + d.year();
                            }
                            else if (f instanceof Boolean) {
                                Boolean b = (Boolean) f;
								value += b ? '1' : '0';
                            }
							else
								value += f;
						}
						
						value += multipleValueSeparator;
					}
					
					value = value.substring(0, value.length() - 1);
				}
			}
            else if (field instanceof Date) {
                Date d = (Date) field;
                value += d.month() + '/' + d.day() + '/' + d.year();
            }
            else if (field instanceof Boolean) {
                Boolean b = (Boolean) field;
                value += b ? '1' : '0';
            }
			else
				value += field;
		}
		
		return value;
	}
    
    public static String monthYearValue(Date field) {
        String value = '';
        
        if (field != null) {
            value += (field.month() < 10 ? '0' : '') + field.month() + '' + field.year();
        }
		
		return value;
    }
}