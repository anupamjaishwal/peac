/**
 * Created on 12/18/17.
 */
({
    doInit: function (cmp, event, helper) {




        if (cmp.get ('v.isEdit') == false) {





/*
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
                                        //dealOpp

                    cmp.set ('v.clientWrapper', clientWrapper);*/
            helper.getAvailableRecordTypesHelper(cmp);


        } 

        /*else {
            cmp.set ('v.selectedRecordTypeName','Franchise');
        }*/
        //helper.getAvailableRecordTypesHelper(cmp);

        /*var acc = {};
        acc.sobjectType = 'Account';

        var con = {};
        con.sobjectType = 'Contact';

        var clientWrapper = {};

        clientWrapper.company.record = acc;
        clientWrapper.companyCustomer.record = con;

        cmp.set ('v.clientWrapper', clientWrapper);*/




        //console.log('do init');
        //if (!cmp.get('v.fromDetail')) {
        //    cmp.set('v.recordId', helper.getPageParameters(cmp).id);
        //    console.log('doInit', cmp.get('v.recordId'));
            //helper.getApplicationRecordById(cmp);
        //}

        // Capture Quote IDs from the URL State
        var pageRef = cmp.get("v.pageReference");
        if (pageRef && pageRef.state && pageRef.state.c__selectedQuoteIds) {
            var quoteIds = pageRef.state.c__selectedQuoteIds;
            
            // Call helper to fetch quote data and prepopulate fields
            helper.fetchAndPopulateQuotes(cmp, quoteIds);
        }
    },

    refreshDealGuarantorsComponent: function (cmp, event, helper) {
        helper.refreshDealGuarantorsView(cmp);
    },

    refreshDealQuotesComponent: function (cmp, event, helper) {
        helper.refreshDealQuotesView(cmp);
    },

    refreshDealEquipmentComponent: function (cmp, event, helper) {
        helper.refreshDealEquipmentView(cmp);
    },

    refreshDealReviewComponent: function (cmp, event, helper) {
//        helper.calculateTotalFinanceAmount(cmp);
        helper.refreshView(cmp);
        //Added by Rajesh Kumar (LTIMindtree)
        if(cmp.find('loanstatement'))
        {
            cmp.find('loanstatement').getDocumentDetails(cmp.get ('v.clientWrapper.deal.opportunity.Id'));
        }
        
    },

    refreshDealDetailsComponent: function (cmp, event, helper) {
//        helper.calculateTotalFinanceAmount(cmp);
        helper.refreshDealDetailsView(cmp);
    },

    handleTabNavigation: function (cmp, event, helper) {


        var navEventData = event.getParam('data');
        console.log('event triggered handleTabNavigation', navEventData);
        var currentStep = cmp.get('v.currentStep');
        var stepIndex = currentStep.split('_')[1];

        if (navEventData.direction === 'next') {
            stepIndex++;
            cmp.set('v.isButtonNavigation', true);
            cmp.set('v.currentStep', 'step_' + stepIndex);
        } else if (navEventData.direction === 'prev') {
            stepIndex--;
            cmp.set('v.currentStep', 'step_' + stepIndex);
        }
    },

    handleStepClick: function (cmp, event, helper) {

        var currentStep = event.getSource().get('v.value');
        cmp.set('v.currentStep', currentStep);
//        helper.showHideButtons(cmp);
    },

    handleTabSelect: function (cmp, event, helper) {

        var selectedTabId = event.getSource().get('v.selectedTabId');

        // SAL-2289 - force users to go through Guarantors -> Quotes -> Review/Submit tabs using Save & Next button
        if ((selectedTabId === 'step_6' || selectedTabId === 'step_7') && !cmp.get('v.isButtonNavigation')) {
            selectedTabId = 'step_5';
        }

        cmp.set('v.isButtonNavigation', false);
        cmp.set('v.currentStep', selectedTabId);
    },


    goToNext: function (cmp, event, helper) {
//if (cmp.get ('v.clientWrapper.deal.opportunity.Id') != null && cmp.get ('v.clientWrapper.deal.opportunity.Id') != '') {

        var currentStep = cmp.get('v.currentStep');
        var stepIndex = currentStep.split('_')[1];
        stepIndex++;
        cmp.set('v.currentStep', 'step_' + stepIndex);
    },

    goToBack: function (cmp, event, helper) {
        var currentStep = cmp.get('v.currentStep');
        var stepIndex = currentStep.split('_')[1];
        stepIndex--;
        cmp.set('v.currentStep', 'step_' + stepIndex);
    },

    cancel: function (cmp, event, helper) {
        var modalBody;
        $A.createComponent("c:tc_cancelDialogMessage", {
                confirmAction: helper.navigateToHome
            },
            function (content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    cmp.find('overlayLib').showCustomModal({
                        header: "Warning - all changes will be lost!",
                        body: modalBody,
                        showCloseButton: true,
                        cssClass: "cancelModal",
                        closeCallback: function () {
                            concole.log('modal closed');
                        }
                    })

                }

            });
    },

    quickSave: function (cmp, event, helper) {
        helper.saveRecords(cmp, event, helper);
    },

    submitDeal: function (cmp, event, helper) {
       /*var fileList = cmp.get('v.fileList');
       
        if(fileList.length ==  0){
           TCLightningUtils.showToast('Error', 'Please upload the following: 1. Driver\'s License (required) 2. Last 3 months business bank statements - summary pages only (optional)', 'error');
        }else{
            helper.submitDeal(cmp);
        }*/
        helper.submitDeal(cmp);
    },

    //Function to handle the LookupChooseEvent. Sets the chosen record.
    handleCompanyChoose: function (cmp, event, helper) {
        helper.selectCompany(cmp, event);
    },


    submitToRapport: function (cmp, event, helper) {
            helper.navigateToRapportHelper(cmp);
        },
     submitToCaseCenter: function (cmp, event, helper) {
                 helper.navigateToCaseCenterHelper(cmp);
             },
        //navigateToCaseCenterHelper

    //navigateToRapportHelper


})