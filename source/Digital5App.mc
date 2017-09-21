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
        if (null == App.getApp().getProperty("ActKcalAvg")) {
            var actKcalAvg = [0, 0, 0, 0, 0, 0];
            App.getApp().setProperty("ActKcalAvg", actKcalAvg);
        }
        
        sunRiseSet = new SunRiseSunSet();

        view = new Digital5View();
        
        Background.registerForTemporalEvent(new Time.Duration(900)); // 15 min
        
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [view, new Digital5Delegate()];
        } else {
            return [view];
        }
    }
    
    function getServiceDelegate() {
        return [new Digital5ServiceDelegate()]; 
    }

    function onBackgroundData(data) {
        if (data instanceof Dictionary) {
            var msg = data.get("msg");
            if (msg.equals("FAIL") || msg.equals("WRONG KEY")) {
            } else if (msg.equals("CURRENTLY")) {
                App.getApp().setProperty("temp", data.get("temp"));
            } else if (msg.equals("DAILY")) {
                App.getApp().setProperty("tempMin", data.get("tempMin"));
                App.getApp().setProperty("tempMax", data.get("tempMax"));
            }
            // rain, snow, sleet, wind, fog, cloudy
            var icon = data.get("icon");
            if (icon == null) {
                App.getApp().setProperty("icon", 7);
            } else if (icon.equals("clear-day") || icon.equals("clear-night")) {
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

    function onSettingsChanged() {
        App.getApp().setProperty("sunrise", (sunRiseSet.computeSunrise(true) / 3600000));
        App.getApp().setProperty("sunset", (sunRiseSet.computeSunrise(false) / 3600000));
        WatchUi.requestUpdate();
    }
}