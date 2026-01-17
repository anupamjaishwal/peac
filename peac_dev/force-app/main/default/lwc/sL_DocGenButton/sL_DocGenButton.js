import { LightningElement, wire, api, track} from 'lwc';
import getContacts from '@salesforce/apex/SL_DocGenController.getContacts';
import getInstance from '@salesforce/apex/SL_DocGenController.getInstance';
import getOppInfo from '@salesforce/apex/SL_DocGenController.getOppInfo';
import isOppValid  from '@salesforce/apex/SL_DocGenController.isOppValid';
import isStateValid  from '@salesforce/apex/SL_DocGenController.isStateValid';
import sendDocuments  from '@salesforce/apex/SL_DocGenController.sendDocuments';
import hasPendingItems  from '@salesforce/apex/SL_DocGenController.hasPendingItems';
import createPrimaryContact  from '@salesforce/apex/SL_DocGenController.handlePrimaryContact';
import getUserContact  from '@salesforce/apex/SL_DocGenController.getUserContact';
import getDisclaimers  from '@salesforce/apex/SL_DocGenController.getDisclaimers';
import NAME_FIELD from '@salesforce/schema/Contact.Name';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import { CloseActionScreenEvent } from "lightning/actions";
import { refreshApex } from '@salesforce/apex';
import { showToast, reduceErrors} from 'c/sl_Utils';
import {CurrentPageReference,NavigationMixin} from 'lightning/navigation';

export default class SL_DocGenButton extends NavigationMixin(LightningElement) {
    _recordId;
    currentOpportunity;
    pdContactId;
    showContactList=true;
    showErrorMessage=false;
    showStateMessage=false;
    showApprovedMessage=false;
    showPendingCheckListMessage=false;
    showAmountMessage = false;
    isValid=true;
    fields = [NAME_FIELD,EMAIL_FIELD,PHONE_FIELD];
    showNewButton=false;
    generateBtnState = false;
    spinState = false;
    instanceId='';
    conRecId;

    @api rec;

    @track privateLabels;
    @track oppBranch;
    @track PrimaryContact;
    @track dealerContacts=[];      
    @track selectedContact='';
    @track newContactFlag = false;
    @track wiredResponse

    //Iframe variables:
    @track height = '900px';
    @track referrerPolicy = 'no-referrer';
    @track sandbox = '';
    @track url = '';
    @track width = '100%';
    disabledAgree = true;
    showTermsCondMessage = false;
    TermsCondMessage;
    _recordId;
    @api set recordId(value) {
      this._recordId = value;
      this.init();
    }

    get recordId() {
      return this._recordId;
    }

    connectedCallback(){
      this.value="Docusign";
    }

    @wire(CurrentPageReference)
    pageRef;

    handleNavigate(params) {
      console.log('in handleNavigate');
      const config = {
          type: 'standard__webPage',
          attributes: {
            url: '/dealers/apex/loop__looplus?'+this.instanceId+'&header=true&sidebar=true&hidecontact=true&hideddp=true&eid='+this.recordId+'&autorun=true&'+params+'&contactId='+this.selectedContact
              //url: '/dealers/apex/loop__looplus?'+this.instanceId+'&header=false&sidebar=false&hidecontact=true&hideddp=true&eid='+this.recordId+'&autorun=true&'+params+'&contactId='+this.selectedContact
          }
      };
      //console.log('GenURL: '+config.attributes.url);
      this[NavigationMixin.Navigate](config);
    }
   
    init(){
      console.log("Record ID: ",this.recordId);
      console.log("rec",this.rec);
      
      //this.handlerOppInfo();
      /*isOppValid({recordId:this.recordId}).then(result=>{
        console.log("Valido",result);
        this.showErrorMessage=!result;
        this.isValid=result;
      });
      hasPendingItems({recordId:this.recordId}).then(result=>{
        console.log("Pending Items",result);
        this.showPendingCheckListMessage=result;
        this.isValid=!result;
      });
    isStateValid({recordId:this.recordId}).then(result=>{
        console.log("Valido",result);
        this.showStateMessage=!result;
        this.isValid=result;
      });*/
      this.value="Docusign";
    }
    
    @wire(getOppInfo, {recordId: '$_recordId'})
    wiredData(result){
      this.wiredResponse = result;
      if(result.data){
        this.currentOpportunity = result.data;
        this.showApprovedMessage= !this.isApproved(this.currentOpportunity.Application_Status__c);
        this.pdContactId = this.currentOpportunity.Primary_Contact__c;
        this.privateLabels = this.currentOpportunity.Private_Label_Documents__c;
        this.oppBranch = this.currentOpportunity.Branch__c;
        this.getDealerContacts();
        this.oppequipmentCost = this.currentOpportunity.Equipment_Cost__c;
        getUserContact().then(data=>{
          this.spinState = true;
          this.showTermsCondMessage = false;
          console.log('data',JSON.stringify(data));
          console.log(this.oppBranch.indexOf('OEG'), '   ', data.Contact.Account.Pre_Delivery__c.indexOf('Yes'),'  delivery ' ,data.Contact.Account.Pre_Delivery__c);
          //if(this.oppBranch && this.oppBranch.indexOf('OEG') != -1 && (!data.Contact.Account.Pre_Delivery__c || data.Contact.Account.Pre_Delivery__c.indexOf('Yes') != -1)) {
          if((this.oppBranch && this.oppBranch.indexOf('OEG') == -1) && (!data.Contact.Account.Pre_Delivery__c || data.Contact.Account.Pre_Delivery__c.indexOf('Yes') != -1)){
          
            this.spinState = true;
            
            this.TermsCondMessage = undefined;
            getDisclaimers().then(dis=>{

              dis.forEach(Element=>{
                console.log(JSON.stringify(Element));
                if(data.Contact.Account.Pre_Delivery__c == Element.Pre_Delivery__c && Element.Equipment_Cost__c < this.oppequipmentCost){
                //if(data.Contact.Account.Pre_Delivery__c == Element.Pre_Delivery__c){
                  this.TermsCondMessage = Element.Message__c;
                  this.showTermsCondMessage = true;
                }
              })
            }).finally(() => {
            this.spinState = false;
            });
          } else {
            this.showTermsCondMessage = false
          }
        }).catch(error=>{
          console.log("Error when sending the message",error);
        }).finally(() => {
          this.spinState = false;
        });
        isOppValid({recordId:this.recordId}).then(result=>{
          //console.log("Valido",result);
          this.showErrorMessage=!result;
          this.isValid=result;
          hasPendingItems({recordId:this.recordId}).then(result=>{
            //console.log("Pending Items",result);
            this.showPendingCheckListMessage=result;
            this.isValid=!result;
            isStateValid({recordId:this.recordId}).then(result=>{
              //console.log("Valido",result);
              this.showStateMessage=!result;
              this.isValid=result;
              if(!this.currentOpportunity.Payment_Amount__c || this.currentOpportunity.Payment_Amount__c <= 0){
                this.showAmountMessage = true;
              } else {
                this.showAmountMessage = false;
              }
              if(!this.isValid || !this.showApprovedMessage){
                //this.handleNavigate();
              }
              
              getInstance().then(result=>{
                //console.log("INSTANCE: "+result);
                this.instanceId="&instance="+result+"&";
              });
            });
          });
        
        });
        
      }else if(result.error){
        console.error(result.error);
      }
    }
    
    /*handlerOppInfo(){
      getOppInfo({recordId:this.recordId}).then(data=>{
        console.log("Test data:",data);
        this.showApprovedMessage=data.Application_Status__c!='Approved';
        this.currentOpportunity = data;
        this.pdContactId = this.currentOpportunity.Primary_Contact__c;
        this.privateLabels = this.currentOpportunity.Private_Label_Documents__c;
        this.oppBranch = this.currentOpportunity.Branch__c;
        this.getDealerContacts();
      }).catch(error=>{
        console.error(error);
      });
    }*/

    getDealerContacts(){
      /*const contactList=[];
      if(this.pdContactId!=null){
        this.selectedContact=this.currentOpportunity.Primary_Contact__c;
        contactList.push({label:this.currentOpportunity.Primary_Contact__r.Name,value:this.currentOpportunity.Primary_Contact__c});
      }
      console.log('contactList', JSON.stringify(contactList))
      this.dealerContacts = contactList;*/

      getContacts({accountId: this.currentOpportunity.AccountId})
      .then(
        data=>{
          const contactList=[];
          if(this.pdContactId!=null){
            this.selectedContact=this.currentOpportunity.Primary_Contact__c;
            contactList.push({label:this.currentOpportunity.Primary_Contact__r.Name,value:this.currentOpportunity.Primary_Contact__c});
          }
          
          data.filter((item) => item.Id !== this.currentOpportunity.Primary_Contact__c).forEach(el=>{
            contactList.push({label:el.Name,value:el.Id});
          })
          this.dealerContacts = contactList;
        }
      ).catch(error=>{
          console.log("Error when sending the message",error);
      });
    }

    contactSelect(event){
      this.selectedContact= event.detail.value;
    }

    newContactClick(event){
        this.isModalOpen=true;
    }
    handleerror(event){
      console.log(event.detail.detail,'error',JSON.stringify(event.detail.detail));
      this.dispatchEvent(showToast('Error', event.detail.detail, 'error'));
    }
    
    @track value = '';
    get options(){
      return [
        {label:'Docusign', value:'Docusign'},
        {label: 'Download', value:'Download'},
        {label:'In-Person Signature',value:'In-Person'}
      ]
    }
    handleChange(event){
      this.value = event.detail.value;
    }

    isModalOpen=false;
    handleSuccess(event) {
      console.log('sucess:');
      this.selectedContact=event.detail.id;
      this.isModalOpen=false;
      console.log('this.selectedContact', this.selectedContact);
      if(this.selectedContact!==''){
        this.handlePrimaryContact(this.selectedContact, false);
      }
    }

    close(){
      const selectEvent = new CustomEvent('close', {
          detail: 'close' ,bubbles: true
      });
      this.dispatchEvent(selectEvent);
      this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleClose(){
      this.close();
    }

    showValidationMessage=false;
    showContactMessage=false;
    
    handleClick(){
      
      this.showValidationMessage=false;
      this.showContactMessage=false;
      if( this.value=='' || this.value==null){
          this.showValidationMessage=true;
      }else if(this.value!='Download' && (this.selectedContact==null  || this.selectedContact=='') ){
          this.showContactMessage=true;
      }else{
        this.spinState = true;
        this.handleStateGenerateBtn(true);
        if(this.selectedContact !== this.currentOpportunity.Primary_Contact__c && this.selectedContact!==''){
          this.handlePrimaryContact(this.selectedContact, true);
        }else{
          this.handlerSendDocs();
        }
      }
    }

    closeModal(){
        this.isModalOpen=false;
    }

  //handler to enable or disable the Generate doc button.
  handleStateGenerateBtn(state){
    this.generateBtnState = state;
  }

  handlerSendDocs(){
    sendDocuments({recordId:this.recordId, contactId:this.selectedContact,sendMethod:this.value})
    .then(data=>{
      console.log('RETURN VALUE:',data);
      if(data!=''){
        this.handleNavigate(data);
        this.dispatchEvent(new CloseActionScreenEvent());
        this.close();
        //this.dispatchEvent(showToast('Message Sent', this.docgenMsg(this.value), 'success'));
        //this.dispatchEvent(evt);
        this.handleStateGenerateBtn(false);
      }
    }).catch(error=>{
        //this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "), 'error'));
        console.log("Error when sending the message",error);
    })
    .finally(() => {
      this.spinState = false;
    });
  }

  //handler to create the Primary Contact Role. DP-549
  handlePrimaryContact(contactId, isUpdate){
    createPrimaryContact({contactId, 'OpportunityId':this._recordId })
    .then(()=>{
      if(!isUpdate){
        this.dispatchEvent(showToast('Contact created', 'Contact Created', 'success'));
      }else{
        this.handlerSendDocs();
      }
    })
    .catch((error)=>{
      this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "), 'error'));
    })
    .finally(()=>{
      //this.handlerOppInfo();
      return this.refresh();
    });
  }

  async refresh() {
    await refreshApex(this.wiredResponse);
    this.spinState = false;
  }

  //DP-549 Contact will be related to the end user account.
  handleContactSubmit(event) {
    console.log('submit:', event);
    event.preventDefault(); 
    const fields = event.detail.fields;
    
    fields.AccountId = this.currentOpportunity.AccountId;
    fields.Id = null;
    console.log(':fields:',JSON.stringify(fields));
    this.template.querySelector('lightning-record-edit-form').submit(fields);
    //this.template.querySelector('lightning-record-edit-form').submit();
    //this.spinState = true;
  }
  TermsConditionChange(evt){
      this.disabledAgree = true;
      if(evt.target.checked){
        this.disabledAgree = false;
      }
    }
    proceedtoDocumentGen(){
      this.showTermsCondMessage = false;
      //this.handleClick();
    }
  //DocGen msg based on method selected DP-465
  docgenMsg(method){
    const DOC_GEN_VALUES = {
      'Docusign':  'DocuSign package has been sent.',
      'Download':  'Go to Document section to retrieve your generated document.',
      'In-Person':  'Message Sent'
    }; 
    return DOC_GEN_VALUES[method];
  }

  //check if the Opp is approved DP-549
  isApproved(value){
    const APPROVED_VALUES = {
      'Manually Approved':  true,
      'Automatically Approved':  true,
      'default':  false
    };
    return APPROVED_VALUES[value] || APPROVED_VALUES['default'];
  }
}