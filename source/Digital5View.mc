using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.ActivityMonitor as Act;
//using Toybox.SensorHistory as Sensor;
using Toybox.Attention as Att;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Greg;
using Toybox.Application as App;
using Toybox.UserProfile as UserProfile;
using Toybox.Ant as Ant;
using Toybox.Timer as Timer;

var timer;
var showSeconds;

class Digital5View extends Ui.WatchFace {
enum { WOMAN, MEN }
    const BRIGHT_BLUE  = 0x0055ff;
    const BRIGHT_GREEN = 0x55ff00;
    const DARK_RED     = 0xaa0000;
    const BRIGHT_RED   = 0xff0055;
    const DARK_ORANGE  = 0xff5500;
    const ORANGE       = 0xffaa00;
    const YELLOW_GREEN = 0xaaff00;
    
    const STEP_COLORS  = [ DARK_RED, Gfx.COLOR_RED, DARK_ORANGE, ORANGE, Gfx.COLOR_YELLOW, Gfx.COLOR_YELLOW, YELLOW_GREEN, YELLOW_GREEN, Gfx.COLOR_GREEN, BRIGHT_GREEN ];
    const LEVEL_COLORS = [ Gfx.COLOR_GREEN, Gfx.COLOR_DK_GREEN, Gfx.COLOR_YELLOW, Gfx.COLOR_ORANGE, Gfx.COLOR_RED ];
    var weekdays       = new [7];
    var timeFont, dateFont, valueFont, distanceFont, sunFont;
    var timeFontAnalog, valueFontAnalog, distanceFontAnalog;    
    var chargeFont;
    var bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon, bpmMaxRedIcon, bpmMaxBlackIcon;
    var alarmIcon, alertIcon, batteryIcon, bleIcon, bpmIcon, burnedIcon, mailIcon, stepsIcon;    
    var heartRate;    
      
    function initialize() {
        timer       = new Timer.Timer();
        showSeconds = false;
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        timeFont           = Ui.loadResource(Rez.Fonts.digitalUpright72);
        dateFont           = Ui.loadResource(Rez.Fonts.digitalUpright26);
        valueFont          = Ui.loadResource(Rez.Fonts.digitalUpright24);
        distanceFont       = Ui.loadResource(Rez.Fonts.digitalUpright16);
        timeFontAnalog     = Ui.loadResource(Rez.Fonts.analog60);        
        valueFontAnalog    = Ui.loadResource(Rez.Fonts.analog22);
        distanceFontAnalog = Ui.loadResource(Rez.Fonts.analog14);
        chargeFont         = Ui.loadResource(Rez.Fonts.droidSansMono12);        
        alarmIcon          = Ui.loadResource(Rez.Drawables.alarm);
        alertIcon          = Ui.loadResource(Rez.Drawables.alert);
        batteryIcon        = Ui.loadResource(Rez.Drawables.battery);
        bleIcon            = Ui.loadResource(Rez.Drawables.ble);
        bpmIcon            = Ui.loadResource(Rez.Drawables.bpm);
        bpm1Icon           = Ui.loadResource(Rez.Drawables.bpm1);
        bpm2Icon           = Ui.loadResource(Rez.Drawables.bpm2);
        bpm3Icon           = Ui.loadResource(Rez.Drawables.bpm3);
        bpm4Icon           = Ui.loadResource(Rez.Drawables.bpm4);
        bpm5Icon           = Ui.loadResource(Rez.Drawables.bpm5);
        bpmMaxRedIcon      = Ui.loadResource(Rez.Drawables.bpmMaxRed);
        bpmMaxBlackIcon    = Ui.loadResource(Rez.Drawables.bpmMaxBlack);
        burnedIcon         = Ui.loadResource(Rez.Drawables.burned);
        mailIcon           = Ui.loadResource(Rez.Drawables.mail);
        stepsIcon          = Ui.loadResource(Rez.Drawables.steps);        
        weekdays[0]        = Ui.loadResource(Rez.Strings.Sun);
        weekdays[1]        = Ui.loadResource(Rez.Strings.Mon);
        weekdays[2]        = Ui.loadResource(Rez.Strings.Tue);
        weekdays[3]        = Ui.loadResource(Rez.Strings.Wed);
        weekdays[4]        = Ui.loadResource(Rez.Strings.Thu);
        weekdays[5]        = Ui.loadResource(Rez.Strings.Fri);
        weekdays[6]        = Ui.loadResource(Rez.Strings.Sat);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {        
        View.onUpdate(dc);
                
        var bpmZoneIcons          = [ bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon ];
 
        // General
        var width                 = dc.getWidth();
        var height                = dc.getHeight();
        var centerX               = width * 0.5;
        var centerY               = height * 0.5;
        var clockTime             = Sys.getClockTime();
        var midnightInfo          = Greg.info(Time.today(), Time.FORMAT_SHORT);
        var nowinfo               = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var actinfo               = Act.getInfo();
        var systemStats           = Sys.getSystemStats();
        var is24Hour              = Sys.getDeviceSettings().is24Hour;
        var hrHistory             = Act.getHeartRateHistory(null, true);
        var hr                    = hrHistory.next();
        //var altHistory            = Sensor.getElevationHistory(null, true);
        //var altitude              = altHistory.next();
        //var pressureHistory       = Sensor.getPressureHistory(null, true);
        //var pressure              = pressureHistory.next();
        var steps                 = actinfo.steps;
        var stepGoal              = actinfo.stepGoal;
        var actMinutes            = actinfo.activeMinutesDay.total;
        var activeHours           = (actMinutes / 60.0).toNumber();
        var activeMinutes         = (actMinutes % 60).toNumber();
        var deltaSteps            = stepGoal - steps;
        var stepsReached          = steps.toDouble() / stepGoal;        
        var kcal                  = actinfo.calories;        
        var showActiveKcalOnly    = Application.getApp().getProperty("ShowActiveKcalOnly");
        var bpm                   = (hr.heartRate != Act.INVALID_HR_SAMPLE && hr.heartRate > 0) ? hr.heartRate : 0;        
        var charge                = systemStats.battery;
        var showChargePercentage  = Application.getApp().getProperty("ShowChargePercentage");
        var showPercentageUnder20 = Application.getApp().getProperty("ShowPercentageUnder20");
        var dayOfWeek             = nowinfo.day_of_week;
        var lcdBackgroundVisible  = Application.getApp().getProperty("LcdBackground");         
        var connected             = Sys.getDeviceSettings().phoneConnected;        
        var profile               = UserProfile.getProfile();
        var notificationCount     = Sys.getDeviceSettings().notificationCount;
        var alarmCount            = Sys.getDeviceSettings().alarmCount;
        var dst                   = Application.getApp().getProperty("DST");    
        var timezoneOffset        = clockTime.timeZoneOffset;
        var showHomeTimezone      = Application.getApp().getProperty("ShowHomeTimezone");
        var homeTimezoneOffset    = dst ? Application.getApp().getProperty("HomeTimezoneOffset") + 3600 : Application.getApp().getProperty("HomeTimezoneOffset");
        var onTravel              = timezoneOffset != homeTimezoneOffset;        
        var distanceUnit          = Application.getApp().getProperty("DistanceUnit"); // 0 -> Kilometer, 1 -> Miles
        var distance              = distanceUnit == 0 ? actinfo.distance * 0.00001 : actinfo.distance * 0.00001 * 0.621371;        
        var dateFormat            = Application.getApp().getProperty("DateFormat") == 0 ? "$1$.$2$" : "$2$/$1$";
        var showMoveBar           = Application.getApp().getProperty("ShowMoveBar");
        var showLeadingZero       = Application.getApp().getProperty("ShowLeadingZero");
        var lcdFont               = Application.getApp().getProperty("LcdFont");
        var showDeltaSteps        = Application.getApp().getProperty("ShowDeltaSteps");
        var moveBarLevel          = actinfo.moveBarLevel;
        var showStepBar           = Application.getApp().getProperty("ShowStepBar");
        var showCalorieBar        = Application.getApp().getProperty("ShowCalorieBar");
        var colorizeStepText      = Application.getApp().getProperty("ColorizeStepText");
        var colorizeCalorieText   = Application.getApp().getProperty("ColorizeCalorieText");
        //System.println("Altitude: " + altitude == null ? "-" : altitude.data);
        //System.println("Pressure: " + pressure == null ? "-" : pressure.data);
        var gender;
        var userWeight;
        var userHeight;
        var userAge;

        if (profile == null) {
            gender     = Application.getApp().getProperty("Gender");
            userWeight = Application.getApp().getProperty("Weight");
            userHeight = Application.getApp().getProperty("Height");
            userAge    = Application.getApp().getProperty("Age");
        } else {
            gender     = profile.gender;
            userWeight = profile.weight / 1000.0;
            userHeight = profile.height;
            userAge    = nowinfo.year - profile.birthYear;            
        }

        // Mifflin-St.Jeor Formula (1990)
        var baseKcalMen   = (9.99 * userWeight) + (6.25 * userHeight) - (4.92 * userAge) + 5;               // base kcal men
        var baseKcalWoman = (9.99 * userWeight) + (6.25 * userHeight) - (4.92 * userAge) - 161.0;           // base kcal woman        
        var baseKcal      = (gender == MEN ? baseKcalMen : baseKcalWoman) * 1.21385;                        // base kcal related to gender incl. correction factor for fenix 5x
        var kcalPerMinute = baseKcal / 1440;                                                                // base kcal per minute
        var activeKcal    = (kcal - (kcalPerMinute * (clockTime.hour * 60.0 + clockTime.min))).toNumber();  // active kcal
        var kcalReached   = kcal / baseKcal;

        // Heart Rate Zones
        var showBpmZones  = Application.getApp().getProperty("BpmZones");        
        var maxBpm        = (211.0 - 0.64 * userAge).toNumber(); // calculated after a study at NTNU (http://www.ntnu.edu/cerg/hrmax-info)
        var bpmZone1      = (0.5 * maxBpm).toNumber();
        var bpmZone2      = (0.6 * maxBpm).toNumber();
        var bpmZone3      = (0.7 * maxBpm).toNumber();
        var bpmZone4      = (0.8 * maxBpm).toNumber();
        var bpmZone5      = (0.9 * maxBpm).toNumber();
        
        var currentZone;
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
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, 151);
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
        dc.fillRectangle(0, 151, width, 89);
            
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 151, width, 151);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 152, width, 152);

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 179, width, 3);
        
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 182, width, 182);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 183, width, 183);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 210, width, 3);
        
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 213, width, 213);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(0, 214, width, 214);
        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(119, 151, 3, 60);
        
        // Notification
        if (notificationCount > 0) { dc.drawBitmap(62, 34, mailIcon); }    
           
        // Battery
        dc.drawBitmap(106, 34, batteryIcon);
        dc.setColor(charge < 20 ? Gfx.COLOR_RED : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(108, 36 , 24.0 * charge / 100.0, 7);        
        if (showChargePercentage) {
            if (showPercentageUnder20) {
                if (charge.toNumber() <= 20) {
                    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);                    
                    dc.drawText(120, 15, chargeFont, charge.toNumber() + "%", Gfx.TEXT_JUSTIFY_CENTER);                    
                }
            } else {
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                dc.drawText(120, 15, chargeFont, charge.toNumber() + "%", Gfx.TEXT_JUSTIFY_CENTER);
            }            
        }
        
        // BLE
        if (connected) { dc.drawBitmap(150, 32, bleIcon); }
        
        // Alarm
        if (alarmCount > 0) { dc.drawBitmap(169, 33, alarmIcon); }
       
        // Steps
        dc.drawBitmap(21, 157, stepsIcon);
        if (showDeltaSteps) {
            if (deltaSteps > 0) {
                dc.setColor(BRIGHT_RED, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            }
        } else {
            if (colorizeStepText) {
                stepsReached = stepsReached > 1.0 ? 1.0 : stepsReached;
                var endIndex = (10.0 * stepsReached).toNumber();
                dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            }
        }
        if (lcdFont) {
            dc.drawText(115, 154, valueFont, (showDeltaSteps ? deltaSteps.abs() : steps), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(115, 149, valueFontAnalog, (showDeltaSteps ? deltaSteps.abs() : steps), Gfx.TEXT_JUSTIFY_RIGHT);
        }
            
        // KCal
        dc.drawBitmap(206, 157, burnedIcon);
        if (colorizeCalorieText) {
            if (kcalReached > 3.0) {
                dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
            } else if (kcalReached > 2.0) {
                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            } else if (kcalReached > 1.0) {
                dc.setColor(BRIGHT_BLUE, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
            }
        } else {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        }
        if (showActiveKcalOnly) {            
            if (lcdFont) {
                dc.drawText(202, 154, valueFont, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(202, 149, valueFontAnalog, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
        } else {
            if (lcdFont) {
                dc.drawText(202, 154, valueFont, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(202, 149, valueFontAnalog, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
        }        

        // BPM        
        if (bpm >= maxBpm) {
            dc.drawBitmap(43, 188, showBpmZones ? bpmMaxRedIcon : bpmMaxBlackIcon);
        } else {
            dc.drawBitmap(43, 188, showBpmZones ? bpmZoneIcons[currentZone - 1] : bpmIcon);
        }        
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);        
        if (lcdFont) {
            dc.drawText(115, 185, valueFont, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(115, 180, valueFontAnalog, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        }

        // Distance
        if (lcdFont) {
            dc.drawText(175, 185, valueFont, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(195, 192, distanceFont, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(175, 180, valueFontAnalog, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(197, 189, distanceFontAnalog, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_RIGHT);
        }
                
        // Bottom field
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);        
        if (lcdFont) {
            dc.drawText(centerX, 214, valueFont, Lang.format("$1$:$2$", [activeHours.format(showLeadingZero ? "%02d" : "%01d"), activeMinutes.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(centerX, 221, distanceFontAnalog, Lang.format("$1$:$2$", [activeHours.format(showLeadingZero ? "%02d" : "%01d"), activeMinutes.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
        }
                                
        // Step Bar background
        if (showStepBar) {
            dc.setPenWidth(8);           
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            for(var i = 0; i < 10 ; i++) {            
                var startAngleLeft  = 130 + (i * 6);
                dc.drawArc(centerX, centerY, 117, 0, startAngleLeft, startAngleLeft + 5);
            }
            
            // Step Goal Bar
            stepsReached      = stepsReached > 1.0 ? 1.0 : stepsReached;
            var endIndex      = (10.0 * stepsReached).toNumber();
            var stopAngleLeft = (184.0 - 59.0 * stepsReached).toNumber();
            stopAngleLeft     = stopAngleLeft < 130.0 ? 130.0 : stopAngleLeft;        
            dc.setColor(endIndex > 0 ? STEP_COLORS[endIndex - 1] : Gfx.COLOR_TRANSPARENT, Gfx.COLOR_TRANSPARENT);
            for(var i = 0; i < endIndex ; i++) {            
                var startAngleLeft  = 184 - (i * 6);
                dc.drawArc(centerX, centerY, 117, 0, startAngleLeft, startAngleLeft + 5);
            }
        }

        // KCal Goal Bar Background
        if (showCalorieBar) {
            if (kcalReached > 3.0) {
                dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
            } else if (kcalReached > 2.0) {
                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            } else if (kcalReached > 1.0) {
                dc.setColor(BRIGHT_BLUE, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            }
            for(var i = 0; i < 10 ; i++) {            
                var startAngleRight = -10 + (i * 6);         
                dc.drawArc(centerX, centerY, 117, 0, startAngleRight, startAngleRight + 5);            
            }
                    
            // KCal Goal Bar
            if (kcalReached > 3.0) {
                dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
                kcalReached -= 3.0;
            } else if (kcalReached > 2.0) {
                dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
                kcalReached -= 2.0;
            } else if (kcalReached > 1.0) {
                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
                kcalReached -= 1.0;
            } else {
                dc.setColor(BRIGHT_BLUE, Gfx.COLOR_TRANSPARENT);
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
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            for (var i = 0 ; i < 5 ; i++) { dc.fillRectangle(54 + (i * 27), 146, 25, 4); }
            if (moveBarLevel > Act.MOVE_BAR_LEVEL_MIN) { dc.setColor(LEVEL_COLORS[moveBarLevel - 1], Gfx.COLOR_TRANSPARENT); }
            for (var i = 0 ; i < moveBarLevel ; i++) { dc.fillRectangle(54 + (i * 27), 146, 25, 4); }
            if (moveBarLevel == 5) { dc.drawBitmap(190, 142, alertIcon); }
        }
        

        // Time        
        if (lcdBackgroundVisible && lcdFont) {
            dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            if (showLeadingZero) {
                dc.drawText(centerX, 51, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                if (is24Hour) {
                    if (clockTime.hour < 10) {
                        dc.drawText(centerX, 51, timeFont, "8:88", Gfx.TEXT_JUSTIFY_CENTER);
                    } else {
                        dc.drawText(centerX, 51, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                    }
                } else {
                    if (clockTime.hour < 10 || clockTime.hour > 12) {
                        dc.drawText(centerX, 51, timeFont, "8:88", Gfx.TEXT_JUSTIFY_CENTER);
                    } else {
                        dc.drawText(centerX, 51, timeFont, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                    }
                }
            }            
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        if (is24Hour) {
            if (lcdFont) {
                dc.drawText(centerX, 51, timeFont, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(centerX, 44, timeFontAnalog, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
            }
            if (showSeconds) {
                dc.drawText(199, (lcdFont ? (97) : (92)), lcdFont ? distanceFont : distanceFontAnalog, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
            }
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
                dc.drawText(centerX, 51, timeFont, Lang.format("$1$:$2$", [hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(199, 97, distanceFont, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(centerX, 44, timeFontAnalog, Lang.format("$1$:$2$", [hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(199, 92, distanceFontAnalog, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            }
            if (showSeconds) {
                dc.drawText(199, (lcdFont ? (75) : (72)), lcdFont ? distanceFont : distanceFontAnalog, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
            }
        }        
    
        // Date and home timezone
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var dateYPosition = showMoveBar ? 116 : 119;
        dateYPosition = lcdFont ? dateYPosition : dateYPosition - 6;
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
                        
            if (lcdFont) {
                dc.drawText(38, dateYPosition, dateFont, Lang.format(weekdays[homeDayOfWeek] + dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(203, dateYPosition, dateFont, Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(38, dateYPosition, valueFontAnalog, Lang.format(weekdays[homeDayOfWeek] + dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(203, dateYPosition, valueFontAnalog, Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]), Gfx.TEXT_JUSTIFY_RIGHT);
            }   
        } else {
            if (lcdFont) {
                dc.drawText(centerX, dateYPosition, dateFont, Lang.format(weekdays[dayOfWeek -1] + dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(centerX, dateYPosition, valueFontAnalog, Lang.format(weekdays[dayOfWeek -1] + dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
    }
    
    
    function daysOfMonth(month) { 
        return 28 + (month + Math.floor(month / 8)) % 2 + 2 % month + 2 * Math.floor(1 / month); 
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // Will be called by timer
    function callback() {
        Ui.requestUpdate();
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {        
        showSeconds = true;
        timer.start(method(:callback), 1000, true);
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {        
        timer.stop();
        showSeconds = false;
        Ui.requestUpdate();
    }
}
