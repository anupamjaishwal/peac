import { LightningElement, api, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_ID from '@salesforce/schema/User.Contact.AccountId';
import getDealerRep from '@salesforce/apex/SL_DealerRepController.getDealerRep';
import { reduceErrors, showToast } from 'c/sl_Utils';

export default class Sl_DealerReps extends LightningElement {
  @api fieldAPINames;
  userId = Id;
  ACCOUNTID;
  dealerReps;
  wireResultDealers;

  @wire(getRecord, { recordId: Id, fields: [ACCOUNT_ID]}) 
    userDetails({error, data}) {
      if (data) {
        this.ACCOUNTID = data.fields?.Contact.value?.fields.AccountId?.value;
      } else if (error) {
        this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "),'error'));
      }
    }

  @wire(getDealerRep, {accountId : '$ACCOUNTID', fieldAPINames: '$fieldAPINames'})
    wiredDealers(result) {
      this.wireResultDealers = result;
      if (result.data) {
        const CHILD_FIELDS  = this.fieldAPINames.split(',').filter(item => item.includes('.'));
        const CHILD_FIELDS_BY_RELATION_NAME = new Map();
        this.getChildFields(CHILD_FIELDS, CHILD_FIELDS_BY_RELATION_NAME);

        this.wrapResponse(result, CHILD_FIELDS_BY_RELATION_NAME);
      } else if (result.error) {
        this.dispatchEvent(showToast('Error', reduceErrors(result.error).join(", "),'error'));
      }
    }
  
  getChildFields(CHILD_FIELDS, CHILD_FIELDS_BY_RELATION_NAME){
    CHILD_FIELDS.map((item) =>{
      let field = item.split('.');
      const PARENT_FIELD  = field[0].trim();
      const CHILD_FIELD   = field[1].trim();
      if(CHILD_FIELDS_BY_RELATION_NAME.has(PARENT_FIELD)){
        CHILD_FIELDS_BY_RELATION_NAME.get(PARENT_FIELD).push(CHILD_FIELD);
      }else{
        CHILD_FIELDS_BY_RELATION_NAME.set(PARENT_FIELD, [CHILD_FIELD]);
      }
    });
  }

  wrapResponse(response, CHILD_FIELDS_BY_RELATION_NAME, ){
    const isObjectNotEmpty = (objectName) => {
      return (
        objectName &&
        Object.keys(objectName).length > 0 &&
        objectName.constructor === Object
      );
    };

    let dealerReps = [];
            
    for (let childFields of CHILD_FIELDS_BY_RELATION_NAME.keys()) {
      const TEMP_OBJ = {};
      CHILD_FIELDS_BY_RELATION_NAME.get(childFields).forEach((item) => {
        let value = response.data[0][childFields]?.[item];
        if(value){
          if(item.toLowerCase().includes('name')){
            TEMP_OBJ.hasOwnProperty('Name') ? TEMP_OBJ['Name'] += ` ${value}` : TEMP_OBJ['Name'] = value;
          }else{
            TEMP_OBJ[item] = value
          }
        }
      });

      if(isObjectNotEmpty(TEMP_OBJ)){
        dealerReps.push(TEMP_OBJ);
      }
    }

    if(dealerReps.length > 0){
      //Remove dups by converting the array to an String -> Set -> Array.
      const ARR_OBJ    = dealerReps.map(JSON.stringify);
      const UNIQUE_ARR = new Set(ARR_OBJ);
      this.dealerReps  = Array.from(UNIQUE_ARR).map(JSON.parse);
    }
  }

}