// sL_LookupPicklistLWC.js
import { LightningElement, api, track } from 'lwc';
import searchRecords   from '@salesforce/apex/SL_LookupPicklistController.searchRecords';
import getRecordById   from '@salesforce/apex/SL_LookupPicklistController.getRecordById';
import getProgramRules from '@salesforce/apex/SL_LookupPicklistController.getProgramRules';

const SEARCH_DELAY_MS = 300;

export default class SL_LookupPicklistLWC extends LightningElement {

    // ─── Public properties ─────────────────────────────────────────────────

    @api label          = 'Search';
    @api sObjectApiName;
    @api displayField   = 'Name';
    @api iconName       = 'standard:record';
    @api placeholder    = 'Type to search...';
    @api maxResults     = 10;
    @api extraFields;
    @api noFilterMessage = 'Select a parent record to see available options.';

    // Mode 1: direct filter
    @api filterField;

    // Mode 2: junction object filter
    @api junctionObject;
    @api junctionFilterField;
    @api junctionTargetField;

    /**
     * filterValue — reactive. When it changes:
     *   1. Clears the current selection
     *   2. Calls getProgramRules to determine required/readOnly/auto-select
     */
    @api
    get filterValue() { return this._filterValue; }
    set filterValue(val) {
        const changed = val !== this._filterValue;
        this._filterValue = val;
        if (changed) {
            this.clearSelection();
            if (val) {
                this.applyProgramRules(val);
            } else {
                // No account selected — reset to default state
                this._required = false;
                this._disabled = false;
            }
        }
    }

    /**
     * value — pre-populates the label when editing an existing record.
     */
    @api
    get value() { return this._value; }
    set value(val) {
        if (val === this._value) return;
        this._value = val;
        if (val) {
            this.loadInitialValue(val);
        } else {
            this.selectedRecord = null;
        }
    }

    // ─── Internal state ────────────────────────────────────────────────────

    @track selectedRecord = null;
    @track records        = [];
    @track isLoading      = false;
    @track errorMessage   = '';
    @track searchTerm     = '';

    // Required and disabled are managed internally by program rules
    // but can still be overridden via @api if needed
    @track _required = false;
    @track _disabled = false;

    _filterValue = null;
    _value       = null;
    _isOpen      = false;
    _searchTimer = null;

    // ─── Lifecycle ─────────────────────────────────────────────────────────

    connectedCallback() {
        if (this._value && !this.selectedRecord) {
            this.loadInitialValue(this._value);
        }
    }

    // ─── Program rules logic ───────────────────────────────────────────────

    /**
     * Calls Apex to determine how many programs exist for the given accountId,
     * then applies the appropriate UX rules:
     *   0 programs → optional, empty
     *   1 program  → pre-filled, read-only
     *   2+ programs → required, user picks
     */
    async applyProgramRules(accountId) {
        this.isLoading = true;
        try {
            const rules = await getProgramRules({ accountId });

            this._required = rules.isRequired;
            this._disabled = rules.isReadOnly;

            if (rules.count === 1 && rules.autoSelected) {
                // Auto-select the single program and lock the field
                this.selectedRecord = rules.autoSelected;
                this._value         = rules.autoSelected.id;
                this.fireChange(rules.autoSelected.id, rules.autoSelected.label);
            } else {
                // Multiple or zero — clear selection so user can choose or skip
                this.clearSelection();
            }
        } catch (e) {
            console.error('sL_LookupPicklistLWC: error loading program rules', e);
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Pre-load existing value ───────────────────────────────────────────

    async loadInitialValue(recordId) {
        try {
            const result = await getRecordById({
                sObjectApiName : this.sObjectApiName,
                displayField   : this.displayField,
                recordId
            });
            if (result) this.selectedRecord = result;
        } catch (e) {
            console.error('sL_LookupPicklistLWC: error loading initial value', e);
        }
    }

    // ─── Template getters ──────────────────────────────────────────────────

    get computedLabelClass() {
        return 'slds-form-element__label' + (this._required ? ' slds-required' : '');
    }

    get dropdownClass() {
        return 'slds-combobox_container slds-has-inline-listbox'
            + (this._isOpen ? ' slds-is-open' : '');
    }

    get hasResults() {
        return !this.isLoading && this.records.length > 0 && this._isOpen;
    }

    get showNoResults() {
        return !this.isLoading
            && this.records.length === 0
            && this._isOpen
            && this.searchTerm.length > 0
            && this.filterValueOk;
    }

    get showNoFilterMsg() {
        return !this.isLoading && !this.filterValueOk && this._isOpen;
    }

    get pillClass() {
        return "selected-pill slds-pill slds-pill_link"
            + (this._disabled ? " pill--readonly" : "");
    }

    get filterValueOk() {
        const hasAnyFilter = this.filterField
            || (this.junctionObject && this.junctionFilterField && this.junctionTargetField);
        if (!hasAnyFilter) return true;
        return !!this._filterValue;
    }

    // ─── Input handlers ────────────────────────────────────────────────────

    handleInput(event) {
        this.searchTerm = event.target.value;
        clearTimeout(this._searchTimer);
        this._searchTimer = setTimeout(() => this.doSearch(), SEARCH_DELAY_MS);
    }

    handleFocus() {
        this._isOpen = true;
        if (!this.searchTerm) this.doSearch();
    }

    handleBlur() {
        setTimeout(() => { this._isOpen = false; }, 200);
    }

    handleSelect(event) {
        const id    = event.currentTarget.dataset.id;
        const label = event.currentTarget.dataset.label;
        this.selectedRecord = { id, label };
        this._value         = id;
        this._isOpen        = false;
        this.searchTerm     = '';
        this.records        = [];
        this.fireChange(id, label);
    }

    handleClear() {
        // Only allow clearing if the field is not read-only
        if (this._disabled) return;
        this.clearSelection();
        this.fireChange(null, null);
    }

    clearSelection() {
        this.selectedRecord = null;
        this._value         = null;
        this.records        = [];
        this.searchTerm     = '';
    }

    // ─── Apex search ───────────────────────────────────────────────────────

    async doSearch() {
        if (!this.filterValueOk || this._disabled) return;
        this.isLoading    = true;
        this.errorMessage = '';
        try {
            this.records = await searchRecords({
                sObjectApiName      : this.sObjectApiName,
                displayField        : this.displayField,
                searchTerm          : this.searchTerm          || '',
                filterField         : this.filterField         || '',
                filterValue         : this._filterValue        || '',
                extraFields         : this.extraFields         || '',
                maxResults          : this.maxResults,
                junctionObject      : this.junctionObject      || '',
                junctionFilterField : this.junctionFilterField || '',
                junctionTargetField : this.junctionTargetField || ''
            });
        } catch (e) {
            this.errorMessage = 'Search error: ' + (e.body?.message || e.message);
            this.records = [];
        } finally {
            this.isLoading = false;
        }
    }

    // ─── Events ────────────────────────────────────────────────────────────

    fireChange(recordId, label) {
        this.dispatchEvent(new CustomEvent('change', {
            detail   : { value: recordId, label },
            bubbles  : true,
            composed : true
        }));
    }

    // ─── Form validation ───────────────────────────────────────────────────

    @api
    reportValidity() {
        if (this._required && !this._value) {
            this.errorMessage = `${this.label} is required.`;
            return false;
        }
        this.errorMessage = '';
        return true;
    }

    @api
    checkValidity() {
        return !(this._required && !this._value);
    }
}