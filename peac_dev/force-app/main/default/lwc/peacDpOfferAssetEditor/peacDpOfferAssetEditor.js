import { LightningElement, api, track } from 'lwc';

export default class PeacDpOfferAssetEditor extends LightningElement {
    @api assets = [];
    @api isReadOnly = false;

    get visibleAssets() {
        return (this.assets || [])
            .filter(asset => !asset.isDeleted)
            .map((asset, index) => {
                return {
                    ...asset,
                    rowNumber: index + 1,
                    clientKey: asset.clientKey || asset.id,
                    equipmentCode: asset.equipmentCode || '',
                    cost: asset.cost,
                    model: asset.model || '',
                    serialNumber: asset.serialNumber || ''
                };
            });
    }

    get showDeleteColumn() {
        return !this.isReadOnly && this.visibleAssets.length > 1;
    }

    handleFieldChange(event) {
        if (this.isReadOnly) {
            return;
        }

        const clientKey = event.target.dataset.key;
        const fieldName = event.target.dataset.field;
        const value = event.target.value;

        const existingAsset = this.visibleAssets.find(asset => asset.clientKey === clientKey);

        if (!existingAsset || !fieldName) {
            return;
        }

        this.dispatchEvent(new CustomEvent('assetchange', {
            detail: {
                ...existingAsset,
                [fieldName]: value,
                isModified: true
            }
        }));
    }

    handleDelete(event) {
        if (this.isReadOnly) {
            return;
        }

        const clientKey = event.target.dataset.key;
        const existingAsset = this.visibleAssets.find(asset => asset.clientKey === clientKey);

        if (!existingAsset) {
            return;
        }

        this.dispatchEvent(new CustomEvent('assetdelete', {
            detail: existingAsset
        }));
    }
}