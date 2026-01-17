public class TC_TriggerActionFactory {
    public static TC_TriggerActionI getTriggerAction (String className) {
        // if we need any additional logic down the road
        return (TC_TriggerActionI) Type.forName(className).newInstance();
    }
}