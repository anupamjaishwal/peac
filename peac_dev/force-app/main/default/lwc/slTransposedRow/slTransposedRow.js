import { LightningElement, api } from 'lwc';

export default class SlTransposedRow extends LightningElement {
    @api fields = [];
    get hasFields(){return this.fields.length > 0;}
    
    handleKeyClick(event){
        event.preventDefault();
        this.dispatchEvent(new CustomEvent("gotokey", {detail: event.target.dataset.destination}));
    }
}