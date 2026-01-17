import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_DPSubscribeToReport.hubExecute';

export default class SL_DPSubscribeToReport extends LightningElement {
    isLoading = false;
    isModalOpen = false;
    get isReportEmpty() { return !this.targetReport }
    reports = [];
    targetReport = "";
    allUsers = [];
    subscribableReports = [];
    alreadySubscribed = {};
    subscribers = [];
    frequency = "Monthly";
    weekDay = "";
    day = "14";

    connectedCallback(){
        this.isLoading = true;
        hubExecute({methodName: "getSubscriptionData", methodParameters: []})
        .then(result => {
            this.parseSubscriptionData(result);
        })
        .catch(error => {
            showError(this, error);
        })
        .finally(() => { this.isLoading = false; });
    }

    handleOpen(){
        this.isModalOpen = true;
    }

    handleClose(){
        this.targetReport = "";
        this.subscribers = [];
        this.isModalOpen = false;
    }

    handleTargetReport(event){
        this.targetReport = event.target.value;
        this.subscribers = [];
        this.isLoading = true;
        let selectedReport = this.alreadySubscribed? this.alreadySubscribed[this.targetReport]: undefined;
        console.log("selectedReport: ", selectedReport);
        if(selectedReport){
            selectedReport.forEach(subscription =>{
                this.subscribers.push(subscription.User__c);
            })
        }
        this.isLoading = false;
    }

    handleSubsChange(event){
        this.subscribers = event.detail.value;
    }

    handleSave(event){
        let reportCombobox = this.template.querySelector("lightning-combobox");
        reportCombobox.reportValidity();
        // doIt = reportCombobox.checkValidity();
        if(reportCombobox.checkValidity()){
            this.isLoading = true;
            let parameters = [this.targetReport, JSON.stringify(this.subscribers), this.frequency, this.weekDay, this.day ];
            hubExecute({methodName: "saveSubscriptions", methodParameters: parameters})
            .then(result => {
                this.parseSubscriptionData(result);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Subscription(s) saved successfully",
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                showError(this, error);
            })
            .finally(() => { this.isLoading = false; });
        }
    }

    parseSubscriptionData(result){
        let obj = JSON.parse(result);
        console.log("obj: ", obj);
        if(obj && obj.subscribableReports){
            this.reports = [];
            this.allUsers = [];
            this.alreadySubscribed = {};
            obj.subscribableReports.forEach(report =>{
                this.reports.push({ label: report.Label, value: report.Report__c });
            });
            this.subscribableReports = obj.subscribableReports;
            obj.availableUsers.forEach(user =>{
                this.allUsers.push({ label: user.Name, value: user.Id });
            });
            this.alreadySubscribed = obj.alreadySubscribed;
        } else {
            showError(this, "unknown result returned: " + JSON.stringify(obj));
        }
    }
}