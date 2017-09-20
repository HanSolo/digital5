using Toybox.Background;
using Toybox.System;
using Toybox.Application as App;
using Toybox.Communications as Comm;

(:background)
class Digital5ServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        ServiceDelegate.initialize();        
    }
    
    function onTemporalEvent() {
        var apiKey = App.getApp().getProperty("DarkSkyApiKey");
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        if (System.getDeviceSettings().phoneConnected &&
            apiKey.length() > 0 && 
            (null != lat && null != lng)) {            
            makeRequest(lat, lng);
        }
    }

    function makeRequest(lat, lng) {
        var apiKey         = App.getApp().getProperty("DarkSkyApiKey");
        var currentWeather = App.getApp().getProperty("CurrentWeather");
        var url            = "https://api.darksky.net/forecast/" + apiKey + "/" + lat.toString() + "," + lng.toString();
        var params;
        if (currentWeather) {
            params = { "exclude" => "daily,minutely,hourly,alerts,flags", "units" => "si" };
        } else {
            url    = url + "," + Time.now().value();
            params = { "exclude" => "currently,minutely,hourly,alerts,flags", "units" => "si" };
        }
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comm.makeWebRequest(url, params, options, method(:onReceive));
    }

    function onReceive(responseCode, data) {
        if (responseCode == 200) {
            System.println(data);
            if (data instanceof Lang.String && data.equals("Forbidden")) { 
                Background.exit(new DTO(null, null, null, null, "WRONG KEY"));
            } else {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                if (currentWeather) {
                    var currently = data.get("currently");
                    Background.exit(new DTO(currently.get("icon"), currently.get("temperature"), null, null, "CURRENTLY"));
                } else {
                    var daily = data.get("daily");
                    var days  = daily.get("data");
                    var today = days[0];
                    Background.exit(new DTO(daily.get("icon"), null, today.get("temperatureMin"), today.get("temperatureMax"), "DAILY"));
                }
            }
        } else {
            Background.exit(new DTO(null, null, null, null, "FAIL"));
        }
    }
}