/**
 * Created on 12/19/17.
 */
({
    getPageParameters: function (cmp) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var pageParams = {};

        sURLVariables.forEach(function (val) {
            pageParams[val.split('=')[0]] = val.split('=')[1];
        });

        return pageParams;
    },
    
    //SAL-6447 - fetch quoteids from URL and prepopulate fields
    fetchAndPopulateQuotes: function(cmp, quoteIds) {
        var action = cmp.get("c.getQuoteDetailsByIds");
        action.setParams({ "quoteIds": quoteIds });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var quoteData = response.getReturnValue();
                
                if (quoteData) {

                    // Also populate the clientWrapper.deal.opportunity fields so child components pick them up
                    var clientWrapper = cmp.get('v.clientWrapper');
                    if (!clientWrapper) {
                        clientWrapper = { deal: { opportunity: {} } };
                    } else if (!clientWrapper.deal) {
                        clientWrapper.deal = { opportunity: {} };
                    } else if (!clientWrapper.deal.opportunity) {
                        clientWrapper.deal.opportunity = {};
                    }

                    try {
                        // Map quote into the clientWrapper.equipment list (TC_RecordWrapper.equipment = Asset__c)
                        if (!clientWrapper.equipment || !Array.isArray(clientWrapper.equipment)) {
                            clientWrapper.equipment = [];
                        }

                        var eqWrapper = { equipment: {} };
                        eqWrapper.equipment.Description__c = quoteData.Quote__r.Description || null;
                        // Use Cost__c on the Asset wrapper to hold the quoted total cost
                        eqWrapper.equipment.Cost__c = quoteData.tval__Quote_Amount__c || null;
                        eqWrapper.equipment.Equipment_Code__c = quoteData.Quote__r.Equipment_Type__c || null;

                        // Insert populated equipment: replace an empty placeholder if present, otherwise append
                        var replaced = false;
                        for (var i = 0; i < clientWrapper.equipment.length; i++) {
                            var existing = clientWrapper.equipment[i];
                            if (!existing || !existing.equipment) {
                                clientWrapper.equipment[i] = eqWrapper;
                                replaced = true;
                                break;
                            }
                            // consider an equipment entry 'empty' if it has no meaningful fields
                            var keys = Object.keys(existing.equipment || {});
                            if (keys.length === 0 || ((existing.equipment.Description__c == null || existing.equipment.Description__c === '') && (existing.equipment.Cost__c == null || existing.equipment.Cost__c === ''))) {
                                clientWrapper.equipment[i] = eqWrapper;
                                replaced = true;
                                break;
                            }
                        }

                        if (!replaced) {
                            clientWrapper.equipment.push(eqWrapper);
                        }

                        // Keep opportunity-level fields in sync for compatibility
                        if (clientWrapper.deal && clientWrapper.deal.opportunity) {
                            clientWrapper.deal.opportunity.Equipment_Description__c = quoteData.Quote__r.Description;
                            clientWrapper.deal.opportunity.Equipment_Code__c = quoteData.Quote__r.Equipment_Type__c;
                            clientWrapper.deal.opportunity.Equipment_Cost__c = quoteData.tval__Quote_Amount__c;
                            clientWrapper.deal.opportunity.Terms__c = quoteData.tval__Term__c;
                            clientWrapper.deal.opportunity.Purchase_Options__c = quoteData.tval__Purchase_Option__c;
                            clientWrapper.deal.opportunity.Payment_Frequency__c = quoteData.tval__Period__c;
                        }

                        // Persist changes back to component attributes so child components receive them
                        cmp.set('v.clientWrapper', clientWrapper);
                        cmp.set('v.equipmentList', clientWrapper.equipment);
                    } catch (e) {
                        console.warn('Unable to map quote data into clientWrapper.equipment:', e);
                    }
                }
            } else {
                console.error("Error fetching quote details: ", response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    refreshDealGuarantorsView : function (cmp) {
        var dealGuarantorsComp = cmp.find('dealGuarantorsComp');
        dealGuarantorsComp.set('v.company', cmp.get('v.company'));
        dealGuarantorsComp.set('v.guarantors', cmp.get('v.guarantors'));
    },

    refreshDealQuotesView : function (cmp) {
        var dealQuotesComp = cmp.find('dealQuotesComp');
        dealQuotesComp.set('v.company', cmp.get('v.company'));
        dealQuotesComp.set('v.deal', cmp.get('v.deal'));
        console.log('Opportunity detail',cmp.get("v.deal"));
    },

    refreshDealEquipmentView : function (cmp) {
        var dealEquipmentComp = cmp.find('dealEquipmentComp');
        dealEquipmentComp.set('v.company', cmp.get('v.company'));
        dealEquipmentComp.set('v.equipmentList', cmp.get('v.equipmentList'));
        dealEquipmentComp.set('v.deal', cmp.get('v.deal'));
    },

    refreshView : function (cmp) {
        var dealReviewComp = cmp.find('dealReviewComp');
        dealReviewComp.set('v.company', cmp.get('v.company'));
        dealReviewComp.set('v.guarantors', cmp.get('v.guarantors'));
//        dealReviewComp.set('v.quoteOptions', cmp.get('v.quoteOptions'));
        dealReviewComp.set('v.equipmentList', cmp.get('v.equipmentList'));
        dealReviewComp.set('v.deal', cmp.get('v.deal'));
//        dealReviewComp.set('v.totalFinanceAmount', cmp.get('v.totalFinanceAmount'));
//        var docComp = cmp.find('dealDocs');
//        console.log('refreshView', docComp.get('v.fileList'));
//        dealReviewComp.set('v.docs', docComp.get('v.fileList'));
        //Added by Rajesh Kumar(LTIMindtree)
       // $A.get("e.force:refreshView").fire();
    },

    refreshDealDetailsView : function (cmp) {
        var dealDetailsComp = cmp.find('dealDetailsComp');
        dealDetailsComp.set('v.deal', cmp.get('v.deal'));
        dealDetailsComp.set('v.totalFinanceAmount', cmp.get('v.totalFinanceAmount'));
    },

    calculateTotalFinanceAmount : function (cmp) {
        var totalFinanceAmount = 0;
        var equipmentList = cmp.get("v.equipmentList");

        for (var i = 0; i < equipmentList.length; i++) {
            var equipment = equipmentList[i];

            if(equipment.Cost_Per_Unit__c != null && equipment.Quantity__c != null)
                totalFinanceAmount += (equipment.Cost_Per_Unit__c * equipment.Quantity__c);
        }

        cmp.set("v.totalFinanceAmount", totalFinanceAmount);
    },

    getApplicationRecordById: function (cmp) {
        console.log('getApplicationRecordById', cmp.get('v.recordId'));
        
        var action = cmp.get('c.getApplicationById');

        action.setParams({
            appId: cmp.get('v.recordId')
        });

        action.setCallback(this, function (result) {

            if (result.getState() === 'SUCCESS') {
                var appInfo = JSON.parse(result.getReturnValue());
                console.log('getApplicationRecordById appInfo', appInfo);
                cmp.set('v.deal', appInfo.deal);
                cmp.set('v.company', appInfo.company);
                cmp.set('v.quoteOptions', appInfo.quoteOptions);
                // set record type variable after
            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
        });

        $A.enqueueAction(action);

    },

    getAvailableRecordTypesHelper: function (cmp) {
            var action = cmp.get('c.getAvailableRecordTypes');

            action.setCallback(this, function (result) {

                if (result.getState() === 'SUCCESS') {
                    console.log('this works2');
                    var recordTypesReturn = result.getReturnValue();
                    cmp.set('v.availableRecordTypes', recordTypesReturn);



                    var rtList = [];
                    rtList = cmp.get ('v.availableRecordTypes');

                    var clientWrapper = {company : {account : cmp.get ('v.company'), readOnly : false, dupe : false}
                                                                                    , contact : {contact : cmp.get ('v.companyCustomer'), readOnly : false, dupe : false}
                                                                                    , deal : {opportunity : cmp.get ('v.dealOpp'), readOnly : false, dupe : false}
                                                                                    , ccgAccounts : []
                                                                                    , pgContacts : []
                                                                                    , pgs : []
                                                                                    , ccgs : []
                                                                                    , equipment : cmp.get ('v.equipmentList')
                                                                                    , brokerAccounts : cmp.get ('v.brokerList')
                                                                                    , brokers : []
                                                                                    , dealerAccounts : cmp.get ('v.dealersList')
                                                                                    , dealers : []
                                                                                    , franchisorAccounts : cmp.get ('v.franchisorList')
                                                                                    , franchisors : []};



                    if (rtList.length == 2) {
                        clientWrapper.recordTypeName = rtList[1].recordTypeName;
                    } else {
                        clientWrapper.recordTypeName = '';
                    }
                    cmp.set ('v.clientWrapper', clientWrapper); 


                    // Get current user profile name

                    var getCurrentUserProfileAction = cmp.get('c.getCurrentUserProfileName');

                    getCurrentUserProfileAction.setCallback(this, function (result) {

						if (result.getState() === 'SUCCESS') {
							cmp.set ('v.clientWrapper.curentUserProfileName', result.getReturnValue());
                            //Added by Rajesh Kumar(LTIMindtree) to make it dynamic
                            var allowedProfiles = $A.get("$Label.c.PEAC_Quick_Loan_App_Profiles_with_Partner").split(',');
                            var currentProfile = cmp.get("v.clientWrapper.curentUserProfileName");
                            if (allowedProfiles.includes(currentProfile)) {
                                cmp.set("v.isShowAllTabs", true);
                            }           
                             console.log('isShowAllTabs...' + cmp.get("v.isShowAllTabs"));           
							// start get available customer contact roles
 							var getAvailableCustomerContactRoles = cmp.get('c.grabCustomerContactContactRolesInitial');
                            	getAvailableCustomerContactRoles.setCallback(this, function (result) {
									if (result.getState() === 'SUCCESS') {
                                        
                                    	cmp.set ('v.clientWrapper.possibleCustomerContactRoles', result.getReturnValue());
                                    } else {
                                    	console.log(result.getError());
                                    	TCLightningUtils.showToast('Error', result.getError()[0].message, 'error', 'sticky');
                                    }
                            });
        					$A.enqueueAction(getAvailableCustomerContactRoles);
                                        
                                        
                                        
										// end
                                        //alert (result.getReturnValue());

                                    } else {
                                        console.log(result.getError());
                                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error', 'sticky');
                                    }
                                });

                    $A.enqueueAction(getCurrentUserProfileAction);


                } else {
                    console.log('this works3');
                    console.log(result.getError());
                    TCLightningUtils.showToast('Error', result.getError()[0].message, 'error', 'sticky');
                }
            });


            console.log('this works1');
            $A.enqueueAction(action);

        },


    submitDeal: function (cmp) {

        var deal = cmp.get('v.deal');
        console.log('submitDeal start', deal);

        TCLightningUtils.showSpinner(cmp);
        var action = cmp.get('c.submitApplication');

        /*
        console.log('action', action);

        action.setParams({
            companyString: JSON.stringify(cmp.get('v.company')),
            guarantors: JSON.stringify(cmp.get('v.guarantors')),
            ccgGuarantors: JSON.stringify(cmp.get('v.ccgGuarantors')),
            equipmentList: cmp.get('v.equipmentList'),
            dealString: JSON.stringify(deal),
            companyCustomer : JSON.stringify(cmp.get('v.companyCustomer'))
        });

        console.log('action setparams');*/

        action.setParams({
            clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
        });

        action.setCallback(this, function (result) {
            console.log('action setCallback');
            TCLightningUtils.hideSpinner(cmp);
            if (result.getState() === 'SUCCESS') {
                TCLightningUtils.showToast('Success', 'Deal Submitted.', 'success');
                console.log('>>>>NAVIGATION TO URL:' + result.getReturnValue());
                $A.get("e.force:navigateToURL").setParams({ "url": "/" + result.getReturnValue()}).fire();



                //this.navigateToHome();
            } else {
                console.log(result.getError());
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });

        $A.enqueueAction(action);
    },

    navigateToHome: function () {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/'
        });
        urlEvent.fire();
    },

    navigateToRapportHelper: function (cmp) {
            /*var urlEvent = $A.get("e.force:navigateToCmp");
            urlEvent.setParams({
                "url": '/'
            });
            urlEvent.fire();*/
/*

            var newEvent = $A.get("e.force:navigateToComponent");
                    newEvent.setParams({
                        componentDef: "c:MARLIN_RapportAPIAction",
                        componentAttributes: {
                            recordId : cmp.get ('v.clientWrapper.deal.opportunity.Id')
                        }
                    });
                    newEvent.fire();*/
        // save sales comments

        TCLightningUtils.showSpinner(cmp);
        var saveSalesCommentsAction = cmp.get('c.submitApplication');


        saveSalesCommentsAction.setParams({
            clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
        });

        saveSalesCommentsAction.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var callDwhAction = cmp.get('c.callDwhAndAutoPgApi');// SAL-5820 Misael Romero
                callDwhAction.setParams({
                    clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
                });
                callDwhAction.setCallback(this, function (result) {
                    TCLightningUtils.hideSpinner(cmp);
                    if (result.getState() === 'SUCCESS') {
                        var callGdsAction = cmp.get('c.callGdsScoreApex');
                        callGdsAction.setParams({
                            recordId: cmp.get('v.clientWrapper.deal.opportunity.Id')
                        });
                        // callGdsAction.callDwhAction.setCallback(this, function (result) {
                        
                        // });
                        $A.enqueueAction(callGdsAction); // fire and forget
                        var navEvt = $A.get("e.force:navigateToSObject");
                                                navEvt.setParams({
                                                  "recordId": cmp.get ('v.clientWrapper.deal.opportunity.Id'),
                                                  "slideDevName": "detail"
                                                });
                                                navEvt.fire();
                    } else {
                        console.log(result.getError());
                        console.log(result.getError()[0]);
                        console.log(result.getError()[0].message);
                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error', 'sticky');
                    }
                });
                $A.enqueueAction(callDwhAction);
                
                        
                 
                // rapport decom
                /*$A.createComponent("c:MARLIN_RapportAPIAction", {
                            recordId : cmp.get ('v.clientWrapper.deal.opportunity.Id')
                            , fromWizard : true
                    , runGDS : cmp.get ('v.clientWrapper.gdsScoreEnabled')}
                            , function (content, status) {
                                if (status === "SUCCESS") {

                                var modalBody = content;
                                var modalPromise = cmp.find('overlayLib').showCustomModal({
                                    body: modalBody
                                    , showCloseButton: true
                                    , closeCallback: function () {
                                        // not calling GDS from here, because there could be a unsucesfull Rapport submission without the whole process bombing
                                        
                                        // on close actions
                                        //// fire gds score
                                        $A.createComponent("c:tc_gdsScore", {
                                            recordId : cmp.get ('v.clientWrapper.deal.opportunity.Id')
                                            , fromWizard : true}
                                            , function (content, status) {
                                                if (status === "SUCCESS") {
                                                var gdsScoreModalPromise = content;
                                                var gdsScoreModalPromise = cmp.find('overlayLib').showCustomModal({
                                                    body: gdsScoreModalPromise
                                                    , showCloseButton: true
                                                    , closeCallback: function () {}
                                                });
                                                cmp.set("v.gdsScoreModalPromise", gdsScoreModalPromise);   
                                            }
                                        });// end gds score
                                        
                                        
                                    }
                                });
                                cmp.set("v.modalPromise", modalPromise);

                                        }
                        });*/

            } else {
                TCLightningUtils.hideSpinner(cmp);
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
            }
        });

        $A.enqueueAction(saveSalesCommentsAction);


     },


        navigateToCaseCenterHelper: function (cmp) {

                TCLightningUtils.showSpinner(cmp);

                var saveSalesCommentsAction = cmp.get('c.submitApplication');


                saveSalesCommentsAction.setParams({
                    clientWrapperString : JSON.stringify (cmp.get ('v.clientWrapper'))
                });

                saveSalesCommentsAction.setCallback(this, function (result) {
                    TCLightningUtils.hideSpinner(cmp);
                    if (result.getState() === 'SUCCESS') {
                        // case center

                        $A.createComponent("c:MARLIN_CaseCenterAPIAction", {
                                                                            recordId : cmp.get ('v.clientWrapper.deal.opportunity.Id')
                                                                            , fromWizard : true
                                                                        },
                                                                                    function (content, status) {
                                                                                        if (status === "SUCCESS") {

                                                                                            var modalBody = content;
                                                                                            var modalPromise = cmp.find('overlayLib').showCustomModal({
                                                                                                body: modalBody,
                                                                                                showCloseButton: true,
                                                                                                closeCallback: function () {
                                                                                                    //alert('You closed the alert!');
                                                                                                }
                                                                                            });
                                                                                            cmp.set("v.modalPromise", modalPromise);
                                                                                        }
                                                                                    });

                    } else {
                        TCLightningUtils.showToast('Error', result.getError()[0].message, 'error');
                    }
                });

                $A.enqueueAction(saveSalesCommentsAction);
                    /*var urlEvent = $A.get("e.force:navigateToCmp");
                    urlEvent.setParams({
                        "url": '/'
                    });
                    urlEvent.fire();*/
/*

                    var newEvent = $A.get("e.force:navigateToComponent");
                            newEvent.setParams({
                                componentDef: "c:MARLIN_CaseCenterAPIAction",
                                componentAttributes: {
                                    recordId : cmp.get ('v.clientWrapper.deal.opportunity.Id')
                                }
                            });
                            newEvent.fire();*/
                            //alert ('case center');



                },




        //MARLIN_CaseCenterAPIAction



    //MARLIN_RapportAPIAction
})