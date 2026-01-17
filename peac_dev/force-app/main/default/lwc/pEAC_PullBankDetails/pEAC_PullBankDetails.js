/**********************************************************************************************
 * @Description:This class is used to invoke gds callout as Ocrolus
 * @Author:Rajesh Kumar(LTIMindtree)
 * Created Date:07/15/2025
 * User Story:SAL-5458
 **********************************************************************************************/
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import pullBankDetails from '@salesforce/apex/PEAC_LoanAppProcessor.pullBankDetails';

export default class PEAC_PullBankDetails extends LightningElement {

    @track _recordId;
    hasRun = false; 

    @api set recordId(value) {
        this._recordId = value;
        if (!this.hasRun && value) {
            this.hasRun = true;
            this.pullBankDetails();
        } 
        else {
                console.log('Duplicate recordId assignment — skipping runGDSRescore');
            }
    }
    
    get recordId() {
        return this._recordId;
    }

    pullBankDetails() {
        pullBankDetails({
            oppId: this._recordId
        }).then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Pull Bank Details Requested. Please wait up to 30 seconds for the process to complete',
                    variant: 'success'
                }));
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