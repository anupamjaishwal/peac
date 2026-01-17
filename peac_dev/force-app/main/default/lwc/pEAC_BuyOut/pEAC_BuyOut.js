import { LightningElement, api, track, wire } from 'lwc';
import modal from "@salesforce/resourceUrl/customModalCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBuyOuts from '@salesforce/apex/pEAC_BuyOutController.getBuyOuts';
import toggleLockContract from '@salesforce/apex/SL_SummaryAndDetail.toggleLockContract';
import buyoutCreationV2 from '@salesforce/apex/SL_SummaryAndDetail.buyoutCreationV2';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import processBuyouts from '@salesforce/apex/pEAC_BuyOutController.processBuyouts';
import updateContractAssets from '@salesforce/apex/SL_ReturnAuthorizationHelper.updateContractAssets';
import checkReturnAuthorizationContractAssets from '@salesforce/apex/SL_ReturnAuthorizationHelper.checkReturnAuthorizationContractAssets';
import hubExecute from '@salesforce/apex/SL_PartialBuyout.hubExecute';
import getPartnerPDFDetails from '@salesforce/apex/pEAC_BuyOutController.getPartnerPDFDetails';
import getCustomerPDFDetails from '@salesforce/apex/pEAC_BuyOutController.getCustomerPDFDetails';
import sendBuyoutCreationEmail from '@salesforce/apex/SL_SummaryAndDetail.sendBuyoutCreationEmail';
import returnAuthorizationRequest from '@salesforce/apex/SL_ReturnAuthorizationHelper.returnAuthorizationRequest';
//import userId from '@salesforce/user/Id';
//import USER_EMAIL from '@salesforce/schema/User.Email';
//import { getRecord } from 'lightning/uiRecordApi';
import { reduceErrors, showToast } from 'c/sl_Utils';

const RA_TYPES = ["21", "22", "26", "35", "36", "37", "40", "44", "70", "72", "76", "79", "81"];
const LESSOR_CODES = ["101", "102", "103", "104", "111", "113", "211", "213", "471"];

export default class PEAC_BuyOut extends LightningElement {

    _recordId;
    isLoading = false;
    isPartialBuyout = false;
    get isNotPartialBuyout() { return !this.isPartialBuyout; }
    willSendExternalEmail = false;
    isPartialOn = false;
    firstScreen = true;
    currentScreen = "firstScreen";
    buyouts = [];
    successes = [];
    quoteBuyoutTypes;
    buyoutTypesError = '';
    @track quotes = []
    emailAddresses;
    emailTo = [];
    emailFormatError = "Please enter a valid e-mail address";
    errorOccurred = false;
    firstCreateError = "";


    // PAGINATION PROPERTIES
    pageSize = 10;
    pageNumber = 1;
    totalRecords = 0;
    isPartialChecked = false;

    /*@wire(getRecord, { recordId: userId, fields: [USER_EMAIL]}) 
    userDetails({error, data}){
      if(data){
        if(!this.emailAddresses){
            this.emailAddresses += data.fields?.Email?.value;
        }
      } else if(error){
        this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "),'error'));
      }
    }*/

    get isPartialScreen() { return this.currentScreen == "partialBuyout" }

    get backEnabled() {
        return !this.firstScreen && this.currentScreen == "buyoutOptions";
    }

     
    get buyoutOptionDisable() { 
        return !(this.buyoutList.length>0);
    }

    @api set recordId(value) {
        this.isLoading = true;
        this._recordId = value;
        this.fetchBuyOut();
        this.loadPartialInfo();
    }

    get recordId() {
        return this._recordId;
    }

    @track buyoutList = [];
    @track originalBuyoutList = [];
    showBuyOutTable = false;
    message = 'Fetching buyout details...';
    showModal = true;

    get paginatedBuyoutList() {
        let from = (this.pageNumber - 1) * this.pageSize,
            to = this.pageSize * this.pageNumber;
        return this.buyoutList?.slice(from, to);
    }
    get showPaginator() {
        return this.originalBuyoutList.length > 0;
    }

    connectedCallback() {
        loadStyle(this, modal);
    }

    handleSendExternalEmailOn(event) {
        this.willSendExternalEmail = event.detail.checked;
    }

    handleIsPartial(event) {
        this.isPartialBuyout = event.detail.isPartial;
    }


    handlePartialBuyout(event) {
        if (!this.validateEmail()) {
            this.isPartialOn = true;
            setTimeout(() => {
                this.isPartialOn = false;
            }, 0);
            return;
        }

        if (this.willSendExternalEmail && this.emailAddresses) {
            //this.emailTo = this.emailAddresses.split(/[,;]\s*/);
            this.emailTo = this.emailAddresses.split(',');
        }

        this.isPartialOn = event.detail.checked;
        if (this.isPartialBuyout && this.isPartialOn) {
            this.currentScreen = 'partialBuyout';
            this.firstScreen = false;
        }
    }

    fetchBuyOut() {
        console.log('fetchBuyOut::entry');
        getBuyOuts({
            contractId: this.recordId
        }).then(response => {
            console.log('fetchBuyOut::response', response);
            if (response && response.length > 0) {
                response.forEach(res => {

                    if (res.Most_Recent_DP__c) {
                        if (res.Partial_Buyout__c) {
                            this.isPartialChecked = true;
                        }
                        res["rowStyle"] = 'background-color: #fff8db !important;';
                    } else {
                        res["rowStyle"] = 'background-color: #ffffff;';
                    }
                    res.isRAQuoteType = false;
                    if (RA_TYPES.includes(res.Buyout_Type__c) && LESSOR_CODES.includes(res.Contract__r.Lessor_Code__c)) {
                        res.isRAQuoteType = true;
                    }

                });
                this.buyoutList = response;
                this.originalBuyoutList = response;
                this.totalRecords = this.originalBuyoutList.length;
                this.showBuyOutTable = true;
                this.message = '';
            }
            //else {
            //  this.message = 'There is no buyouts available. Please click on "Generate Buyout"';
            //this.showToast('Error!','There is no buyouts available. Please click on "Generate Buyout.','error');
            // }
            this.isLoading = false;
        }).catch(error => {
            this.isLoading = false;
        });
    }



    handleGenerateBuyout() {
        if (this.validateEmail()) {
            this.isLoading = true;
            this.errorOccurred = false;
            toggleLockContract({ contractId: this._recordId, isLocking: true })
                .then((result) => {
                    let obj = JSON.parse(result);
                    console.log("locking obj: ", obj);
                    if (obj.message && obj.message == "success") {
                        this.createBuyoutTypes(false);
                    } else {
                        this.showToast('Error!', JSON.stringify(obj), 'error');
                    }
                })
                .catch((error) => {
                    this.showToast('Error!', error, 'error');
                    this.isLoading = false;
                })
                .finally(() => { });
        }
    }

    createBuyoutTypes(justRetrieve) {
        console.log("justRetrieve: ", justRetrieve);
        console.log("this.quoteBuyoutTypes: ", this.quoteBuyoutTypes);
        if (justRetrieve || (!justRetrieve && !this.buyouts.length && !this.buyoutTypesError)) {
            buyoutCreationV2({ recordId: this._recordId })
                .then((result) => {
                    let obj = JSON.parse(result);
                    console.log('buyoutCreationV2 result', JSON.stringify(obj));
                    if (obj.quoteBuyouts) {
                        this.buyouts = obj.quoteBuyouts.split(';');
                        this.quoteBuyoutTypes = obj.quoteBuyouts;
                        if (!justRetrieve) {
                            this.generateBuyout();
                        } else {
                            this.isLoading = false;
                        }
                    } else {
                        this.isLoading = false;
                        if (!justRetrieve) {
                            this.showToast('Error!', obj.errmessage, 'error');
                            this.errorOccurred = true;
                            //this.putLockBack();
                        } else {
                            this.buyoutTypesError = obj.errmessage;
                        }
                    }

                }).catch((error) => {
                    this.showToast('Error!', error, 'error');
                    this.isLoading = false;
                    if (!justRetrieve) {
                        this.showToast('Error!', error, 'error');
                        this.errorOccurred = true;
                        //this.putLockBack();
                    } else {
                        this.buyoutTypesError = error;
                    }
                })
        } else if (this.buyouts.length) {
            this.generateBuyout();
        } else {
            if (!justRetrieve) {
                this.showToast('Error!', this.buyoutTypesError, 'error');
                this.errorOccurred = true;
                //this.putLockBack();
            }
        }

    }

    generateBuyout() {
        console.log('this.buyouts:', this.buyouts);
        if (this.buyouts.length > 0) {
            let quoteType = this.buyouts.splice(0, 1).toString().replace(/^0+/, "");
            let additionalKeys = `{"BuyoutType": ${JSON.stringify(quoteType)}}`;
            requestByContractNumber({ recordId: this._recordId, nitroApiOption: "createBuyoutDP", additionalKeys: additionalKeys })
                .then((result) => {
                    let obj = JSON.parse(result);
                    let responseObj = obj.Response || obj.response.Response;
                    if (responseObj) {
                        console.log('generateBuyout response:', responseObj);
                        if (responseObj.Success.toLowerCase() == "true") {
                            this.successes.push(quoteType);
                            //this.createdBuyOuts.push({Buyout_Type__c: quoteType, Quote_Sequence__c: responseObj.QuoteSeq });
                        } else {
                            let currentError = responseObj.Errors.join(',');
                            if (this.firstCreateError != currentError) {
                                this.showToast('Error!', currentError, 'error');
                                this.firstCreateError = currentError;
                            }
                        }
                    } else {
                        this.showToast('Error!', JSON.stringify(obj), 'error');
                    }
                    this.generateBuyout();
                })
                .catch((error) => {
                    console.log('generateBuyout response error:', error);
                    this.showToast('Error!', error, 'error');
                    this.errorOccurred = true;
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
                this.getBuyoutQuotes();
            } else {
                this.errorOccurred = true;
                //this.putLockBack();
            }
        }
    }

    getBuyoutQuotes() {
        console.log('I am being called getBuyoutQuotes::');
        this.isLoading = true;
        requestByContractNumber({ recordId: this._recordId, nitroApiOption: "buyoutQuotes", additionalKeys: "fromPEAC_BuyOut" })
            .then(result => {
                let envelope = JSON.parse(result);
                console.log('envelope::' + JSON.stringify(envelope));
                //this.response = envelope;
                let obj = envelope.response || envelope;
                if (obj.Response && obj.Response.Success == "True" && obj.Response.Quotes) {
                    this.quotes = [];
                    let qBTypes = this.quoteBuyoutTypes.split(';');
                    console.log('qBTypes::' + JSON.stringify(qBTypes));
                    let foundQBTypes = [];
                    let isError = false;
                    for (let i = obj.Response.Quotes.length - 1; i >= 0; i--) {
                        let row = obj.Response.Quotes[i];
                         if (row.TotalBuyout < 0) {
                             isError = true;
                             this.quotes = [];
                             this.showToast('Error!', 'To process your request, please contact customer service at buyouts@peacsolutions.com. Thank you.', 'error');
                             break;
                         }
                        let currentQuoteType = row.QuoteType.toString()/*.padStart(2,"0")*/;
                        if (qBTypes.includes(currentQuoteType) && !foundQBTypes.includes(currentQuoteType)) {
                            this.quotes.push({ showIt: true, ...row });
                            foundQBTypes.push(currentQuoteType);
                            if (this.quotes.length == qBTypes.length) {
                                break;
                            }
                        }
                    }
                    console.log('this.quotes::' + JSON.stringify(this.quotes));//3
                    if (!isError) {
                        this.processBuyouts();
                    }

                } else {
                    if (obj.Response.Errors) {
                    } else {
                    }
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error!', 'Technical Error occured, while fetching buyouts.', 'error');
                console.log('this.quotes::' + JSON.stringify(error));//3
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    processBuyouts() {
        this.isLoading = true;
        processBuyouts({
            wrapList: this.quotes,
            contractId: this._recordId
        }).then(result => {
            console.log('this.processBuyouts::', JSON.stringify(result));
            if (result == 'Success') {
                this.showToast('Success!', 'The buyouts has been generated successfully.', 'success');
                this.putLockBack();

                    //this.sendCreationEmail();
            } else {
                this.showToast('Error!', 'Technical Error occured, while fetching buyouts.', 'error');
            }
            this.isLoading = false;
        }).catch(error => {
            this.showToast('Error!', 'Technical Error occured, while fetching buyouts.', 'error');
        });
    }
    putLockBack() {
        toggleLockContract({ contractId: this._recordId, isLocking: false })
            .then((result) => {
                console.log('putLockBack result: ', result);
                if (!this.errorOccurred) {
                    this.sendCreationEmail();
                }
                this.fetchBuyOut();
            }).catch((error) => {
                this.showToast('Error!', error);
            })
            .finally(() => {
                this.isLoading = false;
                this.errorOccurred = false;
                this.firstCreateError = "";
                this.successes = [];
            });
    }


    handleBack(event) {
        this.firstScreen = true;
        this.currentScreen = "firstScreen";
        if (event.detail == "success") {
            this.fetchBuyOut();
        }
    }

    handleBuyoutOptions() {
        this.firstScreen = false;
        this.currentScreen = "buyoutOptions";
    }

    handleReturnAuthorization(event) {
        updateContractAssets({
            recordId: this.recordId
        }).then((result) => {
            console.log("result: ", result);
            if (result.includes('OK')) {
                window.open("/apex/SL_ReturnAuthorization?contractId=" + this.recordId + "&buyoutSeq=" + event.target.dataset.quoteSequence, "_blank");
                checkReturnAuthorizationContractAssets({
                    contractId: this.recordId,
                    buyoutSeq: rows[0].destination
                }).then(() => {
                }
                ).catch(error => {
                    this.isLoading = false;
                });
            }
            else {
                this.showToast('Error', result, 'error');
            }
        }
        ).catch(error => {
            this.isLoading = false;
        });


    }


    hideModal() {
        this.showModal = false;
    }


    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        let searchKey = String(evt.target.value).toLowerCase();
        if (searchKey) {
            console.log('searchKey::', searchKey);
            if (isEnterKey) {
                this.buyoutList = this.originalBuyoutList.filter(record => {
                    const nameStr = String(record["Name"]).toLowerCase();
                    console.log('nameStr::', nameStr);
                    const amountStr = String(record["Buyout_Amount__c"]).toLowerCase();
                    console.log('amountStr::', amountStr);
                    const descStr = String(record["Buyout_Description__c"]).toLowerCase();
                    console.log('descStr::', descStr);
                    return (nameStr.includes(searchKey) || amountStr.includes(searchKey) || descStr.includes(searchKey));
                });
            }
        } else {
            this.buyoutList = this.originalBuyoutList;
        }
    }

    handleClear() {
        this.buyoutList = this.originalBuyoutList;
    }


    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handlePartnerPDFDownload(event) {
        this.isLoading = true;
        getPartnerPDFDetails({
            buyoutID: event.currentTarget.dataset.id
        }).then(result => {
            console.log('Result::', result);
            if (result === 'Error') {
                this.showToast('Error', 'There is some issue, while retreiving your file.', 'error');
            } else {
                window.open(result, '_blank');
            }
            this.isLoading = false;
        });
    }
    handlecustomerPDFDownload(event) {
        this.isLoading = true;
        getCustomerPDFDetails({
            buyoutID: event.currentTarget.dataset.id,
            contractId: this._recordId
        }).then(result => {
            if (result === 'Error') {
                this.showToast('Error', 'There is some issue, while retreiving your file.', 'error');
            } else {
                window.open(result, '_blank');
            }
            this.isLoading = false;
        });
    }

    handleDownload(evt) {
        var recId = evt.currentTarget.dataset.id;
        console.log('recId:', recId)
        window.open('/PEAC_PartnerQuotePDF?buyoutId=' + recId, '_blank');
    }

    loadPartialInfo() {
        hubExecute({ methodName: "getCAssetsInfo", parameters: [this.recordId] })
            .then((result) => {
                let obj = JSON.parse(result);
                this.isPartialBuyout = obj.isPartialBuyout && obj.isIL10;
                console.log("this.isPartialBuyout: ", JSON.stringify(this.isPartialBuyout));
            })
            .catch((error) => {
                console.error("loadPartialInfo error: ", JSON.parse(JSON.stringify(error)));
            })
            .finally(() => { });
    }

    paginationChangeHandler(event) {
        if (event.detail) {
            this.pageNumber = event.detail.pageNumber;
            this.pageSize = event.detail.pageSize;
        }
    }

    handleEmailChange(event) {
        this.emailAddresses = event.detail.value;
    }

    validateEmail() {
        if (!this.willSendExternalEmail) {
            return true;
        }
        let isValid = true;
        let field = this.refs.sendBuyoutEmail;

        if (!field.checkValidity()) {
            field.reportValidity();
            isValid = false;
        }
        if (!isValid) {
            this.showToast('Error!', this.emailFormatError, 'error');
        }

        return isValid;
    }

    async sendCreationEmail() {
        try {
            if (this.willSendExternalEmail && this.emailAddresses) {
                //this.emailTo = this.emailAddresses.split(/[,;]\s*/);
                this.emailTo = this.emailAddresses.split(',');
            }
            if (this.emailTo.length > 0) {
                await sendBuyoutCreationEmail({ contractId: this.recordId, lstEmailAddress: this.emailTo });
                this.showToast('Success', 'Buyout Email sent successfully', 'success');
            }
        } catch (error) {
            console.log("pdf error :", JSON.stringify(error));
            this.showToast('Error!', error);
        }
    }

    returnAuthorizationRequest(event) {
        let currentBuyoutId = event.currentTarget.dataset.id;
        console.log('currentBuyoutId', currentBuyoutId);
        returnAuthorizationRequest({ buyoutId: currentBuyoutId })
            .then((result) => {
                this.showToast('Success!', 'Return Authorization request has been created!', 'success');

            })
            .catch((error) => {
                this.showToast('Error!', error, 'error');
            })
            .finally(() => { });

    }
}