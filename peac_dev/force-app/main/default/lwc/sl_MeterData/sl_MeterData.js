import { LightningElement, api, track } from 'lwc';
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getMeterReadData from '@salesforce/apex/SL_MeterDataController.getMeterReadData';
import getAccountHierarchy from '@salesforce/apex/SL_MeterDataController.getAccountHierarchy';
import transform from '@salesforce/apex/SL_MeterDataController.dwCSVtoJson';
import sendMeterFile  from '@salesforce/apex/SL_MeterDataController.sendMeterFile';



const cols = [
  //{ label: "AumtAggrKey", fieldName: "AumtAggrKey", editable: false, sortable: "true" },
  { label: "Contract No.", fieldName: "ContractNo", editable: false ,sortable: "true"},
  { label: "Meter Account", fieldName: "MeterAcct", editable: false,sortable: "true" },
  { label: "Reading Method", fieldName: "Method", editable: false, hidden:true},
  { label: "Read Data", fieldName: "ReadCycle", editable: false },
  { label: "Reading Date", fieldName: "NextRead", editable: false ,sortable: "true"},
  { label: "Description", fieldName: "Descrip", editable: false ,sortable: "true"},
  { label: "Serial No.", fieldName: "Serial", editable: false,sortable: "true" },
  { label: "Prior Reading", fieldName: "PrevRead", editable: false, type:"number", typeAttributes: {maximumFractionDigits: '0'}, sortable: "true" },
  { label: "Current Read Value", fieldName: "CurrentReadValue", editable: true, type:"number" },
  { label: "Copy Credits Count", fieldName: "CopyCreditsCount", editable: true, type:"number" },
  { label: "Dealer Invoice Number", fieldName: "DealerInvoiceNumber", editable: true, typeAttributes: null },
  { label: "Customer Name", fieldName: "CustName", editable: false,sortable: "true" },
  { label: "Asset ID", fieldName: "Asset", sortable: "true" },
  { label: "Prior Reading Date", fieldName: "ReadDate", editable: false, sortable: "true"},
  { label: "Meter Type", fieldName: "ShortDesc", editable: false,sortable: "true" }
 ];


 const cols2 = [
  //{ label: "AumtAggrKey", fieldName: "AumtAggrKey", editable: false, sortable: "true" },
  { label: "Contract No.", fieldName: "ContractNo", editable: false ,sortable: "true" },
  { label: "Meter Account", fieldName: "MeterAcct", editable: false,sortable: "true" },
  { label: "Reading Method", fieldName: "Method", editable: false, hidden:true},
  { label: "Read Data", fieldName: "ReadCycle", editable: false },
  { label: "Reading Date", fieldName: "NextRead", editable: false ,sortable: "true"},
  { label: "Description", fieldName: "Descrip", editable: false ,sortable: "true"},
  { label: "Serial No.", fieldName: "Serial", editable: false,sortable: "true" },
  { label: "Prior Reading", fieldName: "PrevRead", editable: false, type:"number", typeAttributes: {maximumFractionDigits: '0'}, sortable: "true" },
  { label: "Current Read Value", fieldName: "CurrentReadValue", editable: false, type:"number" },
  { label: "Copy Credits Count", fieldName: "CopyCreditsCount", editable: false, type:"number" },
  { label: "Dealer Invoice Number", fieldName: "DealerInvoiceNumber", editable: false, typeAttributes: null },
  { label: "Customer Name", fieldName: "CustName", editable: false,sortable: "true" },
  { label: "Asset ID", fieldName: "Asset", sortable: "true" },
  { label: "Prior Reading Date", fieldName: "ReadDate", editable: false, sortable: "true"},
  { label: "Meter Type", fieldName: "ShortDesc", editable: false,sortable: "true" }

 ];

  const CSVfieldName=['ContractNo','MeterAcct','Method','ReadCycle','NextRead','Descrip','Serial', 'PrevRead', 'CurrentReadValue', 'CopyCreditsCount', 'DealerInvoiceNumber', 'CustName', 'Asset', 'ReadDate', 'ShortDesc']; 

export default class Sl_MeterData extends LightningElement {

  @track COLUMNS= [];
  @track assets = [];
  @track fileData;
  @track recordsToDisplay = [];
  @track validFile = false;
  @track draftValues = [];
  @track dataErrors = {};
  @track sortBy; 
  @track sortDirection; 
  @track empty = false;
  @track viewUploadResults = false;
  @track isShowModal = false;
  @track isSorting = false;
  @track lockedData = [];
  @track lockedColumns=[];
  @track lockedRows = [];
  @track preSelectedRows;
  @track lockedRecordsExist = false;
  @track backgroundRefreshActive = false;
  @track lastSaveDate; 
  @track selectedAccount;
  
  dataSize;


  connectedCallback(){

    //this.getMeterReadData();
    this.getAccountHierarchy();
    this.COLUMNS = cols;
    this.COLUMNS = [...cols].filter(col => col.fieldName != 'ReadCycle' && col.fieldName != 'Method');

    this.lockedColumns = cols2;
    this.lockedColumns = [...cols2].filter(col => col.fieldName != 'ReadCycle' && col.fieldName != 'Method');
  }

  getAccountHierarchy(){
    getAccountHierarchy()
    .then((result) => {
      //console.log(JSON.stringify(result));
      this.accounts = result.map(account => ({
        label: account.Name + " - " + account.Dealer_Number__c, // Display the Name field in the dropdown
        value: account.Dealer_Number__c     // The value should be the Account Id
    }));
      this.selectedAccount = result[0].Dealer_Number__c;
      this.getMeterReadData(this.selectedAccount);
    })
    .catch((error) => {
      //console.log(error);
    })
  }

  backgroundRefresh(){
    this.backgroundRefreshActive = true;
    if(this.lockedRows.length>0)
    {
      //Get the older date saved in the locked records
      const olderSavedRow = this.lockedRows.reduce((r, o) => o.date > r.date ? o : r);
      let now = Date.now();
      let firstDate = new Date(olderSavedRow.SentDate);
      let diffMs = (now - firstDate); // 
      //console.log('Time  ', diffMs);

      if(diffMs > 60000)      {
        //Retrieve data and compare
        this.resetFileInput();
        this.compareLockedData();

      }

    }
    else{
      this.backgroundRefreshActive = false;
      this.lockedRecordsExist = false;
      clearInterval(this.interval);
    }
  }

  compareLockedData(){
    let dealerNumber;
    let refreshedData = [];
    const unlockData = [];
    dealerNumber = this.selectedAccount;
    getMeterReadData({            
      dealerNumber: dealerNumber
  })
    .then((result) => {
      
      refreshedData = JSON.parse(result);
      //console.log('refreshedData ', JSON.stringify(refreshedData));
      //console.log('locked DATA ', JSON.stringify(this.lockedRows));
      this.lockedRows.forEach((lockedRecord) => {

        let now = Date.now();
        let saveDate = new Date(lockedRecord.SentDate);
        let diffMs = (now - saveDate);
        //console.log('diffMs ', diffMs);

        if(diffMs > 60000){

        unlockData.push(lockedRecord);
        let matchingRecord = refreshedData.find(item => (item.ContractNo === lockedRecord.ContractNo &&
            item.NextRead == lockedRecord.NextRead &&
            item.Serial == lockedRecord.Serial &&
            item.Asset == lockedRecord.Asset &&
            item.ShortDesc == lockedRecord.ShortDesc));
        
            if(matchingRecord){
              //console.log('matching record ');

            //For matching values, move them from locked table to main table
            this.assets.push(matchingRecord);
            this.assets.sort((a, b) => new Date(a.NextRead) - new Date(b.NextRead)||  a.Asset - b.Asset ||a.AumtAggrKey.split('*')[1] - b.AumtAggrKey.split('*')[1]);                                         
            for(let i=0; i<this.assets.length; i++ )
              {
                this.assets[i].recordKey = i;
              }
            this.draftValues=[];
            }

            //NEW VALUES?
            let newRecord = refreshedData.find(item => (item.ContractNo === lockedRecord.ContractNo &&
            item.NextRead != lockedRecord.NextRead &&
            item.Serial == lockedRecord.Serial &&
            item.Asset == lockedRecord.Asset &&
            item.ShortDesc == lockedRecord.ShortDesc));

            console.log('NEW RECORD ', newRecord);
            if(newRecord){
              //console.log('matching record ');

            //For matching values, move them from locked table to main table
            this.assets.push(newRecord);
            this.assets.sort((a, b) => new Date(a.NextRead) - new Date(b.NextRead)||  a.Asset - b.Asset ||a.AumtAggrKey.split('*')[1] - b.AumtAggrKey.split('*')[1]);                                         
            for(let i=0; i<this.assets.length; i++ )
              {
                this.assets[i].recordKey = i;
              }
            this.draftValues=[];
            }

            this.assets = [...this.assets];
        }        
      }  
    );
      
      //Remove the value from locked table
      unlockData.forEach((unlockRecord) => {
        this.lockedRows = this.lockedRows.filter(item => (item != unlockRecord)); 
    })
      this.lockedRows = [...this.lockedRows];
      this.lockedData = [...this.lockedRows];
      if(this.lockedRows.length<1)
      {
        this.lockedRecordsExist = false;
      }
      this.refreshMainTable();

    })
    .catch((error) => {
      //console.log(error);
    })

  }


   
  getMeterReadData(dealerNumber){
    console.log('Dealer number  ', dealerNumber);
    getMeterReadData({            
      dealerNumber: dealerNumber
  })
    .then((result) => {
      this.assets = JSON.parse(result);
      if(this.assets.length>0)
      {
        this.empty = false;
        this.assets.sort((a, b) => new Date(a.NextRead) - new Date(b.NextRead)||  a.Asset - b.Asset ||a.AumtAggrKey.split('*')[1] - b.AumtAggrKey.split('*')[1]);                                         
        this.dataSize   = this.assets.length;

        for(let i=0; i<this.assets.length; i++ )
          {
            this.assets[i].recordKey = i;
          }

          if(this.lockedRows.length>0){this.lockedRecordsExist=true;}
          else {this.lockedRecordsExist=false;}
        this.refreshMainTable();
      }
      else{
        this.empty = true;
      }
    })
    .catch((error) => {
      //console.log(error);
    })
  }

//Upload function
handleFileUpload(event){
  if(event.target.files.length > 0){
      const file = event.target.files[0];
      this.validateCSV(file);
      const reader = new FileReader();
      reader.onload = () => {
        let base64 = reader.result.split(',')[1]
        this.fileData = {
            'filename': file.name,
            'base64': base64
        }
       }
        reader.readAsDataURL(file);
        setTimeout(() => {
          if(this.validFile){
            this.transform();
          }
        }, 2000);

    }

}

  transform(){
    const {base64, filename} = this.fileData;
    //console.log('base64', base64);
    transform({base64})
    .then(result=>{
      this.fileData = null
      let title = `${filename} uploaded successfully!!`
      this.showNotification('SUCCESS', 'File uploaded successfully!','success');
      //console.log('title ', title);
      ////console.log('result ', result);
      this.assets = JSON.parse(result);
      for(let i=0; i<this.assets.length; i++ )
        {
          this.assets[i].recordKey = i;
          this.assets[i].NextRead = new Date(this.assets[i].NextRead).toLocaleDateString('fr-CA');
          this.assets[i].ReadDate = new Date(this.assets[i].ReadDate).toLocaleDateString('fr-CA');          
        }
      this.dataSize   = this.assets.length;

        this.refreshMainTable();
        this.handleSendMeterFileAll();

    })
  }

  handleSendMeterFileAll()
  {

    this.assets.forEach((record) => {
      record.SentDate = Date.now();
      record.Locked = true;
    });

    this.lockedRows = this.assets;
    this.handleSendMeterFile(this.lockedRows, true);
    if(this.lockedRows.length>0){
      this.empty = false;
      this.lockedRecordsExist=true;              
    }
    else {this.lockedRecordsExist=false;}
    this.lockedRows = [...this.lockedRows];
    this.lockedData = [...this.lockedRows];
    this.assets = [];


    this.refreshMainTable();
    if(!this.backgroundRefreshActive){
      this.interval = setInterval(() => {
        this.backgroundRefresh();
    }, 30000);
    }


  }

   
  handleSendMeterFile(records, all){    
    let dataToExport = [];
    dataToExport = records; 
    //console.log('handleSendMeterFile data ' , JSON.stringify(dataToExport));

    // convert JSON to CSV
    const replacer = (key, value) => value === null ? '' : value // specify how you want to handle null values here

    // headerFieldNames defines the order of the columns in the file
    const headerFieldNames=CSVfieldName;
    const header = this.getfieldLabel(headerFieldNames);


    let csv = dataToExport.map(row => headerFieldNames.map(fieldName => {
      if(fieldName == "NextRead" || fieldName == "ReadDate"){ //If is a date field, it must be formatted
        
        let timestamp; 
        if(row[fieldName].includes("/")){
          let convertedDate = new Date(row[fieldName]).toLocaleDateString('fr-CA');
          timestamp = new Date(convertedDate+'T00:00');         
        }
        else{
          timestamp = new Date(row[fieldName]+'T00:00');
        }

        let formattedDate = timestamp.toLocaleDateString('en-US');
        return formattedDate;
      }
      else{
        if((fieldName == "CurrentReadValue" || fieldName == "CopyCreditsCount" || fieldName =="PrevRead") &&(row[fieldName]) ){ //numeric fields are formatted to be whole numbers
          let num = parseInt(row[fieldName]);
          return num;
        }
        else{
          if(fieldName == "Method"){
            return "A";
          }
          else{
            if(row[fieldName] && row[fieldName].includes(","))
            {
              let value = '&quote'+row[fieldName]+'&quote';
              //console.log('value',value);
              return JSON.stringify(value, replacer);
            }
            return JSON.stringify(row[fieldName], replacer);
          }
          
        }
      }
    
    }).join(','))
    csv.unshift(header.join(','))
    csv = csv.join('\n')
    ////console.log('SEND CSV:   \n', csv);

    csv = csv.replace(/"/g, '');
    csv = csv.replace(/&quote/g, '\"');
    ////console.log('DOWNLOAD CSV AFTER:   \n', csv);
    sendMeterFile({
      csv: csv , 
      dealerNumber: this.selectedAccount
  }).then(() => {
      if(all){
        this.showNotification('SUCCESS', 'Meters have been successfully uploaded and saved.','success');
      }
      else{
        this.showNotification('SUCCESS', 'File sent successfully!','success');
      }
    })
    .catch(error => {
      this.showNotification('ERROR', error.body.message,'error');                
    });;
    



  }

 validateCSV(fileObj) {
  
    //Type validation
    const validationReader = new FileReader();
    validationReader.readAsText(fileObj)
    this.validFile = false;
    
    validationReader.onload = () => {

      //Validate file format
        let acceptedTypes = ['csv'];
        let acceptedTypesLong = ['text/csv'];
        let nameExtension = fileObj.name.split('.').pop();
          if (acceptedTypes.includes(nameExtension) && acceptedTypesLong.includes(fileObj.type)) {

            //Validate CSV columns
            let csvContent = validationReader.result;
            csvContent = JSON.stringify(csvContent.split('\n')[0].split(',')).replace(/(?:\\[rn"'])+/g, "");
            let expectedHeader = this.getfieldLabel(CSVfieldName);

            if (csvContent !== JSON.stringify(expectedHeader))
              {
                this.showNotification('ERROR', 'Invalid layout in the uploaded file. Please check the header columns and try again.','error');                
              }
            else{
              this.validFile = true;
            }
          }
          else{
              this.showNotification('ERROR', 'The file format must be ".csv"','error');
          }

    };

  }



  // Export file
  exportToCSV() {

    let dataToExport = [];
    dataToExport = this.assets; //this.template.querySelector('c-sl_-custom-data-table-type');
    this.downloadCSVFromJson('Meter Reads.csv', JSON.parse(JSON.stringify(dataToExport)));
  }



  downloadCSVFromJson = (filename, arrayOfJson) => {
    // convert JSON to CSV
    const replacer = (key, value) => value === null ? '' : value // specify how you want to handle null values here
    
    // headerFieldNames defines the order of the columns in the file
    const headerFieldNames=CSVfieldName;
    const header = this.getfieldLabel(headerFieldNames);

    let csv = arrayOfJson.map(row => headerFieldNames.map(fieldName => {
      if(fieldName == "NextRead" || fieldName == "ReadDate"){ //If is a date field, it must be formatted
        
        let timestamp = new Date(row[fieldName]+'T00:00');
        let formattedDate = timestamp.toLocaleDateString('en-US');
        return formattedDate;
      }
      else{
        if((fieldName == "CurrentReadValue" || fieldName == "CopyCreditsCount" || fieldName =="PrevRead") &&(row[fieldName]) ){ //numeric fields are formatted to be whole numbers
          let num = parseInt(row[fieldName]);
          return num;
        }
        else{
          if(fieldName == "Method"){
            return "A";
          }
          else{
            if(row[fieldName] && row[fieldName].includes(","))
            {
              let value = '&quote'+row[fieldName]+'&quote';
              //console.log('value',value);
              return JSON.stringify(value, replacer);
            }
            return JSON.stringify(row[fieldName], replacer);
          }
        }
      }
    }
    ).join(','))
    csv.unshift(header.join(','))
    csv = csv.join('\n')
    csv = csv.replace(/"/g, '');
    ////console.log('DOWNLOAD CSV:   \n', csv);

    csv = csv.replace(/&quote/g, '\"');
    ////console.log('DOWNLOAD CSV AFTER:   \n', csv);
  
    // Create link and download    
    var link = document.createElement('a');
    link.setAttribute('href', 'data:text/csv;charset=utf-8,%EF%BB%BF' + encodeURIComponent(csv));
    link.setAttribute('download', filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link); 
  };

  onCancelAction(event) {
    this.isSorting=true;
    //console.log('CANCEL');
    //console.log('CANCEL DRAFT VALUES', JSON.stringify(this.draftValues));
    this.draftValues.forEach((draftValue) => {
      if(draftValue.CurrentReadValue) delete this.assets[draftValue.recordKey].CurrentReadValue;
      if(draftValue.CopyCreditsCount) delete this.assets[draftValue.recordKey].CopyCreditsCount;
      if(draftValue.DealerInvoiceNumber) delete this.assets[draftValue.recordKey].DealerInvoiceNumber;
    });
    setTimeout(() => {
      this.draftValues=[];
      this.validateTable();
      this.template.querySelector('c-sl_datatable-paginator').setRecordsToDisplay();

    }, 100);
  }

handleDraftChange(event) {
      console.debug('handleDraftChange -> ' );

  this.draftValues = event.detail.draftValues;
}

handleSaveMeterReads() {
    // Build a fake event object similar to lightning-datatable onsave event
    const fakeEvent = {
        detail: {
            draftValues: this.draftValues
        }
    };

    // Call your onsave handler passing the draftValues
    this.onSaveAction(fakeEvent);


}


handleCancel() {
    // Build a fake event object similar to lightning-datatable onsave event
    const fakeEvent = {
        detail: {
            draftValues: this.draftValues
        }
    };

    // Call your onsave handler passing the draftValues
    this.onCancelAction(fakeEvent);


}

handleCellChange(event) {
    const newDraftValues = event.detail.draftValues;

    // Initialize draftValues if not already
    if (!this.draftValues) {
        this.draftValues = [];
    }

    // Use recordKey instead of Id
    const draftMap = new Map(this.draftValues.map(item => [item.recordKey, item]));


    newDraftValues.forEach(newItem => {
        if (draftMap.has(newItem.recordKey)) {
            // Merge existing with new values
            draftMap.set(newItem.recordKey, {
                ...draftMap.get(newItem.recordKey),
                ...newItem
            });


            if(this.dataErrors){
              if (Object.keys(this.dataErrors["rows"]).length > 0)
              {
                delete this.dataErrors["rows"][newItem.recordKey];    
              }
            }


        } else {
            draftMap.set(newItem.recordKey, newItem);
        }
    });

    this.draftValues = Array.from(draftMap.values());


    console.log('ERRORS AFTER ', JSON.stringify(this.dataErrors));


    console.log('DRAFT ', JSON.stringify(this.draftValues));
}




  onSaveAction(event) {
    
    console.debug('onSaveAction -> ' + event.detail.draftValues);
    let dataError = {};
    let title = 'Error';
    let rowError = {};
    let changesCount = 0;
    this.draftValues = event.detail.draftValues;
    const updatedRecords = event.detail.draftValues;
    const recordKeys = new Set();
    //console.log('DRAFT ',  JSON.stringify(this.draftValues));
    //console.log('DRAFT UPDATED ',  JSON.stringify(updatedRecords));
    if(event.detail.draftValues.length>0){
updatedRecords.forEach((updatedRecord) => {
      let hasChanged = false;
      let fieldsWithError = [];
      let messages = [];
      //Bug with first row
      if(updatedRecord.recordKey =='row-0')
        {
          updatedRecord.recordKey='0';
        }
      //The JSON array will be updated
      // Validate and update CurrentReadValue
      if(updatedRecord.CurrentReadValue)
        {


          if(updatedRecord.CurrentReadValue.replace(/\s/g, '').length === 0 || updatedRecord.CurrentReadValue.replace(/\s/g, '')==="")
          {
            delete this.assets[updatedRecord.recordKey].CurrentReadValue ;
          }
          else{

            if(Number(updatedRecord.CurrentReadValue) >= Number(this.assets[updatedRecord.recordKey].PrevRead.replace(/,/g, '')))
              {
                this.assets[updatedRecord.recordKey].CurrentReadValue = updatedRecord.CurrentReadValue;
                recordKeys.add(updatedRecord.recordKey);
                hasChanged=true;
                changesCount=changesCount+1;

                if(this.assets[updatedRecord.recordKey].CopyCreditsCount && !updatedRecord.CopyCreditsCount)
                  {
                    if(updatedRecord.CopyCreditsCount.replace(/\s/g, '').length == 0 || updatedRecord.CopyCreditsCount.replace(/\s/g, '')==='')
                    {
                      this.assets[updatedRecord.recordKey].CopyCreditsCount = null;
                    }
                    updatedRecord.CopyCreditsCount=this.assets[updatedRecord.recordKey].CopyCreditsCount;

                  }
              }
            else
              {
                this.assets[updatedRecord.recordKey].CurrentReadValue = updatedRecord.CurrentReadValue;
                fieldsWithError.push('CurrentReadValue');
                messages.push('Next read due meter must be equal to or greater than prior reading');
              }
          }
        }
        else{
            if(this.assets[updatedRecord.recordKey] && typeof updatedRecord.CurrentReadValue ==='string'){
              delete this.assets[updatedRecord.recordKey].CurrentReadValue ;

              if(this.assets[updatedRecord.recordKey].CopyCreditsCount && !updatedRecord.CopyCreditsCount && typeof updatedRecord.CopyCreditsCount !=='string')
                {
                  //console.log('543 CCC', updatedRecord.CopyCreditsCount);
                  updatedRecord.CopyCreditsCount=this.assets[updatedRecord.recordKey].CopyCreditsCount;
                }
            }
        }


        
      // Validate and update CopyCreditsCount
      if(updatedRecord.CopyCreditsCount)
        {
          //console.log('updatedRecord.CopyCreditsCount!!! ', updatedRecord.CopyCreditsCount);
          if(updatedRecord.CopyCreditsCount.replace(/\s/g, '').length == 0 || updatedRecord.CopyCreditsCount.replace(/\s/g, '')==='')
            {
              this.assets[updatedRecord.recordKey].CopyCreditsCount = null;
            }
            else{
              if(Number(updatedRecord.CopyCreditsCount) <= (Number(this.assets[updatedRecord.recordKey].CurrentReadValue) - Number(this.assets[updatedRecord.recordKey].PrevRead.replace(/,/g, ''))))
                {
                  this.assets[updatedRecord.recordKey].CopyCreditsCount = updatedRecord.CopyCreditsCount;
                  recordKeys.add(updatedRecord.recordKey);
                  hasChanged=true;
                  changesCount=changesCount+1;
                }
              else{
                this.assets[updatedRecord.recordKey].CopyCreditsCount = updatedRecord.CopyCreditsCount;
                fieldsWithError.push('CopyCreditsCount');
                messages.push('Copy credits cannot be greater than usage');
              }
            }
        }
        else{
          if(this.assets[updatedRecord.recordKey] && typeof updatedRecord.CopyCreditsCount ==='string'){
            delete this.assets[updatedRecord.recordKey].CopyCreditsCount ;
          }
      }


      // Validate and update DealerInvoiceNumber
      if(updatedRecord.DealerInvoiceNumber)
        {
          if(updatedRecord.DealerInvoiceNumber.replace(/\s/g, '').length === 0 || updatedRecord.DealerInvoiceNumber.replace(/\s/g, '')==="" )
            {
              delete this.assets[updatedRecord.recordKey].DealerInvoiceNumber;
            }
            else{
              if(!updatedRecord.CurrentReadValue){
                this.assets[updatedRecord.recordKey].CopyCreditsCount = updatedRecord.CopyCreditsCount;
                fieldsWithError.push('DealerInvoiceNumber');
                messages.push('Dealer invoice number requires entry of a current read');
              }
              else{
                this.assets[updatedRecord.recordKey].DealerInvoiceNumber = updatedRecord.DealerInvoiceNumber;
                recordKeys.add(updatedRecord.recordKey);
                hasChanged=true;
                changesCount=changesCount+1;
              }

            }
        }
      else{
          if(this.assets[updatedRecord.recordKey]  && typeof updatedRecord.DealerInvoiceNumber ==='string'){
            delete this.assets[updatedRecord.recordKey].DealerInvoiceNumber ;
          }
      }

      if(messages.length>0)
        {
          /*if(updatedRecord.recordKey =='0')
            {
              updatedRecord.recordKey='row-0';
            }*/
          rowError[updatedRecord.recordKey] =this.triggerError(title,messages,fieldsWithError);
        }


      });
      window.sessionStorage.setItem('lockedDataSession', JSON.stringify(this.lockedData));

      if (Object.keys(rowError).length > 0)
        {
          dataError['rows'] = rowError;
          if (Object.keys(dataError).length > 0)
            {
              this.dataErrors = dataError;
              this.showNotification('ERROR', 'There are errors in the Meter Reads data input. Please check the table and correct the marked records.','error');

            }
        }
      else {
          //Lock data
          let records = [];
          for (const key of recordKeys.keys()) {
            this.assets[key].Locked = true;
            this.assets[key].SentDate =  Date.now();
            this.lockedData.push(this.assets[key]); //Put the value into locked data
            records.push(this.assets[key]);
          }
          for (const key of recordKeys.keys()) {
            this.assets = this.assets.filter(item => item.recordKey != key); //Remove the value from assets
          }
          if(changesCount>0)this.showNotification('Details Saved Successfully! ', 'Note - The table filters were cleared and the meter reads have been saved','success');
          this.draftValues = [];
          this.dataErrors = {};
          this.handleSendMeterFile(records, false);
          window.sessionStorage.setItem('lastSaveDate', Date.now());
          this.lockedRows= this.lockedData;
          if(this.lockedRows.length>0){
            this.lockedRecordsExist=true;              
          }
          else {this.lockedRecordsExist=false;}
          this.lockedRows = [...this.lockedRows];


          this.refreshMainTable();
          if(!this.backgroundRefreshActive){
            this.interval = setInterval(() => {
              this.backgroundRefresh();
          }, 30000);
          }

      }
    }
    
  }




  validateTable(){

    let dataError = {};
    let title = 'Error';
    let rowError = {};
    const updatedRecords = this.assets;
    updatedRecords.forEach((updatedRecord) => {
      let fieldsWithError = [];
      let messages = [];

      //Bug with first row
      if(updatedRecord.recordKey =='row-0')
        {
          updatedRecord.recordKey='0';
        }

      // Validate and update CurrentReadValue
      if(updatedRecord.CurrentReadValue)
        {

          if(Number(updatedRecord.CurrentReadValue) >= Number(this.assets[updatedRecord.recordKey].PrevRead.replace(/,/g, '')))
            {
              this.assets[updatedRecord.recordKey].CurrentReadValue = updatedRecord.CurrentReadValue;
              if(this.assets[updatedRecord.recordKey].CopyCreditsCount && !updatedRecord.CopyCreditsCount)
                {
                  updatedRecord.CopyCreditsCount=this.assets[updatedRecord.recordKey].CopyCreditsCount; 
                }
            }
          else
            {
              fieldsWithError.push('CurrentReadValue');
              messages.push('Next read due meter must be equal to or greater than prior reading');
            }
        }

      // Validate and update CopyCreditsCount
      if(updatedRecord.CopyCreditsCount)
        {
          if(Number(updatedRecord.CopyCreditsCount) <= (Number(this.assets[updatedRecord.recordKey].CurrentReadValue) - Number(this.assets[updatedRecord.recordKey].PrevRead.replace(/,/g, ''))))
            {
              this.assets[updatedRecord.recordKey].CopyCreditsCount = updatedRecord.CopyCreditsCount;
            }
          else{
            fieldsWithError.push('CopyCreditsCount');
            messages.push('Copy credits cannot be greater than usage');
          }

        }

      // Validate and update DealerInvoiceNumber
      if(updatedRecord.DealerInvoiceNumber)
        {
          this.assets[updatedRecord.recordKey].DealerInvoiceNumber = updatedRecord.DealerInvoiceNumber;
        }

      if(messages.length>0)
        {
          if(updatedRecord.recordKey =='0')
            {
              updatedRecord.recordKey='row-0';
            }
          rowError[updatedRecord.recordKey] =this.triggerError(title,messages,fieldsWithError);
        }

      });

      if (Object.keys(rowError).length > 0)
        {
          dataError['rows'] = rowError;
          if (Object.keys(dataError).length > 0)
            {
              this.dataErrors = dataError;
              if(!this.isSorting)this.showNotification('ERROR', 'There are errors in the Meter Reads data input. Please check the table and correct the marked records.','error');

            }
        }
      else {
          if(!this.isSorting)this.showNotification('Details Saved Successfully! ', 'Note - The table filters were cleared and the meter reads have been saved','success');
          this.draftValues = [];
          this.dataErrors = {};
      }

          this.isSorting=false;


  }

  doSorting(event) {
    this.isSorting = true;
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortData(this.sortBy, this.sortDirection);
    ////console.log('ERRORS - before ', JSON.stringify(this.dataErrors));
    for(let i=0; i<this.assets.length; i++ )
      {
        this.assets[i].recordKey = i;      
      }
    setTimeout(() => {
      this.draftValues=[];
      this.validateTable();
      this.template.querySelector('c-sl_datatable-paginator').setRecordsToDisplay();

    }, 100);
}

  sortData(fieldname, direction) {
      let parseData = this.assets;
      // Return the value stored in the field
      let keyValue = (a) => {
          return a[fieldname];
      };
      // cheking reverse direction
      let isReverse = direction === 'asc' ? 1: -1;
      // sorting data
      parseData.sort((x, y) => {
          x = keyValue(x) ? keyValue(x) : ''; // handling null values
          y = keyValue(y) ? keyValue(y) : '';
          // sorting values based on direction
          return isReverse * ((x > y) - (y > x));
      });
      this.assets = parseData;
  }   

  get paginatorLimit() {
    return [10000];
  }



  getfieldLabel = (fieldNames) => {
    let labels = [];

    fieldNames.forEach((fieldName) => {
    let field = cols.filter(function(item){
        return item.fieldName == fieldName;
    });
    if(field.length>0){
      let fieldObject = JSON.parse(JSON.stringify(field[0]));
      labels.push(fieldObject.label);

    }
    else{
      labels.push(fieldName);
    }
    });
    return labels;
  }


  showNotification = (titleText,messageText, variant) => {
    const evt = new ShowToastEvent({
      title: titleText,
      message: messageText,
      variant: variant,
      mode: 'dismissible',
    });
    this.dispatchEvent(evt);
  }


  triggerError(title,messages,fieldNames) {
    let rowError = {};
    rowError['title'] = title;
    rowError['messages'] = messages;
    rowError['fieldNames'] = fieldNames;
    return rowError;
}


  uploadFileButton(event) {
    this.template.querySelector('[data-id="uploadFileInput"]').click();
  }

  showModalBox() {  
    this.isShowModal = true;
}

  hideModalBox() {  
      this.isShowModal = false;
  }

  refreshMainTable(){

    setTimeout(() => {
      for(let i=0; i<this.assets.length; i++ )
        {
          this.assets[i].recordKey = i;      
        }
      this.template.querySelector('c-sl_datatable-paginator').setRecordsToDisplay();
    }, 100);
  }

    // Capture the event fired from the paginator component
    handlePaginatorChange(event) {
      this.recordsToDisplay =event.detail;
    }

    handleAccountChange(event) {
      if(this.lockedData.length>0){
        this.template.querySelector('[data-id="accountValue"]').value = this.selectedAccount;
        this.showNotification('ERROR', 'There are records in progress. Please wait until the process is done to select another dealer.','error');
      }
      else{
        this.selectedAccount = event.detail.value;
        //console.log('Selected option: ', this.selectedAccount);
        this.clearTable();
        this.getMeterReadData(this.selectedAccount);
      }


  }

  clearTable() {  
    this.assets = [];
    this.refreshMainTable();
  } 

  resetFileInput() {
        const fileInput = this.template.querySelector('[data-id="uploadFileInput"]');
    if (fileInput) {
        fileInput.value = null; // Clear the input
    }
}

}