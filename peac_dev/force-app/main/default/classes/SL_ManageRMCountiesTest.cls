@isTest
public with sharing class SL_ManageRMCountiesTest {
    @isTest
    public static void hubTest() {
        SL_SCTestData.createAccountAndContracts(3, 1);
        SL_SCTestData.createInsurancesAndContractAssets(3, 2);
        SL_SCTestData.updateCAssetsWithLocation(2, 4);
        List<County__c> testCounties = SL_SCTestData.createCounties();
        Test.startTest();
        List<SL_ManageRMCounties.CountyWrapper> countyObjects = new List<SL_ManageRMCounties.CountyWrapper>();
        SL_ManageRMCounties.CountyWrapper obj1 = new SL_ManageRMCounties.CountyWrapper();
        obj1.label = testCounties[0].Name;
        obj1.name = testCounties[0].Id;
        countyObjects.add(obj1);
        SL_ManageRMCounties.CountyWrapper obj2 = new SL_ManageRMCounties.CountyWrapper();
        obj2.label = testCounties[1].Name;
        obj2.name = testCounties[1].Id;
        countyObjects.add(obj2);
        List<String> parameters = new List<String>{'ATM', '2 Way Radios', 'CA', 'ALS', JSON.serialize(countyObjects)};
        SL_ManageRMCounties.hubExecute('saveRMatrixes', parameters);
        parameters = new List<String>{'ATM', '2 Way Radios', 'CA', 'ALS'};
        SL_ManageRMCounties.hubExecute('getCounties', parameters);
        parameters = new List<String>{'ATM', '2 Way Radios', 'CA', 'ALS', JSON.serialize(countyObjects)};
        SL_ManageRMCounties.hubExecute('saveRMatrixes', parameters);
        SL_ManageRMCounties.hubExecute('getWarehouseCodes', new List<String>());
        Test.stopTest();
        List<Remarketer_Matrix_Obj__c> rMatrixesAfter = [SELECT Id, Equipment_Type__c, Equipment_Subtype__c, State__c, Return_Warehouse_Code__c, County__c 
            FROM Remarketer_Matrix_Obj__c];
        System.Assert.areEqual(2, rMatrixesAfter.size(), 'must insert matrixes for the 2 counties');
    }
}