import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import { generateUrl } from "lightning/fileDownload";
import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_ViewInvoicePdf.hubExecute';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';

export default class SL_ViewInvoicePdf extends NavigationMixin(LightningElement) {
    invoiceUrl = '';
    contractUrl = '';
    @track isLoading = true;
    @wire(IsConsoleNavigation) isConsoleNavigation;
    @wire(CurrentPageReference)
    pageRef;

    connectedCallback(){
        hubExecute({methodName: "generateUrl", parameters: [this.pageRef.state.c__invoiceId]})
        .then((result)=>{
            console.log("invoicePdf result: ", result);
            let obj = JSON.parse(result);
            if(obj && obj.invoiceLink){
                let contractId = obj.contractId;
                this.invoiceUrl = obj.invoiceLink;
                if(obj.isIL10 || (!obj.isIL10 && !obj.isMigrated)){// DP-1584 Misael Romero
                    // this.isLoading = false;
                    this.invoiceUrl = generateUrl(obj.invoiceLink);
                    console.log("this.invoiceUrl: ", JSON.parse(JSON.stringify(this.invoiceUrl)));
                    
                    
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "the Invoice PDF was downloaded successfully, please find it in your browser downloads",
                            variant: 'success'
                        })
                    );
                    window.location = this.invoiceUrl;
                    this.closeTab();


                }else{
                    if(obj.isMigrated){
                        this.isLoading = false;
                        this.closeTab();
                        window.open(this.invoiceUrl, '_blank');
                        
                    }else{
                        // this[NavigationMixin.Navigate]({
                        //     type: 'standard__webPage',
                        //     attributes: {
                        //       url: this.invoiceUrl
                        //     }
                        // });
                    }
                }
                this.goToInvoices(contractId);
            } else {
                showError(this, "No Invoice Link recieved." + (obj.errorMessage? " " + obj.errorMessage.toString(): ""));
                this.isLoading = false;
                this.closeTab();

                if(obj.contractId){
                    this.goToInvoices(obj.contractId);
                }
            }
        })
        .catch((error)=>{
            showError(this, error);
            this.isLoading = false;
        })
        .finally(()=>{});
    }

    goToInvoices(contractId){
        this[NavigationMixin.Navigate]({
            type: "standard__recordRelationshipPage",
            attributes: {
              recordId: contractId,
              objectApiName: "Contract__c",
              relationshipApiName: "Invoices__r",
              actionName: "view",
              componentName:"View Invoice",
            },
          });
    }

    async closeTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        await closeTab(tabId);
    }
}