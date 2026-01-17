import { LightningElement, api, track,wire } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPrimaryContact from '@salesforce/apex/SL_retrievePrimaryContact.getPrimaryContactsOfContract';


export default class Sl_primaryContact extends LightningElement {
    @track allPrimaryContact ;
    @api recordId;
    @track contactId;
    @track isEdit = false;
    @track primaryContactName;

    connectedCallback(){
        getPrimaryContact({contractId: this.recordId})
        .then((result)=>{
            console.log('Response::'+JSON.stringify(result));
            this.allPrimaryContact = result;
            this.contactId = result.Id;
            this.primaryContactName = result['Name'];
            console.log('contactId::'+this.contactId+'--'+this.primaryContactName);
        })
        .catch((error)=>{
            //this.showError(error);
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }

    showError(error){
        let message = (error && error.body && error.body.message) || error.message || error;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }
    handleReset(event) {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
            this.isEdit = false;
        }
        }
    handleEdit(event){
        console.log('in handleedit');
        this.isEdit = true;
    }
    handleSuccess(event) {
        console.log('onsuccess event recordEditForm',event.detail.id);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Updated the contact successfully!',
                variant: 'success'
            })
        );
        this.isEdit = false;
        
    }
    handleSubmit(event) {
        console.log('onsubmit event recordEditForm'+ event.detail.fields);
    } 
}