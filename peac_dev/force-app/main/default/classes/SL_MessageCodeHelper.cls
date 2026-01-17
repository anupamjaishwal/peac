public with sharing class SL_MessageCodeHelper {

    public BusinessHours bHours;
    public Map<String, Decimal> map_OutcomeFollowupDays = new Map<String, Decimal>();
    public Map<String, Message_Code_Config__mdt> configMap = Message_Code_Config__mdt.getAll();
    public SL_MessageCodeHelper(){       
        bHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        getConfigMap();
    }

    private void getConfigMap(){
        if(configMap.size() <= 0) return;
        for(Message_Code_Config__mdt thisConfig : configMap.values()){

            String key = thisConfig.Department__c +'-'+ thisConfig.Call_Outcome__c;
            Decimal value = thisConfig.Follow_up_Days__c;

            map_OutcomeFollowupDays.put(key, value);
        }
    }

    public Datetime getNextWorkingDay(Datetime d){
        return BusinessHours.nextStartDate(bHours.Id, d);
    }

    public Date handleMessageCodes(String department, String callOutcome){
        Date nextFollowupDate = null;
        if(String.isNotBlank(department) && String.isNotBlank(callOutcome)){
            String key = department +'-'+ callOutcome;
            if(map_OutcomeFollowupDays.size() > 0 && map_OutcomeFollowupDays.get(key) != null){
                nextFollowupDate = addBussinessDaysV2(System.today(), (Integer)map_OutcomeFollowupDays.get(key)); // SL-1832 Misael Romero
            }
        }
        return nextFollowupDate;
    }

    public Date addBussinessDays(Date startDate, Integer days){
        Integer count = 0;
        if(days > 0){
            startDate = startDate.addDays(days);
            startDate = getNextWorkingDay(DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 11, 59, 59)).date();
        }else{
            startDate = startDate.addDays(days);
            while (!isWorkingDay(DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 11, 59, 59))) {
                startDate = startDate.addDays(-1);
            }
        }
        
        return startDate;
    }

    public Date addBussinessDaysV2(Date startDate, Integer days){
        Integer count = 0;
        while (count != days)
        {
            startDate = startDate.addDays(1);
            if(isWorkingDay(DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 11, 59, 59)))
            {
                count = count + 1;
            }
        }
        return startDate;
    }

    public Boolean isWorkingDay(Datetime d){
        Datetime workingDay = getNextWorkingDay(d);
        return d.date() == workingDay.date();
        //return BusinessHours.isWithin(bHours.Id, d);
    }
}