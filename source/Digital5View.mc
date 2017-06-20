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

var timer;
var is24Hour;
var showSeconds;
var secondsAlwaysOn;
var lcdFont;
var clockTime;

class Digital5View extends Ui.WatchFace {
    enum { WOMAN, MEN }
    enum { ALTITUDE, PRESSURE, ACTIVE_TIME }
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
    var digitalUpright72, digitalUpright26, digitalUpright24, digitalUpright20, digitalUpright16;
    var analogFont60, analogFont22, analogFont14;    
    var bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon, bpmMaxRedIcon, bpmMaxBlackIcon;
    var alarmIcon, alertIcon, batteryIcon, bleIcon, bpmIcon, burnedIcon, mailIcon, stepsIcon, dndIcon;    
    var heartRate;    
      
    function initialize() {
        timer       = new Timer.Timer();
        showSeconds = false;
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        digitalUpright72   = Ui.loadResource(Rez.Fonts.digitalUpright72);
        digitalUpright26   = Ui.loadResource(Rez.Fonts.digitalUpright26);
        digitalUpright24   = Ui.loadResource(Rez.Fonts.digitalUpright24);
        digitalUpright20   = Ui.loadResource(Rez.Fonts.digitalUpright20);
        digitalUpright16   = Ui.loadResource(Rez.Fonts.digitalUpright16);
        analogFont60       = Ui.loadResource(Rez.Fonts.analog60);        
        analogFont22       = Ui.loadResource(Rez.Fonts.analog22);
        analogFont14       = Ui.loadResource(Rez.Fonts.analog14);
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
        dndIcon            = Ui.loadResource(Rez.Drawables.dnd);        
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
 
        dc.clearClip();
 
        is24Hour                  = Sys.getDeviceSettings().is24Hour;
        secondsAlwaysOn           = Application.getApp().getProperty("SecondsAlwaysOn");
        lcdFont                   = Application.getApp().getProperty("LcdFont");
        clockTime                 = Sys.getClockTime();
        
        var bpmZoneIcons          = [ bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon ];
 
        // General
        var width                 = dc.getWidth();
        var height                = dc.getHeight();
        var centerX               = width * 0.5;
        var centerY               = height * 0.5;        
        var midnightInfo          = Greg.info(Time.today(), Time.FORMAT_SHORT);
        var nowinfo               = Greg.info(Time.now(), Time.FORMAT_SHORT);
        var actinfo               = Act.getInfo();
        var systemStats           = Sys.getSystemStats();        
        var hrHistory             = Act.getHeartRateHistory(null, true);
        var hr                    = hrHistory.next();
        var steps                 = actinfo.steps;
        var stepGoal              = actinfo.stepGoal;        
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
        var showCalendarWeek      = Application.getApp().getProperty("ShowCalendarWeek");
        var showMoveBar           = Application.getApp().getProperty("ShowMoveBar");
        var showLeadingZero       = Application.getApp().getProperty("ShowLeadingZero");        
        var showDeltaSteps        = Application.getApp().getProperty("ShowDeltaSteps");
        var moveBarLevel          = actinfo.moveBarLevel;
        var showStepBar           = Application.getApp().getProperty("ShowStepBar");
        var showCalorieBar        = Application.getApp().getProperty("ShowCalorieBar");
        var colorizeStepText      = Application.getApp().getProperty("ColorizeStepText");
        var colorizeCalorieText   = Application.getApp().getProperty("ColorizeCalorieText");
        var bottomField           = Application.getApp().getProperty("BottomField");
        var bottomFieldText       = "";
        var bottomFieldUnitText   = "";
        var bottomFieldUnitSpacer = 0;

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
        if (notificationCount > 0) { dc.drawBitmap(58, 34, mailIcon); }    
           
        // Do not disturb
        if (System.getDeviceSettings().doNotDisturb) { dc.drawBitmap(85, 33, dndIcon); }
           
        // Battery
        dc.drawBitmap(106, 34, batteryIcon);
        dc.setColor(charge < 20 ? BRIGHT_RED : Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(108, 36 , 24.0 * charge / 100.0, 7);        
        if (showChargePercentage) {
            if (showPercentageUnder20) {
                if (charge.toNumber() <= 20) {
                    dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                }
            } else {
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            }
            dc.drawText(130, 15, digitalUpright16, charge.toNumber(), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawLine(131, 28, 137, 18);
            dc.drawRectangle(131, 19, 3, 3);
            dc.drawRectangle(134, 26, 3, 3);            
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
            //dc.drawText(115, 154, digitalUpright24, (showDeltaSteps ? deltaSteps.abs() : steps), Gfx.TEXT_JUSTIFY_RIGHT);            
            dc.drawText(115, 154, digitalUpright24, (showDeltaSteps ? deltaSteps * -1 : steps), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(115, 149, analogFont22, (showDeltaSteps ? deltaSteps * -1 : steps), Gfx.TEXT_JUSTIFY_RIGHT);
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
                dc.drawText(202, 154, digitalUpright24, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(202, 149, analogFont22, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
        } else {
            if (lcdFont) {
                dc.drawText(202, 154, digitalUpright24, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(202, 149, analogFont22, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
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
            dc.drawText(115, 185, digitalUpright24, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(115, 180, analogFont22, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        }

        // Distance
        if (lcdFont) {
            dc.drawText(175, 185, digitalUpright24, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(195, 192, digitalUpright16, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(175, 180, analogFont22, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(197, 189, analogFont14, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_RIGHT);
        }
                
        // Bottom field
        if (bottomField == ALTITUDE) {
            var altHistory = Sensor.getElevationHistory(null);        
            var altitude   = altHistory.next();
            if (null != altitude) {
                bottomFieldText       = altitude.data.format("%0.0f");
                bottomFieldUnitText   = "m";
                bottomFieldUnitSpacer = 0;
            }
        } else if (bottomField == PRESSURE) {
            var pressureHistory = Sensor.getPressureHistory(null);
            var pressure        = pressureHistory.next();
            if (null != pressure) {
                bottomFieldText       = (pressure.data.toDouble() / 100.0).toNumber().format("%0.0f");
                bottomFieldUnitText   = "mb";
                bottomFieldUnitSpacer = 10;
            }
        } else {
            var actMinutes        = actinfo.activeMinutesDay.total;
            var activeHours       = (actMinutes / 60.0).toNumber();
            var activeMinutes     = (actMinutes % 60).toNumber();
            bottomFieldText       = Lang.format("$1$:$2$", [activeHours.format(showLeadingZero ? "%02d" : "%01d"), activeMinutes.format("%02d")]);
            bottomFieldUnitText   = "";
            bottomFieldUnitSpacer = 0;
        }
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);        
        if (lcdFont) {
            dc.drawText(143 - bottomFieldUnitSpacer, 215, digitalUpright20, bottomFieldText, Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(155, 219, digitalUpright16, bottomFieldUnitText, Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(centerX, 216, analogFont14, bottomFieldText + bottomFieldUnitText, Gfx.TEXT_JUSTIFY_CENTER);            
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
                dc.drawText(centerX, 51, digitalUpright72, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                if (is24Hour) {
                    if (clockTime.hour < 10) {
                        dc.drawText(centerX, 51, digitalUpright72, "8:88", Gfx.TEXT_JUSTIFY_CENTER);
                    } else {
                        dc.drawText(centerX, 51, digitalUpright72, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                    }
                } else {
                    if (clockTime.hour < 10 || clockTime.hour > 12) {
                        dc.drawText(centerX, 51, digitalUpright72, "8:88", Gfx.TEXT_JUSTIFY_CENTER);
                    } else {
                        dc.drawText(centerX, 51, digitalUpright72, "88:88", Gfx.TEXT_JUSTIFY_CENTER);
                    }
                }
            }            
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        if (is24Hour) {
            if (lcdFont) {
                dc.drawText(centerX, 51, digitalUpright72, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(centerX, 44, analogFont60, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
            }
            if (showSeconds) {
                drawSeconds(dc);
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
                dc.drawText(centerX, 51, digitalUpright72, Lang.format("$1$:$2$", [hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(199, 97, digitalUpright16, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(centerX, 44, analogFont60, Lang.format("$1$:$2$", [hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(199, 92, analogFont14, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            }
            
            if (showSeconds || secondsAlwaysOn) {
                drawSeconds(dc);
            }
        }     
        
        // Calendar week
        if (showCalendarWeek) {
            dc.drawText(45, (lcdFont ? (77) : (72)), lcdFont ? digitalUpright16 : analogFont14, ("KW"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(45, (lcdFont ? (97) : (92)), lcdFont ? digitalUpright16 : analogFont14, (getWeekOfYear(nowinfo)), Gfx.TEXT_JUSTIFY_RIGHT);
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
                dc.drawText(38, dateYPosition, digitalUpright26, Lang.format(weekdays[homeDayOfWeek] + dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(203, dateYPosition, digitalUpright26, Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(38, dateYPosition, analogFont22, Lang.format(weekdays[homeDayOfWeek] + dateFormat, [homeDay.format(showLeadingZero ? "%02d" : "%01d"), homeMonth.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(203, dateYPosition, analogFont22, Lang.format("$1$:$2$", [homeHour.format(showLeadingZero ? "%02d" : "%01d"), homeMinute.format("%02d")]), Gfx.TEXT_JUSTIFY_RIGHT);
            }   
        } else {
            if (lcdFont) {
                dc.drawText(centerX, dateYPosition, digitalUpright26, Lang.format(weekdays[dayOfWeek -1] + dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(centerX, dateYPosition, analogFont22, Lang.format(weekdays[dayOfWeek -1] + dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]), Gfx.TEXT_JUSTIFY_CENTER);
            }
        }
        
        onPartialUpdate(dc);
    }
    
    function drawSeconds(dc) {
        clockTime = Sys.getClockTime();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        if (is24Hour) {
            dc.fillRectangle(199, 96, 18, 15);                    // clear the background behind the seconds
            dc.setClip(199, 96, 18, 15);                          // set the clip
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(199, (lcdFont ? (97) : (92)), lcdFont ? digitalUpright16 : analogFont14, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            dc.fillRectangle(199, 76, 18, 15);
            dc.setClip(199, 76, 18, 15);
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            dc.drawText(199, (lcdFont ? (75) : (72)), lcdFont ? digitalUpright16 : analogFont14, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        }
        //dc.clearClip(); // does not work here, instead clear clip at the beginning on onUpdate()
    }
    
    function daysOfMonth(month) { 
        return 28 + (month + Math.floor(month / 8)) % 2 + 2 % month + 2 * Math.floor(1 / month); 
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {        
        showSeconds = false;
        Ui.requestUpdate();
    }
    
    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {        
        showSeconds = true;
    }
    
    //! Called every second
    function onPartialUpdate(dc) {
        if (secondsAlwaysOn) { drawSeconds(dc); }
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
        var dayOfYear  = DAY_COUNT[month - 1] + day;
        var year_ordinal = dayOfYear;
        var a = (year - 1901) % 28;
        var b = Math.floor(a / 4);
        var week_ordinal = (2 + a + b) % 7 + 1;
        var dow = ((year_ordinal - 1) + (week_ordinal - 1)) % 7 + 1 - 1;
        if (0 == dow) { dow = 7; }        
        return dow;
    }
}

class Digital5Delegate extends Ui.WatchFaceDelegate {
    function onPowerBudgetExceeded(powerInfo) {
        showSeconds = false;        
    }
}
