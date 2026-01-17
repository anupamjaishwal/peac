import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import PortalUserRestricted from '@salesforce/label/c.PEAC_Portal_User_Restricted';
import getMaxCBR from '@salesforce/apex/SL_ManageBalanceCBR.getMaxCBR';
import hubExecute from '@salesforce/apex/SL_ManageBalanceCBR.hubExecute';


export default class SL_ManageBalanceCbr extends LightningElement {
    isLoading;
    wiredResult;
    maximumBalanceCbr;
    maximumBalanceCbr_XBS_ADR;
    isUpdated = false;
    isAllowed = false;
    PortalUserRestrictedMessage = PortalUserRestricted;
    get isDisabled(){ return this.isUpdated || !this.isAllowed; }

    isShowingToast = false;
    messageTitle = "";
    mainMessage = "";
    variant = "success";
    get divClass(){ return "slds-notify slds-notify_toast slds-theme_" + this.variant; }
    get iconClass(){ return "slds-icon_container slds-icon-utility-" + this.variant + " slds-m-right_small slds-no-flex slds-align-top"; }
    get iconPath(){ return "/_slds/icons/utility-sprite/svg/symbols.svg#" + this.variant; }

    @wire(getMaxCBR, {})
    getCurrentMaxCBR(result){
        this.wiredResult = result;
        if(result.data){
            this.maximumBalanceCbr = result.data[0];
            this.maximumBalanceCbr_XBS_ADR = result.data[1];

        }else if(result.error){
            this.showError(result.error);
        }
    }

    connectedCallback(){
        this.isLoading = true;
        hubExecute({methodName: 'checkPermission', methodParameters: []})
        .then((result)=>{
            this.isAllowed = result === "true";
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleChangeMax(event){
        this.maximumBalanceCbr = event.detail.value;
    }

    handleChangeMax_XBS_ADR(event){
        this.maximumBalanceCbr_XBS_ADR = event.detail.value;
    }

    handleCancel(){
        this.goBack();
    }

    handleUpdateCBR(){
        this.isLoading = true;
        hubExecute({methodName: 'saveMaxCBR', methodParameters: [this.maximumBalanceCbr , this.maximumBalanceCbr_XBS_ADR]})
        .then((result)=>{
            if(result === "success"){
                this.isShowingToast = true;
                this.messageTitle = "Success";
                this.mainMessage = "The Maximum Balance CBR has been updated successfully, it might take a while for the Collection Groups to be updated and the Assignees to be changed.";
                this.variant = "success";
                setTimeout(() => {
                    this.handleCloseToast();
                }, 4000);
            } else {
                this.showError(result);
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});        
    }

    handleCloseToast(){
        this.isShowingToast = false;
        if(this.variant == "success"){
            refreshApex(this.wiredResult);
            this.goBack();
        }
    }

    goBack(){
        this.isShowingToast = false;
        window.history.back();
        //window.location = window.location.origin + "/lightning/r/"+ this.contractId + "/related/Contract_Attachments__r/view";
    }

    showError(error, customTitle){
        this.isShowingToast = true;
        let message = (error && error.body && error.body.message) || error.message || error;
        let title = customTitle || 'Error';
        this.messageTitle = title;
        this.mainMessage = message;
        this.variant = "error";
    }
}