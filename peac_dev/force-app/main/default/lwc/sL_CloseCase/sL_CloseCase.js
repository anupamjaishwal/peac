import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";
import { showError } from 'c/sL_Common';

export default class SL_CloseCase extends LightningElement {
    @api recordId;
    @api isFromSaveAndClose;

    isLoading = true;
    title = "Close Case";
    isOther;
    isSaving = false;

    handleOtherReason(event){
        this.isLoading = false;
        let closedReason = "";
        const inputFields = this.template.querySelectorAll("lightning-input-field");
        if (inputFields) {
            inputFields.forEach(field => {
                if(field.name === "Closed_Reason__c") {
                    closedReason = field.value;
                }
            });
        }
        this.isOther = closedReason == "Other";
    }

    handleSubmit(){
        this.isSaving = true;
    }

    handleSuccess(){
        this.isSaving = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Case successfully closed',
                variant: 'success'
            })
        );
        this.goToCallingRecord();
    }

    goToCallingRecord(){
        if(this.isFromSaveAndClose){
            this.dispatchEvent(new CustomEvent("close", {detail: ""}));
        }
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}