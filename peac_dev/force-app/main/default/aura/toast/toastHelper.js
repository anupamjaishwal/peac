({
	dismissToast : function(cmp, event) {
		var toastCmp = cmp.find('toast');

        if (toastCmp) {
            $A.util.addClass(toastCmp, 'slds-hide');
            cmp.set("v.message", '');
        	cmp.set("v.title", '');
        	cmp.set("v.type", 'info');
        }
	},
})