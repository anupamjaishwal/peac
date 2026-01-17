import { LightningElement, api } from 'lwc';
import SummaryAccount from '@salesforce/apex/SL_ContractInvoicedSummary.SummaryAccount';

const columns = [
    {label:'Type', fieldName: 'name'},
    {label:'Current Amount Due', fieldName:'currentAmount', type:'currency'},
    {label:'Past Due', fieldName:'pastDue', type:'currency'},
    {label: 'Total', fieldName:'Total', type:'currency'}

];
export default class SL_ContractInvoiceSummary extends LightningElement {
    @api recordId;
    columns = columns;
    data = [];
    dataString;

    connectedCallback() {
        SummaryAccount({AccountId: this.recordId})
        .then(result=>{
            this.data = result;
        });
        console.log(this.data);
    }

}