import { LightningElement, api, wire } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import hubExecute from '@salesforce/apex/SL_UploadAttachment.hubExecute';
import getOtherContracts from '@salesforce/apex/SL_UploadAttachment.getOtherContracts';

// just a reminder, ShowToastEvent is not being listened inside a VisualForce page

const COLUMNS = [
    { label: "Contract Number", fieldName: "Name"},
    { label: "Status", fieldName: "Status__c"}
];

export default class SL_UploadAttachment extends LightningElement {
    @api contractId;
    isLoading = true;
    wiredResult;
    contracts;
    columns = COLUMNS;
    selectedContracts = [];
    
    isConfirmed = false;
    contractAttachmentId;

    fileContent;
    fileName;
    fileSelected = false;
    isInProgress = false;
    isSavingAttachment = false;
    errorOccurred = false;
    errorMessage = "";

    @wire(getOtherContracts, {contractId: "$contractId"})
    getOtherContracts(result){
        this.wiredResult = result;
        if(result.data){
            this.contracts = result.data;
        }else if(result.error){
            this.showError(result.error);
        }
    }

    connectedCallback(){
        this.isLoading = false;
    }

    handleFile(event){
        if(event.detail.errorOccurred){
            this.errorOccurred = true;
        }else{
            this.fileName = event.detail.fileName;
            this.fileContent = event.detail.fileContent;
            this.fileSelected = true;
            this.errorOccurred = false;
        }
    }
    
    handleSelectedContracts(event){
        this.selectedContracts = [];
        for (let i = 0; i < event.detail.selectedRows.length; i++) {
            this.selectedContracts.push(event.detail.selectedRows[i].Id);
        }
    }

    handleProcessing(event){
        if(this.isInProgress){
            event.preventDefault();
        } else {
            if(this.fileSelected){
                if(this.selectedContracts.length > 0 && !this.isConfirmed){
                    event.preventDefault();
                    this.confirmMultiple(event.detail.fields);
                }else{
                    this.isInProgress = true;
                    this.errorOccurred = false;
                    this.isConfirmed = false;
                }
            }else{
                this.errorMessage = "Please select a file to attach";
                this.errorOccurred = true;
                event.preventDefault();
            }
        }
    }
    handleError(event){
        this.isInProgress = false;
    }
    handleAfterSave(event){
        this.contractAttachmentId = event.detail.id;
        this.isSavingAttachment = true;
        this.template.querySelector("c-sl-big-file-upload").sendToUploadHelper(this.contractAttachmentId);
    }

    afterUploadHelper(event){
        if(!event.detail.attachmentResult.includes("Failed:")){
            this.saveOtherContracts(this.contractAttachmentId);
        }else{
            this.errorMessage = error.body.message;
            this.errorOccurred = true;
            this.isInProgress = false;
            this.isSavingAttachment = false;
        }
    }

    saveOtherContracts(attachmentId){
        let parameters = [attachmentId, this.contractId, this.selectedContracts.join(",")];
        hubExecute({methodName: "saveOtherContracts", methodParameters: parameters})
        .then((result)=>{
            if(result == "success"){
                this.alertSuccess("The Attachment has been uploaded to the selected Contract(s). Request(s) have been submitted to OnBase, it may take a while for the file(s) to process");
            }else{
                this.errorMessage = result;
                this.errorOccurred = true;
            }
        })
        .catch((error)=>{
            this.errorMessage = error.body.message;
            this.errorOccurred = true;
        })
        .finally(()=>{
            this.isInProgress = false;
            this.isSavingAttachment = false;
        });
    }

    async confirmMultiple(submittedFields){
        const isConfirmed = await LightningConfirm.open({
            message: 'This will also upload the file to the selected Contract(s), click Ok to confirm.',
            variant: 'headerless',
            label: 'This will also upload the file to the selected Contract(s), click Ok to confirm.'
        });
        this.isConfirmed = isConfirmed;
        if(isConfirmed){
            this.template.querySelector('lightning-record-edit-form').submit(submittedFields);
        }
    }

    async alertSuccess(customMessage) {
        customMessage = customMessage? customMessage: "Process was Successful.";
        await LightningAlert.open({
            message: customMessage,
            theme: 'success',
            label: 'Success!',
        });
        document.dispatchEvent(new Event("successfulUpload"));
    }
    
    showError(message){
        this.errorMessage = message;
        this.errorOccurred = true;
    }
}