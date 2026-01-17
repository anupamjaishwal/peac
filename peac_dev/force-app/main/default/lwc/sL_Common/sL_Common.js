import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors, showToast } from 'c/sl_Utils';

export function showError(thisReference, error, customTitle){
    // let reducedMessage = reduceErrors(error);
    let message = (error && error.body && error.body.message)
        || (error && error.detail && error.detail.message) || error.message || error;
    // if(reduceErrors[0].length){
    //     if(Array.isArray(message)){
    //         message = [...message, reducedMessage];
    //     }else{
    //         message = [message, reducedMessage];
    //     }
    // }
    message = message.toString();
    console.log('message after: ', message);
    let title = customTitle || 'Error';
    thisReference.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        })
    );
}