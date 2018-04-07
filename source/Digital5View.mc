using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.ActivityMonitor as Act;
using Toybox.Attention as Att;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.Application as App;
using Toybox.UserProfile as UserProfile;
using Toybox.Ant as Ant;
using Toybox.SensorHistory as Sensor;



class Digital5View extends Ui.WatchFace {
    var is24Hour;
    var secondsAlwaysOn;
    var lcdFont;
    var lcdFontDataFields;
    var showLeadingZero;
    var clockTime;
    var sunRiseSet;

    enum { WOMAN, MEN }
    enum { UPPER_LEFT, UPPER_RIGHT, LOWER_LEFT, LOWER_RIGHT, BOTTOM_FIELD }
    enum { M, I, K, B, C, F, T }
    enum { KCAL, ACTIVE_KCAL, ACTIVE_KCAL_REACHED }
    const BRIGHT_BLUE      = 0x0055ff;
    const BRIGHT_GREEN     = 0x55ff00;
    const BRIGHT_RED       = 0xff0055;
    const YELLOW           = 0xffff00;
    const BPM_COLORS       = [ 0x0000FF, 0x00AA00, 0x00FF00, 0xFFAA00, 0xFF0000 ];
    const STEP_COLORS      = [ 0x550000, Gfx.COLOR_DK_RED, Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_YELLOW, YELLOW, 0xaaff00, 0x55ff55, BRIGHT_GREEN, Gfx.COLOR_GREEN ];
    const DARK_STEP_COLORS = [ 0x550000, Gfx.COLOR_DK_RED, Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_YELLOW, 0xaaaa00, 0x55aa00, 0x55aa55, 0x00aa55, 0x00aa00 ];
    const DAY_COUNT        = [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 ];
    var weekdays           = new [7];
    var months             = new [12];
    var sunriseText        = "--:--";
    var sunsetText         = "--:--";
    var currentWeather;
    var digitalUpright72, digitalUpright26, digitalUpright24, digitalUpright20, digitalUpright16;
    var burnedIcon, burnedIconWhite, stepsIcon, stepsIconWhite;
     
    var width, height;
    var centerX, centerY;        
    var midnightInfo;
    var nowinfo;
    var actinfo;
    var systemStats;        
    var hrHistory, hr;
    var steps, stepGoal, deltaSteps, stepsReached;
    var kcal, activeKcal, kcalReached, activeKcalReached;
    var bpm, showBpmZones, maxBpm, currentZone;
    var distanceUnit, distance;     
    var tempUnit;
    var altUnit;
    var coloredStepText;
    var coloredCalorieText;
    var upperLeftField, upperRightField, lowerLeftField, lowerRightField, bottomField;
    var darkUpperBackground, upperBackgroundColor, upperForegroundColor;
    var darkFieldBackground, fieldBackgroundColor, fieldForegroundColor;
    var deviceName, apiKey;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        digitalUpright72 = Ui.loadResource(Rez.Fonts.digitalUpright72);
        digitalUpright26 = Ui.loadResource(Rez.Fonts.digitalUpright26);
        digitalUpright24 = Ui.loadResource(Rez.Fonts.digitalUpright24);
        digitalUpright20 = Ui.loadResource(Rez.Fonts.digitalUpright20);
        digitalUpright16 = Ui.loadResource(Rez.Fonts.digitalUpright16);
        burnedIcon       = Ui.loadResource(Rez.Drawables.burned);
        burnedIconWhite  = Ui.loadResource(Rez.Drawables.burnedWhite);
        stepsIcon        = Ui.loadResource(Rez.Drawables.steps);
        stepsIconWhite   = Ui.loadResource(Rez.Drawables.stepsWhite);
        weekdays[0]      = Ui.loadResource(Rez.Strings.Sun);
        weekdays[1]      = Ui.loadResource(Rez.Strings.Mon);
        weekdays[2]      = Ui.loadResource(Rez.Strings.Tue);
        weekdays[3]      = Ui.loadResource(Rez.Strings.Wed);
        weekdays[4]      = Ui.loadResource(Rez.Strings.Thu);
        weekdays[5]      = Ui.loadResource(Rez.Strings.Fri);
        weekdays[6]      = Ui.loadResource(Rez.Strings.Sat);
        months[0]        = Ui.loadResource(Rez.Strings.Jan);
        months[1]        = Ui.loadResource(Rez.Strings.Feb);
        months[2]        = Ui.loadResource(Rez.Strings.Mar);
        months[3]        = Ui.loadResource(Rez.Strings.Apr);
        months[4]        = Ui.loadResource(Rez.Strings.May);
        months[5]        = Ui.loadResource(Rez.Strings.Jun);
        months[6]        = Ui.loadResource(Rez.Strings.Jul);
        months[7]        = Ui.loadResource(Rez.Strings.Aug);
        months[8]        = Ui.loadResource(Rez.Strings.Sep);
        months[9]        = Ui.loadResource(Rez.Strings.Oct);
        months[10]       = Ui.loadResource(Rez.Strings.Nov);
        months[11]       = Ui.loadResource(Rez.Strings.Dec);
        deviceName       = Ui.loadResource(Rez.Strings.deviceName);
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
 
        dc.clearClip();
 
        is24Hour                  = Sys.getDeviceSettings().is24Hour;
        secondsAlwaysOn           = App.getApp().getProperty("SecondsAlwaysOn");
        lcdFont                   = App.getApp().getProperty("LcdFont");
        lcdFontDataFields         = App.getApp().getProperty("LcdFontDataFields");
        showLeadingZero           = App.getApp().getProperty("ShowLeadingZero");
        
        clockTime                 = Sys.getClockTime();       
        sunRiseSet                = new SunRiseSunSet();
        currentWeather            = App.getApp().getProperty("CurrentWeather");
         
        // General
        width                     = dc.getWidth();
        height                    = dc.getHeight();
        centerX                   = width * 0.5;
        centerY                   = height * 0.5;        
        midnightInfo              = Greg.info(Time.today(), Time.FORMAT_SHORT);
        nowinfo                   = Greg.info(Time.now(), Time.FORMAT_SHORT);
        actinfo                   = Act.getInfo();
        systemStats               = Sys.getSystemStats();        
        hrHistory                 = Act.getHeartRateHistory(null, true);
        hr                        = hrHistory.next();
        steps                     = actinfo.steps;
        stepGoal                  = actinfo.stepGoal;
        deltaSteps                = stepGoal - steps;
        stepsReached              = steps.toDouble() / stepGoal;
        kcal                      = actinfo.calories;
        bpm                       = (hr.heartRate != Act.INVALID_HR_SAMPLE && hr.heartRate > 0) ? hr.heartRate : 0;
        showBpmZones              = App.getApp().getProperty("BpmZones");
        distanceUnit              = Sys.getDeviceSettings().distanceUnits;
        tempUnit                  = App.getApp().getProperty("TempUnit");
        altUnit                   = App.getApp().getProperty("AltUnit");
        distance                  = distanceUnit == 0 ? actinfo.distance * 0.00001 : actinfo.distance * 0.00001 * 0.621371;
        coloredStepText           = App.getApp().getProperty("ColorizeStepText");
        coloredCalorieText        = App.getApp().getProperty("ColorizeCalorieText");
        upperLeftField            = App.getApp().getProperty("UpperLeftField").toNumber();
        upperRightField           = App.getApp().getProperty("UpperRightField").toNumber();
        lowerLeftField            = App.getApp().getProperty("LowerLeftField").toNumber();
        lowerRightField           = App.getApp().getProperty("LowerRightField").toNumber();
        bottomField               = App.getApp().getProperty("BottomField").toNumber();
        darkUpperBackground       = App.getApp().getProperty("DarkUpperBackground");
        upperBackgroundColor      = darkUpperBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
        upperForegroundColor      = darkUpperBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        darkFieldBackground       = App.getApp().getProperty("DarkFieldBackground");
        fieldBackgroundColor      = darkFieldBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
        fieldForegroundColor      = darkFieldBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        apiKey                    = App.getApp().getProperty("DarkSkyApiKey");
        
        var charge                = systemStats.battery + 0.5;
        var showChargePercentage  = App.getApp().getProperty("ShowChargePercentage");
        var showPercentageUnder20 = App.getApp().getProperty("ShowPercentageUnder20");
        var dayOfWeek             = nowinfo.day_of_week;
        var lcdBackgroundVisible  = App.getApp().getProperty("LcdBackground");
        var connected             = Sys.getDeviceSettings().phoneConnected;        
        var profile               = UserProfile.getProfile();
        var notificationCount     = Sys.getDeviceSettings().notificationCount;
        var alarmCount            = Sys.getDeviceSettings().alarmCount;
        var dst                   = App.getApp().getProperty("DST");    
        var timezoneOffset        = clockTime.timeZoneOffset;
        var showHomeTimezone      = App.getApp().getProperty("ShowHomeTimezone");
        var homeTimezoneOffset    = dst ? App.getApp().getProperty("HomeTimezoneOffset") + 3600 : App.getApp().getProperty("HomeTimezoneOffset");
        var onTravel              = timezoneOffset != homeTimezoneOffset;
        var dayMonth              = App.getApp().getProperty("DateFormat") == 0;
        var dateFormat            = dayMonth ? "$1$.$2$" : "$2$/$1$";
        var monthAsText           = App.getApp().getProperty("MonthAsText");
        var showCalendarWeek      = App.getApp().getProperty("ShowCalendarWeek");        
        var showMoveBar           = App.getApp().getProperty("ShowMoveBar");
        var showStepBar           = App.getApp().getProperty("ShowStepBar");
        var showCalorieBar        = App.getApp().getProperty("ShowCalorieBar");
        var hourColor             = App.getApp().getProperty("HourColor").toNumber();
        var minuteColor           = App.getApp().getProperty("MinuteColor").toNumber();
        var coloredBattery        = App.getApp().getProperty("ColoredBattery");
        var showSunriseSunset     = App.getApp().getProperty("SunriseSunset");
        var activeKcalGoal        = App.getApp().getProperty("ActiveKcalGoal").toNumber();
        var biggerBatteryFont     = App.getApp().getProperty("BiggerBatteryFont");
        var gender;
        var userWeight;
        var userHeight;
        var userAge;
        
        if (profile == null) {
            gender     = App.getApp().getProperty("Gender");
            userWeight = App.getApp().getProperty("Weight");
            userHeight = App.getApp().getProperty("Height");
            userAge    = App.getApp().getProperty("Age");
        } else {
            gender     = profile.gender;
            userWeight = profile.weight / 1000.0;
            userHeight = profile.height;
            userAge    = nowinfo.year - profile.birthYear;
        }

        // Mifflin-St.Jeor Formula (1990)
        var baseKcalMen   = (9.99 * userWeight) + (6.25 * userHeight) - (4.92 * userAge) + 5.0;             // base kcal men
        var baseKcalWoman = (9.99 * userWeight) + (6.25 * userHeight) - (4.92 * userAge) - 161.0;           // base kcal woman
        var baseKcal      = (gender == MEN ? baseKcalMen : baseKcalWoman) * 1.21385;                        // base kcal related to gender incl. correction factor for fenix 5x
        var kcalPerMinute = baseKcal / 1440;                                                                // base kcal per minute
        kcalReached       = kcal / baseKcal;
        activeKcal        = (kcal - (kcalPerMinute * (clockTime.hour * 60.0 + clockTime.min))).toNumber();  // active kcal
        activeKcalReached = activeKcal - activeKcalGoal;

        // Heart Rate Zones
        maxBpm = (211.0 - 0.64 * userAge).toNumber(); // calculated after a study at NTNU (http://www.ntnu.edu/cerg/hrmax-info)
        var bpmZone1 = (0.5 * maxBpm).toNumber();
        var bpmZone2 = (0.6 * maxBpm).toNumber();
        var bpmZone3 = (0.7 * maxBpm).toNumber();
        var bpmZone4 = (0.8 * maxBpm).toNumber();
        var bpmZone5 = (0.9 * maxBpm).toNumber();
                
        if (bpm >= bpmZone5) {
            currentZone = 5;
        } else if (bpm >= bpmZone4) {
            currentZone = 4;
        } else if (bpm >= bpmZone3) {
            currentZone = 3;
        } else if (bpm >= bpmZone2) {
            currentZone = 2;
        } else {
            currentZone = 1;
        }

        // Draw Background
        dc.setPenWidth(1);     
        dc.setColor(upperBackgroundColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, 151);
        
        if (darkFieldBackground) {
            dc.setColor(fieldBackgroundColor, Gfx.COLOR_TRANSPARENT);    
            dc.fillRectangle(0, 151, width, 89);
            
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 151, width, 2);
            dc.fillRectangle(0, 180, width, 2);
            dc.fillRectangle(0, 211, width, 2);
            dc.fillRectangle(119, 151, 2, 60);
        } else {
            dc.setColor(fieldBackgroundColor, Gfx.COLOR_TRANSPARENT);    
            dc.fillRectangle(0, 151, width, 89);
                
            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 149, width, 2);    
                
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, 151, width, 151);
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, 152, width, 152);
    
            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 179, width, 2);
            
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, 181, width, 181);
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, 182, width, 182);
            
            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 210, width, 2);
            
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, 212, width, 212);
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, 213, width, 213);
            
            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(119, 150, 2, 60);
        }
        
        if (showPercentageUnder20 and charge < 20) { showChargePercentage = true; }
        
        var iconOffsetX;
        // Battery        
        if (showChargePercentage) {
            iconOffsetX = charge < 100 ? (lcdFont ? 4 : 5) : 0;
            // Charge Text
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            if (lcdFont) {
                dc.drawText(140 - iconOffsetX, 1, digitalUpright20, charge.toNumber(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(140 - iconOffsetX, -2, Graphics.FONT_XTINY, charge.toNumber(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
            
            // Percentage Sign
            dc.drawLine(142 - iconOffsetX, 16, 148 - iconOffsetX, 6);
            dc.drawRectangle(142 - iconOffsetX, 7, 3, 3);
            dc.drawRectangle(145 - iconOffsetX, 14, 3, 3);
            
            // Vertical Battery
            dc.setColor(upperForegroundColor, upperBackgroundColor);        
            dc.drawRectangle(98 + iconOffsetX, 4, 8, 16);
            dc.fillRectangle(100 + iconOffsetX, 3, 4, 1);
            
            if (coloredBattery) {
                setBatteryColor(charge, dc);
            } else {
                dc.setColor(charge < 20 ? BRIGHT_RED : upperForegroundColor, upperBackgroundColor);
            }
            var chargeHeight = clamp(1, 12, 12.0 * charge / 100.0).toNumber();            
            dc.fillRectangle(100 + iconOffsetX, clamp(6, 18, 18 - chargeHeight), 4, chargeHeight);            
        } else {
            iconOffsetX = lcdFont ? 4 : 5;
        
            // Horizontal Battery
            dc.setColor(upperForegroundColor, upperBackgroundColor);        
            dc.drawRectangle(106, 8, 28, 11);
            dc.fillRectangle(134, 11, 2, 5);
            if (coloredBattery) {
                setBatteryColor(charge, dc);
            } else {
                dc.setColor(charge < 20 ? BRIGHT_RED : upperForegroundColor, upperBackgroundColor);
            }
            dc.fillRectangle(108, 10 , clamp (1, 24, 24.0 * charge / 100.0), 7);
        }
        
        // Notification
        if (notificationCount > 0) { 
            dc.setColor(darkUpperBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, upperBackgroundColor);
            dc.fillRectangle(58, 18, 18, 11);
            dc.setColor(darkUpperBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE, upperBackgroundColor);
            dc.drawLine(59, 18, 67, 26);
            dc.drawLine(74, 18, 66, 26);
            dc.drawLine(58, 29, 64, 23);
            dc.drawLine(75, 29, 69, 23);
        }    
        
        // BLE
        if (connected) {
            dc.setColor(upperForegroundColor, upperBackgroundColor);            
            dc.drawLine(83 + iconOffsetX, 12, 90 + iconOffsetX, 19);
            dc.drawLine(90 + iconOffsetX, 19, 86 + iconOffsetX, 23);
            dc.drawLine(86 + iconOffsetX, 23, 86 + iconOffsetX, 10);
            dc.drawLine(86 + iconOffsetX, 10, 90 + iconOffsetX, 14);
            dc.drawLine(90 + iconOffsetX, 14, 82 + iconOffsetX, 22);            
        }

        dc.setColor(upperForegroundColor, upperBackgroundColor);
        
        // Do not disturb
        if (System.getDeviceSettings().doNotDisturb) {             
            dc.drawCircle(161 - iconOffsetX, 17, 7);
            dc.fillRectangle(158 - iconOffsetX, 16, 7, 3);
        }
        
        // Alarm
        if (alarmCount > 0) {
            dc.fillPolygon([[178, 17], [180, 19], [181, 21], [182, 25], [183, 26], [183, 27], [172, 27], [172, 26], [173, 25], [174, 21], [175, 19]]);
            dc.fillPolygon([[176, 28], [178, 30], [180, 28]]);
        }
                            
        // Sunrise/Sunset
        if (showSunriseSunset) {
            calcSunriseSunset();
            dc.fillPolygon([[45, 50], [57, 50], [50, 44]]);    // upIcon
            dc.fillPolygon([[184, 44], [194, 44], [188, 49]]); // downIcon
            if (lcdFont) {
                dc.drawText(59, 36, digitalUpright16, sunriseText, Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(181, 36, digitalUpright16, sunsetText, Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                var y = deviceName.equals("vivoactive3") ? 32 : 28;
                dc.drawText(57, y, Graphics.FONT_XTINY, sunriseText, Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(182, y, Graphics.FONT_XTINY, sunsetText, Gfx.TEXT_JUSTIFY_RIGHT);
            }
        }
                    
        // Step Bar background
        if (showStepBar) {
            dc.setPenWidth(8);           
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, upperBackgroundColor);
            for(var i = 0; i < 10 ; i++) {            
                var startAngleLeft  = 130 + (i * 6);
                dc.drawArc(centerX, centerY, 117, 0, startAngleLeft, startAngleLeft + 5);
            }
            
            // Step Goal Bar
            stepsReached      = stepsReached > 1.0 ? 1.0 : stepsReached;
            var endIndex      = (10.0 * stepsReached).toNumber();
            var stopAngleLeft = (184.0 - 59.0 * stepsReached).toNumber();
            stopAngleLeft     = stopAngleLeft < 130.0 ? 130.0 : stopAngleLeft;        
            if (darkUpperBackground) {
                dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : Gfx.COLOR_TRANSPARENT, upperBackgroundColor);
            } else {
                dc.setColor(endIndex > 0 ? DARK_STEP_COLORS[endIndex - 1] : Gfx.COLOR_TRANSPARENT, upperBackgroundColor);
            }
            for(var i = 0; i < endIndex ; i++) {            
                var startAngleLeft  = 184 - (i * 6);
                dc.drawArc(centerX, centerY, 117, 0, startAngleLeft, startAngleLeft + 5);
            }
        }

        // KCal Goal Bar Background
        if (showCalorieBar) {
            if (kcalReached > 3.0) {
                dc.setColor(Gfx.COLOR_PINK, upperBackgroundColor);
            } else if (kcalReached > 2.0) {
                dc.setColor(Gfx.COLOR_GREEN, upperBackgroundColor);
            } else if (kcalReached > 1.0) {
                dc.setColor(BRIGHT_BLUE, upperBackgroundColor);
            } else {
                dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, upperBackgroundColor);
            }
            for(var i = 0; i < 10 ; i++) {            
                var startAngleRight = -10 + (i * 6);         
                dc.drawArc(centerX, centerY, 117, 0, startAngleRight, startAngleRight + 5);            
            }
                    
            // KCal Goal Bar
            if (kcalReached > 3.0) {
                dc.setColor(Gfx.COLOR_YELLOW, upperBackgroundColor);
                kcalReached -= 3.0;
            } else if (kcalReached > 2.0) {
                dc.setColor(Gfx.COLOR_PINK, upperBackgroundColor);
                kcalReached -= 2.0;
            } else if (kcalReached > 1.0) {
                dc.setColor(Gfx.COLOR_GREEN, upperBackgroundColor);
                kcalReached -= 1.0;
            } else {
                dc.setColor(BRIGHT_BLUE, upperBackgroundColor);
            }
            var stopAngleRight = (-10.0 + 59.0 * kcalReached).toNumber();
            stopAngleRight = stopAngleRight > 59.0 ? 59.0 : stopAngleRight;
            for(var i = 0; i < 10 ; i++) {
                var startAngleRight = -10 + (i * 6);
                if (startAngleRight < stopAngleRight) { dc.drawArc(centerX, centerY, 117, 0, startAngleRight, startAngleRight + 5); }
            }
        }

        // Move Bar
        if (showMoveBar) {
            var moveBarLevel = actinfo.moveBarLevel;
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, upperBackgroundColor);
            dc.fillRectangle(29, 144, 73, 4);
            for (var i = 0 ; i < 4 ; i++) { dc.fillRectangle(104 + (i * 27), 144, 25, 4); }
            if (moveBarLevel > Act.MOVE_BAR_LEVEL_MIN) { dc.setColor(Gfx.COLOR_RED, upperBackgroundColor); }
            dc.fillRectangle(29, 144, 73, 4);
            for (var i = 0 ; i < (moveBarLevel - 1) ; i++) { dc.fillRectangle(104 + (i * 27), 144, 25, 4); }
        }
        
        
        
        // ******************** TIME ******************************************
        if (lcdBackgroundVisible && lcdFont) {
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, upperBackgroundColor);           
            if (showLeadingZero) {
                dc.drawText(centerX, 51, digitalUpright72, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                if (is24Hour) {
                    dc.drawText(centerX, 51, digitalUpright72, clockTime.hour < 10 ? "8:88" : "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                } else {
                    dc.drawText(centerX, 51, digitalUpright72, (clockTime.hour < 10 || clockTime.hour > 12) ? "8:88" : "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                }
            }            
        }
        if (is24Hour) {
            drawTime(hourColor, minuteColor, lcdFont ? digitalUpright72 : Graphics.FONT_NUMBER_HOT, dc);
        } else {
            var amPm = clockTime.hour < 12 ? "am" : "pm";
            if (lcdFont) {   
                drawTime(hourColor, minuteColor, digitalUpright72, dc);
                dc.drawText(195, 93, digitalUpright20, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            } else {
                drawTime(hourColor, minuteColor, Graphics.FONT_NUMBER_HOT, dc);
                dc.drawText(191, 87, Graphics.FONT_XTINY, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            }
        }     
        
        
        // ******************** DATE ******************************************
        
        // KW
        if (showCalendarWeek) {
            var calendarWeekText = Ui.loadResource(Rez.Strings.CalendarWeek);
            dc.drawText((lcdFont ? 43 : 50), (lcdFont ? 71 : 66), lcdFont ? digitalUpright20 : Graphics.FONT_XTINY, (calendarWeekText), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText((lcdFont ? 43 : 50), (lcdFont ? 93 : 87), lcdFont ? digitalUpright20 : Graphics.FONT_XTINY, (getWeekOfYear(nowinfo)), Gfx.TEXT_JUSTIFY_RIGHT);            
        }
    
        // Date and home timezone
        dc.setColor(upperForegroundColor, upperBackgroundColor);
        var dateYPosition = showMoveBar ? 116 : 119;
        dateYPosition = lcdFont ? dateYPosition : dateYPosition - 2;
        if (onTravel && showHomeTimezone) {
            var homeDayOfWeek  = dayOfWeek - 1;
            var homeDay        = nowinfo.day;
            var homeMonth      = nowinfo.month;
            var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
            var utcSeconds     = currentSeconds - clockTime.timeZoneOffset;// - (dst ? 3600 : 0);
            var homeSeconds    = utcSeconds + homeTimezoneOffset;
            if (dst) { homeSeconds = homeTimezoneOffset > 0 ? homeSeconds : homeSeconds - 3600; }
            var homeHour       = ((homeSeconds / 3600)).toNumber() % 24l;
            var homeMinute     = ((homeSeconds - (homeHour.abs() * 3600)) / 60) % 60;
            if (homeHour < 0) {
                homeHour += 24;
                homeDay--;
                if (homeDay == 0) {
                    homeMonth--;
                    if (homeMonth == 0) { homeMonth = 12; }
                    homeDay = daysOfMonth(homeMonth);
                }
                homeDayOfWeek--;
                if (homeDayOfWeek < 0) { homeDayOfWeek = 6; }
            }
            if (homeMinute < 0) { homeMinute += 60; }
            var ampm = is24Hour ? "" : homeHour < 12 ? "A" : "P";
            homeHour = is24Hour ? homeHour : (homeHour == 12) ? homeHour : (homeHour % 12);
            var weekdayText    = weekdays[homeDayOfWeek];
            var dateText       = dayMonth ?  nowinfo.day.format(showLeadingZero ? "%02d" : "%01d") + " " + months[homeMonth - 1] : months[homeMonth - 1] + " " + nowinfo.day.format(showLeadingZero ? "%02d" : "%01d");
            var dateNumberText = Lang.format(dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]);
            var timeText       = Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]) + ampm;            
            dc.drawText(28, dateYPosition, lcdFont ? digitalUpright26 : Graphics.FONT_XTINY, weekdayText + (monthAsText ? dateText : dateNumberText), Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(216, dateYPosition, lcdFont ? digitalUpright26 : Graphics.FONT_XTINY, timeText, Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            var weekdayText    = weekdays[dayOfWeek - 1];            
            var dateText       = dayMonth ?  nowinfo.day.format(showLeadingZero ? "%02d" : "%01d") + " " + months[nowinfo.month - 1] : months[nowinfo.month - 1] + " " + nowinfo.day.format(showLeadingZero ? "%02d" : "%01d");
            var dateNumberText = Lang.format(dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]);
            dc.drawText(centerX, dateYPosition, lcdFont ? digitalUpright26 : Graphics.FONT_XTINY, weekdayText + (monthAsText ? dateText : dateNumberText), Gfx.TEXT_JUSTIFY_CENTER);
        }
                

        // ******************** DATA FIELDS ***********************************
       
        // UpperLeft
        switch(upperLeftField) {
            case 0: drawSteps(getXYPositions(UPPER_LEFT), dc, false, UPPER_LEFT); break;
            case 1: drawCalories(getXYPositions(UPPER_LEFT), dc, KCAL, UPPER_LEFT); break;
            case 2: drawCalories(getXYPositions(UPPER_LEFT), dc, ACTIVE_KCAL, UPPER_LEFT); break;
            case 3: drawHeartRate(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 4: drawDistance(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 5: drawWithUnit(getXYPositions(UPPER_LEFT), dc, 5, UPPER_LEFT); break;
            case 6: drawWithUnit(getXYPositions(UPPER_LEFT), dc, 6, UPPER_LEFT); break;
            case 7: drawActiveTime(getXYPositions(UPPER_LEFT), dc, true, UPPER_LEFT); break;
            case 8: drawActiveTime(getXYPositions(UPPER_LEFT), dc, false, UPPER_LEFT); break;
            case 9: drawFloors(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 10: drawMeters(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 11: drawActKcalAvg(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 12: drawSteps(getXYPositions(UPPER_LEFT), dc, true, UPPER_LEFT); break;
            case 13: drawWithUnit(getXYPositions(UPPER_LEFT), dc, 13, UPPER_LEFT); break;
            case 14: drawCalories(getXYPositions(UPPER_LEFT), dc, ACTIVE_KCAL_REACHED, UPPER_LEFT); break;
        }
       
        // UpperRight
        switch(upperRightField) {
            case 0: drawSteps(getXYPositions(UPPER_RIGHT), dc, false, UPPER_RIGHT); break;
            case 1: drawCalories(getXYPositions(UPPER_RIGHT), dc, KCAL, UPPER_RIGHT); break;
            case 2: drawCalories(getXYPositions(UPPER_RIGHT), dc, ACTIVE_KCAL, UPPER_RIGHT); break;
            case 3: drawHeartRate(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 4: drawDistance(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 5: drawWithUnit(getXYPositions(UPPER_RIGHT), dc, 5, UPPER_RIGHT); break;
            case 6: drawWithUnit(getXYPositions(UPPER_RIGHT), dc, 6, UPPER_RIGHT); break;
            case 7: drawActiveTime(getXYPositions(UPPER_RIGHT), dc, true, UPPER_RIGHT); break;
            case 8: drawActiveTime(getXYPositions(UPPER_RIGHT), dc, false, UPPER_RIGHT); break;
            case 9: drawFloors(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 10: drawMeters(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 11: drawActKcalAvg(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 12: drawSteps(getXYPositions(UPPER_RIGHT), dc, true, UPPER_RIGHT); break;
            case 13: drawWithUnit(getXYPositions(UPPER_RIGHT), dc, 13, UPPER_RIGHT); break;
            case 14: drawCalories(getXYPositions(UPPER_RIGHT), dc, ACTIVE_KCAL_REACHED, UPPER_RIGHT); break;
        }
       
        // LowerLeft
        switch(lowerLeftField) {
            case 0: drawSteps(getXYPositions(LOWER_LEFT), dc, false, LOWER_LEFT); break;
            case 1: drawCalories(getXYPositions(LOWER_LEFT), dc, KCAL, LOWER_LEFT); break;
            case 2: drawCalories(getXYPositions(LOWER_LEFT), dc, ACTIVE_KCAL, LOWER_LEFT); break;
            case 3: drawHeartRate(getXYPositions(LOWER_LEFT), dc, LOWER_LEFT); break;
            case 4: drawDistance(getXYPositions(LOWER_LEFT), dc, UPPER_LEFT); break;
            case 7: drawActiveTime(getXYPositions(LOWER_LEFT), dc, true, LOWER_LEFT); break;
            case 8: drawActiveTime(getXYPositions(LOWER_LEFT), dc, false, LOWER_LEFT); break;
            case 9: drawFloors(getXYPositions(LOWER_LEFT), dc, LOWER_LEFT); break;
            case 14: drawCalories(getXYPositions(LOWER_LEFT), dc, ACTIVE_KCAL_REACHED, LOWER_LEFT); break;
        }
       
        // LowerRight
        switch(lowerRightField) {
            case 0: drawSteps(getXYPositions(LOWER_RIGHT), dc, false, LOWER_RIGHT); break;
            case 1: drawCalories(getXYPositions(LOWER_RIGHT), dc, KCAL, LOWER_RIGHT); break;
            case 2: drawCalories(getXYPositions(LOWER_RIGHT), dc, ACTIVE_KCAL, LOWER_RIGHT); break;
            case 3: drawHeartRate(getXYPositions(LOWER_RIGHT), dc, LOWER_RIGHT); break;
            case 4: drawDistance(getXYPositions(LOWER_RIGHT), dc, LOWER_RIGHT); break;
            case 7: drawActiveTime(getXYPositions(LOWER_RIGHT), dc, true, LOWER_RIGHT); break;
            case 8: drawActiveTime(getXYPositions(LOWER_RIGHT), dc, false, LOWER_RIGHT); break;
            case 9: drawFloors(getXYPositions(LOWER_RIGHT), dc, LOWER_RIGHT); break;
            case 14: drawCalories(getXYPositions(LOWER_RIGHT), dc, ACTIVE_KCAL_REACHED, LOWER_RIGHT); break;
        }

        // Bottom field
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        
        switch(bottomField) {
            case 1: drawCalories(getXYPositions(BOTTOM_FIELD), dc, KCAL, BOTTOM_FIELD); break;
            case 2: drawCalories(getXYPositions(BOTTOM_FIELD), dc, ACTIVE_KCAL, BOTTOM_FIELD); break;
            case 3: drawHeartRate(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD); break;
            case 4: 
                drawWithUnit(getXYPositions(BOTTOM_FIELD), dc, 4, BOTTOM_FIELD);
                if (distanceUnit == 0) {
                    drawCharacter(dc, K, 0);
                    drawCharacter(dc, M, 6);
                } else {
                    drawCharacter(dc, M, 0);
                    drawCharacter(dc, I, 0);
                }
                break;
            case 5: 
                drawWithUnit(getXYPositions(BOTTOM_FIELD), dc, 5, BOTTOM_FIELD);                
                if (altUnit == 0) {
                    drawCharacter(dc, M, 0);
                } else {
                    drawCharacter(dc, F, 0);
                    drawCharacter(dc, T, 0);
                }
                break;
            case 6:
                drawWithUnit(getXYPositions(BOTTOM_FIELD), dc, 6, BOTTOM_FIELD);
                drawCharacter(dc, M, 0);
                drawCharacter(dc, B, 0);
                break;
            case 7: dc.drawText(120, 213, lcdFontDataFields ? digitalUpright20 : Graphics.FONT_XTINY, getActiveTimeText(true), Gfx.TEXT_JUSTIFY_CENTER); break;
            case 8: dc.drawText(120, 213, lcdFontDataFields ? digitalUpright20 : Graphics.FONT_XTINY, getActiveTimeText(false), Gfx.TEXT_JUSTIFY_CENTER); break;
            case 9:
                drawFloors(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD);
                dc.fillPolygon([[63, 221], [75, 221], [68, 215]]);    // up
                dc.fillPolygon([[170, 216], [180, 216], [175, 221]]); // down
                break;
            case 10:
                drawMeters(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD);
                dc.fillPolygon([[63, 221], [75, 221], [68, 215]]);    // up
                dc.fillPolygon([[170, 216], [180, 216], [175, 221]]); // down
                break;
            case 11:
                drawActKcalAvg(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD);
                dc.setPenWidth(2);
                dc.drawCircle(69, 220, 4);
                dc.drawLine(65, 224, 74, 215);            
                break;
            case 13:
                drawWithUnit(getXYPositions(BOTTOM_FIELD), dc, 13, BOTTOM_FIELD);
                drawCharacter(dc, tempUnit == 0 ? C : F, 0);
                break;
            case 14: drawCalories(getXYPositions(BOTTOM_FIELD), dc, ACTIVE_KCAL_REACHED, BOTTOM_FIELD); break;
        }
        onPartialUpdate(dc);
        updateLocation();
    }
    
    // ******************** DRAWING FUNCTIONS *********************************
     
    function drawSeconds(dc) {
        var clockTime = Sys.getClockTime();
        dc.setColor(upperBackgroundColor, upperBackgroundColor);
        if (is24Hour) {
            if (lcdFont) {                
                dc.fillRectangle(195, 96, 25, 15);
                dc.setClip(195, 96, 25, 15);
            } else {
                dc.fillRectangle(191, 93, 21, 17);
                dc.setClip(191, 93, 21, 17);
            }
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawText((lcdFont ? 195 : 191), (lcdFont ? 93 : 87), lcdFont ? digitalUpright20 : Graphics.FONT_XTINY, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            if (lcdFont) {                
                dc.fillRectangle(195, 75, 25, 15);
                dc.setClip(195, 75, 25, 15);
            } else {
                dc.fillRectangle(191, 74, 21, 17);
                dc.setClip(191, 74, 21, 17);
            }
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawText((lcdFont ? 195 : 191), (lcdFont ? 71 : 68), lcdFont ? digitalUpright20 : Graphics.FONT_XTINY, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        }
        //dc.clearClip(); // does not work here, instead clear clip at the beginning on onUpdate()
    }
    
    function daysOfMonth(month) { 
        return 28 + (month + Math.floor(month / 8)) % 2 + 2 % month + 2 * Math.floor(1 / month); 
    }

    function onShow() {}

    function onHide() {}

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {}
    
    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }
    
    //! Called every second
    function onPartialUpdate(dc) {
        if (secondsAlwaysOn) { drawSeconds(dc); }
        var clockTime = Sys.getClockTime();
        if (clockTime.hour == 23 && clockTime.min == 59 && clockTime.sec == 59) {
            addActKcalToAverage(activeKcal); 
        } else if (clockTime.hour == 0 && clockTime.min == 0 && clockTime.sec == 59) {
            App.getApp().setProperty("sunrise", (sunRiseSet.computeSunrise(true) / 3600000));
            App.getApp().setProperty("sunset", (sunRiseSet.computeSunrise(false) / 3600000));
        }
    }

    function drawSteps(xyPositions, dc, showDeltaSteps, field) {       
        var bmpX  = xyPositions[0];
        var bmpY  = xyPositions[1];
        var textX = xyPositions[2];
        var textY = xyPositions[3];
        
        dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? stepsIconWhite : stepsIcon);
        if (showDeltaSteps) {
            dc.setColor(deltaSteps > 0 ? BRIGHT_RED : Gfx.COLOR_BLACK, fieldBackgroundColor);
        } else {
            if (coloredStepText) {
                stepsReached = stepsReached > 1.0 ? 1.0 : stepsReached;
                var endIndex = (10.0 * stepsReached).toNumber();
                if (darkUpperBackground) {
                    dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : Gfx.COLOR_BLACK, fieldBackgroundColor);
                } else {
                    dc.setColor(endIndex > 0 ? DARK_STEP_COLORS[endIndex - 1] : Gfx.COLOR_BLACK, fieldBackgroundColor);
                }
            } else {
                dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            }
        }
        dc.drawText(textX, textY, lcdFontDataFields ? digitalUpright24 : Graphics.FONT_XTINY, (showDeltaSteps ? deltaSteps * -1 : steps), getTextJustification(field));
    }
    
    function drawCalories(xyPositions, dc, kcalType, field) {
        var bmpX      = xyPositions[0];
        var bmpY      = xyPositions[1];
        var textX     = xyPositions[2];
        var textY     = xyPositions[3];
        var fieldText = "";
        dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? burnedIconWhite : burnedIcon);
        switch(kcalType) {
            case KCAL:
                if (coloredCalorieText) {
                    if (kcalReached > 3.0) {
                        dc.setColor(Gfx.COLOR_PINK, fieldBackgroundColor);
                    } else if (kcalReached > 2.0) {
                        dc.setColor(Gfx.COLOR_GREEN, fieldBackgroundColor);
                    } else if (kcalReached > 1.0) {
                        dc.setColor(BRIGHT_BLUE, fieldBackgroundColor);
                    } else {
                        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
                    }
                } else {
                    dc.setColor(fieldForegroundColor, fieldBackgroundColor);
                }
                fieldText = kcal.toString();
                break;
            case ACTIVE_KCAL:
                dc.setColor(fieldForegroundColor, fieldBackgroundColor);
                fieldText = (activeKcal < 0 ? "0" : activeKcal.toString());
                break;
            case ACTIVE_KCAL_REACHED:
                dc.setColor(activeKcalReached < 0 ? Gfx.COLOR_RED : fieldForegroundColor, fieldBackgroundColor);
                fieldText = activeKcalReached.toString();
                break;
        }

        if (lcdFontDataFields) {
        	textX = (field == BOTTOM_FIELD) ? centerLcdTextForBottomField(fieldText, textX, true) : textX;
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, fieldText, getTextJustification(field));
        } else {
        	textX = (field == BOTTOM_FIELD) ? centerTextForBottomField(fieldText, textX, true) : textX;
            dc.drawText(textX, textY, Graphics.FONT_XTINY, fieldText, getTextJustification(field));
        }
    }
    
    function drawHeartRate(xyPositions, dc, field) {       
        var bmpX  = xyPositions[0];
        var bmpY  = xyPositions[1];
        var textX = xyPositions[2];
        var textY = xyPositions[3];

        dc.setColor(showBpmZones ? BPM_COLORS[currentZone - 1] : fieldForegroundColor, fieldBackgroundColor);
        dc.fillCircle(bmpX + 6, bmpY + 6, 5);
        dc.fillCircle(bmpX + 15, bmpY + 6, 5);
        dc.fillRectangle(bmpX + 10, bmpY + 3, 2, 2);
        dc.fillPolygon([[bmpX + 2, bmpY + 9], [bmpX + 10, bmpY + 5], [bmpX + 18, bmpY + 9], [bmpX + 17, bmpY + 12], [bmpX + 10, bmpY + 18], [bmpX + 5, bmpY + 12]]);
        
        if (bpm >= maxBpm) {
            dc.setColor(darkFieldBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(bmpX + 10, bmpY + 5, 2, 5);
            dc.fillRectangle(bmpX + 10, bmpY + 12, 2, 2);
        }
             
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        
        var fieldText = bpm > 0 ? bpm.toString() : "";
        if (lcdFontDataFields) {
        	textX = (field == BOTTOM_FIELD) ? centerLcdTextForBottomField(fieldText, textX, true) : textX;
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, fieldText, getTextJustification(field));
        } else {
        	textX = (field == BOTTOM_FIELD) ? centerTextForBottomField(fieldText, textX, true) : textX;
            dc.drawText(textX, textY, Graphics.FONT_XTINY, fieldText, getTextJustification(field));
        }
    }
    
    function drawDistance(xyPositions, dc, field) {        
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var unitLcdX = xyPositions[4];
        var unitLcdY = xyPositions[5];
        var unitX    = xyPositions[6];
        var unitY    = xyPositions[7];
        				
		dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, digitalUpright24, distance > 99.99 ? distance.format("%.0f") : distance.format("%.1f"), getTextJustification(field));
            dc.drawText(unitLcdX, unitLcdY, digitalUpright16, distanceUnit == 0 ? "km" : "mi", getUnitJustification(field));
        } else {
            dc.drawText(textX, textY, Graphics.FONT_XTINY, distance > 99.99 ? distance.format("%.0f") : distance.format("%.1f"), getTextJustification(field));
            dc.drawText(unitX, unitY, Graphics.FONT_XTINY, distanceUnit == 0 ? "km" : "mi", getUnitJustification(field));
        }
    }
    
    function drawWithUnit(xyPositions, dc, sensor, field) {        
		var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var unitLcdX = xyPositions[4];
        var unitLcdY = xyPositions[5];
        var unitX    = xyPositions[6];
        var unitY    = xyPositions[7];
        var fieldText;
        var unitText = "";
        switch(sensor) {
            case 4: // Distance
                fieldText = distance > 99.99 ? distance.format("%.0f") : distance.format("%.1f");
                unitText  = distanceUnit == 0 ? "km" : "mi";
                break;
            case 5: // Altitude
                var altHistory     = Sensor.getElevationHistory(null);        
                var altitude       = altHistory.next();
                var altitudeOffset = App.getApp().getProperty("AltitudeOffset").toFloat();
                if (null == altitude) {
                    fieldText = "-";
                } else {
                    if (altUnit == 0) {
                        fieldText = (altitude.data.toFloat() + altitudeOffset).format("%.0f");
                    } else {
                        fieldText = ((altitude.data.toFloat() + altitudeOffset) / 0.3048).format("%.0f");
                    }
                }
                unitText = altUnit == 0 ? "m" : "ft";
                break;
            case 6: // Pressure
                var pressureHistory = Sensor.getPressureHistory(null);
                var pressure        = pressureHistory.next();
                var pressureOffset  = App.getApp().getProperty("PressureOffset").toFloat() * 100.0;                
                fieldText = null == pressure ? "-" : ((pressure.data.toFloat() + pressureOffset) / 100.0).format("%.2f");
                unitText = "mb";
                break;
            case 13: // Weather
                if (apiKey.length() > 0) {
                    if (field == 4) { textX += 10; }
                    var icon = 7;
                    if (currentWeather) {
                        var temp = App.getApp().getProperty("temp");
                        if (null == temp) {
                            fieldText = "--/--";
                            unitText  = "E";
                        } else {
                            if (tempUnit == 1) { temp = temp * 1.8 + 32; }
                            icon = App.getApp().getProperty("icon");
                            var bmpX  = xyPositions[0];
                            var bmpY  = xyPositions[1];
                            fieldText = temp.format("%.1f");
                        }
                    } else {
                        var tempMin = App.getApp().getProperty("tempMin");
                        var tempMax = App.getApp().getProperty("tempMax");
                        if (null == tempMin || null == tempMax) {
                            fieldText = "--/--";
                            unitText  = "E";
                        } else {
                            if (tempUnit == 1) {
                                tempMin = tempMin * 1.8 + 32;
                                tempMax = tempMax * 1.8 + 32;
                            }
                            icon = App.getApp().getProperty("icon");
                            var bmpX  = xyPositions[0];
                            var bmpY  = xyPositions[1];
                            fieldText = tempMin.format("%.0f") + "/" + tempMax.format("%.0f");
                        }
                    }
                    drawWeatherSymbol(field, icon, dc);
                } else {
                    fieldText = "--/--";
                    unitText  = "E";
                }
                break;
        }
        
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
        	textX = (field == BOTTOM_FIELD) ? centerLcdTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, fieldText, getTextJustification(field));
            dc.drawText(unitLcdX, unitLcdY, digitalUpright16, unitText, getUnitJustification(field));
        } else {
        	textX = (field == BOTTOM_FIELD) ? centerTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, Graphics.FONT_XTINY, fieldText, getTextJustification(field));
            dc.drawText(unitX, unitY, Graphics.FONT_XTINY, unitText, getUnitJustification(field));
        }
    }
    
    function drawActiveTime(xyPositions, dc, isDay, field) {
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var unitLcdX = xyPositions[4];
        var unitLcdY = xyPositions[5];
        var unitX    = xyPositions[6];
        var unitY    = xyPositions[7];
      
        var activeTimeText = getActiveTimeText(isDay);        
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, digitalUpright24, activeTimeText, getTextJustification(field));
            dc.drawText(unitLcdX, unitLcdY, digitalUpright16, isDay ? "D" : "W", getUnitJustification(field));
        } else {
            dc.drawText(textX, textY, Graphics.FONT_XTINY, activeTimeText, getTextJustification(field));
            dc.drawText(unitX, unitY, Graphics.FONT_XTINY, isDay ? "D" : "W", getUnitJustification(field));
        }  
    }
    
    function drawFloors(xyPositions, dc, field) {
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        
        var floorsClimbed   = actinfo.floorsClimbed;
        var floorsDescended = actinfo.floorsDescended;
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        // draw stairs icon
        if (field < BOTTOM_FIELD) {
            dc.setPenWidth(1);
            dc.drawLine(bmpX + 3, bmpY + 15, bmpX + 6, bmpY + 15);
            dc.drawLine(bmpX + 6, bmpY + 15, bmpX + 6, bmpY + 12);
            dc.drawLine(bmpX + 6, bmpY + 12, bmpX + 9, bmpY + 12);
            dc.drawLine(bmpX + 9, bmpY + 12, bmpX + 9, bmpY + 9);
            dc.drawLine(bmpX + 9, bmpY + 9, bmpX + 12, bmpY + 9);
            dc.drawLine(bmpX + 12, bmpY + 9, bmpX + 12, bmpY + 6);
            dc.drawLine(bmpX + 12, bmpY + 6, bmpX + 15, bmpY + 6);
            dc.drawLine(bmpX + 15, bmpY + 6, bmpX + 15, bmpY + 3);
            dc.drawLine(bmpX + 15, bmpY + 3, bmpX + 18, bmpY + 3);
        }
        
        var fieldText = floorsClimbed.toString() + "/" + floorsDescended.toString();
        
        if (lcdFontDataFields) {
        	textX = (field == BOTTOM_FIELD) ? centerLcdTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, field < BOTTOM_FIELD ? digitalUpright24 : digitalUpright20, fieldText, getTextJustification(field));
        } else {
        	textX = (field == BOTTOM_FIELD) ? centerTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, Graphics.FONT_XTINY, fieldText, getTextJustification(field));
        }
    }
    
    function drawMeters(xyPositions, dc, field) {
        var textX           = xyPositions[2];
        var textY           = xyPositions[3];
        var unitLcdX        = xyPositions[4];
        var unitLcdY        = xyPositions[5];
        var unitX           = xyPositions[6];
        var unitY           = xyPositions[7];
        var metersClimbed   = actinfo.metersClimbed.format("%0d");
        var metersDescended = actinfo.metersDescended.format("%0d");
        var fieldText 		= metersClimbed.toString() + "/" + metersDescended.toString();

        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
        	textX = (field == BOTTOM_FIELD) ? centerLcdTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, field < BOTTOM_FIELD ? digitalUpright24 : digitalUpright20, fieldText, getTextJustification(field));
            if (field < BOTTOM_FIELD) { dc.drawText(unitLcdX, unitLcdY, digitalUpright16, "m", getUnitJustification(field)); }
        } else {
        	textX = (field == BOTTOM_FIELD) ? centerTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, Graphics.FONT_XTINY, fieldText, getTextJustification(field));
            if (field < BOTTOM_FIELD) { dc.drawText(unitX, unitY, Graphics.FONT_XTINY, "m", getUnitJustification(field)); }
        }
    }
    
    function drawActKcalAvg(xyPositions, dc, field) {
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];

        if (field != BOTTOM_FIELD) { 
            dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? burnedIconWhite : burnedIcon);
        }
        
        var fieldText = getActKcalAvg(activeKcal).toString();
        
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
        	textX = (field == BOTTOM_FIELD) ? centerLcdTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, field < BOTTOM_FIELD ? digitalUpright24 : digitalUpright20, fieldText, getTextJustification(field));
        } else {
        	textX = (field == BOTTOM_FIELD) ? centerTextForBottomField(fieldText, textX, false) : textX;
            dc.drawText(textX, textY, Graphics.FONT_XTINY, fieldText, getTextJustification(field));
        }
    }
    
    function drawWeatherSymbol(field, icon, dc) {
        var x;
        var y;
        switch(field) {
            case UPPER_LEFT:
                x = 16;
                y = 157;
                break;
            case UPPER_RIGHT:
                x = 207;
                y = 157;
                break;
            case BOTTOM_FIELD:
                x = 85;
                y = 216;
                break;
        }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        dc.setPenWidth(2);
        switch(icon) {
            case 0:
                // Clear
                dc.drawCircle(x + 10, y + 10, 3);
                dc.drawLine(x + 10, y + 1, x + 10, y + 4);
                dc.drawLine(x + 10, y + 17, x + 10, y + 20);
                dc.drawLine(x + 1, y + 10, x + 4, y + 10);
                dc.drawLine(x + 17, y + 10, x + 20, y + 10);
                dc.drawLine(x + 4, y + 16, x + 6, y + 14);
                dc.drawLine(x + 4, y + 4, x + 6, y + 6);
                dc.drawLine(x + 15, y + 5, x + 17, y + 3);
                dc.drawLine(x + 15, y + 15, x + 17, y + 17);
                break;
            case 1:
                // Rain
                drawCloud(dc, x, y);
                dc.drawLine(x + 14, y + 9, x + 12, y + 12);
                dc.drawLine(x + 9, y + 11, x + 7, y + 14);
                dc.drawLine(x + 15, y + 14, x + 13, y + 17);
                dc.drawLine(x + 10, y + 16, x + 8, y + 19);
                break;
            case 2:
                // Cloudy
                drawCloud(dc, x, y);                
                dc.fillCircle(x + 8, y + 13, 5);
                dc.fillCircle(x + 13, y + 16, 4);
                dc.fillCircle(x + 4, y + 16, 4);
                dc.drawLine(x + 6, y + 20, x + 15, y + 20);
                dc.setColor(fieldBackgroundColor, fieldBackgroundColor);
                dc.fillCircle(x + 8, y + 14, 4);
                dc.fillCircle(x + 12, y + 16, 3);
                dc.fillCircle(x + 5, y + 16, 3);
                dc.fillRectangle(x + 5, y + 14, 10, 6);
                break;
            case 3:
                // Partly Cloudy
                dc.drawCircle(x + 12, y + 8, 3);
                dc.drawLine(x + 12, y - 1, x + 12, y + 2);
                dc.drawLine(x + 3, y + 8, x + 6, y + 8);
                dc.drawLine(x + 19, y + 8, x + 22, y + 8);
                dc.drawLine(x + 7, y + 2, x + 9, y + 4);
                dc.drawLine(x + 18, y + 3, x + 19, y + 1);
                dc.fillCircle(x + 8, y + 13, 5);
                dc.fillCircle(x + 13, y + 16, 4);
                dc.fillCircle(x + 4, y + 16, 4);
                dc.drawLine(x + 6, y + 20, x + 15, y + 20);
                dc.setColor(fieldBackgroundColor, fieldBackgroundColor);
                dc.fillCircle(x + 8, y + 14, 4);
                dc.fillCircle(x + 12, y + 16, 3);
                dc.fillCircle(x + 5, y + 16, 3);
                dc.fillRectangle(x + 5, y + 14, 10, 6);
                break;
            case 4:
                // Thunderstorm
                drawCloud(dc, x, y);
                dc.fillPolygon([[x + 10, y + 7], [x + 15, y + 7], [x + 11, y + 11], [x + 15, y + 11], [x + 6, y + 20], [x + 10, y + 13], [x + 7, y + 13], [x + 10, y + 7]]);
                break;
            case 5:
            case 6:
                // Sleet/Snow
                drawCloud(dc, x, y);
                dc.fillCircle(x + 9, y + 11, 2);
                dc.fillCircle(x + 13, y + 15, 2);
                dc.fillCircle(x + 7, y + 18, 2);
                break; 
            
        }
        dc.setPenWidth(1);
    }
    
    function drawCloud(dc, x, y) {
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        dc.fillCircle(x + 11, y + 6, 6);
        dc.fillCircle(x + 15, y + 9, 5);
        dc.fillCircle(x + 4, y + 9, 4);
        dc.setColor(fieldBackgroundColor, fieldBackgroundColor);
        dc.fillCircle(x + 11, y + 7, 5);
        dc.fillCircle(x + 14, y + 9, 4);
        dc.fillCircle(x + 5, y + 9, 3);
        dc.fillRectangle(x + 5, y + 8, 12, 7);
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
    }
    
    function drawCharacter(dc, char, x) {
        dc.setPenWidth(1);
        switch(char) {
            case M:
                dc.drawLine(168 + x, 218, 168 + x, 223);
                dc.drawLine(170 + x, 218, 170 + x, 223);
                dc.drawLine(172 + x, 218, 172 + x, 223);
                dc.drawLine(168 + x, 218, 172 + x, 218);
                break;
            case I:
                dc.drawLine(176, 218, 176, 223);
                break;
            case K:
                dc.drawLine(168, 215, 168, 223);
                dc.drawLine(168, 220, 172, 216);
                dc.drawLine(168, 219, 172, 223);
                break;
            case B:
                dc.drawLine(174, 215, 174, 223);
                dc.drawLine(177, 218, 177, 223);
                dc.drawLine(174, 218, 177, 218);
                dc.drawLine(174, 222, 177, 222);
                break;
            case C:
                dc.drawLine(173, 216, 169, 216);
                dc.drawLine(169, 216, 169, 223);
                dc.drawLine(173, 223, 168, 223);
                break;
            case F:
                dc.drawLine(173, 216, 169, 216);
                dc.drawLine(169, 216, 169, 223);
                dc.drawLine(172, 219, 168, 219);
                break;
            case T:
                dc.drawLine(177, 216, 177, 223);
                dc.drawLine(175, 216, 180, 216);
                break;    
        }
    }
    
    function drawTime(hourColor, minuteColor, font, dc) {
        var hh   = clockTime.hour;
        var hour = is24Hour ? hh : (hh == 12) ? hh : (hh % 12);
        var y = deviceName.equals("vivoactive3") ? 44 : 56;
        dc.setColor(hourColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX - 6, lcdFont ? 51 : y, font, hour.format(showLeadingZero ? "%02d" : "%01d"), Gfx.TEXT_JUSTIFY_RIGHT);
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, lcdFont ? 51 : y, font, ":", Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(minuteColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX + 6, lcdFont ? 51 : y, font, clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT);
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
    }

    function setBatteryColor(charge, dc) {
        if (charge > 80) {
            dc.setColor(Gfx.COLOR_DK_GREEN, upperBackgroundColor);
        } else if (charge > 50) {
            dc.setColor(Gfx.COLOR_GREEN, upperBackgroundColor);
        } else if (charge > 30) {
            dc.setColor(YELLOW, upperBackgroundColor);
        } else if (charge > 20) {
            dc.setColor(Gfx.COLOR_ORANGE, upperBackgroundColor);
        } else {
            dc.setColor(BRIGHT_RED, upperBackgroundColor);
        }
    }

    function getXYPositions(field) {
        var bmpX, bmpY, textX, textY, unitLcdX, unitLcdY, unitX, unitY;
        switch(field) {
            case 0: // UPPER LEFT
                bmpX     = 16;
                bmpY     = 157;
                textX    = 115;
                textY    = lcdFontDataFields ? 153 : 152;
                unitLcdX = 16;
                unitLcdY = 160;
                unitX    = 16;
                unitY    = 152;
                break;
            case 1: // UPPER RIGHT
                bmpX     = 207; 
                bmpY     = 157;
                textX    = lcdFontDataFields ? 126 : 124;
                textY    = lcdFontDataFields ? 153 : 152;
                unitLcdX = 224;
                unitLcdY = 160;
                unitX    = 220;
                unitY    = 152;
                break;
            case 2: // LOWER LEFT
                bmpX     = 36; 
                bmpY     = 187;
                textX    = 115;
                textY    = lcdFontDataFields ? 184 : 183;
                unitLcdX = 36;
                unitLcdY = 190;
                unitX    = 36;
                unitY    = 183;
                break;
            case 3: // LOWER RIGHT
                bmpX     = 187; 
                bmpY     = 187;
                textX    = lcdFontDataFields ? 126 : 124;
                textY    = lcdFontDataFields ? 184 : 183;
                unitLcdX = 204;
                unitLcdY = 190;
                unitX    = 198;
                unitY    = 183;
                break;
            case 4: // BOTTOM_FIELD
                bmpX     = 80;
                bmpY     = 216;
                textX    = lcdFontDataFields ? 104 : 108;
                textY    = lcdFontDataFields ? 215 : 213;
                unitLcdX = 0;
                unitLcdY = 0;
                unitX    = 0;
                unitY    = 0;
                break;
        }
        return [ bmpX, bmpY, textX, textY, unitLcdX, unitLcdY, unitX, unitY ];
    }

    function getActiveTimeText(isDay) {
        var actMinutes     = isDay ? actinfo.activeMinutesDay.total : actinfo.activeMinutesWeek.total;
        var activeHours    = (actMinutes / 60.0).toNumber();
        var activeMinutes  = (actMinutes % 60).toNumber();
        return Lang.format("$1$:$2$", [activeHours.format(showLeadingZero ? "%02d" : "%01d"), activeMinutes.format("%02d")]);
    }

    function getWeekOfYear(nowinfo) {
        var year          = nowinfo.year;
        var isLeapYear    = year % 4 == 0;
        var month         = nowinfo.month;
        var day           = nowinfo.day;
        var dayOfYear     = DAY_COUNT[month - 1] + day;
        var dayOfWeek     = nowinfo.day_of_week - 1;
        if (month > 0 && isLeapYear) { dayOfYear++; }
        if (0 == dayOfWeek) { dayOfWeek = 7; }        
        var kw            = 1 + 4 * (month - 1) + ( 2 * (month - 1) + day - 1 - dayOfWeek + 6 ) * 36 / 256;      
        var dayOfWeek0101 = getDayOfWeek(year, 1, 1);
        return kw.toNumber();
    }
    
    function getDayOfWeek(year, month, day) {
        var dayOfYear   = DAY_COUNT[month - 1] + day;
        var yearOrdinal = dayOfYear;
        var a = (year - 1901) % 28;
        var b = Math.floor(a / 4);
        var weekOrdinal = (2 + a + b) % 7 + 1;
        var dow = ((yearOrdinal - 1) + (weekOrdinal - 1)) % 7 + 1 - 1;
        if (0 == dow) { dow = 7; }        
        return dow;
    }
    
    function getActKcalAvg(actKcal) {
        var actKcalAvg = App.getApp().getProperty("ActKcalAvg");
        var sum   = 0.0;
        var count = 0.0;
        for (var i = 0 ; i < 6 ; i++) {
            sum += actKcalAvg[i];
            if (actKcalAvg[i] > 0) { count++; }
        }
        if (count > 0) {
            return (sum / count).toNumber();
        } else {
            return actKcal;
        }
    }
    
    function addActKcalToAverage(actKcal) {
        var actKcalAvg = App.getApp().getProperty("ActKcalAvg");
        for (var i = 0 ; i < 5 ; i++) {
            actKcalAvg[i] = actKcalAvg[i+1];
        }
        actKcalAvg[5] = actKcal < 0 ? 0 : actKcal;
        App.getApp().setProperty("ActKcalAvg", actKcalAvg);       
    }

    function calcSunriseSunset() {
        var sunrise     = App.getApp().getProperty("sunrise");
        var sunset      = App.getApp().getProperty("sunset");
        
        var sunriseHH   = Math.floor(sunrise).toNumber();
        var sunriseMM   = Math.floor((sunrise-Math.floor(sunrise))*60).toNumber();
        var sunriseAmPm = "";
        var sunsetHH    = Math.floor(sunset).toNumber();
        var sunsetMM    = Math.floor((sunset-Math.floor(sunset))*60).toNumber();
        var sunsetAmPm  = "";
        
        if (sunriseMM < 10) { sunriseMM = "0" + sunriseMM; }
        if (sunsetMM < 10) { sunsetMM = "0" + sunsetMM; }
        if (!is24Hour) {
            sunriseAmPm = sunriseHH < 12 ? "A" : "P";
            sunsetAmPm  = sunsetHH < 12 ? "A" : "P";
            sunriseHH   = sunriseHH == 0 ? sunriseHH : sunriseHH % 12;
            sunsetHH    = sunsetHH == 0 ? sunsetHH : sunsetHH % 12;
        }
        if (showLeadingZero) {
            sunriseText = Lang.format("$1$:$2$$3$", [sunriseHH.format("%02d"), sunriseMM, sunriseAmPm]);
            sunsetText  = Lang.format("$1$:$2$$3$", [sunsetHH.format("%02d"), sunsetMM, sunsetAmPm]);
        } else {
            sunriseText = Lang.format("$1$:$2$$3$", [sunriseHH, sunriseMM, sunriseAmPm]);
            sunsetText  = Lang.format("$1$:$2$$3$", [sunsetHH, sunsetMM, sunsetAmPm]);
        }
    }
    
    function updateLocation() {
        var location = Activity.getActivityInfo().currentLocation;
        if (null != location) {
            App.getApp().setProperty("UserLat", location.toDegrees()[0].toFloat());
            App.getApp().setProperty("UserLng", location.toDegrees()[1].toFloat());
        }
    }
    
    function clamp(min, max, value) {
            if (value < min) { return min; }
            if (value > max) { return max; }
            return value;
    }
    
    function getTextJustification(field) {
		var justification;

    	if (field == UPPER_LEFT || field == LOWER_LEFT) {
    		justification = Gfx.TEXT_JUSTIFY_RIGHT;
    	} else if (field == UPPER_RIGHT || field == LOWER_RIGHT) {
    		justification = Gfx.TEXT_JUSTIFY_LEFT;
    	} else {
    		justification = Gfx.TEXT_JUSTIFY_LEFT;
    	}
    	
    	return justification;
    }
    
    function getUnitJustification(field) {
		var justification;

    	if (field == UPPER_LEFT || field == LOWER_LEFT) {
    		justification = Gfx.TEXT_JUSTIFY_LEFT;
    	} else if (field == UPPER_RIGHT || field == LOWER_RIGHT) {
    		justification = Gfx.TEXT_JUSTIFY_RIGHT;
    	} else {
    		justification = Gfx.TEXT_JUSTIFY_CENTER;
    	}
    	
    	return justification;
    }

    function centerTextForBottomField(text, originXLoc, hasBitmap) {
    	var margin = 2;
    	var len = text.length();
    	
    	if (len == 1) {
    	
    		margin = 8;
    		
		} else if (len == 2) {
		
			margin = 2;
			
    	} else if (len == 4) {
    	
    		margin = hasBitmap ? 0 : -10;
    		
		} else if (len == 5) {
		
			margin = hasBitmap ? -4 : -4;
			
		} else if (len == 6) {
		
			margin = hasBitmap ? 0 : -20;
			
		} else if (len == 7) {
		
			margin = hasBitmap ? 0 : -25;
			
    	} else {
    	
    		margin = 2;
    		
    	}
    	
    	return originXLoc + margin;
    }
    
    function centerLcdTextForBottomField(text, originXLoc, hasBitmap) {
    	var margin = 2;
    	var len = text.length();
    	
    	if (len == 1) {
    	
    		margin = 10;
    		
		} else if (len == 2) {
		
			margin = 4;
			
    	} else if (len == 4) {
    	
    		margin = hasBitmap ? 0 : -10;
    		
		} else if (len == 5) {
			
			margin = hasBitmap ? -8 : -15;
			
		} else if (len == 6) {
		
			margin = hasBitmap ? 0 : -20;
			
		} else if (len == 7) {
		
			margin = hasBitmap ? 0 : -30;
			
    	} else {
    	
    		margin = 2;
    		
    	}
    	
    	return originXLoc + margin;
    }
}
