import { LightningElement, api, track } from 'lwc';
import LightningAlert from 'lightning/alert';
import getDocTypes from '@salesforce/apex/UploadAttachment.getDocumentTypesLWC';



export default class UploadAttachment extends LightningElement {
    @api opportunityId;
    @track isLoading = true;
    @track isConfirmed = false;
    @track fileContent;
    @track fileName;
    @track fileSelected = false;
    @track isInProgress = false;
    @track isSavingAttachment = false;
    @track errorOccurred = false;
    @track errorMessage = "";
    @track opportunityAttachmentId;
    @track docTypeValue;
    @track docTypeOptions;



    connectedCallback() {
        console.log('UploadAttachmentJS');
        this.isLoading = false;
        getDocTypes({
            oppId: this.opportunityId
        })
            .then((result) => {
                console.log('result: ', JSON.stringify(result));
                this.docTypeOptions = result;
            })
            .catch((error) => {
                console.log(error);
            })
    }

    handleFile(event) {
        if (event.detail.errorMessage) {
            console.log('errorMessage in main LWC: ', event.detail.errorMessage);
            this.errorOccurred = true;
            this.alertError(event.detail.errorMessage);


        } else {
            this.fileName = event.detail.fileName;
            this.fileContent = event.detail.fileContent;
            this.fileSelected = true;
            this.errorOccurred = false;
        }
    }
    handleProcessing(event) {
        console.log('handleProcessing');
        if (this.isInProgress) {
            event.preventDefault();
        } else {
            if (this.fileSelected) {
                console.log('fileSelected');
                this.isInProgress = true;
                this.errorOccurred = false;
                this.isConfirmed = false;
                //this.template.querySelector("c-sl-big-file-upload").sendToUploadHelperOpportunity(this.opportunityAttachmentId);
                //  event.detail.fields.Type__c = this.docTypeValue;

                let fields = event.detail.fields;
                fields["Type__c"] = this.docTypeValue;
                
                //if(!fields["Type__c"].startsWith("FS")) fields["Dealer_Doc_Type__c"] = this.docTypeValue;
                console.log('Fields::', JSON.stringify(fields));
                this.template.querySelector('lightning-record-edit-form').submit(fields);
            } else {
                this.errorMessage = "Please select a file to attach";
                this.errorOccurred = true;
                event.preventDefault();
            }
        }
    }
    handleAfterSave(event) {
        try {
            this.opportunityAttachmentId = event.detail.id;
            console.log("event.detail.id: ", event.detail.id);
            this.isSavingAttachment = true;
            this.template.querySelector("c-sl-big-file-upload").sendToUploadHelper(this.opportunityAttachmentId);
            console.log('75');

        }
        catch (error) {
            console.log(error);
        }

    }

    afterUploadHelper(event) {
        console.log("afterUploadHelper event: ", JSON.parse(JSON.stringify(event)));
        console.log('MSG: ', event.detail.attachmentResult);

        if (!event.detail.attachmentResult.includes("Failed:")) {
            this.isInProgress = false;
            this.isSavingAttachment = false;
            this.alertSuccess("The Attachment has been uploaded to the selected Opportunity.");
        } else {
            this.errorMessage = error.body.message;
            this.errorOccurred = true;
            this.isInProgress = false;
            this.isSavingAttachment = false;
        }
    }

    handleDocTypeChange(event) {
        this.docTypeValue = event.detail.value;
    }

    async alertSuccess(customMessage) {
        customMessage = customMessage ? customMessage : "Process was Successful.";
        await LightningAlert.open({
            message: customMessage,
            theme: 'success',
            label: 'Success!',
        });
        document.dispatchEvent(new Event("successfulUpload"));
    }

    async alertError(customMessage) {
        customMessage = customMessage ? customMessage : "Error.";
        await LightningAlert.open({
            message: customMessage,
            theme: 'error',
            label: 'Error!',
        });
    }

    showError(message) {
        this.errorMessage = message;
        this.errorOccurred = true;
    }

    handleError(event) {
        this.isInProgress = false;
    }
}