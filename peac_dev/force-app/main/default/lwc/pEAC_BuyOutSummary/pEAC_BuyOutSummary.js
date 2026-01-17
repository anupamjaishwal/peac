import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import buyoutCreationV2 from '@salesforce/apex/SL_SummaryAndDetail.buyoutCreationV2';
import sendBuyout from '@salesforce/apex/SL_SummaryAndDetail.sendBuyout';
import getContract from '@salesforce/apex/SL_SummaryAndDetail.getContract';
import sendSummaryBuyout from '@salesforce/apex/SL_SummaryAndDetail.sendSummaryBuyout';
import toggleLockContract from '@salesforce/apex/SL_SummaryAndDetail.toggleLockContract';
import localizationService from '@salesforce/i18n/internationalizationProperty';
import { loadScript } from 'lightning/platformResourceLoader';
import PDFResource from '@salesforce/resourceUrl/PDFResource'; // This is a static resource that holds the PDF file


const BUYOUT_HEADER = [
    { name: "QuoteSeq", label: "Quote" },
    { name: "QuoteType", label: "Quote Type" },
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

export default class PEAC_BuyOutSummary extends LightningElement {
    @api recordId;
     quoteBuyoutTypes ;
    isExecuting;
    get isLoading() { return !this.recordId || this.isExecuting; }
    isFirstLoadDone = false;

    quotes = [];
    buyoutHeader = BUYOUT_HEADER;
    currentMode = "summary";
    get isSummary(){ return this.currentMode == "summary"; }
    get isDetail(){ return this.currentMode == "detail"; }
    buyoutSort = {column: "BuyoutDate", isAscending: false};
    todaysDate = new Date();
    purchaseOption = "";
    quoteDescriptions = [];

    buyouts = [];
    buyouts_clone = [];
    @track detailColumn = [];
    ContractRecord;
    openApplication = false; 
    popupHeaderMessage = false;
    tradeKeepTotal;
    tradeReturnTotal;
     successes = [];
    failedQBs = [];
     isgetquote = false;
    buyoutTotal;

    connectedCallback(){
        getContract({contractId: this.recordId})
        .then((result)=>{
            this.ContractRecord = result;
        });
        console.log('This.ContractRecord:',this.ContractRecord);
        requestByContractNumber({recordId: this.recordId, nitroApiOption: "getPurchaseOption", additionalKeys: ""})
        .then(result => {
            let obj = JSON.parse(result);
            console.log('@87 obj::'+JSON.stringify(obj));
            if(obj){
                this.purchaseOption = obj.oppPurchaseOpt;
            } else {
                this.cancelScreen(JSON.stringify(obj));
            }
        })
        .catch(error => {
            this.cancelScreen(error);
        })
        .finally(() => { });

        this.isExecuting = true;
        toggleLockContract({contractId: this.recordId, isLocking: true})
        .then((lockResult)=>{
            let obj = JSON.parse(lockResult);
            console.log("locking obj: ", obj);
            if(obj.message && obj.message == "success"){
                buyoutCreationV2({recordId: this.recordId})
                .then((result)=>{
                    let obj = JSON.parse(result);
                    if(obj.quoteBuyouts){
                        this.buyouts = obj.quoteBuyouts.split(';');
                        this.buyouts_clone = this.buyouts;
                        this.quoteBuyoutTypes = obj.quoteBuyouts;
                    }
                    console.log('this.buyouts::'+JSON.stringify(this.buyouts)+this.buyouts_clone);
                    console.log('this.quoteBuyoutTypes::'+JSON.stringify(this.quoteBuyoutTypes));
                    this.successes = [];
                    this.failedQBs = [];
                    this.createBuyoutDP();
                });
            } else {
                showError(this, JSON.stringify(obj), "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            showError(this, error);
            this.isExecuting = false;
        })
        .finally(()=>{});
    }

   /* renderedCallback(){
       // this.createBuyoutDP();
        if(this.recordId && !this.isFirstLoadDone){
            //this.getBuyoutQuotes();
            this.isFirstLoadDone = true;
        }
    }*/

    createBuyoutDP(){
        console.log('I am being invoked createBuyoutDP::'+JSON.stringify(this.buyouts_clone.length)+this.recordId);
        if(this.buyouts_clone.length > 0){
            let quoteType1 = this.buyouts_clone.splice(0,1);//.toString();
            let quoteType = quoteType1.toString();
           // this.isLoading = true;
            console.log(quoteType);
            requestByContractNumber({recordId: this.recordId, nitroApiOption: "createBuyoutDP", additionalKeys: quoteType})
            .then((result)=>{
                let obj = JSON.parse(result);
                console.log('@120::'+JSON.stringify(obj));
                let responseObj = obj.Response || obj.response.Response;
                if(responseObj){
                    if(responseObj.Success.toLowerCase() == "true"){
                        this.successes.push(quoteType);
                        // this.createBuyoutDP();
                    } else {
                        this.failedQBs.push(quoteType);
                        // showError(this, responseObj.Errors.join(','));
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
            .finally(()=>{/*this.isLoading = false;*/
                    
                });
        }else if(this.buyouts_clone.length == 0){
            console.log('in else if');
            this.isgetquote = true;
        //} //else {
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
            if(this.failedQBs.length > 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: "The following Buyout Quotes encountered errors: " + this.failedQBs,
                        variant: 'error'
                    })
                );
                this.failedQBs = [];
            }
            this.putLockBack();
        if(this.recordId && !this.isFirstLoadDone && this.buyouts_clone.length == 0 && this.isgetquote ){
                    this.getBuyoutQuotes();
                    this.isFirstLoadDone = true;
            }
                    }
    }

    putLockBack(){
        toggleLockContract({contractId: this.recordId, isLocking: false})
        .then((result)=>{
            console.log('putLockBack result: ', result);
        }).catch((error)=>{
            showError(this,error);
        })
        .finally(()=>{this.isExecuting = false;});
    }

    getBuyoutQuotes(){
        console.log('I am being called getBuyoutQuotes::'+this.buyouts_clone);
        this.isExecuting = true;
        requestByContractNumber({recordId: this.recordId, nitroApiOption: "buyoutQuotes", additionalKeys: ""})
        .then(result => {
            let envelope = JSON.parse(result);
            console.log('envelope::'+JSON.stringify(envelope));
            //this.response = envelope;
            let obj = envelope.response || envelope;
            if(obj.Response && obj.Response.Success == "True" && obj.Response.Quotes){
                console.log("complete quotes response: ", obj);
                this.quotes = [];
                let qBTypes = this.quoteBuyoutTypes.split(';');
                console.log('qBTypes::'+JSON.stringify(qBTypes));
                let foundQBTypes = [];
                for(let i = obj.Response.Quotes.length -1; i >= 0; i-- ){
                    let row = obj.Response.Quotes[i];
                    let currentQuoteType = row.QuoteType.toString()/*.padStart(2,"0")*/;
                    console.log('qBTypes::'+JSON.stringify(qBTypes));
                    console.log('currentQuoteType::'+JSON.stringify(currentQuoteType));
                    console.log('foundQBTypes::'+JSON.stringify(foundQBTypes));
                    if(qBTypes.includes(currentQuoteType) && !foundQBTypes.includes(currentQuoteType)){
                        this.quotes.push({showIt: true, ...row});
                        foundQBTypes.push(currentQuoteType);
                        if(this.quotes.length == qBTypes.length){
                            break;
                        }
                    }
                }
                console.log('this.quotes::'+JSON.stringify(this.quotes));//3
                let tempQuotes = this.quotes;
                this.processRows("buyouts", tempQuotes);
                this.processRows("buyoutDetail", tempQuotes);
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
    }

    handleGoToDetail(event){
        event.preventDefault();
        this.currentMode = "detail";
        console.log('event.detail::'+JSON.stringify(event.detail));
        let tempQuote = this.quotes.find((row)=> row.QuoteSeq == event.detail);
        //if(tempQuote)
         //   this.processRows("buyoutDetail", [tempQuote]);
        // let tempQuotes = this.quotes;
        console.log(tempQuotes)
         if(tempQuotes){
             this.processRows("buyoutDetail", tempQuotes);
             console.log( this.buyoutTotal,'  this.buyoutTotal ',  this.tradeReturnTotal, '   ',  this.tradeKeepTotal)
            
         }
    }

    handleGoToSummary(event){
        event.preventDefault();
        this.currentMode = "summary";
    }

    @api refreshBuyouts(){
        this.buyoutSort.isAscending = true;
       // this.getBuyoutQuotes();
    }

    processRows(whichTable, preliminary){
        let finalRows = [];
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
                    if(column.name == 'TotalBuyout'){
                        fieldCollection.totals = "font-weight: var(--lwc-fontWeightBold, 700);";
                        console.log('fieldCollection.rows', fieldCollection.rows.length, fieldCollection.rows)
                        if(fieldCollection.rows.length > 2){
                            
                            this.tradeReturnTotal = fieldCollection.rows[2].value;
                        } 
                        if(fieldCollection.rows.length > 1){
                            this.tradeKeepTotal = fieldCollection.rows[1].value;
                        }
                        this.buyoutTotal = fieldCollection.rows[0].value;
                        sendSummaryBuyout({contractId: this.recordId, buyoutTotal: this.buyoutTotal, tradeReturnTotal: this.tradeReturnTotal, tradeKeepTotal: this.tradeKeepTotal})
            .then(result => {
            }).catch(error => {
                this.cancelScreen(error);
            });
                    }
                    
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
                console.log('this.detailColumn::'+JSON.stringify(this.detailColumn));
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

    cancelScreen(error){
        console.log('error::'+JSON.stringify(error));
        showError(error);
    }

    openBuyout(){
        let rows = [...this.detailColumn];
        console.log('error::',JSON.stringify(rows));
        window.open('/apex/pEAC_CustomerBuyOutLetter?rows='+JSON.stringify(rows)+'&recId='+this.recordId+'&action=buyout', "_blank");//this.detailColumn
    }
    EmailCustBuyout(){
        let rows = [...this.detailColumn];
        console.log('error::',JSON.stringify(rows));
        //this.response = this.testresponse;
        /*rows.forEach(element => {
            //delete element.key;
            delete element.isLink;
            delete element.isCherwell;
            delete element.isCheck;
            delete element.isCurrency;
            delete element.isChecked;
            delete element.isPlain;
        });*/

        
        if(rows){
            sendBuyout({contractId: this.recordId, detail: JSON.stringify(rows)})
            .then(result => {
                this.showToast('Success!', 'Successfully sent an Email!','success','dismissable');
            })
            .catch(error => {
                console.log('error:',error);
                //this.cancelScreen(error);
            })
        }  else {
            console.log('error',this.response.Response.Errors);
            if(this.response.Response.Errors)
                this.showToast('Error!!',this.response.Response.Errors[0], 'error', 'dismissable');
            else
            this.showToast('Error!!',JSON.stringify(this.response.Response), 'error', 'dismissable');
        }
    }
    PrintCustBuyout(){
        console.log('PrintCustBuyout:');
        let rows = [...this.detailColumn];
        window.open('/apex/pEAC_CustomerEmailBuyOut?rows='+JSON.stringify(rows)
            + '&recId=' + this.recordId, "_blank");

    }
    excelCustBuyout(){
        console.log('this.ContractRecord',this.ContractRecord);
        let colCnt = 0;
        this.detailColumn.forEach(record => {
            colCnt = record.rows.length;
        });
        let doc = '<table>';
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '}';          
        doc += '</style>';
        doc += '<tr><td>Customer:</td><td>'+this.ContractRecord.Customer__r.Name+'</td><td></td><td></td></tr>';
        doc += '<tr><td>Contract:</td><td>'+this.ContractRecord.Name+'</td><td></td><td></td></tr>';
        doc += '<tr><td>Equipment:</td><td>'+this.ContractRecord.Invoice_Description__c+'</td><td>Commencement Date:</td><td>'+(this.ContractRecord.Commencement_Date__c ? this.ContractRecord.Commencement_Date__c : '')+'</td></tr>';
        doc += '<tr><td>Remaining Payments:</td><td>'+this.ContractRecord.Payments_Remaining__c+'</td><td>Purchase Option::</td><td>'+this.purchaseOption+'</td></tr>';
        doc += '<tr><td>Term:</td><td>'+this.ContractRecord.Contract_Term__c+'</td><td>Equipment Cost:</td><td>'+this.ContractRecord.Gross_Equipment_Cost__c+'</td></tr>';
        doc += '<tr><td>Lease Payment:</td><td>$'+this.ContractRecord.Payment_Amount__c+'</td><td>Quote Date:</td><td>'+this.todaysDate+'</td></tr>';
        doc += '<tr><td>Total Payment:</td><td>$'+this.ContractRecord.Current_Rental_Payment__c+'</td><td>Next Payment Due Date:</td><td>'+(this.ContractRecord.Next_Payment_Date__c ? this.ContractRecord.Next_Payment_Date__c : '')+'</td></tr>';
        doc += '<tr><td></td><td></td><td>Type:</td><td>'+this.ContractRecord.Quote_Buyout__c+'</td></tr>';
        doc += '</table><br/><br/>';
        doc += '<table>';
        // Add styles for the table
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '}';          
        doc += '</style>';
        // Add all the Table Headers
        doc += '<tr><th></th><th>Buyout</th>'
        if(colCnt > 1)
            doc += '<th>Trade Up to Keep</th>';
        if(colCnt > 2){
            doc += '<th>Trade Up(Return)</th>';
        }   
        doc += '</tr>';
        // Add the data rows
        this.detailColumn.forEach(record => {
            doc += '<tr>';
            doc += '<td>'+record.label+'</td>'; 
            //doc += '<td>$'+record.value+'</td>'; 
            record.rows.forEach(element => {
                doc += '<td>$'+element.value+'</td>';
            });
            
            doc += '</tr>';
        });
        doc += '</table>';
        console.log(':doc:',doc);
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Buyout.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
    createTradeupReturn(event){
        this.openApplication = true;
        this.popupHeaderMessage = 'TradeUp Return Application';
        let tradeupMessage = '<b>Tradeup Amount:</b> '+(this.tradeReturnTotal ?this.tradeReturnTotal : '0.00' )  +' <b>Contract:</b> '+this.ContractRecord.Name + ' <b>Buyout Type:</b> Trade Up to Return';
        this.inputVariables = [
            {
                name: 'recordId',
                type: 'String',
                value: this.ContractRecord.Customer__c
            },
             {
                name: 'TradeBuyoutMsg',
                type: 'String',
                value: tradeupMessage
             }
            ];
    }
    createTradeupKeep(){
        
        let tradeupMessage = '<b>Tradeup Amount:</b> '+(this.tradeKeepTotal ? this.tradeKeepTotal : '0.00') +' <b>Contract:</b> '+this.ContractRecord.Name + ' <b>Buyout Type:</b> Trade Up to Keep';
        this.openApplication = true;
        this.popupHeaderMessage = 'TradeUp Keep Application';
        this.inputVariables = [
            {
                name: 'recordId',
                type: 'String',
                value: this.ContractRecord.Customer__c
            },
             {
                name: 'TradeBuyoutMsg',
                type: 'String',
                value: tradeupMessage
             }
            ];
    }
    handleClose(){
        this.openApplication = false;
    }
    handleStatusChange(event) {
        console.log('event.detail.status',event.detail.status);
        if (event.detail.status === 'FINISHED') {
            this.openApplication = false;
        }
    }
}