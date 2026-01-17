import { LightningElement, api } from 'lwc';
import hubExecute from '@salesforce/apex/SL_UploadAttachment.hubExecute';

const CHUNK_SIZE = 4000000;

export default class SlBigFileUpload extends LightningElement {
    @api inputLabel;
    @api messageWhenValueMissing;
    @api optionalFile;
    @api customButtonText = "";
    @api isWithoutHelper = false;
    requiredFile;

    fileContent;
    fileName;
    fileSelected = false;
    isSavingAttachment = false;

    connectedCallback(){
        this.requiredFile = !this.optionalFile;
    }

    renderedCallback(){
        let buttonInput = this.template.querySelector('lightning-input');
        if(this.customButtonText && buttonInput){
            let customButtonTextStyle = document.createElement('style');
            customButtonTextStyle.innerText = '.slds-file-selector__dropzone .slds-file-selector__button{font-size: 0 !important;} '
                + '.slds-file-selector__dropzone .slds-file-selector__button:after{content: "' + this.customButtonText
                + '" !important;font-size: .8125rem !important;}';
            buttonInput.appendChild(customButtonTextStyle);
        }
    }

    handleFile(event){
        let uploadedFile = event.target.files[0];
        if(uploadedFile){
            if(uploadedFile.size >36000000 ){
                this.dispatchEvent(new CustomEvent("finishedupload", {detail: {
                    errorMessage: 'File size cannot be greater than 36MB. Please try again with a file of less than 36MB.',
                }}));
            }
            else{
                this.fileName = uploadedFile.name;
                let fileReader = new FileReader();  
                fileReader.onloadend = (() => {  
                    this.fileContent = fileReader.result;  
                    let base64 = 'base64,';  
                    let content = this.fileContent.indexOf(base64) + base64.length;  
                    this.fileContent = this.fileContent.substring(content);
                    this.fileSelected = true;
                    this.errorOccurred = false;
                    this.dispatchEvent(new CustomEvent("finishedupload", {detail: {
                        fileName: this.fileName,
                        fileContent: this.fileContent,
                    }}));
                });  
                fileReader.readAsDataURL(uploadedFile);  
            }

        }
    }

    @api
    sendToUploadHelper(parentId){
        if(this.isWithoutHelper){
            this.saveAttachmentNoHelper(parentId);
        }else{
            let parameters = {
                parentId : parentId,
                fileName : this.fileName,
                fileContent : this.fileContent
            }
            const messageHandler = (message) => {
              console.log("Listening from window");
              console.log("message:", message);
              console.log("message.data:", message.data);
              this.isSavingAttachment = false;
              this.dispatchEvent(new CustomEvent("savedinsalesforce", {detail: {
                  attachmentResult: message.data
              }}));
              
              // Remove the event listener after it's used
              window.removeEventListener("message", messageHandler);
            };
      
            window.addEventListener("message", messageHandler);
            this.isSavingAttachment = true;
            this.template.querySelector('iframe').contentWindow.postMessage(parameters, '*');
        }
    }

    @api
    resetFile(){
        this.fileContent = "";
        this.fileName = "";
        this.fileSelected = false;
        this.isSavingAttachment = false;
    }

    saveAttachmentNoHelper(parentId){
        this.isSavingAttachment = true;
        let chunk = this.fileContent.substring(0, CHUNK_SIZE);
        let parameters = [
            parentId,
            this.fileName,
            chunk
        ];
        // console.log("chunk length: ", chunk.length);
        // console.log("parameters: ", parameters);
        hubExecute({methodName: "justSaveAttachment", methodParameters: parameters})
        .then((result)=>{
          console.log("result: ", result);
          if(this.fileContent.length < CHUNK_SIZE){
            this.dispatchEvent(new CustomEvent("savedinsalesforce", {detail: {
                attachmentResult: result
            }}));
            this.isSavingAttachment = false;
          }else{
             //this.attachmentId = result;
             this.callCompleteFile(result, 2);
          }
        })
        .catch((error)=>{
            this.errorOnAttachment(error);
        })
        .finally(()=>{});
    }

    callCompleteFile(attachmentId, step){
        let upperLimit = CHUNK_SIZE * step;
        let chunk = this.fileContent.substring(CHUNK_SIZE * (step - 1), upperLimit);
        let isLastPart = this.fileContent.length < upperLimit;
        hubExecute({methodName: "appendChunk", methodParameters: [attachmentId, chunk, step, isLastPart]})
        .then((result)=>{
          console.log("result: ", result);
          if(isLastPart){
            setTimeout(()=>{
                this.dispatchEvent(new CustomEvent("savedinsalesforce", {detail: {
                    attachmentResult: result
                }}));
                this.isSavingAttachment = false;
            }, 4000);
          }else{
             //this.attachmentId = result;
             this.callCompleteFile(attachmentId, step + 1);
          }
        })
        .catch((error)=>{
            this.errorOnAttachment(error);
        })
        .finally(()=>{});
    }

    errorOnAttachment(error){
        this.dispatchEvent(new CustomEvent("savedinsalesforce", {detail: {
            attachmentResult: "Failed: with message: " + JSON.stringify(error)
        }}));
        this.isSavingAttachment = false;
    }
}