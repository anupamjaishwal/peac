import { LightningElement, api, track } from 'lwc';
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

export default class TvalueQuotePicker extends LightningElement {
    @api recordId;
    @api selectedQuoteIds = [];
    @api selectedQuoteRecords = [];
    @api selectedQuoteId;
    @track quotes = [];
    @track selectedRows = [];
    @track error;
    @track isLoading = false;
    @track columns = [];
    @track isEmailModalOpen = false;
    showYieldColumn = false;
    eventSubscription = null;
    cometdLib = null;
    libInitialized = false;
    sessionId;
    // Waiting-for-quotes state (used when no recordId provided)
    @track waitingForQuotes = false;
    waitingTimer = null;
    waitingTimeoutMs = 30000; // 30 seconds
    @track waitingError = false;

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
        QUOTES_NOT_GENERATED_LABEL
    };

    connectedCallback() {
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
    }

    // Determine user type and subscribe accordingly
    initEventSubscription() {
        isPortalUser()
            .then((isPortal) => {
                if (isPortal) {
                    console.log('Portal user detected — using CometD');
                    this.setupCometD();
                } else {
                    console.log('Internal user detected — using empApi');
                    this.setupEmpApi();
                }
            })
            .catch((error) => {
                console.error('Error checking user type:', error);
            });
    }

    // empApi path for internal users
    setupEmpApi() {
        subscribe('/event/NT_TValue_Event__e', -1, (message) => {
            this.handlePlatformEvent(message);
        }).then((subscription) => {
            this.eventSubscription = subscription;
        });

        onError((error) => {
            console.error('empApi error:', error);
        });
    }

    // CometD path for portal users — replicates sL_DPOffers pattern
    setupCometD() {
        getSessionId()
            .then((sessionId) => {
                this.sessionId = sessionId;
                return loadScript(this, COMETD);
            })
            .then(() => {
                this.initCometD();
            })
            .catch((error) => {
                console.error('CometD setup failed:', error);
            });
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
            logLevel: 'debug'
        });

        cometdLib.websocketEnabled = false;
        const _this = this;
        cometdLib.handshake((status) => {
            if (status.successful) {
                cometdLib.subscribe('/event/NT_TValue_Event__e', function (message) {
                    console.log('subscribed to message!', message);
                    _this.handlePlatformEvent(message);
                });
            } else {
                console.error('Error in handshaking: ' + JSON.stringify(status));
            }
        });
        // cometdLib.handshake((handshakeReply) => {
        //     console.log('CometD handshake:', handshakeReply);
        //     if (handshakeReply.successful) {
        //         cometdLib.subscribe('/event/NT_TValue_Event__e', (message) => {
        //             console.log('CometD event received:', message);
        //             this.handlePlatformEvent(message);
        //         });
        //     }
        // });

        this.cometdLib = cometdLib;
    }

    handlePlatformEvent(message) {
        // Extract event payload
        const eventData = message?.data?.payload;

        if (!eventData) {
            console.warn('Platform event payload missing or malformed');
            return;
        }

        // Cancel waiting timer since we received an event
        this.cancelWaitingForQuotes();
        this.waitingError = false;

        // Validate RecordId match if this component has one
        if (this.recordId && eventData.RecordId__c && this.recordId !== eventData.RecordId__c) {
            console.warn(
                `Platform event RecordId (${eventData.RecordId__c}) does not match component recordId (${this.recordId}) — ignoring event`
            );
            return;
        }

        // Prioritize TValue quote IDs if present
        if (eventData.TvalueQuoteIds__c && String(eventData.TvalueQuoteIds__c).trim().length > 0) {
            this.loadTValueQuotesByIds(eventData.TvalueQuoteIds__c);
            return;
        }

        // Otherwise, load quotes by RecordId
        if (eventData.RecordId__c) {
            this.recordId = eventData.RecordId__c;
            this.loadQuotes();
        }
    }

    loadTValueQuotesByIds(tvalueQuoteIds) {
        // Parse the semicolon-separated IDs
        const ids = tvalueQuoteIds.split(';').map(id => id.trim()).filter(id => id.length > 0);
        
        if (ids.length === 0) {
            return;
        }

        this.isLoading = true;
        getTValueQuotesByIds({ quoteIds: ids })
            .then(result => {
                // Cancel waiting state since we got data
                this.cancelWaitingForQuotes();
                this.waitingError = false;
                this.quotes = result.quotes;
                this.showYieldColumn = result.showYield;
                this.initializeColumns();
                this.error = undefined;
                this.showToast('Success', 'New quotes loaded', 'success');
            })
            .catch(error => {
                console.error('Error fetching TValue quotes by IDs:', error);
                this.error = error;
                this.showToast('Error', 'Failed to load new quotes.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
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

        // Conditionally add the Yield column
        if (this.showYieldColumn) {
            const yieldColumn = {
                label: this.label.YIELD_LABEL,
                fieldName: 'yield',
                type: 'percent',
                sortable: true,
                cellAttributes: { alignment: 'center' }
            };
            // Insert Yield column at the 7th position (index 6)
            tempColumns.splice(6, 0, yieldColumn);
        }

        this.columns = tempColumns;
    } 

    loadQuotes() {
        this.isLoading = true;
        // We'll decide to show a waiting UI after the server call if no quotes are returned.
        // Call the new Apex method
        getQuoteData({ recordId: this.recordId })
            .then(result => {
                this.quotes = result.quotes;
                this.showYieldColumn = result.showYield;
                this.initializeColumns(); // Initialize columns now that we have the flag
                this.error = undefined;
                // If no quotes were returned, start waiting for the platform event
                if (!this.quotes || this.quotes.length === 0) {
                    console.log('tvalueQuotePicker: no quotes returned; starting waiting for platform event');
                    this.startWaitingForQuotes();
                } else {
                    this.cancelWaitingForQuotes();
                }
            })
            .catch(error => {
                console.error('Imperative call failed. Error:', error);
                this.error = error;
                this.quotes = [];
                this.initializeColumns(); // Also initialize in case of error to show headers
                console.log('tvalueQuotePicker: error fetching quotes; starting/waiting for quotes');
                this.startWaitingForQuotes();
            })
            .finally(() => {
                this.isLoading = false;
                this.selectedRows = [];
            });
    }

    handleRowSelection(event) {
        // Extracts the selected row details
        const selectedRows = event.detail.selectedRows;
        // Maps the selected rows to just their IDs for easier processing
        this.selectedRows = selectedRows.map(row => row.id);
        this.updateFlowOutputs();
    }

    get hasQuotes() {
        return this.quotes && this.quotes.length > 0;
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
        return this.quotes.filter(q => this.selectedRows.includes(q.id));
        //return matched.length > 0 ? matched[0] : null;
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

        //const selectedRecords = this.quotes.filter(q => this.selectedRows.includes(q.id));
        this.updateFlowOutputs();

        // SAL-7243 — stamp tval__Selected__c on the chosen TValue Quote (and
        // clear siblings) before navigating. Failures here are non-blocking:
        // we still advance the flow so the user isn't stuck if the update
        // hits a sharing/validation edge case; the toast surfaces the error.
        const chosenId = this.selectedRows[0];
        markSelectedTValueQuote({ tvalueQuoteId: chosenId })
            .catch((error) => {
                console.error('markSelectedTValueQuote failed:', error);
                this.showToast('Warning', 'Could not mark this TValue Quote as selected.', 'warning');
            });

        //Dispatch event to move Flow forward
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleCloseEmailModal() {
        this.isEmailModalOpen = false;
    }

    updateFlowOutputs() {
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedQuoteIds', this.selectedRows);
        this.dispatchEvent(attributeChangeEvent);

        const selected = this.currentSelectedRecords?.[0] ?? null;
        const recordsChangeEvent = new FlowAttributeChangeEvent('selectedQuoteRecords', selected ? [selected] : []);
        this.dispatchEvent(recordsChangeEvent);

        const idChangeEvent = new FlowAttributeChangeEvent('selectedQuoteId', selected ? selected.id : null);
        this.dispatchEvent(idChangeEvent);
    }

    // Start a waiting state when there is no recordId and we're awaiting platform events.
    startWaitingForQuotes() {
        console.log('tvalueQuotePicker: startWaitingForQuotes()');
        this.waitingForQuotes = true;
        this.waitingError = false;
        if (this.waitingTimer) {
            clearTimeout(this.waitingTimer);
        }
        this.waitingTimer = setTimeout(() => {
            // No events received within timeout
            console.log('tvalueQuotePicker: waiting timed out — showing error');
            this.waitingForQuotes = false;
            this.waitingError = true;
            this.waitingTimer = null;
        }, this.waitingTimeoutMs);
    }

    cancelWaitingForQuotes() {
        console.log('tvalueQuotePicker: cancelWaitingForQuotes()');
        if (this.waitingTimer) {
            clearTimeout(this.waitingTimer);
            this.waitingTimer = null;
        }
        this.waitingForQuotes = false;
        this.waitingError = false;
    }
}