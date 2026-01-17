import { LightningElement, track, wire} from 'lwc';
import getFastTrackURL from "@salesforce/apex/pEAC_FetchAccountDetails.getFastTrackURL";
export default class PEAC_FastTrackURL extends LightningElement {
    FastTrackURL;
    accName;
    @wire (getFastTrackURL) 
    wiredAccounts({data, error}){
        console.log('error:',error);
        if(data) {
            this.FastTrackURL =data.EF_Partner_UDA_URL__c;
            this.accName = 'FastTrackURL'+' '+'for' + '   '+data.Name;
            this.errors = undefined;
        }else {

        }

    }
}