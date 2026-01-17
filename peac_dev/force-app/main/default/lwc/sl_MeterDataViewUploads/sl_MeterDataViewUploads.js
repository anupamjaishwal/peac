import { LightningElement , track, api} from 'lwc';
import getLogFiles from '@salesforce/apex/SL_MeterDataController.getLogFiles';
import generateFileLink from '@salesforce/apex/SL_MeterDataController.generateFileLink';



const columns = [
    { label: 'File', fieldName: 'name', initialWidth: 500 },
    //{ label: 'Size', fieldName: 'size' },
       {
        type: "button", label: 'Download', initialWidth: 200, typeAttributes: {
            label: '',
            name: 'Download',
            title: 'Download',
            disabled: false,
            value: 'Download',
            iconPosition: 'left',
            iconName:'utility:download'
        }
    }
];



export default class Sl_MeterDataViewUploads extends LightningElement {
    @track logs = [];
    @track files = [];
    @track data = [];
    @track empty = false;
    @api dealerNumber;
    @api requestType;
    columns = columns;

    connectedCallback() {
        this.logs=[];
        this.files=[];
        this.data=[];

        this.getFilesData();
    }

    getFilesData(){
        //console.log('DEALER NUMBER: ', this.dealerNumber);
        //Get the log files and sort them
        getLogFiles({            
            dealerNumber: this.dealerNumber,
            requestType: this.requestType
        })
        .then((result) => {
            //console.log('result.length', result.length);
            if(result.length>0){
            this.data = JSON.parse(result);            
            this.empty = false;
            }
            else{
                this.empty = true;
            }
            })

        .catch((error) => {
          console.log(error);
        })
        


    }

    callRowAction(event) {
        const recId = event.detail.row['name'];
        const actionName = event.detail.action.name;
        if (actionName === 'Download') {
           
            generateFileLink({
                fileName: recId , 
                dealerNumber: this.dealerNumber,
                requestType: this.requestType
            })
            .then((result) => {
                console.log('result ', result);
                window.open(result, '_blank');

            })
            .catch((error) => {
                console.log(error);
            })

        }

    }

    @api refreshData(newDealerNumber) {
        this.dealerNumber = newDealerNumber;
        this.getFilesData();
    }
}