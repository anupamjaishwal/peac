/******************************************************************************************************************************
@Author : Vinod Rathod(LTIMindtree)
@Description : Retrieves and formats Bank Statements and Bank Information for an Opportunity to produce a grouped matrix structure
used by the LWC PEAC_BankStatementMatrix.
@User Story : SAL-5551
@Created Date: November-20-2025 	    
*******************************************************************************************************************************/
public class PEAC_BankStatementMatrixCtrl {
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getBankData(Id opportunityId) {
        
        List<Map<String, Object>> resultSections = new List<Map<String, Object>>();
        
        if(opportunityId == null) return resultSections;
        
        // 1) Query all Bank Statements (ordered by Month)
        List<Bank_Statement__c> stmts = [
            SELECT Id, Name, Indicator__c,
            Opening_Balance__c, Ending_Balance__c, Amount_of_Deposits__c,
            Daily_Average_Balance__c, Negative_Days__c, NSFs__c,
            Number_of_Deposits__c, Month__c, Exclude__c
            FROM Bank_Statement__c
            WHERE Bank_Information__r.Financial__r.Opportunity__c = :opportunityId
            ORDER BY Month__c ASC
        ];
        
        // 2) Query Bank Information parent records 
        
        List<Financial_Bank_Information__c> bankInfos = [
            SELECT Id, Indicator__c,
            Opening_Balance_Average__c,
            Amount_of_Deposits_Average__c,
            Ending_Balance_Average__c,
            Daily_Average_Balance_Average__c,
            Negative_Days_Average__c,
            NSFs_Average__c,
            Number_of_Deposits_Average__c
            FROM Financial_Bank_Information__c
            WHERE Financial__r.Opportunity__c = :opportunityId
        ];
        
        // Map bank information by Indicator for quick lookup
        Map<String, Financial_Bank_Information__c> bankInfoByIndicator = new Map<String, Financial_Bank_Information__c>();
        for (Financial_Bank_Information__c bi : bankInfos) {
            if (bi.Indicator__c != null) bankInfoByIndicator.put(bi.Indicator__c, bi);
        }
        
        // 3) Group Bank Statements by Indicator (preserve desired indicators order)
        Map<String, List<Bank_Statement__c>> grouped = new Map<String, List<Bank_Statement__c>>();
        List<String> indicatorOrder = new List<String>{'Primary','Backup','Other','-'};
            for (String ind : indicatorOrder) grouped.put(ind, new List<Bank_Statement__c>());
        
        for (Bank_Statement__c s : stmts) {
            if (s.Indicator__c != null && grouped.containsKey(s.Indicator__c)) {
                grouped.get(s.Indicator__c).add(s);
            }
        }
        
        // Row label order (the vertical table rows)
        List<String> rows = new List<String>{
            'Month',
                'Opening Balance',
                'Amount of Deposits',
                'Ending Balance',
                'Number of Deposits',
                'Daily Average Balance',
                'Negative Days',
                'NSFs',
                'Exclude'
                };
                    
                    // Helper: map the row label to the Bank Statement field API name and to the Bank Information average field
                    Map<String, String> rowToStmtField = new Map<String, String>{
                        'Opening Balance' => 'Opening_Balance__c',
                            'Amount of Deposits' => 'Amount_of_Deposits__c',
                            'Ending Balance' => 'Ending_Balance__c',
                            'Daily Average Balance' => 'Daily_Average_Balance__c',
                            'Negative Days' => 'Negative_Days__c',
                            'NSFs' => 'NSFs__c',
                            'Number of Deposits' => 'Number_of_Deposits__c'
                            };
                                
                                Map<String, String> rowToAvgField = new Map<String, String>{
                                    'Opening Balance' => 'Opening_Balance_Average__c',
                                        'Amount of Deposits' => 'Amount_of_Deposits_Average__c',
                                        'Ending Balance' => 'Ending_Balance_Average__c',
                                        'Daily Average Balance' => 'Daily_Average_Balance_Average__c',
                                        'Negative Days' => 'Negative_Days_Average__c',
                                        'NSFs' => 'NSFs_Average__c',
                                        'Number of Deposits' => 'Number_of_Deposits_Average__c'
                                        };
                                            
                                            // 4) Build sections in desired order
                                            for (String indicator : indicatorOrder) {
                                                
                                                List<Bank_Statement__c> listByInd = grouped.get(indicator);
                                                if (listByInd == null || listByInd.isEmpty()) {
                                                    
                                                    continue;
                                                }
                                                
                                                // Column headers (statement names)
                                                List<Map<String,String>> columnHeaders = new List<Map<String,String>>();
                                                for (Bank_Statement__c b : listByInd) {
                                                    columnHeaders.add(new Map<String,String>{
                                                        'id' => b.Id,
                                                            'name'=> b.Name
                                                            });
                                                }
                                                
                                                // Build table rows
                                                List<Map<String, Object>> tableRows = new List<Map<String, Object>>();
                                                
                                                for (String r : rows) {
                                                    Map<String, Object> rowData = new Map<String, Object>();
                                                    rowData.put('label', r);
                                                    
                                                    List<String> values = new List<String>();
                                                    
                                                    // For Month and Exclude we just display values as strings for each statement
                                                    if (r == 'Month') {
                                                        for (Bank_Statement__c b : listByInd) {
                                                            values.add(b.Month__c == null ? '' : String.valueOf(b.Month__c));
                                                        }
                                                        rowData.put('values', values);
                                                        rowData.put('avgValue', 'NA'); // No average for Month
                                                        tableRows.add(rowData);
                                                        continue;
                                                    }
                                                    
                                                    if (r == 'Exclude') {
                                                        for (Bank_Statement__c b : listByInd) {
                                                            values.add(b.Exclude__c == null ? '' : String.valueOf(b.Exclude__c));
                                                        }
                                                        rowData.put('values', values);
                                                        rowData.put('avgValue', 'NA'); // Not numeric average - leave blank
                                                        tableRows.add(rowData);
                                                        continue;
                                                    }
                                                    
                                                    // For numeric fields: 
                                                    for (Bank_Statement__c b : listByInd) {
                                                        // Map statement's field to that statement's value
                                                        Decimal val = null;
                                                        String stmtField = rowToStmtField.containsKey(r) ? rowToStmtField.get(r) : null;
                                                        if (stmtField != null) {
                                                            if (stmtField == 'Opening_Balance__c') val = b.Opening_Balance__c;
                                                            else if (stmtField == 'Amount_of_Deposits__c') val = b.Amount_of_Deposits__c;
                                                            else if (stmtField == 'Ending_Balance__c') val = b.Ending_Balance__c;
                                                            else if (stmtField == 'Daily_Average_Balance__c') val = b.Daily_Average_Balance__c;
                                                            else if (stmtField == 'Negative_Days__c') val = b.Negative_Days__c;
                                                            else if (stmtField == 'NSFs__c') val = b.NSFs__c;
                                                            else if (stmtField == 'Number_of_Deposits__c') val = b.Number_of_Deposits__c;
                                                        }
                                                        
                                                        if (val != null) values.add(val.format());
                                                        else values.add('');
                                                    }
                                                    
                                                    // For average, look up the Financial_Bank_Information__c record for this indicator and return its Average field
                                                    String avgString = '';
                                                    if (bankInfoByIndicator.containsKey(indicator)) {
                                                        Financial_Bank_Information__c parentBI = bankInfoByIndicator.get(indicator);
                                                        String avgField = rowToAvgField.containsKey(r) ? rowToAvgField.get(r) : null;
                                                        if (avgField != null) {
                                                            Decimal avgValue;
                                                            // read the appropriate field
                                                            if (avgField == 'Opening_Balance_Average__c') avgValue = parentBI.Opening_Balance_Average__c;
                                                            else if (avgField == 'Amount_of_Deposits_Average__c') avgValue = parentBI.Amount_of_Deposits_Average__c;
                                                            else if (avgField == 'Ending_Balance_Average__c') avgValue = parentBI.Ending_Balance_Average__c;
                                                            else if (avgField == 'Daily_Average_Balance_Average__c') avgValue = parentBI.Daily_Average_Balance_Average__c;
                                                            else if (avgField == 'Negative_Days_Average__c') avgValue = parentBI.Negative_Days_Average__c;
                                                            else if (avgField == 'NSFs_Average__c') avgValue = parentBI.NSFs_Average__c;
                                                            else if (avgField == 'Number_of_Deposits_Average__c') avgValue = parentBI.Number_of_Deposits_Average__c;
                                                            else avgValue = null;
                                                            
                                                            if (avgValue != null) {
                                                                // format to 2 decimal places (optional)
                                                                avgValue = avgValue.setScale(2, RoundingMode.HALF_UP);
                                                                avgString = avgValue.format();
                                                            }
                                                        }
                                                    } // end if bankInfo present
                                                    
                                                    rowData.put('values', values);
                                                    rowData.put('avgValue', avgString);
                                                    tableRows.add(rowData);
                                                } // end rows loop
                                                
                                                Map<String, Object> section = new Map<String, Object>();
                                                if(indicator == '-'){
                                                    section.put('header', 'None Bank Statement');
                                                    section.put('columns', columnHeaders);
                                                    section.put('rows', tableRows);
                                                } else 
                                                    section.put('header', indicator + ' Bank Statement');
                                                section.put('columns', columnHeaders);
                                                section.put('rows', tableRows);
                                                
                                                resultSections.add(section);
                                            } // end indicators loop
        
        return resultSections;
    }
    
}