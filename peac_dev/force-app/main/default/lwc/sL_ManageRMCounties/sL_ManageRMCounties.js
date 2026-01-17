import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { IsConsoleNavigation, getFocusedTabInfo, setTabLabel } from 'lightning/platformWorkspaceApi';

import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_ManageRMCounties.hubExecute';

const TAB_LABEL = "Manage Remarketer Matrix Counties";

export default class SL_ManageRMCounties extends LightningElement {
    @wire(IsConsoleNavigation) isConsoleNavigation;
    title = TAB_LABEL;
    isLoading = false;
    type = "";
    subType = "";
    @track state = "";
    wareHouse = "";
    warehouseCodes = [];
    // filter = {
    //     criteria: []
    // };
    counties = [];
    stateCounties = [];
    isEditing = false;
    get isNotEditing(){ return !this.isEditing; }
    changedCounties = true;
    
    async setTabLabel() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        setTabLabel(tabId, TAB_LABEL);
    }

    connectedCallback(){
        this.setTabLabel();
        this.fetchCounties();
        this.isLoading = true;
        let params = [];
        hubExecute({methodName: "getWarehouseCodes", parameters: params})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj){
                this.warehouseCodes = [];
                obj.forEach(code => {
                    this.warehouseCodes.push({label: code.Name, value: code.Name});
                });
            } else {
                showError(this, result, "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    fetchCounties(){
        this.isLoading = true;
        let params = [this.type, this.subType, this.state, this.wareHouse];
        hubExecute({methodName: "getCounties", parameters: params})
        .then((result)=>{
            // console.log('result string: ', result);
            let obj = JSON.parse(result);
            // console.log('result obj: ', obj);
            if(obj){
                this.counties = this.counties.filter((selectedCounty) => { return selectedCounty.isSelectedByUser});
                this.stateCounties = [];
                if(this.type && this.subType && this.state && this.wareHouse){
                    obj.existingCounties.forEach(county => {
                        if(!this.counties.find(selectedCounty => { return selectedCounty.name == county.Id})){
                            this.counties.push({label: county.Name, name: county.Id, type: 'icon', fallbackIconName: 'action:map',
                                variant: 'circle', alternativeText: county.Name, isSelectedByUser: false});
                        }
                    });
                }
                obj.stateCounties.forEach(county => {
                    this.stateCounties.push({label: county.Name, value: county.Id});
                });
            } else {
                showError(this, result, "Response came in unexpected format");
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleType(event){
        this.type = event.target.value;
        this.fetchCounties();
    }
    handleSubType(event){
        this.subType = event.target.value;
        this.fetchCounties();
    }
    handleState(event){
        this.state = event.target.value;
        // this.filter.criteria = [];
        // if(this.state){
        //     this.filter.criteria.push({fieldPath: "State__c", operator: "eq", value: event.target.value});
        // }
        this.counties = [];
        this.fetchCounties();
    }
    handleWarehouse(event){
        this.wareHouse = event.target.value;
        this.fetchCounties();
    }
    handleAddCounty(event){
        let countyId = undefined;
        if(event.detail.recordId){
            countyId = event.detail.recordId;
        }
        if(event.target.value){
            countyId = event.target.value;
        }
        if(countyId && !this.counties.find(selectedCounty => { return selectedCounty.name == countyId})){
            this.isEditing = true;
            let newCounty = this.stateCounties.find(stateCounty => { return stateCounty.value == countyId})
            let tempCounties = [...this.counties];
            this.counties = [];
            tempCounties.push({label: newCounty.label, name: newCounty.value, type: 'icon', fallbackIconName: 'action:map',
                variant: 'circle', alternativeText: newCounty.label, isSelectedByUser: true});
            this.counties = [...tempCounties];
        }
        this.changedCounties = false;
        setTimeout(()=> {this.changedCounties = true;}, 0);
    }
    handleCountyRemoval(event){
        // if(event.detail.index >= 0){
            let tempCounties = [...this.counties];
            this.counties = [];
            tempCounties.splice(event.detail.index, 1);
            this.counties = [...tempCounties];
            this.isEditing = true;
        // }
    }
    handleSave(event){
        let isValid = true;
        isValid = isValid && this.type;
        isValid = isValid && this.subType;
        isValid = isValid && this.state;
        isValid = isValid && this.wareHouse;
        if(isValid){
            this.isLoading = true;
            let params = [this.type, this.subType, this.state, this.wareHouse, JSON.stringify(this.counties)];
            hubExecute({methodName: "saveRMatrixes", parameters: params})
            .then((result)=>{
                if(result = "success"){
                    this.counties = [];
                    this.isEditing = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Remarketer Matrix Counties have been Saved successfully.",
                            variant: "success"
                        })
                    );
                    this.fetchCounties();
                } else {
                    showError(this, result, "Error saving Counties");
                }
            })
            .catch((error)=>{
                showError(this, error);
            })
            .finally(()=>{this.isLoading = false;});
        }else{
            showError(this, "Please enter the required fields.");
        }
    }

    customValidate(field){
        field.reportValidity();
        return field.checkValidity();
    }
}