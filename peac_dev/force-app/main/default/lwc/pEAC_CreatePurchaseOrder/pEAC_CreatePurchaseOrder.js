import { LightningElement, api } from 'lwc';
import createPurchaseOrders from '@salesforce/apex/PEAC_PurchaseOrderController.createPurchaseOrders';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import Custom Labels
import PEAC_PURCHASE_ORDER from '@salesforce/label/c.PEAC_Purchase_Order';
import PEAC_PURCHASE_ORDER_ERROR from '@salesforce/label/c.PEAC_Purchase_Order_Error';


export default class PEAC_CreatePurchaseOrder extends LightningElement {
    @api recordId;
   
    @api invoke() {
    createPurchaseOrders({ OpportunityId: this.recordId })
        .then(async (result) => { 
            if(result === PEAC_PURCHASE_ORDER) {
                this.showToast('Success', PEAC_PURCHASE_ORDER, 'success');
            
            }else if(result === PEAC_PURCHASE_ORDER_ERROR) {
                this.showToast('Information', PEAC_PURCHASE_ORDER_ERROR, 'info');
            }
        })
        .catch((error) => {
            this.showToast('Error', error.body?.message || 'An unknown error occurred', 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}