import { LightningElement, api, wire } from 'lwc';
import generatedDocument from '@salesforce/apex/showAllDocuments.generatedDocuments';
import hubExecute from "@salesforce/apex/SL_DealerPortalCAAttachment.hubExecute";
import uId from "@salesforce/user/Id";
import superUser from "@salesforce/apex/SL_DealerPortalCAAttachment.checkSuperUser";
import DPExcludeDocumentsToView from "@salesforce/label/c.DPExcludeDocumentsToView";

const COLUMNS = [
    { label: "File Name", fieldName: "recordUrl", type: "url", typeAttributes: {label: {fieldName: "Name"}}},
    { label: "Document Type", fieldName: "Dealer_Doc_Type__c"  }
  ];

  const FILECOLUMNS = [
    { label: "File Name", fieldName: "Title", type: 'text', wrapText: true},
    { label: "Date", fieldName: "CreatedDate"  },
    { label: "Download Link", fieldName: "url", type: "url", typeAttributes: {label: {fieldName: "Name"}}},
  ];

export default class PEAC_ShowAllDocuments extends LightningElement {
    @api recordId;
    isModalOpen = false;
    uploadedDocuments = [];
    viewAllDocu = [];
    viewAll = false;
    viewAllUploads = false;
    modalAllUpload = false;
    viewAllUploadsDocs = [];
    showUploadPopup = false;
    columns = COLUMNS;
    fcolumns = FILECOLUMNS;
    rows = [];
    defaultRow = [];
    userId = uId;
    superUserCheck = false;

    showGeneratedDocu(){
        this.isModalOpen = true;
    }
    showAllUploadDocu(){
        this.modalAllUpload = true;
    }
    closeModal(){
        this.isModalOpen = false;
        this.showUploadPopup = false;
        this.modalAllUpload = false;
        this.connectedCallback();
    }

    uploadedDocuments =[]
    @wire(generatedDocument, {parentId: '$recordId'})
    wiredResult({data, error}){ 
        if(data){ 
            console.log('data:',data);
            var datalist =[];//= JSON.parse(JSON.stringify(data));
            let i = 0;
            data.forEach((item) => {
                
                i++;
                //accounts.push(rec);
                let rec = {
                    Title: item.Title,
                    CreatedDate: item.CreatedDate,
                    url: item.url,
                    Name: 'Download'
                };
                if(i <= 5){
                    datalist.push(rec);
                } else{
                    this.viewAll = true;
                }
                this.viewAllDocu.push(rec);
            });
            this.uploadedDocuments = datalist;
            console.log(datalist,'uploadedDocuments:',this.uploadedDocuments);
        }
        if(error){ 
            console.log('error',error)
        }
    }

    handleGoToAdd(){
        this.showUploadPopup = true;
    }

    connectedCallback(){
        this.viewAllUploads = false;
        this.rows = [];
        superUser({

        }).then(result => {
            this.superUserCheck = result;
            this.fetchDocuments();
        }).catch(error => {

        });
        
    }

    fetchDocuments() {
        hubExecute({methodName: "getOppAttachments", methodParameters: [this.recordId]})
        .then((result)=>{
        let obj = JSON.parse(result);
        console.log('obj.length:',obj.length);
        console.log('obj.length:',obj.length);
        if(obj && obj.length){
            var i =0;
            let processed = [];
            let processed5 = [];
            obj.forEach(oppAttachment=>{
                if(oppAttachment.Type__c == 'LC - Lease' || (this.superUserCheck && oppAttachment["DPSuperUserDocuments__c"]) || 
                     (oppAttachment.CreatedById == this.userId && oppAttachment.Type__c != DPExcludeDocumentsToView)
                ){
                    i++;
                    let newRow = JSON.parse(JSON.stringify(oppAttachment));
                    newRow.recordUrl = "/detail/" + newRow.Id;
                    processed.push(newRow);
                    if(i<=5){
                        processed5.push(newRow);
                    } else {
                        this.viewAllUploads = true;
                    }
                }
              }); 
              console.log('this.processed5:',processed5);
              this.viewAllUploadsDocs = processed;
              this.defaultRow = processed5;

            /*this.viewAllUploadsDocs = this.processRows(obj);
            this.viewAllUploadsDocs.forEach(rec=>{
                i++;
                console.log('rec:',rec);
                if(i<=5){
                    let newRow = JSON.parse(JSON.stringify(rec));
                    this.rows.push(newRow);
             } else {
                    this.viewAllUploads = true;
                }
                
            });*/
        } 
        console.log('this.rows:',this.defaultRow);
        })
        .catch((error)=>{
            
        })
        .finally(()=>{
            
        });
    }

    processRows(rawData){
        let processed = [];
        rawData.forEach(oppAttachment=>{
          let newRow = JSON.parse(JSON.stringify(oppAttachment));
          newRow.recordUrl = "/dealers/s/detail/" + newRow.Id;
          processed.push(newRow);
        });
        return processed;
      }

      showAllUploadDocu(){
        this.modalAllUpload = true;
      }
}