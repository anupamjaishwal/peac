import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { showToast, reduceErrors } from 'c/sl_Utils';

import getOfferData from '@salesforce/apex/PEAC_DPOfferSaveService.getOfferData';
import getLeasePricingTrackedFields from '@salesforce/apex/PEAC_DPOfferSaveService.getLeasePricingTrackedFields';
import saveOfferChanges from '@salesforce/apex/PEAC_DPOfferSaveService.saveOfferChanges';
import getLatestPricingResultStatus from '@salesforce/apex/PEAC_DPOfferSaveService.getLatestPricingResultStatus';

import PEAC_DPPricingDisclaimerTitle from '@salesforce/label/c.PEAC_DPPricingDisclaimerTitle';
import PEAC_DPPricingDisclaimerMessage from '@salesforce/label/c.PEAC_DPPricingDisclaimerMessage';
import PEAC_DPOfferPricingSaveAndCalculate from '@salesforce/label/c.PEAC_DPOfferPricingSaveAndCalculate';
import PEAC_DPOfferPricingCancel from '@salesforce/label/c.PEAC_DPOfferPricingCancel';
import PEAC_DPPricingSaveSuccess from '@salesforce/label/c.PEAC_DPPricingSaveSuccess';
import PEAC_DPOfferPricingSaveSuccessNoPricing from '@salesforce/label/c.PEAC_DPOfferPricingSaveSuccessNoPricing';
import PEAC_DPOfferPricingNoChanges from '@salesforce/label/c.PEAC_DPOfferPricingNoChanges';
import PEAC_DPOfferPricingSaveError from '@salesforce/label/c.PEAC_DPOfferPricingSaveError';

export default class PeacDpOfferPricing extends LightningElement {
    @api recordId;
    @api rateFactorMsg;

    @track draftOffer = {};
    @track draftAssets = [];

    isLoading = true;
    isSaving = false;
    isAssetSaving = false;
    isDisclaimerOpen = false;
    isEditMode = false;
    showNewAssetModal = false;
    showRateFactorMsg = false;
    showPricingResultBanner = false;
    hasInitialized = false;

    latestPricingResult;
    originalOffer = {};
    originalAssetsById = {};
    trackedFieldMap = {};
    pendingPayload;
    disclaimerMessage = '';

    labels = {
        disclaimerTitle: PEAC_DPPricingDisclaimerTitle,
        disclaimerMessage: PEAC_DPPricingDisclaimerMessage,
        saveAndCalculate: PEAC_DPOfferPricingSaveAndCalculate,
        cancel: PEAC_DPOfferPricingCancel,
        saveSuccess: PEAC_DPPricingSaveSuccess,
        saveSuccessNoPricing: PEAC_DPOfferPricingSaveSuccessNoPricing,
        noChanges: PEAC_DPOfferPricingNoChanges,
        saveError: PEAC_DPOfferPricingSaveError
    };

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (!this.recordId && pageRef) {
            this.recordId = pageRef.attributes?.recordId || pageRef.state?.recordId || this.getRecordIdFromUrl();
        }

        if (this.recordId && !this.hasInitialized) {
            this.initializeComponent();
        }
    }

    connectedCallback() {
        if (!this.recordId) {
            this.recordId = this.getRecordIdFromUrl();
        }

        if (this.recordId && !this.hasInitialized) {
            this.initializeComponent();
        }
    }

    get isReadOnly() {
        return !this.isEditMode;
    }

    get rateFactorDisplay() {
        return this.draftOffer.rateFactor === null || this.draftOffer.rateFactor === undefined
            ? '0.00000'
            : Number(this.draftOffer.rateFactor).toFixed(5);
    }

    get purchaseOptionDisplay() {
        return this.draftOffer.purchaseOption || '-';
    }

    get pricingResultUrl() {
        if (!this.latestPricingResult || !this.latestPricingResult.pricingResultId) {
            return null;
        }

        return '/' + this.latestPricingResult.pricingResultId;
    }

    get pricingResultTitle() {
        if (!this.latestPricingResult || !this.latestPricingResult.hasPricingResult) {
            return '';
        }

        return this.latestPricingResult.pricingResultStatus === 'Error'
            ? 'Pricing calculation failed'
            : 'Pricing calculation status: ' + this.latestPricingResult.pricingResultStatus;
    }

    get pricingResultBannerClass() {
        if (this.latestPricingResult && this.latestPricingResult.pricingResultStatus === 'Error') {
            return 'pricing-result-banner pricing-result-error';
        }

        return 'pricing-result-banner pricing-result-success';
    }

    getRecordIdFromUrl() {
        const match = (window.location.pathname || '').match(/\/opportunity\/(006[A-Za-z0-9]{12,15})/);
        return match ? match[1] : null;
    }

    async initializeComponent() {
        this.hasInitialized = true;
        this.isLoading = true;

        try {
            await Promise.all([this.loadOfferData(), this.loadTrackedFields()]);
        } catch (error) {
            this.dispatchEvent(showToast('Error', reduceErrors(error).join(', '), 'error'));
        } finally {
            this.isLoading = false;
        }
    }

    async loadOfferData() {
        const data = await getOfferData({ opportunityId: this.recordId });

        this.originalOffer = JSON.parse(JSON.stringify(data));
        this.draftOffer = JSON.parse(JSON.stringify(data));
        this.draftAssets = JSON.parse(JSON.stringify(data.assets || []));

        this.originalAssetsById = {};
        this.draftAssets.forEach(asset => {
            if (asset.id) {
                this.originalAssetsById[asset.id] = JSON.parse(JSON.stringify(asset));
            }
        });

        this.showRateFactorMsg = Number(data.rateFactor || 0) <= 0 && this.rateFactorMsg;
    }

    async loadTrackedFields() {
        const fields = await getLeasePricingTrackedFields();
        this.trackedFieldMap = {};

        (fields || []).forEach(field => {
            if (field.fieldApiName) {
                this.trackedFieldMap[field.fieldApiName] = field;
            }
        });
    }

    handleEditOffer() {
        this.isEditMode = true;
    }

    handleCancel() {
        this.draftOffer = JSON.parse(JSON.stringify(this.originalOffer));
        this.draftAssets = JSON.parse(JSON.stringify(this.originalOffer.assets || []));
        this.isEditMode = false;
    }

    async handleRefresh() {
        this.isEditMode = false;
        this.isLoading = true;

        try {
            await this.loadOfferData();
        } catch (error) {
            this.dispatchEvent(showToast('Error', reduceErrors(error).join(', '), 'error'));
        } finally {
            this.isLoading = false;
        }
    }

    handleOpenNewAssetModal() {
        this.showNewAssetModal = true;
    }

    handleCloseNewAssetModal() {
        this.showNewAssetModal = false;
        this.isAssetSaving = false;
    }

    handleNewAssetSubmit(event) {
        event.preventDefault();

        const fields = event.detail.fields;
        fields.Opportunity__c = this.recordId;

        if (fields.Cost__c === null || fields.Cost__c === undefined || fields.Cost__c === '' || Number(fields.Cost__c) === 0) {
            this.dispatchEvent(showToast('Error', 'The Equipment Cost is required, please enter a valid Cost and try again.', 'error'));
            return;
        }

        let totalAmount = Number(fields.Cost__c || 0);

        this.draftAssets.forEach(asset => {
            if (!asset.isDeleted && asset.cost) {
                totalAmount += Number(asset.cost);
            }
        });

        const approvedAmount = Number(this.draftOffer.approvedAmount || 0);
        const approvedAmountWithTolerance = approvedAmount + (approvedAmount * 10 / 100);

        if (approvedAmountWithTolerance && approvedAmountWithTolerance < totalAmount) {
            this.dispatchEvent(showToast('Error', 'Entered Cost cannot be greater than 10% of the approved amount, Please enter the correct Cost.', 'error'));
            return;
        }

        this.isAssetSaving = true;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    async handleNewAssetSuccess() {
        this.showNewAssetModal = false;
        this.isAssetSaving = false;
        this.dispatchEvent(showToast('Success', 'Asset Created Successfully!', 'success'));
        await this.loadOfferData();
    }

    handleNewAssetError(event) {
        this.isAssetSaving = false;
        const message = event?.detail?.message || 'Unable to create Asset.';
        this.dispatchEvent(showToast('Error', message, 'error'));
    }

    handleOpportunityChange(event) {
        const dtoField = this.mapOpportunityFieldToDto(event.target.dataset.field);
        if (dtoField) {
            this.draftOffer = { ...this.draftOffer, [dtoField]: event.target.value };
        }
    }

    handleAssetChange(event) {
        if (this.isReadOnly) {
            return;
        }

        const changedAsset = event.detail;

        this.draftAssets = this.draftAssets.map(asset => {
            const assetKey = asset.clientKey || asset.id;
            const changedKey = changedAsset.clientKey || changedAsset.id;

            return assetKey === changedKey
                ? { ...asset, ...changedAsset, isModified: true }
                : asset;
        });
    }

    handleAssetDelete(event) {
        if (this.isReadOnly) {
            return;
        }

        const activeAssets = this.draftAssets.filter(asset => !asset.isDeleted);
        if (activeAssets.length <= 1) {
            this.dispatchEvent(showToast('Error', 'At least one asset is required.', 'error'));
            return;
        }

        const assetToDelete = event.detail;

        this.draftAssets = this.draftAssets.map(asset => {
            const assetKey = asset.clientKey || asset.id;
            const deleteKey = assetToDelete.clientKey || assetToDelete.id;

            return assetKey === deleteKey
                ? { ...asset, isDeleted: true }
                : asset;
        });
    }

    handleSave() {
        const opportunityChanges = this.buildOpportunityChanges();
        const assetChanges = this.buildAssetChanges();

        if (Object.keys(opportunityChanges).length === 0 && assetChanges.length === 0) {
            this.dispatchEvent(showToast('Info', this.labels.noChanges, 'info'));
            return;
        }

        const validationMessage = this.validateSave();
        if (validationMessage) {
            this.dispatchEvent(showToast('Error', validationMessage, 'error'));
            return;
        }

        const pricingImpact = this.getPricingImpact(opportunityChanges, assetChanges);

        this.pendingPayload = {
            opportunityId: this.recordId,
            opportunityChanges,
            assetChanges,
            shouldStartPricing: pricingImpact.hasPricingImpact
        };

        if (pricingImpact.hasPricingImpact) {
            this.disclaimerMessage = this.formatLabel(this.labels.disclaimerMessage, pricingImpact.labels.join(', '));
            this.isDisclaimerOpen = true;
        } else {
            this.executeSave();
        }
    }

    handleDisclaimerCancel() {
        this.isDisclaimerOpen = false;
        this.pendingPayload = null;
        this.disclaimerMessage = '';
    }

    handleDisclaimerConfirm() {
        this.isDisclaimerOpen = false;
        this.executeSave();
    }

    async executeSave() {
        if (!this.pendingPayload) {
            return;
        }

        this.isSaving = true;
        this.isLoading = true;
        this.showPricingResultBanner = false;
        this.latestPricingResult = null;

        try {
            const result = await saveOfferChanges(this.pendingPayload);

            if (result && result.success) {
                if (result.pricingStarted) {
                    const pricingResult = await this.waitForPricingResult();

                    if (pricingResult) {
                        this.dispatchEvent(showToast('Success', 'Changes saved and pricing result created.', 'success'));
                    } else {
                        this.dispatchEvent(showToast('Info', 'Changes saved. Pricing calculation has started. Refresh shortly to see the result.', 'info'));
                    }
                } else {
                    this.dispatchEvent(showToast('Success', this.labels.saveSuccessNoPricing, 'success'));
                }

                await this.loadOfferData();
                this.isEditMode = false;
            } else {
                this.dispatchEvent(showToast('Error', result?.message || this.labels.saveError, 'error'));
            }
        } catch (error) {
            this.dispatchEvent(showToast('Error', reduceErrors(error).join(', '), 'error'));
        } finally {
            this.isSaving = false;
            this.isLoading = false;
            this.pendingPayload = null;
            this.disclaimerMessage = '';
        }
    }

    async waitForPricingResult() {
        const maxAttempts = 10;
        const delayMs = 1500;

        for (let i = 0; i < maxAttempts; i++) {
            const result = await getLatestPricingResultStatus({ opportunityId: this.recordId });

            if (result && result.hasPricingResult) {
                this.latestPricingResult = result;
                this.showPricingResultBanner = true;
                return result;
            }

            await new Promise(resolve => window.setTimeout(resolve, delayMs));
        }

        return null;
    }

    buildOpportunityChanges() {
        const changes = {};
        const mappings = {
            requiredAdvancePayments: 'Required_Adv_Payments__c',
            term: 'Terms__c'
        };

        Object.keys(mappings).forEach(dtoField => {
            if (!this.areValuesEqual(this.originalOffer[dtoField], this.draftOffer[dtoField])) {
                changes[mappings[dtoField]] = this.draftOffer[dtoField];
            }
        });

        return changes;
    }

    buildAssetChanges() {
        const changes = [];

        this.draftAssets.forEach(asset => {
            if (asset.isDeleted && asset.id) {
                changes.push({ action: 'DELETE', recordId: asset.id, fields: {} });
                return;
            }

            if (asset.isDeleted) {
                return;
            }

            if (asset.isModified && asset.id) {
                const original = this.originalAssetsById[asset.id] || {};
                const fields = {};
                const fieldMap = this.assetDtoToFieldMap(asset);
                const originalFieldMap = this.assetDtoToFieldMap(original);

                Object.keys(fieldMap).forEach(fieldApi => {
                    if (!this.areValuesEqual(originalFieldMap[fieldApi], fieldMap[fieldApi])) {
                        fields[fieldApi] = fieldMap[fieldApi];
                    }
                });

                if (Object.keys(fields).length > 0) {
                    changes.push({ action: 'UPDATE', recordId: asset.id, fields });
                }
            }
        });

        return changes;
    }

    getPricingImpact(opportunityChanges, assetChanges) {
        const labels = [];

        Object.keys(opportunityChanges || {}).forEach(fieldApi => {
            if (this.trackedFieldMap[fieldApi]) {
                labels.push(this.trackedFieldMap[fieldApi].fieldLabel || fieldApi);
            }
        });

        (assetChanges || []).forEach(change => {
            if (change.action === 'DELETE') {
                labels.push('Asset Cost');
            }

            if (change.fields && Object.prototype.hasOwnProperty.call(change.fields, 'Cost__c')) {
                labels.push('Asset Cost');
            }
        });

        return {
            hasPricingImpact: labels.length > 0,
            labels: [...new Set(labels)]
        };
    }

    validateSave() {
        if (this.draftOffer.term && this.draftOffer.maxApprovedTerm) {
            if (Number(this.draftOffer.term) > Number(this.draftOffer.maxApprovedTerm)) {
                return 'Entered Term cannot be greater than Approved Term, Please enter the correct term.';
            }
        }

        let totalCost = 0;

        for (const asset of this.draftAssets) {
            if (asset.isDeleted) {
                continue;
            }

            if (asset.cost === null || asset.cost === undefined || asset.cost === '' || Number(asset.cost) === 0) {
                return 'The Equipment Cost is required, please enter a valid Cost and try again.';
            }

            totalCost += Number(asset.cost);
        }

        const approvedAmount = Number(this.draftOffer.approvedAmount || 0);
        const approvedAmountWithTolerance = approvedAmount + (approvedAmount * 10 / 100);

        if (approvedAmountWithTolerance && totalCost > approvedAmountWithTolerance) {
            return 'Entered Cost cannot be greater than 10% of the approved amount, Please enter the correct Cost.';
        }

        return null;
    }

    assetDtoToFieldMap(asset) {
        return {
            Equipment_Code__c: asset.equipmentCode,
            Cost__c: asset.cost,
            Serial_Number__c: asset.serialNumber,
            Model__c: asset.model
        };
    }

    mapOpportunityFieldToDto(fieldApi) {
        return {
            Required_Adv_Payments__c: 'requiredAdvancePayments',
            Terms__c: 'term'
        }[fieldApi];
    }

    areValuesEqual(value1, value2) {
        return this.normalizeValue(value1) === this.normalizeValue(value2);
    }

    normalizeValue(value) {
        if (value === null || value === undefined || value === '') {
            return '';
        }

        if (!isNaN(value)) {
            return String(Number(value));
        }

        return String(value);
    }

    formatLabel(labelValue, replacementValue) {
        return labelValue ? labelValue.replace('{0}', replacementValue) : replacementValue;
    }
}