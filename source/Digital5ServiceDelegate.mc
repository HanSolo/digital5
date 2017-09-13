using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;

(:background)
class Digital5ServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        //System.println("initialize()");
        ServiceDelegate.initialize();        
    }
    
    function onTemporalEvent() {
        //System.println("onTemporalEvent()");
        var location = Activity.getActivityInfo().currentLocation;
        var lat;
        var lng;
        if (null == location) {
            lat = App.getApp().getProperty("UserLat").toFloat();
            lng = App.getApp().getProperty("UserLng").toFloat();
        } else {
            lat = location.toDegrees()[0];
            lng = location.toDegrees()[1];
        }
        if (null != lat && null != lng) {
            makeRequest(lat, lng);
        } else {
            Background.exit("NA");
        }
    }

    function makeRequest(lat, lng) {
        var apiKey = App.getApp().getProperty("DarkSkyApiKey");
        var url, params;
        if (null == apiKey || apiKey.length() != 32) {
            url    = "https://api.sunrise-sunset.org/json";
            params = { "lat" => lat.toString(), "lng" => lng.toString() };
        } else {
            url    = "https://api.darksky.net/forecast/" + apiKey + "/" + lat.toString() + "," + lng.toString() + "," + Time.now().value();
            params = { "exclude" => "currently,minutely,hourly,alerts,flags", "units" => "si" };
        }
        if (System.getDeviceSettings().phoneConnected) {
            //System.println("makeRequest()");
            var options = {
                :methods => Comm.HTTP_REQUEST_METHOD_GET,
                :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            Comm.makeWebRequest(url, params, options, method(:onReceive));
        } else {
            //System.println("Background.exit(\"NOT CONNECTED\")");
            Background.exit("NOT CONNECTED");
        }
    }

    function onReceive(responseCode, data) {
        //System.println("onReceive(" + responseCode + ", " + data + ")");
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) { onBackgroundData("WRONG KEY"); }
            var apiKey = App.getApp().getProperty("DarkSkyApiKey");
            if (apiKey.length() == 32) {
                //System.println("Write data to dictionary");
                var daily = data.get("daily");
                var days  = daily.get("data");
                var today = days[0];
                var dict = {
                    "icon"    => today.get("icon"),
                    "sunrise" => today.get("sunriseTime"),
                    "sunset"  => today.get("sunsetTime"),
                    "minTemp" => today.get("temperatureMin"),
                    "maxTemp" => today.get("temperatureMax")
                };
                //System.println("Background.exit(WeatherData)");
                Background.exit(dict);
            } else {
                //System.println("Background.exit(SunriseSunsetData)");
                Background.exit(data);
            }
        } else {
           //System.println("Background.exit(\"FAIL\")");
            Background.exit("FAIL");
        }    
    }
}