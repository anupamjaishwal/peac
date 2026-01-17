/**
 * Created by andrewmayer on 2/5/20.
 */

 public with sharing class TC_GdsScoreApiCalloutMock implements HttpCalloutMock{

    public HttpResponse respond (HttpRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);

        if (req.getEndpoint().containsIgnoreCase('Dataview360')) {
            res.setBody([SELECT Body FROM StaticResource WHERE Name = 'gdstest'][0].Body.toString ());
        } else if (req.getEndpoint().containsIgnoreCase('geocode')) {
            res.setBody([SELECT Body FROM StaticResource WHERE Name = 'googleGeoCodeMockResp'][0].Body.toString ());
        }else{
            if(req.getBody() != null && (req.getBody().contains('BW.UPDATE.DEALER.UDO')
            || req.getBody().contains('BW.UPDATE.CUSTOMER.UDO'))){
                res.setBody('{"response":{"Header":{"NitroApi":"BW.UPDATE.DEALER.UDO"},"Response":{"TbVdmZip":"03210","TbVdmState":"CO","TbVdmName":"1 test Customer","TbVdmCity":"03210239 test city","TbVdmAddr1":"03210239 test str","DlrMMRPaymentType":"01","DlrDealerId":"111000001","DlrCreditPhone":"1234567891","DlrCreditName":"test0 testbeni0","DlrCreditEmail":"test@email11111.com","DlrActiveDealer":"0001","DealerNumber":"111000001","ApaMailZip":"03210","ApaMailState":"CO","ApaMailCity":"03210239 test city","ApaMailAddr1":"03210239 test str"}}}');
            }
        }

        return res;

    }

}