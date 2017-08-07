using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;

(:background)
class Digital5ServiceDelegate extends System.ServiceDelegate {
    
    function initialize() {
        ServiceDelegate.initialize();
    }
    
    function onTemporalEvent() {
        var location = Activity.getActivityInfo().currentLocation;
        if (null == location) {
            System.println("null == location");
            var lat = App.getApp().getProperty("UserLat");
            var lng = App.getApp().getProperty("UserLng");
            if (null != lat && null != lng) {
                requestSunriseSunset(lat, lng);
            } else {
                Background.exit("NA");
            }
        } else {
            requestSunriseSunset(location.toDegrees()[0], location.toDegrees()[1]);
        }
    }

    function requestSunriseSunset(lat, lng) {
        var url     = "https://api.sunrise-sunset.org/json?lat=" + lat.toString() + "&lng=" + lng.toString();
        var params  = {};
        var options = {
            :methods => Comm.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (System.getDeviceSettings().phoneConnected) {
            Comm.makeWebRequest(url, params, options, method(:onReceive));
        }
    }

    function onReceive(responseCode, data) {
        if (responseCode == 200) {
            Background.exit(data);
        } else {
            Background.exit("FAIL");
        }    
    }
}