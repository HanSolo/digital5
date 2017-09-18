using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.ActivityMonitor as Act;
using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.Activity as Activity;


class SunRiseSunSet {
    
    function initialize() {
        App.getApp().setProperty("sunrise", (computeSunrise(true) / 3600000));
        App.getApp().setProperty("sunset", (computeSunrise(false) / 3600000));
    }
    
    function dayOfTheYear() {
        var day   = Calendar.info(Time.now(), Time.FORMAT_SHORT).day;
        var month = Calendar.info(Time.now(), Time.FORMAT_SHORT).month;
        var year  = Calendar.info(Time.now(), Time.FORMAT_SHORT).year;

        var N1 = Math.floor(275 * month / 9);
        var N2 = Math.floor((month + 9) / 12);
        var N3 = (1 + Math.floor((year - 4 * Math.floor(year / 4) + 2) / 3));
        return N1 - (N2 * N3) + day - 30;
    }

    function computeSunrise(sunrise) {
        /* Sunrise/Sunset Algorithm taken from
            http://williams.best.vwh.net/sunrise_sunset_algorithm.htm
            inputs:
                day     = day of the year
                sunrise = true for sunrise, false for sunset
            output:
                time of sunrise/sunset in hours
        */
        var day    = dayOfTheYear();
        var lat    = App.getApp().getProperty("UserLat").toFloat();
        var lng    = App.getApp().getProperty("UserLng").toFloat();
        var zenith = 90.83333333333333;
        var D2R    = Math.PI / 180;
        var R2D    = 180.0 / Math.PI;

        // Convert the longitude to hour value and calculate an approximate time
        var lnHour = lng / 15;
        var t      = sunrise ? (day + ((6 - lnHour) / 24)) : (day + ((18 - lnHour) / 24)); 
        
        // Calculate the Sun's mean anomaly
        var M = (0.9856 * t) - 3.289;

        // Calculate the Sun's true longitude
        var L = M + (1.916 * Math.sin(M * D2R)) + (0.020 * Math.sin(2 * M * D2R)) + 282.634;
        if (L > 360) {
            L = L - 360;
        } else if (L < 0) {
            L = L + 360;
        }

        // Calculate the Sun's right ascension
        var RA = R2D * Math.atan(0.91764 * Math.tan(L * D2R));
        if (RA > 360) {
            RA = RA - 360;
        } else if (RA < 0) {
            RA = RA + 360;
        }

        // Right ascension value needs to be in the same qua and right ascension value needs to be converted into hours
        var Lquadrant  = (Math.floor(L / (90))) * 90;
        var RAquadrant = (Math.floor(RA / 90)) * 90;
        RA = (RA + (Lquadrant - RAquadrant)) / 15;

        // Calculate the Sun's declination
        var sinDec = 0.39782 * Math.sin(L * D2R);
        var cosDec = Math.cos(Math.asin(sinDec));

        // Calculate the Sun's local hour angle
        var cosH = (Math.cos(zenith * D2R) - (sinDec * Math.sin(lat * D2R))) / (cosDec * Math.cos(lat * D2R));
        var H    = (sunrise ? (360 - R2D * Math.acos(cosH)) : (R2D * Math.acos(cosH))) / 15;

        // Calculate local mean time of rising/setting
        var T = H + RA - (0.06571 * t) - 6.622;

        // Adjust back to UTC
        var UT = clampTo24((T - lnHour));

        // Current timezone offset from settings
        var currentTimezoneOffset = App.getApp().getProperty("CurrentTimezoneOffset").toFloat() / 3600.0;

        // Take current timezone daylight saving time into account from settings
        if (App.getApp().getProperty("CurrentDST")) {
            currentTimezoneOffset++;
        }

        // Convert UT value to local time zone of latitude/longitude
        var localT = clampTo24((UT + currentTimezoneOffset));

        // Convert to Milliseconds
        return localT * 3600 * 1000;
    }
    
    function clampTo24(value) {
        if (value > 24) {
            value = value - 24;
        } else if (value < 0) {
            value = value + 24;
        }
        return value;
    }
}