/**
 * BusinessDays Class
 * Use this class to operate only on business days 
 * and easily skip weekends and holidays from your logic
 * @author - rsirivella
 * */
public class BusinessDays
{
    
    //retrieves & assign the Organization level Business Hours to defaultBH 
    @testVisible static BusinessHours defaultBH
    {
        get
        {
            if (defaultBH == null)
                defaultBH = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
            return defaultBH;
        }
        private set;
    }
        
    public static Boolean isWithin()
    {
        return isWithin(Datetime.now());
    }
    
    public static Boolean isWithin(Datetime input)
    {        
        return BusinessHours.isWithin(defaultBH.Id, input);
    }

    public static  Datetime nextStartDate()
    {
        return nextStartDate(Datetime.now());
    }
  
    public static Datetime nextStartDate(Datetime input)
    {
  		return BusinessHours.nextStartDate(defaultBH.Id, input);
    }
   
    public static Datetime getSLATimeByBusinessHour (DateTime input, Integer SLAhours)
    {        
        return BusinessHours.add(defaultBH.Id,input, SLAhours* 60 * 60 * 1000L);
    }
}