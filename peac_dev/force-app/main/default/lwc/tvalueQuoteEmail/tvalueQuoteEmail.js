import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/tvalueQuotePickerController.sendEmail';
import EMAIL_SUBJECT from '@salesforce/label/c.TvalueEmailSubject';
import EMAIL_SUCCESS_MESSAGE from '@salesforce/label/c.TvalueEmailSuccess';
import EMAIL_ERROR_MESSAGE from '@salesforce/label/c.TvalueEmailError';

export default class TvalueQuoteEmail extends LightningElement {
    @api selectedQuotes = [];
    toAddress = '';
    ccAddress = '';
    subject = EMAIL_SUBJECT;
    body = '';
    isSending = false;

    connectedCallback() {
        this.generateEmailBody();
    }

    generateEmailBody() {
        let emailBody = 'Here are the quote details you requested:\n\n';
        this.selectedQuotes.forEach(quote => {
            emailBody += `Quote: ${quote.quoteOptionName || ''}\n`;
            emailBody += `Description: ${quote.description || ''}\n`;
            emailBody += `Financed Amount: ${quote.financedAmount || ''}\n`;
            emailBody += `Term: ${quote.term || ''}\n`;
            emailBody += `Payment: ${quote.payment || ''}\n`;
            emailBody += `Advance Payments: ${quote.advancePayments || ''}\n`;
            emailBody += `Deferral: ${quote.deferral || ''}\n`;
            emailBody += `End Option: ${quote.endOption || ''}\n`;
            emailBody += `Notes: ${quote.notes || ''}\n\n`;
            emailBody += '--------------------------------------------------\n\n';
        });
        this.body = emailBody;
    }

    handleToChange(event) {
        this.toAddress = event.target.value;
    }

    handleCcChange(event) {
        this.ccAddress = event.target.value;
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }

    async handleSendEmail() {
        // Basic validation
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showToast('Error', 'Please fill in all required fields.', 'error');
            return;
        }

        this.isSending = true;
        try {
            await sendEmail({ 
                toAddress: this.toAddress, 
                ccAddress: this.ccAddress, 
                subject: this.subject, 
                body: this.body 
            });
            this.showToast('Success', EMAIL_SUCCESS_MESSAGE, 'success');
            this.handleClose();
        } catch (error) {
            const errorMessage = error.body ? error.body.message : EMAIL_ERROR_MESSAGE;
            this.showToast('Error', errorMessage, 'error');
        } finally {
            this.isSending = false;
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}