import { LightningElement, api } from 'lwc';

export default class Tc_NavigateToQuickApp extends LightningElement {
    @api quoteIds = [];

    connectedCallback() {
        const quoteId = this.quoteIds && this.quoteIds.length > 0 ? this.quoteIds[0] : '';
        const url = '/lightning/n/Quick_App' + (quoteId ? '?c__selectedQuoteIds=' + encodeURIComponent(quoteId) : '');
        window.open(url, '_self');
    }
}
