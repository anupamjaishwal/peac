import { LightningElement, api, wire } from 'lwc';
import getLatestLogs from '@salesforce/apex/PEAC_ILIntegrationLogService.getLatestLogs';

export default class PEAC_ilIntegrationLogSummary extends LightningElement {
  @api recordId;
  //@api minutesBack = 1440;
  @api minutesBack = 10080; // 7 days

  showComponent = false;
  rows = [];
  error;

  @wire(getLatestLogs, { contractId: '$recordId', minutesBack: '$minutesBack' })
  wiredLogs({ data, error }) {
    if (data) {
        this.rows = data.rows || [];
        // Always render when there are rows; keep server flag as secondary.
        this.showComponent = (this.rows.length > 0) || !!data.showComponent;
        this.error = undefined;
        console.log('IL Summary rows:', this.rows.length, JSON.stringify(this.rows));
    }else if (error) {
      this.showComponent = false; // avoids whitespace on error
      this.rows = [];
      this.error = error?.body?.message || error?.message || 'Failed to load logs';
      // eslint-disable-next-line no-console
      console.error(JSON.stringify(error));
    }
  }

  get hasRows() {
    return Array.isArray(this.rows) && this.rows.length > 0;
  }

  mapStatusToClass(status) {
    const key = (status || '').toLowerCase();
    if (key === 'success' || key === 'completed' || key === 'done') return 'slds-badge slds-theme_success';
    if (key === 'in progress' || key === 'warning') return 'slds-badge slds-theme_warning';
    if (key === 'failed' || key === 'error') return 'slds-badge slds-theme_error';
    return 'slds-badge';
  }

  get rowsWithFallback() {
    return (this.rows || []).map((r, idx) => {
      const label = (r.quoteBuyoutTypeLabel || r.quoteBuyoutType || '').trim();
      const status = (r.status || r.errorMessage || 'Failed').trim();

      return {
        ...r,
        rowKey: r.id || `${idx}-${label}-${status}`,
        qbtDisplay: label || '—',
        statusDisplay: status || '—',
        startTimeDisplay: r.startTime || '—',
        statusClass: this.mapStatusToClass(status),
      };
    });
  }
}