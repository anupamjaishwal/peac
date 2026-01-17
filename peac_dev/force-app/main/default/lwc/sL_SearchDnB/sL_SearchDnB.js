import { LightningElement, api, track } from 'lwc';
import getAccessToken from '@salesforce/apex/SL_DnBCallout.getAccessToken';
import callSearch from '@salesforce/apex/SL_DnBCallout.callSearch';
import searchByCCAN from '@salesforce/apex/SL_DnBCallout.searchByCCAN';
import hubExecute from '@salesforce/apex/SL_DealerPortalCreateApp.hubExecute';
import { showError } from 'c/sL_Common';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

const COLUMNS = [
    { label: "Select", fieldName: "selectButton", type: "button", typeAttributes: 
        {label: "Select", alternativeText: "Choose Customer", variant: "brand", name: "selectAccount"}},
    { label: "DUNS Number", fieldName: "duns"  },
    { label: "CCAN", fieldName: "ccan"  },
    { label: "Name", fieldName: "primaryName"  },
    { label: "Address", fieldName: "primaryAddress"  },
    { label: "Annual Revenue", fieldName: "yearlyRevenue"  },
    { label: "Industry", fieldName: "usSicV4Description"  }
];

export default class SL_SearchDnB extends LightningElement {
    criteria;
    stillTyping;
    taxId;
    result;
    cookieToken;
    @track rows = [];
    noDataReason = "";
    columns = COLUMNS;
    selectedRow = {};
    isLoading = false;
    @api foundAccountId = "";
    @api foundAccount = {};
    debounceTimeout;
    searchTerm;
    
    connectedCallback(){
        sessionStorage.setItem('isNewAppComingBack', false);
    }

    handleSearchTerm(event){
        this.rows = [];
        this.selectedRow = {};
        let newValue = event.target.value;


        clearTimeout(this.debounceTimeout);  // Clear the previous timeout
        this.searchTerm = event.target.value;
    
        this.debounceTimeout = setTimeout(() => {
            if (this.searchTerm.length >= 2) {
                this.searchAccountsByCCAN();
            } else {
                this.accounts = [];
            }
        }, 300); // Wait for 300ms after the last keystroke






        
    }


    searchAccountsByCCAN() {

        // If not in cache, call Apex
        searchByCCAN({ searchTerm: this.searchTerm })
            .then((result) => {
                if(result.length > 0){
                    let tempRows = [];
                    result.forEach(row => {

                        let addressObject = {streetAddress: row.Business_Address__c? row.Business_Address__c: "",
                            addressLocality: row.Business_City__c? row.Business_City__c: "",
                            addressRegion:row.Business_State__c? row.Business_State__c: "",
                            postalCode: row.Business_Zip__c? row.Business_Zip__c: "",
                            addressCountry: row.Business_Country__c? row.Business_Country__c: ""}

                        tempRows.push({displaySequence: 1,
                            duns: row.DUNS__c  ,
                            primaryName: row.Name,
                            ccan: row.CCAN__c,
                            primaryAddress: row.Business_Address__c + ' '+ row.Business_Address2__c + ' ' + row.Business_City__c + ' ' + row.Business_State__c + ' ' + row.Business_Zip__c + ' ' + row.Business_Country__c,
                            yearlyRevenue: row.D_B_Revenue__c,
                            usSicV4Description: row.Industry, 
                            addressObject: addressObject
                            });
                    })
                    this.rows = tempRows;
                    this.selectedRow = {};

               }
               else{
                /*if(this.criteria != newValue){
                    this.stillTyping = true;
                } */
                this.criteria = this.searchTerm? this.searchTerm: "";
                this.handleSearch();
        
               }

            })
            .catch((error) => {
                console.error('Error retrieving accounts:', error);
            });
    }

    handleSearch(event){
        this.isLoading = true;
        if(this.cookieToken){
            this.callSearchApi();
        }else{
            getAccessToken()
            .then((result)=>{
                this.cookieToken = result;
                this.callSearchApi();
            })
            .catch((error)=>{
                showError(this, error);
                this.isLoading = false;
            })
            .finally(()=>{});
        }
        
    }

    handleSingleSelection(event){
        let selectedRows = JSON.parse(JSON.stringify(event.detail.selectedRows));
        if(selectedRows.length>1)
        {
            let el = this.template.querySelector('lightning-datatable');
            let newSelection = {};
            el.selectedRows.forEach((keyField, index)=>{
                if(keyField != this.selectedRow.displaySequence){
                    newSelection = selectedRows.find(row => row.displaySequence == keyField);
                }
            })
            this.selectedRow = newSelection;
            let newKeyArray = [];
            newKeyArray.push(newSelection.displaySequence);
            el.selectedRows = newKeyArray;
        }else if(selectedRows.length){
            this.selectedRow = selectedRows[0];
        }else{
            this.selectedRow = {};
        }
    }

    callSearchApi(){
        callSearch({criteria: this.criteria, cookieToken: this.cookieToken})
        .then((result)=>{
            this.result = result;
            let obj = JSON.parse(result);
            if(obj.error && obj.error.errorCode == "00040"){
                this.cookieToken = "";
            }else{
                let tempRows = [];
                if(obj.searchCandidates){
                    obj.searchCandidates.forEach(row=>{
                        let addressObject = {streetAddress: row.organization.primaryAddress.streetAddress? row.organization.primaryAddress.streetAddress.line1: "",
                            addressLocality: row.organization.primaryAddress.addressLocality.name? row.organization.primaryAddress.addressLocality.name: "",
                            addressRegion: row.organization.primaryAddress.addressRegion.name? row.organization.primaryAddress.addressRegion.name: "",
                            postalCode: row.organization.primaryAddress.postalCode? row.organization.primaryAddress.postalCode: "",
                            addressCountry: row.organization.primaryAddress.addressCountry.isoAlpha2Code? row.organization.primaryAddress.addressCountry.isoAlpha2Code: ""}
                        let primaryAddress = (addressObject.streetAddress? addressObject.streetAddress: "") 
                            + (addressObject.addressLocality? " " + addressObject.addressLocality: "")
                            + (addressObject.addressRegion? " " + addressObject.addressRegion: "")
                            + (addressObject.postalCode? " " + addressObject.postalCode: "")
                            + (addressObject.addressCountry? ", " + addressObject.addressCountry: "");
                        let yearlyRevenue = 0;
                        if(row.organization.financials){
                            row.organization.financials.forEach(financial => {
                                financial.yearlyRevenue.forEach(revenue =>{
                                    yearlyRevenue += revenue.value;
                                });
                            });
                        }
                        let usSicV4Description = (row.organization.primaryIndustryCodes && row.organization.primaryIndustryCodes.length? row.organization.primaryIndustryCodes[0].usSicV4Description: "");
                        tempRows.push({displaySequence: row.displaySequence,
                            duns: row.organization.duns,
                            primaryName: row.organization.primaryName,
                            primaryAddress: primaryAddress,
                            yearlyRevenue: yearlyRevenue,
                            usSicV4Description: usSicV4Description,
                            addressObject: addressObject});
                    });
                }else {
                    if(obj.error){
                        if(obj.error.errorCode == "21501"){
                            this.noDataReason = obj.error.errorMessage;
                        }else if(obj.error.errorCode == "10002"){
                            this.noDataReason = "Invalid parameter, Minimum length allowed is 2 characters.";
                        }else if(obj.error.errorMessage){
                            this.noDataReason = obj.error.errorMessage;
                        }
                    }
                }
                this.rows = tempRows;
                this.selectedRow = {};
                if(this.stillTyping && this.isLoading){
                    this.stillTyping = false;
                }else{
                    this.isLoading = false;
                } 
            }
        })
        .catch((error)=>{
            showError(this, error);
            this.isLoading = false;
        })
        .finally(()=>{
            if(this.stillTyping && this.isLoading){
                this.stillTyping = false;
            }else{
                this.isLoading = false;
            } 
        });
    }

    handleSearchAccount(event){
        if(!this.isLoading){
            this.isLoading = true;
            this.selectedRow = event.detail.row;
            console.log("this.selectedRow: ", JSON.stringify(this.selectedRow));
            let parameters = [this.selectedRow.duns, this.taxId, this.selectedRow.primaryName,
                this.selectedRow.addressObject.streetAddress,
                this.selectedRow.addressObject.addressLocality,
                this.selectedRow.addressObject.addressRegion,
                this.selectedRow.addressObject.postalCode,
                this.selectedRow.addressObject.addressCountry,
                this.selectedRow.yearlyRevenue,
                this.selectedRow.usSicV4Description,
                this.selectedRow.primaryAddress,
                null];
            hubExecute({methodName: "getAccountByDUNS", parameters: parameters})

            .then((result)=>{
                let obj = JSON.parse(result);
                this.foundAccountId = obj.Id;
                this.foundAccount = obj;
                //console.log("this.foundAccount: ", JSON.parse(JSON.stringify(this.foundAccount)));
                this.dispatchEvent(new FlowNavigationNextEvent());
            })
            .catch((error)=>{
                showError(this, error);
            })
            .finally(()=>{ this.isLoading = false; });
        }
    }

    @api
    validate(){
        let isValid = true;
        let fields = this.template.querySelectorAll('lightning-input');
        let validLength;        
        fields.forEach(field => {
            field.reportValidity();
            console.log('Valid Length ', field.value.length>2);
            console.log(field.value.length);
            isValid = field.checkValidity(); //&& field.value.length>2;
            
        });
        if(!isValid) { 
            return {
                isValid: false,
                errorMessage: "Please Try to search for an existing Customer first."
            }
        }       
    }
}