import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjectAPIName from '@salesforce/apex/SL_NewUccRequest.getObjectAPIName';

export default class SL_NewUccRequest extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track isLoading;
    @track title;
    
    @track account;
    @track filer;
    @track contract;
    @track status = "Draft";

    connectedCallback(){
        this.title = "Create New UCC Request";
        this.isLoading = true;
        getObjectAPIName({recordId: this.recordId})
        .then((result) =>{
            let obj = JSON.parse(result);
            this.account = obj.account;
            this.filer = obj.filer;
            this.contract = obj.contract;
            this.objectApiName = obj.objectApiName;
        })
        .catch((error) =>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    renderedCallback(){
        this.isLoading = false;
    }

    handleSuccess(){
        this.goToCallingRecord();
    }

    showError(error){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body.message,
                variant: 'error'
            })
        );
    }

    goToCallingRecord(){
        window.location = window.location.origin + "/" + this.recordId;
    }
}