@IsTest
private class TC_ListViewUtilTests {
    @IsTest static void testBehavior() {
        Test.startTest();
        TC_ListViewUtil lvu = new TC_ListViewUtil();
                        lvu = new TC_ListViewUtil('Account');
        System.assert(!lvu.listViews.isEmpty());
        System.assert(String.isNotBlank(lvu.getListViewConditions(lvu.listViews[0])));
        System.assert(!lvu.getListViewMap(new Set<String>{lvu.listViews[0].DeveloperName}).isEmpty());
        System.assert(lvu.listViewsAsSelectOptions.size()>1, 'More than one select options should be available!');
        Test.stopTest();
    }
}