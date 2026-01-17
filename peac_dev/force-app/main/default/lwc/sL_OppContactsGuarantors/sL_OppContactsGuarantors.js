import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import hubExecute from '@salesforce/apex/SL_OppContactsGuarantors.hubExecute';
import { showError } from 'c/sL_Common';

const COLUMNS = [
    // { label: "Select", fieldName: "selectButton", type: "button", typeAttributes: 
    //     {label: "Select", alternativeText: "Choose Customer", variant: "brand", name: "selectAccount"}},
    { label: "First Name", fieldName: "FirstName"/*, initialWidth: "200"*/  },
    { label: "Last Name", fieldName: "LastName"/*, initialWidth: "200"*/  },
    { label: "Email", fieldName: "Email"/*, initialWidth: "200"*/  },
    { label: "Phone", fieldName: "Phone"/*, initialWidth: "200"*/  },
    { label: "Guarantor ", fieldName: "isGuarantor", type: "boolean"/*, initialWidth: "80"*/  },
    { label: "Home Address", fieldName: "formattedAddress", wrapText: true  },
    { type: 'action', typeAttributes: { rowActions: [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' },
        ] },
    }
];

export default class SL_OppContactsGuarantors extends LightningElement {
    @api theAccount = {};
    @api theContact = {};
    @api theOpportunity = {};
    @api theOppContactRole = {};// legacy, we don't use it anywhere else

    isLoading = false;
    isFormLoading = false;
    currentMode = "list";
    @api get isList(){ return this.currentMode == "list"; }
    get isDetail(){ return this.currentMode == "detail"; }
    columns = COLUMNS;
    rows = [];
    currentContact = {};
    contactId;
    isPG = false;
    get isNotPG(){ return !this.isPG; }
    get isPhoneRequired(){ return !this.theAccount.Business_Phone__c; }
    isAddressDifferent = false;
    isMailingDifferent = false;
    get addressVisible(){ return this.isAddressDifferent? "slds-visible": "slds-collapsed"}
    get mailingVisible(){ return this.isMailingDifferent? "slds-visible": "slds-collapsed"}
    get otherStreet() { return this.currentContact.OtherStreet; }
    get otherCity() { return this.currentContact.OtherCity; }
    get otherStateCode() { return this.currentContact.OtherStateCode; }
    get otherPostalCode() { return this.currentContact.OtherPostalCode; }
    get otherCountryCode() { return this.currentContact.OtherCountryCode; }
    get mailingStreet() { return this.currentContact.MailingStreet; }
    get mailingCity() { return this.currentContact.MailingCity; }
    get mailingStateCode() { return this.currentContact.MailingStateCode; }
    get mailingPostalCode() { return this.currentContact.MailingPostalCode; }
    get mailingCountryCode() { return this.currentContact.MailingCountryCode; }
    isOkToPullCredit = false;

    connectedCallback(){
        this.loadExisting();
    }

    loadExisting(){
        this.isLoading = true;
        hubExecute({ methodName: "getAllContacts", parameters: [this.theAccount.Id, this.theOpportunity.Id] })
        .then((result) => {
            console.log('result: ', JSON.parse(result));
            let obj = JSON.parse(result);
            if(obj && obj.allContacts){
                this.rows = obj.allContacts;
            }else{
                showError(this, "Error while retrieving Contacts, Response came in unexpected format.");
            }            
        })
        .catch((error) => {
            console.error("getAllContacts error: ", JSON.parse(JSON.stringify(error)));
            showError(this, error);
        })
        .finally(() => { this.isLoading = false; });
    }

    handleGoToDetail(){
        this.currentMode = "detail";
        this.isFormLoading = true;
    }

    handleGoToEdit(row){
        this.currentContact = row;// load data on inputs
        this.contactId = row.contactId;
        this.isPG = row.isGuarantor;
        this.isAddressDifferent = true;
        this.isMailingDifferent = true;
        this.isOkToPullCredit = row.isOkToPullCredit;
        this.handleGoToDetail();
    }

    handleGoToList(){
        this.currentMode = "list";
        this.currentContact = {};
        this.contactId = null;
        this.isPG = false;
        this.isAddressDifferent = false;
        this.isMailingDifferent = false;
        this.isOkToPullCredit = false;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'edit':
                this.handleGoToEdit(row);
                break;
            case 'delete':
                this.deleteContact(row);
                break;
            default:
        }
    }

    handleContactLoad(event){
        // console.log("onload event.detail: ", JSON.parse(JSON.stringify(event.detail)));
        this.isFormLoading = false;
    }

    handleIsPG(event){
        this.isPG = event.detail.checked;
        // console.log('Boolean(this.otherStateCode): ', Boolean(this.otherStateCode));
        if(!this.isAddressDifferent || !(this.isAddressDifferent && Boolean(this.otherStreet || this.otherCity || this.otherStateCode || this.otherPostalCode))){
            this.isAddressDifferent = this.isPG;
        }
        // this.reRender();
    }

    handleFirstName(event){
        this.currentContact.FirstName = event.target.value;
    }
    handleLastName(event){
        this.currentContact.LastName = event.target.value;
    }
    handleSsn(event){
        this.currentContact.SSN__c = event.target.value;
    }
    handleEmail(event){
        this.currentContact.Email = event.target.value;
    }
    handleTitle(event){
        this.currentContact.Title = event.target.value;
    }
    handlePhone(event){
        this.currentContact.Phone = event.target.value;
    }
    handleAddress(event){
        // console.log('event.detail: ', JSON.parse(JSON.stringify(event.detail)));
        this.currentContact.OtherStreet = event.detail.street;
        this.currentContact.OtherCity = event.detail.city;
        this.currentContact.OtherStateCode = event.detail.province;
        this.currentContact.OtherPostalCode = event.detail.postalCode;
        this.currentContact.OtherCountryCode = event.detail.country;
        // this.currentContact.OtherAddress.street = event.detail.street; // this doesn't work
        // this.currentContact.OtherAddress.city = event.detail.city;
        // this.currentContact.OtherAddress.stateCode = event.detail.province;
        // this.currentContact.OtherAddress.postalCode = event.detail.postalCode;
        // this.currentContact.OtherAddress.countryCode = event.detail.country;
    }
    handleMailingAddress(event){
        this.currentContact.MailingStreet = event.detail.street;
        this.currentContact.MailingCity = event.detail.city;
        this.currentContact.MailingStateCode = event.detail.province;
        this.currentContact.MailingPostalCode = event.detail.postalCode;
        this.currentContact.MailingCountryCode = event.detail.country;
        // this.currentContact.MailingAddress.street = event.detail.street; // this doesn't work
        // this.currentContact.MailingAddress.city = event.detail.city;
        // this.currentContact.MailingAddress.stateCode = event.detail.province;
        // this.currentContact.MailingAddress.postalCode = event.detail.postalCode;
        // this.currentContact.MailingAddress.countryCode = event.detail.country;
    }

    handleDifferent(event){
        this.isAddressDifferent = event.detail.checked;
        // this.reRender();
    }

    handleMailingDifferent(event){
        this.isMailingDifferent = event.detail.checked;
    }

    handleIsOkToPullCredit(event){
        this.isOkToPullCredit = event.detail.checked;
    }

    validateAllowedPGs(){
        let savingAllowed = true;
        if(this.isPG){
            let totalPGs = 1;
            this.rows.forEach(contact =>{
                if(contact.isGuarantor && contact.contactId != this.contactId){
                    totalPGs++;
                }
            })
            if(totalPGs > 2){
                showError(this, "Up to 2 PGs are allowed.");
                savingAllowed = false;
            }
        }
        return savingAllowed;
    }

    handleSubmit(event){
        event.preventDefault();
        let isValid = true;
        let field = this.refs.isOkToPullCredit;
        if (field && !field.checkValidity()) {
            field.reportValidity();
            isValid = false;
        }
        if(isValid){
            isValid = isValid && this.validateAllowedPGs();
        }
        if(isValid){
            const fields = event.detail.fields;
            this.theContact = { ...this.theContact, ...fields };
            if(!this.isAddressDifferent){
                this.theContact.OtherStreet = this.theAccount.Business_Address__c;
                this.theContact.OtherCity = this.theAccount.Business_City__c;
                this.theContact.OtherStateCode = this.theAccount.Business_State__c;
                this.theContact.OtherPostalCode = this.theAccount.Business_Zip__c;
                this.theContact.OtherCountryCode = this.theAccount.Business_Country__c || "US";
            }
            if(!this.isMailingDifferent){
                this.theContact.MailingStreet = this.theContact.OtherStreet;
                this.theContact.MailingCity = this.theContact.OtherCity;
                this.theContact.MailingStateCode = this.theContact.OtherStateCode;
                this.theContact.MailingPostalCode = this.theContact.OtherPostalCode;
                this.theContact.MailingCountryCode = this.theContact.OtherCountryCode;
            }
            if(this.isPG){
                this.theContact.SSNMain__c = fields.SSN__c;
            }else{
                this.theContact.SSN__c = null;
                this.theContact.SSNMain__c = null;
            }
            this.theContact.OK_to_Pull_Credit__c = this.isPG && this.isOkToPullCredit;
            let usedAccountPhone = false;
            if(!this.theContact.Phone){
                this.theContact.Phone = this.theAccount.Business_Phone__c;
                usedAccountPhone = true;
            }
            this.theContact.Id = this.contactId;
            let sentParams = [JSON.stringify(this.theContact), this.theOpportunity.Id, this.isPG, this.isAddressDifferent, this.isMailingDifferent, usedAccountPhone];
            this.isFormLoading = true;
            hubExecute({ methodName: "saveOppContact", parameters: sentParams })
            .then((result) => {
                if(result){
                    this.isLoading = true
                    this.handleGoToList();
                    this.loadExisting();
                }else{
                    this.handleError("Error while saving Contact, please contact your administrator.");
                }
            })
            .catch((error) => {
                console.error("saveOppContact error: ", JSON.parse(JSON.stringify(error)));
                this.handleError(error);
            })
            .finally(() => { this.isFormLoading = false; })
        }
        
    }

    deleteContact(row){
        let sentParams = [row.contactId, this.theOpportunity.Id, row.isGuarantor];
        console.log("sentParams: ", sentParams);
        this.isLoading = true
        hubExecute({ methodName: "deleteOppContact", parameters: sentParams })
        .then((result) => {
            if(result){
                this.handleGoToList();
                this.loadExisting();
            }else{
                this.handleError("Error while deleting Contact, please contact your administrator.");
            }
        })
        .catch((error) => {
            console.error("deleteOppContact error: ", JSON.parse(JSON.stringify(error)));
            this.handleError(error);
        })
    }

    handleGoBack(event){
        this.dispatchEvent(new FlowNavigationBackEvent());
    }
    handleGoNext(event){
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    handleError(message){
        showError(this, message);
        this.isLoading = false;
    }

    // reRender(){
    //     setTimeout(()=>{ 
    //         this.isLoading = true;
    //         setTimeout(()=>{ this.isLoading = false; }, 0);
    //     }, 0);
    // }
}