import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const showToast = (title, message, variant, mode  = 'dismissible') => {
  const EVT = new ShowToastEvent({
    title,
    message,
    variant,
    mode
  });
  return EVT;
}

/**
 * Reduces one or more LDS errors into a string[] of error messages.
 * @param {FetchResponse|FetchResponse[]} errors
 * @return {String[]} Error messages
 */
const reduceErrors = (errors) => {
  if (!Array.isArray(errors)) {
    errors = [errors];
  }

  return (
    errors
    // Remove null/undefined items
    .filter(error => !!error)
    // Extract an error message
    .map(error => {
      // UI API read errors
      if (Array.isArray(error.body)) {
        return error.body.map(e => e.message);
      }
      //Duplicate errors
      else if (error.body && typeof error.body.message === 'string' && error.body.message.indexOf('Duplicate') !== -1) {
        return 'Duplicate(s) found: {0}';
      }
      // UI API DML, Apex and network errors
      else if (error.body && typeof error.body.message === 'string') {
        return error.body.message;
      }
      // JS errors
      else if (typeof error.message === 'string') {
        return error.message;
      }
      // Unknown error shape so try HTTP status text
      return error.statusText;
    })
    // Flatten
    .reduce((prev, curr) => prev.concat(curr), [])
    // Remove empty strings
    .filter(message => !!message)
  );
}

export {showToast, reduceErrors}