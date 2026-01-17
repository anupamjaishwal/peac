import { LightningElement, wire, api } from 'lwc';
import getContacts from '@salesforce/apex/SL_ContractPGController.getContacts';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
 
// columns
const columns = [
    {
        label: 'Name',
        fieldName: 'ConName',
        type: 'url',
        typeAttributes: {label: { fieldName: 'FirstName' }, target: '_blank'}
    },
    {
        label: 'Email',
        fieldName: 'Email',
        type: 'email',
        editable: false
    }, 
    {
        label: 'Credit Score',
        fieldName: 'Credit_Score__c',
        type: 'number',
        editable: true
    }
];
 
export default class SL_ContractPG extends LightningElement {
    columns = columns;
    consData = [];
    @api recordId;
    saveDraftValues = [];

    @wire(getContacts, {contractId : '$recordId'})
    wiredContacts(result) {
        this.wireResult = result;
        if (result.data) {

            let data = result.data;
            let tempConList = []; 
            data.forEach((record) => {
                let tempConRec = Object.assign({}, record);  
                tempConRec.ConName = '/' + tempConRec.Id;
                tempConList.push(tempConRec);
            });
            
            this.consData = tempConList;
            this.error = undefined;

        } else if (result.error) {
            this.error = result.error;
            console.log('this.error : ',this.error);
        }

    }

    handleSave(event) {
        this.saveDraftValues = event.detail.draftValues;
        const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
 
        // Updating the records using the UiRecordAPi
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.ShowToast('Success', 'Records Updated Successfully!', 'success', 'dismissable');
            this.saveDraftValues = [];
            return this.refresh();
        }).catch(error => {
            this.ShowToast('Error', 'An Error Occured!!', 'error', 'dismissable');
        }).finally(() => {
            this.saveDraftValues = [];
        });
    }
 
    ShowToast(title, message, variant, mode){
        const evt = new ShowToastEvent({
                title: title,
                message:message,
                variant: variant,
                mode: mode
            });
        this.dispatchEvent(evt);
    }
 
    // This function is used to refresh the table once data updated
    async refresh() {
        await refreshApex(this.wireResult);
    }
}