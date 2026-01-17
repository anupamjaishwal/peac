import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import hubExecute from '@salesforce/apex/SL_PartialBuyout.hubExecute';

export default class SL_CreateBuyout extends LightningElement {
    @api recordId;    
    isStarted = false;
    isLoading = false;
    isSubmitting = false;
    currentMode = "create";
    get isCreate(){ return this.currentMode == "create"; }
    get isSend(){ return this.currentMode == "send"; }
    get isViewSchedule(){ return this.currentMode == "viewSchedule"; }
    filteredQBs = [];
    visibleBuyouts = [];
    buyouts = [];
    successes = [];
    failures = [];
    oldBuyout;
    isPartial = false;
    selectedCAssets = [];
    createdBuyOuts = [];
    firstCreateError = "";

    connectedCallback(){
        this.isLoading = true;
        requestByContractNumber({recordId: this.recordId, nitroApiOption: "getValidQB", additionalKeys: ""})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj.filteredQBs){
                this.filteredQBs = obj.filteredQBs;
                this.visibleBuyouts = obj.quoteBuyoutTypes.split(';');
            } else {
                showError(this, JSON.stringify(obj), "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleIsPartial(event){
        this.isPartial = event.detail.isPartial;
    }

    handleStartQuote(){
        this.isStarted = true;
    }

    handleChangeQB(event){
        this.visibleBuyouts = event.target.value;
    }

    handleSelectCAssets(event){
        this.selectedCAssets = event.detail;
    }

    handleSaveQB(){
        this.isSubmitting = true;
        this.successes = [];
        this.firstCreateError = "";
        requestByContractNumber({recordId: this.recordId, nitroApiOption: "saveQB", additionalKeys: this.visibleBuyouts.join(';')})
        .then((result)=>{
            if(result == "success"){
                this.isSubmitting = false;
                this.buyouts = [...this.visibleBuyouts];
                this.createBuyout();
            } else {
                showError(this, JSON.stringify(obj), "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{this.isSubmitting = false;});
    }

    createBuyout(){
        if(this.buyouts.length > 0){
            let quoteType = this.buyouts.splice(0, 1).toString();
            let additionalKeys = `{"BuyoutType": ${JSON.stringify(quoteType)}, "Assets": ${JSON.stringify(this.selectedCAssets)}}`;
            this.isLoading = true;
            requestByContractNumber({recordId: this.recordId, nitroApiOption: "createBuyout", additionalKeys: additionalKeys})
            .then((result)=>{
                let obj = JSON.parse(result);
                let responseObj = obj.Response || obj.response.Response;
                if(responseObj){
                    if(responseObj.Success.toLowerCase() == "true"){
                        this.successes.push(quoteType);
                        this.createdBuyOuts.push({Buyout_Type__c: quoteType, Quote_Sequence__c: responseObj.QuoteSeq });
                    } else {
                        let currentError = responseObj.Errors.join(',');
                        if(this.firstCreateError != currentError){
                            showError(this, currentError);
                            this.firstCreateError = currentError;
                        }
                    }
                } else {
                    showError(this, JSON.stringify(obj), "Response came in unexpected format");
                }
                this.createBuyout();
            })
            .catch((error)=>{
                showError(this, error);
            })
            .finally(()=>{this.isLoading = false;});
        } else {
            if(this.successes.length > 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "The following Buyout Quotes were successfully sent: " + this.successes,
                        variant: 'success'
                    })
                );
                this.saveBuyoutRecords();
            }
        }
    }

    saveBuyoutRecords(){
        this.isLoading = true;
        let parameters = [this.recordId, JSON.stringify(this.createdBuyOuts), JSON.stringify(this.selectedCAssets)];
        hubExecute({methodName: "saveBuyouts", parameters: parameters})
        .then((result)=>{
            console.log('save buyout result:', result);
            if(result == "success"){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "The Buyouts were successfully saved",
                        variant: 'success'
                    })
                );
            } else {
                showError(this, JSON.stringify(result));
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{
            this.createdBuyOuts = [];
            this.isLoading = false;
        });
    }

    handleRefresh(){
        this.template.querySelector("c-s-l_-view-buyout").refreshBuyouts();
    }

    handleSendDelayed(){
        this.currentMode = "send";
    }

    handleCancelSend(){
        this.currentMode = "create";
    }

    handleViewSchedule(){
        this.currentMode = "viewSchedule";
    }
}