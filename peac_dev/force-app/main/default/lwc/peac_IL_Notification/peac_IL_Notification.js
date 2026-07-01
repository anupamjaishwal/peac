import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, isEmpEnabled } from 'lightning/empApi';

export default class Peac_IL_Notification extends LightningElement {
    @api recordId;
    @api pfEventName = '/event/PEAC_IL_Notification__e';

    /**
     * Optional: which fields to read from payload
     */
    @api titleField = 'Title__c';
    @api messageField = 'Message__c';
    @api variantField = 'Variant__c';
    @api recIdField = 'Record_Id__c';

    // -1 means "new events only"
    @api replayId = -1;

    subscription = null;

    @track status;
    @track lastReplayId;

    async connectedCallback() {
        // Register error listener
        onError((error) => {
            // You can log this to console or show a toast
            // eslint-disable-next-line no-console
            console.error('EMP API error: ', JSON.stringify(error));
            this.status = 'Error (see console)';
        });

        const empEnabled = isEmpEnabled();
        if (!empEnabled) {
            this.status = 'EMP API not enabled in this context.';
            return;
        }
        await this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    async handleSubscribe() {
        if (this.subscription) return;
        const messageCallback = (response) => {
            // Typical response shape:
            // response.data.payload contains event fields
            const payload = response?.data?.payload || {};
            const event = response?.data?.event || {};

            //this.lastReplayId = event?.replayId;

            const title = payload[this.titleField] || 'Platform Event';
            const message = payload[this.messageField] || 'Event received';
            const variant = (payload[this.variantField] || 'info').toLowerCase();
            const recId = (payload[this.recIdField] || '').toLowerCase();
            console.log('recId ==> ', recId);
            console.log('this.recordId ==> ', this.recordId);
            if (recId.toLowerCase() === this.recordId.toLowerCase()) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title,
                        message,
                        variant: ['success', 'info', 'warning', 'error'].includes(variant) ? variant : 'info',
                        mode: 'sticky'
                    })
                );
                //this.recordId = '';
            }
        };
        try {
            this.subscription = await subscribe(
                this.pfEventName,
                Number(this.replayId),
                messageCallback
            );
            this.status = 'Subscribed';
            console.log('Subscribed to: ', this.pfEventName);
        } catch (e) {
            console.error('Subscribe failed: ', e);
            this.status = 'Subscribe failed (see console)';
        }
    }

    async handleUnsubscribe() {
        if (!this.subscription) return;
        try {
            await unsubscribe(this.subscription, () => {
                console.log('Unsubscribed from: ', this.pfEventName);
            });
        } finally {
            this.subscription = null;
            this.status = 'Unsubscribed';
        }
    }
}