trigger SL_RunTaxRules on Run_Tax_Rules__e (after insert) {
	System.debug('ran quick app notification');
}