import { api, LightningElement } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // check if still giving error
import { showError } from 'c/sL_Common';
import buyoutCreationV2 from '@salesforce/apex/SL_SummaryAndDetail.buyoutCreationV2';
import toggleLockContract from '@salesforce/apex/SL_SummaryAndDetail.toggleLockContract';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import sendCreateBuyout from '@salesforce/apex/SL_SummaryAndDetail.sendCreateBuyout';
import hubExecute from '@salesforce/apex/SL_PartialBuyout.hubExecute';
import sendBuyoutCreationEmail from '@salesforce/apex/SL_SummaryAndDetail.sendBuyoutCreationEmail';

const COLUMNS = [
    { label: "Asset Id", fieldName: "Asset_Number__c" },
    { label: "Model", fieldName: "Model_Number__c" },
    { label: "Serial Number", fieldName: "Serial_Number__c" }
];

export default class SlPartialBuyout extends LightningElement {
    @api contractId;
    @api isDealerPortal;
    @api emailTo = [];
    isLoading;
    isPartialBuyout;
    columns = COLUMNS;
    get cardTitle() { return this.isDealerPortal ? /*"Create Buyouts"*/ "" : ""; }

    allCAssets = [];
    selectedCAssets = [];
    errorMessage = "";
    get noCAssetsSelected() { return !this.selectedCAssets.length; }

    buyouts = [];
    successes = [];
    quoteBuyoutTypesToShow = '';
    buyoutTypesError = '';
    createdBuyOuts = [];
    firstCreateError = "";
    genericMessage = "To process your request, please contact customer service at buyouts@peacsolutions.com. Thank You.";

    connectedCallback() {
        this.isLoading = true;
        hubExecute({ methodName: "getCAssetsInfo", parameters: [this.contractId] })
            .then((result) => {
                let obj = JSON.parse(result);
                console.log("obj: ", JSON.parse(JSON.stringify(obj)));
                if (obj.contractAssets) {
                    this.errorMessage = "";
                    this.allCAssets = [...obj.contractAssets];
                } else {
                    if (obj.isPartialBuyout) {
                        this.showErrorMess("No Contract Assets found.");
                    }
                }
                this.isPartialBuyout = obj.isPartialBuyout && obj.isIL10;
                this.dispatchEvent(new CustomEvent("loadinfo", { detail: { isPartial: this.isPartialBuyout } }));
            })
            .catch((error) => {
                console.log("technical error: ", error);
                this.showErrorMess(this.genericMessage);
            })
            .finally(() => { this.isLoading = false; });
    }

    handleSelection(event) {
        this.selectedCAssets = [];
        event.detail.selectedRows.forEach(contractAsset => {
            this.selectedCAssets.push(contractAsset.Asset_Number__c);
        });
        this.dispatchEvent(new CustomEvent("selectcassets", { detail: this.selectedCAssets }));
        if (!this.noCAssetsSelected) {
            this.errorMessage = "";
        }
    }

    showErrorMess(message) {
        this.errorMessage = message;
        if (showError) {
            showError(this, message);
        }
    }

    handleCreateBuyouts() {
        if (!this.errorMessage) {
            if (this.noCAssetsSelected) {
                this.errorMessage = "Please select at least one Contract Asset";
            } else {
                this.startCreateBuyouts();
            }
        }
    }

    startCreateBuyouts() {
        this.isLoading = true;
        toggleLockContract({ contractId: this.contractId, isLocking: true })
            .then((result) => {
                let obj = JSON.parse(result);
                console.log("locking obj: ", obj);
                if (obj.message && obj.message == "success") {
                    this.createBuyoutTypes(false);
                } else {
                    this.showErrorMess(JSON.stringify(obj), "Response came in unexpected format");
                }
            })
            .catch((error) => {
                console.log("technical error: ", error);
                this.showErrorMess(this.genericMessage);
                this.isLoading = false;
            })
            .finally(() => { });
    }

    createBuyoutTypes(justRetrieve) {
        console.log("justRetrieve: ", justRetrieve);
        console.log("this.quoteBuyoutTypesToShow: ", this.quoteBuyoutTypesToShow);
        if (justRetrieve || (!justRetrieve && !this.buyouts.length && !this.buyoutTypesError)) {
            buyoutCreationV2({ recordId: this.contractId })
                .then((result) => {
                    let obj = JSON.parse(result);
                    console.log('buyoutCreationV2 result', JSON.stringify(obj));
                    if (obj.quoteBuyouts) {
                        this.buyouts = obj.quoteBuyouts.split(';');
                        this.quoteBuyoutTypesToShow = obj.quoteBuyouts;
                        if (!justRetrieve) {
                            this.createPartialBuyout();
                        } else {
                            this.isLoading = false;
                        }
                    } else {
                        this.isLoading = false;
                        if (!justRetrieve) {
                            this.showErrorMess(obj.errmessage);
                            //this.putLockBack();
                        } else {
                            this.buyoutTypesError = obj.errmessage;
                        }
                    }

                }).catch((error) => {
                    console.log("technical error: ", error);
                    this.showErrorMess(this.genericMessage);
                    this.isLoading = false;
                    if (!justRetrieve) {
                        this.showErrorMess(error);
                        //this.putLockBack();
                    } else {
                        this.buyoutTypesError = error;
                    }
                })
        } else if (this.buyouts.length) {
            this.createPartialBuyout();
        } else {
            if (!justRetrieve) {
                this.showErrorMess(this.buyoutTypesError);
                //this.putLockBack();
            }
        }

    }

    createPartialBuyout() {
        if (this.buyouts.length > 0) {
            let quoteType = this.buyouts.splice(0, 1).toString().replace(/^0+/, "");
            let additionalKeys = `{"BuyoutType": ${JSON.stringify(quoteType)}, "Assets": ${JSON.stringify(this.selectedCAssets)}}`;
            requestByContractNumber({ recordId: this.contractId, nitroApiOption: "createBuyoutDP", additionalKeys: additionalKeys })
                .then((result) => {
                    let obj = JSON.parse(result);
                    let responseObj = obj.Response || obj.response.Response;
                    if (responseObj) {
                        console.log('createPartialBuyout response:', responseObj);
                        // let isInDevelopment = true; // remove when development is complete
                        // if(isInDevelopment){
                        //     responseObj.Success = "true";
                        //     responseObj.QuoteSeq = (this.successes.length + 1).toString();
                        // }
                        if (responseObj.Success.toLowerCase() == "true") {
                            this.successes.push(quoteType);
                            this.createdBuyOuts.push({ Buyout_Type__c: quoteType, Quote_Sequence__c: responseObj.QuoteSeq });
                        } else {
                            let currentError = responseObj.Errors.join(',');
                            if (this.firstCreateError != currentError) {
                                this.showErrorMess(currentError);
                                this.firstCreateError = currentError;
                            }
                        }
                    } else {
                        this.showErrorMess(JSON.stringify(obj));
                    }
                    this.createPartialBuyout();
                })
                .catch((error) => {
                    console.log("technical error: ", error);
                    this.showErrorMess(this.genericMessage);
                    //this.putLockBack();
                })
                .finally(() => {
                    /*this.isLoading = false;*/
                });
        } else {
            if (this.successes.length > 0) {
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: "Success",
                //         message: "The following Buyout Quotes were successfully sent: " + this.successes,
                //         variant: 'success'
                //     })
                // );
                this.successes = [];
                this.saveBuyoutRecords();
            } else {
                //this.putLockBack();
            }
        }
    }

    saveBuyoutRecords() {
        let parameters = [this.contractId, JSON.stringify(this.createdBuyOuts), JSON.stringify(this.selectedCAssets)];
        hubExecute({ methodName: "saveBuyouts", parameters: parameters })
            .then((result) => {
                console.log('save buyout result:', result);
                if (result == "success") {
                    this.putLockBack();
                    // this.dispatchEvent(
                    //     new ShowToastEvent({
                    //         title: "Success",
                    //         message: "The Buyouts were successfully saved",
                    //         variant: 'success'
                    //     })
                    // );
                } else {
                    console.log("technical error: ", JSON.stringify(result));
                    this.showErrorMess(this.genericMessage);
                }
            })
            .catch((error) => {
                console.log("technical error: ", error);
                this.showErrorMess(this.genericMessage);
                this.dispatchEvent(new CustomEvent("close", { detail: "success" }));

            })
            .finally(() => {
                this.isLoading = false;
                this.createdBuyOuts = [];
                //this.putLockBack();
            });
    }

    putLockBack() {
        toggleLockContract({ contractId: this.contractId, isLocking: false })
            .then((result) => {
                console.log('putLockBack result: ', result);
                if (!this.firstCreateError) {
                    this.sendCreationEmail();
                }
            }).catch((error) => {
                console.log("technical error: ", error);
                this.showErrorMess(this.genericMessage);
            })
            .finally(() => {
                this.isLoading = false;
                //this.dispatchEvent(new CustomEvent("close", {detail: "success"}));
                this.firstCreateError = "";
                this.successes = [];
            });
    }

    handleBack(event) {
        this.dispatchEvent(new CustomEvent("close", { detail: "cancelled" }));
    }

    async sendCreationEmail() {
        try {
            this.isLoading = true;
            await sendCreateBuyout({ contractId: this.contractId });
            if (this.emailTo.length > 0) {
                await sendBuyoutCreationEmail({ contractId: this.contractId, lstEmailAddress: this.emailTo });
            }
        } catch (error) {
            this.showErrorMess(error);
        } finally {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent("close", { detail: "success" }));
        }
    }
}