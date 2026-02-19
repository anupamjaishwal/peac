trigger TC_UpdateChildDealerAccountsActionTrigger on TC_Update_Child_Dealer_Accounts__e (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        TC_UpdateChildDealerAccounts.handleChildrenAction(Trigger.new);
    }
}