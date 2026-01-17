import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { showError } from 'c/sL_Common';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import updateContractAssets from '@salesforce/apex/SL_ReturnAuthorizationHelper.updateContractAssets';
import checkReturnAuthorizationContractAssets from '@salesforce/apex/SL_ReturnAuthorizationHelper.checkReturnAuthorizationContractAssets';

const BUYOUT_HEADER = [
    { name: "QuoteSeq", label: "Quote" },
    { name: "QuoteType", label: "Quote Type" },
    { name: "PartialCodeCheckBox", label: "Partial" },
    { name: "QuoteTypeDesc", label: "Buyout Type" },
    { name: "Status", label: "Status" },
    { name: "BuyoutDate", label: "Buyout Date" },
    { name: "QuoteExpireDatet", label: "Expired Date" },
    { name: "TotalBuyout", label: "Quote Total" }
];
const BUYOUT_A = ["QuoteSeq"];
const BUYOUT_CHECK = ["PartialCodeCheckBox"];
const BUYOUT_CURRENCY = ["TotalBuyout"];

const DETAIL_HEADER = [
    { name: "QuoteSeq", label: "Quote" },
    { name: "BuyoutDate", label: "Buyout Date" },
    { name: "CommencementDate", label: "Commencement Date" },
    { name: "OriginalTerm", label: "Original Term" },
    { name: "NumberOfPayments", label: "Number of Payments" },
    { name: "DealerName", label: "Partner Name" },
    { name: "QuoteExpireDatet", label: "Expiration Date" },
    { name: "InvoiceDescription", label: "Equipment Description" },
    { name: "CustomerReceivableBalance", label: "Receivable Balance" },
    { name: "Residual", label: "Residual" },
    { name: "SalesTax", label: "Sales Tax" },
    { name: "LateCharges", label: "Late Charges" },
    { name: "Fees", label: "Fees" },
    { name: "SecurityDeposit", label: "Security Deposit (if applicable)" },
    { name: "TotalBuyout", label: "Total Buyout" }
];
const DETAIL_A = ["QuoteSeq"];
const DETAIL_CHECK = [];
const DETAIL_CURRENCY = ["CustomerReceivableBalance", "Residual", "SalesTax", "LateCharges", "Fees", "SecurityDeposit", "TotalBuyout"];
const RA_TYPES = ["21", "22", "26", "35", "36", "37", "40", "44", "70", "72", "76", "79", "81"];

export default class SL_ViewBuyout extends LightningElement {
    @api recordId;
    @api isDealerPortal = false;
    @api quoteBuyoutTypes = '';
    isExecuting;
    get isLoading() { return !this.recordId || this.isExecuting; }
    isFirstLoadDone = false;
    

    quotes = [];
    buyoutHeader = BUYOUT_HEADER;
    currentMode = "summary";
    get isSummary(){ return this.currentMode == "summary"; }
    get isDetail(){ return this.currentMode == "detail"; }
    get isRA(){ return this.currentMode == "returnAuth"; }
    buyoutSort = {column: "BuyoutDate", isAscending: false};
    isAssetManagement = false;
    isRAQuoteType = false;
    get showRAButton(){ return this.isRAQuoteType && this.isAssetManagement; }
    targetIds = [];
    dateRequested;

    @track responseBuyouts = [];
    @track selectedBuyouts = [];

    buyouts = [];
    @track detailColumn = [];

    printSendModalPopUp = false;
    selectedQuoteType;

    renderedCallback(){
        if(this.recordId && !this.isFirstLoadDone){
            this.getBuyoutQuotes();
            this.isFirstLoadDone = true;
        }
    }

    getBuyoutQuotes(){
        this.isExecuting = true;
        requestByContractNumber({recordId: this.recordId, nitroApiOption: "buyoutQuotes", additionalKeys: ""})
        .then(result => {
            let envelope = JSON.parse(result);
            let obj = envelope.response || envelope;
            if(obj.Response && obj.Response.Success == "True" && obj.Response.Quotes){
                console.log("complete quotes response: ", obj);
                this.quotes = [];
                this.responseBuyouts = obj.Response.Quotes;
                if(!this.isDealerPortal){
                    console.log('isDealerPortal');
                    obj.Response.Quotes.forEach((row) =>{
                        let partialCode = false;
                       // if(row["PartialCode"] && row.PartialCode === 'Full Asset Buyout') {
                        if((row["PartialCode"] && row.PartialCode === 'Multiple Asset Buyout') || (row["PartialCode"] && row.PartialCode === 'Full Asset Buyout') || (row["PartialCode"] && row.PartialCode === 'Partial Asset Buyout')) {
                            partialCode = true;
                            //console.log('partialCode after response');
                        } 
                        console.log('partialCode:', partialCode);
                        this.quotes.push({showIt: true, PartialCodeCheckBox :partialCode, ...row});
                    });
                }else{
                   // console.log('isDealerPortal 1');
                    let qBTypes = this.quoteBuyoutTypes.split(';');
                    // let startSeq = obj.Response.Quotes.length - qBTypes.length;
                    let foundQBTypes = [];
                    for(let i = obj.Response.Quotes.length -1; i >= 0; i-- ){
                        let row = obj.Response.Quotes[i];
                        let currentQuoteType = row.QuoteType.toString()/*.padStart(2,"0")*/;
                        /*let partialCode = false;
                        if(row["PartialCode"] && row.PartialCode === 'Full Asset Buyout') {
                            partialCode = true;
                        }*/
                        if(qBTypes.includes(currentQuoteType) && !foundQBTypes.includes(currentQuoteType)){
                            this.quotes.push({showIt: true, ...row});
                            foundQBTypes.push(currentQuoteType);
                            if(this.quotes.length == qBTypes.length){
                                break;
                            }
                        }
                    }
                }
                let tempQuotes = this.quotes;
                this.processRows("buyouts", tempQuotes);
            } else {
                if(obj.Response.Errors){
                    let errorMessage = obj.Response.Errors.join(',');
                    this.cancelScreen(errorMessage);
                }else{
                    this.cancelScreen(JSON.stringify(obj));
                }
            }
        })
        .catch(error => {
            this.cancelScreen(error);
        })
        .finally(() => {
            this.isExecuting = false;
         });
         requestByContractNumber({recordId: this.recordId, nitroApiOption: "getUserProfile", additionalKeys: ""})
         .then(result => {
             let obj = JSON.parse(result);
             if(obj){
                 this.isAssetManagement = obj.isAssetManagement;
             } else {
                 this.cancelScreen(JSON.stringify(obj));
             }
         })
         .catch(error => {
             this.cancelScreen(error);
         })
         .finally(() => {
             //this.isExecuting = false;
          });
    }

    handleGoToDetail(event){
        event.preventDefault();
        this.currentMode = "detail";
        
        let tempQuote = this.quotes.find((row)=> row.QuoteSeq == event.detail);
         console.log('tempQuote::',JSON.stringify(tempQuote));
        if(tempQuote){
            this.selectedQuoteType = tempQuote.QuoteType;
            this.isRAQuoteType = RA_TYPES.includes(tempQuote.QuoteType);
            this.processRows("buyoutDetail", [tempQuote]);
        }
    }

    handleGoToSummary(event){
        event.preventDefault();
        this.currentMode = "summary";
    }

    @api refreshBuyouts(){
        this.buyoutSort.isAscending = true;
        this.getBuyoutQuotes();
    }

    processRows(whichTable, preliminary){
        let finalRows = [];
        let headers = [], linkZeldas = [], checkBoxes = [], currencies, recordKey = "";
        let miscSummary = [];
        let hasMiscLateCharges = false, hasMiscSecurityDeposit = false;
        switch (whichTable){
            case "buyouts":
                headers = BUYOUT_HEADER;
                linkZeldas = BUYOUT_A;
                checkBoxes = BUYOUT_CHECK;
                currencies = BUYOUT_CURRENCY;
                recordKey = "QuoteSeq";
                preliminary.sort((rowA, rowB) => {
                    if(Date.parse(rowA[this.buyoutSort.column]) < rowB[this.buyoutSort.column])
                        return -1;
                    else if(Date.parse(rowA[this.buyoutSort.column]) > rowB[this.buyoutSort.column])
                        return 1;
                    else
                        return 0;
                });
                if(!this.buyoutSort.isAscending)
                    preliminary.reverse();
                break;
            case "buyoutDetail":
                headers = DETAIL_HEADER;
                linkZeldas = DETAIL_A;
                checkBoxes = DETAIL_CHECK;
                currencies = DETAIL_CURRENCY;
                recordKey = "QuoteSeq";
                let extraHeaders = [];
                miscSummary = preliminary[0].MiscSummary? preliminary[0].MiscSummary: [];
                miscSummary.forEach((row, i)=>{
                    if(row.MiscDescription){
                        let miscKey = "Misc" + i;
                        extraHeaders.push({ name: miscKey, label: row.MiscDescription });
                        currencies.push(miscKey);
                        preliminary[0][miscKey] = row.MiscTotal;
                        hasMiscLateCharges = hasMiscLateCharges || row.MiscDescription == "LateCharges";
                        hasMiscSecurityDeposit = hasMiscSecurityDeposit || row.MiscDescription == "Security Deposit";;
                    }
                });
                headers.splice(11, 0, ...extraHeaders);
                break;
        }
        preliminary.forEach((row, i)=>{
            let fieldsArray = [];
            headers.forEach(column =>{
                let key = column.name;
                let isLink = linkZeldas.includes(key);
                let isCherwell = false;
                let isCheck = checkBoxes.includes(key);
                let isCurrency = currencies.includes(key);
                let headerLabel = column.label;
                let processedValue = row[key] === "" && isCurrency? "0": row[key];
                if(isLink && key == recordKey)
                    processedValue = "View";
                fieldsArray.push({ key: key,
                    label: headerLabel,
                    value: processedValue,
                    isLink: isLink,
                    isCherwell: isCherwell,
                    isCheck: isCheck,
                    isCurrency: isCurrency,
                    isChecked: row[key]== "1",
                    isPlain: !isLink && !isCherwell && !isCheck && !isCurrency});
            });
            finalRows.push({index: i, showIt: row.showIt, destination: row[recordKey], fieldsArray: fieldsArray});
        });
        switch (whichTable){
            case "buyouts":
                this.buyouts = [...finalRows];
                console.log("this.buyouts: ", JSON.parse(JSON.stringify(this.buyouts)));
                break;
            case "buyoutDetail":
                let tempColumn = [];
                tempColumn.push(finalRows[0].fieldsArray.find(field => field.key == "QuoteSeq"));
                tempColumn[0].destination = finalRows[0].destination;
                tempColumn.push(finalRows[0].fieldsArray.find(field => field.key == "BuyoutDate"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "CommencementDate"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "OriginalTerm"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "NumberOfPayments"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "DealerName"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "QuoteExpireDatet"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "InvoiceDescription"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "CustomerReceivableBalance"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Residual"));
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "SalesTax"));
                for (let i = 0; i < miscSummary.length; i++){
                    let miscField = finalRows[0].fieldsArray.find(field =>field.key == "Misc" + i);
                    if(miscField)
                        tempColumn.push(miscField);
                }
                if(!hasMiscLateCharges){
                    tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LateCharges"));
                }
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Fees"));
                if(!hasMiscSecurityDeposit){
                    tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "SecurityDeposit"));
                }
                tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "TotalBuyout"));
                this.detailColumn = tempColumn;
                break;
        }
        
    }
    //summary button
    handlePdf(){
        let rows = [...this.detailColumn];
        rows.splice(0, 1);
        window.open('/apex/SL_PrintBuyout?rows='+encodeURIComponent(JSON.stringify(rows))
            + '&contractId=' + this.recordId, "_blank");
    }
    //detailed button
    handleDetailedPdf(){
        let rows = [...this.detailColumn];
        rows.splice(0, 1);
        window.open('/apex/SL_PrintDetailedBuyout?rows='+encodeURIComponent(JSON.stringify(rows))
            + '&contractId=' + this.recordId, "_blank");
    }

    handleReturnAuthorization(){
        let rows = [...this.detailColumn];
        console.log("&buyoutSeq=" + rows[0].destination);
        updateContractAssets({
            recordId: this.recordId, quoteSeq: rows[0].destination
        }).then( (result) => {
            console.log('handleReturnAuthorization result: ', result);
            if(result.includes('OK')){
            window.open("/apex/SL_ReturnAuthorization?contractId=" + this.recordId + "&buyoutSeq=" + rows[0].destination, "_blank");
            checkReturnAuthorizationContractAssets({
                contractId: this.recordId,
                buyoutSeq: rows[0].destination
            }).then( () => {
            }
            ).catch(error => {
                //this.isLoading = false;
            });
        }
        else{
            showError(this, result);        
        }               
        }
        ).catch(error => {
            //this.isLoading = false;
        });
        // the below will be used if we use DocGen in the future
        // this.isExecuting = true;
        // requestByContractNumber({recordId: this.recordId, nitroApiOption: "generateRAs", additionalKeys: ""})
        //  .then(result => {
        //     console.log("RA response: ", result);
        //     let obj = JSON.parse(result);
        //     if(obj.contractAssetIds){
        //         this.targetIds = obj.contractAssetIds;
        //         this.dateRequested = obj.dateRequested;
        //         this.currentMode = 'returnAuth';
        //     } else if(obj.docGenError){
        //     this.cancelScreen(obj.docGenError);
        //     }else{
        //         this.cancelScreen(JSON.stringify(obj));
        //     }
        //  })
        //  .catch(error => {
        //      this.cancelScreen(error);
        //  })
        //  .finally(() => {
        //      this.isExecuting = false;
        //   });
    }

    cancelScreen(error){
        showError(this, error);
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handlePrintSend(event) {

        this.printSendModalPopUp = !this.printSendModalPopUp;
    }

    // handleRowSelection(event) {
    //     console.log('Row selection::', JSON.stringify(event.detail));
    //     if(event.detail.checked) {
    //         let buyout = this.responseBuyouts.find(ele => ele.QuoteSeq == event.detail.destination);
    //         let bt = {};
    //         bt["ReceivableBalance"] = buyout["ReceivableBalance"];
    //         bt["TotalBuyout"] = buyout["TotalBuyout"];
    //         bt["EndingDeposit"] = buyout["EndingDeposit"];
    //         bt["SecurityDeposit"] = buyout["SecurityDeposit"];
    //         bt["Fees"] = buyout["Fees"];
    //         bt["LateCharges"] = buyout["LateCharges"];
    //         bt["SalesTax"] = buyout["SalesTax"];
    //         bt["Residual"] = buyout["Residual"];
    //         bt["QuoteTypeDesc"] = buyout["QuoteTypeDesc"];
    //         bt["QuoteSeq"] = buyout["QuoteSeq"];
    //         this.selectedBuyouts.push(bt);
    //     } else {
    //         let index = this.selectedBuyouts.findIndex(ele => ele.QuoteSeq == event.detail.destination);
    //         if(index != -1) {
    //             this.selectedBuyouts.splice(index,1);
    //         }
    //     }
    //     console.log('selectedBuyouts::', JSON.stringify(this.selectedBuyouts));

    // }

    printBuyout(){
        window.open('/apex/PEAC_BuyoutComparison?&recId=' + this.recordId, "_blank");
    }

}