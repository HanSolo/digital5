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
        var lat = App.getApp().getProperty("UserLat").toFloat();
        var lng = App.getApp().getProperty("UserLng").toFloat();
        if (null != lat && null != lng) {
            makeRequest(lat, lng);
        } else {
            Background.exit("NA");
        }
    }

    function makeRequest(lat, lng) {
        var apiKey         = App.getApp().getProperty("DarkSkyApiKey");
        var currentWeather = App.getApp().getProperty("CurrentWeather");
        var url, params;
        if (null != apiKey || apiKey.length() == 32) {
            var url    = "https://api.darksky.net/forecast/" + apiKey + "/" + lat.toString() + "," + lng.toString() + "," + Time.now().value();
            var params = currentWeather ? { "exclude" => "daily,minutely,hourly,alerts,flags", "units" => "si" } : { "exclude" => "currently,minutely,hourly,alerts,flags", "units" => "si" };
            //var params = { "exclude" => "currently,minutely,hourly,alerts,flags", "units" => "si" }; // daily
            //var params = { "exclude" => "daily,minutely,hourly,alerts,flags", "units" => "si" }; // currently
            var options = {
                :methods => Comm.HTTP_REQUEST_METHOD_GET,
                :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            if (System.getDeviceSettings().phoneConnected) {
                //System.println("makeRequest()");
                Comm.makeWebRequest(url, params, options, method(:onReceive));
            } else {
                //System.println("Background.exit(\"NOT CONNECTED\")");
                Background.exit("NOT CONNECTED");
            }
        }
    }

    function onReceive(responseCode, data) {
        //System.println("onReceive(" + responseCode + ", " + data + ")");
        if (responseCode == 200) {
            if (data instanceof Lang.String && data.equals("Forbidden")) { onBackgroundData("WRONG KEY"); }
            var apiKey         = App.getApp().getProperty("DarkSkyApiKey");
            var currentWeather = App.getApp().getProperty("CurrentWeather");
            var dict;
            if (apiKey.length() == 32) {
                //System.println("Write data to dictionary");
                if (currentWeather) {
                    var currently = data.get("currently");
                    dict = {
                        "icon"        => currently.get("icon"),
                        "temperature" => currently.get("temperature")
                    };
                } else {
                    var daily = data.get("daily");
                    var days  = daily.get("data");
                    var today = days[0];
                    dict = {
                        "icon"    => today.get("icon"),
                        "minTemp" => today.get("temperatureMin"),
                        "maxTemp" => today.get("temperatureMax")
                    };
                }
                //System.println("Background.exit(WeatherData)");
                Background.exit(dict);
            }
        } else {
           //System.println("Background.exit(\"FAIL\")");
            Background.exit("FAIL");
        }    
    }
}