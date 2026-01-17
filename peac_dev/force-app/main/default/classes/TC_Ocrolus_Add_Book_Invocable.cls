global class TC_Ocrolus_Add_Book_Invocable {
    // async call to generate ocrolus guid, needs guid to upload docs
    
    global class AddBookParam { 
        
        @InvocableVariable
        global String oppId;
        
        /*global AddBookParam (Id oppId) {
            this.oppId = oppId;
        }*/
        global AddBookParam () {
            this.oppId = oppId;
        }
        
    }
	@InvocableMethod(
            Label='Add Ocrolus Book'
            Description='Creates a Ocrolus Book, so you can upload files to it'
    )    
    global static void execute(List<AddBookParam> params) {
        
        System.debug ('##### TC_Ocrolus_Add_Book_Invocable params:' + params);
        
        // there should never be more than 1
        
        if (!params.isEmpty () && params.size () == 1) {
            TC_OcrolusCtrl.processOcrolusAttachmentList (params[0].oppId);
        }
        
    }
    

}