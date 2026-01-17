public class TaxValues {
    public String state;
    public String county;
    public String city;
    public String parentId;
    public String recordName;

    public Boolean isValid() {
        return String.isNotEmpty(state) && String.isNotEmpty(county) && String.isNotEmpty(city);
    }
}