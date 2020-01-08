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
    var lcdFont = false;	
    var lcdFontDataFields = false;
    var showLeadingZero;
    var clockTime;
    var sunRiseSet;

    enum { 
        WOMAN = 0, 
        MEN = 1
    }
    
    enum { 
        UPPER_LEFT = 0, 
        UPPER_RIGHT = 1, 
        LOWER_LEFT = 2, 
        LOWER_RIGHT = 3, 
        BOTTOM_FIELD = 4 
    }
    
    enum { 
        M = 0, 
        I = 1, 
        K = 2, 
        B = 3, 
        C = 4, 
        F = 5, 
        T = 6 
    }
    enum { 
        KCAL = 0, 
        ACTIVE_KCAL = 1, 
        ACTIVE_KCAL_REACHED = 2 
    }
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
    //var robotoCondensed72;
    var burnedIcon, burnedIconWhite, stepsIcon, stepsIconWhite;
    var alarmIcon, alarmIconWhite;
    var width, height;
    var centerX, centerY;
    var upperFieldHeightPercentage, fieldHeightPercentage;
    var dataFieldsTop, dataFieldsTopPadding;
    var fieldHeight;
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
    var batteryIconOffsetX;

    var coloredCalorieText;
    var upperLeftField, upperRightField, lowerLeftField, lowerRightField, bottomField;
    var darkUpperBackground, upperBackgroundColor, upperForegroundColor;
    var darkFieldBackground, fieldBackgroundColor, fieldForegroundColor;
    var apiKey;
    var secondsFont = 0;
    var secondsYPosition = 0;
    

    function initialize() {
        WatchFace.initialize();
        
        //reset weather data
        App.getApp().setProperty("dsResult", "");
        App.getApp().setProperty("temp", "");
        App.getApp().setProperty("minTemp", "");
        App.getApp().setProperty("maxTemp", "");

    }

    function onLayout(dc) {
        digitalUpright72 = Ui.loadResource(Rez.Fonts.digitalUpright72);
        digitalUpright26 = Ui.loadResource(Rez.Fonts.digitalUpright26);
        digitalUpright24 = Ui.loadResource(Rez.Fonts.digitalUpright24);
        digitalUpright20 = Ui.loadResource(Rez.Fonts.digitalUpright20);
        digitalUpright16 = Ui.loadResource(Rez.Fonts.digitalUpright16);
        //robotoCondensed72 = Ui.loadResource(Rez.Fonts.robotoCondensed72);
        burnedIcon = Ui.loadResource(Rez.Drawables.burned);
        burnedIconWhite = Ui.loadResource(Rez.Drawables.burnedWhite);
        stepsIcon = Ui.loadResource(Rez.Drawables.steps);
        stepsIconWhite = Ui.loadResource(Rez.Drawables.stepsWhite);
        weekdays[0] = Ui.loadResource(Rez.Strings.Sun);
        weekdays[1] = Ui.loadResource(Rez.Strings.Mon);
        weekdays[2] = Ui.loadResource(Rez.Strings.Tue);
        weekdays[3] = Ui.loadResource(Rez.Strings.Wed);
        weekdays[4] = Ui.loadResource(Rez.Strings.Thu);
        weekdays[5] = Ui.loadResource(Rez.Strings.Fri);
        weekdays[6] = Ui.loadResource(Rez.Strings.Sat);
        months[0] = Ui.loadResource(Rez.Strings.Jan);
        months[1] = Ui.loadResource(Rez.Strings.Feb);
        months[2] = Ui.loadResource(Rez.Strings.Mar);
        months[3] = Ui.loadResource(Rez.Strings.Apr);
        months[4] = Ui.loadResource(Rez.Strings.May);
        months[5] = Ui.loadResource(Rez.Strings.Jun);
        months[6] = Ui.loadResource(Rez.Strings.Jul);
        months[7] = Ui.loadResource(Rez.Strings.Aug);
        months[8] = Ui.loadResource(Rez.Strings.Sep);
        months[9] = Ui.loadResource(Rez.Strings.Oct);
        months[10] = Ui.loadResource(Rez.Strings.Nov);
        months[11] = Ui.loadResource(Rez.Strings.Dec);
        
        width = dc.getWidth();
        height = dc.getHeight();
        centerX = width * 0.5;
        centerY = height * 0.5;
        batteryIconOffsetX = 0;
        upperFieldHeightPercentage = 0.625;
        dataFieldsTop = height * upperFieldHeightPercentage;
        dataFieldsTopPadding = 7;
        fieldHeightPercentage = 0.125;
        fieldHeight = fieldHeightPercentage * height;
        
        distanceUnit  = Sys.getDeviceSettings().distanceUnits;
        
        Log("Digital5View.onLayout","width: " + width + ", height: " + height);
        
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
        
        dc.clearClip();

        is24Hour                  = Sys.getDeviceSettings().is24Hour;
        secondsAlwaysOn           = App.getApp().getProperty("SecondsAlwaysOn");
        //lcdFont                   = App.getApp().getProperty("LcdFont");	
        //lcdFontDataFields         = App.getApp().getProperty("LcdFontDataFields");
        showLeadingZero           = App.getApp().getProperty("ShowLeadingZero");
        tempUnit                  = App.getApp().getProperty("TempUnit");
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
        showBpmZones              = App.getApp().getProperty("BpmZones");

        clockTime                 = Sys.getClockTime();
        sunRiseSet                = new SunRiseSunSet();
        currentWeather            = App.getApp().getProperty("CurrentWeather");
        var showMoveBar           = App.getApp().getProperty("ShowMoveBar");

        // General
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
        distance                  = distanceUnit == 0 ? actinfo.distance * 0.00001 : actinfo.distance * 0.00001 * 0.621371;

        var lcdBackgroundVisible  = App.getApp().getProperty("LcdBackground");
        var profile               = UserProfile.getProfile();
        var dst                   = App.getApp().getProperty("DST");
        var timezoneOffset        = clockTime.timeZoneOffset;
        var showHomeTimezone      = App.getApp().getProperty("ShowHomeTimezone");
        var homeTimezoneOffset    = dst ? App.getApp().getProperty("HomeTimezoneOffset") + 3600 : App.getApp().getProperty("HomeTimezoneOffset");
        var onTravel              = (timezoneOffset != homeTimezoneOffset) && showHomeTimezone;
        var dayOfWeek             = nowinfo.day_of_week;
        var dayMonth              = App.getApp().getProperty("DateFormat") == 0;
        var dateFormat            = dayMonth ? "$1$.$2$" : "$2$/$1$";
        var monthAsText           = App.getApp().getProperty("MonthAsText");
        var showCalendarWeek      = App.getApp().getProperty("ShowCalendarWeek");
        var showStepBar           = App.getApp().getProperty("ShowStepBar");
        var showCalorieBar        = App.getApp().getProperty("ShowCalorieBar");
        var hourColor             = App.getApp().getProperty("HourColor").toNumber();
        var minuteColor           = App.getApp().getProperty("MinuteColor").toNumber();
        var showSunriseSunset     = App.getApp().getProperty("SunriseSunset");
        var activeKcalGoal        = App.getApp().getProperty("ActiveKcalGoal").toNumber();
        
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
        
        if (hourColor == upperBackgroundColor){
            hourColor = upperForegroundColor;
        }
        if (minuteColor == upperBackgroundColor){
            minuteColor = upperForegroundColor;
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
        dc.fillRectangle(0, 0, width, dataFieldsTop + 1);

        if (darkFieldBackground) {
            dc.setColor(fieldBackgroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, dataFieldsTop + 1, width, 3 * fieldHeight);

            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, dataFieldsTop + 1, width, 2); // top separator line
            dc.fillRectangle(0, dataFieldsTop + fieldHeight, width, 2); // middle separator line
            dc.fillRectangle(0, dataFieldsTop + 2 * fieldHeight, width, 2); // bottom separator line
            dc.fillRectangle(centerX - 1, dataFieldsTop + 1, 2, 2 * fieldHeight); // vertical separator line
        } else {
            dc.setColor(fieldBackgroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, dataFieldsTop + 1, width, 3 * fieldHeight);

            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, dataFieldsTop - 1, width, 2); // top separator line

            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, dataFieldsTop + 1, width, dataFieldsTop + 1); // top separator line
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, dataFieldsTop + 2, width, dataFieldsTop + 2); // top separator line shadow

            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, dataFieldsTop + fieldHeight - 1, width, 2); // middle separator line

            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, dataFieldsTop + fieldHeight + 1, width, dataFieldsTop + fieldHeight + 1); // middle separator line
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, dataFieldsTop + fieldHeight + 2, width, dataFieldsTop + fieldHeight + 2); // middle separator line shadow

            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, dataFieldsTop + 2 * fieldHeight, width, 2);

            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, dataFieldsTop + 2 * fieldHeight + 2, width, dataFieldsTop + 2 * fieldHeight + 2);
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.drawLine(0, dataFieldsTop + 2 * fieldHeight + 3, width, dataFieldsTop + 2 * fieldHeight + 3);

            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(centerX - 1, dataFieldsTop, 2, 2 * fieldHeight); // bottom field
        }    

        // draw Battery
        var biggerBatteryFont = App.getApp().getProperty("BiggerBatteryFont");
        var showChargePercentage = App.getApp().getProperty("ShowChargePercentage");
        var showPercentageUnder20 = App.getApp().getProperty("ShowPercentageUnder20");
        var charge = systemStats.battery + 0.5;
        var coloredBattery = App.getApp().getProperty("ColoredBattery");
        showChargePercentage = showChargePercentage || showPercentageUnder20 && charge < 20;
        
        Log("Digital5View.onUpdate","(draw battery) charge: " + charge + ", showPercentageUnder20: " + showPercentageUnder20 + ", showChargePercentage: " + showChargePercentage);

        if (showChargePercentage) {
            batteryIconOffsetX = 7;
            // Charge Text
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawText(centerX, 1, digitalUpright20, charge.toNumber(), Gfx.TEXT_JUSTIFY_CENTER);

            // Percentage Sign
            dc.drawLine(centerX + 20 - batteryIconOffsetX, 16, centerX + 28 - batteryIconOffsetX, 6);
            dc.drawRectangle(centerX + 20 - batteryIconOffsetX, 7, 3, 3);
            dc.drawRectangle(centerX + 26 - batteryIconOffsetX, 14, 3, 3);

            // Vertical Battery
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawRectangle(centerX - 27 + batteryIconOffsetX, 4, 8, 16);
            dc.fillRectangle(centerX - 25 + batteryIconOffsetX, 3, 4, 1);

            if (coloredBattery) {
                setBatteryColor(charge, dc);
            } else {
                dc.setColor(charge < 20 ? BRIGHT_RED : upperForegroundColor, upperBackgroundColor);
            }
            var chargeHeight = clamp(1, 12, 12.0 * charge / 100.0).toNumber();
            dc.fillRectangle(centerX - 25 + batteryIconOffsetX, clamp(6, 18, 18 - chargeHeight), 4, chargeHeight);
        } else {
            batteryIconOffsetX = 4;

            // Horizontal Battery
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawRectangle(centerX - 14, 8, 28, 11);
            dc.fillRectangle(centerX + 14, 11, 2, 5);
            if (coloredBattery) {
                setBatteryColor(charge, dc);
            } else {
                dc.setColor(charge < 20 ? BRIGHT_RED : upperForegroundColor, upperBackgroundColor);
            }
            dc.fillRectangle(centerX - 12, 10 , clamp (1, 24, 24.0 * charge / 100.0), 7);
        }    

        // draw notification
        var notificationCount = Sys.getDeviceSettings().notificationCount;
        if (notificationCount > 0) {
            var startX = centerX - 55 - batteryIconOffsetX;
            var startY = 18;
 
            Log("Digital5View.onUpdate","(draw notification) startX: " + startX + ", startY: " + startY + ", notificationCount: " + notificationCount);
 
            dc.setColor(darkUpperBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, upperBackgroundColor);
            dc.fillRectangle(startX, startY, 18, 11);
            dc.setColor(darkUpperBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE, upperBackgroundColor);
            dc.drawLine(startX + 1, startY, startX  + 9, startY + 8);
            dc.drawLine(startX + 16, startY, startX  + 8, startY + 8);
            dc.drawLine(startX, startY + 11, startX  + 6, startY + 5);
            dc.drawLine(startX + 17, startY + 11, startX  + 11, startY + 5);
        }

        // draw bluetooth
        var connected = Sys.getDeviceSettings().phoneConnected;  
        if (connected) {
            var startX = centerX - 30 - batteryIconOffsetX;
            var startY = 12;
            Log("Digital5View.onUpdate","(draw bluetooth) startX: " + startX + ", startY: " + startY + ", connected: " + connected);
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawLine(startX, startY, startX + 7, startY + 7);
            dc.drawLine(startX + 7, 19, startX + 3, startY + 11);
            dc.drawLine(startX + 3, 23, startX + 3, startY - 2);
            dc.drawLine(startX + 3, startY - 2, startX + 7, startY + 2);
            dc.drawLine(startX + 7, startY + 2, startX -1, startY + 10);
        }     
        
        // Draw Do not disturb
        dc.setColor(upperForegroundColor, upperBackgroundColor);
        if (System.getDeviceSettings().doNotDisturb) {
            var noDisturbX = centerX + 28 + batteryIconOffsetX;
            dc.drawCircle(noDisturbX, 17, 7);
            dc.fillRectangle(noDisturbX - 3, 16, 7, 3);
        }

        // Draw Alarm
        var alarmCount = Sys.getDeviceSettings().alarmCount;
        if (alarmCount > 0) {
            var alarmX = centerX + 42 + batteryIconOffsetX;
            dc.fillPolygon([[alarmX + 6, 17], [alarmX + 9, 21], [alarmX + 10, 25], [alarmX + 11, 26], [alarmX + 11, 27], [alarmX, 27], [alarmX, 26], [alarmX + 1, 25], [alarmX + 2, 21], [alarmX + 3, 19]]);
            dc.fillPolygon([[alarmX + 4, 28], [alarmX + 6, 30], [alarmX + 8, 28]]);
        }

        var arcRadius = centerX - 3;

        // Step Bar background
        if (showStepBar) {
            dc.setPenWidth(8);
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, upperBackgroundColor);
            for(var i = 0; i < 10 ; i++) {
                var startAngleLeft  = 130 + (i * 6);
                dc.drawArc(centerX, centerY, arcRadius, 0, startAngleLeft, startAngleLeft + 5);
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
                dc.drawArc(centerX, centerY, arcRadius, 0, startAngleLeft, startAngleLeft + 5);
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
                dc.drawArc(centerX, centerY, arcRadius, 0, startAngleRight, startAngleRight + 5);
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

        // draw Move Bar
        if (showMoveBar) {
            var moveBarLevel = actinfo.moveBarLevel;
           
            var moveBarLength = .75 * width;
            var moveBarLeft = (width - moveBarLength) / 2;
            var moveBarLeftPart = moveBarLength * 0.388888889;
            var moveBarRightStart = moveBarLeftPart + moveBarLeft + 2;
            var moveBarRightPart = moveBarLength * 0.138888889;
            var moveBarX = dataFieldsTop - 6;
            
            Log("Digital5View.onUpdate","(draw move bar) moveBarLength: " + moveBarLength + "moveBarLeft: " + moveBarLeft + "moveBarLeftPart: " + moveBarLeftPart + "moveBarRightStart: " + moveBarRightStart + "moveBarRightPart: " + moveBarRightPart + "moveBarX: " + moveBarX);
            
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, upperBackgroundColor);

            dc.fillRectangle(moveBarLeft, moveBarX, moveBarLeftPart, 4);
            for (var i = 0 ; i < 4 ; i++) { 
                dc.fillRectangle(moveBarRightStart + (i * (moveBarRightPart + 2)), moveBarX, moveBarRightPart, 4); 
            }
            
            if (moveBarLevel > Act.MOVE_BAR_LEVEL_MIN) { 
                dc.setColor(Gfx.COLOR_RED, upperBackgroundColor); 
            }
            
            dc.fillRectangle(moveBarLeft, moveBarX, moveBarLeftPart, 4);
            
            for (var i = 0 ; i < (moveBarLevel - 1) ; i++) {
                dc.fillRectangle(moveBarRightStart + (i * (moveBarRightPart + 2)), moveBarX, moveBarRightPart, 4); 
            }
        }
        
        // Date and home timezone
        dc.setColor(upperForegroundColor, upperBackgroundColor);
        var dateTimeFont = digitalUpright26;
        var dateTimefontSize = Graphics.getFontHeight(dateTimeFont);
        var dateYPosition = dataFieldsTop - 9  - dateTimefontSize;
        var dateXPosition = centerX - 99;
        var dateTimeText = calcHomeDateTime();

        // draw Time
        var timeFont = digitalUpright72 ;
        var timeFontSize = Graphics.getFontHeight(timeFont);
        var timeYPosition = dateYPosition - timeFontSize + 10;
        secondsFont = digitalUpright20;
        secondsYPosition = dateYPosition - Graphics.getFontHeight(secondsFont);
        
        if (lcdFont && lcdBackgroundVisible) {
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, upperBackgroundColor);
            if (showLeadingZero) {
                dc.drawText(centerX, timeYPosition, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                if (is24Hour) {
                    dc.drawText(centerX, timeYPosition, timeFont, clockTime.hour < 10 ? "8:88" : "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                } else {
                    dc.drawText(centerX, timeYPosition, timeFont, (clockTime.hour < 10 || clockTime.hour > 12) ? "8:88" : "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                }
            }
        }
        drawTime(hourColor, minuteColor, timeFont, dc, timeYPosition);


        // draw Date
        if (onTravel) {
            dc.drawText(dateXPosition, dateYPosition, dateTimeFont, dateTimeText[0], Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(width - dateXPosition, dateYPosition, dateTimeFont, dateTimeText[1], Gfx.TEXT_JUSTIFY_RIGHT);
        } 
        else {
            dc.drawText(centerX, dateYPosition, dateTimeFont, dateTimeText[0], Gfx.TEXT_JUSTIFY_CENTER);
        }


        // draw Calendar Week
        if (showCalendarWeek) {
            var calendarWeekText = Ui.loadResource(Rez.Strings.CalendarWeek);
            dc.drawText(centerX - 77, secondsYPosition - Graphics.getFontHeight(digitalUpright20), digitalUpright20, (calendarWeekText), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(centerX - 77, secondsYPosition, digitalUpright20, (getWeekOfYear(nowinfo)), Gfx.TEXT_JUSTIFY_RIGHT);
        }

        // draw Sunrise/Sunset
        if (showSunriseSunset) {
            var notificationsBottomY = 30;
            var sunRiseY = (timeYPosition - notificationsBottomY) / 2 + notificationsBottomY;
            calcSunriseSunset();
            drawArrow(dc, centerX - 70, sunRiseY, 0);
            drawArrow(dc, centerX + 60, sunRiseY, 1);
            dc.drawText(centerX - 50, sunRiseY - 5, digitalUpright16, sunriseText, Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(centerX + 55 , sunRiseY - 5, digitalUpright16, sunsetText, Gfx.TEXT_JUSTIFY_RIGHT);
        }


        // ******************** DATA FIELDS ***********************************

        var xyPositions = getXYPositions(UPPER_LEFT);
        // UpperLeft
        switch(upperLeftField) {
            case 0: drawSteps(xyPositions, dc, false, UPPER_LEFT); break;
            case 1: drawCalories(xyPositions, dc, KCAL, UPPER_LEFT); break;
            case 2: drawCalories(xyPositions, dc, ACTIVE_KCAL, UPPER_LEFT); break;
            case 3: drawHeartRate(xyPositions, dc, UPPER_LEFT); break;
            case 4: drawWithUnit(xyPositions, dc, 4, UPPER_LEFT); break;
            case 5: drawWithUnit(xyPositions, dc, 5, UPPER_LEFT); break;
            case 6: drawWithUnit(xyPositions, dc, 6, UPPER_LEFT); break;
            case 7: drawActiveTime(xyPositions, dc, true, UPPER_LEFT); break;
            case 8: drawActiveTime(xyPositions, dc, false, UPPER_LEFT); break;
            case 9: drawFloors(xyPositions, dc, UPPER_LEFT); break;
            case 10: drawMeters(xyPositions, dc, UPPER_LEFT); break;
            case 11: drawActKcalAvg(xyPositions, dc, UPPER_LEFT); break;
            case 12: drawSteps(xyPositions, dc, true); break;
            case 13: drawWithUnit(xyPositions, dc, 13, UPPER_LEFT); break;
            case 14: drawCalories(xyPositions, dc, ACTIVE_KCAL_REACHED, UPPER_LEFT); break;
        }

        xyPositions = getXYPositions(UPPER_RIGHT);
        // UpperRight
        switch(upperRightField) {
            case 0: drawSteps(xyPositions, dc, false, UPPER_LEFT); break;
            case 1: drawCalories(xyPositions, dc, KCAL, UPPER_RIGHT); break;
            case 2: drawCalories(xyPositions, dc, ACTIVE_KCAL, UPPER_RIGHT); break;
            case 3: drawHeartRate(xyPositions, dc, UPPER_RIGHT); break;
            case 4: drawWithUnit(xyPositions, dc, 4, UPPER_RIGHT); break;
            case 5: drawWithUnit(xyPositions, dc, 5, UPPER_RIGHT); break;
            case 6: drawWithUnit(xyPositions, dc, 6, UPPER_RIGHT); break;
            case 7: drawActiveTime(xyPositions, dc, true, UPPER_RIGHT); break;
            case 8: drawActiveTime(xyPositions, dc, false, UPPER_RIGHT); break;
            case 9: drawFloors(xyPositions, dc, UPPER_RIGHT); break;
            case 10: drawMeters(xyPositions, dc, UPPER_RIGHT); break;
            case 11: drawActKcalAvg(xyPositions, dc, UPPER_RIGHT); break;
            case 12: drawSteps(xyPositions, dc, true); break;
            case 13: drawWithUnit(xyPositions, dc, 13, UPPER_RIGHT); break;
            case 14: drawCalories(xyPositions, dc, ACTIVE_KCAL_REACHED, UPPER_RIGHT); break;
        }

        xyPositions = getXYPositions(LOWER_LEFT);
        // LowerLeft
        switch(lowerLeftField) {
            case 0: drawSteps(xyPositions, dc, false, UPPER_LEFT); break;
            case 1: drawCalories(xyPositions, dc, KCAL, LOWER_LEFT); break;
            case 2: drawCalories(xyPositions, dc, ACTIVE_KCAL, LOWER_LEFT); break;
            case 3: drawHeartRate(xyPositions, dc, LOWER_LEFT); break;
            case 4: drawWithUnit(xyPositions, dc, 4, LOWER_LEFT); break;
            case 6: drawWithUnit(xyPositions, dc, 6, LOWER_LEFT); break;
            case 7: drawActiveTime(xyPositions, dc, true, LOWER_LEFT); break;
            case 8: drawActiveTime(xyPositions, dc, false, LOWER_LEFT); break;
            case 9: drawFloors(xyPositions, dc, LOWER_LEFT); break;
            case 14: drawCalories(xyPositions, dc, ACTIVE_KCAL_REACHED, LOWER_LEFT); break;
        }

        xyPositions = getXYPositions(LOWER_RIGHT);
        // LowerRight
        switch(lowerRightField) {
            case 0: drawSteps(xyPositions, dc, false, UPPER_LEFT); break;
            case 1: drawCalories(xyPositions, dc, KCAL, LOWER_RIGHT); break;
            case 2: drawCalories(xyPositions, dc, ACTIVE_KCAL, LOWER_RIGHT); break;
            case 3: drawHeartRate(xyPositions, dc, LOWER_RIGHT); break;
            case 4: drawWithUnit(xyPositions, dc, 4, LOWER_RIGHT); break;
            case 6: drawWithUnit(xyPositions, dc, 6, LOWER_RIGHT); break;
            case 7: drawActiveTime(xyPositions, dc, true, LOWER_RIGHT); break;
            case 8: drawActiveTime(xyPositions, dc, false, LOWER_RIGHT); break;
            case 9: drawFloors(xyPositions, dc, LOWER_RIGHT); break;
            case 14: drawCalories(xyPositions, dc, ACTIVE_KCAL_REACHED, LOWER_RIGHT); break;
        }

        // Bottom field
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        xyPositions = getXYPositions(BOTTOM_FIELD);

        switch(bottomField) {
            case 0: drawSteps(xyPositions, dc, false, BOTTOM_FIELD); break;
            case 1: drawCalories(xyPositions, dc, KCAL, BOTTOM_FIELD); break;
            case 2: drawCalories(xyPositions, dc, ACTIVE_KCAL, BOTTOM_FIELD); break;
            case 3: drawHeartRate(xyPositions, dc, BOTTOM_FIELD); break;
            case 4: drawWithUnit(xyPositions, dc, 4, BOTTOM_FIELD); break;
            case 5: drawWithUnit(xyPositions, dc, 5, BOTTOM_FIELD); break;
            case 6: drawWithUnit(xyPositions, dc, 6, BOTTOM_FIELD); break;
            case 7: drawActiveTime(xyPositions, dc, true, BOTTOM_FIELD); break;
            case 8: drawActiveTime(xyPositions, dc, false, BOTTOM_FIELD); break;
            case 9: drawFloors(xyPositions, dc, BOTTOM_FIELD); break;
            case 10: drawMeters(xyPositions, dc, BOTTOM_FIELD); break;
            case 11:
                drawActKcalAvg(xyPositions, dc, BOTTOM_FIELD);
                dc.setPenWidth(2);
                dc.drawCircle(69, 220, 4);
                dc.drawLine(65, 224, 74, 215);
                break;
            case 13: drawWithUnit(xyPositions, dc, 13, BOTTOM_FIELD); break;
            case 14: drawCalories(xyPositions, dc, ACTIVE_KCAL_REACHED, BOTTOM_FIELD); break;
        }
        onPartialUpdate(dc);
        updateLocation();
    }

    // ******************** DRAWING FUNCTIONS *********************************

    function drawSeconds(dc) {
        var xBase = centerX + 70 + 3;
        var clockTime = Sys.getClockTime();
        dc.setColor(upperBackgroundColor, upperBackgroundColor);
        if (is24Hour) {
            dc.fillRectangle(xBase, secondsYPosition, 25, Graphics.getFontHeight(secondsFont));
            dc.setClip(xBase, secondsYPosition, 25, Graphics.getFontHeight(secondsFont));
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawText(xBase, secondsYPosition, secondsFont, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        } 
        else {
            dc.fillRectangle(xBase, secondsYPosition, 25, Graphics.getFontHeight(secondsFont));
            dc.setClip(xBase, secondsYPosition, 25, Graphics.getFontHeight(secondsFont));
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawText(xBase, secondsYPosition, secondsFont, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        }
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
        var coloredStepText = App.getApp().getProperty("ColorizeStepText");

        dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? stepsIconWhite : stepsIcon);
        if (showDeltaSteps) {
            dc.setColor(deltaSteps > 0 ? BRIGHT_RED : fieldForegroundColor, fieldBackgroundColor);
        } else {
            if (coloredStepText) {
                stepsReached = stepsReached > 1.0 ? 1.0 : stepsReached;
                var endIndex = (10.0 * stepsReached).toNumber();
                if (darkFieldBackground) {
                    dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : fieldForegroundColor, fieldBackgroundColor);
                } else {
                    dc.setColor(endIndex > 0 ? DARK_STEP_COLORS[endIndex - 1] : fieldForegroundColor, fieldBackgroundColor);
                }
            } else {
                dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            }
        }
        dc.drawText(textX, textY, GetFieldFont(field, false), (showDeltaSteps ? deltaSteps * -1 : steps), Gfx.TEXT_JUSTIFY_RIGHT);
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
        dc.drawText(field != BOTTOM_FIELD ? textX : textX + 13, textY, GetFieldFont(field, false), fieldText, Gfx.TEXT_JUSTIFY_RIGHT);
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
            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(bmpX + 10, bmpY + 5, 2, 5);
            dc.fillRectangle(bmpX + 10, bmpY + 12, 2, 2);
        }

         dc.setColor(fieldForegroundColor, fieldBackgroundColor);
         dc.drawText(textX, textY, GetFieldFont(field, false), (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);

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
                    if (distanceUnit == 0) {
                        fieldText = (altitude.data.toFloat() + altitudeOffset).format("%.0f");
                    } else {
                        fieldText = ((altitude.data.toFloat() + altitudeOffset) / 0.3048).format("%.0f");
                    }
                }
                unitText = distanceUnit == 0 ? "m" : "ft";
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
            
                    Log("Digital5View.drawWithUnit","(weather) - apiKey: " + apiKey);
            
                    if (field == BOTTOM_FIELD) { textX += 10; }
                    var icon = 7;
                    var dsResult = App.getApp().getProperty("dsResult");
                    Log("Digital5View.drawWithUnit","(weather) - dsResult: " + dsResult + ", length: " + dsResult.length());
                    
                    if (dsResult.length() == 0){
                        Log("Digital5View.drawWithUnit","(weather) - no results yet, displaying empty");
                    	fieldText = "----";
                    	unitText = "";
                    	break;
                    }
                    
                    if (!dsResult.equals("CURRENTLY") && !dsResult.equals("DAILY")){
                       Log("Digital5View.drawWithUnit","(weather) - displaying error");
                       fieldText = dsResult;
                       unitText = "";
                       break;
                    }


                    if (currentWeather) {
                        var temp = App.getApp().getProperty("temp");
                        Log("Digital5View.drawWithUnit","(weather) - temp: " + temp);
                       if (!(temp instanceof Toybox.Lang.Float)) {
                            Log("Digital5View.drawWithUnit","(weather) - no current data available, displaying empty");
                            fieldText = "----";
                            unitText = "";
                            break;
                        } else {
                            if (tempUnit == 1) { temp = temp * 1.8 + 32; }
                            icon = App.getApp().getProperty("icon");
                            var bmpX  = xyPositions[0];
                            var bmpY  = xyPositions[1];
                            fieldText = temp.format("%.1f");
                        }
                    } 
                    else {
                        var minTemp = App.getApp().getProperty("minTemp");
                        var maxTemp = App.getApp().getProperty("maxTemp");
                        Log("Digital5View.drawWithUnit","(weather) - minTemp: " + minTemp + ", maxTemp: " + maxTemp);
                        if (!(minTemp instanceof Toybox.Lang.Float)) {
                            Log("Digital5View.drawWithUnit","(weather) - no daily data available, displaying empty");
                            fieldText = "----";
                            unitText = "";
                            break;
                        } else {
                            if (tempUnit == 1) {
                                minTemp = minTemp * 1.8 + 32;
                                maxTemp = maxTemp * 1.8 + 32;
                            }
                            icon = App.getApp().getProperty("icon");
                            var bmpX  = xyPositions[0];
                            var bmpY  = xyPositions[1];
                            fieldText = minTemp.format("%.0f") + "/" + maxTemp.format("%.0f");
                        }
                    }
                    
                    Log("Digital5View.drawWithUnit","drawWithUnit (weather) - icon: " + icon );
                    
                    drawWeatherSymbol(field, icon, dc, xyPositions);
                } 
                else {
                    fieldText = "KEY";
                    unitText = "";
                    break;
                }
                unitText = tempUnit == 0 ? "C" : "F";
                break;
        }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        dc.drawText(textX, textY, GetFieldFont(field, false), fieldText, Gfx.TEXT_JUSTIFY_RIGHT);
        drawUnitText(xyPositions, dc, unitText, field);
    }
    
    function drawUnitText(xyPositions, dc, unitText, field){
        var unitLcdX = xyPositions[4];
        var unitLcdY = xyPositions[5];
        var unitX    = xyPositions[6];
        var unitY    = xyPositions[7];
        Log("Digital5View.drawUnitText", "unitText: " + unitText + ", field: " + field);
        if (field == BOTTOM_FIELD){
            switch(unitText.toLower()){
            case "km":
                drawCharacter(xyPositions, dc, K, 0);
                drawCharacter(xyPositions, dc, M, 6);
                break;
            case "mi":
                drawCharacter(xyPositions, dc, M, 0);
                drawCharacter(xyPositions, dc, I, 0);
                break;
            case "m":
                drawCharacter(xyPositions, dc, M, -5);
                break;
            case "ft":
                drawCharacter(xyPositions, dc, F, 0);
                drawCharacter(xyPositions, dc, T, 0);
                break;
            case "mb":
                drawCharacter(xyPositions, dc, M, 0);
                drawCharacter(xyPositions, dc, B, 0);
                break;
            case "c":
                drawCharacter(xyPositions, dc, C, 6);
                break;
            case "f":
                drawCharacter(xyPositions, dc, F, 6);
                break;
            }          
            return;
        }
        
        dc.drawText(unitLcdX, unitLcdY, GetFieldFont(field, true), unitText, Gfx.TEXT_JUSTIFY_LEFT);
    }

    function drawCharacter(xyPositions,dc, char, x) {
        dc.setPenWidth(1);
        var bmpX = xyPositions[0] + 84 + x;
        var bmpY = xyPositions[1];
        switch(char) {
            case M:
                dc.drawLine(bmpX - 1, bmpY + 2, bmpX - 1, bmpY + 7);
                dc.drawLine(bmpX + 1, bmpY + 2, bmpX + 1, bmpY + 7);
                dc.drawLine(bmpX + 3, bmpY + 2, bmpX + 3, bmpY + 7);
                dc.drawLine(bmpX - 1, bmpY + 2, bmpX + 3, bmpY + 2);
                break;
            case I:
                dc.drawLine(bmpX + 7, bmpY + 2, bmpX + 7, bmpY + 7);
                break;
            case K:
                dc.drawLine(bmpX - 1, bmpY - 1, bmpX - 1, bmpY + 7);
                dc.drawLine(bmpX - 1, bmpY + 4, bmpX + 3, bmpY);
                dc.drawLine(bmpX - 1, bmpY + 3, bmpX + 3, bmpY + 7);
                break;
            case B:
                dc.drawLine(bmpX + 5, bmpY - 1, bmpX + 5, bmpY + 7);
                dc.drawLine(bmpX + 8, bmpY + 2, bmpX + 8, bmpY + 7);
                dc.drawLine(bmpX + 5, bmpY + 2, bmpX + 8, bmpY + 2);
                dc.drawLine(bmpX + 5, bmpY + 6, bmpX + 8, bmpY + 6);
                break;
            case C:
                dc.drawLine(bmpX + 4, bmpY, bmpX, bmpY);
                dc.drawLine(bmpX, bmpY, bmpX, bmpY + 8);
                dc.drawLine(bmpX + 4, bmpY + 7, bmpX, bmpY + 7);
                break;
            case F:
                dc.drawLine(bmpX + 4, bmpY, bmpX, bmpY);
                dc.drawLine(bmpX, bmpY, bmpX, bmpY + 8);
                dc.drawLine(bmpX + 3, bmpY + 3, bmpX - 1, bmpY + 3);
                break;
            case T:
                dc.drawLine(bmpX + 8, bmpY, bmpX + 8, bmpY + 7);
                dc.drawLine(bmpX + 6, bmpY, bmpX + 11, bmpY);
                break;
        }
    }
    
    function drawActiveTime(xyPositions, dc, isDay, field) {
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var unitLcdX = xyPositions[4];
        var unitLcdY = xyPositions[5];
        var unitX    = xyPositions[6];
        var unitY    = xyPositions[7];
        var horAlign = Gfx.TEXT_JUSTIFY_RIGHT;
        
        switch (field) {
            case UPPER_RIGHT: textX -= 76; horAlign = Gfx.TEXT_JUSTIFY_LEFT; break;
        }
        var activeTimeText = getActiveTimeText(isDay);
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        dc.drawText(textX, textY, GetFieldFont(field, false), activeTimeText, horAlign);
        drawUnitText(xyPositions, dc, isDay ? "D" : "W", field);

    }
    function drawFloors(xyPositions, dc, field) {
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var horAlign = Gfx.TEXT_JUSTIFY_RIGHT;
        switch (field) {
            case UPPER_RIGHT: bmpX +=2; textX +=  8; break;
            case LOWER_RIGHT: bmpX +=2; textX +=  8; break;
            case BOTTOM_FIELD: textX = 120; horAlign = Gfx.TEXT_JUSTIFY_CENTER; break;
        }
        var floorsClimbed   = actinfo.floorsClimbed;
        var floorsDescended = actinfo.floorsDescended;
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        // draw stairs icon
        if (field == BOTTOM_FIELD) 
        {
             drawArrow(dc, bmpX, bmpY, 0);
             drawArrow(dc, .66 * width, bmpY, 1);
             horAlign = Gfx.TEXT_JUSTIFY_CENTER;
             textX = centerX;
        }
        else {
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
        dc.drawText(textX, textY, GetFieldFont(field, false), (floorsClimbed.toString() + "/" + floorsDescended.toString()), horAlign);
    }
    
    function drawMeters(xyPositions, dc, field) {
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX           = xyPositions[2];
        var textY           = xyPositions[3];
        var unitLcdX        = xyPositions[4];
        var unitLcdY        = xyPositions[5];
        var unitX           = xyPositions[6];
        var unitY           = xyPositions[7];
        var metersClimbed   = actinfo.metersClimbed.format("%0d");
        var metersDescended = actinfo.metersDescended.format("%0d");
        var horAlign        = Gfx.TEXT_JUSTIFY_RIGHT;
        if (field == BOTTOM_FIELD) { textX = 120; horAlign = Gfx.TEXT_JUSTIFY_CENTER; }
        switch (field) {
            case UPPER_RIGHT: 
                unitLcdX += 8; 
                unitX += 4; 
                textX += 8; 
                break; 
            case LOWER_RIGHT: 
                unitLcdX += 8; 
                unitX += 4; 
                textX += 8; 
                break; 
            case BOTTOM_FIELD: 
                textX = width /2; 
                horAlign = Gfx.TEXT_JUSTIFY_CENTER; 
                break;
        }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        dc.drawText(textX, textY, GetFieldFont(field, false), metersClimbed.toString() + "/" + metersDescended.toString(), horAlign);
        drawUnitText(xyPositions, dc, "m", field);
        
        if (field == BOTTOM_FIELD){
            drawArrow(dc, bmpX, bmpY, 0);
             drawArrow(dc, width - bmpX, bmpY, 1);
        }
    }
    
    function drawArrow(dc, x, y, direction){
        
        var horSize = 12;
        var vertSize = 6;
        if (direction == 0){
            dc.fillPolygon([[x, y + vertSize ], [x + horSize, y + vertSize], [x + horSize / 2, y]]); //(left bottom , right bottom , top)
            return;
        }
        dc.fillPolygon([[x, y], [x + horSize, y], [x + horSize / 2, y + vertSize]]); //(left top  , right top , bottom)
        
    }
    
    function drawActKcalAvg(xyPositions, dc, field) {
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var horAlign = Gfx.TEXT_JUSTIFY_RIGHT;
        if (field == BOTTOM_FIELD) {
            textX = 120;
            horAlign = Gfx.TEXT_JUSTIFY_CENTER;
        } else {
            dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? burnedIconWhite : burnedIcon);
        }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        dc.drawText(textX, textY, GetFieldFont(field, false), getActKcalAvg(activeKcal), horAlign);
    }
    
    function drawWeatherSymbol(field, icon, dc, xyPositions) {
        var x = xyPositions[0];
        var y = xyPositions[1];

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

    function drawTime(hourColor, minuteColor, font, dc, timeYPosition) {
        var hh   = clockTime.hour;
        var hour = is24Hour ? hh : (hh == 12) ? hh : (hh % 12 == 0 ? 12 : hh % 12);
        
        dc.setColor(hourColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX - 6, timeYPosition, font, hour.format(showLeadingZero ? "%02d" : "%01d"), Gfx.TEXT_JUSTIFY_RIGHT);
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, timeYPosition, font, ":", Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(minuteColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX + 6, timeYPosition, font, clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT);
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
        
        if (!is24Hour) {
        	var xBase = centerX + 70 + 3;
        	var yBase = secondsYPosition;
        	if (secondsAlwaysOn) {
        	    yBase = yBase - Graphics.getFontHeight(digitalUpright20);
        	}
            var amPm = clockTime.hour < 12 ? "am" : "pm";
            dc.drawText(xBase, yBase, digitalUpright20, amPm, Gfx.TEXT_JUSTIFY_LEFT);
        }
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
        
        var font = GetFieldFont(field, false);
        var fontSize = Graphics.getFontHeight(font);
        var textYPadding = (fieldHeight - fontSize)/2;
        switch (field) {
            case UPPER_LEFT: // UPPER LEFT
                bmpX     = 0.06667 * width;
                bmpY     = dataFieldsTop + dataFieldsTopPadding;
                textX    = centerX - 5;
                textY    = dataFieldsTop + textYPadding;
                unitLcdX = 16;
                unitLcdY = dataFieldsTop + 10;
                unitX    = 16;
                unitY    = dataFieldsTop + 2;
                break;
            case UPPER_RIGHT: // UPPER RIGHT
                bmpX     = width - 33;
                bmpY     = dataFieldsTop + dataFieldsTopPadding;
                textX    = width - 38;
                textY    = dataFieldsTop + textYPadding;
                unitLcdX = width - 33;
                unitLcdY = dataFieldsTop + 10;
                unitX    = width - 40;
                unitY    = dataFieldsTop + 2;
                break;
            case LOWER_LEFT: // LOWER LEFT
                bmpX     = 0.15 * width;
                bmpY     = dataFieldsTop + fieldHeight + dataFieldsTopPadding;
                textX    = centerX - 5;
                textY    = dataFieldsTop + fieldHeight + textYPadding;
                unitLcdX = 36;
                unitLcdY = dataFieldsTop + fieldHeight + 10;
                unitX    = 36;
                unitY    = dataFieldsTop + fieldHeight + 3;
                break;
            case LOWER_RIGHT: // LOWER RIGHT
                bmpX     = width - 53;
                bmpY     = dataFieldsTop + fieldHeight + dataFieldsTopPadding;
                textX    = width - 59;
                textY    = dataFieldsTop + fieldHeight + textYPadding;
                unitLcdX = width - 53;
                unitLcdY = dataFieldsTop + fieldHeight + 10;
                unitX    = width - 60;
                unitY    = dataFieldsTop + fieldHeight + 3;
                break;
            case BOTTOM_FIELD: // BOTTOM_FIELD
                bmpX     = 0.33 * width;
                bmpY     = dataFieldsTop + 2 * fieldHeight + dataFieldsTopPadding;
                textX    = centerX + 30;
                textY    = dataFieldsTop + 2 * fieldHeight + textYPadding + 1;
                unitLcdX = width - 83;
                unitLcdY = dataFieldsTop + 2 * fieldHeight + 10;
                unitX    = width - 90;
                unitY    = dataFieldsTop + 2 * fieldHeight + 3;
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
    
    function GetFieldFont(fieldNumber, isUnitText) {
        var tinyFont = Graphics.FONT_XTINY;

        if (width > 240 and !isUnitText){
            tinyFont = Graphics.FONT_TINY;
        }
    
       if (fieldNumber == BOTTOM_FIELD) {
             if (isUnitText){
                return Graphics.FONT_XTINY;
             }
             return digitalUpright20;
       }

       if (isUnitText){
             return digitalUpright16;
       }
       return digitalUpright24;
    }
    
    /// <summary>
    /// Get the home date  and time, both time zone dependent. Depending on settings we may return the current date, and an empty time
    /// </summary>
    /// <returns>array that contains Date and Time</returns>
    function calcHomeDateTime(){
        var dst  = App.getApp().getProperty("DST");
        var dayOfWeek = nowinfo.day_of_week;
        var dayMonth = App.getApp().getProperty("DateFormat") == 0;
        var dateFormat = dayMonth ? "$1$.$2$" : "$2$/$1$";
        var monthAsText = App.getApp().getProperty("MonthAsText");
        var timezoneOffset = clockTime.timeZoneOffset;
        var showHomeTimezone = App.getApp().getProperty("ShowHomeTimezone");
        var showHomeDate = App.getApp().getProperty("ShowHomeDate");
        var homeTimezoneOffset = dst ? App.getApp().getProperty("HomeTimezoneOffset") + 3600 : App.getApp().getProperty("HomeTimezoneOffset");
        var onTravel = timezoneOffset != homeTimezoneOffset;
        
        var monthText = "";
        var timeText = "";
        var currentWeekdayText    = weekdays[dayOfWeek - 1];
        var currentDateText       = dayMonth ?  nowinfo.day.format(showLeadingZero ? "%02d" : "%01d") + " " + months[nowinfo.month - 1] : months[nowinfo.month - 1] + " " + nowinfo.day.format(showLeadingZero ? "%02d" : "%01d");
        var currentDateNumberText = Lang.format(dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]);
        monthText = currentWeekdayText + (monthAsText ? currentDateText : currentDateNumberText);
        
        if (!onTravel) {
            // if we are not traveling, just show the current date, time will be empty
            return [monthText, timeText];
        }

        if (showHomeTimezone || showHomeDate){
            // we are traveling. If we are showing either home Time or home Date, we need to calculate this
            var currentSeconds = clockTime.hour * 3600 + clockTime.min * 60 + clockTime.sec;
            var utcSeconds     = currentSeconds - clockTime.timeZoneOffset;
        
            var homeDayOfWeek  = dayOfWeek - 1;
            var homeDay        = nowinfo.day;
            var homeMonth      = nowinfo.month;
            var homeSeconds    = utcSeconds + homeTimezoneOffset;
            if (dst) { 
                homeSeconds = homeTimezoneOffset > 0 ? homeSeconds : homeSeconds - 3600; 
            }
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
            
            if (showHomeDate) {
                // if we want to show the home date, we need to calculate it
                var homeWeekdayText    = weekdays[homeDayOfWeek];
                var homeDateText       = dayMonth ?  
                    homeDay.format(showLeadingZero ? "%02d" : "%01d") + " " + months[homeMonth - 1] : 
                      months[homeMonth - 1] + " " + homeDay.format(showLeadingZero ? "%02d" : "%01d");
                var homeDateNumberText = Lang.format(dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]);
                monthText =  homeWeekdayText + (monthAsText ? homeDateText : homeDateNumberText);
            }

            timeText = Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]) + ampm;
        }


        return [monthText, timeText];
    }
    
    //function Log(method, message){
   // 	if ($.debug){
   // 	
   //       var myTime = System.getClockTime(); 
   //       var myTimeString = myTime.hour.format("%02d") + ":" + myTime.min.format("%02d") + ":" + myTime.sec.format("%02d");
   //       if ($.debug) {System.println(myTimeString + " | " + method + " | " + message);}
   //     }
   // }
}
