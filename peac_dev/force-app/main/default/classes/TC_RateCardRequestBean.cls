/** @author : Northteq Consulting, Inc.
 * @date : 10/30/20
 * @description: Wrapper class for the request object
 *
 */
public with sharing class TC_RateCardRequestBean {

    public String branch;
    public String riskGrade;
    public Decimal equipmentCost;
    public Decimal timeInBusiness;
    public Boolean riskBasedPricing;

    public TC_RateCardRequestBean() {}
}