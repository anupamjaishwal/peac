import { LightningElement, api, wire, track } from 'lwc';
import { showError } from 'c/sL_Common';
import hubExecute from '@salesforce/apex/SL_DPOffers.hubExecute';
import { updateRecord} from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { showToast, reduceErrors} from 'c/sl_Utils';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import EQUIPMENT_CODE_FIELD from "@salesforce/schema/Asset__c.Equipment_Code__c";
import getLeasePricingTrackedFields from '@salesforce/apex/PEAC_DPOfferSaveService.getLeasePricingTrackedFields';
import saveOfferChanges from '@salesforce/apex/PEAC_DPOfferSaveService.saveOfferChanges';
import PEAC_DPPricingDisclaimerTitle from '@salesforce/label/c.PEAC_DPPricingDisclaimerTitle';
import PEAC_DPPricingDisclaimerMessage from '@salesforce/label/c.PEAC_DPPricingDisclaimerMessage';
import PEAC_DPOfferPricingSaveAndCalculate from '@salesforce/label/c.PEAC_DPOfferPricingSaveAndCalculate';
import PEAC_DPOfferPricingCancel from '@salesforce/label/c.PEAC_DPOfferPricingCancel';
import PEAC_DPPricingSaveSuccess from '@salesforce/label/c.PEAC_DPPricingSaveSuccess';
import PEAC_DPOfferPricingSaveSuccessNoPricing from '@salesforce/label/c.PEAC_DPOfferPricingSaveSuccessNoPricing';
import PEAC_DPOfferPricingNoChanges from '@salesforce/label/c.PEAC_DPOfferPricingNoChanges';
import PEAC_DPOfferPricingSaveError from '@salesforce/label/c.PEAC_DPOfferPricingSaveError';

/*import COMETD from '@salesforce/resourceUrl/cometD';
import { loadScript } from 'lightning/platformResourceLoader';
import getSessionId  from '@salesforce/apex/SL_DPOffers.getSessionId';*/

import ApprovedAmount from "@salesforce/schema/Opportunity.Approved_Amount__c";
const fields = [ApprovedAmount];

export default class SL_DPOffers extends LightningElement {
  @track COLUMNS = [
    {
      label: "Equipment Type", fieldName: "Equipment_Code__c", type: "picklistColumn", editable : true,
      typeAttributes:{
        placeholder: 'Choose Value', options: { fieldName: 'Equipment_Code_Options' },
        context: { fieldName: 'Id' },
        value: { fieldName: 'Equipment_Code__c' },
        
      }
    },

    { label: "Cost", fieldName: "Cost__c", type: "requiredColumn", editable: true,
      typeAttributes: {context: { fieldName: 'Id' }, value: { fieldName: 'Cost__c' }}  },
    
    { label: "Model", fieldName: "Model__c", editable: false,
      typeAttributes: {context: { fieldName: 'Id' }, value: { fieldName: 'Model__c' }}  },

    { label: "Serial Number", fieldName: "Serial_Number__c", editable: true,
      typeAttributes: {context: { fieldName: 'Id' }, value: { fieldName: 'Serial_Number__c' }}  } 
    /*,
    { label: "Meter Info", fieldName: "meterButton", type: "button", typeAttributes: 
    {label: "Meter Info", alternativeText: "Meter Info", variant: "brand", name: "meterInfo"}}*/
  ];

    @api recordId;
    @api rateFactorMsg;
    editable = true;
    isLoading = true;
    isEdit = false;
    isSaving = false;
    isNewAsset = false;
    refreshed = false;
    hasAdvancePayment = false;
    accountBillingState = "";
    showRateFactorMsg = false;
    defaultRecordTypeId;

    @track wiredResponse;
    @track assets = [];
    @track sessionId;
    saveDraftValues = [];
    picklistValues = [];
    manfacturerPicklistValues = [];
    EFMonthlyPayment = 0.00;
    rateFactorValue = 0.000000;
    intervalId;
    libInitialized = false;

    // PEAC New Pricing Changes - Start
    @track isPEACPricingDisclaimerOpen = false;
    @track peacPricingChangedFieldLabels = [];
    @track peacDisclaimerMessage = '';

    peacOriginalOpportunityValues = {};
    peacOriginalAssetsById = {};
    peacLeasePricingTrackedFields = [];
    peacLeasePricingTrackedFieldMap = {};
    peacPendingSavePayload = null;

    labels = {
      PEAC_DPPricingDisclaimerTitle,
      PEAC_DPPricingDisclaimerMessage,
      PEAC_DPOfferPricingSaveAndCalculate,
      PEAC_DPOfferPricingCancel,
      PEAC_DPPricingSaveSuccess,
      PEAC_DPOfferPricingSaveSuccessNoPricing,
      PEAC_DPOfferPricingNoChanges,
      PEAC_DPOfferPricingSaveError
    };

    connectedCallback() {
      this.peacLoadLeasePricingTrackedFields();
    }

    async peacLoadLeasePricingTrackedFields() {
      try {
        const trackedFields = await getLeasePricingTrackedFields();
        this.peacLeasePricingTrackedFields = trackedFields || [];
        this.peacLeasePricingTrackedFieldMap = {};

        this.peacLeasePricingTrackedFields.forEach(fieldConfig => {
          if (fieldConfig && fieldConfig.fieldApiName) {
            this.peacLeasePricingTrackedFieldMap[fieldConfig.fieldApiName] = fieldConfig;
          }
        });
      } catch (error) {
        console.log('PEAC New Pricing Changes - getLeasePricingTrackedFields error:', error);
      }
    }
    // PEAC New Pricing Changes - End

    /*connectedCallback(){
        hubExecute({methodName: "getAssets", parameters: [this.recordId]})
        .then((result)=>{
            //console.log("result json: ", result);
            let obj = JSON.parse(result);
            this.assets = obj.assets;
            this.accountBillingState = obj.oppInfo.Account_Billing_State_Province__c;
        })
        .catch((error)=>{
            showError(this, error);
        })
        .finally(()=>{ this.isLoading = false; });
    }*/

    /*cometdLoaded = false;
    @wire(getSessionId)
    wiredSessionId({ error, data }) {
      if(data){
        this.sessionId = data;
        loadScript(this, COMETD)
        .then(() => {
          this.initCometD();
        });
      }
    }

    initCometD() {
      if (this.libInitialized) {
        return;
      }
    
      this.libInitialized = true;

      const cometdLib = new window.org.cometd.CometD();
      cometdLib.configure({
        url: window.location.protocol + '//' + window.location.hostname + '/cometd/58.0/',
        requestHeaders: { Authorization: 'OAuth ' + this.sessionId},
        appendMessageTypeToURL : false,
        logLevel: 'debug'
      });

      cometdLib.websocketEnabled = false;
      cometdLib.handshake((handshakeReply) => {
        console.log(handshakeReply)
        if (handshakeReply.successful) {
          // Subscribe to a channel
          const subscription = cometdLib.subscribe('/event/SL_BW_Integration_Status__e', (message) => {
            console.log('message', message)
            if(this.recordId == message.data.payload.Record_Id__c){
              this.refresh(false);
            }
          });
          console.log('subscription',subscription);
        }
      });
    }*/

    @wire(getRecord, {
      recordId: "$recordId",
      fields
    })
    opportunityrec;

    //if there's no record type available on the object use the default 'null' Id 012000000000000AAA.
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: EQUIPMENT_CODE_FIELD })
    wiredPicklist({ error, data }){
      if(data){
        data?.values?.map(item => {
          this.picklistValues.push({
            label: item.value,
            value: item.value
          });
        });
        this.setEquipmentCodeOptions();
      } else if (error) {
        
      }
  }
 
  @wire(hubExecute, {methodName: "getAssets", parameters: '$recordId'})
    wiredData(result){
      this.wiredResponse = result;
      if(result.data){
        let obj = JSON.parse(result.data);
        this.assets = obj.assets;
        // PEAC New Pricing Changes - Start
        this.peacCaptureOriginalAssets(this.assets);
        // PEAC New Pricing Changes - End
        this.accountBillingState = obj.oppInfo.Account_Billing_State_Province__c;
        this.EFMonthlyPayment = obj.oppInfo?.EF_Approved_Offers__c ? obj.oppInfo.EF_Approved_Offers__r?.Monthly_Payment__c : '0.00';
        this.isEditable(obj.oppInfo.StageName);
        this.isLoading = false;
        this.refreshed = false;
        this.clearIntervalRefresh();
        this.defaultRecordTypeId = '012000000000000AAA';
       // let rateFactorValue = obj.oppInfo?.EF_Approved_Offers__c ? obj.oppInfo.Offer_Rate_Factor__c : '0.000000';
        //let roundedRateFactor = Number(rateFactorValue.toFixed(5)); // 123.46
        this.rateFactorValue = obj.oppInfo?.EF_Approved_Offers__c ? Number(obj.oppInfo.Offer_Rate_Factor__c.toFixed(5)) : '0.000000';
        this.displayMsgForRateFactor(this.rateFactorValue);
      }else if(result.error){
        showError(this, error);
        this.isLoading = false;
      }
    }

    setEquipmentCodeOptions(){
      this.assets.map(item => {
        item.Equipment_Code_Options = this.picklistValues;
      });
    }


    setManufacturerOptions(){
      this.assets.map(item => {
        item.Manufacturer_Options = this.manfacturerPicklistValues;
      });
    }

    handleLoad(event){
      this.isLoading = false;
      let hasAdvancePaymentInput = this.template.querySelector('lightning-input-field.hasAdvancePayment');
      if(hasAdvancePaymentInput){
          this.hasAdvancePayment = hasAdvancePaymentInput.value;
      }else{
          let recordObj = event.detail.records[this.recordId];
          this.hasAdvancePayment = recordObj? recordObj.fields.CA_Advance_Payment__c?.value: false;
      }
      // PEAC New Pricing Changes - Start
      this.peacCaptureOriginalOpportunityValues(event);
      // PEAC New Pricing Changes - End

      console.log("this.hasAdvancePayment onload: ", this.hasAdvancePayment);
    }

    handleEdit(){
        this.isEdit = true;
        this.isLoading = true;
    }

    handleAdvancePayment(event){
        this.hasAdvancePayment = event.target.value;
        console.log("this.hasAdvancePayment onchange: ", this.hasAdvancePayment);
    }

    handleCancel(event){
      // PEAC New Pricing Changes - Start
      if (event) {
        event.preventDefault();
      }

      this.isEdit = false;
      this.isSaving = false;
      this.isLoading = false;
      this.peacPendingSavePayload = null;
      this.peacPricingChangedFieldLabels = [];
      this.peacDisclaimerMessage = '';

      this.peacClearDraftValues();
      // PEAC New Pricing Changes - End
    }

    handleSubmit(event){
      //event.detail.fields.Purchase_Options__c != "FMV"
      // && (this.accountBillingState == "CA"
      // || this.accountBillingState == "UT"
      // || this.accountBillingState == "NY")
      event.preventDefault();   
      let fields = event.detail.fields;
      console.log('fields:',JSON.stringify(fields));
      console.log(fields.Max_Term_Approved__c , ' handleSubmit if ',fields.Terms__c);
        if(fields.Cost__c == '0' || fields.Cost__c == ''){
          console.log('handleSubmit if');
            event.preventDefault();
            showError(this, "The Equipment Cost is required, please enter a valid Cost and try again.");
        } else if(fields.Terms__c > fields.Max_Term_Approved__c){
          //showError(this, "You are not allow to change the term, please enter a valid term and try again.");
          showError(this, "Entered Term cannot be greater than Approved Term, Please enter the correct term.");
        } else{
          /*console.log('handleSubmit else');
          let totalAmt = parseFloat(fields.Cost__c);
          this.assets.map(item => {
            totalAmt  = totalAmt + item.Cost__c;
          });
          let approvedAmt = getFieldValue(this.opportunityrec.data, ApprovedAmount);
          console.log('approvedAmt:',approvedAmt);
          console.log('totalAmt:',totalAmt);
          let approvedAmtPer = (approvedAmt*10/100)+approvedAmt;
          console.log(approvedAmt,' approvedAmtPer:',approvedAmtPer);
          console.log('per:',(approvedAmt*10/100));*/

          let approvedAmt = getFieldValue(this.opportunityrec.data, ApprovedAmount);
          let totalAmt = 0;    
          console.log('fields.Cost__c:',fields.Cost__c);
          totalAmt = totalAmt + parseFloat(fields.Cost__c);
          console.log('totalAmt:',totalAmt);
          this.assets.map(item => {
            console.log('item.Cost__c:',item.Cost__c);
            if(item.Cost__c){
              totalAmt  = totalAmt + item.Cost__c;
            }
          });
          let approvedAmtPer = (approvedAmt*10/100)+approvedAmt;
          console.log(totalAmt,' approvedAmtPer:',approvedAmtPer);
          if(approvedAmtPer && approvedAmtPer < totalAmt){
            console.log('approvedAmt < totalAmt');
            this.isSaving = false;
            //showError(this, "The Equipment Cost shouldn\'t be greater than Approved Amount, please enter a valid Cost and try again.");
           // showError(this, "Entered Term cannot be greater than Approved Term, Please enter the correct term");
            showError(this,"Entered Cost cannot be greater than 10% of the approved amount, Please enter the correct Cost.");
          }  else{
            console.log('approvedAmt > totalAmt', fields.Cost__c);
            this.isSaving = true;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
          }
        }
        
    }

    handleError(event){
      console.log('handleSubmit error', JSON.stringify(event));
      showError(this, event);
      this.isSaving = false;
    }

    handleSuccess(event){
      console.log('handleSubmit success');
      this.isEdit = false;
      this.isSaving = false;
      this.isLoading = true;
      this.refresh();
    }

    handleMeterInfo(event){
      if(event.detail.name == "meterInfo"){

      }
    }

    handleSaveDT(event) {
      event.preventDefault();   
      let approvedAmt = getFieldValue(this.opportunityrec.data, ApprovedAmount);
      console.log('approvedAmt:',approvedAmt);
      this.saveDraftValues = event.detail.draftValues;
      let isValidCost = true;
      let totalAmt = 0;
      let draftIds = [];
      this.saveDraftValues.forEach(draft=>{
        console.log('draft ',JSON.stringify(draft));
        draftIds.push(draft.Id);
        if(isValidCost && draft.Cost__c == '0' || draft.Cost__c == ''){
          isValidCost = false;
          
        } else {
          console.log('draft.Cost__c:',draft.Cost__c);
          totalAmt = totalAmt + parseFloat(draft.Cost__c);
        }
      });
      console.log('draftIds:',draftIds);
      this.assets.map(item => {
        console.log(item.Id,' dfghjk ',item.Id.includes(draftIds));
        if(!draftIds.includes(item.Id)){
          totalAmt  = totalAmt + item.Cost__c;
        }
      });
      console.log('totalAmt:',totalAmt)
      let approvedAmtPer = (approvedAmt*10/100)+approvedAmt;
      console.log(approvedAmt,' approvedAmtPer:',approvedAmtPer);
      console.log('per:',(approvedAmt*100));
      if(approvedAmtPer && approvedAmtPer < totalAmt){
        //showError(this, "The Equipment Cost shouldn\'t be greater than Approved Amount, please enter a valid Cost and try again.");
        //showError(this, "Entered Term cannot be greater than Approved Term, Please enter the correct term");
        showError(this,"Entered Cost cannot be greater than 10% of the approved amount, Please enter the correct Cost.");
      } else {
        if(isValidCost){
          const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
          });
          event.target.isLoading = true;
          event.target.suppressBottomBar = true;
          const promises = recordInputs.map(recordInput => updateRecord(recordInput));
          Promise.all(promises).then(res => {
            this.dispatchEvent(showToast('Success', 'Records Updated Successfully!', 'success'));
            return this.refresh();
          }).catch(error => {
            console.log('error:',error);
            this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "), 'error'));
          }).finally(() => {
            this.saveDraftValues = [];
            const assetDatatable = this.template.querySelector("c-sl_-custom-data-table-type[data-name=assetTable]");
            assetDatatable.isLoading = false;
            assetDatatable.suppressBottomBar = false;
          });
        }else{
          showError(this, "The Equipment Cost is required, please enter a valid Cost and try again.");
        }
    }
    }

    // PEAC New Pricing Changes - Start
    /*
     * New unified Save handler for Experience Cloud pricing changes.
     * HTML Save button should call this method.
     * Existing production handlers are left in place until the HTML flow fully uses this unified save.
     */
    handlePEACUnifiedSave(event) {
      if (event) {
        event.preventDefault();
      }

      const opportunityChanges = this.peacBuildOpportunityChanges();
      const assetChanges = this.peacBuildAssetChanges();

      this.peacPrepareSave(opportunityChanges, assetChanges, false);
    }

    handlePEACNewAssetSubmit(event) {
      event.preventDefault();
      const fields = Object.assign({}, event.detail.fields);

      if (fields.Cost__c === '0' || fields.Cost__c === 0 || fields.Cost__c === '' || fields.Cost__c === null || fields.Cost__c === undefined) {
        showError(this, "The Equipment Cost is required, please enter a valid Cost and try again.");
        return;
      }

      const assetChanges = [{
        action: 'INSERT',
        fields: fields
      }];

      this.peacPrepareSave({}, assetChanges, true);
    }

    peacPrepareSave(opportunityChanges, assetChanges, isNewAssetSave) {
      const hasOpportunityChanges = Object.keys(opportunityChanges || {}).length > 0;
      const hasAssetChanges = (assetChanges || []).length > 0;

      if (!hasOpportunityChanges && !hasAssetChanges) {
        this.dispatchEvent(showToast('Info', this.labels.PEAC_DPOfferPricingNoChanges, 'info'));
        return;
      }

      const validationMessage = this.peacValidateUnifiedSave(assetChanges, opportunityChanges);
      if (validationMessage) {
        showError(this, validationMessage);
        return;
      }

      const pricingImpactResult = this.peacGetPricingImpactResult(opportunityChanges, assetChanges);

      this.peacPendingSavePayload = {
        opportunityId: this.recordId,
        opportunityChanges: opportunityChanges,
        assetChanges: assetChanges,
        shouldStartPricing: pricingImpactResult.hasPricingImpact,
        isNewAssetSave: isNewAssetSave === true
      };

      if (pricingImpactResult.hasPricingImpact) {
        this.peacPricingChangedFieldLabels = pricingImpactResult.changedLabels;
        this.peacDisclaimerMessage = this.peacFormatLabel(
          this.labels.PEAC_DPPricingDisclaimerMessage,
          pricingImpactResult.changedLabels.join(', ')
        );
        this.isPEACPricingDisclaimerOpen = true;
      } else {
        this.peacExecuteUnifiedSave();
      }
    }

    handlePEACPricingDisclaimerCancel() {
      this.isPEACPricingDisclaimerOpen = false;
      this.peacPendingSavePayload = null;
      this.peacPricingChangedFieldLabels = [];
      this.peacDisclaimerMessage = '';
    }

    handlePEACPricingDisclaimerConfirm() {
      this.isPEACPricingDisclaimerOpen = false;
      this.peacExecuteUnifiedSave();
    }

    async peacExecuteUnifiedSave() {
      if (!this.peacPendingSavePayload) {
        return;
      }

      const payload = {
        opportunityId: this.peacPendingSavePayload.opportunityId,
        opportunityChanges: this.peacPendingSavePayload.opportunityChanges,
        assetChanges: this.peacPendingSavePayload.assetChanges,
        shouldStartPricing: this.peacPendingSavePayload.shouldStartPricing
      };
      const isNewAssetSave = this.peacPendingSavePayload.isNewAssetSave === true;

      this.isSaving = true;
      this.isLoading = true;

      try {
        const result = await saveOfferChanges(payload);

        if (result && result.success) {
          const successMessage = result.pricingStarted
            ? this.labels.PEAC_DPPricingSaveSuccess
            : this.labels.PEAC_DPOfferPricingSaveSuccessNoPricing;

          this.dispatchEvent(showToast('Success', successMessage, 'success'));

          this.peacClearDraftValues();
          this.isEdit = false;
          if (isNewAssetSave) {
            this.isNewAsset = false;
          }
          await this.refresh(false);
        } else {
          const errorMessage = result && result.message ? result.message : this.labels.PEAC_DPOfferPricingSaveError;
          this.dispatchEvent(showToast('Error', errorMessage, 'error'));
        }
      } catch (error) {
        console.log('PEAC New Pricing Changes - saveOfferChanges error:', error);
        this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "), 'error'));
      } finally {
        this.isSaving = false;
        this.isLoading = false;
        this.peacPendingSavePayload = null;
        this.peacPricingChangedFieldLabels = [];
        this.peacDisclaimerMessage = '';
      }
    }

    peacBuildOpportunityChanges() {
      const opportunityChanges = {};
      const inputFields = this.template.querySelectorAll('lightning-record-edit-form[object-api-name="Opportunity"] lightning-input-field');

      if (!inputFields) {
        return opportunityChanges;
      }

      inputFields.forEach(inputField => {
        const fieldApi = inputField.fieldName || inputField.getAttribute('field-name');

        if (!fieldApi || fieldApi === 'Id') {
          return;
        }

        const newValue = inputField.value;
        const oldValue = this.peacOriginalOpportunityValues[fieldApi];

        if (!this.peacAreValuesEqual(oldValue, newValue)) {
          opportunityChanges[fieldApi] = newValue;
        }
      });

      return opportunityChanges;
    }

    peacBuildAssetChanges() {
      const assetChanges = [];
      const draftValues = this.peacGetAssetDraftValues();

      draftValues.forEach(draft => {
        if (!draft || !draft.Id) {
          return;
        }

        const fields = {};

        Object.keys(draft).forEach(fieldApi => {
          if (fieldApi === 'Id') {
            return;
          }

          const originalAsset = this.peacOriginalAssetsById[draft.Id] || {};
          const oldValue = originalAsset[fieldApi];
          const newValue = draft[fieldApi];

          if (!this.peacAreValuesEqual(oldValue, newValue)) {
            fields[fieldApi] = newValue;
          }
        });

        if (Object.keys(fields).length > 0) {
          assetChanges.push({
            action: 'UPDATE',
            recordId: draft.Id,
            fields: fields
          });
        }
      });

      return assetChanges;
    }

    peacGetAssetDraftValues() {
      let draftValues = [];

      const assetDatatable = this.template.querySelector("c-sl_-custom-data-table-type[data-name=assetTable]");

      if (assetDatatable && assetDatatable.draftValues && assetDatatable.draftValues.length > 0) {
        draftValues = assetDatatable.draftValues;
      } else if (this.saveDraftValues && this.saveDraftValues.length > 0) {
        draftValues = this.saveDraftValues;
      }

      return JSON.parse(JSON.stringify(draftValues || []));
    }

    peacGetPricingImpactResult(opportunityChanges, assetChanges) {
      const changedLabels = [];

      Object.keys(opportunityChanges || {}).forEach(fieldApi => {
        if (this.peacLeasePricingTrackedFieldMap[fieldApi]) {
          changedLabels.push(this.peacLeasePricingTrackedFieldMap[fieldApi].fieldLabel || fieldApi);
        }
      });

      const hasAssetPricingImpact = (assetChanges || []).some(change => {
        if (!change) {
          return false;
        }

        if (change.action === 'INSERT' || change.action === 'DELETE') {
          return true;
        }

        return change.fields && Object.prototype.hasOwnProperty.call(change.fields, 'Cost__c');
      });

      if (hasAssetPricingImpact) {
        changedLabels.push('Asset Cost');
      }

      const uniqueLabels = [...new Set(changedLabels)];

      return {
        hasPricingImpact: uniqueLabels.length > 0,
        changedLabels: uniqueLabels
      };
    }

    peacValidateUnifiedSave(assetChanges, opportunityChanges) {
      const termValue = opportunityChanges && Object.prototype.hasOwnProperty.call(opportunityChanges, 'Terms__c')
        ? opportunityChanges.Terms__c
        : this.peacGetOpportunityInputValue('Terms__c');
      const maxTermValue = this.peacGetOpportunityInputValue('Max_Term_Approved__c');

      if (termValue && maxTermValue && parseFloat(termValue) > parseFloat(maxTermValue)) {
        return 'Entered Term cannot be greater than Approved Term, Please enter the correct term.';
      }

      const approvedAmt = getFieldValue(this.opportunityrec.data, ApprovedAmount);
      let totalAmt = 0;
      let isValidCost = true;

      const draftCostByAssetId = {};
      const deletedAssetIds = new Set();
      const insertAssetCosts = [];

      (assetChanges || []).forEach(change => {
        if (!change) {
          return;
        }

        if (change.action === 'UPDATE' && change.recordId && change.fields && Object.prototype.hasOwnProperty.call(change.fields, 'Cost__c')) {
          draftCostByAssetId[change.recordId] = change.fields.Cost__c;
        } else if (change.action === 'DELETE' && change.recordId) {
          deletedAssetIds.add(change.recordId);
        } else if (change.action === 'INSERT' && change.fields && Object.prototype.hasOwnProperty.call(change.fields, 'Cost__c')) {
          insertAssetCosts.push(change.fields.Cost__c);
        }
      });

      this.assets.forEach(asset => {
        if (deletedAssetIds.has(asset.Id)) {
          return;
        }

        let costValue = Object.prototype.hasOwnProperty.call(draftCostByAssetId, asset.Id)
          ? draftCostByAssetId[asset.Id]
          : asset.Cost__c;

        if (costValue === '0' || costValue === 0 || costValue === '' || costValue === null || costValue === undefined) {
          isValidCost = false;
        } else {
          totalAmt = totalAmt + parseFloat(costValue);
        }
      });

      insertAssetCosts.forEach(costValue => {
        if (costValue === '0' || costValue === 0 || costValue === '' || costValue === null || costValue === undefined) {
          isValidCost = false;
        } else {
          totalAmt = totalAmt + parseFloat(costValue);
        }
      });

      if (!isValidCost) {
        return 'The Equipment Cost is required, please enter a valid Cost and try again.';
      }

      const approvedAmtPer = (approvedAmt * 10 / 100) + approvedAmt;

      if (approvedAmtPer && approvedAmtPer < totalAmt) {
        return 'Entered Cost cannot be greater than 10% of the approved amount, Please enter the correct Cost.';
      }

      return null;
    }

    peacGetOpportunityInputValue(fieldApi) {
      const inputField = this.template.querySelector(`lightning-record-edit-form[object-api-name="Opportunity"] lightning-input-field[field-name="${fieldApi}"]`);
      return inputField ? inputField.value : null;
    }

    peacCaptureOriginalOpportunityValues(event) {
      try {
        this.peacOriginalOpportunityValues = {};

        if (!event || !event.detail || !event.detail.records || !event.detail.records[this.recordId]) {
          return;
        }

        const recordObj = event.detail.records[this.recordId];

        if (!recordObj.fields) {
          return;
        }

        Object.keys(recordObj.fields).forEach(fieldApi => {
          this.peacOriginalOpportunityValues[fieldApi] = recordObj.fields[fieldApi]
            ? recordObj.fields[fieldApi].value
            : null;
        });
      } catch (error) {
        console.log('PEAC New Pricing Changes - peacCaptureOriginalOpportunityValues error:', error);
      }
    }

    peacCaptureOriginalAssets(assetRows) {
      this.peacOriginalAssetsById = {};

      (assetRows || []).forEach(asset => {
        if (asset && asset.Id) {
          this.peacOriginalAssetsById[asset.Id] = JSON.parse(JSON.stringify(asset));
        }
      });
    }

    peacClearDraftValues() {
      this.saveDraftValues = [];

      const assetDatatable = this.template.querySelector("c-sl_-custom-data-table-type[data-name=assetTable]");

      if (assetDatatable) {
        assetDatatable.draftValues = [];
        assetDatatable.isLoading = false;
        assetDatatable.suppressBottomBar = true;
      }
    }

    peacAreValuesEqual(oldValue, newValue) {
      const normalizedOldValue = this.peacNormalizeComparableValue(oldValue);
      const normalizedNewValue = this.peacNormalizeComparableValue(newValue);

      return normalizedOldValue === normalizedNewValue;
    }

    peacNormalizeComparableValue(value) {
      if (value === null || value === undefined || value === '') {
        return '';
      }

      if (typeof value === 'number') {
        return String(Number(value));
      }

      if (!isNaN(value) && value !== true && value !== false) {
        return String(Number(value));
      }

      return String(value);
    }

    peacFormatLabel(labelValue, replacementValue) {
      if (!labelValue) {
        return replacementValue;
      }

      return labelValue.replace('{0}', replacementValue);
    }
    // PEAC New Pricing Changes - End

    async refresh(runInterval = true) {
      if(runInterval){
        this.refreshed = true;
        this.intervalId = setInterval(async function() {
          await refreshApex(this.wiredResponse);
        }.bind(this), 10000);
        
        setTimeout(() => {
          this.clearIntervalRefresh();
          this.refreshed = false;
        }, 60000);
      }else{
        await refreshApex(this.wiredResponse);
      }

      this.setEquipmentCodeOptions();
      
    }

    clearIntervalRefresh(){
      clearInterval(this.intervalId);
    }

    isEditable(stageName){
      const DESCRIPTION_REQ_VALUES = {
        'Quote':  true,
        'Application':  true,
        'Decision':  true,
        'Proposal':  true,
        'Default':    false
      }; 

      this.editable  = DESCRIPTION_REQ_VALUES[stageName] || DESCRIPTION_REQ_VALUES['Default'];
      const cols  = this.COLUMNS.map(item => {
        if(item.fieldName === 'Name'){
          item.editable = false;
        }else{
          item.editable = true ? item.editable = this.editable : '';
        }
        return item
      })
      this.COLUMNS = [...cols];
    }

    displayMsgForRateFactor(rateFactor){
      if(rateFactor <= 0 && this.rateFactorMsg){
        this.showRateFactorMsg = true;
        //this.dispatchEvent(showToast( ' ', this.rateFactorMsg, 'info'));
      }else{
        this.showRateFactorMsg = false;
      }
    }

    handleNewAsset(){
      this.isNewAsset = true;
    }

    closeNewAsset(){
      this.isNewAsset = false;
    }

    handleAssetSuccess(){
      this.refresh();
      this.isNewAsset = false;
      this.isSaving = false;
      this.dispatchEvent(showToast('Success', 'Asset Created Successfully!', 'success'));
    }

    handleRefresh(){
      this.refreshed = true;
      setTimeout(() => {
        this.refreshed = false;
      }, 1000);
      this.refresh(false);
    }

    handleNewRecordSave(event){
      const inputFields = this.template.querySelectorAll(
        'lightning-input-field'
      );
      console.log('inputFields:',inputFields);
      if (inputFields) {
        
        inputFields.forEach(field => {
          //field.reset();
          console.log('field:',field);
        });
      }
    }
}