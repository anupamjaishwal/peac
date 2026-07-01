import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class FlowLookupInput extends LightningElement {
    // Public properties configurable in Flow
    @api value;                    // Selected record ID
    @api label;                    // Field label
    @api fieldName;                // API name of the field
    @api helpText;                 // Help text
    @api required = false;         // Is the field required?
    @api disabled = false;         // Is the field disabled?
    @api readOnly = false;         // Is the field read-only?
    
    // Lookup-specific properties
    @api sobjectType;              // Object API name for lookup (e.g., 'Account')
    @api recordId;                 // Record ID for lightning-record-edit-form context
    
    // Internal flag to track initialization
    isInitialized = false;
    
    // Lifecycle hook
    renderedCallback() {
        if (!this.isInitialized) {
            this.isInitialized = true;
            this.hideLookupHelpText();
        }
    }
    
    // Hide the default help text while keeping custom help text visible
    hideLookupHelpText() {
        // Use a style injection approach targeting only our specific lookup field
        // I am still looking for a CSS only way to makee this work
        const style = document.createElement('style');
        style.innerText = `
            .hide-default-help .slds-form-element__icon {
                display: none !important;
            }
            .hide-default-help lightning-helptext {
                display: none !important;
            }
        `;
        
        // Apply style to our specific lookup field elements
        const lookupContainer = this.template.querySelector('.hide-default-help');
        if (lookupContainer && !lookupContainer.querySelector('style')) {
            lookupContainer.appendChild(style);
        }
    }
    
    // Handle lookup field changes
    handleLookupChange(event) {
        const field = this.fieldName || 'value';
        let newValue;
        
        // Handle the event detail structure from lightning-input-field
        if (event.detail && event.detail.value) {
            if (Array.isArray(event.detail.value)) {
                // Handle array of selected records (multi-select lookups)
                newValue = event.detail.value.length > 0 ? event.detail.value[0] : '';
            } else {
                newValue = event.detail.value;
            }
        } else {
            newValue = event.target.value || '';
        }
        
        // Update the value
        this.value = newValue;
        
        // Dispatch Flow events for reactivity
        this.dispatchFlowAttributeChangeEvent();
    }
    
    // Dispatch Flow Attribute Change Event for Flow reactivity
    dispatchFlowAttributeChangeEvent() {
        const attributeChangeEvent = new FlowAttributeChangeEvent('value', this.value);
        this.dispatchEvent(attributeChangeEvent);
    }
    
    // Computed property for disabled state
    get disabledState() {
        return this.disabled || this.readOnly;
    }
    
    // Computed property to check if sobjectType is provided
    get isObjectTypeProvided() {
        return !!this.sobjectType;
    }
    
    // Error handling for missing object type
    get objectTypeError() {
        return 'Object API Name is required for lookup fields. Please configure the sobjectType property.';
    }
}