import { LightningElement, api, wire, track } from 'lwc';
import getGuidanceLineWarning
    from '@salesforce/apex/PEAC_DisplayGuidanceLineAmtMessageClass.getGuidanceLineWarning';

export default class Peac_guidance_amount_warning_message extends LightningElement {

    // Standard Lightning injected Id
    @api recordId;

    // Backward compatibility (DO NOT REMOVE)
    @api oppId;

    // Configured in Lightning App Builder
    @api parentObject = 'Opportunity';

    @track showWarning = false;
    @track warningMessage;

    @wire(getGuidanceLineWarning, {
        recordId: '$effectiveRecordId',
        objectName: '$parentObject'
    })
    wiredGuidance({ data, error }) {
        if (data) {
            this.showWarning = data.showWarning;
            this.warningMessage = data.message;
        } else if (error) {
            this.showWarning = false;
            this.warningMessage = null;
            // console.error(error);
        }
    }

    // Use recordId first, fallback to oppId (for old pages)
    get effectiveRecordId() {
        return this.recordId ? this.recordId : this.oppId;
    }
}