import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { loadScript } from 'lightning/platformResourceLoader';
import COMETD from '@salesforce/resourceUrl/cometD';
import getSessionId from '@salesforce/apex/tvalueQuotePickerController.getSessionId';
import isPortalUser from '@salesforce/apex/tvalueQuotePickerController.isPortalUser';
import getQuoteData from '@salesforce/apex/tvalueQuotePickerController.getQuoteData';
import getTValueQuotesByIds from '@salesforce/apex/tvalueQuotePickerController.getTValueQuotesByIds';
// SAL-7243 — set tval__Selected__c on the chosen TValue Quote (and clear
// siblings under the same parent Quote) when the user clicks "Use this quote".
import markSelectedTValueQuote from '@salesforce/apex/TC_LoanApplicationCtrl.markSelectedTValueQuote';
import WAITING_LABEL from '@salesforce/label/c.TvalueQuotePicker_Waiting';
import QUOTES_NOT_GENERATED_LABEL from '@salesforce/label/c.TvalueQuotePicker_QuotesNotGenerated';
import SELECT_LABEL from '@salesforce/label/c.TvalueQuotePicker_Select';
import QUOTE_OPTION_LABEL from '@salesforce/label/c.TvalueQuotePicker_QuoteOption';
import DESCRIPTION_LABEL from '@salesforce/label/c.TvalueQuotePicker_Description';
import FINANCED_AMOUNT_LABEL from '@salesforce/label/c.TvalueQuotePicker_FinancedAmount';
import TERM_LABEL from '@salesforce/label/c.TvalueQuotePicker_Term';
import PAYMENT_LABEL from '@salesforce/label/c.TvalueQuotePicker_Payment';
import ADVANCE_PAYMENTS_LABEL from '@salesforce/label/c.TvalueQuotePicker_AdvancePayments';
import YIELD_LABEL from '@salesforce/label/c.TvalueQuotePicker_Yield';
import DEFERRAL_LABEL from '@salesforce/label/c.TvalueQuotePicker_Deferral';
import END_OPTION_LABEL from '@salesforce/label/c.TvalueQuotePicker_EndOption';
import NOTES_LABEL from '@salesforce/label/c.TvalueQuotePicker_Notes';
import CREATED_LABEL from '@salesforce/label/c.TvalueQuotePicker_Created';
import EMAIL_QUOTES_LABEL from '@salesforce/label/c.TvalueQuotePicker_EmailQuotes';
import USE_THIS_QUOTE_LABEL from '@salesforce/label/c.TvalueQuotePicker_UseThisQuote';
import LEGAL_DISCLAIMER_LABEL from '@salesforce/label/c.TvalueQuotePicker_LegalDisclaimer';
// SAL-6442 — friendly, customer-facing message shown when the pricing run fails
// (e.g. no eligible rate card). The technical reason stays in Pricing_Status__c /
// the error Pricing_Result__c for admins; users never see raw backend strings.
import PRICING_ERROR_LABEL from '@salesforce/label/c.TvalueQuotePicker_PricingError';

const TVALUE_EVENT_CHANNEL = '/event/NT_TValue_Event__e';

export default class TvalueQuotePicker extends LightningElement {
    @api recordId;
    @api selectedQuoteIds = [];
    @api selectedQuoteRecords = [];
    @api selectedQuoteId;

    // Field reassignments are reactive on API 47+, so these don't need @track
    // (none are mutated in place).
    quotes = [];
    selectedRows = [];
    error;
    isLoading = false;
    columns = [];
    isEmailModalOpen = false;
    showYieldColumn = false;
    eventSubscription = null;
    cometdLib = null;
    libInitialized = false;
    sessionId;
    // Working copy of the record whose quotes we display. Seeded from the @api
    // recordId and updated when a platform event arrives, so we never reassign the
    // public property the flow/record page owns.
    _activeRecordId;
    // Waiting state shown while async pricing runs and no quotes exist yet.
    waitingForQuotes = false;
    waitingTimer = null;
    waitingTimeoutMs = 30000; // 30 seconds
    waitingError = false;
    // SAL-6442 — friendly message for the error state; falls back to the generic
    // timeout label when unset (see waitingErrorText).
    waitingErrorMessage;

    label = {
        SELECT_LABEL,
        QUOTE_OPTION_LABEL,
        DESCRIPTION_LABEL,
        FINANCED_AMOUNT_LABEL,
        TERM_LABEL,
        PAYMENT_LABEL,
        ADVANCE_PAYMENTS_LABEL,
        YIELD_LABEL,
        DEFERRAL_LABEL,
        END_OPTION_LABEL,
        NOTES_LABEL,
        CREATED_LABEL,
        EMAIL_QUOTES_LABEL,
        USE_THIS_QUOTE_LABEL,
        LEGAL_DISCLAIMER_LABEL,
        WAITING_LABEL,
        QUOTES_NOT_GENERATED_LABEL,
        PRICING_ERROR_LABEL
    };

    connectedCallback() {
        this._activeRecordId = this.recordId;
        this.loadQuotes();
        this.initEventSubscription();
    }

    disconnectedCallback() {
        if (this.eventSubscription) {
            unsubscribe(this.eventSubscription);
        }
        if (this.cometdLib) {
            this.cometdLib.disconnect();
        }
        // Prevent the waiting timer from firing on a destroyed component.
        if (this.waitingTimer) {
            clearTimeout(this.waitingTimer);
            this.waitingTimer = null;
        }
    }

    // Determine user type and subscribe to the pricing platform event accordingly.
    async initEventSubscription() {
        try {
            const isPortal = await isPortalUser();
            if (isPortal) {
                await this.setupCometD();
            } else {
                await this.setupEmpApi();
            }
        } catch (error) {
            console.error('Error initializing event subscription:', error);
        }
    }

    // empApi path for internal users
    async setupEmpApi() {
        try {
            this.eventSubscription = await subscribe(TVALUE_EVENT_CHANNEL, -1, (message) =>
                this.handlePlatformEvent(message)
            );
        } catch (error) {
            console.error('empApi subscribe failed:', error);
        }
        onError((error) => console.error('empApi error:', error));
    }

    // CometD path for portal users — replicates the sL_DPOffers pattern
    async setupCometD() {
        try {
            this.sessionId = await getSessionId();
            await loadScript(this, COMETD);
            this.initCometD();
        } catch (error) {
            console.error('CometD setup failed:', error);
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
            requestHeaders: { Authorization: 'OAuth ' + this.sessionId },
            appendMessageTypeToURL: false,
            logLevel: 'info'
        });

        cometdLib.websocketEnabled = false;
        cometdLib.handshake((status) => {
            if (status.successful) {
                cometdLib.subscribe(TVALUE_EVENT_CHANNEL, (message) => this.handlePlatformEvent(message));
            } else {
                console.error('CometD handshake failed: ' + JSON.stringify(status));
            }
        });

        this.cometdLib = cometdLib;
    }

    handlePlatformEvent(message) {
        const eventData = message?.data?.payload;
        if (!eventData) {
            console.warn('Platform event payload missing or malformed');
            return;
        }

        // Ignore events for a different record so they can't clear our waiting state.
        if (
            this._activeRecordId &&
            eventData.RecordId__c &&
            this._activeRecordId !== eventData.RecordId__c
        ) {
            return;
        }

        const status = eventData.Status__c;
        // 'Starting' is transient (the run was just enqueued); keep waiting rather
        // than re-querying for quotes that don't exist yet.
        if (status === 'Starting') {
            return;
        }

        const hasQuoteIds = !!(
            eventData.TvalueQuoteIds__c && String(eventData.TvalueQuoteIds__c).trim().length > 0
        );

        // A pricing failure ('Error' / 'Pricing Error'): stop waiting immediately.
        if (status === 'Error' || status === 'Pricing Error') {
            this.cancelWaitingForQuotes();
            // If some combinations succeeded before the failure, still show those quotes
            // rather than hiding successful work; the error is recorded on the record /
            // Pricing Result for admins. Only when nothing was generated do we surface
            // the friendly pricing-error message (the no-rate-card / missing-config case).
            if (hasQuoteIds) {
                this.waitingErrorMessage = undefined;
                this.loadTValueQuotesByIds(eventData.TvalueQuoteIds__c);
            } else {
                this.waitingError = true;
                this.waitingErrorMessage = this.label.PRICING_ERROR_LABEL;
            }
            return;
        }

        // Otherwise this is a completion event — cancel the waiting timer and load results.
        this.cancelWaitingForQuotes();
        this.waitingErrorMessage = undefined;

        if (hasQuoteIds) {
            this.loadTValueQuotesByIds(eventData.TvalueQuoteIds__c);
        } else if (eventData.RecordId__c) {
            this._activeRecordId = eventData.RecordId__c;
            this.loadQuotes();
        }
    }

    async loadTValueQuotesByIds(tvalueQuoteIds) {
        const ids = tvalueQuoteIds
            .split(';')
            .map((id) => id.trim())
            .filter((id) => id.length > 0);
        if (ids.length === 0) {
            return;
        }

        this.isLoading = true;
        try {
            const result = await getTValueQuotesByIds({ quoteIds: ids });
            this.cancelWaitingForQuotes();
            this.quotes = result.quotes;
            this.showYieldColumn = result.showYield;
            this.initializeColumns();
            this.error = undefined;
            this.showToast('Success', 'New quotes loaded', 'success');
        } catch (error) {
            console.error('Error fetching TValue quotes by IDs:', error);
            this.error = error;
            this.showToast('Error', 'Failed to load new quotes.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadQuotes() {
        this.isLoading = true;
        try {
            const result = await getQuoteData({ recordId: this._activeRecordId });
            this.quotes = result.quotes;
            this.showYieldColumn = result.showYield;
            this.initializeColumns();
            this.error = undefined;
            if (!this.quotes || this.quotes.length === 0) {
                // No quotes yet — wait for the pricing platform event.
                this.startWaitingForQuotes();
            } else {
                this.cancelWaitingForQuotes();
            }
        } catch (error) {
            // A genuine fetch failure shows the error state only — not the waiting
            // spinner as well (the normal "no quotes yet" path is the empty-success
            // branch above, which starts waiting).
            console.error('getQuoteData failed:', error);
            this.error = error;
            this.quotes = [];
            this.initializeColumns();
            this.cancelWaitingForQuotes();
        } finally {
            this.isLoading = false;
            this.selectedRows = [];
        }
    }

    initializeColumns() {
        let tempColumns = [
            {
                label: this.label.QUOTE_OPTION_LABEL,
                fieldName: 'quoteOptionName',
                type: 'text',
                sortable: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: this.label.DESCRIPTION_LABEL,
                fieldName: 'description',
                type: 'text',
                sortable: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: this.label.FINANCED_AMOUNT_LABEL,
                fieldName: 'financedAmount',
                type: 'currency',
                sortable: true,
                cellAttributes: { alignment: 'right' }
            },
            {
                label: this.label.TERM_LABEL,
                fieldName: 'term',
                type: 'number',
                sortable: true,
                cellAttributes: { alignment: 'center' }
            },
            {
                label: this.label.PAYMENT_LABEL,
                fieldName: 'payment',
                type: 'currency',
                sortable: true,
                cellAttributes: { alignment: 'right' }
            },
            {
                label: this.label.ADVANCE_PAYMENTS_LABEL,
                fieldName: 'advancePayments',
                type: 'number',
                sortable: true,
                cellAttributes: { alignment: 'right' }
            },
            {
                label: this.label.DEFERRAL_LABEL,
                fieldName: 'deferral',
                type: 'text',
                sortable: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: this.label.END_OPTION_LABEL,
                fieldName: 'endOption',
                type: 'text',
                sortable: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: this.label.NOTES_LABEL,
                fieldName: 'notes',
                type: 'text',
                sortable: true,
                cellAttributes: { alignment: 'left' }
            },
            {
                label: this.label.CREATED_LABEL,
                fieldName: 'createdDate',
                type: 'date',
                sortable: true,
                cellAttributes: { alignment: 'center' }
            }
        ];

        // Conditionally add the Yield column at the 7th position (index 6)
        if (this.showYieldColumn) {
            tempColumns.splice(6, 0, {
                label: this.label.YIELD_LABEL,
                fieldName: 'yield',
                type: 'percent',
                sortable: true,
                cellAttributes: { alignment: 'center' }
            });
        }

        this.columns = tempColumns;
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.map((row) => row.id);
        this.updateFlowOutputs();
    }

    get hasQuotes() {
        return this.quotes && this.quotes.length > 0;
    }

    // SAL-6442 — error copy for the error state: the friendly pricing-error message
    // when a failure event arrived, otherwise the generic timeout message.
    get waitingErrorText() {
        return this.waitingErrorMessage || this.label.QUOTES_NOT_GENERATED_LABEL;
    }

    get hasSelection() {
        return this.selectedRows && this.selectedRows.length > 0;
    }

    get notHasSelection() {
        return !this.hasSelection;
    }

    get selectedCount() {
        return this.selectedRows.length;
    }

    get currentSelectedRecords() {
        return this.quotes.filter((q) => this.selectedRows.includes(q.id));
    }

    handleEmailQuotes() {
        if (this.selectedRows.length === 0) {
            this.showToast('Error', 'You must select at least one quote to email.', 'error');
            return;
        }
        this.isEmailModalOpen = true;
    }

    handleUseThisQuote() {
        if (this.selectedRows.length === 0) {
            this.showToast('Error', 'You must select a quote to proceed.', 'error');
            return;
        }
        if (this.selectedRows.length > 1) {
            this.showToast('Error', 'You can only select one quote to use.', 'error');
            return;
        }

        this.updateFlowOutputs();

        // SAL-7243 — stamp the selection in the background. Intentionally not awaited:
        // navigation should proceed even if the update hits a sharing/validation edge
        // case; markSelectedQuote surfaces any failure via a toast.
        this.markSelectedQuote(this.selectedRows[0]);

        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    async markSelectedQuote(tvalueQuoteId) {
        try {
            await markSelectedTValueQuote({ tvalueQuoteId });
        } catch (error) {
            console.error('markSelectedTValueQuote failed:', error);
            this.showToast('Warning', 'Could not mark this TValue Quote as selected.', 'warning');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleCloseEmailModal() {
        this.isEmailModalOpen = false;
    }

    updateFlowOutputs() {
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedQuoteIds', this.selectedRows));

        const selected = this.currentSelectedRecords?.[0] ?? null;
        this.dispatchEvent(
            new FlowAttributeChangeEvent('selectedQuoteRecords', selected ? [selected] : [])
        );
        this.dispatchEvent(
            new FlowAttributeChangeEvent('selectedQuoteId', selected ? selected.id : null)
        );
    }

    startWaitingForQuotes() {
        this.waitingForQuotes = true;
        this.waitingError = false;
        this.waitingErrorMessage = undefined;
        if (this.waitingTimer) {
            clearTimeout(this.waitingTimer);
        }
        // Intentional timeout fallback; cleared in cancelWaitingForQuotes/disconnectedCallback.
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.waitingTimer = setTimeout(() => {
            // No event arrived within the timeout — fall back to the generic
            // "quotes not generated" message (waitingErrorMessage stays unset).
            this.waitingForQuotes = false;
            this.waitingError = true;
            this.waitingErrorMessage = undefined;
            this.waitingTimer = null;
        }, this.waitingTimeoutMs);
    }

    cancelWaitingForQuotes() {
        if (this.waitingTimer) {
            clearTimeout(this.waitingTimer);
            this.waitingTimer = null;
        }
        this.waitingForQuotes = false;
        this.waitingError = false;
    }
}