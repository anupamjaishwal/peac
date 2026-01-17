import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_DelayedEmail.hubExecute';
import { NavigationMixin } from 'lightning/navigation';

const HEADER = [
    { name: "CronJobDetailId", label: "Email Message"},
    { name: "CreatedById", label: "Created By" },
    { name: "statusLabel", label: "Email Status" },
    { name: "MessageDate", label: "Next Run Time" },
    { name: "CancelEmail", label: "" }
];
const A = ["CancelEmail"];

export default class SlViewScheduledQB extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading;

    scheduledQBHeader = HEADER;
    scheduledQBs = [];

    connectedCallback(){
        this.isLoading = true;
        hubExecute({methodName: 'getScheduledQBs', methodParameters: [this.recordId]})
        .then(result =>{
            this.processScheduledQB(result);
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleCancelEmail(event){
        this.confirmCancel(event.detail);        
    }


    handleViewEmail(event){
        
        let recordId = event.detail.key;
        console.log("handleViewEmail recordId "+recordId );

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
            recordId: recordId,
            actionName: 'view'
            }
            });
        //this.confirmCancel(event.detail);        
    }

    async confirmCancel(jobId){
        let message = `The Buyout Email in with ID: ${jobId} will not be sent, Click Ok to confirm.`;
        const isConfirmed = await LightningConfirm.open({
            message: message,
            variant: 'headerless',
            label: message
        });
        this.isConfirmed = isConfirmed;
        if(isConfirmed){
            this.isLoading = true;
            hubExecute({methodName: 'cancelScheduledQB', methodParameters: [this.recordId, jobId]})
            .then(result =>{
                this.processScheduledQB(result);
            })
            .catch((error)=>{
                showError(this, error);
            })
            .finally(()=>{this.isLoading = false;});
        }
    }

    handleClose(){
        this.dispatchEvent(new CustomEvent("closesquedule", {detail: ""}));
    }

    processScheduledQB(result){
        console.log("result: ",result);
        let obj = JSON.parse(result);
        if(obj){
            if(obj.length > 0){
                let finalRows = [];
                let headers = [], linkZeldas = [], checkBoxes = [], currencies = [], recordKey = "";
                headers = HEADER;
                linkZeldas = A;
                recordKey = "Id";
                obj.forEach((row, i)=>{
                    let fieldsArray = [];
                    headers.forEach(column =>{
                        let key = column.name;
                        let isLink = linkZeldas.includes(key);
                        let isCherwell = false;
                        let isCheck = checkBoxes.includes(key);
                        let isCurrency = currencies.includes(key);
                        let headerLabel = column.label;
                        let processedValue = row[key] === "" && isCurrency? "0": row[key];
                        let isWaiver = false;
                        if(isLink && key == "CancelEmail")
                            processedValue = "Cancel Email";
                        if(key == "CronJobDetailId"){
                            isWaiver = true;
                            processedValue = row.Subject + ' : '+  row.Id;
                        }else if(key == "CreatedById"){
                            processedValue = row.CreatedBy.Name;
                        }else if(key == "MessageDate"){
                            processedValue = new Date(row.MessageDate).toISOString().slice(0, 10);
                        }
                        else if(key == "statusLabel"){
                            if(row.statusLabel == "Draft"){
                                processedValue = "Scheduled"
                            }
                        }
                        fieldsArray.push({ key: key,
                            label: headerLabel,
                            value: processedValue,
                            isLink: isLink,
                            isCherwell: isCherwell,
                            isCheck: isCheck,
                            isWaiver: isWaiver,
                            isCurrency: isCurrency,
                            isChecked: row[key]== "1",
                            isPlain: !isLink && !isCherwell && !isCheck && !isCurrency && !isWaiver});
                    });
                    finalRows.push({index: i, showIt: true, isWaiverEnabled:true, destination: row[recordKey], fieldsArray: fieldsArray});
                });
                this.scheduledQBs = finalRows;
                
            }else{
                this.dispatchEvent(new ShowToastEvent({
                    message: 'There are no Delayed Buyout email records related to this Contract.'
                }));
                this.handleClose();
            }
        } else {
            showError(this, JSON.stringify(obj), "Response came in unexpected format");
        }
    }
}