import { LightningElement, api, track } from 'lwc';
import { showError } from 'c/sL_Common';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import BuyoutReplacement from '@salesforce/apex/SL_SummaryAndDetail.BuyoutReplacement';
import updateContractAssets from '@salesforce/apex/SL_ReturnAuthorizationHelper.updateContractAssets';
import checkReturnAuthorizationContractAssets from '@salesforce/apex/SL_ReturnAuthorizationHelper.checkReturnAuthorizationContractAssets';

const BUYOUT_HEADER = [
    //{ name: "QuoteSeq", label: "Quote" },
    //{ name: "QuoteType", label: "Quote Type" },
    { name: "QuoteTypeDesc", label: "Buyout Type" },
    { name: "Status", label: "Status" },
    { name: "BuyoutDate", label: "Buyout Date" },
    { name: "QuoteExpireDatet", label: "Expired Date" },
    { name: "TotalBuyout", label: "Quote Total" }
];
const BUYOUT_A = ["QuoteTypeDesc"];
const BUYOUT_CHECK = [];
const BUYOUT_CURRENCY = ["TotalBuyout"];

const DETAIL_HEADER = [
    { name: "ReceivableBalance", label: "Receivable Balance" },
    { name: "Residual", label: "Residual" },
    { name: "SalesTax", label: "Sales Tax" },
    { name: "LateCharges", label: "Late Charges" },
    { name: "AlwaysZero", label: "Early Termination Fee" },
    { name: "SecurityDeposit", label: "Security Deposit" },
    { name: "EndingDeposit", label: "Ending Deposit" },
    { name: "MiscTotalServiceContract", label: "Service Pass Through" },
    { name: "MiscTotalSumPropertyTax", label: "Property Tax" },
    { name: "MiscTotalSumInsurance", label: "Insurance" },
    { name: "MiscTotalSumOther", label: "Other Lease Charges" },
    { name: "TotalBuyout", label: "Total Buyout" }
];
const DETAIL_A = [];
const DETAIL_CHECK = [];
const DETAIL_CURRENCY = ["ReceivableBalance", "Residual", "SalesTax", "LateCharges", "AlwaysZero", "SecurityDeposit",
    "EndingDeposit", "MiscTotalServiceContract", "MiscTotalSumPropertyTax", "MiscTotalSumInsurance", "MiscTotalSumOther", "TotalBuyout"];
const RA_TYPES = ["21", "22", "26", "35", "36", "37", "40", "44", "70", "72", "76", "79", "81"];

export default class SL_ViewBuyout extends LightningElement {
    @api recordId;
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
    todaysDate = new Date(Date.now());
    purchaseOption = "";
    quoteDescriptions = [];
    isRAQuoteType = false;
    get showRAButton(){ return this.isRAQuoteType; }
    targetIds = [];
    dateRequested;

    buyouts = [];
    @track detailColumn = [];

    connectedCallback(){
        requestByContractNumber({recordId: this.recordId, nitroApiOption: "getPurchaseOption", additionalKeys: ""})
        .then(result => {
            let obj = JSON.parse(result);
            if(obj){
                console.log("purchaseOpt obj: ", obj);
                this.purchaseOption = obj.oppPurchaseOpt;
            } else {
                this.cancelScreen(JSON.stringify(obj));
            }
        })
        .catch(error => {
            this.cancelScreen(error);
        })
        .finally(() => { });
    }

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
            BuyoutReplacement({payload: JSON.stringify(obj)})
            .then(result2 => {
                let obj = JSON.parse(result2);             
            if(obj.Response && obj.Response.Success == "True" && obj.Response.Quotes){
                console.log("complete quotes response: ", obj);
                this.quotes = [];
                let qBTypes = this.quoteBuyoutTypes.split(';');
                let foundQBTypes = [];
                for(let i = obj.Response.Quotes.length -1; i >= 0; i-- ){
                    let row = obj.Response.Quotes[i];
                    let currentQuoteType = row.QuoteType.toString()/*.padStart(2,"0")*/;

                    if(qBTypes.includes(currentQuoteType) && !foundQBTypes.includes(currentQuoteType)){
                        this.quotes.push({showIt: true, ...row});
                        foundQBTypes.push(currentQuoteType);
                        if(this.quotes.length == qBTypes.length){
                            break;
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
            
        })
        .catch(error => {
            this.cancelScreen(error);
        })        
    }

    handleGoToDetail(event){
        event.preventDefault();
        this.currentMode = "detail";
        let tempQuote = this.quotes.find((row)=> row.QuoteSeq == event.detail);
        if(tempQuote){
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
        let hiddenColumns = ["QuoteSeq","QuoteType"];
        let headers = [], linkZeldas = [], checkBoxes = [], currencies, recordKey = "";
        let miscSummary = [];
        let transposedRows = {};
        let tempQuoteDesc = [];
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
                break;
        }
        preliminary.forEach((row, i)=>{
            let fieldsArray = [];
            if(whichTable == "buyoutDetail"){
                row["AlwaysZero"] = "";
                row["MiscTotalServiceContract"] = "";
                miscSummary = row.MiscSummary? row.MiscSummary: [];
                let sumPropertyTax = 0, sumInsurance = 0, sumOther = 0;
                miscSummary.forEach((miscItem)=>{
                    if(miscItem.MiscDescription){
                        if(miscItem.MiscDescription == "Service Contract"){
                            row["MiscTotalServiceContract"] = miscItem.MiscTotal;
                        }else if(miscItem.MiscDescription.startsWith("Property Tax")){
                            sumPropertyTax += Number(miscItem.MiscTotal);
                        }else if(miscItem.MiscDescription.startsWith("Insurance")){
                            sumInsurance += Number(miscItem.MiscTotal);
                        }else if(!miscItem.MiscDescription.includes("Service Contract")){
                            sumOther += Number(miscItem.MiscTotal);
                        }
                    }
                });
                row["MiscTotalSumPropertyTax"] = sumPropertyTax;
                row["MiscTotalSumInsurance"] = sumInsurance;
                row["MiscTotalSumOther"] = sumOther;
                let prettyDesc = "";
                switch(row.QuoteType.toString()){
                    case '1':
                    case '01':
                    case '38':
                    case '39':
                        prettyDesc = "Buyout";
                        break;
                    case "6":
                    case "06":
                    case "10":
                        prettyDesc = "Trade Up to Keep";
                        break;
                    case "35":
                    case "36":
                    case "37":
                        prettyDesc = "Trade Up to Return";
                        break;
                }
                tempQuoteDesc.push({label: prettyDesc, seq: row.QuoteSeq});
            }
            headers.forEach(column =>{
                let key = column.name;
                let isLink = linkZeldas.includes(key);
                let isCherwell = false;
                let isCheck = checkBoxes.includes(key);
                let isCurrency = currencies.includes(key);
                let headerLabel = column.label;
                let processedValue = row[key] === "" && isCurrency? "0": row[key];
                if(whichTable == "buyoutDetail"){
                    if(!Array.isArray(transposedRows[key])){
                        transposedRows[key] = [];
                    }
                    transposedRows[key].push({value: processedValue, QuoteSeq: row[recordKey]});
                }
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
                break;
            case "buyoutDetail":
                let tempColumn = [];
                headers.forEach(column =>{
                    let fieldCollection = finalRows[0].fieldsArray.find(field => field.key == column.name);
                    fieldCollection.rows = transposedRows[column.name];
                    tempColumn.push(fieldCollection);
                });
                // tempColumn.push(finalRows[0].fieldsArray.find(field => field.key == "ReceivableBalance"));
                // //tempColumn[0].destination = finalRows[0].destination;
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Residual"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "SalesTax"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LateCharges"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field => field.key == "AlwaysZero"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "SecurityDeposit"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "EndingDeposit"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "MiscTotalServiceContract"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "MiscTotalSumPropertyTax"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "MiscTotalSumInsurance"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "MiscTotalSumOther"));
                // tempColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "TotalBuyout"));
                this.detailColumn = tempColumn;
                this.quoteDescriptions = tempQuoteDesc;
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
        updateContractAssets({
            recordId: this.recordId
        }).then( () => {
            window.open("/apex/SL_ReturnAuthorization?contractId=" + this.recordId + "&buyoutSeq=" + rows[0].destination, "_blank");
            checkReturnAuthorizationContractAssets({
                contractId: this.recordId,
                buyoutSeq: rows[0].destination
            }).then( () => {
            }
            ).catch(error => {
                this.isLoading = false;
            });
            
        }
        ).catch(error => {
            this.isLoading = false;
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
    }

}