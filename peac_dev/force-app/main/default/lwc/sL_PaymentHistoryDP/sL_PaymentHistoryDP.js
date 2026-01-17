import { LightningElement, api, track } from "lwc";
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SheetJS from '@salesforce/resourceUrl/SheetJS'; // The static resource for SheetJS
import sendPaymentsToApex from '@salesforce/apex/SL_PaymentHistoryDPController.sendPaymentsToApex';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';
import getDetailByPymtKeyDP from '@salesforce/apex/SL_SummaryAndDetail.getDetailByPymtKeyDP';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { showError } from "c/sL_Common";


const PYMT_HISTORY_HEADER = [
    { name: "PymtKey", label: "Key" },
    { name: "PymtType", label: "Payment Type" },
    { name: "CheckMemo", label: "Check Memo" },
    { name: "DateReceived", label: "Date Received" },
    { name: "PymtAmount", label: "Payment Amount" },
    { name: "TotalRental", label: "Total Rental" },
    { name: 'Taxes', label: 'Taxes' }, // New column for Taxes
    { name: 'MiscFees', label: 'Misc Fees' }, // New column for Misc Fees
    { name: 'PassThrough', label: 'Pass-Through' }, // New column for Pass-Through
    { name: 'LateChargeAmt', label: 'Late Fees' }, // New column for Taxes
    { name: "TotalRemainingDue", label: "Total Remaining Due" } 

];
const PYMT_HISTORY_A = ["PymtKey"];
const PYMT_HISTORY_CHECK = [];
const PYMT_HISTORY_CURRENCY = ["PymtAmount", "TotalRental", "Taxes", "MiscFees", "PassThrough", "LateChargeAmt", "TotalRemainingDue"];

const PYMT_DETAIL_HEADER = [
    { name: "PymtKey", label: "PymtKey" },
    { name: "PostingDate", label: "Posting Date" },
    // { name: "BatchNumber", label: "BatchNumber" },
    { name: "PymtReverse", label: "PymtReverse" },
    { name: "PaymentAmount", label: "Amount Received" },
    { name: "TotRental", label: "Contract Payment" },
    { name: "MiscReceived", label: "Misc Received" },
    { name: "Taxes", label: "Taxes" },
    { name: "WaivedAmout", label: "Waived Amount" },
    { name: "LateChargeAmt", label: "Late Charges" },
    { name: "Current", label: "Contract Payment Current" },
    { name: "Past1", label: "Contract Payment Past1" },
    { name: "Past31", label: "Contract Payment Past31" },
    { name: "Past61", label: "Contract Payment Past61" },
    // { name: "Past91", label: "Contract Payment Past91" },
    { name: "Past91Plus", label: "Contract Payment 91" },
    { name: "Past121Plus", label: "Past121+" },
    // { name: "StateTaxes", label: "StateTaxes" },
    // { name: "CountyTaxes", label: "CountyTaxes" },
    // { name: "CityTaxes", label: "CityTaxes" },
    // { name: "TCountyTaxes", label: "TCountyTaxes" },
    // { name: "TCityTaxes", label: "TCityTaxes" },
    { name: "PymtMethod", label: "Pymt Method" },
    { name: "ReferenceNo", label: "Reference Number" },
    { name: "PymtMemo", label: "Payment Returned Reason" },
    { name: "CheckNo", label: "Check Number" },
    { name: "InvoiceNo", label: "Invoice Number(s)" },
    // { name: "LcStateTaxes", label: "LcStateTaxes" },
    // { name: "LcCountyTaxes", label: "LcCountyTaxes" },
    // { name: "LcCityTaxes", label: "LcCityTaxes" },
    // { name: "LcTCountyTaxes", label: "LcTCountyTaxes" },
    // { name: "LcTCityTaxes", label: "LcTCityTaxes" },
    { name: "AdjustCode", label: "AdjustCode" },
    { name: "UserId", label: "UserId" }
];
const PYMT_DETAIL_A = ["PymtKey"];
const PYMT_DETAIL_CHECK = [];
const PYMT_DETAIL_CURRENCY = ["PaymentAmount", "TotRental", "MiscReceived", "Current", "Past1", "Past31", 
    "Past61", /*"Past91",*/ "Past91Plus", "Past121Plus", "Taxes", "WaivedAmout", "LateChargeAmt"];

const MISC_CHARGES_HEADER = [
    { name: "MiscHistKey", label: "Misc Key" },
    { name: "MiscDesc", label: "Misc Description" },
    { name: "MiscRcvd", label: "Misc Amount Total" },
    { name: "MiscAmt", label: "Payment Amount (excluding taxes)" },
    { name: "MiscPassThru", label: "Pass Through to Dealer" },
    { name: "Taxes", label: "Taxes" },
    // { name: "MiscStateTax", label: "Misc State Tax" },
    // { name: "MiscCntyTax", label: "Misc County Tax" },
    // { name: "MiscCityTax", label: "Misc City Tax" },
    // { name: "MiscTCityTax", label: "Misc TCity Tax" },
    // { name: "MiscTCntyTax", label: "Misc TCounty Tax" },
    { name: "MiscDate", label: "Misc Date" }
];
const MISC_CHARGES_A = [];
const MISC_CHARGES_CHECK = [];
const MISC_CHARGES_CURRENCY = ["MiscRcvd", "MiscAmt", "MiscPassThru", "Taxes"];

export default class SL_PaymentHistory extends LightningElement {
    @api recordId;
    paymentHeader = PYMT_HISTORY_HEADER;
    isLoading;
    isIL10 = true;
    isAlsoIL9 = false;
    @track payments = [];
    paymentSort = {column: "DateReceived", isAscending: false};

    currentMode = "summary";
    get isSummary(){ return this.currentMode == "summary"; }
    get isDetail(){ return this.currentMode == "detail"; }

    paymentDetailHeader = PYMT_DETAIL_HEADER;
    isLoadingDetail;
    paymentDetail = [];
    @track leftColumn = [];
    @track rightColumn = [];
    @track contractFieldsInfo;
    @track contractRecord;
    currentPymtKey = "";
    
    miscChargesHeader = MISC_CHARGES_HEADER;
    @track miscCharges = [];

    async connectedCallback(){
        await loadScript(this, SheetJS); // load the library
        this.callPaymentHistory(true, []);
        // At this point, the library is accessible with the `XLSX` variable
        this.version = XLSX.version;
    }

    handleGoToCherwell(event){
        window.open("http://njcherwell01/CherwellPortal/ARRequest?_=7bffa4b0#0", "_blank");
    }

    callPaymentHistory(isFirstTime, tempPayments) {
        this.isLoading = true;
        requestByContractNumber({ recordId: this.recordId, nitroApiOption: "getPaymentHistoryDP", additionalKeys: isFirstTime.toString() })
            .then((result) => {
                console.log("result: ", JSON.parse(result));
                let rawResponse = JSON.parse(result);
                this.isIL10 = rawResponse.isIL10;
                this.isAlsoIL9 = rawResponse.isAlsoIL9;
                let callIL9OnDetail = (this.isAlsoIL9 && !isFirstTime) || (isFirstTime && !this.isIL10);
                console.log("this.isIL10 && isFirstTime: ", this.isIL10 && isFirstTime);
                // console.log("this.isAlsoIL9: ", this.isAlsoIL9);
                let obj = this.isIL10 && isFirstTime ? rawResponse.actualResponse.response.Response : rawResponse.actualResponse.Response;
                if (obj.Success == "True") {
                    obj.Payments.forEach((row) => {
                        if (row.PymtType != "Standard" || row.CheckMemo != "Transaction Migrated") { // filter migrated
                            tempPayments.push({ showIt: true, callIL9: callIL9OnDetail, ...row });
                        }
                    });
                    // DP-2012 as of now I guess we need to modify the call
                    if (this.isAlsoIL9 && isFirstTime) {
                        this.callPaymentHistory(false, tempPayments);
                    } else {
                        this.getTotalsFromCallout(tempPayments, 1);
                    }
                }
            })
            .catch((error) => {
                showError(this, error);
                this.isLoading = false;
            }).finally(() => {});
    }

    getTotalsFromCallout(tempPayments, pageNumber){
        // Call Apex to get Taxes, Misc Fees, and Pass-Through for each payment
        sendPaymentsToApex({ payments: tempPayments, isIL10: this.isIL10, pageNumber: pageNumber})
        .then((apexResult) => {
            let obj = JSON.parse(apexResult);
            let enhancedPayments = obj.processedPayments;
            let nextPage = obj.nextPage;
            console.log('enhanced obj: ', obj);
            if(enhancedPayments){
                for(let i = obj.startIndex; i <= obj.endIndex && i < tempPayments.length; i++){
                    let enhancedPayment = enhancedPayments[i - obj.startIndex]? enhancedPayments[i - obj.startIndex]: {};
                    tempPayments[i].Taxes = enhancedPayment.Taxes;
                    tempPayments[i].MiscFees = enhancedPayment.MiscFees;
                    tempPayments[i].PassThrough = enhancedPayment.PassThrough;
                    tempPayments[i].LateChargeAmt = enhancedPayment.LateChargeAmt;
                }
                if(nextPage > pageNumber){
                    this.getTotalsFromCallout(tempPayments, nextPage);
                }else{
                    // Now pass the enhanced payments with new fields to processRows
                    this.processRows("payments", tempPayments);
                    this.isLoading = false;
                }
            }else{
                showError(this, 'Error Retrieving Payments');
                console.error("object didn't return a valid enhancedPayments variable");
                this.isLoading = false;
            }
        })
        .catch((error) => {
            showError(this, error);
            this.isLoading = false;
        })
        .finally(()=> {});
    }

    processRows(whichTable, preliminary){
        let finalRows = [];
        let headers = [], linkZeldas = [], checkBoxes = [], currencies, recordKey = "";
        switch (whichTable){
            case "payments":
                headers = PYMT_HISTORY_HEADER;
                linkZeldas = PYMT_HISTORY_A;
                checkBoxes = PYMT_HISTORY_CHECK;
                currencies = PYMT_HISTORY_CURRENCY;
                recordKey = "PymtKey";
                preliminary = this.sortRows(preliminary, this.paymentSort);
                break;
            case "paymentDetail":
                headers = PYMT_DETAIL_HEADER;
                linkZeldas = PYMT_DETAIL_A;
                checkBoxes = PYMT_DETAIL_CHECK;
                currencies = PYMT_DETAIL_CURRENCY;
                recordKey = "PymtKey";
                break;
            case "miscCharges":
                headers = MISC_CHARGES_HEADER;
                linkZeldas = MISC_CHARGES_A;
                checkBoxes = MISC_CHARGES_CHECK;
                currencies = MISC_CHARGES_CURRENCY;
                recordKey = "MiscHistKey";
                break;
        }
        preliminary.forEach((row, i)=>{
            let fieldsArray = [];
            headers.forEach(column => {
                if(row[column.name] !== undefined){
                    let key = column.name;
                    let isLink = linkZeldas.includes(key);
                    let isCherwell = false;
                    let isCheck = checkBoxes.includes(key);
                    let isCurrency = currencies.includes(key);
                    let foundHeader = headers.find(column => column.name == key);
                    let headerLabel = foundHeader? foundHeader.label: "";
                    let processedValue = row[key] === "" && isCurrency? "0": row[key];
                    fieldsArray.push({ key: key,
                        label: headerLabel,
                        value: processedValue,
                        isLink: isLink,
                        isCherwell: isCherwell,
                        isCheck: isCheck,
                        isCurrency: isCurrency,
                        isChecked: row[key]== "1",
                        isPlain: !isLink && !isCherwell && !isCheck && !isCurrency});
                }
            });
            finalRows.push({index: i, showIt: row.showIt, destination: row[recordKey], callIL9: row.callIL9, fieldsArray: fieldsArray});
        });
        switch (whichTable){
            case "payments":
                this.payments = [...finalRows];
                break;
            case "paymentDetail":
                this.paymentDetail = [...finalRows];
                let tempLeftColumn = [];
                let tempRightColumn = [];

                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "PymtKey");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "PostingDate");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "PaymentAmount");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "TotRental");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "MiscReceived");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Taxes");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "WaivedAmout");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "LateChargeAmt");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Current");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Past1");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Past31");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Past61");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Past91");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Past91Plus");
                this.pushTransposedField(tempLeftColumn, finalRows[0].fieldsArray, "Past121Plus");
                this.pushTransposedField(tempRightColumn, finalRows[0].fieldsArray, "PymtMethod");
                this.pushTransposedField(tempRightColumn, finalRows[0].fieldsArray, "ReferenceNo");
                this.pushTransposedField(tempRightColumn, finalRows[0].fieldsArray, "PymtMemo");// payment returned Reason
                this.pushTransposedField(tempRightColumn, finalRows[0].fieldsArray, "CheckNo");
                this.pushTransposedField(tempRightColumn, finalRows[0].fieldsArray, "InvoiceNo");
                this.leftColumn = tempLeftColumn;
                this.rightColumn = tempRightColumn;
                break;
            case "miscCharges":
                this.miscCharges = [...finalRows];
                break;
        }
        
    }

    pushTransposedField(transposedRow, fieldsArray, fieldKey){
        let transposedField = fieldsArray.find(field => field.key == fieldKey);
        if(transposedField){
            transposedRow.push(transposedField);
        }
    }

    sortRows(preliminary, sortingSetting){
        preliminary.sort((rowA, rowB) => {
            if(Date.parse(rowA[sortingSetting.column]) < Date.parse(rowB[sortingSetting.column]))
                return -1;
            else if(Date.parse(rowA[sortingSetting.column]) > Date.parse(rowB[sortingSetting.column]))
                return 1;
            else
                return 0;
        });
        if(!sortingSetting.isAscending)
            preliminary.reverse();
        return preliminary;
    }

    hangleGoToDetail(event){
        this.currentMode = "detail";
        this.isLoadingDetail = true;
        this.currentPymtKey = event.detail;
        let currentRow = this.payments.find(row=> row.destination == this.currentPymtKey);
        let rowIsIL10 = currentRow && !currentRow.callIL9;
        getDetailByPymtKeyDP({pymtKey: event.detail, isIL10: rowIsIL10})
        .then((result)=>{
            let rawResponse = JSON.parse(result);
            console.log("detail result: ", rawResponse);
            let obj = rawResponse.response && rawResponse.response.Response || rawResponse.Response;
            if(obj.Success == "True"){
                let tempPaymentDetail = [];
                let tempMiscCharges = [];
                let extended = [];
                tempMiscCharges = obj.MiscCharges? obj.MiscCharges: [];
                delete obj.MiscCharges;
                delete obj.Success;
                delete obj.Errors;
                delete obj.Messages;
                let thePayment = this.payments.find(payment => payment.destination == this.currentPymtKey);
                obj.Taxes = thePayment.fieldsArray.find(field => field.key == "Taxes").value;
                obj.InvoiceNo = obj.InvoiceNo.join(", \r\n");
                if(Object.keys(obj).length){
                    tempPaymentDetail.push(obj);
                    this.processRows("paymentDetail", tempPaymentDetail);
                    tempMiscCharges.forEach((row) =>{
                        let miscTaxes = parseFloat(row.MiscStateTax) + parseFloat(row.MiscCntyTax) + parseFloat(row.MiscCityTax)
                            + parseFloat(row.MiscTCityTax) + parseFloat(row.MiscTCntyTax);
                        extended.push({showIt: true, ...row, Taxes: miscTaxes});
                    });
                    this.processRows("miscCharges", extended);  
                }
                              
            }
            
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{
            this.isLoadingDetail = false;
        });
    }

    handleGoToSummary(event){
        event.preventDefault();
        this.currentMode = "summary";
    }

    handleLoad(event) {
        this.contractRecord = event.detail.records[this.recordId].fields; // gives values of fields against field name
    }

    exportToExcel() {

        if(this.payments.length > 0){
            let contractNumber =  this.contractRecord.Name.value;
            const tableData = this.payments;
            const filename = "Payment History "+contractNumber+".xlsx";
            const workbook = XLSX.utils.book_new();
            const worksheetData = [];
            
            // Iterate through the data and build rows
            for (const record of tableData) {
                let key, type, checkMemo, dateReceived, paymentAmount, totalRental, taxes, miscFee, passThrough, lateFees, totalRemainingDue;
        
                for (let field of record.fieldsArray) {
                    
                    if (field.key == "PymtKey") key = field.value;
                    if (field.key == "PymtType") type = field.value;
                    if (field.key == "CheckMemo") checkMemo = field.value;
                    if (field.key == "DateReceived") dateReceived = field.value;
                    if (field.key == "PymtAmount") {
                        // Ensure the value is numeric
                        paymentAmount = parseFloat(field.value);
                    }
                    if (field.key == "TotalRental") totalRental = parseFloat(field.value);
                    if (field.key == "Taxes") taxes = parseFloat(field.value);
                    if (field.key == "MiscFees") miscFee = parseFloat(field.value);
                    if (field.key == "PassThrough") passThrough = parseFloat(field.value);
                    if (field.key == "LateChargeAmt") lateFees = parseFloat(field.value);
                    if (field.key == "TotalRemainingDue") totalRemainingDue = parseFloat(field.value);
                }
        
                worksheetData.push({
                    "Key": key,
                    "Payment Type": type,
                    "Check Memo": checkMemo,
                    "Date Received": dateReceived,
                    "Payment Amount": paymentAmount,
                    "Total Rental": totalRental,
                    "Taxes": taxes,
                    "Misc Fees": miscFee,
                    "Pass-Through": passThrough,
                    "Late Fees": lateFees,
                    "Total Remaining Due": totalRemainingDue
                });
            }
        
            // Create the worksheet
            const worksheet = XLSX.utils.json_to_sheet(worksheetData);
            
            // Apply currency formatting to specific columns
            this.applyCurrencyFormat(worksheet, 4); // Payment Amount
            this.applyCurrencyFormat(worksheet, 5); // Total Rental
            this.applyCurrencyFormat(worksheet, 6); // Taxes
            this.applyCurrencyFormat(worksheet, 7); // Misc Fees
            this.applyCurrencyFormat(worksheet, 9); // Late Fees
            this.applyCurrencyFormat(worksheet, 10); // Total Remaining Due
        
            // Append the worksheet to the workbook
            XLSX.utils.book_append_sheet(workbook, worksheet, "Payment History");
        
            // Write the Excel file and trigger download
            const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
            const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });
        
            const a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = filename;
            a.click();
            URL.revokeObjectURL(a.href);
        }
  
        else{
            showError(this, "No data to export.");
        }
    }
    
    // Helper function to apply currency format to a specific column
    applyCurrencyFormat(worksheet, colIndex) {
        const range = XLSX.utils.decode_range(worksheet['!ref']);
        
        for (let row = range.s.r; row <= range.e.r; row++) {
            const cellAddress = { r: row, c: colIndex };
            const cell = worksheet[XLSX.utils.encode_cell(cellAddress)];
            
            if (cell && typeof cell.v === 'number') {
                // Apply the correct currency formatting
                cell.s = { numFmt: '"$"#,##0.00' }; // Correct currency format with the dollar sign
            }
        }
    }
    

}