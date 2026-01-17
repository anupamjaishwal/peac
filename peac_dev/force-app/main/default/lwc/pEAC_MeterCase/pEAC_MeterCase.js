import { LightningElement,wire,api,track} from 'lwc';
import getCaseReason from '@salesforce/apex/PEAC_MeterReadCaseController.getCaseReason';
import savebButton from "@salesforce/label/c.PEAC_Save";
import caseTitle from "@salesforce/label/c.PEAC_Case_Title";
import createCase from "@salesforce/label/c.PEAC_Create_Case";
import reasonType from "@salesforce/label/c.PEAC_Reason_Type";
import successMessage from "@salesforce/label/c.PEAC_Success_Case_Message";
import loadingMessage from "@salesforce/label/c.PEAC_Loading";
import headerMessage from "@salesforce/label/c.PEAC_Modal_Header";
import closeModal from "@salesforce/label/c.PEAC_Close";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OWNER_FILED from '@salesforce/schema/Case.OwnerId';
import REASON_FIELD from '@salesforce/schema/Case.Reason';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import getDetailedCase from '@salesforce/apex/PEAC_MeterReadCaseController.getDetailedCase';

export default class PEAC_MeterCase extends LightningElement {
    label = {
        savebButton,caseTitle,createCase,reasonType,
        successMessage,loadingMessage,headerMessage,closeModal
    };
    error='';
    ownerId = OWNER_FILED;
    reasonField = REASON_FIELD;
    statusField = STATUS_FIELD;
    description = DESCRIPTION_FIELD
    fields = [OWNER_FILED, REASON_FIELD, STATUS_FIELD];
    serviceRecordTypeId;
    caseobject = CASE_OBJECT;
    showModal = false;
    reasonPickList = [];
    reasonSelected = '';
    descriptionDeatis= '';
    showForm = false;    
    caseNumber;
    caseDes;
    showspinner = false;
    
    connectedCallback(){

        
        getCaseReason().then(result => {
            if (result) {
                this.reasonPickList = [];
                for (let key in result ) {
                    this.reasonPickList.push({ label: key, value: result[key] });
                }
            }
            
        }).catch(error => {
            this.error = error;
        });
        
    }
    displayModal(event){
        this.showModal = true;
    }
    hidemodel(event){
        this.showModal = false;
    }
    closeModal(event){
        this.resetFields();
    }
    
    handleChange(event) {
        this.showspinner = true;
        this.reasonSelected = event.detail.value;
        getDetailedCase({meterReason: this.reasonSelected}).then(result => {
            let caseRes  = result;
            this.descriptionDeatis = caseRes.defaultTemplate;
            if( caseRes.defaultTemplate == '' ||  caseRes.defaultTemplate == null)
            {
                this.showForm = false;
            }
            else{
                this.showForm = true; 
            }
            this.caseDes = caseRes;
            this.showspinner = false;
            
        }).catch(error => {
            this.error = error;
            this.showspinner = false;
            this.showForm = false;
        });
        
        //this.showForm = true;
        
    }

    handleSubmit(event)
    {
        this.showspinner = true;
        event.preventDefault();
        const fields = event.detail.fields;
        fields.OwnerId = this.caseDes.ownerId;
        fields.RecordTypeId = this.caseDes.recordTypeIdValue;
        fields.Account = this.caseDes.dealerAccount;
        fields.Contact = this.caseDes.contactUser;
        fields.Reason = this.reasonSelected;
        fields.Subject = this.reasonSelected;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        

    }
    handleSucess(event){
        this.showspinner = false;
        const toastEvent = new ShowToastEvent({
            title: this.label.caseTitle,
            message: this.label.successMessage,
            variant: "success"
        });
        this.dispatchEvent(toastEvent);
        this.resetFields();
     }
     resetFields(){
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach( field => {
            field.reset();
        });
        this.reasonSelected = '';
        this.showForm = false;
        this.showModal = false;
    }

     
}