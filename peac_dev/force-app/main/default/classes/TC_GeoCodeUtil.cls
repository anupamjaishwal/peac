/**
 * Created by andrewmayer on 12/27/19. Class exists for Geo Code functions not specific to Google
 */

public with sharing class TC_GeoCodeUtil {

    // formula copied from this JIRA task: https://marlinbusiness.atlassian.net/browse/SAL-920
    public static Decimal calculateDistance (Decimal lat1, Decimal long1, Decimal lat2, Decimal long2) {
        Decimal distance;
        Decimal dTor = 0.017453278;
        distance =  Math.round(3949.99 * Math.acos(Math.sin(lat1 * dTor) * Math.sin(lat2 * dTor) + Math.cos(lat1 * dTor) * Math.cos(lat2 * dTor) * Math.cos(long2 * dTor - long1 * dTor)));
        return distance;
    }

}