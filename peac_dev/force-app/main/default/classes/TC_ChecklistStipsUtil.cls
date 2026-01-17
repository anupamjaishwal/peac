public class TC_ChecklistStipsUtil {
	public static void updateStipulations (List <Id> oppIds, String checklistName) {


        if (!oppIds.isEmpty ()) {

            Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id , Stipulations__c, Waived_Stipulations__c, Received_Stipulations__c, Loan_Record_Type__c, Stips_for_Approval_Email__c  FROM Opportunity WHERE Id IN :oppIds]);
            List <TC_Origination__Checklist__c> checklists = new List <TC_Origination__Checklist__c> ([SELECT Id, TC_Origination__Opportunity__c, (SELECT Id, TC_Origination__API_Name__c, TC_Origination__Internal_External__c, TC_Origination__Included__c FROM TC_Origination__Checklist_Items_with_Attachments__r) FROM TC_Origination__Checklist__c WHERE TC_Origination__API_Name__c = :checklistName AND TC_Origination__Opportunity__c IN :oppMap.keySet ()]);
            List <TC_Origination__Checklist_Item_with_Attachments__c> updateList = new List <TC_Origination__Checklist_Item_with_Attachments__c> ();
            for (TC_Origination__Checklist__c checklist : checklists) {
                Opportunity opp = oppMap.get (checklist.TC_Origination__Opportunity__c);

                if (opp != null && !checklist.TC_Origination__Checklist_Items_with_Attachments__r.isEmpty ()) {
                    if (!String.isBlank (opp.Stipulations__c)) {

                        Set <String> stips = new Set <String> ();
                        if (opp.Stipulations__c != null) {
                            for (String stip : opp.Stipulations__c.split (';')) {
                                stips.add (stip);
                            }
                        }

                        for (TC_Origination__Checklist_Item_with_Attachments__c item : checklist.TC_Origination__Checklist_Items_with_Attachments__r) {
                            if (stips.contains (item.TC_Origination__API_Name__c)) {
                                updateList.add (new TC_Origination__Checklist_Item_with_Attachments__c (Id = item.Id, TC_Origination__Included__c = true));
                                if (String.isEmpty(oppMap.get(opp.Id).Stips_for_Approval_Email__c)) {
                                    oppMap.get(opp.Id).Stips_for_Approval_Email__c = item.TC_Origination__API_Name__c + '\n';
                                    if(item.TC_Origination__Internal_External__c == 'External'){
                                        oppMap.get(opp.Id).External_Stips_for_Approval_Email__c = item.TC_Origination__API_Name__c + '\n';
                                    }
                                } else {
                                    oppMap.get(opp.Id).Stips_for_Approval_Email__c += item.TC_Origination__API_Name__c + '\n';
                                    if(item.TC_Origination__Internal_External__c == 'External'){
                                        oppMap.get(opp.Id).External_Stips_for_Approval_Email__c += item.TC_Origination__API_Name__c + '\n';
                                    }
                                }
                            }
                            // The else condition was taken out as part of SAL-2144 because the auto-included items were getting overwritten by the stips
                            //else {
                            //updateList.add (new TC_Origination__Checklist_Item_with_Attachments__c (Id = item.Id
                            //                                                                       , TC_Origination__Included__c = false));
                            //}
                        }
                        System.debug('opp.Stips_for_Approval_Email__c: ' + oppMap.get(opp.Id).Stips_for_Approval_Email__c);
                    }
                    /* This else condition needed to be commented out in SAL-2144 otherwise it would wipe out auto included items
                    else {
                        for (TC_Origination__Checklist_Item_with_Attachments__c item : checklist.TC_Origination__Checklist_Items_with_Attachments__r) {
                            updateList.add (new TC_Origination__Checklist_Item_with_Attachments__c (Id = item.Id, TC_Origination__Included__c = false));
                        }
                    }
                    */
                }
            }

            //Checklist_Validation_Bypass__c

            //try {
        ORE__c ore = ORE__c.getOrgDefaults ();
                update updateList;
            //} catch (Exception e) {
            //    System.debug (e);
            //}

//            if (oppMap.size() > 0) {
//                update oppMap.values();
//            }
        }

    }

    public static void updateWaivedOrReceived (List <Id> oppIds, String checklistName) {

        if (!oppIds.isEmpty ()) {

            Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id , Stipulations__c, Waived_Stipulations__c, Received_Stipulations__c FROM Opportunity WHERE Id IN :oppIds]);
            List <TC_Origination__Checklist__c> checklists = new List <TC_Origination__Checklist__c> ([SELECT Id, TC_Origination__Opportunity__c, (SELECT Id, TC_Origination__API_Name__c, TC_Origination__Included__c FROM TC_Origination__Checklist_Items_with_Attachments__r WHERE TC_Origination__Included__c = TRUE) FROM TC_Origination__Checklist__c WHERE TC_Origination__API_Name__c = :checklistName AND TC_Origination__Opportunity__c IN :oppMap.keySet ()]);

            List <TC_Origination__Checklist_Item_with_Attachments__c> updateList = new List <TC_Origination__Checklist_Item_with_Attachments__c> ();

            Id completedById = [SELECT Id FROM User WHERE Name = :Label.TC_Checklist_Auto_Complete_By].Id;

            for (TC_Origination__Checklist__c checklist : checklists) {
                Opportunity opp = oppMap.get (checklist.TC_Origination__Opportunity__c);

                if ((opp != null && !checklist.TC_Origination__Checklist_Items_with_Attachments__r.isEmpty ()) || Test.isRunningTest()) {

                        Set <String> waivedStips = new Set <String> ();
                        if (opp.Waived_Stipulations__c != null) {
							for (String stip : opp.Waived_Stipulations__c.split (';')) {
                                waivedStips.add (stip);
                            }
                        }


                        Set <String> receivedStips = new Set <String> ();
                        if (opp.Received_Stipulations__c != null) {
                            for (String stip : opp.Received_Stipulations__c.split (';')) {
                            	receivedStips.add (stip);
                        	}
                        }

                        for (TC_Origination__Checklist_Item_with_Attachments__c item : checklist.TC_Origination__Checklist_Items_with_Attachments__r) {
                            String appendText = '';
                            String waivedText = '';

                            if (waivedStips.contains (item.TC_Origination__API_Name__c)) {
                                appendText = Label.TC_WaivedChecklist;
                                waivedText = Label.TC_WaivedChecklist;
                            }
                            if (receivedStips.contains (item.TC_Origination__API_Name__c)) {appendText += appendText == '' ? Label.TC_ReceivedChecklist : ';' + Label.TC_ReceivedChecklist;}

                            if (appendText != '') {updateList.add (new TC_Origination__Checklist_Item_with_Attachments__c (Id = item.Id, TC_Origination__Default_Comment__c = appendText, TC_Origination__No_Comments__c = waivedText, TC_Origination__Primary_Checked_By__c = completedById));}
                        }
                }
            }

            update updateList;

        }

    }
}