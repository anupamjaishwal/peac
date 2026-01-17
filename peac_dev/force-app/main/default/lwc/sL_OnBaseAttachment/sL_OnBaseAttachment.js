import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';
import { NavigationMixin } from 'lightning/navigation';
import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_UploadAttachment.hubExecute';

export default class SL_OnBaseAttachment extends NavigationMixin(LightningElement) {
    @api recordId;
    @api lookupFieldName = 'Account__c';
    @api operation = 'uploadFile';
    isLoading = false;
    onBaseAttachmentId;
    get showStatusField(){ return this.lookupFieldName != 'Account__c'; }

    fileContent;
    fileName;
    fileSelected = false;
    isInProgress = false;
    isSavingAttachment = false;
    get isSendToOnBaseOperation() { return this.operation == 'sendToOnBaseFromAcc'; }
    isRequestSent = false;

    @wire(IsConsoleNavigation) isConsoleNavigation;

    // connectedCallback(){
    //     if(!this.isLoading && this.isSendToOnBaseOperation){
    //         this.isRequestSent = false;
    //     }
    // }
    renderedCallback(){
      if(!this.isRequestSent && this.isSendToOnBaseOperation){
        this.isRequestSent = true;
        this.sendToOnBase();
      }
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

    handleProcessing(event){
        let fields = event.detail.fields;
        fields[this.lookupFieldName] = this.recordId;
        event.preventDefault();
        if(!this.isInProgress){
            if(this.fileSelected){
                this.template.querySelector('lightning-record-edit-form').submit(fields);
                this.isInProgress = true;
                this.errorOccurred = false;
                this.isConfirmed = false;
            }else{
                showError(this, "Please select a file to attach");
                this.errorOccurred = true;
            }
        }
    }
    handleError(event){
        this.isInProgress = false;
    }
    handleAfterSave(event){
        this.onBaseAttachmentId = event.detail.id;
        this.isSavingAttachment = true;
        this.template.querySelector("c-sl-big-file-upload").sendToUploadHelper(this.onBaseAttachmentId);
    }

    afterUploadHelper(event){
        if(!event.detail.attachmentResult.includes("Failed:")){
            this.isInProgress = false;
            this.isSavingAttachment = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "The Attachment has been uploaded.",
                    variant: 'success'
                })
            )
            this.handleCancel();
        }else{
            showError(this, event.detail.attachmentResult);
            this.errorOccurred = true;
            this.isInProgress = false;
            this.isSavingAttachment = false;
        }
    }

    handleCancel() {
        this.onBaseAttachmentId = undefined;
        this.fileContent = undefined;
        this.fileName = undefined;
        this.fileSelected = false;
        this.isInProgress = false;
        this.isSavingAttachment = false;
        this.isRequestSent = false;
        this.actuallyCloseTab();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }

    async actuallyCloseTab(){
        if(this.isConsoleNavigation){
            const { tabId } = await getFocusedTabInfo();
            await closeTab(tabId);
        }
    }

    sendToOnBase(){
        this.isLoading = true;
        this.isSavingAttachment = true;
        let parameters = [this.recordId];
        hubExecute({methodName: "sendToOnBaseFromAcc", methodParameters: parameters})
        .then((result)=>{
        // this.isLoading = false;
        if(result == "success"){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Request(s) have been submitted to OnBase, it may take a while for the file(s) to process.",
                    variant: 'success'
                })
            );
        }else{
            showError(this, result);
        }
        })
        .catch((error)=>{
            showError(this, error.body.message);
        })
        .finally(()=>{
            this.isSavingAttachment = false;
            this.isLoading = false;
            setTimeout(() => { 
                console.log("this.isRequestSent: ", JSON.parse(JSON.stringify(this.isRequestSent)));
                this.handleCancel();                         
            }, 500);
            
        });
    }

}