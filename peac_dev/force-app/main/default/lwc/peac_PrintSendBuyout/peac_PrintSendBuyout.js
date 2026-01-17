import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/PEAC_PrintSendBuyoutController.sendEmail';
import getEmailTemplates from '@salesforce/apex/PEAC_PrintSendBuyoutController.getEmailTemplates';
export default class Peac_PrintSendBuyout extends LightningElement {
    @api recordId;
    @api detailColumn;
    @api selectedQuoteType;

    selectDetailPDF = false;
    selectSummaryPDF = false;
    selectCustomerPDF = false;
    emailList;
    emailFormatError = "Please enter a valid e-mail address";
    emailTemplates = [];
    emailTemplateId;

    @track quoteTypeList = [79, 80, 73, 72, 70];

    get showCustomerLetter() {
        return this.quoteTypeList.includes(parseInt(this.selectedQuoteType));
    }

    isLoading = false;

    connectedCallback() {
        console.log('selectedQuoteType::',this.selectedQuoteType);
        getEmailTemplates({
            recordId: this.recordId
        }).then(result => {
            if (result) {
                this.emailTemplates = result.map(emailTemplate => {
                    return {
                        ...emailTemplate,
                        label: emailTemplate.Name,
                        value: emailTemplate.Id
                    };
                });
                console.log('this.emailTemplates::', this.emailTemplates);
            }
        }).catch(error => {
            this.showToast('Error!', 'An error occured while fetching email templates', 'error');

        })
    }

    get enableSendButton() {
        return !(this.emailList && this.emailTemplateId);
    }

    get showEmailField() {
        return this.selectDetailPDF || this.selectSummaryPDF || this.selectCustomerPDF;
    }

    handleClosePopup() {
        const closeEvent = new CustomEvent('closepopup', {});
        this.dispatchEvent(closeEvent);
    }

    handlePdf() {
        let rows = [...this.detailColumn];
        let quoteSeq = this.detailColumn.find((ele) =>  ele.key == 'QuoteSeq')["destination"];
        console.log('quoteSeq::',quoteSeq);
        console.log('handlePdf::', JSON.stringify(rows));
        rows.splice(0, 1);
        window.open('/apex/SL_PrintBuyout?rows=' + encodeURIComponent(JSON.stringify(rows))
            + '&contractId=' + this.recordId + '&quoteSeq=' + quoteSeq, "_blank");
    }

    handleDetailedPdf() {
        let rows = [...this.detailColumn];
        let quoteSeq = this.detailColumn.find((ele) =>  ele.key == 'QuoteSeq')["destination"];
        console.log('quoteSeq::',quoteSeq);
        rows.splice(0, 1);
        console.log('handleDetailedPdf::', JSON.stringify(rows));
        window.open('/apex/SL_PrintDetailedBuyout?rows=' + encodeURIComponent(JSON.stringify(rows))
            + '&contractId=' + this.recordId + '&quoteSeq=' + quoteSeq, "_blank");
    }

    handleCustomerPdf() {
        let rows = [...this.detailColumn];
        let quoteSeq = this.detailColumn.find((ele) =>  ele.key == 'QuoteSeq')["destination"];
        console.log('quoteSeq::',quoteSeq);
        rows.splice(0, 1);
        console.log('handleDetailedPdf::', JSON.stringify(rows));
        window.open('/apex/PEAC_BPCustomerBuyoutLetter?recId=' + this.recordId + '&quoteSeq=' + quoteSeq + '&sourceName=Customer_Letter_SC&action=letter', "_blank");
    }

    handleDetailPDFSelect(event) {
        if (event.target.checked) {
            this.selectDetailPDF = true;
        } else {
            this.selectDetailPDF = false;
        }
    }

    handleSummaryPDFSelect(event) {
        if (event.target.checked) {
            this.selectSummaryPDF = true;
        } else {
            this.selectSummaryPDF = false;
        }
    }

    handleCustomerPDFSelect(event) {
        if (event.target.checked) {
            this.selectCustomerPDF = true;
        } else {
            this.selectCustomerPDF = false;
        }
    }

    handleEmail(event) {
        this.emailList = event.detail.value;
    }

    handleEmailTemplateChange(event) {
        this.emailTemplateId = event.target.value;
    }

    validateEmail() {

        let isValid = false;
        let field = this.refs.sendBuyoutEmail;

        if (field.checkValidity()) {
            field.reportValidity();
            isValid = true;
        }

        return isValid;
    }

    handleSendEmail() {

        this.isLoading = true;
        if (this.validateEmail()) {

            let pdfList = [];
            console.log('detail Column::', JSON.stringify(this.detailColumn));
            
        let quoteSeq = this.detailColumn.find((ele) =>  ele.key == 'QuoteSeq')["destination"];
            if (this.selectSummaryPDF) {
                let rows = [...this.detailColumn];
                rows.splice(0, 1);

                let requiredHeaders = ['Total Buyout', 'Expiration Date', 'Equipment Description'];
                rows = rows.filter(ele => requiredHeaders.includes(ele.label));
                rows = this.cleanFields(rows);
                let pdfAttributeList = [];
                let pdfAttribute = {};
                pdfAttribute['key'] = 'rows';
                pdfAttribute['value'] = JSON.stringify(rows);
                pdfAttributeList.push(pdfAttribute);

                let pdfAttribute1 = {};
                pdfAttribute1['key'] = 'contractId';
                pdfAttribute1['value'] = this.recordId;
                pdfAttributeList.push(pdfAttribute1);

                let pdfAttribute2 = {};
                pdfAttribute2['key'] = 'quoteSeq';
                pdfAttribute2['value'] = quoteSeq;
                pdfAttributeList.push(pdfAttribute2);


                let pdfWrap = {};
                pdfWrap['pdfName'] = "Summary Buyout.pdf";
                pdfWrap['apexVFPageName'] = "SL_PrintBuyout";
                pdfWrap['pdfAttributeList'] = pdfAttributeList;

                pdfList.push(pdfWrap);

            }
            if (this.selectDetailPDF) {
                let rows = [...this.detailColumn];
                rows.splice(0, 1);
                rows = this.cleanFields(rows);

                let pdfAttributeList = [];
                let pdfAttribute = {};
                pdfAttribute['key'] = 'rows';
                pdfAttribute['value'] = JSON.stringify(rows);
                pdfAttributeList.push(pdfAttribute);

                let pdfAttribute1 = {};
                pdfAttribute1['key'] = 'contractId';
                pdfAttribute1['value'] = this.recordId;
                pdfAttributeList.push(pdfAttribute1);

                let pdfAttribute2 = {};
                pdfAttribute2['key'] = 'quoteSeq';
                pdfAttribute2['value'] = quoteSeq;
                pdfAttributeList.push(pdfAttribute2);


                let pdfWrap = {};
                pdfWrap['pdfName'] = "Detailed Buyout.pdf";
                pdfWrap['apexVFPageName'] = "SL_PrintDetailedBuyout";
                pdfWrap['pdfAttributeList'] = pdfAttributeList;

                pdfList.push(pdfWrap);

            }
            if (this.selectCustomerPDF) {
                
                let pdfAttributeList = [];
                let pdfAttribute = {};
                pdfAttribute['key'] = 'sourceName';
                pdfAttribute['value'] = 'Customer_Letter_SC';
                pdfAttributeList.push(pdfAttribute);

                let pdfAttribute1 = {};
                pdfAttribute1['key'] = 'recId';
                pdfAttribute1['value'] = this.recordId;
                pdfAttributeList.push(pdfAttribute1);

                let pdfAttribute2 = {};
                pdfAttribute2['key'] = 'quoteSeq';
                pdfAttribute2['value'] = quoteSeq;
                pdfAttributeList.push(pdfAttribute2);

                let pdfAttribute3 = {};
                pdfAttribute3['key'] = 'action';
                pdfAttribute3['value'] = 'letter';
                pdfAttributeList.push(pdfAttribute3);


                let pdfWrap = {};
                pdfWrap['pdfName'] = "Customer.pdf";
                pdfWrap['apexVFPageName'] = "PEAC_BPCustomerBuyoutLetter";
                pdfWrap['pdfAttributeList'] = pdfAttributeList;

                pdfList.push(pdfWrap);

            }

            let emailWrap = {};
            emailWrap['emailList'] = this.emailList;
            emailWrap['recordId'] = this.recordId;
            emailWrap['emailTemplateId'] = this.emailTemplateId;
            emailWrap['pdfList'] = pdfList;

            sendEmail({
                emlWrap: emailWrap
            }).then(result => {
                console.log('Result::', result);
                console.log('email==', emailWrap);
            this.isLoading = false;
                if (result == 'Success') {
                    this.showToast('Done!', 'Email has sent successfully', 'success');
                    this.handleClosePopup();
                } else {
                    this.showToast('Error!', 'An error occured while sending email', 'error');
                }
            });
        } else {
            this.isLoading = false;
            this.showToast('Error!', this.emailFormatError, 'error');
        }


    }

    cleanFields(fieldsArray) {
        const keysToRemove = ['isCheck', 'isCherwell', 'isLink', 'isChecked'];
        return fieldsArray.map(field => {
            const cleanedField = { ...field };
            keysToRemove.forEach(key => delete cleanedField[key]);
            return cleanedField;
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}