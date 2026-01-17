import { LightningElement, api,wire, track } from 'lwc';
import getAccount from '@salesforce/apex/tc_notificationCenterController.GetAccount';
import getContact from '@salesforce/apex/tc_notificationCenterController.GetContact';
import updateAccount from '@salesforce/apex/tc_notificationCenterController.updateAccountRec';
import updateContact from '@salesforce/apex/tc_notificationCenterController.UpdateContact';
import getFields from '@salesforce/apex/tc_notificationCenterController.getFields';
import updateRole from '@salesforce/apex/tc_notificationCenterController.updateRole';
import getRoleOptions from '@salesforce/apex/tc_notificationCenterController.getRoleOptions';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';


const columns = [
    { label: 'Contact Name', fieldName: 'ConName' },
    { label: 'Email', fieldName: 'ConEmail', type: 'Email' },
    { label: 'Role', fieldName: 'Role', type: 'Role' },
    { label: 'Equipment Finance', fieldName: 'ReceiveAllNotifications', type: 'boolean' }
];

export default class TC_notifyCenter extends LightningElement {
    @api recid;
    @api recordId;
    accId;
    @track accountRec = {};
    data = [];
    columns = columns;
    editRecId;
    roleId;
    openEditContact;
    roleoptions = [];
    roleValue;

   /* @wire(getAccount, {AccId: '$recid'})
    getAccounts({data, error}){
        console.log(this.recid,'  data:',JSON.stringify(data));
        if(data){
            
            this.accountRec = data;
            this.error = undefined;
        }
        else if (error) {
            this.error = error;
            this.accountRec = undefined;
        }
    }

    @wire(getContact, {AccId: '$recid'})
    getContacts({data, error}){
        console.log(this.recid,'  1data:',JSON.stringify(data));
        if(data){
            this.data = data;
            this.error = undefined;
        }
        else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }*/

    connectedCallback() {
        console.log('this.recordId:',this.recordId);
        this.accId = this.recordId;
        console.log(this.accId);
        getAccount({AccId: this.accId})
        .then(result => {
            this.accountRec = result;
            
            console.log(JSON.stringify(this.accountRec));
        })

        getContact({AccId: this.accId})
        .then(result => {
            this.data = result;
        
            console.log(JSON.stringify(result));
        })
        
        getFields({objectName: 'Contact'}).then(result=>{
            /*result.forEach(item => {
                
            });*/
            this.editfields = result;
            console.log('this.editfields',JSON.stringify(this.editfields));
        })
        getRoleOptions({objectName: 'AccountContactRelation', fieldName: 'Roles'}).then(result=>{
            this.roleoptions = [];
            result.forEach(item => {
                let opt = {
                    label: item,
                    value: item
                }
                this.roleoptions.push(opt);
            });
            console.log('this.editfields',JSON.stringify(result));
        })
    }

    changeToggle(event){
        const selectedRecordId = event.target.dataset.id;
        
        if(selectedRecordId == 'submit'){
            this.accountRec.Submitted__c = event.target.checked;
        } else if(selectedRecordId == 'moreinfo'){
            this.accountRec.More_Info__c = event.target.checked;
        } else if(selectedRecordId == 'approved'){
            this.accountRec.Approved__c = event.target.checked;
        } else if(selectedRecordId == 'declined'){
            this.accountRec.Declined__c = event.target.checked;
        } else if(selectedRecordId == 'docsout'){
            this.accountRec.Docs_Out__c = event.target.checked;
        } else if(selectedRecordId == 'docsoutcontr'){
            this.accountRec.Docs_Out_Contracts__c = event.target.checked;
        } else if(selectedRecordId == 'docsin'){
            this.accountRec.Docs_In__c = event.target.checked;
        } else if(selectedRecordId == 'funding'){
            this.accountRec.In_Funding__c = event.target.checked;
        } else if(selectedRecordId == 'finded'){
            this.accountRec.Funded__c = event.target.checked;
        } 
        console.log('selectedRecordId:',JSON.stringify(this.accountRec));
    }
    saveAccountrec(){
        console.log('selectedRecordId:',JSON.stringify(this.accountRec));
        /*updateAccount({acc: this.accountRec})
                .then(() => {
                    this.showToast('Success!!', 'Account updated successfully!!', 'success', 'dismissable');
                    // Display fresh data in the form
                    return refreshApex(this.accountRec);
                })
                .catch(error => {
                    console.log('error',error.body.message);
                    this.showToast('Error!!', error.body.message, 'error', 'dismissable');
                });

                updateContact({objACRW: this.data, objAcc: this.accountRec})
                .then(() => {
                    this.showToast('Success!!', 'Dealer updated successfully!!', 'success', 'dismissable');
                    // Display fresh data in the form
                    return refreshApex(this.accountRec);
                })
                .catch(error => {
                    console.log('error',error.body.message);
                    this.showToast('Error!!', error.body.message, 'error', 'dismissable');
                });*/
                console.log('save this.data:',this.data);
                updateContact({objACRW: JSON.stringify(this.data), objAcc: this.accountRec})
                    .then(() => {
                        this.showToast('Success!!', 'Dealer updated successfully!!', 'success', 'dismissable');
                        return refreshApex(this.accountRec);
                    })
                    .catch(error => {
                        console.log('error',error.body.message);
                        this.showToast('Error!!', error.body.message, 'error', 'dismissable');
                    });
                }  
    changeNotifyToggle(event){
        const selectedRecordId = event.target.dataset.id;
        this.data.forEach(ele => {
            if(selectedRecordId == ele.Id)
            ele.ReceiveAllNotifications = event.target.checked;
        });
    }
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
    handleEdit(event){
        this.editRecId = event.currentTarget.dataset.id;
        this.roleId = event.currentTarget.dataset.roleid;
        this.roleValue = event.currentTarget.dataset.role;
        console.log('this.editRecId:',this.roleValue);
        this.openEditContact = true;
    }
    handleClose(){
        this.openEditContact = false;
    }

    handleSubmit(event){
        /*event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Street = '32 Prince Street';
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        */
        console.log('this.roleValue:',this.roleValue, this.roleId);
        updateRole({role: this.roleValue, roleid: this.roleId})
        .then(result => {
            this.data.forEach(ele => {
                if(this.roleId == ele.Id)
                ele.Role = this.roleValue;
                
            })
            this.showToast('Success!!', 'Contact updated successfully!!', 'success', 'dismissable');
            console.log(JSON.stringify(result));
            
        }).catch(error =>{
            console.log('error:',JSON.stringify(error));
            this.showToast('Error!!', error.body.message, 'error', 'dismissable');
        })
    }
    handleChange(event){
        this.roleValue = event.detail.value;
    }
}