public without sharing class TC_UpdateDocsRequestedChecklists implements TC_TriggerActionI{
    
    public void doAction(TC_TriggerContext tc){
        attachItem((List<TC_Origination__Checklist__c>)tc.getNewList());
    }
    
    public static void attachItem(List<TC_Origination__Checklist__c>newList){
        for(TC_Origination__Checklist__c checklist:newList){
            if(checklist.TC_Origination__API_Name__c == 'Docs Requested' || checklist.TC_Origination__API_Name__c == 'Docs Requested Loan'){
                boolean valid = TC_StateRules.stateFinder(checklist.TC_Origination__Opportunity__c);
                if(valid){
                    TC_Origination__Checklist_Template_Item__c loanStip = [SELECT id FROM TC_Origination__Checklist_Template_Item__c WHERE TC_Origination__API_Name__c = 'Does not meet state pricing regs.' AND TC_Origination__Checklist_Template__c =:checklist.TC_Origination__Checklist_Template__c LIMIT 1];
					List<TC_Origination__Checklist_Item_with_Attachments__c> items = new List<TC_Origination__Checklist_Item_with_Attachments__c>();
                    TC_Origination__Checklist_Item_with_Attachments__c stateItem = new TC_Origination__Checklist_Item_with_Attachments__c(TC_Origination__API_Name__c = 'Does not meet state pricing regs.',TC_Origination__Authority_to_Clear__c='CMS',TC_Origination__Checklist__c=checklist.Id,TC_Origination__Checklist_s_Opportunity__c=checklist.TC_Origination__Opportunity__c,TC_Origination__Included__c=true,TC_Origination__Internal_External__c='Internal',Name='Does not meet state pricing regs.',TC_Origination__Simple_Complex__c='Complex',TC_Origination__Stage_to_Clear__c='Docs Out',TC_Origination__Checklist_Template_Item__c =loanStip.id);
                    items.add(stateItem);
                    insert items;
                }
            }
        }
    }

}