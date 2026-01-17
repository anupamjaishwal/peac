/** @author : Tamarack Consulting, Inc.
 * @date : 12/21/20
 * @description: 
 *
 */
public with sharing class TC_DwhStoredProcedureJSONUtil {

    public static TC_DwhStoredProcedureRespBean deserializeResponse (String resp) {

        TC_DwhStoredProcedureRespBean respBean = (TC_DwhStoredProcedureRespBean)JSON.deserialize(resp, TC_DwhStoredProcedureRespBean.class);
        return respBean;
    }
}