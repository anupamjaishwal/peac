import { LightningElement, api, wire } from 'lwc';
import getChecklists from '@salesforce/apex/showCheckListCls.getChecklists';
import uploadFile from '@salesforce/apex/showCheckListCls.uploadFile';
import { loadStyle } from 'lightning/platformResourceLoader';
import customstyle from '@salesforce/resourceUrl/customStyle';


const COLUMNS = [
    { label: "Name", fieldName: "recordUrl", type: "url", typeAttributes: {label: {fieldName: "Name"}}},
    { label: "Status", fieldName: "TC_Origination__Status__c"  }
  ];
  const fileCOLUMNS = [
    { label: "FileName", fieldName: "name"},
    { label: "Document Type", fieldName: "Type__c"  }
  ];

export default class ShowChecklistItem extends LightningElement { 
 
    @api recordId;
    recordsToDisplay = [];
    requireFile = false;
    columns = COLUMNS;
    isModalOpen = false;
    uploadedDocuments = [];
    fCol = fileCOLUMNS;
    fileName;
    docType ='LC - Misc';
    fileContent;
    fileSelected;
    filetoShow = {};

    uploadDoc(){
        this.isModalOpen = true;
    }
    closeModal(){
        this.isModalOpen = false;
    }

    connectedCallback(){
        Promise.all([
            loadStyle(this, customstyle )
        ]).then(() => {
            console.log('Upload success')
        }).catch( (error) => {
            console.error(error);
        })
        console.log(this.recordId, ' ***** ');
        this.recordsToDisplay = [];
        let rows = [];
        getChecklists({recId: this.recordId})
        .then(result => {
            console.log('result:',result);
            result.forEach(rec => {

                rec.showFile = false;
                rec.count = 0;
                this.filetoShow[rec.Id] = [];
            });
            this.recordsToDisplay = result;
            
            console.log(' test  ',JSON.stringify(rows));
        })
    }
    
    
    handleFile(event){
        let uploadedFile = event.detail.files;
        var docUploadedId = [];
        let checkitemid = event.currentTarget.dataset.id;
        console.log('uploadedFile:',JSON.stringify(uploadedFile));
        if(uploadedFile){
            this.fileName = '';
            uploadedFile.forEach(uf => {
                this.fileName = uf.name;
                let fileReader = new FileReader();  
                docUploadedId.push({'Name':uf.name, 'documentId': uf.documentId});
                uf.Type__c = this.docType;
                this.filetoShow[checkitemid].push(uf);
                console.log('this.filetoShow :',this.filetoShow );
                
            });
                var clonerecordsToDisplay = [];
                
                uploadFile({type: this.docType, contentDocuments: JSON.stringify(docUploadedId), recordId: this.recordId})
                .then((result)=>{
                    console.log(JSON.stringify(result))
                    
                    
                    
                    this.recordsToDisplay.forEach(rec => {
                        if(checkitemid == rec.Id){
                            console.log('rec.count:',rec.count);
                            //var recCopy = [...rec];
                            rec.count = rec.count+docUploadedId.length;
                            rec.showFile = true;
                            console.log('rec.count:',rec.count);
                            
                            
                        }
                        clonerecordsToDisplay.push(rec);
                    });
                    this.recordsToDisplay = [...clonerecordsToDisplay];
                }).catch((error) => {
                    console.log('error',error);
                });
        }
    }
    showuploadedDocu(event){
        let checkitemid = event.currentTarget.dataset.id;
        this.isModalOpen = true;
        console.log('checkitemid:',checkitemid);
        this.uploadedDocuments = this.filetoShow[checkitemid];
    }
    
}