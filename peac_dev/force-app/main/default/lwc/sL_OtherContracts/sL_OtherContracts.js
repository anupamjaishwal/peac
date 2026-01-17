import { LightningElement, api, track } from 'lwc';
import getContracts from '@salesforce/apex/SL_OtherContractsController.getContractList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    { label: 'Contract Number', fieldName: 'Name', sortable: true, type: 'text' },
    { label: 'Contract Balance Remaining', fieldName: 'Contract_Balance_Remaining__c', sortable: true, type: 'Currency' },
    { label: 'Total Past Due', fieldName: 'Total_Past_Due__c', sortable: true, type: 'Currency' },
    { label: 'Delinquency Status Code', fieldName: 'Delinquency_Status_Code__c', sortable: true, type: 'text' },
    { label: 'Status', fieldName: 'Status__c', sortable: true,  type: 'text' },
    { label: 'Commencement', fieldName: 'Commencement_Date__c', sortable: true, type: 'date' },
    { label: 'Term Date', fieldName: 'Term_Date__c', sortable: true, type: 'date' },
    { label: 'Owner', fieldName: 'OwnerName', sortable: true, type: 'text' }
];

export default class SL_OtherContracts extends LightningElement {
    @track error;
    @track contractList;
    @api recordId;
    columns = columns;

    connectedCallback(){
        this.getContracts();
    }

    getContracts(){
        getContracts({recordId : this.recordId})
                .then((result) => {
                    if(result){
                        result.forEach(element => {
                            element.OwnerName = element.Owner.Name
                        });
                        this.contractList = result;
                    }                    
                })
                .catch(error => {console.log(error);
                    this.error = result;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Getting Contracts',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });

    }
}