import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hubExecute from '@salesforce/apex/SL_Activity360.hubExecute';

const COLUMNS = [
    { label: "Date", fieldName: "activityDate", type: "date", sortable: true, fixedWidth: 150,
        typeAttributes: { month: "2-digit", day: "2-digit", year: "numeric",hour: "2-digit", minute: "2-digit" } },
    { label: "Type", fieldName: "recordUrl", type: "url", hideDefaultActions: true, initialWidth: 94, typeAttributes: { label: { fieldName: 'type' } } },
    { label: "Comments", fieldName: "description", initialWidth: 440, wrapText: true },
    { label: "Owner", fieldName: "owner", hideDefaultActions: true, initialWidth: 77 },
    { label: "Activity", fieldName: "activity", hideDefaultActions: true, initialWidth: 48 },
    { label: "Primary Call Outcome", fieldName: "primaryCallOutcome", hideDefaultActions: true, initialWidth: 121 },
    { label: "Case Reason", fieldName: "caseReason", hideDefaultActions: true, initialWidth: 85 },
    { label: "Closed Reason", fieldName: "closedReason", hideDefaultActions: true, initialWidth: 65 },
    { label: "Related To", fieldName: "parentUrl", type: "url", hideDefaultActions: true, initialWidth: 110, typeAttributes: { label: { fieldName: 'parentName' } } }
];

export default class SL_Activity360 extends LightningElement {
    @api recordId;
    isLoading = false;

    columns = COLUMNS;
    data = [];
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy;

    connectedCallback(){
        this.isLoading = true;
        hubExecute({methodName: 'getAllActivities', methodParameters: [this.recordId]})
        .then((result)=>{
            console.log(result);
            let obj = JSON.parse(result);
            console.log(obj);
            if(obj.data){
                this.data = obj.data;
                this.doSort("activityDate", "desc");
            } else {
                this.showError(obj.error);
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    doSort(sortedBy, sortDirection){
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.doSort(sortedBy, sortDirection);
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