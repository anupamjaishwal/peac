/**
 * @description Subscriber for NT_Quote_Backstamp__e. Platform event triggers run
 *              as the Automated Process user, which has access to the Opportunity
 *              even when the originating Quote update was performed by a portal /
 *              community user. This is what avoids the
 *              INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY error the synchronous
 *              path hit when the tval managed-package trigger cascaded a Quote
 *              update (SAL-7168).
 * @author Northteq
 */
trigger NT_QuoteBackstampEventTrigger on NT_Quote_Backstamp__e (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        NT_QuoteTriggerHandler.handleBackstampEvents(Trigger.new);
    }
}