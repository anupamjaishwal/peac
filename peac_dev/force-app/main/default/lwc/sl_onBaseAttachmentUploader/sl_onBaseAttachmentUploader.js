import { LightningElement, api, track } from 'lwc';
import { reduceErrors } from 'c/sl_Utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';
import hubExecute from "@salesforce/apex/SL_DealerPortalCAAttachment.hubExecute";

const COLUMNS = [
  { label: "File Name", fieldName: "recordUrl", type: "url", typeAttributes: {label: {fieldName: "Name"}}},
  { label: "Document Type", fieldName: "Dealer_Doc_Type__c"  }
];

export default class Sl_onBaseAttachmentUploader extends LightningElement {
  @api sendFileSelectedMessage;
  @api  docType;
  @api  opportunityId;
  @api  accountId;
  @api recordId;
  fileContent;
  @track isView = false;
  isNotRecordPage;

  isDescriptionRequired = false;
  @api fileName;
  @api isCompleted;
  @api fileId;
  @api fileSelected = false;
  isInProgress = false;
  isSavingAttachment = false;
  errorOccurred = false;
  errorMessage = "";
  oppAttachmentId;
  columns = COLUMNS;
  rows = [];

  connectedCallback(){
    this.isNotRecordPage = !this.recordId;
    if(this.recordId != null){
      this.opportunityId = this.recordId;
      this.isView = true;
    }
    if(this.sendFileSelectedMessage){
      showError(this, "There was a file uploaded but it wasn\'t added, please make sure to click on the Add Document Button and once the document is added and the information is correct,"
        + " click on Submit.");
    }
    hubExecute({methodName: "getOppAttachments", methodParameters: [this.opportunityId]})
    .then((result)=>{
      let obj = JSON.parse(result);
      if(obj && obj.length){
        this.rows = this.processRows(obj);
      } 
    })
    .catch((error)=>{
        this.errorMessage = error.body.message;
        this.errorOccurred = true;
        showError(this, this.errorMessage);
    })
    .finally(()=>{
        this.isInProgress = false;
        this.isSavingAttachment = false;
    });
  }

  handleGoToAdd(){
    this.isView = false;
  }
  handleGoToView(){
    this.isView = true;
  }

  handleFile(event){
    if(!event.detail.errorOccurred){
      this.fileName         = event.detail.fileName;
      this.fileContent      = event.detail.fileContent;
      this.fileSelected  = true;
      this.template.querySelector("lightning-button").focus();
    }
  }

  handleSubmit(event){
    console.log('Submit EVT', event.detail);
    event.preventDefault();
    
    if(this.isInProgress){
      //event.preventDefault();
    } else {
      const fields  = event.detail.fields;
      if(this.fileSelected){
        if(fields.Dealer_Doc_Type__c){
          console.log('ttt')
          this.isInProgress = true;
          this.errorOccurred = false;
          //event.preventDefault();
          fields.Type__c  = fields.Dealer_Doc_Type__c;
          this.template.querySelector('lightning-record-edit-form').submit(fields);
        }else{
          this.dispatchEvent(new ShowToastEvent({title: 'Warning',
            message: 'Please Select a Document Type'}));
          this.errorOccurred = true;
        }
      }else{
          this.dispatchEvent(new ShowToastEvent({title: 'Warning',
            message: 'Please Select a file'}));
          this.errorOccurred = true;
          //event.preventDefault();
      }
    }
  }

  handleSuccess(event){
    this.oppAttachmentId = event.detail.id;
    this.isSavingAttachment = true;
    this.template.querySelector("c-sl-big-file-upload").sendToUploadHelper(this.oppAttachmentId);
  }

  handleError(event){
    showError(this, reduceErrors(event.detail).join(", "));
  }

  afterUploadHelper(event){
    if(this.isSavingAttachment){
      this.isSavingAttachment = false;
      if(!event.detail.attachmentResult.includes("Failed:")){
        this.updateOppAttachment(event.detail.attachmentResult);
      }else{
        console.log("error: ", event.detail.attachmentResult.substring(event.detail.attachmentResult.indexOf('message:')));
        showError(this, event.detail.attachmentResult.substring(event.detail.attachmentResult.indexOf('message:')));
          this.errorOccurred = true;
          this.isInProgress = false;
      }
    }
  }
  
  updateOppAttachment(attachmentId){
    let parameters = [this.oppAttachmentId, attachmentId];
    hubExecute({methodName: "updateOppAttachment", methodParameters: parameters})
    .then((result)=>{
      let obj = JSON.parse(result);
      //console.log("obj: ", obj);
      if(obj && obj.length){
        this.rows = this.processRows(obj);
        this.dispatchEvent(new ShowToastEvent({title: 'Success',
          message: `File ${this.fileName} created succesfully.`,
          variant: "success"
        }));
        this.cleanUp();
      }else{
          this.errorMessage = result;
          this.errorOccurred = true;
          showError(this, this.errorMessage);
      }
    })
    .catch((error)=>{
        this.errorMessage = error.body.message;
        this.errorOccurred = true;
        showError(this, this.errorMessage);
    })
    .finally(()=>{
        this.isInProgress = false;
    });
  }

  cleanUp(event){
    this.docType = "";
    this.fileName = "";
    this.fileContent = null;
    this.fileSelected = false;
    this.isInProgress = false;
    this.isSavingAttachment = false;
    this.errorOccurred = false;
    this.errorMessage = "";
    this.oppAttachmentId = null;
    this.template.querySelector("c-sl-big-file-upload").resetFile();
  }

  processRows(rawData){
    let processed = [];
    rawData.forEach(oppAttachment=>{
      let newRow = JSON.parse(JSON.stringify(oppAttachment));
      newRow.recordUrl = "/dealers/s/detail/" + newRow.Id;
      processed.push(newRow);
    });
    return processed;
  }

  handleTypeChange(event){
    const SELECTED_VALUE  = event.detail.value;
    this.docType = SELECTED_VALUE;
    //object to map when the Description field is required based on the selected Type field.
    const DESCRIPTION_REQ_VALUES = {
      'LC - Misc':  true,
      'Default':    false
    }; 

    this.isDescriptionRequired  = DESCRIPTION_REQ_VALUES[SELECTED_VALUE] || DESCRIPTION_REQ_VALUES['Default'];
  }
}