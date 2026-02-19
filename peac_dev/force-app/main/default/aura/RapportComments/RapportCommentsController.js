({
	openActionWindow1 : function(component, event, helper) {
         window.open("http://njreporting01/ReportServer/Pages/ReportViewer.aspx?%2fCustomer+Service%2fRapportAppComments&rs:Command=Render&AppId={!Opportunity.Application__c}");		
	}
})