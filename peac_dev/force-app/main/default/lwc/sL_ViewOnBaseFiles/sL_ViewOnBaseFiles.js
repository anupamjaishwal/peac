import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retrieveDocuments from '@salesforce/apex/SL_OnBaseCallout.retrieveDocuments';
import CSMISCLabelName from '@salesforce/label/c.OnBaseFilesTextForAccountFromContract';


const ONBASE_FILES_HEADER_FEW = [
    { name: "DocType", label: "Document Type" },
    { name: "Name", label: "Name" },
    { name: "CreateDate", label: "Document Date" }
];
const ONBASE_FILES_HEADER = [
    { name: "DocType", label: "Document Type" },
    { name: "Name", label: "Name" },
    { name: "CreateDate", label: "Document Date" }
];
const ONBASE_FILES_A = ["Name"];

export default class SL_ViewOnBaseFiles extends LightningElement {
    @api recordId;

    label = {
        CSMISCLabelName,
    };

    currentMode = "start";
    get isStart() { return this.currentMode == "start"; }
    get isViewFew() { return this.currentMode == "few"; }
    get isViewAll() { return this.currentMode == "all"; }
    isLoadingFiles;
    get isLoading() { return this.isLoadingFiles; }

    @track header;
    fewColumns;
    allColumns;
    docUrls = {};
    @track onBaseFiles;

    get isContractRecord() {
        return this.recordId.startsWith('a1I');
    }

    handleCallOnBase() {
        this.fewColumns = [];
        this.allColumns = [];
        this.docUrls = {};
        this.onBaseFiles = [];
        this.makeSplitCall(true);
    }

    makeSplitCall(isFirstTime) {
        this.isLoadingFiles = true;
        retrieveDocuments({ recordId: this.recordId, isFS: !isFirstTime })
            .then((result) => {
                console.log("raw result: ", result);
                let modifiedString = result.replace(/\\\"/g, "\"");
                console.log("modifiedString after: ", modifiedString);
                let obj = JSON.parse(modifiedString);
                let temporaryFew = [...this.fewColumns];
                let temporaryAll = [...this.allColumns];
                if (obj.Documents) {
                    let actualIndex = temporaryFew.length ? temporaryFew.length : 0;
                    obj.Documents.forEach((doc) => {
                        let row = { showIt: true };
                        row["DocType"] = doc["DocType"];

                        row["Name"] = doc["Name"];
                        //row["CCAN #"] = this.findKeywordValue(doc, "CCAN #");
                        row["CreateDate"] = doc["CreateDate"];

                        if ((this.recordId.startsWith('001') && doc["DocType"] == 'CS - Misc') || !this.recordId.startsWith('001')) {
                            temporaryFew.push(row);
                            let extended = { ...row };
                            temporaryAll.push(extended);
                            this.docUrls[doc["Name"] + actualIndex] = doc["DocPopUrl"];
                            actualIndex++;
                        }


                        console.log('DOC: ', row["Name"]);
                        console.log('URL: ', doc["DocPopUrl"]);

                    });
                    this.fewColumns = temporaryFew;
                    this.allColumns = temporaryAll;
                } else {
                    if (obj.Error.Message)
                        this.showError(obj.Error.Message);
                    else
                        this.showError(JSON.stringify(obj));
                }
                if (isFirstTime && this.recordId && !this.recordId.startsWith('001')) {
                    this.makeSplitCall(false);
                } else {
                    this.currentMode = "few";
                    this.processRows("few", temporaryFew);
                }
            })
            .catch((error) => {
                this.showError(error);
            })
            .finally(() => {
                this.isLoadingFiles = false;
            });
    }

    findKeywordValue(doc, keywordName) {
        let keyword = doc.Keywords.find(keyword => keyword.Name == keywordName);
        return keyword ? keyword.CurrentValue : "";
    }

    handleOpenFile(event) {
        // console.log("docurl on event.detail: ", event.detail);
        // console.log("this.docUrls: ", JSON.parse(JSON.stringify(this.docUrls)));
        window.open(this.docUrls[event.detail], "_blank");
    }

    handleViewAll(event) {
        event.preventDefault();
        let temporary = [];
        temporary = this.allColumns;
        this.currentMode = "all";
        this.processRows("all", temporary);
    }
    handleViewFew(event) {
        event.preventDefault();
        let temporary = [];
        temporary = this.fewColumns;
        this.currentMode = "few";
        this.processRows("few", temporary);
    }

    processRows(whichTable, preliminary) {
        let finalRows = [];
        let linkZeldas = [], checkBoxes = [], recordKey = "", header = [];
        switch (whichTable) {
            case "few":
            case "all":
                linkZeldas = ONBASE_FILES_A;
                checkBoxes = [];
                recordKey = "Name";
                break;
        }
        preliminary.forEach((row, i) => {
            let fieldsArray = [];
            for (let key in row)
                if (key != "showIt") {
                    let isLink = linkZeldas.includes(key);
                    let isWaiver = row[key] == "waiver";
                    let isCheck = checkBoxes.includes(key);
                    fieldsArray.push({
                        key: key,
                        value: row[key],
                        isLink: isLink,
                        isWaiver: isWaiver,
                        isCheck: isCheck,
                        isChecked: row[key] == "1",
                        isPlain: !isLink && !isWaiver && !isCheck
                    });
                }

            finalRows.push({
                index: i, showIt: row.showIt, destination: row[recordKey] + i,
                fieldsArray: fieldsArray
            });
        });
        switch (whichTable) {
            case "few":
                header = ONBASE_FILES_HEADER.slice(0, 4);
                break;
            case "all":
                header = ONBASE_FILES_HEADER;
                break;
        }
        this.header = header;

        this.onBaseFiles = [...finalRows];
    }

    showError(error, customTitle) {
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