public class TC_TriggerContext {
    
    private Map <Id, SObject> oldMap;
    private Map <Id, SObject> newMap;
    private List <SObject> newList;
    private System.TriggerOperation operationType;
    private String sobjectType;
    
    public TC_TriggerContext (Map <Id, SObject> oldMap, Map <Id, SObject> newMap, List <SObject> newList, System.TriggerOperation operationType, String sobjectType) {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.newList = newList;
        this.operationType = operationType;
        this.sobjectType = sobjectType;
    }
    
    // less of a footprint in the trigger
    public Boolean isAfter () {
        return String.valueOf (this.operationType).containsIgnoreCase ('after');
    }
    public Boolean isUpdate () {
        return String.valueOf (this.operationType).containsIgnoreCase ('update');
    }    
    public Boolean isBefore () {
        return String.valueOf (this.operationType).containsIgnoreCase ('before');
    }
    public Boolean isInsert () {
        return String.valueOf (this.operationType).containsIgnoreCase ('insert');
    }
    public Boolean isDelete () {
        return String.valueOf (this.operationType).containsIgnoreCase ('delete');
    }
    public Map <Id, SObject> getOldMap () {
        return this.oldMap;
    }
    public Map <Id, SObject> getNewMap () {
        return this.newMap;
    }
    public List <SObject> getNewList () {
        return this.newList;
    }
    public String getSobjectType () {
        return this.sobjectType;
    }
    

}