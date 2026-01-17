import { LightningElement, api, wire } from 'lwc';
import CURRENCY from '@salesforce/i18n/currency';
import getTopApprovedOffer from '@salesforce/apex/optyApprovalController.getTopApprovedOffer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ApprovalFieldSection extends LightningElement {
    

    /** Record context **/
    @api recordId;
    @api objectApiName = 'Opportunity';    
    additionalRequirements = '';
    docsOut = '';


    /** Section header label (keep as Approval) **/
    @api sectionLabel = 'Approval'; // displayed text
    @api collapsedByDefault = false;

    /** Collapsible state for SLDS section **/
    isOpen = !this.collapsedByDefault;
    get sectionClass() {
        return `slds-section ${this.isOpen ? 'slds-is-open' : 'slds-is-closed'}`;
    }
    toggleSection = () => {
        this.isOpen = !this.isOpen;
    };

    /** LEFT: Approved_Offer__c values (always read-only) **/
    offer;
    error;

    @wire(getTopApprovedOffer, { opptyId: '$recordId' })
    wiredOffer({ data, error }) {
        this.offer = data;
        this.error = error;
    }

    get offerId() {
        return this.offer?.Id ?? null;
    }
    get approvedFrequency() {
        return this.offer?.Approved_Frequency__c ?? '';
    }
    get term() {
        return this.offer?.Term__c ?? '';
    }
    get offerAmount() {
        return this.offer?.Offer_Amount__c ?? null;
    }
    get currencyCode() {
        return CURRENCY;
    }
    
    handleAdditionalRequirementsChange = (e) => {
        this.additionalRequirements = e.target.value;
    };

    handleDocsOutChange = (e) => {
        this.docsOut = e.target.value;
    }

    /** Right: edit state only affects the right column **/
    isEditing = false;

    handleEdit() {
        this.isEditing = true;
    }
    handleCancel() {
        this.isEditing = false;
    }
    
    handleSubmit = (event) => {
        // IMPORTANT: put your custom input values into the record fields
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    };

    handleSuccess() {
        this.isEditing = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Approval fields updated.',
            variant: 'success'
        }));
    }
    handleError(evt) {
        const msg = (evt.detail && evt.detail.message) ? evt.detail.message : 'Update failed.';
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'sticky'
        }));
    }

    /** Legacy properties kept for safe deployment while pages still reference them **/
    @api cardTitle;   // deprecated
    @api fieldsLeft;  // deprecated
    @api fieldsRight; // deprecated
    @api fieldsCsv;  // deprecated
   
    
    isOpen = true;
    connectedCallback() {
    this.isOpen = !this.collapsedByDefault;
    }

    get sectionClass() {
    return `slds-section ${this.isOpen ? 'slds-is-open' : 'slds-is-closed'}`;
    }
    get chevronIcon() {
    return this.isOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }
    toggleSection = () => {
    this.isOpen = !this.isOpen;

    }
}