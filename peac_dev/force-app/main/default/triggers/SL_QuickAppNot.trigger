trigger SL_QuickAppNot on TC_Quick_App_Notification__e (after insert) {
	System.debug('ran quick app notification');
}