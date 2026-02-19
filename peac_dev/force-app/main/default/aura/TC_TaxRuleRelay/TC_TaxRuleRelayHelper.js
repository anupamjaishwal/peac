({
    // Invokes the subscribe method on the empApi component
    subscribe : function(component, event, helper) { 
        // Get the empApi component
        const empApi = component.find('empApi');
        // Get the channel from the input box /event/Run_Tax_Rules__e
        //const channel = component.find('channel').get('v.value');
        const channel = '/event/Run_Tax_Rules__e';
        // Replay option to get new events
        const replayId = -1;

        // Subscribe to an event
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            // Process event (this is called each time we receive an event)
            if (eventReceived.data.payload.Record_Id__c == component.get ('v.recordId')) {
            	var spinner = component.find('spinner');
            	if (eventReceived.data.payload.Status__c == 'Submitted') {
        			//$A.util.toggleClass(spinner, 'slds-show');
            		$A.util.removeClass(spinner, 'slds-hide');
            		$A.util.addClass(spinner, 'slds-show')
            		//alert ('Submitted event ', JSON.stringify(eventReceived));
        		} else if (eventReceived.data.payload.Status__c == 'Completed') {
        			$A.util.removeClass(spinner, 'slds-show');
            		$A.util.addClass(spinner, 'slds-hide')
                    //alert ('completed event ', JSON.stringify(eventReceived));
        			$A.get('e.force:refreshView').fire();
        		}
        	}
            
        	
        }))
        .then(subscription => {
            // Confirm that we have subscribed to the event channel.
            // We haven't received an event yet.
            //alert ('Subscribed to channel ', subscription.channel);
            // Save subscription to unsubscribe later
            component.set('v.subscription', subscription);
        });
    },
})