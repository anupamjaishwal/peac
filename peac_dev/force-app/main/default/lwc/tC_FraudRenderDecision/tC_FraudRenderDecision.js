import { LightningElement, wire, api, track } from 'lwc';
import getUserInfo from '@salesforce/apex/TC_FraudRenderDecisionCtrl.getUserInfo';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import renderDecision from '@salesforce/apex/TC_FraudRenderDecisionCtrl.renderDecision';

export default class TC_FraudRenderDecision extends LightningElement {

    @api recordId;
    @api showSpinner = false;

    @wire(getUserInfo, { userId: Id })
    userData;

    @track decisionValue;

    permissibleProfiles = ['System Administrator'];

    permissibleRoles = ['Credit Manager', 'Credit VP', 'CVP Analyst'];

    get isPermissible() {
        return this.permissibleProfiles.includes(this.userData.data.Profile.Name) || this.permissibleRoles.includes(this.userData.data.UserRole.Name);
    }

    handleChange(event) {
        this.decisionValue = event.target.value;
    }

    handleSubmit(event) {
        this.showSpinner = true;
        event.preventDefault(); // prevents a duplicate form submission
        const fields = event.detail.fields;
        // this.template.querySelector('lightning-record-edit-form').submit(fields);
        renderDecision({ opportunityId: this.recordId, decision: this.decisionValue })
            .then((result) => {
                this.handleSuccess();
            })
            .catch((error) => {
                this.showSpinner = false;
                if (error.body.fieldErrors != null) {
                    var val = Object.values(error.body.fieldErrors);
                    const evt = new ShowToastEvent({
                        title: "Error!",
                        message: val[0][0]["message"],
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                } else {
                    const evt = new ShowToastEvent({
                        title: "Error!",
                        message: "An unexpected error has occurred. Please review the debug logs.",
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                }
            });
    }

    handleSuccess() {
        this.showSpinner = false;
        const evt = new ShowToastEvent({
            title: "Success!",
            variant: "success",
        });
        this.dispatchEvent(evt);
        this.closeQuickAction();
    }

    closeQuickAction() {
        const closeQA = new CustomEvent('close');
        this.dispatchEvent(closeQA);
    }
}