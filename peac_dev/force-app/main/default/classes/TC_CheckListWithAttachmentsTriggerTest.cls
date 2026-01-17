@isTest
public class TC_CheckListWithAttachmentsTriggerTest {
    static testMethod void MyTestMethod() {

        TC_Origination__Checklist_Template__c temp = new TC_Origination__Checklist_Template__c();
        temp.Name = 'Test';
        insert temp;
        
        TC_Origination__Checklist__c objCL = new TC_Origination__Checklist__c();
        objCL.Name = 'Customer Verification Procedures Required';
        objCL.TC_Origination__Checklist_Template__c = temp.Id;
        insert objCL;
        update objCL;
        
        TC_Origination__Checklist_Item_with_Attachments__c objCIWT = new TC_Origination__Checklist_Item_with_Attachments__c();
        objCIWT.Name = 'Customer Verification Procedures Required';
        objCIWT.TC_Origination__Checklist__c = objCL.Id;
        objCIWT.TC_Origination__Primary_Reviewer__c = true;
        insert objCIWT;
        objCIWT.TC_Origination__Primary_Reviewer__c = False;
        Update objCIWT;
    }

}