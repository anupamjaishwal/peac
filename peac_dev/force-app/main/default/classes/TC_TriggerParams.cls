// encapsulates the trigger parameters
public class TC_TriggerParams {
    
    private Map <Id, SObject> oldMap;
    private Map <Id, SObject> newMap;
    private List <SObject> newList;
    
    public TC_TriggerParams (Map <Id, SObject> oldMap, Map <Id, SObject> newMap, List <SObject> newList) {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.newList = newList;
    }
    
    public Map <Id, SObject> getOldMap () {return this.oldMap;}
    public Map <Id, SObject> getNewMap () {return this.newMap;}
    public List <SObject> getNewList () {return this.newList;}

}