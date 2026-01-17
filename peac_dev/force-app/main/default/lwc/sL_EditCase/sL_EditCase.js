import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError } from 'c/sL_Common';

import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';

export default class SL_EditCase extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isNewCase = false;
    a_Record_URL;//added by raja
    
    @wire(CurrentPageReference)
    pageRef;

    @wire(getRecord, { recordId: '$recordId', fields: ["Case." + CASE_NUMBER_FIELD.fieldApiName] })
    case;
    
    isLoading = true;
    isSaveAndClose = false;
    isAlsoClosing = false;
    isSaving = false;
    dynamicHeight = 'height: auto;';
    get title(){ 
        let title = "";
        if(this.isNewCase){
            title = "New Case";
        }else{
            "Edit " + (this.case.data? this.case.data.fields[CASE_NUMBER_FIELD.fieldApiName].value: "");
        }
        return title;
    }
    get contractId(){
        let contractId = null;
        if(this.pageRef){
            contractId = this.pageRef.state.c__id;
        }
        return contractId;
    }

    connectedCallback(){
        this.a_Record_URL = window.location.origin;
        this.dynamicHeight = "height: " + (window.innerHeight - (this.isNewCase? 332: 232)) + "px";
    }

    handleLoad(){
        this.isLoading = false;
    }

    handleCancel(){
        this.handleButtonChange();//added by Raja
        if(this.isNewCase){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.contractId,
                    actionName: 'view'
                }
            });
        }else{
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    handleSaveAndClose(event){
        this.isSaving = true;
        this.isAlsoClosing = true;
        //added by Raja
        //this.handleButtonChange();
        
    }

    handleJustSave(event){
        this.isSaving = true;
        //added by Raja
        this.handleSuccess(event);

        this.handleButtonChange();
       // alert(this.contractId);
        /*this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.contractId,
                    actionName: 'view'
                }
            });*/
            let detailpageURL = this.a_Record_URL+'/lightning/r/Contract__c/'+this.contractId+'/view';
            console.log(this.a_Record_URL+'/lightning/r/Contract__c/'+this.contractId+'/view');
            window.open(detailpageURL,'_self');
        //eval("$A.get('e.force:refreshView').fire();");
        /*if(this.isNewCase){
            console.log('parentId ::'+this.contractId+'--'+this.isNewCase);
            
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.contractId,
                    actionName: 'view'
                }
            });
        }*/
        //end 
    }
    
    handleError(event){
        this.isSaving = false;
        showError(this, event);
    }

    handleSuccess(event){
        this.dispatchEvent(new ShowToastEvent({
            title: "Success",
            message: "The Case has been saved successfully.",
            variant: 'success'
        }));
        this.isSaving = false;
        if(this.isNewCase){
            this.recordId = event.detail.id;
        }
        if(this.isAlsoClosing){
            this.isSaveAndClose = true;
        }else{
            this.handleCancel();
        }
    }

//added by Raja
    handleButtonChange(){ 
        var close = true;
        const closeclickedevt = new CustomEvent('closeclicked', {
            detail: { close },
        });

         // Fire the custom event
         this.dispatchEvent(closeclickedevt); 
         
    }
    //end
}