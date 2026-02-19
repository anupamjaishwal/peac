/****************************************************************************************
* @Author       Huron IT Team
* @Date         Aprl  30, 2017
*
*****************************************************************************************/
trigger opportunityTrigger on Opportunity (after insert, after update, before insert, before update) {

if(DeactivateTriggers__c.getAll().get('opportunityTrigger') != null && DeactivateTriggers__c.getAll().get('opportunityTrigger').IsDeactived__c) return;
/*  // old version, queries the profile table everytime opportunity updates pushing us over our limits
    Id profileId=userinfo.getProfileId();
    String profileName='';

    List<Profile> profiles = [Select Id,Name from Profile where Id=:profileId];
    
    if (profiles.size() > 0)
        profileName = profiles[0].Name;
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert ) {
            OpportunityTriggerHandler.addFranchisor(Trigger.new);
            
            if(profileName != 'DataAdmin'){
                OpportunityTriggerHandler.copyPhoneandTaxIdafterTrigger(Trigger.new);
            }
        }
        if(Trigger.isUpdate ) {
            System.Debug('Oppty Trigger call');
            //  OpportunityTriggerHandler.getUpdatedRapportAPIField(Trigger.new,Trigger.old);
            OpportunityTriggerHandler.triggerOnBaseAPI(Trigger.new,Trigger.old);
            if(profileName != 'DataAdmin'){
                OpportunityTriggerHandler.copyPhoneandTaxIdafterTrigger(Trigger.new);
            }
            
        }
    }   
    
    else if(Trigger.isBefore) {
        if(Trigger.isInsert ) {
            //OpportunityTriggerHandler.defaultStageQuote(Trigger.new);
            
            if(profileName != 'DataAdmin'){
                OpportunityTriggerHandler.copyBusinessPhoneandTaxId(Trigger.new);
            }
            
        }
        if(Trigger.isUpdate ) {
            System.Debug('Update primary contact ');
            // tam commented out: OpportunityTriggerHandler.updatePrimaryContactOnOpportunity(Trigger.new);
            if(profileName != 'DataAdmin'){
                OpportunityTriggerHandler.copyBusinessPhoneandTaxId(Trigger.new);
            }
            //OpportunityTriggerHandler.defaultStageQuote(Trigger.new);
        }
    }  */
    
    if (Trigger.isBefore && Trigger.isUpdate){
         TC_OpportunityTriggerHelper.validationForManager (Trigger.oldMap, Trigger.new); //3/17/2021
        }
    
    
    public Trigger_Helper_Settings__c setting = Trigger_Helper_Settings__c.getOrgDefaults ();
    Boolean notDataAdmin = UserInfo.getProfileId () != setting.Data_Admin_Profile_Id__c;
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert ) {
            //Branch to platform, bandita confirmed we can remove this. this code also isn't used anymore after quick app
            //OpportunityTriggerHandler.addFranchisor(Trigger.new);
            
            if(notDataAdmin){
                OpportunityTriggerHandler.copyPhoneandTaxIdafterTrigger(Trigger.new);
            }
        }
        if(Trigger.isUpdate ) {
            System.Debug('Oppty Trigger call');
            //  OpportunityTriggerHandler.getUpdatedRapportAPIField(Trigger.new,Trigger.old);
            OpportunityTriggerHandler.triggerOnBaseAPI(Trigger.new,Trigger.old);
            if(notDataAdmin){
                OpportunityTriggerHandler.copyPhoneandTaxIdafterTrigger(Trigger.new);
            }
            
        }
    }   
    
    else if(Trigger.isBefore) {
        if(Trigger.isInsert ) {
            System.debug('>>>>>>>>opportunity is beforeInsert');
            OpportunityTriggerHandler.PopulatePrimaryContactFields(trigger.new);
            //OpportunityTriggerHandler.defaultStageQuote(Trigger.new);
            
            if(notDataAdmin){
                OpportunityTriggerHandler.copyBusinessPhoneandTaxId(Trigger.new);
            }
            
        }
        if(Trigger.isUpdate ) {
              System.debug('>>>>>>>>opportunity is beforeupdate');
            OpportunityTriggerHandler.PopulatePrimaryContactFields(trigger.new);
            System.Debug('Update primary contact ');
            // tam commented out: OpportunityTriggerHandler.updatePrimaryContactOnOpportunity(Trigger.new);
            if(notDataAdmin){
                OpportunityTriggerHandler.copyBusinessPhoneandTaxId(Trigger.new);
            }
            //OpportunityTriggerHandler.defaultStageQuote(Trigger.new);
        }
    }
}