using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class Digital5App extends App.AppBase {
    hidden var view;
    hidden var sunRiseSet;


    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {}
    
    function onStop(state) {}

    function getInitialView() {
        App.getApp().setProperty("status", "NA");
                        
        if (null == App.getApp().getProperty("ActKcalAvg")) {
            var actKcalAvg = [0, 0, 0, 0, 0, 0];
            App.getApp().setProperty("ActKcalAvg", actKcalAvg);
        }
        
        sunRiseSet = new SunRiseSunSet();
        
        view = new Digital5View();
        
        Background.registerForTemporalEvent(new Time.Duration(10 * 60));
        
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [view, new Digital5Delegate()];
        } else {
            return [view];
        }
    }
    
    function getServiceDelegate() {
        updateLocation();
        return [new Digital5ServiceDelegate()]; 
    }

    function onBackgroundData(data) {
        if (data instanceof Lang.String) {
            App.getApp().setProperty("status", data);
        } else if (data instanceof Dictionary) {
            var apiKey = App.getApp().getProperty("DarkSkyApiKey");
            if (apiKey != null) {
                var currentWeather = App.getApp().getProperty("CurrentWeather");
                App.getApp().setProperty("status", "OK");
                if (currentWeather) {
                    App.getApp().setProperty("temperature", data.get("temperature"));
                } else {
                    App.getApp().setProperty("tempMin", data.get("minTemp"));
                    App.getApp().setProperty("tempMax", data.get("maxTemp"));
                }
                // rain, snow, sleet, wind, fog, cloudy
                var icon = data.get("icon");
                if (icon.equals("clear-day") || icon.equals("clear-night")) {
                    App.getApp().setProperty("icon", 0);
                } else if (icon.equals("rain") || icon.equals("hail")) {
                    App.getApp().setProperty("icon", 1);
                } else if (icon.equals("cloudy")) {
                    App.getApp().setProperty("icon", 2);
                } else if (icon.equals("partly-cloudy-day") || icon.equals("partly-cloudy-night")) {
                    App.getApp().setProperty("icon", 3);
                } else if (icon.equals("thunderstorm")) {
                    App.getApp().setProperty("icon", 4);
                } else if (icon.equals("sleet")) {
                    App.getApp().setProperty("icon", 5);
                } else if (icon.equals("snow")) {
                    App.getApp().setProperty("icon", 6);
                } else {
                    App.getApp().setProperty("icon", 7);
                }
            }
        }
    }

    function onSettingsChanged() {
        App.getApp().setProperty("sunrise", (sunRiseSet.computeSunrise(true) / 3600000));
        App.getApp().setProperty("sunset", (sunRiseSet.computeSunrise(false) / 3600000));
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