import { LightningElement, api } from 'lwc';
import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_DPImperative.hubExecute';

export default class SL_DPCustomerSummary extends LightningElement {
    @api recordId;
    isLoading;
    aggregated = {totalAmountDue: null,totalAmtPastDue: null,totalTax: null,miscellaneous: null,pastDue130: null,
        pastDue6190: null,totalCbr: null,totalActive: null,currentInvoiced: null,lateCharges: null, pastDue3160: null,
        pastDue90: null
    };

    connectedCallback(){
        this.isLoading = true;
        console.log("this.recordId: ", JSON.parse(JSON.stringify(this.recordId)));
        hubExecute({methodName: "getCustomerSummary", parameters: [this.recordId]})
        .then((result)=>{
            console.log("result: ", JSON.parse(JSON.stringify(result)));
            let obj = JSON.parse(result);
            console.log("obj: ", JSON.parse(JSON.stringify(obj)));
            if(obj){
                this.aggregated = obj;
            }else{
                showError(this, "Could not retrieve Summary for Customer.");
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{ this.isLoading = false; });
    }
}