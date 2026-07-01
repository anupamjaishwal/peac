/**
 * @description LWC component for CSV asset import with discrepant assets resolution
 * Developed by Suraj Harichandan (LTIMindtree) for SAL-6285 Project Expo - RF: Asset Selection Screen for Multi-County Listings
 * @author Rajesh Kumar (LTIMindtree) - Original implementation (SAL-5080)
 * @author Suraj Harichandan (LTIMindtree) - Discrepant assets UI with SLDS Tab Set (SAL-6285)
 * @date December 19, 2025
 */
import { LightningElement, api, track, wire } from 'lwc';
import userGuide from '@salesforce/resourceUrl/AssetDataUploadTemplate';
import getFieldDataTypes from '@salesforce/apex/PEAC_ImportCSVController.getFieldDataTypes';
import getPicklistLabelAPIs from '@salesforce/apex/PEAC_ImportCSVController.getPicklistLabelAPIs';
import saveFile from '@salesforce/apex/PEAC_ImportCSVController.saveFile';
import getDiscrepantAssets from '@salesforce/apex/PEAC_ImportCSVController.getDiscrepantAssets';
import getDiscrepantAssetCount from '@salesforce/apex/PEAC_ImportCSVController.getDiscrepantAssetCount';
import getTaxJurisdictionsForZip from '@salesforce/apex/PEAC_ImportCSVController.getTaxJurisdictionsForZip';
import saveAssetJurisdiction from '@salesforce/apex/PEAC_ImportCSVController.saveAssetJurisdiction';
import loadingMessage from "@salesforce/label/c.PEAC_Loading";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import failedMessage from "@salesforce/label/c.PEAC_Import_Failed_Message"; 
import successMessage from "@salesforce/label/c.PEAC_Asset_Upload_Success_Message";
import maxCount from "@salesforce/label/c.PEAC_AssetUploadMaxCount";
import infoMsg from "@salesforce/label/c.PEAC_AssetUploadMsg";

const PAGE_SIZE = 20;

export default class PEAC_ImportAssets extends LightningElement {

    @api recordId;
    staticResourceURL = userGuide;
    @api objectName = 'Asset__c';
    @api parentFieldName = 'Opportunity__c';
    @api uploadtitle = 'Assets Upload';
    
    // File upload state
    @track fileName = '';
    @track UploadFile = 'Upload';
    @track isTrue = false;
    showspinner = false;
    filesUploaded = [];
    fieldsAPINames = [];
    fieldsDataTypes;
    picklistFieldsValueMap;
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;
    
    // SAL-6285: Discrepant assets state
    @track showDiscrepantView = false;
    @track uploadCompleted = false;
    @track discrepantAssets = [];
    @track currentPage = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track isLoadingDiscrepant = false;
    @track jurisdictionOptionsMap = {}; // Map of assetId -> options[]
    @track selectedJurisdictions = {}; // Map of assetId -> selected value
    @api fieldlist;

    label = {loadingMessage, successMessage, maxCount, infoMsg};
    
    // SAL-6285: Datatable columns for discrepant assets
    get discrepantColumns() {
        return [
            { label: 'Asset Name', fieldName: 'Name', type: 'text' },
            { label: 'Serial Number', fieldName: 'Serial_Number__c', type: 'text' },
            { label: 'Description', fieldName: 'Description__c', type: 'text', wrapText: true },
            { label: 'Model', fieldName: 'Model__c', type: 'text' },
            { label: 'Equipment Zip', fieldName: 'Equipment_Zip__c', type: 'text' },
            { label: 'Street', fieldName: 'Equipment_Street__c', type: 'text' },
            { label: 'City', fieldName: 'Equipment_City__c', type: 'text' },
            { label: 'State', fieldName: 'Equipment_State__c', type: 'text' },
            { label: 'List Price', fieldName: 'List_Price__c', type: 'currency' },
            { label: 'Quantity', fieldName: 'Quantity__c', type: 'number' }
        ];
    }
    
    // SAL-6285: Pagination computed properties
    get isPreviousDisabled() {
        return this.currentPage <= 1;
    }
    
    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }
    
    get paginationInfo() {
        return `Page ${this.currentPage} of ${this.totalPages} (${this.totalRecords} total)`;
    }
    
    get hasDiscrepantAssets() {
        return this.discrepantAssets && this.discrepantAssets.length > 0;
    }
    
    get showViewDiscrepantButton() {
        return this.uploadCompleted;
    }
    
    // SAL-6285: Computed properties for button variant and title
    get discrepantButtonVariant() {
        return 'brand-outline'; // Always active - users can view anytime
    }
    
    get discrepantButtonTitle() {
        return 'View assets requiring jurisdiction selection';
    }
    
    @wire(getFieldDataTypes) getFieldDataTypes({ error, data }) {
        if (data) {
            this.fieldsDataTypes = new Map(Object.entries(JSON.parse(data)));
            console.log('fieldsDataTypes ==> ' , this.fieldsDataTypes);
            this.fieldsAPINames = [...this.fieldsDataTypes.keys()];
            this.fieldlist = ['Id',...this.fieldsDataTypes.keys()];
            this.getPicklistLabelAPIs();
        } else if (error) {
            console.error(error);
        }
    }

    getPicklistLabelAPIs() {
        getPicklistLabelAPIs({ strObjectName: this.objectName, fieldAPIList: this.fieldsAPINames})
            .then(result => {
                this.picklistFieldsValueMap = new Map(Object.entries(JSON.parse(result)));
            })
            .catch(error => {
                console.error(error);
            });
    }

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
            const rows = this.fileContents.split('\n').map(row => row.split(','));
            const serNumIndex = rows[0].indexOf("Serial_Number__c");
            console.log('header indexsn ==> ' , serNumIndex);
            if(rows.length-2 > this.label.maxCount) {
                this.showToastMsg('Assets Count Error!', 'Uploads are restricted to a maximum of '+this.label.maxCount+' assets.', 'error');
                this.showspinner = false;
                return;
            }
            // Data rows (exclude header). Filter out completely empty rows.
            const dataRows = rows.slice(1).filter(r => Array.isArray(r) && r.some(cell => String(cell).trim() !== ''));
            // Compute duplicates for the SerialNumber column with 2 index
            this.dupSerNumsList = this.computeDuplicates(dataRows, serNumIndex);
            if (this.dupSerNumsList.length) {
                this.showToastMsg('Duplicate assets were detected in the uploaded sheet!', 'Duplicates - '+this.dupSerNumsList, 'error');
                this.showspinner = false;
                return;
            }
            this.saveFile();
        };
        this.fileReader.readAsText(this.filesUploaded[0]);
    }

    saveFile() {
        try {
            let fieldsDataTypesApex = {};
            let picklistFieldsValueMapApex = {};
            this.fieldsDataTypes.forEach((value, key) => {
                fieldsDataTypesApex[key] = value;
            });
            this.picklistFieldsValueMap.forEach((value, key) => {
                picklistFieldsValueMapApex[key] = value;
            });
            saveFile({ base64Data: JSON.stringify(this.fileContents), oppId: this.recordId, fieldsDataTypes: fieldsDataTypesApex, picklistFieldsValueMap: picklistFieldsValueMapApex})
                .then(result => {
                    this.isTrue = false;
                    this.showspinner = false;
                if (result === '') {
                    this.showToastMsg('Warning', 'The CSV file does not contain any data', 'warning');
                }
                else {
                    this.fileName = this.filesUploaded[0].name  +' '+ this.label.successMessage;
                    this.showspinner = false;
                    this.showToastMsg('Success..!!', this.filesUploaded[0].name + ' '+ this.label.successMessage, 'success');
                    this.isTrue = false;
                    // SAL-6285: Mark upload as completed to enable discrepant assets button
                    this.uploadCompleted = true;
                }
            })
            .catch(error => {
                console.error(error);
                this.showspinner = false;
                this.showToastMsg('Error while uploading File', error.body.message, 'error');
            });
        } catch (error) {
            console.error(error);
            this.showspinner = false;
            this.showToastMsg('Error', 'An unexpected error occurred.', 'error');
        }
    }

    computeDuplicates(dataRows, nameIdx) {
        const counts = new Map();
        const displayName = new Map(); // keep first-seen casing for display

        for (const row of dataRows) {
            const raw = row?.[nameIdx] ?? '';
            const trimmed = String(raw).trim();

            if (!trimmed) continue;

            const key = trimmed.toLowerCase(); // normalize for duplicates
            if (!displayName.has(key)) displayName.set(key, trimmed);

            counts.set(key, (counts.get(key) || 0) + 1);
        }
        // Build list only where count > 1
        const dupes = [];
        for (const [key, count] of counts.entries()) {
            if (count > 1) {
                dupes.push(displayName.get(key));
                //dupes.push({name: displayName.get(key), count});//Push the Serial Number with No. of duplicates
            }
        }
        // Sort: highest count first, then alphabetically
        //dupes.sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
        return dupes;
    }

    // SAL-6285: Handle Multi-County Assets tab activation - Suraj Harichandan (LTIMindtree)
    handleMultiCountyTabActive() {
        // Load discrepant assets when tab becomes active
        this.currentPage = 1;
        this.loadDiscrepantAssets();
    }
    
    // SAL-6285: Legacy method kept for backward compatibility
    handleViewDiscrepantAssets() {
        this.currentPage = 1;
        this.loadDiscrepantAssets();
    }
    
    // SAL-6285: Load discrepant assets with pagination
    async loadDiscrepantAssets() {
        this.isLoadingDiscrepant = true;
        try {
            // Get total count
            this.totalRecords = await getDiscrepantAssetCount({ oppId: this.recordId });
            this.totalPages = Math.ceil(this.totalRecords / PAGE_SIZE);
            
            if (this.totalRecords === 0) {
                this.discrepantAssets = [];
                this.showToastMsg('Info', 'No discrepant assets found. All assets have been resolved.', 'info');
                this.isLoadingDiscrepant = false;
                return;
            }
            
            // Get paginated assets
            const assets = await getDiscrepantAssets({ 
                oppId: this.recordId, 
                pageNumber: this.currentPage, 
                pageSize: PAGE_SIZE 
            });
            
            // Add UI properties for each asset
            // SAL-6285: Added recordUrl for Asset Name hyperlink - Suraj Harichandan (LTIMindtree) - January 29, 2026
            this.discrepantAssets = assets.map(asset => ({
                ...asset,
                recordUrl: `/lightning/r/Asset__c/${asset.Id}/view`,
                jurisdictionOptions: [],
                selectedJurisdiction: null,
                isLoadingOptions: false,
                isSaving: false,
                placeholderText: 'Select Jurisdiction',
                saveButtonLabel: 'Save'
            }));
            
        } catch (error) {
            console.error('Error loading discrepant assets:', error);
            this.showToastMsg('Error', 'Error loading discrepant assets: ' + error.body?.message, 'error');
        }
        this.isLoadingDiscrepant = false;
    }
    
    // SAL-6285: Handle dropdown focus to load jurisdictions
    async handleJurisdictionFocus(event) {
        const assetId = event.target.dataset.assetId;
        const zipCode = event.target.dataset.zipCode;
        
        // Find asset in list
        const assetIndex = this.discrepantAssets.findIndex(a => a.Id === assetId);
        if (assetIndex === -1) return;
        
        // If already loaded, skip
        if (this.discrepantAssets[assetIndex].jurisdictionOptions.length > 0) return;
        
        // Set loading state
        this.discrepantAssets = this.discrepantAssets.map(asset => 
            asset.Id === assetId ? { ...asset, isLoadingOptions: true, placeholderText: 'Loading...' } : asset
        );
        
        try {
            const options = await getTaxJurisdictionsForZip({ zipCode: zipCode });
            this.discrepantAssets = this.discrepantAssets.map(asset => 
                asset.Id === assetId ? { 
                    ...asset, 
                    jurisdictionOptions: options,
                    isLoadingOptions: false,
                    placeholderText: 'Select Jurisdiction'
                } : asset
            );
        } catch (error) {
            console.error('Error loading jurisdictions:', error);
            this.showToastMsg('Error', 'Error loading tax jurisdictions: ' + error.body?.message, 'error');
            this.discrepantAssets = this.discrepantAssets.map(asset => 
                asset.Id === assetId ? { ...asset, isLoadingOptions: false, placeholderText: 'Select Jurisdiction' } : asset
            );
        }
    }
    
    // SAL-6285: Handle jurisdiction selection change
    handleJurisdictionChange(event) {
        const assetId = event.target.dataset.assetId;
        const selectedValue = event.detail.value;
        
        this.discrepantAssets = this.discrepantAssets.map(asset => 
            asset.Id === assetId ? { ...asset, selectedJurisdiction: selectedValue } : asset
        );
    }
    
    // SAL-6285: Save selected jurisdiction for an asset
    async handleSaveJurisdiction(event) {
        const assetId = event.target.dataset.assetId;
        const asset = this.discrepantAssets.find(a => a.Id === assetId);
        
        if (!asset || !asset.selectedJurisdiction) {
            this.showToastMsg('Warning', 'Please select a jurisdiction first.', 'warning');
            return;
        }
        
        // Set saving state
        this.discrepantAssets = this.discrepantAssets.map(a => 
            a.Id === assetId ? { ...a, isSaving: true, saveButtonLabel: 'Saving...' } : a
        );
        
        try {
            await saveAssetJurisdiction({ 
                assetId: assetId, 
                taxJurisdictionJson: asset.selectedJurisdiction 
            });
            
            this.showToastMsg('Success', 'Jurisdiction saved successfully.', 'success');
            
            // Remove the asset from the list immediately
            this.discrepantAssets = this.discrepantAssets.filter(a => a.Id !== assetId);
            this.totalRecords--;
            this.totalPages = Math.ceil(this.totalRecords / PAGE_SIZE);
            
            // If current page is now empty and not the first page, go to previous page
            if (this.discrepantAssets.length === 0 && this.currentPage > 1) {
                this.currentPage--;
                this.loadDiscrepantAssets();
            } else if (this.discrepantAssets.length === 0 && this.totalRecords === 0) {
                this.showToastMsg('Success', 'All discrepant assets have been resolved!', 'success');
            }
            
        } catch (error) {
            console.error('Error saving jurisdiction:', error);
            this.showToastMsg('Error', 'Error saving jurisdiction: ' + error.body?.message, 'error');
            this.discrepantAssets = this.discrepantAssets.map(a => 
                a.Id === assetId ? { ...a, isSaving: false, saveButtonLabel: 'Save' } : a
            );
        }
    }
    
    // SAL-6285: Pagination handlers
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadDiscrepantAssets();
        }
    }
    
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadDiscrepantAssets();
        }
    }

    showToastMsg(title, message, type){
        this.dispatchEvent(
            new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
            mode: type = 'error' ? 'sticky' : 'dismissible'
            }),
        );
    }
}