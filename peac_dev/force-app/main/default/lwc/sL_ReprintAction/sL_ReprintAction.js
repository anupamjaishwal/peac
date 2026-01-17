import { LightningElement, api } from 'lwc';
import updateReprintFields from '@salesforce/apex/SL_ReprintAction.updateReprintFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class SL_ReprintAction extends LightningElement {
    @api recordId;
  
    isExecuting;
    get isLoading() { return !this.recordId || this.isExecuting; }
    isFirstLoadDone = false;
    isDelinquent = false;
    question = "";
    
    renderedCallback(){
        if(this.recordId && !this.isFirstLoadDone)
            this.setReprintField(false);
    }

    handleProceedDQ(){
        this.setReprintField(true);
    }

    handleCancelDQ(){
        this.cancelScreen("Reprint not Completed");
    }

    setReprintField(userConfirmed) {
        this.isExecuting = true;
        updateReprintFields({recordId: this.recordId, userConfirmed: userConfirmed})
        .then(result => {
            if(result == "success"){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contract successfully set for reprinting.',
                        variant: 'success'
                    })
                );
                getRecordNotifyChange([{recordId: this.recordId}]);
                this.dispatchEvent(new CloseActionScreenEvent());
            }else{
                if(result == "Confirm reprint on a delinquent contract"){
                    this.isDelinquent = true;
                    this.question = result;
                }else{
                    this.cancelScreen(result);
                }
            }
        })
        .catch(error => {
            this.cancelScreen(error);
        })
        .finally(() => {
            this.isExecuting = false;
            this.isFirstLoadDone = true;
         });
        
        
    }

    cancelScreen(error){
        this.showError(error);
        this.dispatchEvent(new CloseActionScreenEvent());
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
}