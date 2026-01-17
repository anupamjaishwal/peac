import { LightningElement, api, wire, track } from 'lwc';
import getQuotes from '@salesforce/apex/tvalueQuotePickerController.getQuotes';
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

export default class TvalueQuotePicker extends LightningElement {
    @api recordId;
    @track quotes = [];
    @track selectedRows = [];
    @track error;
    @track isLoading = false;
    @track columns = [];

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
        USE_THIS_QUOTE_LABEL
    };

    connectedCallback() {
        this.initializeColumns();
    }

    initializeColumns() {
        this.columns = [
            {
                label: this.label.SELECT_LABEL,
                type: 'boolean',
                fieldName: 'isSelected',
                sortable: false,
                cellAttributes: { alignment: 'center' },
                hideDefaultActions: true
            },
            {
                label: this.label.QUOTE_OPTION_LABEL,
                fieldName: 'quoteOption',
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
                type: 'currency',
                sortable: true,
                cellAttributes: { alignment: 'right' }
            },
            {
                label: this.label.YIELD_LABEL,
                fieldName: 'yield',
                type: 'percent',
                sortable: true,
                cellAttributes: { alignment: 'center' }
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
    }

    @wire(getQuotes, { recordId: ' ' })
    wiredQuotes({ error, data }) {
        if (data) {
            this.isLoading = false;
            this.quotes = data;
            this.selectedRows = [];
            this.error = undefined;
        } else if (error) {
            this.isLoading = false;
            this.error = error;
            this.quotes = [];
            this.selectedRows = [];
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRows = selectedRows.map(row => row.id);
        // Update isSelected field in quotes
        this.quotes = this.quotes.map(quote => ({
            ...quote,
            isSelected: this.selectedRows.includes(quote.id)
        }));
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

    handleEmailQuotes() {
        if (this.hasSelection) {
            this.dispatchEvent(new CustomEvent('emailquotes', {
                detail: {
                    selectedQuoteIds: this.selectedRows,
                    quoteRecords: this.quotes.filter(q => this.selectedRows.includes(q.id))
                },
                bubbles: true,
                composed: true
            }));
        }
    }

    handleUseThisQuote() {
        if (this.hasSelection) {
            this.dispatchEvent(new CustomEvent('usethisquote', {
                detail: {
                    selectedQuoteIds: this.selectedRows,
                    quoteRecords: this.quotes.filter(q => this.selectedRows.includes(q.id))
                },
                bubbles: true,
                composed: true
            }));
        }
    }
}