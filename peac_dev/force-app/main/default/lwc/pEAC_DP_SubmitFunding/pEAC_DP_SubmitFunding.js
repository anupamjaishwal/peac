import { LightningElement, api, wire } from 'lwc';
import updateOpportunity from '@salesforce/apex/SL_SummaryAndDetail.updateOpportunity';
import checkRelatedRecords from '@salesforce/apex/SL_SummaryAndDetail.checkRelatedRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Stage_NAME from '@salesforce/schema/Opportunity.StageName';
import Id from '@salesforce/schema/Opportunity.Id';
import Name from '@salesforce/schema/Opportunity.Name';
import NextStep from '@salesforce/schema/Opportunity.NextStep';
import APP_STATUS from '@salesforce/schema/Opportunity.Application_Status__c';

const fields = [Id, Stage_NAME, APP_STATUS];

export default class PEAC_DP_SubmitFunding extends LightningElement {
    @api recordId;
    appstatusVal;
    errormessagetoshow = '';
    successmessagetoshow = '';
    showSpinner = true;
    /*@wire(getRecord, { recordId: '$recordId', fields: fields })
    opportunityrec({ error, data }) {
        this.showSpinner = true;
        console.log(error)
        comsole.log(data)
        if (error) {
            this.error = error;
            console.log('app',error);
            this.showSpinner = false;
        } else if (data) {
            //this.APPSTATUS = data.fields.Application_Status__c.value;
            console.log('this.APPSTATUS',data);
            //if(this.APPSTATUS == 'Automatically Approved' || this.APPSTATUS == 'Manually Approved'){
                this.updateOpportunityRec();
           } 
            else {
                console.log('else',this.APPSTATUS );
                this.errormessagetoshow = 'You are not allowed to submit for funding since the application is not approved.';
                this.successmessagetoshow = '';
                this.showSpinner = false;
            }
        
        }*/
    @wire(getRecord, { recordId: "$recordId", fields: fields })
    wiredRecord({ error, data }) {
        this.showSpinner = true;
        if (error) {
            console.log('error');
            this.showSpinner = false;
        } else if (data) {
            console.log('data');
            this.appstatusVal = data.fields.Application_Status__c.value;
            if (this.appstatusVal == 'Automatically Approved' || this.appstatusVal == 'Manually Approved') {
                this.checkRelatedRecords();
            } else {
                this.errormessagetoshow = 'You are not allowed to submit for funding since the application is not approved.';
                this.successmessagetoshow = '';
                this.showSpinner = false;
            }
        }

    }

    checkRelatedRecords() {
        console.log('this.recordId', this.recordId);
        checkRelatedRecords({
            oppId: this.recordId
        }).then(result => {
            console.log('result', result);
            if (result) {
                this.updateOpportunityRec();
            } else {
                this.errormessagetoshow = 'Documents have not been uploaded';
                this.successmessagetoshow = '';
                this.showSpinner = false;
            }
        });
    }




    //messagetoshow = '';// = 'Thank you for submitting your documents for funding. Your PEAC representative will contact you if anything else is required for funding.';
    updateOpportunityRec() {
        updateOpportunity({ recordId: this.recordId })
            .then(result => {
                console.log(result)
                this.successmessagetoshow = 'Thank you for submitting your documents for funding. Your PEAC representative will contact you if anything else is required for funding.';
                this.errormessagetoshow = '';
                this.showSpinner = false;
            })
            .catch(error => {
                console.log(error);
                this.errormessagetoshow = 'There is a system error. Please contact PEAC representative.';//+error.body.message;
                this.successmessagetoshow = '';
                this.showSpinner = false;
                /*const event = new ShowToastEvent({
                    title: 'Failed to update an Opportunity',   
                    message: error.body.message,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);*/

            })
            .finally(() => { });

    }

}