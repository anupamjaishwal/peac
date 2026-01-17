import { LightningElement, api, track} from 'lwc';
import { subscribe, onError}  from 'lightning/empApi';

export default class SL_BWSyncUI extends LightningElement {
    subscription = {};
    @api channelName = '/event/SL_BW_Integration_Status__e';
    @track isModalOpen = false;
    @track syncMessage;
    @track syncStatus;
    @track inProgress = true;
    @track isSuccess = false;
    @track isError = false;
    @api recordId;

    connectedCallback() {       
        // Register error listener     
        this.registerErrorListener();
        this.handleSubscribe();
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const thisReference = this;
        // Response contains the payload of the new message received
        const messageCallback = function(response) {
            
            var obj = JSON.parse(JSON.stringify(response));

            console.log('obj.data.payload.Record_Id__c: ',obj.data.payload.Record_Id__c);
            console.log('obj.data.payload.Message__c: ',obj.data.payload.Message__c);
            console.log('obj.data.payload.Status__c: ',obj.data.payload.Status__c);
            //make sure this opens up on the correct record
            if(thisReference.recordId == obj.data.payload.Record_Id__c){
                thisReference.isModalOpen = true;

                thisReference.syncMessage = obj.data.payload.Message__c;
                thisReference.syncStatus = obj.data.payload.Status__c;

                if (obj.data.payload.Status__c == 'Success') {
                    thisReference.isSuccess = true;
                    thisReference.inProgress = false;
                    thisReference.isError = false;
                }
                if (obj.data.payload.Status__c == 'Error') {
                    thisReference.inProgress = false;
                    thisReference.isError = true;
                    thisReference.isSuccess = false;
                }
            }else{
                //thisReference.isModalOpen = false;
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }
   
    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
}