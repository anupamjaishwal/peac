({
	onKeyup: function (cmp, event, helper) {
        helper.searchHelper(cmp, event, helper);
    }
    , onRadio : function(cmp, event, helper) {  
        cmp.find("radioButtonGroup").forEach (addr => addr.set("v.value",false));
		event.getSource().set("v.value",true);
	},selectUserCtrl: function (cmp, event, helper) {
        helper.selectUserHelper(cmp, event, helper);
    }
})