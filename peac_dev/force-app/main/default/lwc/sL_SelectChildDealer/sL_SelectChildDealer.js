import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_SelectChildDealer.hubExecute';

export default class SL_SelectChildDealer extends LightningElement {
    @api currentContactId;
    @api dealerAccountId;
    @api dealerUserId = null;
    @api dealerUserFirstName;
    @api dealerUserLastName;
    @api isComingSecondTime = false;
    dealerUser = null;
    isLoading;
    childAccounts = [];
    allDealerUsers = {};
    get isAccountEmpty() { return !this.dealerAccountId }
    dealerUsers = [];
    userId;
    canAdvocate;

    connectedCallback(){
        this.isLoading = true;
        this.dealerUser = null;
        this.canAdvocate = false;
        hubExecute({methodName: "getChildAccounts", parameters: [this.currentContactId]})
        .then((result)=>{
            let obj = JSON.parse(result);
            console.log("obj: ", JSON.parse(JSON.stringify(obj)));
            this.canAdvocate = obj.canAdvocate;
            if(!this.canAdvocate){
                this.dealerAccountId = obj.dealerAccountId;
                this.dealerUser = obj.dealerUsersByAccountId[this.dealerAccountId].find(user => { 
                    return user.ContactId.substring(0,15) == this.currentContactId
                });
                this.setUserInfo();
                this.isComingSecondTime = sessionStorage.getItem('isNewAppComingBack') === 'true';
                if(this.isComingSecondTime){
                    sessionStorage.setItem('isNewAppComingBack',false);
                    this.dispatchEvent(new FlowNavigationBackEvent());
                }else{
                    sessionStorage.setItem('isNewAppComingBack', true);
                    this.dispatchEvent(new FlowNavigationNextEvent());
                }
            }else{
                this.childAccounts = [];
                obj.childAccounts.forEach(account =>{
                    this.childAccounts.push({ label: account.Name, value: account.Id });
                });
                this.allDealerUsers = obj.dealerUsersByAccountId;
            }
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{ this.isLoading = false; });
    }

    handleChildAccount(event){
        this.dealerAccountId = event.target.value;
        this.dealerUsers = [];
        this.isLoading = true;
        this.allDealerUsers[this.dealerAccountId].forEach(user =>{
            this.dealerUsers.push({ label: user.Name, value: user.Id });
        });
        this.isLoading = false;
    }

    handleDealerUser(event){
        this.userId = event.target.value;
        this.dealerUser = this.allDealerUsers[this.dealerAccountId].find(user => { return user.Id == this.userId});
        this.setUserInfo();
    }

    @api
    validate(){
        let isValid = true;
        let fields = this.template.querySelectorAll('lightning-combobox');
        fields.forEach(field => {
            if(isValid){
                field.reportValidity();
                isValid = field.checkValidity();
            }
        }); 
        if(!isValid) { 
            return {
                isValid: false,
                errorMessage: "Please Select a Dealer Account and a Dealer User."
            }
        }
    }

    setUserInfo(){
        this.dealerUserId = this.dealerUser.Id;
        this.dealerUserFirstName = this.dealerUser.FirstName;
        this.dealerUserLastName = this.dealerUser.LastName;
    }
}