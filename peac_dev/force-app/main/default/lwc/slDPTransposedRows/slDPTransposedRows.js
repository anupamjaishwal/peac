import { LightningElement, api } from 'lwc';

export default class SlDPTransposedRows extends LightningElement {
    @api fields = [];
    @api columnHeaders = [];
    @api tableCss;
    get hasFields(){return this.fields.length > 0;}
    
    handleKeyClick(event){
        event.preventDefault();
        this.dispatchEvent(new CustomEvent("gotokey", {detail: event.target.dataset.destination}));
    }
}