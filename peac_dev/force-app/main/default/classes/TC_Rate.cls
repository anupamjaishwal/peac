/**
 * Created by andrewmayer on 8/26/20.
 *
 *
 */

public with sharing class TC_Rate {

    //static function to interpolate terms for https://marlinbusiness.atlassian.net/browse/SAL-1744
    public static Decimal interpolate (Decimal lowTermRate, Decimal highTermRate, Decimal extraMonths) {
        if (lowTermRate == null || highTermRate == null || extraMonths == null) return null;
        if (extraMonths == 0) return lowTermRate;
        return Math.abs ((highTermRate - lowTermRate)/12 * extraMonths + lowTermRate);
    }

}