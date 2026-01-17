import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

const COLUMNS = [
    { label: "Select", fieldName: "selectButton", type: "button-icon", typeAttributes: 
        {alternativeText: "Choose Contact", iconName: "utility:check", variant: "brand", name: "selectContact"}},
    { label: "Full Name", fieldName: "Name"},
    { label: "Title", fieldName: "Title"  },
    { label: "Email", fieldName: "Email"  },
    { label: "Mobile", fieldName: "MobilePhone"  }
  ];

export default class SL_CADPRelatedContacts extends LightningElement {
    columns = COLUMNS;
    @api contacts;
    @api selectedContact = {};
    rows = [];

    connectedCallback(){
        let finalRows = [];
        if(this.contacts){
            this.contacts.forEach(contact => {
                // let row = JSON.parse(JSON.stringify(contact));
                // row.recordUrl = "/#";
                // finalRows.push(row);
                finalRows.push(contact);
            });
        }        
        this.rows = finalRows;
    }

    handleSelection(event){
        this.selectedContact = event.detail.row;
        console.log("this.selectedContact: ", JSON.stringify(this.selectedContact));
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}