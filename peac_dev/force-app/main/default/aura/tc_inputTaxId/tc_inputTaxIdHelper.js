/**
 * Created on 1/8/18.
 */
({
    formatSSN : function (cmp, event, helper) {
        var  ssn = event.getSource().get('v.value');

        ssn = ssn.replace(/[A-Za-z$-()\.]/g, '');
        ssn = ssn.replace(/[^0-9]/g, '');
        ssn = ssn.replace( /[^\d]/g, '' );
        ssn = ssn.substring(0, 9);
        if (cmp.get('v.entityType') === 'person') {
            ssn = ssn.replace(/(\d{3})(\d{2})(\d{4})/, '$1-$2-$3');
        } else if(cmp.get('v.entityType') === 'company') {
            ssn = ssn.replace(/(\d{2})(\d{6})/, '$1-$2');
        }

        // event.getSource().set('v.value', ssn);
        cmp.set('v.value', ssn);
    }
})