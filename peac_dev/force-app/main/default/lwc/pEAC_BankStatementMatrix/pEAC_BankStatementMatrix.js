import { LightningElement, api, wire } from 'lwc';
import getBankData from '@salesforce/apex/PEAC_BankStatementMatrixCtrl.getBankData';

export default class PEAC_BankStatementMatrix extends LightningElement {
@api recordId; // Opportunity Id
sections = [];

@wire(getBankData, { opportunityId: '$recordId' })
wiredData({ data, error }) {
    if (data) {
        // Apex returns a LIST of sections in the desired order
        const sectionsArr = Object.keys(data).map(key => data[key]);

        // Enrich each column header with a record URL for hyperlinking
        this.sections = sectionsArr.map(sec => {
            const columnsWithUrl = (sec.columns || []).map(col => {
                return {
                    ...col,
                    url: `/lightning/r/Bank_Statement__c/${col.id}/view`
                };
            });
            return {
                ...sec,
                columns: columnsWithUrl
            };
        });
    } else if (error) {
        console.error('Error fetching bank data: ', error);
        this.sections = [];
    }
}
}