import { LightningElement, api, track, wire } from 'lwc';
import generatedDocument from '@salesforce/apex/showAllDocuments.generatedDocuments';
import hubExecute from "@salesforce/apex/showContractDocuments.hubExecute";
import retrieveDocuments from '@salesforce/apex/SL_OnBaseCallout.retrieveDocuments';
import uId from "@salesforce/user/Id";

const COLUMNS = [
    { label: "File Name", fieldName: "recordUrl", type: "url", typeAttributes: { label: { fieldName: "Name" } } },
    { label: "Document Type", fieldName: "DocType" }
];


export default class PEAC_ShowAllDocuments extends LightningElement {
    @api recordId;
    @api docTypes;
    isModalOpen = false;
    viewAll = false;
    showViewAllLink = false;
    modalAllUpload = false;
    viewAllUploadsDocs = [];
    showUploadPopup = false;
    columns = COLUMNS;
    defaultRow = [];
    userId = uId;
    isLoading = false;

    documentTypes = ["LC - Migrated Contracts","AM - Return Authorization","LC - External"];

    showGeneratedDocu() {
        this.isModalOpen = true;
    }
    showAllUploadDocu() {
        this.modalAllUpload = true;
    }
    closeModal() {
        this.isModalOpen = false;
        this.showUploadPopup = false;
        this.modalAllUpload = false;
        this.showViewAllLink = true;
    }

    handleGoToAdd() {
        this.showUploadPopup = true;
    }

    connectedCallback() {
        this.showViewAllLink = false;
        if(this.docTypes){
            this.documentTypes = this.docTypes.split(',');
            this.documentTypes = this.documentTypes.map(docType => docType.trim());
        }
        this.handleRetreiveDocuments();
    }
    
    handleRetreiveDocuments() {
       // console.log('this.recordId::', this.recordId);
       // console.log('this.docTypes: ', this.docTypes);
        this.isLoading = true;
        retrieveDocuments({ recordId: this.recordId, isFS: false })
            .then((result) => {
                let modifiedString = result.replace(/\\\"/g, "\"");
               // console.log("raw result: ", result);
                let obj = JSON.parse(modifiedString);
               // console.log('obj::', obj);
               // console.log('obj::', JSON.stringify(obj));
                if (obj.Documents && obj.Documents.length > 0) {
                    let documents = [];
                    obj.Documents.forEach(doc => {
                        if (doc.DocType && this.documentTypes.includes(doc.DocType)) {
                            let document = {};
                            document["Name"] = doc.Name;
                            document["Id"] = doc.Id;
                            document["recordUrl"] = doc.DocPopUrl;
                            document["DocType"] = doc.DocType;
                            documents.push(document);
                        }
                    });
                    this.defaultRow = documents;
                    this.showViewAllLink = true;
                    this.isLoading = false;
                }
            })
            .catch((error) => {
                console.log('Error::', JSON.stringify(error));
                //  this.showError(error);
            })
            .finally(() => {
                    this.isLoading = false;
                // this.isLoadingFiles = false;
            });
    }

    processRows(rawData) {
        let processed = [];
        rawData.forEach(oppAttachment => {
            let newRow = JSON.parse(JSON.stringify(oppAttachment));
            newRow.recordUrl = "/dealers/s/detail/" + newRow.Id;
            processed.push(newRow);
        });
        return processed;
    }

}