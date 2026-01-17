import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import DEALER_DOC from '@salesforce/schema/Opportunity_Attachment__c.Dealer_Doc_Type__c';
import OPP_ATTACHMENT_OBJ from '@salesforce/schema/Opportunity_Attachment__c';

import { reduceErrors } from 'c/sl_Utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';
import hubExecute from "@salesforce/apex/SL_DealerPortalCAAttachment.hubExecute";
import DPExcludeDocumentsToView from "@salesforce/label/c.DPExcludeDocumentsToView";
import uId from "@salesforce/user/Id";
import superUser from "@salesforce/apex/SL_DealerPortalCAAttachment.checkSuperUser";

const COLUMNS = [
  { label: "File Name", fieldName: "recordUrl", type: "url", typeAttributes: { label: { fieldName: "Name" } } },
  { label: "Document Type", fieldName: "Dealer_Doc_Type__c" }
];

export default class Sl_onBaseAttachmentDP extends LightningElement {
  //Test
  @track documentOptions = [];

// Obtener info del objeto
@wire(getObjectInfo, { objectApiName: OPP_ATTACHMENT_OBJ })
objectInfo;

// Obtener valores del picklist
@wire(getPicklistValues, {
    recordTypeId: '$objectInfo.data.defaultRecordTypeId',
    fieldApiName: DEALER_DOC
})  
getPicklistValues({ data, error }) {
    if (data) {
        this.documentOptions = data.values;
    }
}

  //


  @api sendFileSelectedMessage;
  @api docType;
  @api opportunityId;
  @api accountId;
  @api recordId;
  fileContent;
  @track isView = false;
  isNotRecordPage;

  isDescriptionRequired = false;
  @api fileName;
  @api isCompleted;
  @api fileId;
  @api fileSelected = false;
  @api filteruser;
  isInProgress = false;
  isSavingAttachment = false;
  errorOccurred = false;
  errorMessage = "";
  oppAttachmentId;
  columns = COLUMNS;
  rows = [];
  userId = uId;

  superUserCheck = false;

  connectedCallback() {
    sessionStorage.setItem('isNewAppComingBack', false);
    this.isNotRecordPage = !this.recordId;
    if (this.recordId != null) {
      this.opportunityId = this.recordId;
      this.isView = true;
    }
    if (this.sendFileSelectedMessage) {
      showError(this, "Please make sure you click the \'Save Files\' button for the Files you\'ve selected to upload them before submitting.");
    }

    superUser({

    }).then(result => {
      this.superUserCheck = result;
      this.fetchDocuments();
    }).catch(error => {

    });

  }

  fetchDocuments() {
    hubExecute({ methodName: "getOppAttachments", methodParameters: [this.opportunityId] })
      .then((result) => {
        let obj = JSON.parse(result);
        if (obj && obj.length) {

          this.rows = this.processRows(obj);
        }
      })
      .catch((error) => {
        this.errorMessage = error.body.message;
        this.errorOccurred = true;
        showError(this, this.errorMessage);
      })
      .finally(() => {
        this.isInProgress = false;
        this.isSavingAttachment = false;
      });
  }

  handleGoToAdd() {
    this.isView = false;
  }
  handleGoToView() {
    this.isView = true;
  }

  handleFile(event) {
    if (event.detail.errorMessage) {
      showError(this, "An error occured, while uploading the file");
      this.template.querySelector("c-sl-big-file-upload-d-p").resetFile();
      //this.alertError(event.detail.errorMessage);


    } else {
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

  handleSubmit(event) {
    //event.preventDefault();

    if (this.isInProgress) {
      event.preventDefault();
    } else {
      let fields = event.detail.fields;
      if (this.fileSelected) {
        if (this.docType) {
          this.isInProgress = true;
          this.errorOccurred = false;
          //event.preventDefault();
          fields.Dealer_Doc_Type__c = this.docType;
          fields.Type__c = fields.Dealer_Doc_Type__c;
          fields.Account__c = this.accountId;
          fields.Opportunity__c = this.opportunityId;
          fields.DPSuperUserDocuments__c = true;
          this.template.querySelector('lightning-record-edit-form').submit(fields);
        } else {
          this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: 'Please Select a Document Type'
          }));
          this.errorOccurred = true;
        }
      } else {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Warning',
          message: 'Please Select a file'
        }));
        this.errorOccurred = true;
        //event.preventDefault();
      }
    }
  }

  handleSuccess(event) {
    this.oppAttachmentId = event.detail.id;
    this.isSavingAttachment = true;
    this.template.querySelector("c-sl-big-file-upload-d-p").sendToUploadHelper(this.oppAttachmentId);
  }

  handleError(event) {
    showError(this, reduceErrors(event.detail).join(", "));
  }

  afterUploadHelper(event) {
    if (this.isSavingAttachment) {
      this.isSavingAttachment = false;
      if (!event.detail.attachmentResult.includes("Failed:")) {
        this.updateOppAttachment(event.detail.attachmentResult);
      } else {
        console.log("error: ", event.detail.attachmentResult.substring(event.detail.attachmentResult.indexOf('message:')));
        showError(this, event.detail.attachmentResult.substring(event.detail.attachmentResult.indexOf('message:')));
        this.errorOccurred = true;
        this.isInProgress = false;
      }
    }
  }

  updateOppAttachment(attachmentId) {
    let parameters = [this.oppAttachmentId, attachmentId];
    hubExecute({ methodName: "updateOppAttachment", methodParameters: parameters })
      .then((result) => {
        let obj = JSON.parse(result);
        //console.log("obj: ", obj);
        if (obj && obj.length) {
          this.rows = this.processRows(obj);
          this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: `File ${this.fileName} created succesfully.`,
            variant: "success"
          }));
          this.cleanUp();
        } else {
          this.errorMessage = result;
          this.errorOccurred = true;
          showError(this, this.errorMessage);
        }
      })
      .catch((error) => {
        this.errorMessage = error.body.message;
        this.errorOccurred = true;
        showError(this, this.errorMessage);
      })
      .finally(() => {
        this.isInProgress = false;
      });
  }

  cleanUp(event) {
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

  processRows(rawData) {
    let processed = [];
    rawData.forEach(oppAttachment => {
      console.log(this.filteruser, 'oppAttachment:', JSON.stringify(oppAttachment));
      //  if( ((this.filteruser == 'true' && oppAttachment.CreatedById == this.userId) || !this.filteruser) && oppAttachment.Type__c != DPExcludeDocumentsToView){
      //  if (oppAttachment.Type__c == 'LC - Lease' || (oppAttachment.CreatedById == this.userId && oppAttachment.Type__c != DPExcludeDocumentsToView)) {
      if (oppAttachment.Type__c == 'LC - Lease' || (this.superUserCheck && oppAttachment["DPSuperUserDocuments__c"]) ||
        (oppAttachment.CreatedById == this.userId && oppAttachment.Type__c != DPExcludeDocumentsToView)) {
        let newRow = JSON.parse(JSON.stringify(oppAttachment));
        newRow.recordUrl = "/dealers/s/detail/" + newRow.Id;
        processed.push(newRow);
      }
    });
    return processed;
  }

  handleTypeChange(event) {
    const SELECTED_VALUE = event.detail.value;
    this.docType = SELECTED_VALUE;
    //object to map when the Description field is required based on the selected Type field.
    const DESCRIPTION_REQ_VALUES = {
      'LC - Misc': true,
      'Default': false
    };

    this.isDescriptionRequired = DESCRIPTION_REQ_VALUES[SELECTED_VALUE] || DESCRIPTION_REQ_VALUES['Default'];
  }
}