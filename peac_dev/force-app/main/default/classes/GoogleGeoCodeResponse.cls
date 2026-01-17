/**
 * Created by tamarack on 12/26/19.
 */

public with sharing class GoogleGeoCodeResponse {

    public List<Result> results;
    public String status;
    public String error_message;

    public GoogleGeoCodeResponse () {
        results = new List <Result> ();
    }

    public class Result {
        public String formatted_address;
        public Geometry geometry;

        public Result () {
            geometry = new Geometry ();
        }
    }

    public class Geometry {
        public Location location;

        public Geometry () {
            location = new Location ();
        }
    }

    public class Location {
        public String lat;
        public String lng;
    }

    /*
POSSIBLE STATUS MESSAGES: OK, ZERO_RESULTS, REQUEST_DENIED

    SUCCESS RESPONSE:
{
   "results": [
      {
         "address_components": [
            {
               "long_name": "1600",
               "short_name": "1600",
               "types": [
                  "street_number"
               ]
            },
            {
               "long_name": "Amphitheatre Parkway",
               "short_name": "Amphitheatre Pkwy",
               "types": [
                  "route"
               ]
            },
            {
               "long_name": "Mountain View",
               "short_name": "Mountain View",
               "types": [
                  "locality",
                  "political"
               ]
            },
            {
               "long_name": "Santa Clara County",
               "short_name": "Santa Clara County",
               "types": [
                  "administrative_area_level_2",
                  "political"
               ]
            },
            {
               "long_name": "California",
               "short_name": "CA",
               "types": [
                  "administrative_area_level_1",
                  "political"
               ]
            },
            {
               "long_name": "United States",
               "short_name": "US",
               "types": [
                  "country",
                  "political"
               ]
            },
            {
               "long_name": "94043",
               "short_name": "94043",
               "types": [
                  "postal_code"
               ]
            }
         ],
         "formatted_address": "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",
         "geometry": {
            "location": {
               "lat": 37.420146,
               "lng": -122.0845541
            },
            "location_type": "ROOFTOP",
            "viewport": {
               "northeast": {
                  "lat": 37.4214949802915,
                  "lng": -122.0832051197085
               },
               "southwest": {
                  "lat": 37.4187970197085,
                  "lng": -122.0859030802915
               }
            }
         },
         "place_id": "ChIJtYuu0V25j4ARwu5e4wwRYgE",
         "plus_code": {
            "compound_code": "CWC8+35 Mountain View, California, United States",
            "global_code": "849VCWC8+35"
         },
         "types": [
            "street_address"
         ]
      }
   ],
   "status": "OK"
}

    FAILED RESPONSE:
{
   "error_message": "The provided API key is invalid.",
   "results": [],
   "status": "REQUEST_DENIED"
}
}
     */
}