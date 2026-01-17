import { LightningElement, api } from 'lwc';
import deleteExternalFirst from '@salesforce/apex/SL_DeleteCMBillable.deleteExternalFirst';

export default class SL_DeleteCMBillable extends LightningElement {
    isLoading;
    @api recordId;
    contractId = null;
    messageTitle = "";
    mainMessage = "";
    variant = "success";
    get divClass(){ return "slds-notify slds-notify_toast slds-theme_" + this.variant; }
    get iconClass(){ return "slds-icon_container slds-icon-utility-" + this.variant + " slds-m-right_small slds-no-flex slds-align-top"; }
    get iconPath(){ return "/_slds/icons/utility-sprite/svg/symbols.svg#" + this.variant; }

    connectedCallback(){
        this.isLoading = true;
        deleteExternalFirst({action: "deleteExternal", recordId: this.recordId})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj.Response){
                if(obj.Response.Success.toLowerCase() == "true"){
                    this.isLoading = true;
                    deleteExternalFirst({action: "deleteInternal", recordId: this.recordId})
                    .then((result)=>{
                        let obj = JSON.parse(result);
                        if(obj.isSuccess){
                            this.contractId = obj.contractId;
                            this.messageTitle = "Success";
                            this.mainMessage = "Misc Billable Deleted successfully.";
                            this.variant = "success";
                            setTimeout(()=>{ this.handleClose(); }, 3000);
                        }else{
                            this.showError("Unknown error.");
                        }
                    })
                    .catch((error)=>{
                        this.showError(error);
                    })
                    .finally(()=>{this.isLoading = false;});
                } else {
                    this.showError(obj.Response.Errors);
                }
            } else {
                this.showError(JSON.stringify(obj), "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleClose(event){
        if(event){
            event.preventDefault();
        }
        document.dispatchEvent(new CustomEvent("close", {detail: {divClass: this.contractId? ".goToContract": ".notDeleted"}}));
    }

    showError(error, customTitle){
        let message = (error && error.body && error.body.message) || error.message || error;
        let title = customTitle || 'Error';
        this.messageTitle = title;
        this.mainMessage = message;
        this.variant = "error";
    }
}