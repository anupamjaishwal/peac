import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContractAssets from '@salesforce/apex/SL_DealerRepurchaseController.getContractAssets';
import generateInvoice from '@salesforce/apex/SL_DealerRepurchaseController.generateInvoice';
import generateInvoiceDocument from '@salesforce/apex/SL_DealerRepurchaseController.generateInvoiceDocument';
import updateContractAssets from '@salesforce/apex/SL_DealerRepurchaseController.updateContractAssets';


import { CloseActionScreenEvent } from 'lightning/actions';
import UnitPrice from '@salesforce/schema/PricebookEntry.UnitPrice';


const columns = [
    { label: 'Asset Number', fieldName: 'Asset_Number__c', editable: false  },
    { label: 'Unit Price', fieldName: 'UnitPrice', editable: true, type: 'number' },
    { label: 'Serial Number', fieldName: 'Serial_Number__c', editable: false  }, // Already added Serial Number
    { label: 'Model Number', fieldName: 'Model_Number__c', editable: false },    // New Column for Model Number
    { label: 'Status', fieldName: 'Status2__c', editable: false }              // New Column for Status
];

const invoiceAssetsTableColumns = [
    { label: 'Serial', fieldName: 'Serial', editable:false  },
    { label: 'Manufacturer', fieldName: 'Manufacturer', editable:false  },
    { label: 'Model', fieldName: 'Model', editable:false  },
    { label: 'Unit Price', fieldName: 'UnitPrice', editable:false  }
];


export default class SL_RepurchaseInvoice extends LightningElement {
    @track contractAssets = [];
    @track invoiceAssetsData = [];
    @track columns = columns;
    @track invoiceAssetsTableColumns = invoiceAssetsTableColumns;

    @track contractAssetScreen = true;
    @track invoiceDetailsScreen = false;
    @track draftValues = [];
    @track invoiceID;
    @track invoiceObject;
    @track generateInvoiceDocumentDisabled = false;
    documentGenerated = false;
    _recordId;

    
    @api set recordId(value) {
        this._recordId = value;
        console.log('recordId: ', this._recordId);
        this.fetchContractAsset();
    }

    get recordId() {
        return this._recordId;
    }

    fetchContractAsset() {
        console.log('fetchContractAsset');
        getContractAssets({
            contractId: this.recordId
        }).then(response => {
            console.log('RESPONSE ', response);
            if (response && response.length > 0) {
                this.contractAssets = response;
                this.contractAssets.forEach(contractAsset => {
                    contractAsset.UnitPrice = contractAsset.Invoice_Amount__c;
                });
            } else {
                //this.message = 'There is no contract assets available.';
                this.showToast('Error!','There is no contract assets available.','error', 'dismissible' );
            }
        }).catch(error => {
        });
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant : variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    handleClose() {
        // Custom code to run when the panel is closed
        console.log('Quick Action Panel is closed');
        
        // Add any other functionality you need here
    } 
    
    closeQuickAction() {
        if(!this.documentGenerated)
        {
            console.log('closeQuickAction  ', this.invoiceID );
        }
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    onSaveAction(event) {
        const updatedRecords = event.detail.draftValues;
        let totalInvoiceAmount = 0;
        let recordsToUpdate = [];
    
    
        // Loop through the array and set the Invoice_Amount__c, sum the Invoice_Amount__c in the total
        updatedRecords.forEach((updatedRecord) => {
            this.contractAssets.forEach((contractAsset) => {
                if (contractAsset.Id === updatedRecord.Id) {
                    contractAsset.UnitPrice = updatedRecord.UnitPrice;
                    contractAsset.Invoice_Amount__c = parseFloat(updatedRecord.UnitPrice);
                    totalInvoiceAmount += parseFloat(updatedRecord.UnitPrice);
                
                    recordsToUpdate.push({
                        Id: contractAsset.Id,
                        Invoice_Amount__c: contractAsset.Invoice_Amount__c,
                    });
                }
            });
        });
    
        console.log('Updated Records:', updatedRecords);
        console.log('Records to Update:', recordsToUpdate);
        console.log('Total Invoice Amount:', totalInvoiceAmount);
    
        // Loop again through the array and set the Total_Invoice_Amount__c
        recordsToUpdate.forEach((contractAsset) => {
            contractAsset.Total_Invoice_Amount__c = totalInvoiceAmount;
        });
    
        console.log('Records to Update with Total Invoice Amount:', recordsToUpdate);
    
        // Call Apex method to update the records
        updateContractAssets({ contractAssets: recordsToUpdate })
            .then(() => {
                this.showToast('Success', 'Contract Assets updated successfully', 'success', 'dismissible' );
                console.log('Records updated successfully');
            })
            .catch(error => {
                this.showToast('Error', 'Error updating records: ' + error.body.message, 'error', 'dismissible' );
                console.error('Error updating records:', error);
            });
    
        this.draftValues = [];
    }

    saveInvoiceAssetsAction() {
        let emptyAmount = 0;
        var selectedRecords =  this.template.querySelector('[data-id="assetsTable"]').getSelectedRows();
        let assets = [];
        //Validate selected records
        if(selectedRecords.length > 0){
            console.log('selectedRecords are ', JSON.stringify(selectedRecords));
   
            
            selectedRecords.forEach(currentItem => {


                if(!currentItem.UnitPrice){
                    emptyAmount++;
                }
                else{
                    let asset = {
                        Id: currentItem.Id,
                        UnitPrice: currentItem.UnitPrice
                    };
                    assets.push(asset);
                }
            });

            if(emptyAmount>0){
                this.showToast('Error!','Please enter an amount for all included assets.','error', 'dismissible' );
            }
            else{
                //Create invoice and invoice assets records
                console.log('Assets ', JSON.stringify(assets));                   
                let jsonString = JSON.stringify(assets);
                generateInvoice({
                    contractId: this.recordId,
                    invoiceAssetsJSON: jsonString
                }).then(response => {
                    this.contractAssetScreen=false;
                    this.invoiceDetailsScreen = true;                    
                    this.invoiceObject = JSON.parse(response);
                    this.invoiceID = this.invoiceObject.Id;                    
                    let invoiceAssets = this.invoiceObject.InvoiceAssets;
                    invoiceAssets[0].Model
                    this.invoiceAssetsData = invoiceAssets;

                }).catch(error => {
                });

            }   
        }
        else{
            this.showToast('Error!','No assets have been selected to create the invoice.','error', 'dismissible' );
        }
    }


    validateEmails(emailString) {

        if(emailString.length>0){
            const emailPattern = /^[a-zA-Z0-9@.,\-_ ]+$/;
            if (!emailPattern.test(emailString)) {
                return { isValid: false, message: "Invalid characters detected in Additional email addresses field." };
            }
            
            const emails = emailString.split(',').map(email => email.trim());
            const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        
            for (let email of emails) {
                if (!emailRegex.test(email)) {
                    return { isValid: false, message: `Invalid email format detected: ${email}` };
                }
            }
        
            return { isValid: true, message: "Valid email addresses." };
        }
        else{
            return { isValid: true, message: "Valid email addresses." };
        }

    }

    generateInvoiceDocument(event) {
        this.generateInvoiceDocumentDisabled = true;
        let checkboxACH = this.template.querySelector('[data-id="checkboxACH"]').checked;
        let emailList = this.template.querySelector('[data-id="emails"]').value;


        const validation = this.validateEmails(emailList);

        if (!validation.isValid) {            
            this.showToast('Error!', validation.message ,'error', 'dismissible' );
            this.generateInvoiceDocumentDisabled = false;

        } else {

            generateInvoiceDocument({
                invoiceId: '',
                emails: emailList,
                ACH: checkboxACH,
                invoiceJSON: JSON.stringify(this.invoiceObject),
                assetsJSON: JSON.stringify(this.invoiceAssetsData)
            }).then(response => {
    
                console.log('created record ' + response);
                
                this.showToast('Success!','Repurchase invoice '+ response + ' was succesfully created.','success', 'sticky');
    
                this.showToast('Success!','Invoice was succesfully sent.','success', 'dismissible' );
    
                setTimeout(() => {
                    this.closeQuickAction();
                  }, 0);
                
            }).catch(error => {
                console.log('Error ',error);
                this.generateInvoiceDocumentDisabled = false;
            });
        }



    }


}