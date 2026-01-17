import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { showError }  from 'c/sL_Common';
import hubExecute from "@salesforce/apex/SL_UpdateAssetLocation.hubExecute";


export default class SL_UpdateAssetLocation extends LightningElement {
    @api recordId;
    title = "Upload Asset Location";
    isLoading = false;
    isInProgress = false;
    isInfoReceived = false;
    isSavedInIL = false;

    address1;
    address2;
    zip;
    effectiveDate;

    receivedZip;
    stateCode;
    stateName;
    cities;
    countyName;
    countyOptions;
    selectedCounty;
    cityName;
    cityOptions;
    selectedCity;
    
    handleAddress1(event){
        this.address1 = event.detail.value;
    }
    handleAddress2(event){
        this.address2 = event.detail.value;
    }
    handleZip(event){
        this.zip = event.detail.value;
    }
    handleEffectiveDate(event){
        this.effectiveDate = event.detail.value;
    }

    handleSendZip(){
        let allInputs = this.template.querySelectorAll('lightning-input-field');
        allInputs.forEach(input =>{
            if(input.name == "Asset_Zip_Code__c"){
                this.zip = input.value;
            }
        });
        this.isLoading = true;
        let parameters = [this.zip];
        hubExecute({methodName: "getCounty", methodParameters: parameters })
        .then((result)=>{
            let rawResponse = JSON.parse(result);
            let obj = rawResponse.response || rawResponse;
            if(obj){
                if(!obj.errors){
                    this.isInfoReceived = true;
                    this.receivedZip = obj.zipcode;
                    this.stateCode = obj.stcode;
                    this.stateName = obj.stname;
                    let newCities = [];
                    let newCountyOptions = [];
                    for(let i = 0; i < obj.county.length; i++){
                        let county = obj.county[i];
                        newCountyOptions.push({value: county.cncode, label: county.cnname});
                        county.city.forEach(city =>{
                            newCities.push({cnCode: county.cncode,
                                cnName: county.cnname,
                                ciCode: city.cicode,
                                ciName: city.ciname});
                        });
                    }
                    this.cities = newCities;
                    this.countyOptions = newCountyOptions;
                }else{
                    showError(this, obj.errors);
                }
            }else{
                showError(this, "Response came in unexpected format.");
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{ this.isLoading = false; });
    }

    handleCounty(event){
        this.selectedCounty = event.detail.value;
        if(this.selectedCounty){
            let newOptions = [];
            this.cities.filter(city => city.cnCode == this.selectedCounty).forEach(city =>{
                newOptions.push({value: city.ciCode, label: city.ciName});
            });
            this.cityOptions = newOptions;
            this.selectedCity = null;
        }
    }

    handleCity(event){
        this.selectedCity = event.detail.value;
        if(this.selectedCity){
            let cityObj = this.cities.find(city => city.cnCode == this.selectedCounty && city.ciCode == this.selectedCity);
            this.countyName = cityObj.cnName;
            this.cityName =  cityObj.ciName;
        }
    }

    handleClose(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    handleBeforeSave(event){
        if(this.isInProgress){
            event.preventDefault();
        } else {
            let isCityValid = false;
            this.template.querySelectorAll("lightning-combobox").forEach(cityCombo =>{
                if(cityCombo.name == "receivedCity"){
                    cityCombo.reportValidity();
                    isCityValid = cityCombo.checkValidity();
                }
            });
            if(isCityValid){
                if(this.receivedZip == this.zip){
                    if(!this.isSavedInIL){
                        event.preventDefault();
                        this.isLoading = true;
                        this.isInProgress = true;
                        let form = this.template.querySelector('lightning-record-edit-form');
                        let fields = event.detail.fields;
                        let address2 = fields.Asset_Address_2__c? fields.Asset_Address_2__c: "";
                        let effectiveDate = fields.Asset_Location_Effective_Date__c? fields.Asset_Location_Effective_Date__c: "";
                        let parameters = [this.recordId, this.stateCode, this.selectedCounty, this.selectedCity,
                            fields.Asset_Address_1__c, address2, this.receivedZip, effectiveDate];
                        hubExecute({methodName: "saveNewLocation", methodParameters: parameters})
                        .then((result)=>{
                            let rawResponse = JSON.parse(result)
                            let obj = rawResponse.response || rawResponse;
                            console.log("result obj: ", obj);
                            if(obj.Response.Success == "True" && obj.Response.Errors.length == 0){
                                this.isSavedInIL = true;
                                if(!effectiveDate){
                                    fields.Asset_Location_Effective_Date__c = (new Date(Date.now())).toISOString();
                                }
                                form.submit(fields);
                            }else{
                                this.isLoading = false;
                                if(obj.Response.Errors && obj.Response.Errors.length > 0){
                                    showError(this, obj.Response.Errors);
                                }else{
                                    showError(this, JSON.parse(obj.Response), "Unknow error");
                                }
                            }
                        })
                        .catch((error)=>{
                            this.isLoading = false;
                            showError(this, error);
                        })
                        .finally(()=>{
                            this.isInProgress = false;
                        });
                    }
                }else{
                    showError(this, "Please click on Send Location Update to get the corresponding Cities for the Zip Code currently entered.");
                    event.preventDefault();
                }
            }else{
                event.preventDefault();
            }
        }
    }

    handleSuccess(){
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Success",
                message: "The new location was correctly Saved in InfoLease and the fields where updated locally.",
                variant: 'success'
            })
        );
        this.handleClose();
    }
}