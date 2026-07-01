/**
 * Developed by Suraj Harichandan(LTIMindtree) as a part of BugFix for SAL-5654
 * Modified by Suraj Harichandan(LTM) on 2026-03-27 — Refactored to async @future pattern.
 *     Button click now returns immediately, shows info toast, and polls via
 *     notifyRecordUpdateAvailable until the wire detects matching values.
 *
 * @description Auto-visible banner on the Opportunity record page.
 *              Compares Total_Asset_Residual__c (rollup) vs Residual__c (trigger-updated).
 *              If mismatch: shows red warning banner with inline "Resolve Residual" button.
 *              If match: renders nothing (fully hidden).
 *              Reactive to record changes via @wire(getRecord).
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TOTAL_ASSET_RESIDUAL from '@salesforce/schema/Opportunity.Total_Asset_Residual__c';
import RESIDUAL from '@salesforce/schema/Opportunity.Residual__c';
import resolveDiscrepancy from '@salesforce/apex/PEAC_ResidualDiscrepancyController.resolveResidualDiscrepancy';

// Added by Suraj Harichandan(LTM) on 2026-03-27 — Polling constants
const POLL_INTERVAL_MS = 2000;  // Check every 2 seconds
const POLL_TIMEOUT_MS = 15000;  // Give up after 15 seconds

export default class Peac_residualDiscrepancyBanner extends LightningElement {
    @api recordId;
    isResolving = false;

    // Added by Suraj Harichandan(LTM) on 2026-03-27 — Polling state
    _pollTimer = null;
    _pollTimeoutTimer = null;
    _wasResolvingWhenBannerHid = false;

    @wire(getRecord, { recordId: '$recordId', fields: [TOTAL_ASSET_RESIDUAL, RESIDUAL] })
    wiredOpportunity(value) {
        this.opportunity = value;
        // Added by Suraj Harichandan(LTM) on 2026-03-27 — Detect async resolution completion
        if (this._wasResolvingWhenBannerHid && !this.showBanner) {
            this._onAsyncResolutionComplete();
        }
    }
    opportunity;

    /**
     * Determines whether to show the discrepancy banner.
     * Compares rounded values (2 decimal places) of rollup vs residual.
     */
    get showBanner() {
        if (!this.opportunity?.data) return false;
        return this.rollupValue !== this.residualValue;
    }

    /** Rollup summary field value rounded to 2 decimals */
    get rollupValue() {
        return Math.round((getFieldValue(this.opportunity.data, TOTAL_ASSET_RESIDUAL) || 0) * 100) / 100;
    }

    /** Trigger-updated Residual field value rounded to 2 decimals */
    get residualValue() {
        return Math.round((getFieldValue(this.opportunity.data, RESIDUAL) || 0) * 100) / 100;
    }

    /** Warning message displayed in the banner */
    get discrepancyMessage() {
        return `Residual ($${this.residualValue}) does not match the Sum of Asset Residuals ($${this.rollupValue}). This is typically caused by validation rules preventing field updates on the Opportunity.`;
    }

    /**
     * Modified by Suraj Harichandan(LTM) on 2026-03-27
     * Handler for the "Resolve Residual" button.
     * Calls the Apex dispatcher which enqueues an @future method,
     * shows a dismissible info toast, and starts polling for completion.
     */
    async handleResolve() {
        this.isResolving = true;
        try {
            const result = await resolveDiscrepancy({ opportunityId: this.recordId });

            if (result.status === 'no_discrepancy') {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'No Discrepancy',
                    message: result.message,
                    variant: 'info',
                    mode: 'dismissible'
                }));
                this.isResolving = false;
                await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                return;
            }

            if (result.status === 'error') {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: result.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.isResolving = false;
                return;
            }

            // status === 'processing' — @future enqueued successfully
            this.dispatchEvent(new ShowToastEvent({
                title: 'Recalculation in Progress',
                message: 'The residual is being recalculated. The banner will disappear once complete.',
                variant: 'info',
                mode: 'dismissible'
            }));

            this._wasResolvingWhenBannerHid = true;
            this._startPolling();

        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'An unexpected error occurred.',
                variant: 'error'
            }));
            this.isResolving = false;
        }
    }

    /**
     * Added by Suraj Harichandan(LTM) on 2026-03-27
     * Starts polling via notifyRecordUpdateAvailable to refresh the wired record.
     * Stops automatically when the wire detects matching values or after 15s timeout.
     */
    _startPolling() {
        this._stopPolling();
        this._pollTimer = setInterval(() => {
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        }, POLL_INTERVAL_MS);

        this._pollTimeoutTimer = setTimeout(() => {
            this._stopPolling();
            this.isResolving = false;
            this._wasResolvingWhenBannerHid = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Resolution Timed Out',
                message: 'The recalculation did not complete in time. Please try again.',
                variant: 'error',
                mode: 'sticky'
            }));
        }, POLL_TIMEOUT_MS);
    }

    /**
     * Added by Suraj Harichandan(LTM) on 2026-03-27
     * Clears all active polling timers.
     */
    _stopPolling() {
        if (this._pollTimer) {
            clearInterval(this._pollTimer);
            this._pollTimer = null;
        }
        if (this._pollTimeoutTimer) {
            clearTimeout(this._pollTimeoutTimer);
            this._pollTimeoutTimer = null;
        }
    }

    /**
     * Added by Suraj Harichandan(LTM) on 2026-03-27
     * Called when the wire detects values now match after an async resolution.
     * Stops polling, resets state, and shows a success toast.
     */
    _onAsyncResolutionComplete() {
        this._stopPolling();
        this.isResolving = false;
        this._wasResolvingWhenBannerHid = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Residual Resolved',
            message: 'The residual has been successfully recalculated.',
            variant: 'success',
            mode: 'dismissible'
        }));
    }

    /**
     * Added by Suraj Harichandan(LTM) on 2026-03-27
     * Cleanup polling timers when the component is removed from the DOM.
     */
    disconnectedCallback() {
        this._stopPolling();
    }
}