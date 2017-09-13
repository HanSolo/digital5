using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class Digital5App extends App.AppBase {
    hidden var view;


    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {}
    
    function onStop(state) {}

    function getInitialView() {
        App.getApp().setProperty("status", "NA");
        
        Background.deleteTemporalEvent();
        Background.registerForTemporalEvent(new Time.Duration(15 * 60));
                
        if (null == App.getApp().getProperty("ActKcalAvg")) {
            var actKcalAvg = [0, 0, 0, 0, 0, 0];
            App.getApp().setProperty("ActKcalAvg", actKcalAvg);
        }
        view = new Digital5View();
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [view, new Digital5Delegate()];
        } else {
            return [view];
        }
    }
    
    function getServiceDelegate() {
        //updateLocation();
        return [new Digital5ServiceDelegate()]; 
    }

    function onBackgroundData(data) {
        if (data instanceof Lang.String) {
            App.getApp().setProperty("status", data);
        } else if (data instanceof Dictionary) {
            var apiKey            = App.getApp().getProperty("DarkSkyApiKey");
            if (apiKey.length() == 32) {
                var sunrise = Gregorian.info(new Time.Moment(data.get("sunrise")), Time.FORMAT_SHORT);
                var sunset  = Gregorian.info(new Time.Moment(data.get("sunset")), Time.FORMAT_SHORT);
                var icon    = data.get("icon");
                App.getApp().setProperty("status", "OK");
                App.getApp().setProperty("sunriseHH", sunrise.hour);
                App.getApp().setProperty("sunriseMM", sunrise.min);
                App.getApp().setProperty("sunsetHH", sunset.hour);
                App.getApp().setProperty("sunsetMM", sunset.min);
                App.getApp().setProperty("tempMin", data.get("minTemp"));
                App.getApp().setProperty("tempMax", data.get("maxTemp"));
                if (icon.equals("clear-day") || icon.equals("clear-night")) {
                    App.getApp().setProperty("icon", 0);
                } else if (icon.equals("rain") || icon.equals("snow") || icon.equals("sleet") || icon.equals("hail") || icon.equals("thunderstorm")) {
                    App.getApp().setProperty("icon", 1);
                } else if (icon.equals("cloudy")) {
                    App.getApp().setProperty("icon", 2);
                } else if (icon.equals("partly-cloudy-day") || icon.equals("partly-cloudy-night")) {
                    App.getApp().setProperty("icon", 3);
                } else {
                    App.getApp().setProperty("icon", 4);
                }
            }
        }
    }

    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
    
    function updateLocation() {
        var location = Activity.getActivityInfo().currentLocation;
        if (null != location) {
            App.getApp().setProperty("UserLat", location.toDegrees()[0]);
            App.getApp().setProperty("UserLng", location.toDegrees()[1]);
        }
    }
}