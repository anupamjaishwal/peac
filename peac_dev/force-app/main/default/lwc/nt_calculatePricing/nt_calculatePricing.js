import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import validateAndRunPricing from '@salesforce/apex/NT_CalculatePricingController.validateAndRunPricing';

export default class Nt_calculatePricing extends LightningElement {
    @api recordId;

    @api async invoke() {
        try {
            const result = await validateAndRunPricing({ opportunityId: this.recordId });
            if (result.isInProgress) {
                this.showToast('Pricing In Progress', result.message, 'warning');
            } else if (!result.isValid) {
                this.showToast('Cannot Calculate Pricing', result.message, 'error');
            } else {
                this.showToast(
                    'Pricing Started',
                    'Pricing calculation has been started. You will receive a notification when it completes.',
                    'success'
                );
            }
        } catch (error) {
            this.showToast('Error', this.reduceError(error), 'error');
        } finally {
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unknown error occurred.';
    }
}