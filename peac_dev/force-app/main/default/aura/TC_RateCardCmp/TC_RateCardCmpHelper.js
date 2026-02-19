({
     
  getRows : function(cmp) {
    return new Promise(function(resolve, reject){
      console.log('cmp='+cmp);
      var rateCardId = cmp.get("v.rateCardId");
      var action = cmp.get("c.getRows");
      var params = {"rateCardId":rateCardId};
      action.setParams(params);
      console.log ('getting rows for [ '+ rateCardId + ']');
      action.setCallback(this, function(response) {
          try {
              var state = response.getState();
              if (cmp.isValid() && state === "SUCCESS") {
                  console.log ('done getting rows', response.getReturnValue());
                  cmp.set ("v.rateCardRows", response.getReturnValue());
                  resolve(response.getReturnValue()); // Resolve the promise with the result
                  
              } else {
                  console.log ('Error : ' + state);
                  console.log (response.getError()[0].message);
                  reject(response.getError()[0].message); // Reject the promise with the error message
              }
              
          }
          catch (e) {
              console.log('Exception ' + e);
              reject(e); // Reject the promise if an exception occurs
          }
      });
      $A.enqueueAction(action); 
    });
  },
  getColumns : function(cmp) {
    return new Promise(function(resolve, reject) {
      console.log('cmp='+cmp);
      var rateCardId = cmp.get("v.rateCardId");
      var action = cmp.get("c.getColumns");
      var params = {"rateCardId":rateCardId};
      action.setParams(params);
      console.log ('getting columns for [ '+ rateCardId + ']');
      action.setCallback(this, function(response) {
          try {
              var state = response.getState();
              if (cmp.isValid() && state === "SUCCESS") {
                  console.log ('done getting columns', response.getReturnValue());
                  cmp.set ("v.rateCardCols", response.getReturnValue());
                  resolve(response.getReturnValue()); // Resolve the promise with the result
                  
              } else {
                  console.log ('Error : ' + state);
                  console.log (response.getError()[0].message);
                  reject(response.getError()[0].message); // Reject the promise with the error message
              }
              
          }
          catch (e) {
              console.log('Exception ' + e);
              reject(e); // Reject the promise if an exception occurs
          }
      });
      $A.enqueueAction(action); 
    });
  },
  saveChanges : function (cmp, event, shouldNavigateBack){
    return new Promise(function(resolve, reject){
      console.log ('saving rate card');

      var action = cmp.get("c.saveRateCardValues");
      console.log('action = ' + action);
      
      
      console.log(' here 0.1 ');
      
      var rateCardId = cmp.get("v.rateCardId");        
      var rateCardCols = cmp.get("v.rateCardCols");
      
      console.log(' here 0.2 ');
      var rateList = []; 
      console.log(' here 0.3 ');
      //populate transactions map
      for (var i=0; i<rateCardCols.length; i++) {
          console.log('loop 1')
          for (var j=0; j<rateCardCols[i].Rate_Card_Rates__r.length; j++) {
              console.log('loop 2');
              //copy the obj without reference.
              let rcr = Object.assign({},rateCardCols[i].Rate_Card_Rates__r[j]);
              console.log('rate = ' + rcr.Rate__c);
              delete rcr.TempResidual;
              rateList.push(rcr);
          }
      }
      
      console.log('rateList = ' , rateList);
           

      var params = {"rateCardId":rateCardId,"rateList":rateList};
      console.log(' here 1 ');
 
      action.setParams(params);
      console.log(' here 2 ');

      action.setCallback(this, function(response) {
          
          console.log(' here 3 ');

          try {
              var state = response.getState();
              console.log(' here 4 ');
              if (cmp.isValid() && state === "SUCCESS") {
                  console.log(' here 5 ');
                  
                  cmp.set ("v.rateCardCols", response.getReturnValue());
                  
                  if (shouldNavigateBack){
                    this.navigateBackToRateCard(cmp);
                  }else{
                    resolve(response.getReturnValue()); // Resolve the promise with the result
                  }
                      
                  
              } else {
                  console.log(' here 6 ');
                  console.log ('Error : ' + state);
                  console.log (response.getError()[0].message);
                  reject(response.getError()[0].message); // Reject the promise with the error message
              }
              
          }
          catch (e) {
              console.log('Exception ' + e);
              reject(e); // Reject the promise if an exception occurs
          }
         
      });
      $A.enqueueAction(action);
    });
  },
  
  navigateBackToRateCard : function (cmp) {
      var sObjectEvent = $A.get("e.force:navigateToSObject");
      var rateCardId = cmp.get("v.rateCardId");
      // Check if we are in S1 or LEX. If not, sObjectEvent will be undefined
      if(sObjectEvent){
          
          sObjectEvent.setParams({
              "rateCardId": rateCardId,
          })
          
          sObjectEvent.fire();            
      } else {
          window.location.assign('/' + rateCardId);
      }      
  },

  //DP-153 To display the Residual__c value on the table if the Condition Value is FMV.
  getConditionValue : function(cmp, value) {
    return new Promise(function(resolve, reject) {
      let rateCardId = cmp.get("v.rateCardId");
      let action = cmp.get("c.getConditionValue");
      let params = {
        rateCardId,
        value
      };
      action.setParams(params);
      action.setCallback(this, function(response) {
        try {
          var state = response.getState();
          if (cmp.isValid() && state === "SUCCESS") {
            cmp.set("v.conditionValue", response.getReturnValue());
            resolve(response.getReturnValue()); // Resolve the promise with the result
          } else {
            console.log ('Error : ' + state);
            console.log (response.getError()[0].message);
            reject(response.getError()[0].message); // Reject the promise with the error message
          }
        }
        catch (e) {
          console.log('Exception ' + e);
          reject(e); // Reject the promise if an exception occurs
      }
      });
      $A.enqueueAction(action); 
    });
  },

  getResidual : function(cmp, isReset, value) {
    console.log('cmp.get("v.conditionValue")',cmp.get("v.conditionValue"));
    //Check if the Rate card is for value (FMV)
    if(cmp.get("v.conditionValue") !== value){
      return;
    }
    
    //add rows only if the value is non null on columns.
    /*function checkResidual(item) {
     return item.hasOwnProperty('Residual__c');
    }*/

    // Function to add residual row to the last position
    function addResidualRow(ROWS) {
      const LAST_ROW = ROWS.slice(-1);
      let residualRow = {
        'Name': 'Residual',
        'Order__c': LAST_ROW.Order__c++
      };
      if(!isReset){
        ROWS.push(residualRow);
      }
    }

    //const COLUMNS = cmp.get('v.rateCardCols');
    let ROWS      = cmp.get('v.rateCardRows');
    //let hasResidual = COLUMNS.some(checkResidual);

    //if(hasResidual){
      //add residual row to the last position
      addResidualRow(ROWS);
    //}
    cmp.set('v.rateCardRows', ROWS);
    cmp.set("v.isConditionMatching", true);
  },
})