import { LightningElement, api } from 'lwc';
 
import getLatestInfoleaseIntegrationDetails
    from '@salesforce/apex/PEAC_ValidateOpportunityBookToInfolease.getLatestInfoleaseIntegrationDetails';
import validateResidualThreshold
    from '@salesforce/apex/PEAC_ValidateOpportunityBookToInfolease.validateResidualThreshold';
 
export default class PeacOpportunityInfoleaseProcessingBanner extends LightningElement {
    @api recordId;
 
    wrapperData;
    apexError;
    thresholdData;
 
    connectedCallback() {
        this.loadIntegrationDetails();
        this.loadThreshold();
    }
 
    loadIntegrationDetails() {
        getLatestInfoleaseIntegrationDetails({ opportunityId: this.recordId })
            .then(result => {
                this.wrapperData = result;
                this.apexError = undefined;
            })
            .catch(error => {
                this.wrapperData = null;
                this.apexError = error;
            });
    }
 
    loadThreshold() {
    validateResidualThreshold({ recordId: this.recordId })
        .then(result => {
            console.log('Threshold Response:', JSON.stringify(result));
            this.thresholdData = result;
        })
        .catch(error => {
            console.error('Threshold Error:', error);
        });
    }
 
    get showTable() {
        return this.wrapperData?.hasIntegrationRecord === true;
    }
 
    get createdDate() {
        return this.wrapperData?.lastIntegrationDate;
    }
 
    get integrationStatus() {
        return this.wrapperData?.integrationStatus;
    }
 
    get infoleaseError() {
        return this.wrapperData?.infoleaseError;
    }
 
    get integrationLogUrl() {
        const id = this.wrapperData?.integrationLogId;
        return id ? `/lightning/r/Integration_Log__c/${id}/view` : null;
    }
 
    get showWarning() {
        return this.thresholdData?.showWarning === true;
    }
 
    get warningMessage() {
        return this.thresholdData?.message;
    }
}