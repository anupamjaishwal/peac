import { LightningElement, api } from 'lwc';
import getAccount from '@salesforce/apex/tc_notificationCenterController.GetuserAccount';
import getContact from '@salesforce/apex/tc_notificationCenterController.GetContact';
import GetuserContact from '@salesforce/apex/tc_notificationCenterController.GetuserContact';

export default class Tc_userNotificationCenter extends LightningElement {
    @api recordId;
    accountRec = {};
    connectedCallback() {
        console.log('this.recordId:',this.recordId);
        getAccount({userId: this.recordId})
        .then(result => {
            this.accountRec = result;
            
            console.log(JSON.stringify(this.accountRec));
        })

        GetuserContact({userId: this.recordId})
        .then(result => {
            this.data = result;
        
            console.log(JSON.stringify(result));
        })
    }
}