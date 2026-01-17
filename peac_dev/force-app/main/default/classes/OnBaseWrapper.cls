/**
 * Created on 9/29/18.
 * Tamarack Consulting. 
 */

public with sharing class OnBaseWrapper {
    public String Name;
    public String DocType;
    public String FileExtension;
    public String FileType;
    public String CreateDate;
    public String bytes;
    public List <OnBaseKeyword> Keywords;

    public OnBaseWrapper () {
        Keywords = new List <OnBaseKeyword> ();

    }


    public class OnBaseKeyword {
        public String Name;
        public String CurrentValue;
        public String UpdatedValue;

        public OnBaseKeyword (String Name, String CurrentValue, String UpdatedValue) {
            this.Name = Name;
            this.CurrentValue = CurrentValue;
            this.UpdatedValue = UpdatedValue;
        }

    }
}