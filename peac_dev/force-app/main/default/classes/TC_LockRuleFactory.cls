public class TC_LockRuleFactory {
    public static TC_LockRuleAbstract getLockRule (String sobjectType) {
        return (TC_LockRuleAbstract) Type.forName ('TC_' + sobjectType + 'LockRule').newInstance ();
    }
}