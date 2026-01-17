import { LightningElement, api, track } from 'lwc';
import userGuide from '@salesforce/resourceUrl/AssetDataUploadTemplate'; // Static Resource import
import saveFile from '@salesforce/apex/PEAC_ImportCSVController.saveFile';
import loadingMessage from "@salesforce/label/c.PEAC_Loading";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import failedMessage from "@salesforce/label/c.PEAC_Import_Failed_Message"; 
import successMessage from "@salesforce/label/c.PEAC_Asset_Upload_Success_Message";

export default class PEAC_ImportAssets extends LightningElement {

    @api recordId;
    // Static resource URL
    staticResourceURL = userGuide;
    @api objectName = 'Asset__c';
    @api parentFieldName = 'Opportunity__c';
    isTrue = false;
    @track fileName = '';
    @api uploadtitle = 'Assets Upload';
    @track UploadFile = 'Upload';
    @track isTrue = false;
    showspinner = false;
    selectedRecords;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;
    label = {
        loadingMessage,successMessage
    };
    handleFilesChange(event) {

        if (event.target.files.length > 0) {

            this.filesUploaded = event.target.files;

            this.fileName = this.filesUploaded[0].name;
            this.isTrue = true;

        }
    }

    handleSave() {

        if (this.filesUploaded.length > 0) {

        this.uploadFile();

        } else {

    this.fileName = 'Please select a CSV file to upload!!';

    }

    }

    uploadFile() {

    if (this.filesUploaded[0].size > this.MAX_FILE_SIZE) {

    console.log('File Size is too large');

    return;

    }

    this.showspinner = true;

    this.fileReader = new FileReader();

    this.fileReader.onloadend = () => {

    this.fileContents = this.fileReader.result;

    this.saveFile();

    };

    this.fileReader.readAsText(this.filesUploaded[0]);

    }

    saveFile() {

    try {

    saveFile({ base64Data: JSON.stringify(this.fileContents), recId: this.recordId, objectName: this.objectName, parentFieldName: this.parentFieldName })

        .then(result => {
            this.isTrue = false;
            this.showspinner = false;
        if (result === '') {

        this.dispatchEvent(

        new ShowToastEvent({

        title: 'Warning',

        message: 'The CSV file does not contain any data',

        variant: 'warning',

        }),

    );

    }

    else {
        this.fileName = this.filesUploaded[0].name  +' '+ this.label.successMessage;

        this.showspinner = false;

        this.dispatchEvent(

        new ShowToastEvent({

        title: 'Success!!',

        message: this.filesUploaded[0].name + ' '+ this.label.successMessage,

        variant: 'success',

        }),

    );
    this.isTrue = false;
    }

    })

    .catch(error => {

        console.error(error);

        this.showspinner = false;

        this.dispatchEvent(

        new ShowToastEvent({

        title: 'Error while uploading File',

        message: error.body.message,

        variant: 'error',

        }),

    );

    });

    } catch (error) {

        console.error(error);

        this.showspinner = false;

        this.dispatchEvent(

        new ShowToastEvent({

        title: 'Error',

        message: 'An unexpected error occurred.',

        variant: 'error',

        }),

    );

    }

    }

    }