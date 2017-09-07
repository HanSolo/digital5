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

    enum { WOMAN, MEN }
    enum { UPPER_LEFT, UPPER_RIGHT, LOWER_LEFT, LOWER_RIGHT, BOTTOM_FIELD }
    enum { STEPS, CALORIES, ACTIVE_CALORIES, HEART_RATE, DISTANCE, ALTITUDE, PRESSURE, ACTIVE_TIME_TODAY, ACTIVE_TIME_WEEK, FLOORS, METERS, AVG_KCAL_AVG, DELTA_STEPS }    
    const DARK_RED      = 0x550000;
    const BRIGHT_BLUE   = 0x0055ff;
    const BRIGHT_GREEN  = 0x55ff00;
    const BRIGHT_RED    = 0xff0055;
    const YELLOW        = 0xffff00;
    const YELLOW_GREEN  = 0xaaff00;
    const GREEN_YELLOW  = 0x55ff55;
    
    const STEP_COLORS   = [ DARK_RED, Gfx.COLOR_DK_RED, Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_YELLOW, YELLOW, YELLOW_GREEN, GREEN_YELLOW, BRIGHT_GREEN, Gfx.COLOR_GREEN ];
    const LEVEL_COLORS  = [ Gfx.COLOR_GREEN, Gfx.COLOR_DK_GREEN, Gfx.COLOR_YELLOW, Gfx.COLOR_ORANGE, Gfx.COLOR_RED ];
    const DAY_COUNT     = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var weekdays        = new [7];
    var months          = new [12];
    var sunriseText     = "--:--";
    var sunsetText      = "--:--";
    var digitalUpright72, digitalUpright26, digitalUpright24, digitalUpright20, digitalUpright16;
    var mailIcon, mailIconBlack, alarmIcon, alarmIconBlack;
    var alertIcon, alertIconBlack;
    var bpmIcon, bpmIconWhite, burnedIcon, burnedIconWhite, stepsIcon, stepsIconWhite;
    var bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon, bpmMaxRedIcon, bpmMaxBlackIcon, bpmMaxWhiteIcon;
     
    var width, height;
    var centerX, centerY;        
    var midnightInfo;
    var nowinfo;
    var actinfo;
    var systemStats;        
    var hrHistory, hr;
    var steps, stepGoal, deltaSteps, stepsReached;
    var kcal;
    var bpm, showBpmZones, bpmZoneIcons, maxBpm, currentZone;
    var distanceUnit, distance;            
    var colorizeStepText;
    var colorizeCalorieText;
    var upperLeftField, upperRightField, lowerLeftField, lowerRightField, bottomField;
    var darkUpperBackground, upperBackgroundColor, upperForegroundColor;
    var darkFieldBackground, fieldBackgroundColor, fieldForegroundColor;
    var activeKcal, kcalReached;
      
    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        digitalUpright72 = Ui.loadResource(Rez.Fonts.digitalUpright72);
        digitalUpright26 = Ui.loadResource(Rez.Fonts.digitalUpright26);
        digitalUpright24 = Ui.loadResource(Rez.Fonts.digitalUpright24);
        digitalUpright20 = Ui.loadResource(Rez.Fonts.digitalUpright20);
        digitalUpright16 = Ui.loadResource(Rez.Fonts.digitalUpright16);
        alarmIcon        = Ui.loadResource(Rez.Drawables.alarm);
        alarmIconBlack   = Ui.loadResource(Rez.Drawables.alarmBlack);
        alertIcon        = Ui.loadResource(Rez.Drawables.alert);
        alertIconBlack   = Ui.loadResource(Rez.Drawables.alertBlack);
        mailIcon         = Ui.loadResource(Rez.Drawables.mail);
        mailIconBlack    = Ui.loadResource(Rez.Drawables.mailBlack);
        bpmIconWhite     = Ui.loadResource(Rez.Drawables.bpmWhite);
        bpmIcon          = Ui.loadResource(Rez.Drawables.bpm);
        bpm1Icon         = Ui.loadResource(Rez.Drawables.bpm1);
        bpm2Icon         = Ui.loadResource(Rez.Drawables.bpm2);
        bpm3Icon         = Ui.loadResource(Rez.Drawables.bpm3);
        bpm4Icon         = Ui.loadResource(Rez.Drawables.bpm4);
        bpm5Icon         = Ui.loadResource(Rez.Drawables.bpm5);
        bpmMaxRedIcon    = Ui.loadResource(Rez.Drawables.bpmMaxRed);
        bpmMaxBlackIcon  = Ui.loadResource(Rez.Drawables.bpmMaxBlack);
        bpmMaxWhiteIcon  = Ui.loadResource(Rez.Drawables.bpmMaxWhite);
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
        
        bpmZoneIcons              = [ bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon ];
 
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
        var charge                = systemStats.battery;
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
        distanceUnit              = Sys.getDeviceSettings().distanceUnits;
        distance                  = distanceUnit == 0 ? actinfo.distance * 0.00001 : actinfo.distance * 0.00001 * 0.621371;        
        var dayMonth              = App.getApp().getProperty("DateFormat") == 0;
        var dateFormat            = dayMonth ? "$1$.$2$" : "$2$/$1$";
        var monthAsText           = App.getApp().getProperty("MonthAsText");
        var showCalendarWeek      = App.getApp().getProperty("ShowCalendarWeek");        
        var showMoveBar           = App.getApp().getProperty("ShowMoveBar");
        var showStepBar           = App.getApp().getProperty("ShowStepBar");
        var showCalorieBar        = App.getApp().getProperty("ShowCalorieBar");
        var hourColor             = getColor(App.getApp().getProperty("HourColor"));
        var minuteColor           = getColor(App.getApp().getProperty("MinuteColor"));
        var coloredBattery        = App.getApp().getProperty("ColoredBattery");
        colorizeStepText          = App.getApp().getProperty("ColorizeStepText");
        colorizeCalorieText       = App.getApp().getProperty("ColorizeCalorieText");
        upperLeftField            = App.getApp().getProperty("UpperLeftField");
        upperRightField           = App.getApp().getProperty("UpperRightField");
        lowerLeftField            = App.getApp().getProperty("LowerLeftField");
        lowerRightField           = App.getApp().getProperty("LowerRightField");
        bottomField               = App.getApp().getProperty("BottomField");
        darkUpperBackground       = App.getApp().getProperty("DarkUpperBackground");
        upperBackgroundColor      = darkUpperBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
        upperForegroundColor      = darkUpperBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        darkFieldBackground       = App.getApp().getProperty("DarkFieldBackground");
        fieldBackgroundColor      = darkFieldBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
        fieldForegroundColor      = darkFieldBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        var showSunriseSunset     = App.getApp().getProperty("SunriseSunset");
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
        activeKcal        = (kcal - (kcalPerMinute * (clockTime.hour * 60.0 + clockTime.min))).toNumber();         // active kcal

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
        
        // Notification
        if (notificationCount > 0) { dc.drawBitmap(58, 18, darkUpperBackground ? mailIcon : mailIconBlack); }    
        
        // BLE
        if (connected) {
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawLine(86, 18, 93, 25);
            dc.drawLine(93, 25, 89, 29);
            dc.drawLine(89, 29, 89, 16);
            dc.drawLine(89, 16, 93, 20);
            dc.drawLine(93, 20, 85, 28);
        }
        
        // Battery
        dc.setColor(upperForegroundColor, upperBackgroundColor);        
        dc.drawRectangle(106, 18, 28, 11);
        dc.fillRectangle(134, 21, 2, 5);
        if (coloredBattery) {
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
        } else {
            dc.setColor(charge < 20 ? BRIGHT_RED : upperForegroundColor, upperBackgroundColor); 
        }
        dc.fillRectangle(108, 20 , 24.0 * charge / 100.0, 7);        
        if (showChargePercentage) {
            if (showPercentageUnder20) {
                if (charge <= 20) {
                    dc.setColor(upperForegroundColor, upperBackgroundColor);
                }
            } else {
                dc.setColor(upperForegroundColor, upperBackgroundColor);
            }
            dc.drawText(128, 0, digitalUpright16, charge.toNumber(), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawLine(129, 13, 135, 3);
            dc.drawRectangle(129, 4, 3, 3);
            dc.drawRectangle(132, 11, 3, 3);            
        }
        
        // Do not disturb
        if (System.getDeviceSettings().doNotDisturb) { 
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawCircle(153, 23, 7);
            dc.fillRectangle(150, 22, 7, 3);
        }
        
        // Alarm
        if (alarmCount > 0) { dc.drawBitmap(169, 18, darkUpperBackground ? alarmIcon : alarmIconBlack); }
                            
        // Sunrise/Sunset
        if (showSunriseSunset) {
            var sunriseHH = App.getApp().getProperty("sunriseHH");
            var sunriseMM = App.getApp().getProperty("sunriseMM");
            var sunsetHH  = App.getApp().getProperty("sunsetHH");
            var sunsetMM  = App.getApp().getProperty("sunsetMM");
            if (showLeadingZero) {
                sunriseText = null == sunriseHH ? "--:--" : (sunriseHH.format("%02d") + ":" + sunriseMM.format("%02d"));
                sunsetText  = null == sunsetHH ? "--:--" : (sunsetHH.format("%02d") + ":" + sunsetMM.format("%02d"));
            } else {
                sunriseText = null == sunriseHH ? "--:--" : (sunriseHH + ":" + sunriseMM);
                sunsetText  = null == sunsetHH ? "--:--" : (sunsetHH + ":" + sunsetMM);
            }
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.fillPolygon([[45, 50], [57, 50], [50, 44]]);    // upIcon
            dc.fillPolygon([[184, 44], [194, 44], [188, 49]]); // downIcon
            if (lcdFont) {
                dc.drawText(59, 36, digitalUpright16, sunriseText, Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(181, 36, digitalUpright16, sunsetText, Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(57, 28, Graphics.FONT_TINY, sunriseText, Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(182, 28, Graphics.FONT_TINY, sunsetText, Gfx.TEXT_JUSTIFY_RIGHT);
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
            dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : Gfx.COLOR_TRANSPARENT, upperBackgroundColor);
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
            for (var i = 0 ; i < 5 ; i++) { dc.fillRectangle(54 + (i * 27), 144, 25, 4); }
            if (moveBarLevel > Act.MOVE_BAR_LEVEL_MIN) { dc.setColor(LEVEL_COLORS[moveBarLevel - 1], upperBackgroundColor); }
            for (var i = 0 ; i < moveBarLevel ; i++) { dc.fillRectangle(54 + (i * 27), 144, 25, 4); }
            if (moveBarLevel == 5) { dc.drawBitmap(190, 141, darkUpperBackground ? alertIcon : alertIconBlack); }
        }
        
        
        // ******************** TIME ******************************************                

        // Time        
        
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
            var hour = clockTime.hour;
            var amPm = "am";
            if (hour > 12) {
                hour = clockTime.hour - 12;
                amPm = "pm";
            } else if (hour == 0) {
                hour = 12;              
            } else if (hour == 12) {                
                amPm = "pm";
            }         
            if (lcdFont) {   
                drawTime(hourColor, minuteColor, digitalUpright72, dc);
                dc.drawText(195, 93, digitalUpright20, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            } else {
                drawTime(hourColor, minuteColor, Graphics.FONT_NUMBER_HOT, dc);
                dc.drawText(191, 87, Graphics.FONT_TINY, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            }
        }     
        
        
        // ******************** DATE ******************************************
        
        // KW
        if (showCalendarWeek) {
            var calendarWeekText = Ui.loadResource(Rez.Strings.CalendarWeek);
            dc.drawText((lcdFont ? 43 : 50), (lcdFont ? 71 : 66), lcdFont ? digitalUpright20 : Graphics.FONT_TINY, (calendarWeekText), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText((lcdFont ? 43 : 50), (lcdFont ? 93 : 87), lcdFont ? digitalUpright20 : Graphics.FONT_TINY, (getWeekOfYear(nowinfo)), Gfx.TEXT_JUSTIFY_RIGHT);            
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
                        
            var weekdayText    = weekdays[homeDayOfWeek];
            var dateText       = dayMonth ?  nowinfo.day.format(showLeadingZero ? "%02d" : "%01d") + " " + months[homeMonth - 1] : months[homeMonth - 1] + " " + nowinfo.day.format(showLeadingZero ? "%02d" : "%01d");
            var dateNumberText = Lang.format(dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]);
            var timeText       = Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]);            
            dc.drawText(28, dateYPosition, lcdFont ? digitalUpright26 : Graphics.FONT_TINY, weekdayText + (monthAsText ? dateText : dateNumberText), Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(216, dateYPosition, lcdFont ? digitalUpright26 : Graphics.FONT_TINY, timeText, Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            var weekdayText    = weekdays[dayOfWeek - 1];            
            var dateText       = dayMonth ?  nowinfo.day.format(showLeadingZero ? "%02d" : "%01d") + " " + months[nowinfo.month - 1] : months[nowinfo.month - 1] + " " + nowinfo.day.format(showLeadingZero ? "%02d" : "%01d");
            var dateNumberText = Lang.format(dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]);
            dc.drawText(centerX, dateYPosition, lcdFont ? digitalUpright26 : Graphics.FONT_TINY, weekdayText + (monthAsText ? dateText : dateNumberText), Gfx.TEXT_JUSTIFY_CENTER);
        }
                

        // ******************** DATA FIELDS ***********************************
       
        // UpperLeft
        switch(upperLeftField) {
            case 0: drawSteps(getXYPositions(UPPER_LEFT), dc, false); break;
            case 1: drawCalories(getXYPositions(UPPER_LEFT), dc, false, UPPER_LEFT); break;
            case 2: drawCalories(getXYPositions(UPPER_LEFT), dc, true, UPPER_LEFT); break;
            case 3: drawHeartRate(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 4: drawDistance(getXYPositions(UPPER_LEFT), dc); break;
            case 5: drawWithUnit(getXYPositions(UPPER_LEFT), dc, ALTITUDE, UPPER_LEFT); break;
            case 6: drawWithUnit(getXYPositions(UPPER_LEFT), dc, PRESSURE, UPPER_LEFT); break;
            case 7: drawActiveTime(getXYPositions(UPPER_LEFT), dc, true, UPPER_LEFT); break;
            case 8: drawActiveTime(getXYPositions(UPPER_LEFT), dc, false, UPPER_LEFT); break;
            case 9: drawFloors(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 10: drawMeters(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 11: drawActKcalAvg(getXYPositions(UPPER_LEFT), dc, UPPER_LEFT); break;
            case 12: drawSteps(getXYPositions(UPPER_LEFT), dc, true); break;
        }
       
        // UpperRight
        switch(upperRightField) {
            case 0: drawSteps(getXYPositions(UPPER_RIGHT), dc, false); break;
            case 1: drawCalories(getXYPositions(UPPER_RIGHT), dc, false, UPPER_RIGHT); break;
            case 2: drawCalories(getXYPositions(UPPER_RIGHT), dc, true, UPPER_RIGHT); break;
            case 3: drawHeartRate(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 4: drawDistance(getXYPositions(UPPER_RIGHT), dc); break;
            case 5: drawWithUnit(getXYPositions(UPPER_RIGHT), dc, ALTITUDE, UPPER_RIGHT); break;
            case 6: drawWithUnit(getXYPositions(UPPER_RIGHT), dc, PRESSURE, UPPER_RIGHT); break;
            case 7: drawActiveTime(getXYPositions(UPPER_RIGHT), dc, true, UPPER_RIGHT); break;
            case 8: drawActiveTime(getXYPositions(UPPER_RIGHT), dc, false, UPPER_RIGHT); break;
            case 9: drawFloors(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 10: drawMeters(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 11: drawActKcalAvg(getXYPositions(UPPER_RIGHT), dc, UPPER_RIGHT); break;
            case 12: drawSteps(getXYPositions(UPPER_RIGHT), dc, true); break;
        }
       
        // LowerLeft
        switch(lowerLeftField) {
            case 0: drawSteps(getXYPositions(LOWER_LEFT), dc, false); break;
            case 1: drawCalories(getXYPositions(LOWER_LEFT), dc, false, LOWER_LEFT); break;
            case 2: drawCalories(getXYPositions(LOWER_LEFT), dc, true, LOWER_LEFT); break;
            case 3: drawHeartRate(getXYPositions(LOWER_LEFT), dc, LOWER_LEFT); break;
            case 4: drawDistance(getXYPositions(LOWER_LEFT), dc); break;
            case 7: drawActiveTime(getXYPositions(LOWER_LEFT), dc, true, LOWER_LEFT); break;
            case 8: drawActiveTime(getXYPositions(LOWER_LEFT), dc, false, LOWER_LEFT); break;
            case 9: drawFloors(getXYPositions(LOWER_LEFT), dc, LOWER_LEFT); break;
            case 12: drawSteps(getXYPositions(LOWER_LEFT), dc, true); break;
        }
       
        // LowerRight
        switch(lowerRightField) {
            case 0: drawSteps(getXYPositions(LOWER_RIGHT), dc, false); break;
            case 1: drawCalories(getXYPositions(LOWER_RIGHT), dc, false, LOWER_RIGHT); break;
            case 2: drawCalories(getXYPositions(LOWER_RIGHT), dc, true, LOWER_RIGHT); break;
            case 3: drawHeartRate(getXYPositions(LOWER_RIGHT), dc, LOWER_RIGHT); break;
            case 4: drawDistance(getXYPositions(LOWER_RIGHT), dc); break;
            case 7: drawActiveTime(getXYPositions(LOWER_RIGHT), dc, true, LOWER_RIGHT); break;
            case 8: drawActiveTime(getXYPositions(LOWER_RIGHT), dc, false, LOWER_RIGHT); break;
            case 9: drawFloors(getXYPositions(LOWER_RIGHT), dc, LOWER_RIGHT); break;
            case 12: drawSteps(getXYPositions(LOWER_RIGHT), dc, true); break;
        }

        // Bottom field
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        
        switch(bottomField) {
            case 1: drawCalories(getXYPositions(BOTTOM_FIELD), dc, false, BOTTOM_FIELD); break;
            case 2: drawCalories(getXYPositions(BOTTOM_FIELD), dc, true, BOTTOM_FIELD); break;
            case 3: drawHeartRate(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD); break;
            case 5: 
                drawWithUnit(getXYPositions(BOTTOM_FIELD), dc, ALTITUDE, BOTTOM_FIELD);
                dc.setPenWidth(1);
                // m
                dc.drawLine(168, 218, 168, 223);
                dc.drawLine(170, 218, 170, 223);
                dc.drawLine(172, 218, 172, 223);
                dc.drawLine(168, 218, 172, 218);
                break;
            case 6:
                drawWithUnit(getXYPositions(BOTTOM_FIELD), dc, PRESSURE, BOTTOM_FIELD);
                dc.setPenWidth(1);
                // m
                dc.drawLine(168, 218, 168, 223);
                dc.drawLine(170, 218, 170, 223);
                dc.drawLine(172, 218, 172, 223);
                dc.drawLine(168, 218, 172, 218);
                // b
                dc.drawLine(174, 215, 174, 223);
                dc.drawLine(177, 218, 177, 223);
                dc.drawLine(174, 218, 177, 218);
                dc.drawLine(174, 222, 177, 222);
                break;
            case 7: dc.drawText(120, 213, lcdFontDataFields ? digitalUpright20 : Graphics.FONT_TINY, getActiveTimeText(true), Gfx.TEXT_JUSTIFY_CENTER); break;
            case 8: dc.drawText(120, 213, lcdFontDataFields ? digitalUpright20 : Graphics.FONT_TINY, getActiveTimeText(false), Gfx.TEXT_JUSTIFY_CENTER); break;
            case 9:
                drawFloors(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD);
                dc.fillPolygon([[63, 221], [75, 221], [68, 215]]);    // upIcon
                dc.fillPolygon([[170, 216], [180, 216], [175, 221]]); // downIcon
                break;
            case 10:
                drawMeters(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD);
                dc.fillPolygon([[63, 221], [75, 221], [68, 215]]);    // upIcon
                dc.fillPolygon([[170, 216], [180, 216], [175, 221]]); // downIcon
                break;
            case 11:
                drawActKcalAvg(getXYPositions(BOTTOM_FIELD), dc, BOTTOM_FIELD);
                dc.setPenWidth(2);
                dc.drawCircle(69, 220, 4);
                dc.drawLine(65, 224, 74, 215);            
                break;
        }

        onPartialUpdate(dc);
    }
    
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
            dc.drawText((lcdFont ? 195 : 191), (lcdFont ? 93 : 87), lcdFont ? digitalUpright20 : Graphics.FONT_TINY, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            if (lcdFont) {                
                dc.fillRectangle(195, 75, 25, 15);
                dc.setClip(195, 75, 25, 15);
            } else {
                dc.fillRectangle(191, 74, 21, 17);
                dc.setClip(191, 74, 21, 17);
            }
            dc.setColor(upperForegroundColor, upperBackgroundColor);
            dc.drawText((lcdFont ? 195 : 191), (lcdFont ? 71 : 68), lcdFont ? digitalUpright20 : Graphics.FONT_TINY, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
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
        }
    }

    function drawSteps(xyPositions, dc, showDeltaSteps) {       
        var bmpX  = xyPositions[0];
        var bmpY  = xyPositions[1];
        var textX = xyPositions[2];
        var textY = xyPositions[3];
        
        dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? stepsIconWhite : stepsIcon);
        if (showDeltaSteps) {
            dc.setColor(deltaSteps > 0 ? BRIGHT_RED : Gfx.COLOR_BLACK, fieldBackgroundColor);
        } else {
            if (colorizeStepText) {
                stepsReached = stepsReached > 1.0 ? 1.0 : stepsReached;
                var endIndex = (10.0 * stepsReached).toNumber();
                dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : Gfx.COLOR_BLACK, fieldBackgroundColor);
            } else {
                dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            }
        }
        dc.drawText(textX, textY, lcdFontDataFields ? digitalUpright24 : Graphics.FONT_TINY, (showDeltaSteps ? deltaSteps * -1 : steps), Gfx.TEXT_JUSTIFY_RIGHT);
    }
    function drawCalories(xyPositions, dc, isActiveKcal, field) {
        var bmpX      = xyPositions[0];
        var bmpY      = xyPositions[1];
        var textX     = xyPositions[2];
        var textY     = xyPositions[3];
        var fieldText = isActiveKcal ? (activeKcal < 0 ? "0" : activeKcal.toString()) : kcal.toString();
        dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? burnedIconWhite : burnedIcon);
        if (isActiveKcal) {
            dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        } else {
            if (colorizeCalorieText) {
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
        }

        if (lcdFontDataFields) {
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, fieldText, Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, fieldText, Gfx.TEXT_JUSTIFY_RIGHT);
        }
    }
    function drawHeartRate(xyPositions, dc, field) {       
        var bmpX  = xyPositions[0];
        var bmpY  = xyPositions[1];
        var textX = xyPositions[2];
        var textY = xyPositions[3];
        if (bpm >= maxBpm) {
            dc.drawBitmap(bmpX, bmpY, showBpmZones ? bpmMaxRedIcon : darkFieldBackground ? bpmMaxWhiteIcon : bpmMaxBlackIcon);
        } else {
            dc.drawBitmap(bmpX, bmpY, showBpmZones ? bpmZoneIcons[currentZone - 1] : darkFieldBackground ? bpmIconWhite : bpmIcon);
        }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        }
    }
    function drawDistance(xyPositions, dc) {        
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
            dc.drawText(textX, textY, digitalUpright24, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(unitLcdX, unitLcdY, digitalUpright16, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(unitX, unitY, Graphics.FONT_TINY, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_LEFT);
        }
    }
    function drawWithUnit(xyPositions, dc, sensor, field) {        
        var textX      = xyPositions[2];
        var textY      = xyPositions[3];
        var unitLcdX   = xyPositions[4];
        var unitLcdY   = xyPositions[5];
        var unitX      = xyPositions[6];
        var unitY      = xyPositions[7];
        var fieldText;
        var unitText;
        switch(sensor) {
            case ALTITUDE:
                var altHistory = Sensor.getElevationHistory(null);        
                var altitude   = altHistory.next();
                fieldText = null == altitude ? "-" : altitude.data.format("%0.0f");
                unitText  = "m";
                break;
            case PRESSURE:
                var pressureHistory = Sensor.getPressureHistory(null);
                var pressure        = pressureHistory.next();
                fieldText = null == pressure ? "-" : (pressure.data.toDouble() / 100.0).format("%0.2f");
                unitText = "mb";
                break;
        }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, fieldText, Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(unitLcdX, unitLcdY, digitalUpright16, unitText, Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, fieldText, Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(unitX, unitY, Graphics.FONT_TINY, unitText, Gfx.TEXT_JUSTIFY_LEFT);
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
            case 0: break;
            case 1: textX -= lcdFontDataFields ? 76 : 72; horAlign = Gfx.TEXT_JUSTIFY_LEFT; break;
            case 2: break;
            case 3: textX -= lcdFontDataFields ? 55 : 51; horAlign = Gfx.TEXT_JUSTIFY_LEFT; break;
        }        
        var activeTimeText = getActiveTimeText(isDay);        
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, digitalUpright24, activeTimeText, horAlign);
            dc.drawText(unitLcdX, unitLcdY, digitalUpright16, isDay ? "D" : "W", Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, activeTimeText, horAlign);
            dc.drawText(unitX, unitY, Graphics.FONT_TINY, isDay ? "D" : "W", Gfx.TEXT_JUSTIFY_LEFT);
        }  
    }    
    function drawFloors(xyPositions, dc, field) {
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var horAlign = Gfx.TEXT_JUSTIFY_RIGHT;
        switch (field) {
            case 0: break;
            case 1: textX -= lcdFontDataFields ? 76 : 72; horAlign = Gfx.TEXT_JUSTIFY_LEFT; break;
            case 2: break;
            case 3: textX -= lcdFontDataFields ? 55 : 51; horAlign = Gfx.TEXT_JUSTIFY_LEFT; break;
            case 4: textX = 120; horAlign = Gfx.TEXT_JUSTIFY_CENTER; break;
        }
        var floorsClimbed   = actinfo.floorsClimbed;
        var floorsDescended = actinfo.floorsDescended;
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, (floorsClimbed.toString() + "/" + floorsDescended.toString()), horAlign);
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, (floorsClimbed.toString() + "/" + floorsDescended.toString()), horAlign);
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
        var horAlign        = Gfx.TEXT_JUSTIFY_RIGHT;
        if (field == 4) { textX = 120; horAlign = Gfx.TEXT_JUSTIFY_CENTER; }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, metersClimbed.toString() + "/" + metersDescended.toString(), horAlign);
            if (field < 4) { dc.drawText(unitLcdX, unitLcdY, digitalUpright16, "m", Gfx.TEXT_JUSTIFY_LEFT); }
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, metersClimbed.toString() + " / " + metersDescended.toString(), horAlign);
            if (field < 4) { dc.drawText(unitX, unitY, Graphics.FONT_TINY, "m", Gfx.TEXT_JUSTIFY_LEFT); }
        }
    }
    function drawActKcalAvg(xyPositions, dc, field) {
        var bmpX     = xyPositions[0];
        var bmpY     = xyPositions[1];
        var textX    = xyPositions[2];
        var textY    = xyPositions[3];
        var horAlign = Gfx.TEXT_JUSTIFY_RIGHT;
        if (field == 4) { 
            textX = 120; 
            horAlign = Gfx.TEXT_JUSTIFY_CENTER; 
        } else {
            dc.drawBitmap(bmpX, bmpY, darkFieldBackground ? burnedIconWhite : burnedIcon);
        }
        dc.setColor(fieldForegroundColor, fieldBackgroundColor);
        if (lcdFontDataFields) {
            dc.drawText(textX, textY, field < 4 ? digitalUpright24 : digitalUpright20, getActKcalAvg(activeKcal), horAlign);
        } else {
            dc.drawText(textX, textY, Graphics.FONT_TINY, getActKcalAvg(activeKcal), horAlign);
        }
    }

    function drawTime(hourColor, minuteColor, font, dc) {
        var hour = is24Hour ? clockTime.hour : clockTime.hour % 12;
        dc.setColor(hourColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX - 6, lcdFont ? 51 : 56, font, hour.format(showLeadingZero ? "%02d" : "%01d"), Gfx.TEXT_JUSTIFY_RIGHT);
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, lcdFont ? 51 : 56, font, ":", Gfx.TEXT_JUSTIFY_CENTER);
        dc.setColor(minuteColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX + 6, lcdFont ? 51 : 56, font, clockTime.min.format("%02d"), Gfx.TEXT_JUSTIFY_LEFT);
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
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
                textX    = lcdFontDataFields ? 202 : 196;
                textY    = lcdFontDataFields ? 153 : 152;
                unitLcdX = 207;
                unitLcdY = 160;
                unitX    = 200;
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
                textX    = lcdFontDataFields ? 181 : 175;
                textY    = lcdFontDataFields ? 184 : 183;
                unitLcdX = 187;
                unitLcdY = 190;
                unitX    = 180;
                unitY    = 183;
                break;
            case 4: // BOTTOM_FIELD
                bmpX     = 84;
                bmpY     = 216;
                textX    = 150;
                textY    = 213;
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

    function getColor(index) {      
        switch(index) {
            case 0: return Gfx.COLOR_WHITE;
            case 1: return Gfx.COLOR_BLACK;
            case 2: return Gfx.COLOR_RED;
            case 3: return Gfx.COLOR_DK_RED;
            case 4: return Gfx.COLOR_ORANGE;
            case 5: return Gfx.COLOR_YELLOW;
            case 6: return Gfx.COLOR_GREEN;
            case 7: return Gfx.COLOR_DK_GREEN;
            case 8: return Gfx.COLOR_BLUE;
            case 9: return Gfx.COLOR_DK_BLUE;
            case 10: return Gfx.COLOR_PURPLE;
            case 11: return Gfx.COLOR_PINK; 
        }
        return Gfx.COLOR_WHITE;
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
}
