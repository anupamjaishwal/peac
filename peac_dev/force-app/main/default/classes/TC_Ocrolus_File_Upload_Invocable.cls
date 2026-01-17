global class TC_Ocrolus_File_Upload_Invocable {
	global class FileUploadParam { 
        @InvocableVariable
        global String pk;
        @InvocableVariable
        global String attId;
        @InvocableVariable
        global String oppAttId;
        @InvocableVariable
        global String calloutType;
        global FileUploadParam () {}

    }
    @InvocableMethod(
            Label='Upload Ocrolus File'
            Description='Uploads File to Ocrolus. Need to create book and have PK number first'
    ) 
    global static void execute(List<FileUploadParam> params) {
        
        for (FileUploadParam param : params) {
            System.enqueueJob(new TC_OcrolusService.OcrolusQueueable(param.pk, param.attId, param.oppAttId, param.calloutType));
        }
        
    }
    
    
}