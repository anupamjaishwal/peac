import { LightningElement, api, track } from 'lwc';
import getAccountHierarchy from '@salesforce/apex/SL_MeterDataController.getAccountHierarchy';


export default class SL_eAutomatePosting extends LightningElement {

@track selectedAccount;
@track isLoading = true;

  connectedCallback(){
    
    this.getAccountHierarchy();
  }

    getAccountHierarchy(){
      getAccountHierarchy()
      .then((result) => {
        console.log(JSON.stringify(result));
        this.accounts = result.map(account => ({
          label: account.Name + " - " + account.Dealer_Number__c, // Display the Name field in the dropdown
          value: account.Dealer_Number__c     // The value should be the Account Id
      }));
        this.selectedAccount = result[0].Dealer_Number__c;
        this.isLoading = false;
      })
      .catch((error) => {
        //console.log(error);
      })
    }


    handleAccountChange(event) {      
          this.selectedAccount = event.detail.value;
          this.template.querySelector('c-sl_-meter-data-view-uploads').refreshData(this.selectedAccount);

        }


}