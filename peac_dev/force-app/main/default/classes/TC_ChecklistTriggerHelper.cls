/**
 * Created by corycafferty on 2019-02-14.
 */

public without sharing class TC_ChecklistTriggerHelper {


	public static void updateDependentCheckLists(List<TC_Origination__Checklist__c> newlist){
		Set<String> setCheckListIds = new Set<String>();
		Set<Id> oppIdsForQuery = new Set<Id>();
		for(TC_Origination__Checklist__c objCIA : newlist) {
			setCheckListIds.add(objCIA.Id);
			if (objCIA.TC_Origination__Opportunity__c != null)
				oppIdsForQuery.add(objCIA.TC_Origination__Opportunity__c);
		}
		System.debug('setCheckListIds'+setCheckListIds);
		List<TC_Origination__Checklist__c> lstCL = [Select Id, Name,TC_Origination__Opportunity__c, (Select Id, Name, TC_Origination__Primary_Reviewer__c, TC_Origination__Included__c from TC_Origination__Checklist_Items_with_Attachments__r) from TC_Origination__Checklist__c where TC_Origination__Opportunity__c IN : oppIdsForQuery];

		Map<String, String> mapNameToCLId = new Map<String, String>();
		Map<Id, Map<String, Boolean> > mapOppToCheckListToCItems = new Map<Id, Map<String, Boolean> >();
		Map<String, Map<String, Boolean> > mapCheckListToCItems = new Map<String, Map<String, Boolean> >();

		Set<Id> setOppIds = new Set<Id>();
		Map<Id, List<TC_Origination__Checklist__c> > mapOppToCheckList = new Map<Id, List<TC_Origination__Checklist__c> >();
		for(TC_Origination__Checklist__c objCL : lstCL) {
			setOppIds.add(objCL.TC_Origination__Opportunity__c);
			mapNameToCLId.put(objCL.Name, objCL.Id);
			System.debug('size()'+objCL.TC_Origination__Checklist_Items_with_Attachments__r.size());
			Map<String, Boolean> mapCheckListItem = new Map<String, Boolean>();
			for(TC_Origination__Checklist_Item_with_Attachments__c objTCIA : objCL.TC_Origination__Checklist_Items_with_Attachments__r) {
				mapCheckListItem.put(objTCIA.Name, objTCIA.TC_Origination__Included__c);
				System.debug('name of LI'+objTCIA.Name);

				if(mapOppToCheckListToCItems.containsKey(objCL.TC_Origination__Opportunity__c)) {
					mapOppToCheckListToCItems.get(objCL.TC_Origination__Opportunity__c).put(objTCIA.Name, objTCIA.TC_Origination__Included__c);
				}else{
					mapOppToCheckListToCItems.put(objCL.TC_Origination__Opportunity__c, mapCheckListItem);
				}
			}
			if(mapOppToCheckList.containsKey(objCL.TC_Origination__Opportunity__c)) {
				mapOppToCheckList.get(objCL.TC_Origination__Opportunity__c).add(objCL);
			}else{
				List<TC_Origination__Checklist__c> lstCLNew = new List<TC_Origination__Checklist__c>();
				lstCLNew.add(objCL);
				mapOppToCheckList.put(objCL.TC_Origination__Opportunity__c, lstCLNew);
			}

		}
		Map<Id, Opportunity> mapIdToOpportunity = new Map<Id, Opportunity>();
		for(Opportunity opp : [Select Id, StageName, Equipment_Cost__c, Branch__c, MSRP__c from Opportunity where Id IN : setOppIds]) {
			mapIdToOpportunity.put(opp.Id, opp);
		}
		List<TC_Origination__Checklist_Item_with_Attachments__c> lstCheckLsitItemsTOUpdate = new List<TC_Origination__Checklist_Item_with_Attachments__c>();
		for(String s : mapOppToCheckList.keySet()) {
			Boolean hadMuncipleStipIncluded = false;
			for(TC_Origination__Checklist__c checkList : mapOppToCheckList.get(s) ) {
				for(TC_Origination__Checklist_Item_with_Attachments__c objTCIA : checkList.TC_Origination__Checklist_Items_with_Attachments__r) {
					System.debug('mapOppToCheckListToCItems'+mapOppToCheckListToCItems);
					if(mapIdToOpportunity.containsKey(s)) {
						//condition for SAL-2156
						System.debug('within Contains OppID ');
						if(mapIdToOpportunity.get(s).StageName == 'Docs In' && mapIdToOpportunity.get(s).Equipment_Cost__c > 75000 && objTCIA.Name == 'OPINION OF COUNSEL') {
							System.debug('Inside First If');
							System.debug('mapOppToCheckListToCItems.get'+mapOppToCheckListToCItems.get(s));
							if(mapOppToCheckListToCItems.containsKey(checkList.TC_Origination__Opportunity__c) && mapOppToCheckListToCItems.get(checkList.TC_Origination__Opportunity__c).containsKey('Municipality Resolution or Municipality Purchase Order') && mapOppToCheckListToCItems.get(checkList.TC_Origination__Opportunity__c).get('Municipality Resolution or Municipality Purchase Order')) {
								System.debug('Inside second If');
								objTCIA.TC_Origination__Included__c = true;
								lstCheckLsitItemsTOUpdate.add(objTCIA);
							}

						}


						//condition for SAL-2136
						if(objTCIA.Name == 'MSRP') {

							if(mapIdToOpportunity.get(s).Branch__c == 'Office Equip Group-OEG' && mapIdToOpportunity.get(s).MSRP__c != null && mapIdToOpportunity.get(s).Equipment_Cost__c > 1.3 * mapIdToOpportunity.get(s).MSRP__c) {
								objTCIA.TC_Origination__Included__c = true;
								lstCheckLsitItemsTOUpdate.add(objTCIA);
							}

						}

					}
					//Condition For SAL-2138
					if(objTCIA.Name == 'Municipal addendum') {

						if(mapOppToCheckListToCItems.containsKey(checkList.TC_Origination__Opportunity__c) && mapOppToCheckListToCItems.get(checkList.TC_Origination__Opportunity__c).containsKey('Municipality Resolution or Municipality Purchase Order') && mapOppToCheckListToCItems.get(checkList.TC_Origination__Opportunity__c).get('Municipality Resolution or Municipality Purchase Order')) {
							objTCIA.TC_Origination__Included__c = true;
							lstCheckLsitItemsTOUpdate.add(objTCIA);
						}

					}


					//condition for SAL-2155
					if(objTCIA.Name == 'Invoice') {

						if(mapOppToCheckListToCItems.containsKey(checkList.TC_Origination__Opportunity__c) && mapOppToCheckListToCItems.get(checkList.TC_Origination__Opportunity__c).containsKey('Itemized Invoice') && !mapOppToCheckListToCItems.get(checkList.TC_Origination__Opportunity__c).get('Itemized Invoice')) {
							objTCIA.TC_Origination__Included__c = true;
							lstCheckLsitItemsTOUpdate.add(objTCIA);
						}

					}


				}

			}
		}

		update lstCheckLsitItemsTOUpdate;


	}

	public static void mapCreditStipsToFundingBookingChecklists (Map <Id, TC_Origination__Checklist__c> newMap) {

		Set <Id> oppIds = new Set<Id> ();

		for (TC_Origination__Checklist__c checklist : newMap.values()) {
			if(checklist.Checklist_Template_Name__c != null) {
				if (checklist.Checklist_Template_Name__c.contains('Funding Booking Lease')) {
					oppIds.add(checklist.TC_Origination__Opportunity__c);
				}
			}
		}

		if (!oppIds.isEmpty()) {
			List <TC_Origination__Checklist__c> oppChecklists = [SELECT Id, TC_Origination__API_Name__c, TC_Origination__Opportunity__c, (SELECT Id, Name, TC_Origination__Included__c, TC_Origination__Is_Complete__c, TC_Origination__Primary_Reviewer__c, TC_Origination__No_Comments__c, TC_Origination__Primary_Checked_By__c, TC_Origination__Primary_Completed_Date__c FROM TC_Origination__Checklist_Items_with_Attachments__r) FROM TC_Origination__Checklist__c WHERE TC_Origination__Opportunity__c IN :oppIds];

			Map <Id, List<TC_Origination__Checklist__c> > mapOppIdToChecklists = new Map <Id, List<TC_Origination__Checklist__c> > ();
			for (TC_Origination__Checklist__c checklist : oppChecklists) {
				if (mapOppIdToChecklists.get(checklist.TC_Origination__Opportunity__c) == null) {
					mapOppIdToChecklists.put(checklist.TC_Origination__Opportunity__c, new List <TC_Origination__Checklist__c> {
						checklist
					});
				} else {
					mapOppIdToChecklists.get(checklist.TC_Origination__Opportunity__c).add(checklist);
				}
			}

			List <TC_Origination__Checklist_Item_with_Attachments__c> upsertItemList = new List <TC_Origination__Checklist_Item_with_Attachments__c> ();

			for (Id oppId : mapOppIdToChecklists.keySet()) {
				Map <String, TC_Origination__Checklist_Item_with_Attachments__c> mapItemNameToItemRecord = new Map <String, TC_Origination__Checklist_Item_with_Attachments__c> ();

				for (TC_Origination__Checklist__c checklist : mapOppIdToChecklists.get(oppId)) {
					if (checklist.TC_Origination__API_Name__c == 'Credit Stips') {
						for (TC_Origination__Checklist_Item_with_Attachments__c item : checklist.TC_Origination__Checklist_Items_with_Attachments__r) {
							mapItemNameToItemRecord.put(item.Name, item);
						}
						break;
					}
				}

				if (!mapItemNameToItemRecord.isEmpty()) {

					for (TC_Origination__Checklist__c checklist : mapOppIdToChecklists.get(oppId)) {
						if (checklist.TC_Origination__API_Name__c == 'Funding Booking Lease') {
							for (TC_Origination__Checklist_Item_with_Attachments__c item : checklist.TC_Origination__Checklist_Items_with_Attachments__r) {
								if (mapItemNameToItemRecord.get(item.Name) != null && mapItemNameToItemRecord.get(item.Name).TC_Origination__Included__c) {
									item.TC_Origination__Included__c = true;
									if (mapItemNameToItemRecord.get(item.Name).TC_Origination__Is_Complete__c) item.TC_Origination__Primary_Reviewer__c = true;
									if (mapItemNameToItemRecord.get(item.Name).TC_Origination__No_Comments__c != null) item.TC_Origination__No_Comments__c = mapItemNameToItemRecord.get(item.Name).TC_Origination__No_Comments__c;
									if (mapItemNameToItemRecord.get(item.Name).TC_Origination__Primary_Checked_By__c != null) item.TC_Origination__Primary_Checked_By__c = mapItemNameToItemRecord.get(item.Name).TC_Origination__Primary_Checked_By__c;
									if (mapItemNameToItemRecord.get(item.Name).TC_Origination__Primary_Completed_Date__c != null) item.TC_Origination__Primary_Completed_Date__c = mapItemNameToItemRecord.get(item.Name).TC_Origination__Primary_Completed_Date__c;
									upsertItemList.add(item);
								}
							}
						}
					}

				}

			}

			if (!upsertItemList.isEmpty()) upsert upsertItemList;
		}

	}

	public static void uncheckChecklistComplete (Map <Id, TC_Origination__Checklist__c> oldMap, Map <Id, TC_Origination__Checklist__c> newMap) {
		List <Opportunity> updateList = new List <Opportunity> ();
		Map <Id, Opportunity> updateMap = new Map <Id, Opportunity> ();

		for (TC_Origination__Checklist__c checklist : newMap.values ()) {
			if (oldMap.get (checklist.Id).TC_Origination__Status__c == 'Complete' && checklist.TC_Origination__Status__c != 'Complete') {

				// if there's more than 2 checklists build a helper function
				if (checklist.TC_Origination__API_Name__c == 'Funding Booking Loan') {
					if (updateMap.get (checklist.TC_Origination__Opportunity__c) != null) {
						updateMap.get (checklist.TC_Origination__Opportunity__c).Funding_Booking_Loan_Completed_Date__c = null;
					} else {
						updateMap.put (checklist.TC_Origination__Opportunity__c, new Opportunity (Id = checklist.TC_Origination__Opportunity__c, Funding_Booking_Loan_Completed_Date__c = null));
					}
				} else if (checklist.TC_Origination__API_Name__c == 'Loan Credit Stips') {
					if (updateMap.get (checklist.TC_Origination__Opportunity__c) != null) {
						updateMap.get (checklist.TC_Origination__Opportunity__c).Credit_Stips_Completed_Date__c = null;
					} else {
						updateMap.put (checklist.TC_Origination__Opportunity__c, new Opportunity (Id = checklist.TC_Origination__Opportunity__c, Credit_Stips_Completed_Date__c = null));
					}
				}

			}
		}

		if (!updateMap.isEmpty()) update updateMap.values();
	}


}