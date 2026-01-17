import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";
import { showError } from 'c/sL_Common';
import requestByContractNumber from '@salesforce/apex/SL_SummaryAndDetail.requestByContractNumber';

export default class SL_CreateNewPolicy extends LightningElement {
    @api recordId;
    
    isLoading;
    insurType;
    effectiveDate;
    expireDate;
    cancelDate;
    carrier;
    insuranceTypes = [
        { label: 'Property', value: '01' },
        { label: 'Business Auto', value: '02' },
        { label: 'Extended Coverage', value: '09'},
        { label: 'Additional equipment', value: '10' },
    ];

    connectedCallback(){

    }

    handleCarrier(event){
        this.carrier = event.target.value;
    }
    handleInsurType(event){
        this.insurType = event.target.value;
    }
    handleEffectiveDate(event){
        this.effectiveDate = event.target.value;
    }
    handleExpireDate(event){
        this.expireDate = event.target.value;
    }
    handleCancelDate(event){
        this.cancelDate = event.target.value;
    }

    handleSubmit(event){
        let isValid = true;
        let fields = this.template.querySelectorAll('lightning-input');
        fields.forEach(field => {
            if(isValid){
                field.reportValidity();
                isValid = field.checkValidity();
            }
        });
        let combos = this.template.querySelectorAll('lightning-combobox');
        combos.forEach(field => {
            if(isValid){
                field.reportValidity();
                isValid = field.checkValidity();
            }
        });
        if(isValid) { 
            let validCancelDate = (this.cancelDate) ? this.formatDate(this.cancelDate) : '';
            console.log('validCancelDate ', validCancelDate);
            let additionalKeys = `, "InsurType": "${this.insurType}", 
                "EffectiveDate": "${this.formatDate(this.effectiveDate)}", 
                "ExpireDate": "${this.formatDate(this.expireDate)}", 
                "CancelDate": "${validCancelDate}", 
                "Carrier":"${this.carrier}"`; 
            this.isLoading = true;
            requestByContractNumber({recordId: this.recordId, nitroApiOption: "createInsurance", additionalKeys: additionalKeys})
            .then((result)=>{
                console.log("result: ", JSON.parse(JSON.stringify(result)));
                let obj = JSON.parse(result);
                let responseObj = obj.Response || obj.response.Response;
                    if(responseObj){
                        if(responseObj.Success.toLowerCase() == "true"){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: "Success",
                                    message: "The New Policy was created in InfoLease with no errors",
                                    variant: 'success'
                                })
                            );
                            this.goToCallingRecord();
                        } else {
                            showError(this, responseObj.Errors.join(','));
                        }
                    } else {
                        showError(this, JSON.stringify(obj), "Response came in unexpected format");
                    }
            })
            .catch((error)=>{
                showError(this, error);
            })
            .finally(()=>{ this.isLoading = false; });
        }else{
            showError(this, "Please enter the required information.");
        }
    }

    goToCallingRecord(){
        this.insurType = "";
        this.effectiveDate = "";
        this.expireDate = "";
        this.cancelDate = "";
        this.carrier = "";
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    formatDate(dateString){
        let [YYYY, MM, DD] = dateString.split("-");
        return `${MM}/${DD}/${YYYY}`;
    }

}