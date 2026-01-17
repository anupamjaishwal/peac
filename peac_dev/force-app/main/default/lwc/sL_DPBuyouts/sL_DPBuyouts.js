import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';
import buyoutCreationV2 from '@salesforce/apex/SL_SummaryAndDetail.buyoutCreationV2';
import toggleLockContract from '@salesforce/apex/SL_SummaryAndDetail.toggleLockContract';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';

export default class SL_DPBuyouts extends LightningElement {
    @api recordId;    
    isLoading = false;
    buyouts = [];
    successes = [];
    quoteBuyoutTypesToShow = '';
    buyoutTypesError = '';

    connectedCallback(){
        // remove below line after testing
        // this.createBuyoutTypes(true);
    }

    handleCreateBuyouts(){
        this.isLoading = true;
        toggleLockContract({contractId: this.recordId, isLocking: true})
        .then((result)=>{
            let obj = JSON.parse(result);
            console.log("locking obj: ", obj);
            if(obj.message && obj.message == "success"){
                this.createBuyoutTypes(false);
            } else {
                showError(this, JSON.stringify(obj), "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            showError(this, error);
            this.isLoading = false;
        })
        .finally(()=>{});
    }

    createBuyoutTypes(justRetrieve){
        console.log("justRetrieve: ", justRetrieve);
        console.log("this.quoteBuyoutTypesToShow: ", this.quoteBuyoutTypesToShow);
        if(justRetrieve || (!justRetrieve && !this.buyouts.length && !this.buyoutTypesError)){
            buyoutCreationV2({recordId: this.recordId})
            .then((result)=>{
                let obj = JSON.parse(result);
                if(obj.quoteBuyouts){
                    this.buyouts = obj.quoteBuyouts.split(';');
                    this.quoteBuyoutTypesToShow = obj.quoteBuyouts;
                    if(!justRetrieve){
                        this.createBuyoutDP();
                    }else{
                        this.isLoading = false;
                    }
                }else{
                    this.isLoading = false;
                    if(!justRetrieve){
                        showError(this, obj.errmessage);
                        this.putLockBack();
                    }else{
                        this.buyoutTypesError = obj.errmessage;
                    }
                }
                
            }).catch((error)=>{
                showError(this,error);
                this.isLoading = false;
                if(!justRetrieve){
                    showError(this, error);
                    this.putLockBack();
                }else{
                    this.buyoutTypesError = error;
                }
            })
        }else if(this.buyouts.length){
            this.createBuyoutDP();
        }else{
            if(!justRetrieve){
                showError(this, this.buyoutTypesError);
                this.putLockBack();
            }
        }
        
    }

    createBuyoutDP(){
        if(this.buyouts.length > 0){
            let quoteType = this.buyouts.splice(0, 1).toString();
            //this.isLoading = true;
            requestByContractNumber({recordId: this.recordId, nitroApiOption: "createBuyoutDP", additionalKeys: quoteType})
            .then((result)=>{
                let obj = JSON.parse(result);
                let responseObj = obj.Response || obj.response.Response;
                if(responseObj){
                    if(responseObj.Success.toLowerCase() == "true"){
                        this.successes.push(quoteType);
                        // this.createBuyoutDP();
                    } else {
                        showError(this, responseObj.Errors.join(','));
                        // this.putLockBack();
                    }
                } else {
                    showError(this, JSON.stringify(obj), "Response came in unexpected format");
                    // this.putLockBack();
                }
                this.createBuyoutDP();
            })
            .catch((error)=>{
                showError(this, error);
                this.putLockBack();
            })
            .finally(()=>{/*this.isLoading = false;*/});
        } else {
            if(this.successes.length > 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "The following Buyout Quotes were successfully sent: " + this.successes,
                        variant: 'success'
                    })
                );
                this.successes = [];
            }
            this.putLockBack();
        }
    }

    putLockBack(){
        toggleLockContract({contractId: this.recordId, isLocking: false})
        .then((result)=>{
            console.log('putLockBack result: ', result);
        }).catch((error)=>{
            showError(this,error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    // handleRefresh(){
    //     this.template.querySelector("c-s-l_-view-buyout").refreshBuyouts();
    // }
}