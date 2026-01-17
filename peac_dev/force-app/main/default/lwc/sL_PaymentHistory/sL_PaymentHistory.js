import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPaymentHistory from '@salesforce/apex/SL_SummaryAndDetail.getPaymentHistory';
import getDetailByPymtKey from '@salesforce/apex/SL_SummaryAndDetail.getDetailByPymtKey';
import { showError } from "c/sL_Common";


const PYMT_HISTORY_HEADER = [
    { name: "PymtKey", label: "Key" },
    { name: "PymtType", label: "Payment Type" },
    { name: "CheckMemo", label: "Check Memo" },
    { name: "DateReceived", label: "Date Received" },
    { name: "PymtAmount", label: "Payment Amount" },
    { name: "TotalRental", label: "Total Rental" }
];
const PYMT_HISTORY_A = ["PymtKey"];
const PYMT_HISTORY_CHECK = [];
const PYMT_HISTORY_CURRENCY = ["PymtAmount", "TotalRental"];

const PYMT_DETAIL_HEADER = [
    { name: "PymtKey", label: "PymtKey" },
    { name: "PostingDate", label: "PostingDate" },
    { name: "PymtMethod", label: "PymtMethod" },
    { name: "BatchNumber", label: "BatchNumber" },
    { name: "PymtMemo", label: "Payment Returned Reason" },
    { name: "PymtReverse", label: "PymtReverse" },
    { name: "ReferenceNo", label: "ReferenceNo" },
    { name: "PaymentAmount", label: "PaymentAmount" },
    { name: "MiscReceived", label: "MiscReceived" },
    { name: "Current", label: "Current" },
    { name: "Past1", label: "Past1" },
    { name: "Past31", label: "Past31" },
    { name: "Past61", label: "Past61" },
    { name: "Past91", label: "Past91" },
    { name: "StateTaxes", label: "StateTaxes" },
    { name: "CountyTaxes", label: "CountyTaxes" },
    { name: "CityTaxes", label: "CityTaxes" },
    { name: "TCountyTaxes", label: "TCountyTaxes" },
    { name: "TCityTaxes", label: "TCityTaxes" },
    { name: "WaivedAmout", label: "Waived Amount" },
    { name: "LateChargeAmt", label: "Late Charge Amount" },
    { name: "LcStateTaxes", label: "LcStateTaxes" },
    { name: "LcCountyTaxes", label: "LcCountyTaxes" },
    { name: "LcCityTaxes", label: "LcCityTaxes" },
    { name: "LcTCountyTaxes", label: "LcTCountyTaxes" },
    { name: "LcTCityTaxes", label: "LcTCityTaxes" },
    { name: "AdjustCode", label: "AdjustCode" },
    { name: "UserId", label: "UserId" }
];
const PYMT_DETAIL_A = ["PymtKey"];
const PYMT_DETAIL_CHECK = [];
const PYMT_DETAIL_CURRENCY = ["PaymentAmount", "MiscReceived", "Current", "Past1", "Past31", 
    "Past61", "Past91", "StateTaxes", "CountyTaxes", "CityTaxes", "TCountyTaxes", "TCityTaxes",
    "WaivedAmout", "LateChargeAmt", "LcStateTaxes", "LcCountyTaxes", "LcCityTaxes", "LcTCountyTaxes",
    "LcTCityTaxes"];

const MISC_CHARGES_HEADER = [
    { name: "MiscHistKey", label: "Misc Key" },
    { name: "MiscDesc", label: "Misc Description" },
    { name: "MiscAmount", label: "Misc Amount" },
    { name: "MiscDate", label: "Misc Date" }
];
const MISC_CHARGES_A = [];
const MISC_CHARGES_CHECK = [];
const MISC_CHARGES_CURRENCY = ["MiscAmount"];

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
    currentPymtKey = "";
    
    miscChargesHeader = MISC_CHARGES_HEADER;
    @track miscCharges = [];

    connectedCallback(){
        this.callPaymentHistory(true, []);        
    }

    handleGoToCherwell(event){
        window.open("http://njcherwell01/CherwellPortal/ARRequest?_=7bffa4b0#0", "_blank");
    }

    callPaymentHistory(isFirstTime, tempPayments){
        this.isLoading = true;
        getPaymentHistory({recordId: this.recordId, isFirstTime: isFirstTime})
        .then((result)=>{
            console.log("result: ", JSON.parse(result));
            let rawResponse = JSON.parse(result);
            this.isIL10 = rawResponse.isIL10;
            this.isAlsoIL9 = rawResponse.isAlsoIL9;
            let callIL9OnDetail = (this.isAlsoIL9 && !isFirstTime) || (isFirstTime && !this.isIL10);
            let obj = this.isIL10 && isFirstTime? rawResponse.actualResponse.response.Response: rawResponse.actualResponse.Response;
            if(obj.Success == "True"){
                obj.Payments.forEach((row) =>{
                    if(row.PymtType != "Standard" || row.CheckMemo != "Transaction Migrated"){// filter migrated
                        tempPayments.push({showIt: true, callIL9: callIL9OnDetail, ...row});
                    }
                });
                if(this.isAlsoIL9 && isFirstTime){
                    this.callPaymentHistory(false, tempPayments);
                }else{
                    this.isLoading = false;
                    this.processRows("payments", tempPayments);
                }
            }
            
        })
        .catch((error)=>{
            showError(this, error);
            this.isLoading = false;
        }).finally(()=>{});
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
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field => field.key == "PymtKey"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "PostingDate"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "AdjustCode"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "PaymentAmount"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "MiscReceived"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "WaivedAmout"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LateChargeAmt"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Current"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Past1"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Past31"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Past61"));
                tempLeftColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "Past91"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "PymtMethod"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "BatchNumber"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "PymtMemo"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "ReferenceNo"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "StateTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "CountyTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "CityTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "TCountyTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "TCityTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LcStateTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LcCountyTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LcCityTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LcTCountyTaxes"));
                tempRightColumn.push(finalRows[0].fieldsArray.find(field =>field.key == "LcTCityTaxes"));
                this.leftColumn = tempLeftColumn;
                this.rightColumn = tempRightColumn;
                break;
            case "miscCharges":
                this.miscCharges = [...finalRows];
                break;
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
        getDetailByPymtKey({pymtKey: event.detail, isIL10: rowIsIL10})
        .then((result)=>{
            let rawResponse = JSON.parse(result);
            console.log("result: ", rawResponse);
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
                if(Object.keys(obj).length){
                    tempPaymentDetail.push(obj);
                    this.processRows("paymentDetail", tempPaymentDetail);
                    tempMiscCharges.forEach((row) =>{
                        extended.push({showIt: true, ...row});
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
}