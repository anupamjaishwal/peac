import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hubExecute from '@salesforce/apex/SL_QueueAdmin.hubExecute';
import hubExecuteFuture from '@salesforce/apex/SL_RRManageMDTFuture.hubExecuteFuture';

export default class SL_QueueAdministration extends LightningElement {
    isLoading = false;

    userRole = "";
    get objects() {
        return [
            { label: "Case", value: "Case" },
            { label: "Contract", value: "Contract__c" }
        ];
    }
    targetObject = "";
    queues = [];
    targetQueue = "";
    allUsers = [];
    get isNoQueue(){ return !this.targetQueue; }
    isMembersRetrieved = false;
    members = [];
    initialMembers = [];
    isEditing = false;
    get isNotEditing(){ return !this.isEditing; }

    connectedCallback(){
        this.isLoading = true;
        hubExecute({methodName: 'getRole', methodParameters: []})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj.roleName){
                this.userRole = obj.roleName;
                this.targetObject = this.userRole == "Customer Service"? "Case": "Contract__c";
                let newQueues = [];
                obj.queues.forEach(queue => {
                    newQueues.push({label: queue.Name, value: queue.Id});
                });
                this.queues = newQueues;
                let newUsers = [];
                obj.allUsers.forEach(user => {
                    newUsers.push({label: user.Name, value: user.Id});
                });
                this.allUsers = newUsers;
            } else {
                this.showError(obj.error);
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleQueueChange(event){
        if(event.target.value && event.target.value !== this.targetQueue){
            this.targetQueue = event.target.value;
            //this.fetchGroupMembers();
        }
    }

    handleGetMembers(){
        if(this.targetQueue && !this.isMembersRetrieved){
            this.fetchGroupMembers();
        }
        this.isEditing = true;
    }

    fetchGroupMembers(){
        this.isLoading = true;
        hubExecute({methodName: 'getGroupMembers', methodParameters: [this.targetQueue]})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj.members){
                let newMembers = [];
                obj.members.forEach(member =>{
                    newMembers.push(member.Id);
                });
                this.members = newMembers;
                this.initialMembers = [...newMembers];
                this.isMembersRetrieved = true;
            } else {
                this.showError(obj.error);
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    handleMembersChange(event){
        this.members = event.target.value;
    }

    handleStopEditing(){
        this.isEditing = false;
        this.isMembersRetrieved = false;
    }

    handleSave(){
        let memberList = this.members.join(',');
        let parameters = [this.targetQueue, memberList, this.targetObject];
        this.isLoading = true;
        hubExecute({methodName: 'saveGroupMembers', methodParameters: parameters})
        .then((result)=>{
            let obj = JSON.parse(result);
            if(obj.success){
                // good to have message: " You will receive a confirmation soon about the Round Robin Updates to the Queue."
                let forContract = this.targetObject == "Contract__c"? " It may take a while for Round Robin Queue Updates to be finished.": "";
                if(this.targetObject == "Contract__c"){
                    if(obj.fullNames){
                        this.callDeletion(obj.fullNames, forContract);
                    }else{
                        this.callAddition(forContract);
                    }
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Users have been updated successfully for the Queue." + forContract,
                            variant: 'success'
                        })
                    );
                    this.handleStopEditing();
                    this.isLoading = false;
                }
            } else {
                this.showError("An unknown error has occurred.");
                this.isLoading = false;
            }
        })
        .catch((error)=>{
            this.showError(error);
            this.isLoading = false;
        })
    }

    callDeletion(fullNames, forContract){
        let fullNamesList = fullNames.join(',');
        this.isLoading = true;
        hubExecuteFuture({methodName: 'deleteRRAssignees', methodParameters: [fullNamesList]})
        .then((result)=>{
            if(result == "success"){
                if(this.targetObject == "Contract__c"){
                    console.log("deletion was called");
                    this.callAddition(forContract);
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Users have been updated successfully for the Queue." + forContract,
                            variant: 'success'
                        })
                    );
                    this.handleStopEditing();
                    this.isLoading = false;
                }
            } else {
                this.showError("An unknown error has occurred.");
                this.isLoading = false;
            }
        })
        .catch((error)=>{
            this.showError(error);
            this.isLoading = false;
        })
    }

    callAddition(forContract){
        this.isLoading = true;
        hubExecute({methodName: 'addRRAssignees', methodParameters: []})
        .then((result)=>{
            if(result == "success"){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Users have been updated successfully for the Queue." + forContract,
                        variant: 'success'
                    })
                );
                this.handleStopEditing();
            } else {
                this.showError("An unknown error has occurred.");
            }
        })
        .catch((error)=>{
            this.showError(error);
        })
        .finally(()=>{this.isLoading = false;});
    }

    showError(error, customTitle){
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