using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class Digital5App extends App.AppBase {
    hidden const HALF_DAY      = new Time.Duration(43200);
    hidden const SIXTY_MINUTES = new Time.Duration(3600);
    hidden var   view;


    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {}
    
    function onStop(state) {}

    function getInitialView() {
        Background.deleteTemporalEvent();
        App.getApp().setProperty("status", "NA");
        enableWebRequest((App.getApp().getProperty("SunriseSunset") || App.getApp().getProperty("DarkSkyApiKey").length() > 0), false);        
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
        //System.println("getServiceDelegate()");
        return [new Digital5ServiceDelegate()]; 
    }

    function onBackgroundData(data) {
        System.println("onBackgroundData(" + data + ")");
        checkForLocationAndAdjustUpdateTime();
        if (data instanceof Lang.String) {
            //System.println("Status: " + data);
            App.getApp().setProperty("status", data);
        } else if (data instanceof Dictionary) {
            var showSunriseSunset = App.getApp().getProperty("SunriseSunset");
            var apiKey            = App.getApp().getProperty("DarkSkyApiKey");
            if (apiKey.length() > 0) {
                //System.println("Store weather dictionary to properties: " + data);
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
            } else {
                //System.println("Store sunrise/sunset dictionary to properties: " + data);
                var requestStatus = data.get("status");
                if (requestStatus.equals("OK")) {
                    var result        = data.get("results");
                    var sunriseString = result.get("sunrise");
                    var sunsetString  = result.get("sunset");                
                    var sunriseTime   = getTime(sunriseString, sunriseString.find("PM") != null);
                    var sunsetTime    = getTime(sunsetString, sunsetString.find("PM") != null);               
                    var sunrise       = Gregorian.info(Gregorian.moment({:hour => sunriseTime[0], :minute => sunriseTime[1]}), Time.FORMAT_SHORT); 
                    var sunset        = Gregorian.info(Gregorian.moment({:hour => sunsetTime[0], :minute => sunsetTime[1]}), Time.FORMAT_SHORT);
                    App.getApp().setProperty("status", "OK");
                    App.getApp().setProperty("sunriseHH", sunrise.hour);
                    App.getApp().setProperty("sunriseMM", sunrise.min);
                    App.getApp().setProperty("sunsetHH", sunset.hour);
                    App.getApp().setProperty("sunsetMM", sunset.min);
                    if (null != view) { WatchUi.requestUpdate(); }
                }
            }
        }
    }

    function onSettingsChanged() {
        //System.println("onSettingsChanged()");
        enableWebRequest((App.getApp().getProperty("SunriseSunset") || App.getApp().getProperty("DarkSkyApiKey").length() > 0), true);
        WatchUi.requestUpdate();
    }
    
    function enableWebRequest(enabled, updateNow) {
        //System.println("enableWebRequest(" + enabled + ", " + updateNow + ")");
        Background.deleteTemporalEvent();
        if (enabled) {
            var lastTime     = Background.getLastTemporalEventTime();
            var deltaSeconds = null == lastTime ? 305 : (Time.now().value() - lastTime.value());
            
            //System.println("lastTime    : " + (null == lastTime ? "null" : lastTime.value()));
            //System.println("deltaSeconds: " + deltaSeconds);
            
            if (deltaSeconds > 300) {
                //System.println("deltaSeconds > 300 (" + deltaSeconds + ")");
                if (null == lastTime || updateNow) {
                    //System.println("First time web request or updateNow == true");
                    Background.registerForTemporalEvent(Time.now());
                } else {
                    var nextTime;
                    if (App.getApp().getProperty("SunriseSunset") && App.getApp().getProperty("DarkSkyApiKey").length() == 0) {
                        nextTime = lastTime.add(HALF_DAY);
                        //System.println("Web request update interval HALF_DAY");
                    } else {
                        nextTime = lastTime.add(SIXTY_MINUTES);
                        //System.println("Web request update interval SIXTY_MINUTES");
                    }
                    Background.registerForTemporalEvent(nextTime);
                }
            } else {
                //System.println("deltaSeconds < 300 (" + deltaSeconds + ")");
            }
        }
    }
    
    function checkForLocationAndAdjustUpdateTime() {
        var location = Activity.getActivityInfo().currentLocation;
        if (null != location) {
            App.getApp().setProperty("UserLat", location.toDegrees()[0]);
            App.getApp().setProperty("UserLng", location.toDegrees()[1]);
        }
        var status = App.getApp().getProperty("status");
        if (!status.equals("FAIL")) {
            Background.deleteTemporalEvent();
            Background.registerForTemporalEvent(SIXTY_MINUTES);
        }
    }
    
    function getTime(timeString, isPM) {
        var chars      = timeString.toCharArray();
        var colonCount = 0;
        var hh         = "";
        var mm         = "";
        var ss         = "";
        var length     = timeString.length();
        for (var i = 0 ; i < length ; i++) {
            var c = chars[i];
            if (c.toString().equals(":")) {
                colonCount++;
                continue;
            } else if (c.toString().equals(" ")) {
                break;
            }
            if (colonCount == 0) { hh = hh + chars[i].toString(); }
            else if (colonCount == 1) { mm = mm + chars[i].toString(); }
            else if (colonCount == 2) { ss = ss + chars[i].toString(); }
        }
        return [isPM ? hh.toNumber() + 12 : hh.toNumber(), mm.toNumber()];
    }
}