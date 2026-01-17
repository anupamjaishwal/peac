import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hubExecute from '@salesforce/apex/SL_DelayedEmail.hubExecute';
//import saveAttachment from '@salesforce/apex/SL_UploadAttachment.saveAttachment';

export default class SL_DelayedEmail extends LightningElement {
    @api recordId;
    isLoading;
    fromAddresses = [{ label: "--None--", value: "" }];
    contactId = "";
    fromAddress = "";
    toAddress = "";
    emailTemplates = new Map();
    purchaseOptions = [];
    preview = "";
    fileSelected = false;
    fileName = "";
    errorOccurred = false;
    fileContent;

    connectedCallback(){
        this.isLoading = true;
        hubExecute({methodName: 'getOWEmailAddresses', methodParameters: [this.recordId]})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj.oWEA && obj.emailTemplates){
                obj.oWEA.forEach((item)=>{
                    this.fromAddresses.push({label: item.DisplayName + " <" + item.Address + ">", value: item.Address});
                });
                obj.emailTemplates.forEach((item)=>{
                    this.purchaseOptions.push({label: item.Name, value: item.Id});
                    this.emailTemplates.set(item.Id, item);
                });
            } else {
                this.showError(JSON.stringify(obj), "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleFromAddress(event){
        this.fromAddress = event.target.value;
    }

    handleGetToAddress(event){
        this.contactId = event.target.value;
        if(this.contactId){
            this.isLoading = true;
            hubExecute({methodName: 'getToAddress', methodParameters: [this.contactId]})
            .then((result)=>{
                let obj = JSON.parse(result);
                if(obj.toAddress){
                    this.toAddress = obj.toAddress;
                } else {
                    this.showError(obj.error);
                }
            })
            .catch((error)=>{
                this.showError(error);
            })
            .finally(()=>{this.isLoading = false;});
        }
    }

    handleTemplate(event){
        this.selectedTemplate = event.target.value;
        let currentTemplate = this.emailTemplates.get(this.selectedTemplate);
        this.preview = currentTemplate? currentTemplate.HtmlValue: "";
    }

    handleFile(event){
        let uploadedFile = event.target.files[0];
        if(uploadedFile){
            this.fileName = uploadedFile.name;
            let fileReader = new FileReader();  
            fileReader.onloadend = (() => {  
                this.fileContent = fileReader.result;  
                let base64 = 'base64,';  
                let content = this.fileContent.indexOf(base64) + base64.length;  
                this.fileContent = this.fileContent.substring(content);
                this.fileSelected = true;
                this.errorOccurred = false;
            });  
            fileReader.readAsDataURL(uploadedFile);  
        }
    }

    handleCancel(){
        this.dispatchEvent(new CustomEvent("cancelsend", {detail: ""}));
    }
    handleSendEmail(){
        if(this.fileSelected && !this.errorOccurred && this.fromAddress && this.toAddress
            && this.contactId && this.selectedTemplate){
            this.isLoading = true;
            let methodParams = [
                this.fromAddress,
                this.toAddress,
                this.contactId,
                this.selectedTemplate,
                this.recordId,
                this.fileName,
                encodeURIComponent(this.fileContent)];
            hubExecute({methodName: 'scheduleDelivery', methodParameters: methodParams})
            .then((result)=>{
                if(result = "success"){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Your email has been successfully schedule to be sent.",
                            variant: 'success'
                        })
                    );
                    this.fromAddress = "";
                    this.contactId = "";
                    this.selectedTemplate = "";
                    this.preview = "";
                    this.toAddress = "";
                    this.fileName = "";
                    this.fileContent = "";
                    this.fileSelected = false;
                } else {
                    this.showError(result, "Response came in unexpected format");
                }
            })
            .catch((error)=>{
                this.showError(error);
            })
            .finally(()=>{this.isLoading = false;});
        }else{
            this.showError("Please make sure to select all the required values.");
        }
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