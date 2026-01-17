import { LightningElement, wire, api, track } from 'lwc';
import getSobjectRecords from '@salesforce/apex/SL_DataTableController.getSobjectRecords';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { refreshApex } from '@salesforce/apex';
import { reduceErrors, showToast } from 'c/sl_Utils';

let typeAttributes = {
  day:      "numeric",
  month:    "short", 
  year:     "numeric",
  hour:     "2-digit",
  minute:   "2-digit", 
  second:   "2-digit",
  hour12:   true, 
  timeZone: TIME_ZONE
};

export default class Sl_DataTable extends LightningElement {
  @track recordsToDisplay = [];
  myData  = [];
  myColumns;
  nameURL;
  divHeight;
  dataSize;
  wiredResult;
  isLoading = false;
  @api height;
  @api sObjectName;
  @api fieldSetName;
  @api iconName;
  @api recordId               = '';
  @api sObjectLookupIDField   = '';
  @api additionalWhereClause  = '';
  @api tableTitle             = '';
  @api includeName            = false;
  @api orderBy                = '';
  @api sitePath               = '';

  @wire(getSobjectRecords,({sObjectName : '$sObjectName', fieldSetName : '$fieldSetName', recordId : '$recordId', 
                            sObjectLookupIDField : '$sObjectLookupIDField', additionalWhereClause : '$additionalWhereClause',
                            includeName: '$includeName', orderBy: '$orderBy'}))
  wiredAccounts(result){
    this.wiredResult = result;
    // Destructure the provisioned value 
    const { data, error } = result;
    if(data){
      if(this.includeName){
        let nameField = [{
          label:  'Name',
          fieldName:  'nameURL',
          type: 'url',
          typeAttributes: 
          {
            label:  
            { 
              fieldName: 'Name'
            },
            target: '_self'
          },
          sortable: false
        }];

        this.myColumns  = nameField.concat(data.listColumns);

        let nameURL;
        this.myData = data.dataTableData.map(item => {
          if(this.sitePath){
            nameURL = `${this.sitePath}${this.sObjectName.toLowerCase()}/${item.Id}`;
          }else{
            nameURL = `/${item.Id}`;
          }
          return {...item, nameURL}
        });
      }else{
        this.myColumns  = data.listColumns;
        this.myData     = data.dataTableData;
      }
      this.myColumns  = this.convertDateTime(this.myColumns);
      this.myData     = this.formatData(this.myData);
      this.divHeight  = `max-height:${this.height}px;overflow:auto`;
      this.dataSize   = this.myData.length;
      setTimeout(() => {
        this.template.querySelector('c-sl_datatable-paginator').setRecordsToDisplay();
      }, 0);
    }else if(error){
      this.myData     = undefined;
      this.myColumns  = undefined;
      this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "),'error'));
    }
  }

  convertDateTime(columns){
    return columns.map(item => {
      if(item === 'date'){
        return {...item, typeAttributes};
      }else{
        return item;
      }
    });
  }

  formatData(data){
    let dataArr = []; 
    for (let row of data) {
      const flattenedRow = {}
      let rowKeys = Object.keys(row); 

      rowKeys.forEach((rowKey) => {
        const singleNodeValue = row[rowKey];
        
        //check if the value is a node(object) or a string
        if(singleNodeValue.constructor === Object){
          //if it's an object flatten it
          this._flatten(singleNodeValue, flattenedRow, rowKey)        
        }else{
          //if it's a normal string push it to the flattenedRow array
          flattenedRow[rowKey] = singleNodeValue;
        }
      });
        
      //push all the flattened rows to the final array 
      dataArr.push(flattenedRow);
    }
    return dataArr;
  }

  _flatten = (nodeValue, flattenedRow, nodeName) => {        
    let rowKeys = Object.keys(nodeValue);
    rowKeys.forEach((key) => {
      let finalKey = nodeName + '.'+ key;
      flattenedRow[finalKey] = nodeValue[key];
    })
  }

  async handleRefresh() {
    try {
      this.isLoading  = true;
      await refreshApex(this.wiredResult);
      this.isLoading  = false;
    } catch (error) {
      this.dispatchEvent(showToast('Error', reduceErrors(error).join(", "),'error'));
      this.isLoading  = false;
    }
   
  }

  // Capture the event fired from the paginator component
  handlePaginatorChange(event) {
    this.recordsToDisplay = this.formatData(event.detail);
  }

}