import { LightningElement, api } from 'lwc';
import getOppInfo from '@salesforce/apex/SL_DocGenController.getOppInfo';
import getInstance from '@salesforce/apex/SL_DocGenController.getInstance';
import {NavigationMixin} from 'lightning/navigation';
export default class PEAC_ApprovalLetterButton extends NavigationMixin(LightningElement) {

    message;
    
    _recordId;
    instanceId;

    @api set recordId(value) {
        this._recordId = value;
         getInstance().then(result=>{
                //console.log("INSTANCE: "+result);
                this.instanceId="&instance="+result+"&";
              });
        this.handleFetchOpptyInfo();
    }

    get recordId() {
        return this._recordId;
    }

    // connectedCallback() {
    //     this.handleFetchOpptyInfo(); 
    // }

    handleFetchOpptyInfo() {
            console.log('Button::handleFetchOpptyInfo:recordId::', this.recordId);
        getOppInfo({
            recordId : this._recordId
        }).then(result => {
            console.log('Button::handleFetchOpptyInfo:result::', JSON.stringify(result));
            if(result && result.Application_Status__c) {
                if((result.Application_Status__c === 'Manually Approved') || (result.Application_Status__c === 'Automatically Approved') || (result.Application_Status__c === 'Booked')){
                   this.handleNavigate();
                } else {
                    this.message = 'Approval letter cannot be generated as the application is not approved';
                }
            }
        }).catch(error => {
            console.log('Button::handleFetchOpptyInfo:error::', JSON.stringify(error));

        });
    }

    handleNavigate() {
      console.log('in handleNavigate');
      const config = {
          type: 'standard__webPage',
          attributes: {
            url: '/dealers/apex/loop__looplus?&eid='+this._recordId+this.instanceId+'&hidecontact=true&hideddp=true&autorun=true&ddpIds=a1wPP000004I6W5YAK&deploy=a1uPP000004fOs5YAE'
            }
      };
      
      console.log('GenURL: '+config.attributes.url);
      this[NavigationMixin.Navigate](config);
    }

}