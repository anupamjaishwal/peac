import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import runGDSRescore from '@salesforce/apex/PEAC_LoanAppProcessor.runGDSRescore';

export default class PEAC_LoanGDSRescore extends LightningElement {
    @track _recordId;
    hasRun = false; 

    @api
    set recordId(value) {
        this._recordId = value;

        if (!this.hasRun && value) {
            this.hasRun = true;
            this.runGDSRescore();
        } else {
            //console.log('Duplicate recordId assignment — skipping runGDSRescore');
        }
    }

    get recordId() {
        return this._recordId;
    }

    runGDSRescore() {
        runGDSRescore({ oppId: this._recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Gds Score Requested. Please wait up to 30 seconds for the process to complete',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Something went wrong',
                        variant: 'error'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }
}