/** @author : Northteq Consulting, Inc.
 * @date : 10/30/20
 * @description: Wrapper class for the response object
 *
 */
public with sharing class TC_RateCardResponseBean {

    public List<Response> rows;

    public TC_RateCardResponseBean() {
        rows = new List<Response>();
    }

    public class Response {
        public Decimal yield;
        public Decimal term;
    }
}