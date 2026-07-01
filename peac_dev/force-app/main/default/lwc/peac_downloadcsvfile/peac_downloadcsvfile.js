/************************************************************************************************************************
 @Description: This is a generic js to generate csv file from salesforce objects
 @Author: Rajesh Kumar(LTIMindtree)
 @User Story: SAL-6229
 @Created Date: 02/23/2026
 ************************************************************************************************************************/

import { LightningElement,api,wire } from 'lwc';
import getRecords from '@salesforce/apex/PEAC_CSVFileDownloadController.getRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import downloadAssets from "@salesforce/label/c.PEAC_Download_Assets";
export default class Peac_downloadcsvfile extends LightningElement {
    @api objectsapiname = 'Asset__c';
    @api objectApiName;
    @api fieldlist = ['Id', 'Name'];
    @api parentfieldname = 'Opportunity__c';
    @api uploadtitle = 'Assets Download CSV';
    @api recordId;
    label = {downloadAssets};
        
    async handleDownload() {
        try {
            const data = await getRecords({ 
                objectName: this.objectsapiname, 
                fields: this.fieldlist,
                parentFieldName: this.parentfieldname,
                recordId: this.recordId
            });
            if (!data || data.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'No Data',
                        message: 'No records available to download.',
                        variant: 'info',
                    })
                );
                return;
            }

            // 1. Prepare Headers
            let csvString = this.fieldlist.join(',') + '\n';

            // 2. Prepare Rows
            data.forEach(record => {
                let row = this.fieldlist.map(fieldName => {
                    let value = record[fieldName]?record[fieldName] : '';
                    return `"${value}"`; // Wrap in quotes to handle commas in data
                }).join(',');
                csvString += row + '\n';
            });
            
            // Trigger download
            this.downloadCSV(csvString);

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error exporting data',
                    message: error,
                    variant: 'error',
                })
            );
        }
    }

    downloadCSV(csvContent) {
        const exportedFilename = 'Asset.csv';
        // Create a link element
        const link = document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvContent);
        link.target = '_blank';
        link.download = exportedFilename;
        
        // Append the link to the document body, click it, and remove it
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }
}