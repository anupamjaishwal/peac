/****************************************************************************************************
 * Author:Rajesh Kumar(LTMindtree)
 * Description: This class is used to upload and display the loan statements for the selected Opportunity
 * Created Date: 05/12/2025
 *****************************************************************************************************/
import { LightningElement, api, track } from 'lwc';
import { reduceErrors } from 'c/sl_Utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';
import hubExecute from "@salesforce/apex/SL_DealerPortalCAAttachment.hubExecute";
import DPExcludeDocumentsToView from "@salesforce/label/c.DPExcludeDocumentsToView";
import uId from "@salesforce/user/Id";
import getDocTypes from '@salesforce/apex/UploadAttachment.getDocumentTypesLWC';
import{ deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import deleteAttachment from '@salesforce/apex/PEAC_LoanAppContoller.deleteAttachment';

const actions = [
   
    { label: 'Delete', name: 'delete' }
];
const COLUMNS = [
  { label: "File Name", fieldName: "recordUrl", type: "url", typeAttributes: {label: {fieldName: "Name"}}},
  { label: "Document Type", fieldName: "Type__c"  },
  
  {
      type: "action",
      typeAttributes: { rowActions: actions, menuAlignment: "right"}
         
  }
];
const NEWCOLUMNS = [
  { label: "File Name", fieldName: "recordUrl", type: "url", typeAttributes: {label: {fieldName: "Name"}}},
  { label: "Document Type", fieldName: "Type__c"  },
];

export default class Peac_loanStatementsAttachement extends LightningElement {
  @api sendFileSelectedMessage;
  @api  docType;
  @api  opportunityId;
  @api  accountId;
  @api recordId;
  fileContent;
  @api isView = false;
  isNotRecordPage;
  docTypeOptions;
  isDescriptionRequired = false;
  @api fileName;
  @api isCompleted;
  @api fileId;
  @api fileSelected = false;
  @api filteruser;
  @api description="";
  isInProgress = false;
  isSavingAttachment = false;
  errorOccurred = false;
  errorMessage = "";
  oppAttachmentId;
  columns = COLUMNS;
  newcolumns = NEWCOLUMNS;
  
  rows = [];
  userId = uId;
  refreshTable;

  connectedCallback(){
    this.isNotRecordPage = !this.recordId;
    if(this.recordId != null){
      this.opportunityId = this.recordId;
      this.isView = true;
    }
    if(this.sendFileSelectedMessage){
      showError(this, "Please make sure you click the \'Save Files\' button for the Files you\'ve selected to upload them before submitting.");
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

  getDocTypes({
        oppId: this.opportunityId
    })
    .then((result) => {
        this.docTypeOptions = result;
    })
    .catch((error) => {
      console.log(error);
    })
        
  }
  
  @api getDocumentDetails(oppid)
  {
    hubExecute({methodName: "getOppAttachments", methodParameters: [oppid]})
    .then((result)=>{
      let obj = JSON.parse(result);
      if(obj && obj.length){

        this.rows = this.processRows(obj);
      }
      else{
        this.rows = obj;
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
  handleDocTypeChange(event) {
    this.docType = event.detail.value;
  }
  handleGoToAdd(){
    this.isView = false;
  }
  handleGoToView(){
    this.isView = true;
  }

  handleFile(event){
     if(event.detail.errorMessage){
            showError(this, "An error occured, while uploading the file");
            this.template.querySelector("c-sl-big-file-upload-d-p").resetFile();
            //this.alertError(event.detail.errorMessage);


        }else{
            this.fileName = event.detail.fileName;
            this.fileContent = event.detail.fileContent;
            this.fileSelected = true;
            this.template.querySelector('lightning-button[data-id="submitbutton"]').focus();
        }
    // if(!event.detail.errorOccurred){
    //   if(event.detail.fileContent.length > 8000000){
    //     showError(this, "The file selected is bigger than 8MB please select another file and try again.");
    //     this.template.querySelector("c-sl-big-file-upload-d-p").resetFile();
    //   }else{
    //     this.fileName         = event.detail.fileName;
    //     this.fileContent      = event.detail.fileContent;
    //     this.fileSelected  = true;
    //     this.template.querySelector("lightning-button").focus();
    //   }
    // }
  }

  handleSubmit(event){
    //event.preventDefault();
    
    if(this.isInProgress){
      event.preventDefault();
    } else {
      const fields  = event.detail.fields;
      if(this.fileSelected){
        
        if(fields.Doc_Type__c){
          this.isInProgress = true;
          this.errorOccurred = false;
          //event.preventDefault();
          fields.Type__c = fields.Doc_Type__c;
          //fields.Description__c = this.description;
          //fields.Account__c  = this.accountId;
          fields.Opportunity__c  = this.opportunityId;
          this.template.querySelector('lightning-record-edit-form').submit(fields);
        }else{
          this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: 'Please Select a Document Type'
          }));
          this.errorOccurred = true;
        }
      }else{
        this.dispatchEvent(new ShowToastEvent({
          title: 'Warning',
          message: 'Please Select a file'
        }));
          this.errorOccurred = true;
          //event.preventDefault();
      }
    }
  }

  handleSuccess(event){
    this.oppAttachmentId = event.detail.id;
    this.isSavingAttachment = true;
    this.template.querySelector("c-sl-big-file-upload-d-p").sendToUploadHelper(this.oppAttachmentId);
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
          this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
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

  
  async handleSelection(event) {
    const row = event.detail.row;
    await deleteAttachment({oppId:this.opportunityId,attachmentId:row.Id})
      .then((result)=>{
        let obj = JSON.parse(result);
      if(obj && obj.length){

        this.rows = this.processRows(obj);
        
      }
      else{
        this.rows = obj;
      }
      this.dispatchEvent(
      new ShowToastEvent({
          title : 'Success',
          message : 'Your Statement has been deleted successfully' ,
          variant : 'success'
      })
      );
      
       
    

      })
        .catch(error =>{
      this.dispatchEvent(
      new ShowToastEvent({
          title : 'Error while deleting record',
          message: reduceErrors(error).join(', '),
          variant : 'Error'
      })
      );
      });
  }
  cleanUp(event){
    const inputFields = [...this.template.querySelectorAll('lightning-input-field')];
    inputFields.forEach((field) => field.reset());
    //this.description = "";
    this.docType = "";
    this.fileName = "";
    this.fileContent = null;
    this.fileSelected = false;
    this.isInProgress = false;
    this.isSavingAttachment = false;
    this.errorOccurred = false;
    this.errorMessage = "";
    this.oppAttachmentId = null;
    this.template.querySelector("c-sl-big-file-upload-d-p").resetFile();
  }

  processRows(rawData){
    let processed = [];
    rawData.forEach(oppAttachment=>{
      console.log(this.filteruser,'oppAttachment:',JSON.stringify(oppAttachment));
      
        let newRow = JSON.parse(JSON.stringify(oppAttachment));
        newRow.recordUrl = "/" + newRow.Id;
        processed.push(newRow);
      
    });
    return processed;
  }

  handleTypeChange(event){
    const SELECTED_VALUE  = event.detail.value;
    this.docType = SELECTED_VALUE;
    

    }
}