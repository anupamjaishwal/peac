import { LightningElement, api } from 'lwc';
import getQueueId from '@salesforce/apex/SL_EscalateCaseAction.getQueueId';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/Case.Id';
import ESCALATED_FIELD from '@salesforce/schema/Case.IsEscalated';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import OWNER_ID_FIELD from '@salesforce/schema/Case.OwnerId';

export default class SL_EscalateCaseAction extends LightningElement {
    @api recordId;
  
    isExecuting = false;
    queueId;  
    @api invoke() {
        if (!this.isExecuting) {
            this.isExecuting = true;
            getQueueId()
            .then(result => {
                this.queueId = result;

                // Create the recordInput object
                const fields = {};
                fields[ID_FIELD.fieldApiName] = this.recordId;
                fields[ESCALATED_FIELD.fieldApiName] = true;
                fields[STATUS_FIELD.fieldApiName] = 'Escalated';
                fields[OWNER_ID_FIELD.fieldApiName] = this.queueId;
                const recordInput = { fields };

                updateRecord(recordInput)
                    .then(() => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Case successfully escalated',
                                variant: 'success'
                            })
                        );
                    })
                    .catch(error => {
                        this.showError(error);
                    })
                    .finally(() => this.isExecuting = false );
            })
            .catch(error => {
                this.showError(error);
            });
            
        }
    }

    showError(error){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error on the escalation process',
                message: error.body.message,
                variant: 'error'
            })
        );
    }
}