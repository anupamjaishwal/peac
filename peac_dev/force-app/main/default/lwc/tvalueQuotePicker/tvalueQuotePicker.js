import { LightningElement, api, track } from 'lwc'; // Note: 'wire' is removed
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuoteData from '@salesforce/apex/tvalueQuotePickerController.getQuoteData';
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
    @track quotes = [];
    @track selectedRows = [];
    @track error;
    @track isLoading = false;
    @track columns = [];
    @track isEmailModalOpen = false;
    showYieldColumn = false; // Flag to control column visibility

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
        LEGAL_DISCLAIMER_LABEL
    };

    connectedCallback() {
        // We now initialize columns after we fetch the data and visibility flag
        this.loadQuotes();
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
        // Call the new Apex method
        getQuoteData({ recordId: this.recordId })
            .then(result => {
                console.log('Imperative call successful. Data:', result);
                this.quotes = result.quotes;
                this.showYieldColumn = result.showYield;
                this.initializeColumns(); // Initialize columns now that we have the flag
                this.error = undefined;
            })
            .catch(error => {
                console.error('Imperative call failed. Error:', error);
                this.error = error;
                this.quotes = [];
                this.initializeColumns(); // Also initialize in case of error to show headers
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

    get selectedQuoteRecords() {
        return this.quotes.filter(q => this.selectedRows.includes(q.id));
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

        this.dispatchEvent(new CustomEvent('usethisquote', {
            detail: {
                selectedQuoteIds: this.selectedRows,
                quoteRecords: this.quotes.filter(q => this.selectedRows.includes(q.id))
            },
            bubbles: true,
            composed: true
        }));
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
}