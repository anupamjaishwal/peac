import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hubExecute from '@salesforce/apex/SL_LogACall.hubExecute';
import ccrRecords from "@salesforce/apex/SL_LogACall.fetchCCRRecords";
import populateCreatedCCR from "@salesforce/apex/SL_LogACall.populateNewCreatedCCR";
import createContactRecord from "@salesforce/apex/SL_LogACall.createContactRecord";
import { refreshApex } from '@salesforce/apex';

export default class SL_LogACall extends LightningElement {
    @api recordId;
    
    isOpen = false;
    isLoading = false;
    title = "Log a Call";
    fieldsToEdit = new Map([
        ["Department__c", {options: "departmentOptions", value: "departmentValue"}],
        ["Activity__c", {options: "activityOptions", value: "activityValue"}],
        ["Primary_Call_Outcome__c", {options: "primaryOutcomeOptions", value: "primaryOutcomeValue"}],
        ["Secondary__c", {options: "secondaryOptions", value: "secondaryValue"}],
        ["Description", ""]
        
    ]);

    dependencies;
    optionsByField;
    controllingFields = [];
    dependentFields = [];

    departmentValue = "";
    departmentOptions;
    activityValue = "";
    activityOptions;
    primaryOutcomeValue = "";
    primaryOutcomeOptions;
    secondaryValue = [];
    secondaryOptions;
    followupDate;
    maxFollowup = null;
    minFollowup = null;
    contactName = "";
    descriptionValue = "";
    ccrValue = "";
    ccrOptions;
    @track createNewCCR = false;
    @track ccrOptionVal;
    @track progress = 50;
    
//this.template.querySelector(`[data-id="${targetId}"]`);
/*get options() {
    return [
        { label: 'New', value: 'new' },
        { label: 'In Progress', value: 'inProgress' },
        { label: 'Finished', value: 'finished' },
        { label: ' + Add New CCR', value: '_new_' }
    ];
}*/

@track l_All_Types;
@track TypeOptions;

/*@wire(ccrRecords, {ContractId: '$recordId'})
 WiredccrRecords({ error, data }) {
        console.log('recordid::'+this.recordId);
        if (data) {
            try {
                this.l_All_Types = data; 
                let options = [];
                 console.log(data);
                for (var key in data) {
                    // Here key will have index of list of records starting from 0,1,2,....
                    options.push({ label: data[key].Contact__r.Name, value: data[key].Contact__c  });
 
                    // Here Name and Id are fields from sObject list.
                }
                options.push({ label: ' + Add New CCR', value: '_new_' });
                this.TypeOptions = options;
                 console.log(JSON.stringify(this.TypeOptions));
            } catch (error) {
                console.error('check error here', error);
            }
        } else if (error) {
            console.error('check error here', error);
        }
 
    }*/

   // getccrRecords({ContractId: '$recordId'}).then({})
   connectedCallback(){
    this.getccrRecords();
   }
   getccrRecords(){
    ccrRecords({ContractId: this.recordId}).then((data)=>{
            console.log('result in ccr::'+JSON.stringify(data));
            this.ccrOptionVal = ' ';
            this.ccrValue = '';
            console.log(this.ccrOptionVal+'--'+this.ccrValue);
            if (data) {
                try {
                    this.l_All_Types = data; 
                    let options = [];
                     console.log(data);
                    for (var key in data) {
                        // Here key will have index of list of records starting from 0,1,2,....
                        options.push({ label: data[key].Contact__r.Name, value: data[key].Contact__c  });
     
                        // Here Name and Id are fields from sObject list.
                    }
                    options.push({ label: ' + Add New CCR', value: '_new_' });
                    this.TypeOptions = options;
                     console.log(JSON.stringify(this.TypeOptions));
                } catch (error) {
                    console.error('check error here', error);
                }
            } else if (error) {
                console.error('check error here', error);
            }
        })
    }

    closeModal(event){
        this.isLoading = true;
        console.log('on close modal::'+JSON.stringify(this.template.querySelector("[data-id='ccrComboVal']")));
        this.TypeOptions = {};
        this.ccrOptionVal = '';
        this.ccrValue ='';
        console.log('closeModel::'+this.ccrOptionVal);
        this.getccrRecords(this.recordId);
        this.createNewCCR = false;
        this.isLoading = false;
    }
   
    handleChangeCCR(event){
        var Picklist_Value = event.target.value; 
        this.ccrValue = event.target.value;
        console.log('ccrValue::'+this.ccrValue);
        if(this.ccrValue == '_new_'){
        this.createNewCCR = true;
        }
    }
    handleOpen(){
        this.isOpen = true;
        this.isLoading = true;
        let fields = [];
        for (const key of this.fieldsToEdit.keys()) {
            fields.push(key);
        }
        hubExecute({methodName: 'loadEmulatedTask', methodParameters: [fields.join(",")]})
        .then((result)=>{
            let obj = JSON.parse(result);
            console.log(result);
            if(obj.dependencies && obj.optionsByField){
                this.dependencies = new Map(Object.entries(obj.dependencies));
                this.optionsByField = new Map(Object.entries(obj.optionsByField));
                this.controllingFields = obj.controllingFields;
                this.dependentFields = obj.dependentFields;
                this.fieldsToEdit.forEach((object, key)=>{
                    console.log('@@::'+this[object.options]);
                    console.log(this.setPicklistValues(key));
                    this[object.options] =  this.setPicklistValues(key);
                });
            } else {
                this.showError("Response came in an unexpected format");
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    setPicklistValues(fieldName){
        let result = fieldName == "Secondary__c"? []: [{label: "--None--", value: ""}];
        if(this.dependentFields.includes(fieldName)){
            for(let i = 0; i < this.controllingFields.length; i++){
                let controller = this.controllingFields[i];
                let dependencyKey = controller + "_" + fieldName;
                if(this.dependencies.has(dependencyKey)){
                    let selectedValue = this[this.fieldsToEdit.get(controller).value];
                    let foundOption = this.optionsByField.get(controller).find(option=>{option.value == selectedValue});
                    let validOptions = [];
                    if(foundOption){
                        validOptions = this.getDependentOptions(dependencyKey, foundOption.value, fieldName);
                    }
                    result = result.concat(validOptions);
                    break;
                }
            }
        }else{
            result = result.concat(this.optionsByField.get(fieldName));
        }
        return result;
    }
    
    handleDepartment(event){
        this.departmentValue = event.target.value;
        this.changePicklistValues("Department__c", event.target.value);
    }
    handleActivity(event){
        this.activityValue = event.target.value;
        this.changePicklistValues("Activity__c", event.target.value);
    }

    handlePrimaryOutcome(event){
        this.primaryOutcomeValue = event.target.value;
        this.changePicklistValues("Primary_Call_Outcome__c", event.target.value);
        this.isLoading = true;
        let parameters = [this.departmentValue, this.primaryOutcomeValue];
        hubExecute({methodName: 'calculateFollowup', methodParameters: parameters})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj){
                this.followupDate = obj.followupDate;
                this.maxFollowup = obj.maxFollowup? obj.maxFollowup: null;
                this.minFollowup = obj.minFollowup? obj.minFollowup: null;
            } else {
                this.showError("Response came in an unexpected format");
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleSecondary(event){
        this.secondaryValue = event.target.value;
        this.changePicklistValues("Secondary__c", event.target.value);
    }

    handleContact(event){
        this.contactName = event.target.value;
        console.log('cCR Name::'+this.contactName);
    }

    handleDescription(event){
        this.descriptionValue = event.target.value;
    }

    handleFollowup(event){
        let newDate = new Date(event.target.value);
        let maxFollowup = new Date(this.maxFollowup);
        let minFollowup = new Date(this.minFollowup);
        if((this.minFollowup === null || (newDate <= maxFollowup))
            && (this.maxFollowup === null || (newDate >= minFollowup))){
            this.isLoading = true;
            hubExecute({methodName: 'validateBusinessDay', methodParameters: [newDate]})
            .then((result)=>{
                let obj = JSON.parse(result);
                if(obj){
                    if(Boolean(obj.isValid) === true){
                        this.followupDate = newDate.toISOString();
                    }else{
                        this.showError(`The date ${newDate.getUTCMonth()+1}/${newDate.getUTCDate()}/${newDate.getUTCFullYear()} is not a valid Business day, please select another Date.`);
                    }
                } else {
                    this.showError("Response came in an unexpected format");
                }
            })
            .catch((error)=>{
                this.showError(error);
            })
            .finally(()=>{this.isLoading = false;});
        }else{
            this.showError(`Please select a date from ${this.minFollowup} to ${this.maxFollowup}.`);
        }
    }

    closeActionScreen(){
        this.isOpen = false;
    }

    handleSave(){
        let allInputs = this.template.querySelectorAll(".to-validate");
        let doIt = true;
        for(let i = 0; i < allInputs.length; i++){
            allInputs[i].reportValidity();
            if(!allInputs[i].checkValidity()){
                doIt = false;
                break;
            }
        }
        if(doIt){
            this.isLoading = true;
            if(this.ccrValue == '_new_' || this.ccrValue == ' '){
                this.ccrValue = '';
            }
            let parameters = [this.recordId,
                this.departmentValue,
                this.activityValue,
                this.primaryOutcomeValue,
                this.secondaryValue.join(';'),
                this.followupDate,
                //this.contactName,
                this.descriptionValue,
                this.ccrValue
                ];
            hubExecute({methodName: 'saveTask', methodParameters: parameters})
            .then((result)=>{
                if(result == "success"){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Task has been created successfully",
                            variant: result
                        })
                    );
                    this.departmentValue = "";
                    this.activityValue = "";
                    this.primaryOutcomeValue = "";
                    this.secondaryValue = [];
                    this.followupDate = "";
                    this.maxFollowup = null;
                    this.minFollowup = null;
                    this.contactName = "";
                    this.descriptionValue = "";
                    this.ccrValue = "";
                    this.closeActionScreen();
                } else {
                    this.showError("An unknown error occurred.");
                }
            })
            .catch((error)=>{
                console.log('error::'+JSON.stringify(error));
                this.showError(error);
            })
            .finally(()=>{this.isLoading = false;});
        }else{
            this.showError("Please correct the errors on this form and try again.");
        }
    }
    changePicklistValues(controller, controllingValue){
        if(this.controllingFields.includes(controller)){
            this.dependentFields.forEach(dependentField=>{
                let dependencyKey = controller + "_" + dependentField;
                let fieldObject = this.fieldsToEdit.get(dependentField);
                let newOptions = dependentField == "Secondary__c"? []: [{label: "--None--", value: ""}];
                newOptions = newOptions.concat(this.getDependentOptions(dependencyKey, controllingValue, dependentField));
                this[fieldObject.options] = newOptions;
                this[fieldObject.value] = dependentField == "Secondary__c"? []: "";
            });
        }
    }

    getDependentOptions(dependencyKey, controllingValue, dependentField){
        let options = [];
        let validValues = this.dependencies.get(dependencyKey)[controllingValue];
        if(validValues){
            validValues.forEach(validValue=>{
                options.push(this.optionsByField.get(dependentField).find(option=> option.value == validValue));
            });
        }
        return options;
    }

    showError(error){
        let message = (error && error.body && error.body.message) || error.message || error;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }

   /* handleSubmit() {
        var isVal = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            isVal = isVal && element.reportValidity();
            
        })
        if (isVal) {
            var obj = {};
            obj 
            this.template.querySelectorAll('lightning-record-edit-form').forEach(element => {
                element.submit();
                console.log('element::'+JSON.stringify(element));
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'successfully created',
                    variant: 'success',
                }),
                
            );
            
            this.createNewCCR = false;
            //this.getccrRecords();
            this._interval = setInterval(() => {  
                this.progress = this.progress + 5;
                this.getccrRecords();  
                if ( this.progress === 55 ) {  
                    clearInterval(this._interval);  
                }
            }, this.progress);
            //this.ccrRecords(this.recordId);
           // refreshApex(this.WiredccrRecords); 
            this.populateNewlyCreatedCCR();
             //return true;
        
        } else {
        
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: 'Please enter all the required fields',
                    variant: 'error',
                }),
            );
        }
    }*/

    onHandleSave(){
        let contCR = { 'sobjectType': 'Contract_Contact_Role__c' };
        contCR.Contract__c = this.recordId
        contCR.Contact__c = this.template.querySelector("[data-id='Contact__c']").value;
    console.log(contCR);
         createContactRecord({newRecord: contCR})
        .then(result => {
            //this.recordId = result;
            console.log('newly created CCR::'+JSON.stringify(result));
           this.getccrRecords(this.recordId);
           this.populateNewlyCreatedCCR();
           /* console.log('alldata::'+JSON.stringify(this.l_All_Types));
            (this.l_All_Types).forEach(ccrObj=>{
                console.log('ccrObj::'+JSON.stringify(ccrObj));
                if(contCR.Contact__c == ccrObj.Contact__c){
                    this.ccrOptionVal = ccrObj.Contact__c;
                }
            });*/
            this.createNewCCR = false;
            
        })
        .catch(error => {
            console.log(error);
            this.error = error;
        });
        
    }
    handleSuccess(event){
        refreshApex(this.WiredccrRecords); 
        console.log('success::'+JSON.stringify(event));
        console.log(event.detail.id);
        //this.populateNewlyCreatedCCR();
    }
     populateNewlyCreatedCCR(){
        populateCreatedCCR({recordId: this.recordId}).then((result)=>{
            console.log('result::'+JSON.stringify(result));
            this.ccrOptionVal = result.Contact__c;
            console.log(this.ccrOptionVal);
        })
    }

}