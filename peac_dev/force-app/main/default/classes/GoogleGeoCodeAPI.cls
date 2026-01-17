/**
 * Created by tamarack on 12/26/19.
 */

public with sharing class GoogleGeoCodeAPI {

    public static GoogleGeoCodeResponse getGeoCodeResponse(String street, String city, String state, String zip) {


        if (String.isBlank (street)) street = '';
        if (String.isBlank (city)) city = '';
        if (String.isBlank (state)) state = '';
        if (String.isBlank (zip)) zip = '';

        List<String> addressParameterList = street.split(' ');
        addressParameterList.addAll((city + ',').split(' '));
        addressParameterList.addAll(new List<String>{state + ',', zip});

        String addressParameter = String.join(addressParameterList, '+');

        GoogleGeoCodeResponse response = GoogleGeoCodeService.googleGeoCodeCallout(addressParameter);
        return response;

    }

}