import { LightningElement, api, track } from 'lwc';

export default class SL_JsonTable extends LightningElement {
    @api header = [];
    @api rows = [];
    @api hasFooter = false;
    @api totalColumn = "";
    @api totalLabel = "";
    @api totalValue = 0;
    @api rowsSelection = false;
    hasRows;
    get totalColumnIsAfter(){
        if(this.hasRows && this.rows[0] && this.rows[0].fieldsArray){
            return this.rows[0].fieldsArray.findIndex(field => field.key == this.totalColumn);
        }else{
            return 1;
        }}

    connectedCallback(){
        this.hasRows = Boolean(this.rows.length);
    }
// moved processing to parent

    handleKeyClick(event){
        event.preventDefault();
        this.dispatchEvent(new CustomEvent("gotokey", {detail: event.target.dataset.destination}));
    }

    handleGoToOther(event){
        event.preventDefault();
        this.dispatchEvent(new CustomEvent("gotomode", {
            detail: {key: event.target.dataset.destination, mode: event.target.dataset.mode}}));
    }

    handleRowSelection(event){
        event.preventDefault();
        this.dispatchEvent(new CustomEvent("rowselection", {detail: {
            destination : event.target.dataset.destination,
            checked : event.target.checked

        }}));
    }
}