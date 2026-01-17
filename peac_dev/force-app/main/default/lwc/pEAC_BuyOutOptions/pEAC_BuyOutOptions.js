import { LightningElement, api, track, wire } from 'lwc';
import { showError } from 'c/sL_Common';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import buyoutCreationV2 from '@salesforce/apex/SL_SummaryAndDetail.buyoutCreationV2';
import sendBuyout from '@salesforce/apex/SL_SummaryAndDetail.sendBuyout';
import getBuyout from '@salesforce/apex/SL_SummaryAndDetail.getBuyout';
import getcontract from '@salesforce/apex/SL_SummaryAndDetail.getContract';
import sendSummaryBuyout from '@salesforce/apex/SL_SummaryAndDetail.sendSummaryBuyout';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import localizationService from '@salesforce/i18n/internationalizationProperty';
// import updateContractAssets from '@salesforce/apex/SL_SummaryAndDetail.updateContractAssets';
//import SlPartialBuyoutModal from 'c/slPartialBuyoutModal';

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
    { name: "MiscTotalServiceContract", label: "Pass Through" },
    { name: "MiscTotalSumPropertyTax", label: "Property Tax" },
    { name: "MiscTotalSumInsurance", label: "Insurance" },
    { name: "MiscTotalSumOther", label: "Other Lease Charges" },
    { name: "TotalBuyout", label: "Total Buyout" }
];
const DETAIL_A = [];
const DETAIL_CHECK = [];
const DETAIL_CURRENCY = ["ReceivableBalance", "Residual", "SalesTax", "LateCharges", "AlwaysZero", "SecurityDeposit",
    "EndingDeposit", "MiscTotalServiceContract", "MiscTotalSumPropertyTax", "MiscTotalSumInsurance", "MiscTotalSumOther", "TotalBuyout"];

export default class PEAC_BuyOutOptions extends LightningElement {
    @api recordId;
    @api isPartialChecked;
     quoteBuyoutTypes ;
    isExecuting;
    @track isLoading = true;
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
    buyoutTotal;

    showTradeKeep = false;
    showTradeReturn = false;

    connectedCallback(){
        this.tradeReturnTotal = false;
        this.tradeKeepTotal = false;
        console.log('isPartialChecked::',this.isPartialChecked);
        
        getcontract({contractId: this.recordId})
        .then((result)=>{
            this.ContractRecord = result
        });
        this.isLoading = true;
        getBuyout({contractId: this.recordId})
        .then((result)=>{
            this.buyouts = result;
            console.log('result:',JSON.stringify(result));
            this.quoteDescriptions = [];
            this.detailColumn = [
                { name: "ReceivableBalance", label: "Receivable Balance", isCurrency: true,rows: [] },
                { name: "Residual", label: "Residual", isCurrency: true,rows: [] },
                { name: "SalesTax", label: "Sales Tax", isCurrency: true,rows: [] },
                { name: "LateCharges", label: "Late Charges", isCurrency: true,rows: [] },
                { name: "AlwaysZero", label: "Early Termination Fee", isCurrency: true,rows: [] },
                { name: "SecurityDeposit", label: "Security Deposit", isCurrency: true,rows: [] },
                { name: "EndingDeposit", label: "Ending Deposit", isCurrency: true,rows: [] },
                { name: "MiscTotalServiceContract", label: "Pass Through", isCurrency: true,rows: [] },
                { name: "MiscTotalSumPropertyTax", label: "Property Tax", isCurrency: true,rows: [] },
                { name: "MiscTotalSumInsurance", label: "Insurance", isCurrency: true,rows: [] },
                { name: "MiscTotalSumOther", label: "Other Lease Charges", isCurrency: true,rows: [] },
                { name: "TotalBuyout", label: "Total Buyout", isCurrency: true,rows: [] }
            ];
            let cnt =1;
            result.forEach(res => {
                if(res.Name && res.Name.indexOf('Trade Up to Return') != -1){
                    this.showTradeReturn = true;
                    this.tradeReturnTotal = res.Total_Buyout__c;
                }
                if(res.Name && res.Name.indexOf('Trade Up to Keep') != -1){
                    this.showTradeKeep = true;
                    this.tradeKeepTotal = res.Total_Buyout__c;
                }
                this.quoteDescriptions.push(
                    {seq: cnt,label: res.Name}
                );
                this.detailColumn[0].rows.push(
                    {value: res.Receivable_Balance__c,
                        QuoteSeq: cnt }
                );
                this.detailColumn[1].rows.push(
                    {value: res.Residual__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[2].rows.push(
                    {value: res.SalesTax__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[3].rows.push(
                    {value: res.LateCharges__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[4].rows.push(
                    {value: res.Early_Termination_Fee__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[5].rows.push(
                    {value: res.Security_Deposit__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[6].rows.push(
                    {value: res.Ending_Deposit__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[7].rows.push(
                    {value: res.Service_pass_through__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[8].rows.push(
                    {value: res.Property_tax__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[9].rows.push(
                    {value: res.Insurance__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[10].rows.push(
                    {value: res.Other_Lease_Charges__c,
                        QuoteSeq: cnt}
                );
                this.detailColumn[11].rows.push(
                    {value: res.Total_Buyout__c,
                        QuoteSeq: cnt}
                );
                cnt++;
                
            });
            //this.ContractRecord = result;
            this.isLoading = false;
            console.log('this.detailColumn:', JSON.parse(JSON.stringify(this.detailColumn)));
        });
        
    }
    EmailCustBuyout(){
        //console.log('error::',JSON.stringify(rows));
        
            sendBuyout({contractId: this.recordId})
            .then(result => {
                this.showToast('Success!', 'Successfully sent an Email!','success','dismissable');
            })
            .catch(error => {
                //console.log('error:',error);
                //this.cancelScreen(error);
            })
    }
    PrintCustBuyout(){
        //console.log('PrintCustBuyout:');
        window.open('/apex/PEAC_BPPrintEmail?recId=' + this.recordId+'&isPartialChecked='+this.isPartialChecked, "_blank");
    }
    customerBuyoutLetter(){
        window.open('/apex/PEAC_BPCustomerBuyoutLetter?recId='+this.recordId + '&action=letter', "_blank");//this.detailColumn
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
    excelCustBuyout(){
        //console.log('this.ContractRecord',this.ContractRecord);
        let colCnt = this.buyouts.length;
        
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
        doc += '<tr><th></th>';
        this.buyouts.forEach(record => {
            doc += '<th>'+record.Name+'</th>';
        });
       
        doc += '</tr>';
        // Add the data rows
        doc += '<tr>';
        doc += '<td>Receivable Balance</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Receivable_Balance__c ? '$'+record.Receivable_Balance__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Residual</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Residual__c ? '$'+record.Residual__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Sales Tax</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.SalesTax__c ? '$'+record.SalesTax__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Late Charges</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.LateCharges__c ? '$'+record.LateCharges__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Early Termination Fee</td>';
        this.buyouts.forEach(record => {
            
            doc += '<td>'+(record.Early_Termination_Fee__c ? '$'+record.Early_Termination_Fee__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Security Deposit</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Security_Deposit__c ? '$'+record.Security_Deposit__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Ending Deposit</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Ending_Deposit__c ? '$'+record.Ending_Deposit__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Pass Through</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Service_pass_through__c ? '$'+record.Service_pass_through__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Property Tax</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Property_tax__c ? '$'+record.Property_tax__c:'0.00')+'</td>';
        });
        doc += '</tr>';

        doc += '<tr>';
        doc += '<td>Insurance</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Insurance__c ? '$'+record.Insurance__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Other Lease Charges</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Other_Lease_Charges__c ? '$'+record.Other_Lease_Charges__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '<tr>';
        doc += '<td>Total Buyout</td>';
        this.buyouts.forEach(record => {
            doc += '<td>'+(record.Total_Buyout__c ? '$'+record.Total_Buyout__c:'0.00')+'</td>';
        });
        doc += '</tr>';
        doc += '</table>';
        //console.log(':doc:',doc);
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Buyout.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
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
        //console.log('event.detail.status',event.detail.status);
        if (event.detail.status === 'FINISHED') {
            this.openApplication = false;
        }
    }
/*
    handleGoToDetail(event){
        event.preventDefault();
        this.currentMode = "detail";
        //console.log('event.detail::'+JSON.stringify(event.detail));
        let tempQuote = this.quotes.find((row)=> row.QuoteSeq == event.detail);
        //if(tempQuote)
         //   this.processRows("buyoutDetail", [tempQuote]);
        // let tempQuotes = this.quotes;
        //console.log(tempQuotes)
         if(tempQuotes){
             this.processRows("buyoutDetail", tempQuotes);
             //console.log( this.buyoutTotal,'  this.buyoutTotal ',  this.tradeReturnTotal, '   ',  this.tradeKeepTotal)
            
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
                        //console.log('fieldCollection.rows', fieldCollection.rows.length, fieldCollection.rows)
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
                //console.log('this.detailColumn::'+JSON.stringify(this.detailColumn));
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
        //console.log('error::'+JSON.stringify(error));
        showError(error);
    }

    openBuyout(){
        let rows = [...this.detailColumn];
        //console.log('error::',JSON.stringify(rows));
        window.open('/apex/pEAC_CustomerBuyOutLetterClone?rows='+JSON.stringify(rows)+'&recId='+this.recordId+'&action=buyout', "_blank");//this.detailColumn
    }
    
    excelCustBuyout(){
        //console.log('this.ContractRecord',this.ContractRecord);
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
        //console.log(':doc:',doc);
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Buyout.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
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
        //console.log('event.detail.status',event.detail.status);
        if (event.detail.status === 'FINISHED') {
            this.openApplication = false;
        }
    }

    createBuyout(){
        // this.tempMethod();
        buyoutCreationV2({recordId: this.recordId})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj.quoteBuyouts){
                this.buyouts = obj.quoteBuyouts.split(';');
                this.buyouts_clone = this.buyouts;
                this.quoteBuyoutTypes = obj.quoteBuyouts;
    }
    //console.log('this.buyouts::'+JSON.stringify(this.buyouts)+this.buyouts_clone);
     //console.log('this.quoteBuyoutTypes::'+JSON.stringify(this.quoteBuyoutTypes));
     this.createBuyoutDP();
        });
    
   requestByContractNumber({recordId: this.recordId, nitroApiOption: "getPurchaseOption", additionalKeys: ""})
    .then(result => {
        let obj = JSON.parse(result);
        //console.log('@87 obj::'+JSON.stringify(obj));
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

    // currently not set to @auraEnabled when the method is ready, uncomment this
    // updateContractAssets({recordId: this.recordId}).then(result => {
    //     this.showToast('Success!', 'Buyout Created','success','dismissable');
    // });

    }*/

    // async tempMethod(){
    //     const result = await SlPartialBuyoutModal.open({
    //         size: 'large',
    //         description: 'Create Buyouts',
    //         contractId: this.recordId,
    //     });
    // }
}