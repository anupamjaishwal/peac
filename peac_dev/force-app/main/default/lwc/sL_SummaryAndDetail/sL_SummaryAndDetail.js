import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpenItems from '@salesforce/apex/SL_SummaryAndDetail.getOpenItems';
import getWaiverCodes from '@salesforce/apex/SL_SummaryAndDetail.getWaiverCodes';
import sendWaiverByOiKey from '@salesforce/apex/SL_SummaryAndDetail.sendWaiverByOiKey';
import getDetailByOiKey from '@salesforce/apex/SL_SummaryAndDetail.getDetailByOiKey';


const OPEN_ITEM_HEADER = [
    { name: "action1", label: "" },
    { name: "OiKey", label: "Open Item Number" },
    { name: "InvoiceNumber", label: "Invoice #" },
    { name: "DateDue", label: "Date Due" },
    { name: "Aging", label: "Aging" },
    { name: "TotalInvoiced", label: "Total Invoiced" },
    { name: "TotalReceived", label: "Total Received" },
    { name: "WaivedAmount", label: "Waived Amount" },
    { name: "TotalDue", label: "Total Due" },
    { name: "IsMisc", label: "Is Misc" },
    { name: "IsRental", label: "Is Rental" },
    { name: "IsLateChrg", label: "Is Late Charge" },
    { name: "PymtApplied", label: "Payment Applied" }
];
const OPEN_ITEM_A = ["OiKey"];
const OPEN_ITEM_CHECK = ["IsMisc", "IsRental", "IsLateChrg", "PymtApplied"];

const CHARGES_HEADER = [
    { name: "action1", label: "" },
    { name: "ChargeType", label: "ChargeType" },
    { name: "ChargeDesc", label: "ChargeDesc" },
    { name: "InvoiceAmount", label: "Invoice Amount" },
    { name: "TotalReceived", label: "Total Received" },
    { name: "TotalDue", label: "Total Due" }
];
const CHARGES_A = ["action1", "ChargeType"];
const CHARGES_CHECK = [];

const PAYMENTS_HEADER = [
    { name: "PymtKey", label: "Transaction Number" },
    { name: "PymtType", label: "Type" },
    { name: "PymtDateReceived", label: "Date Received" },
    { name: "PymtMemo", label: "Payment Memo" },
    { name: "AmountPaidToCharge", label: "AmountPaidToCharge" }
];
const PAYMENTS_A = ["PymtKey"];
const PAYMENTS_CHECK = [];

export default class SL_SummaryAndDetail extends LightningElement {
    @api recordId;
    openItemHeader = OPEN_ITEM_HEADER;
    isLoading;
    selectedFilter = "";
    rowsRetrieved = false;
    isIL10 = true;
    openItems;
    @track filtered = [];
    openItemSort = {column: "DateDue", isAscending: false};


    currentMode = "summary";
    get isSummary(){ return this.currentMode == "summary"; }
    get isDetail(){ return this.currentMode == "detail"; }
    get isWaiver(){ return this.currentMode == "waiver"; }
    isExpanded = false;

    isLoadingWaiver;
    isSendingWaiver;

    chargesHeader = CHARGES_HEADER;
    isLoadingDetail;
    @track charges = [];
    currentOiKey = "";
    allPayments = [];

    paymentsHeader = PAYMENTS_HEADER;
    @track payments = [];
    paymentSort = {column: "PymtDateReceived", isAscending: false};

    get filterOptions() {
        return [
            { label: "All", value: "" },
            { label: "Misc", value: "IsMisc" },
            { label: "Rental", value: "IsRental" },
            { label: "Late Charge", value: "IsLateChrg" },
            { label: "Paid", value: "PymtApplied" },
            { label: "Unpaid", value: "notPymtApplied" }
        ];
    }
    @track waiverCodes = [];

    connectedCallback(){
        this.isLoading = true;
        getOpenItems({recordId: this.recordId})
        .then((result)=>{
            let rawObj = JSON.parse(result);
            console.log("raw result: ", rawObj);
            this.isIL10 = rawObj.isIL10;
            let obj = this.isIL10? (rawObj.actualResponse.response.Response): rawObj.actualResponse.Response;
            console.log("response obj: ", obj);
            if(obj.Success == "True"){
                let extraColumns = {action1: "waive"};
                this.openItems = [];
                obj.OpenItems.forEach((row) =>{
                    this.openItems.push({showIt: true, ...extraColumns, ...row});
                });
                
                this.applyFilter();
            }
            
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{
            this.isLoading = false;
        });
        
    }

    changeFilter(event){
        this.isLoading = true;
        this.selectedFilter = event.detail.value;
        this.applyFilter();
        this.isLoading = false;
    }

    applyFilter(){
        //Modified by Harsh@Silverline SL-1425 07/08/2022 
        this.isLoading = true;
        let preliminary = this.openItems.filter((openItem, i) => {
            let result = false;
            let decimalTotalDue = parseFloat(openItem.TotalDue);
            if(this.selectedFilter == "notPymtApplied"){
                result = decimalTotalDue > 0 ? true : false;
            }else if(this.selectedFilter == "PymtApplied"){
                result = decimalTotalDue <= 0 ? true : false;
            }
            else{
                result = !this.selectedFilter || openItem[this.selectedFilter] == "1";
            }
            return result;
        });
        if(this.selectedFilter == "notPymtApplied"){
            this.hasFooter = true;
            this.totalColumn = "TotalDue";
            this.totalLabel = "Total Amount Due";
            this.totalValue = preliminary.reduce((total, openItem) => total += parseFloat(openItem[this.totalColumn]), 0);
        }else{
            this.hasFooter = false;
        }
        preliminary.forEach((openItem) => {
            openItem.showIt = true;
        });
        this.processRows("openItems", preliminary);
    }

    processRows(whichTable, preliminary){
        let finalRows = [];
        let linkZeldas = [], checkBoxes = [], recordKey = "", headers = [];
        switch (whichTable){
            case 'openItems':
                linkZeldas = OPEN_ITEM_A;
                checkBoxes = OPEN_ITEM_CHECK;
                headers = OPEN_ITEM_HEADER;
                recordKey = "OiKey";
                preliminary = this.sortRows(preliminary, this.openItemSort);
                break;
            case "charges":
                linkZeldas = CHARGES_A;
                checkBoxes = CHARGES_CHECK;
                headers = CHARGES_HEADER;
                recordKey = "ChargeType";
                break;
            case "payments":
                linkZeldas = PAYMENTS_A;
                checkBoxes = PAYMENTS_CHECK;
                headers = PAYMENTS_HEADER;
                recordKey = "PymtKey";
                preliminary = this.sortRows(preliminary, this.paymentSort);
                break;
        }
        preliminary.forEach((row, i)=>{
            let fieldsArray = [];
            headers.forEach(column => {
                if(row[column.name] !== undefined){
                    let key = column.name;
                    let isLink = linkZeldas.includes(key);
                    let isWaiver = row[key] == "waive";
                    let isCheck = checkBoxes.includes(key);
                    fieldsArray.push({ key: key,
                        value: row[key],
                        isLink: isLink,
                        isWaiver: isWaiver,
                        isCheck: isCheck,
                        isChecked: row[key]== "1",
                        isPlain: !isLink && !isWaiver && !isCheck});
                }
            })
            finalRows.push({index: i, showIt: row.showIt, destination: row[recordKey], 
                isWaiverEnabled: row.IsRental=="0" && row.PymtApplied=="0", fieldsArray: fieldsArray});
        });
        switch (whichTable){
            case 'openItems':
                this.filtered = [...finalRows];
                break;
            case "charges":
                this.charges = [...finalRows];
                break;
            case "payments":
                this.payments = [...finalRows];
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

    handleGoToWaiver(event){
        this.currentMode = "waiver";
        this.isLoadingWaiver = true;
        this.currentOiKey = event.detail.key;
        getWaiverCodes()
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj){
                this.waiverCodes = obj;
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{
            this.isLoadingWaiver = false;
        });
    }

    handleSendWaiver(event){
        if(!this.template.querySelector('lightning-combobox').value){
            this.showError("A waiver type is required in order to request a waiver.");
        } else {
            this.isSendingWaiver = true;
            let parameters = {recordId: this.recordId, oiKey: this.currentOiKey};
            let inputs = this.template.querySelectorAll("lightning-input");
            inputs.forEach(input => {
                parameters[input.name] = input.value;
            });
            let comboBox =this.template.querySelector('lightning-combobox');
            parameters[comboBox.name] = comboBox.value;
            parameters["isIL10"] = this.isIL10;
            sendWaiverByOiKey(parameters)
            .then((result)=>{
                let rawResponse = JSON.parse(result)
                let obj = this.isIL10? rawResponse.response: rawResponse;
                if(obj.Messages && obj.Messages.Msg1 == "Success"){
                    this.shiftToSummary();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: obj.Messages.Msg1,
                            message: "The Waiver was sent successfully.",
                            variant: 'success'
                        })
                    );
                    this.connectedCallback();
                } else {
                    if(obj.Errors){
                        this.showError(obj.Errors.Err1, obj.Messages.Msg1);
                    }
                }
            })
            .catch((error)=>{
                this.showError(error);
            })
            .finally(()=>{
                this.isSendingWaiver = false;
            });
        }
    }

    handleGoToDetail(event){
        this.currentMode = "detail";
        this.isLoadingDetail = true;
        this.currentOiKey = event.detail;
        getDetailByOiKey({oiKey: event.detail, isIL10: this.isIL10}) // will use the property when ready
        .then((result)=>{
            let obj = this.isIL10? (JSON.parse(result).response.Response): JSON.parse(result).Response;
            if(obj.Success == "True"){
                let extraColumns = { action1: ">"};
                let tempCharges = [];
                let tempPayments = [];
                console.log("detail obj: ", obj);
                obj.OiChargeDetails.forEach((row) =>{
                    tempPayments.push({ChargeType: row.ChargeType, Payments: row.Payments});
                    delete row.Payments;
                    tempCharges.push({showIt: true, ...extraColumns, ...row});
                });
                this.allPayments = tempPayments;
                this.processRows("charges", tempCharges);
            }
            
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{
            this.isLoadingDetail = false;
        });
    }

    handleGoToSummary(event){
        event.preventDefault();
        this.shiftToSummary();    
    }

    shiftToSummary(){
        this.currentMode = "summary";
        this.isExpanded = false;
    }

    handleExpandCharge(event){
        if(!this.isExpanded){
            event.preventDefault();
            let chargeType = event.detail;
            this.isExpanded = true;
            let tempPayments = [];
            let extended = [];
            let tempCharges = [];
            tempCharges = this.charges;
            tempCharges.forEach(row=> {
                row.showIt = row.destination == chargeType; // already processed table, the key was moved there
            });
            this.charges = [...tempCharges];
    
            for(let i = 0; i <this.allPayments.length; i++){
                if(this.allPayments[i].ChargeType == chargeType){
                    tempPayments = this.allPayments[i].Payments;
                    tempPayments = tempPayments? tempPayments: [];
                    break;
                }
            }
    
            tempPayments.forEach(row=>{
                extended.push({showIt: true, ...row});
            });
            this.processRows("payments", extended);
        }else
            this.handleCollapseCharge(event);
    }

    handleCollapseCharge(event){
        event.preventDefault();
        let tempCharges = this.charges;
        tempCharges.forEach(row=> row.showIt = true);
        this.charges = [...tempCharges];
        this.isExpanded = false;
    }

    showError(error, customTitle){
        let message = (error && error.body && error.body.message) || error.message || error;
        let title = customTitle || 'Error';
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'error'
            })
        );
    }
}