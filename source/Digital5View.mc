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

var is24Hour;
var secondsAlwaysOn;
var lcdFont;
var lcdFontDataFields;
var clockTime;
var upperBackgroundColor;
var upperForegroundColor;

class Digital5View extends Ui.WatchFace {
    enum { WOMAN, MEN }
    enum { ALTITUDE, PRESSURE, ACTIVE_TIME_TODAY, ACTIVE_TIME_WEEK, FLOORS, METERS }
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
    var digitalUpright72, digitalUpright26, digitalUpright24, digitalUpright20, digitalUpright16;
    var bpm1Icon, bpm2Icon, bpm3Icon, bpm4Icon, bpm5Icon, bpmMaxRedIcon, bpmMaxBlackIcon, bpmMaxWhiteIcon;
    var mailIcon, mailIconBlack, dndIcon, dndIconBlack, batteryIcon, batteryIconBlack, bleIcon, bleIconBlack, alarmIcon, alarmIconBlack;
    var alertIcon, alertIconBlack;
    var bpmIcon, bpmIconWhite, burnedIcon, burnedIconWhite, stepsIcon, stepsIconWhite;    
    var heartRate;    
      
    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        digitalUpright72   = Ui.loadResource(Rez.Fonts.digitalUpright72);
        digitalUpright26   = Ui.loadResource(Rez.Fonts.digitalUpright26);
        digitalUpright24   = Ui.loadResource(Rez.Fonts.digitalUpright24);
        digitalUpright20   = Ui.loadResource(Rez.Fonts.digitalUpright20);
        digitalUpright16   = Ui.loadResource(Rez.Fonts.digitalUpright16);
        alarmIcon          = Ui.loadResource(Rez.Drawables.alarm);
        alarmIconBlack     = Ui.loadResource(Rez.Drawables.alarmBlack);
        alertIcon          = Ui.loadResource(Rez.Drawables.alert);
        alertIconBlack     = Ui.loadResource(Rez.Drawables.alertBlack);
        batteryIcon        = Ui.loadResource(Rez.Drawables.battery);
        batteryIconBlack   = Ui.loadResource(Rez.Drawables.batteryBlack);
        bleIcon            = Ui.loadResource(Rez.Drawables.ble);
        bleIconBlack       = Ui.loadResource(Rez.Drawables.bleBlack);
        mailIcon           = Ui.loadResource(Rez.Drawables.mail);
        mailIconBlack      = Ui.loadResource(Rez.Drawables.mailBlack);
        dndIcon            = Ui.loadResource(Rez.Drawables.dnd);
        dndIconBlack       = Ui.loadResource(Rez.Drawables.dndBlack);
        bpmIconWhite       = Ui.loadResource(Rez.Drawables.bpmWhite);
        bpmIcon            = Ui.loadResource(Rez.Drawables.bpm);
        bpm1Icon           = Ui.loadResource(Rez.Drawables.bpm1);
        bpm2Icon           = Ui.loadResource(Rez.Drawables.bpm2);
        bpm3Icon           = Ui.loadResource(Rez.Drawables.bpm3);
        bpm4Icon           = Ui.loadResource(Rez.Drawables.bpm4);
        bpm5Icon           = Ui.loadResource(Rez.Drawables.bpm5);
        bpmMaxRedIcon      = Ui.loadResource(Rez.Drawables.bpmMaxRed);
        bpmMaxBlackIcon    = Ui.loadResource(Rez.Drawables.bpmMaxBlack);
        bpmMaxWhiteIcon    = Ui.loadResource(Rez.Drawables.bpmMaxWhite);
        burnedIcon         = Ui.loadResource(Rez.Drawables.burned);
        burnedIconWhite    = Ui.loadResource(Rez.Drawables.burnedWhite);
        stepsIcon          = Ui.loadResource(Rez.Drawables.steps);
        stepsIconWhite     = Ui.loadResource(Rez.Drawables.stepsWhite);
        weekdays[0]        = Ui.loadResource(Rez.Strings.Sun);
        weekdays[1]        = Ui.loadResource(Rez.Strings.Mon);
        weekdays[2]        = Ui.loadResource(Rez.Strings.Tue);
        weekdays[3]        = Ui.loadResource(Rez.Strings.Wed);
        weekdays[4]        = Ui.loadResource(Rez.Strings.Thu);
        weekdays[5]        = Ui.loadResource(Rez.Strings.Fri);
        weekdays[6]        = Ui.loadResource(Rez.Strings.Sat);
        months[0]          = Ui.loadResource(Rez.Strings.Jan);
        months[1]          = Ui.loadResource(Rez.Strings.Feb);
        months[2]          = Ui.loadResource(Rez.Strings.Mar);
        months[3]          = Ui.loadResource(Rez.Strings.Apr);
        months[4]          = Ui.loadResource(Rez.Strings.May);
        months[5]          = Ui.loadResource(Rez.Strings.Jun);
        months[6]          = Ui.loadResource(Rez.Strings.Jul);
        months[7]          = Ui.loadResource(Rez.Strings.Aug);
        months[8]          = Ui.loadResource(Rez.Strings.Sep);
        months[9]          = Ui.loadResource(Rez.Strings.Oct);
        months[10]         = Ui.loadResource(Rez.Strings.Nov);
        months[11]         = Ui.loadResource(Rez.Strings.Dec);
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
        secondsAlwaysOn           = App.getApp().getProperty("SecondsAlwaysOn");
        lcdFont                   = App.getApp().getProperty("LcdFont");
        lcdFontDataFields         = App.getApp().getProperty("LcdFontDataFields");
        
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
        var showActiveKcalOnly    = App.getApp().getProperty("ShowActiveKcalOnly");
        var bpm                   = (hr.heartRate != Act.INVALID_HR_SAMPLE && hr.heartRate > 0) ? hr.heartRate : 0;        
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
        var showHomeTimezone      = Application.getApp().getProperty("ShowHomeTimezone");
        var homeTimezoneOffset    = dst ? Application.getApp().getProperty("HomeTimezoneOffset") + 3600 : Application.getApp().getProperty("HomeTimezoneOffset");
        var onTravel              = timezoneOffset != homeTimezoneOffset;        
        var distanceUnit          = Sys.getDeviceSettings().distanceUnits; // 0 -> Kilometer, 1 -> Miles
        var distance              = distanceUnit == 0 ? actinfo.distance * 0.00001 : actinfo.distance * 0.00001 * 0.621371;        
        var dayMonth              = App.getApp().getProperty("DateFormat") == 0;
        var dateFormat            = dayMonth ? "$1$.$2$" : "$2$/$1$";
        var monthAsText           = App.getApp().getProperty("MonthAsText");
        var showCalendarWeek      = App.getApp().getProperty("ShowCalendarWeek");
        var showMoveBar           = App.getApp().getProperty("ShowMoveBar");
        var showLeadingZero       = App.getApp().getProperty("ShowLeadingZero");        
        var showDeltaSteps        = App.getApp().getProperty("ShowDeltaSteps");
        var moveBarLevel          = actinfo.moveBarLevel;
        var showStepBar           = App.getApp().getProperty("ShowStepBar");
        var showCalorieBar        = App.getApp().getProperty("ShowCalorieBar");
        var colorizeStepText      = App.getApp().getProperty("ColorizeStepText");
        var colorizeCalorieText   = App.getApp().getProperty("ColorizeCalorieText");
        var bottomField           = App.getApp().getProperty("BottomField");
        var darkUpperBackground   = App.getApp().getProperty("DarkUpperBackground");
        upperBackgroundColor      = darkUpperBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
        upperForegroundColor      = darkUpperBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        var darkFieldBackground   = Application.getApp().getProperty("DarkFieldBackground");
        var fieldBackgroundColor  = darkFieldBackground ? Gfx.COLOR_BLACK : Gfx.COLOR_WHITE;
        var fieldForegroundColor  = darkFieldBackground ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        var bottomFieldText       = "";
        var bottomFieldUnitText   = "";
        var bottomFieldUnitSpacer = 0;
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
        var baseKcalMen   = (9.99 * userWeight) + (6.25 * userHeight) - (4.92 * userAge) + 5.0;               // base kcal men
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
        dc.setColor(upperBackgroundColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, 151);
        
        if (darkFieldBackground) {
            dc.setColor(fieldBackgroundColor, Gfx.COLOR_TRANSPARENT);    
            dc.fillRectangle(0, 151, width, 89);
            
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            dc.fillRectangle(0, 152, width, 2);
            dc.fillRectangle(0, 180, width, 2);
            dc.fillRectangle(0, 211, width, 2);
            dc.fillRectangle(119, 152, 2, 60);
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
        if (notificationCount > 0) { dc.drawBitmap(58, 34, darkUpperBackground ? mailIcon : mailIconBlack); }    
           
        // Do not disturb
        if (System.getDeviceSettings().doNotDisturb) { dc.drawBitmap(85, 33, darkUpperBackground ? dndIcon : dndIconBlack); }
           
        // Battery
        dc.drawBitmap(106, 34, darkUpperBackground ? batteryIcon : batteryIconBlack);
        dc.setColor(charge < 20 ? BRIGHT_RED : upperForegroundColor, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(108, 36 , 24.0 * charge / 100.0, 7);        
        if (showChargePercentage) {
            if (showPercentageUnder20) {
                if (charge <= 20) {
                    dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
                }
            } else {
                dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
            }
            dc.drawText(130, 15, digitalUpright16, charge.toNumber(), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawLine(131, 28, 137, 18);
            dc.drawRectangle(131, 19, 3, 3);
            dc.drawRectangle(134, 26, 3, 3);            
        }
        
        // BLE
        if (connected) { dc.drawBitmap(150, 32, darkUpperBackground ? bleIcon : bleIconBlack); }
        
        // Alarm
        if (alarmCount > 0) { dc.drawBitmap(169, 33, darkUpperBackground ? alarmIcon : alarmIconBlack); }
                               
        // Step Bar background
        if (showStepBar) {
            dc.setPenWidth(8);           
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
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
                dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
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
            dc.setColor(darkUpperBackground ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            for (var i = 0 ; i < 5 ; i++) { dc.fillRectangle(54 + (i * 27), 143, 25, 4); }
            if (moveBarLevel > Act.MOVE_BAR_LEVEL_MIN) { dc.setColor(LEVEL_COLORS[moveBarLevel - 1], Gfx.COLOR_TRANSPARENT); }
            for (var i = 0 ; i < moveBarLevel ; i++) { dc.fillRectangle(54 + (i * 27), 143, 25, 4); }
            if (moveBarLevel == 5) { dc.drawBitmap(190, 141, darkUpperBackground ? alertIcon : alertIconBlack); }
        }
        
        
        // ******************** TIME ******************************************

        // Time        
        if (lcdBackgroundVisible && lcdFont) {
            dc.setColor(darkBackgroundColor ? Gfx.COLOR_DK_GRAY : Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
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
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
        if (is24Hour) {
            if (lcdFont) {
                dc.drawText(centerX, 51, digitalUpright72, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(centerX, 56, Graphics.FONT_NUMBER_HOT, Lang.format("$1$:$2$", [clockTime.hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
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
                dc.drawText(centerX, 56, Graphics.FONT_NUMBER_HOT, Lang.format("$1$:$2$", [hour.format(showLeadingZero ? "%02d" : "%01d"), clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(191, 87, Graphics.FONT_TINY, amPm, Gfx.TEXT_JUSTIFY_LEFT);
            }
        }     
        
        
        // ******************** DATE ******************************************
        
        // Calendar week
        if (showCalendarWeek) {
            dc.drawText((lcdFont ? 45 : 50), (lcdFont ? 75 : 66), lcdFont ? digitalUpright16 : Graphics.FONT_TINY, ("KW"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText((lcdFont ? 45 : 50), (lcdFont ? 97 : 87), lcdFont ? digitalUpright16 : Graphics.FONT_TINY, (getWeekOfYear(nowinfo)), Gfx.TEXT_JUSTIFY_RIGHT);            
        }
    
        // Date and home timezone
        dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
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
            
            if (lcdFont) {
                if (monthAsText) {
                    dc.drawText(28, dateYPosition, digitalUpright26, weekdayText + dateText, Gfx.TEXT_JUSTIFY_LEFT);
                    dc.drawText(216, dateYPosition, digitalUpright26, timeText, Gfx.TEXT_JUSTIFY_RIGHT);
                 } else {
                    dc.drawText(28, dateYPosition, digitalUpright26, weekdayText + dateNumberText, Gfx.TEXT_JUSTIFY_LEFT);                
                    dc.drawText(216, dateYPosition, digitalUpright26, timeText, Gfx.TEXT_JUSTIFY_RIGHT);
                 }                                
            } else {
                if (monthAsText) {
                    dc.drawText(28, dateYPosition, Graphics.FONT_TINY, weekdayText + dateText, Gfx.TEXT_JUSTIFY_LEFT);                    
                    dc.drawText(216, dateYPosition, Graphics.FONT_TINY, timeText, Gfx.TEXT_JUSTIFY_RIGHT); 
                } else {
                    dc.drawText(28, dateYPosition, Graphics.FONT_TINY, weekdayText + dateNumberText, Gfx.TEXT_JUSTIFY_LEFT);
                    dc.drawText(216, dateYPosition, Graphics.FONT_TINY, timeText, Gfx.TEXT_JUSTIFY_RIGHT);
                }
            }   
        } else {
            var weekdayText    = weekdays[dayOfWeek - 1];            
            var dateText       = dayMonth ?  nowinfo.day.format(showLeadingZero ? "%02d" : "%01d") + " " + months[nowinfo.month - 1] : months[nowinfo.month - 1] + " " + nowinfo.day.format(showLeadingZero ? "%02d" : "%01d");
            var dateNumberText = Lang.format(dateFormat, [nowinfo.day.format(showLeadingZero ? "%02d" : "%01d"), nowinfo.month.format(showLeadingZero ? "%02d" : "%01d")]);
            
            if (lcdFont) {
                if (monthAsText) {
                    dc.drawText(centerX, dateYPosition, digitalUpright26, weekdayText + dateText, Gfx.TEXT_JUSTIFY_CENTER);
                } else {
                    dc.drawText(centerX, dateYPosition, digitalUpright26, weekdayText + dateNumberText, Gfx.TEXT_JUSTIFY_CENTER); 
                }                
            } else {
                if (monthAsText) {
                    dc.drawText(centerX, dateYPosition, Graphics.FONT_TINY, weekdayText + dateText, Gfx.TEXT_JUSTIFY_CENTER);
                } else {
                    dc.drawText(centerX, dateYPosition, Graphics.FONT_TINY, weekdayText + dateNumberText, Gfx.TEXT_JUSTIFY_CENTER);
                }
            }
        }
        
        
        // ******************** DATA FIELDS ***********************************
       
        // Steps
        dc.drawBitmap(21, 157, darkFieldBackground ? stepsIconWhite : stepsIcon);
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
                dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            }
        }
        if (lcdFontDataFields) {
            //dc.drawText(115, 154, digitalUpright24, (showDeltaSteps ? deltaSteps.abs() : steps), Gfx.TEXT_JUSTIFY_RIGHT);            
            dc.drawText(115, 154, digitalUpright24, (showDeltaSteps ? deltaSteps * -1 : steps), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(115, 153, Graphics.FONT_TINY, (showDeltaSteps ? deltaSteps * -1 : steps), Gfx.TEXT_JUSTIFY_RIGHT);
        }
            
        // KCal
        dc.drawBitmap(206, 157, darkFieldBackground ? burnedIconWhite : burnedIcon);
        if (colorizeCalorieText) {
            if (kcalReached > 3.0) {
                dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
            } else if (kcalReached > 2.0) {
                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
            } else if (kcalReached > 1.0) {
                dc.setColor(BRIGHT_BLUE, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
            }
        } else {
            dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);
        }
        if (showActiveKcalOnly) {            
            if (lcdFontDataFields) {
                dc.drawText(202, 154, digitalUpright24, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(202, 153, Graphics.FONT_TINY, activeKcal < 0 ? 0 : activeKcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
        } else {
            if (lcdFontDataFields) {
                dc.drawText(202, 154, digitalUpright24, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(202, 153, Graphics.FONT_TINY, kcal.toString(), Gfx.TEXT_JUSTIFY_RIGHT);
            }
        }        

        // BPM        
        if (bpm >= maxBpm) {
            dc.drawBitmap(43, 187, showBpmZones ? bpmMaxRedIcon : darkFieldBackground ? bpmMaxWhiteIcon : bpmMaxBlackIcon);
        } else {
            dc.drawBitmap(43, 187, showBpmZones ? bpmZoneIcons[currentZone - 1] : darkFieldBackground ? bpmIconWhite : bpmIcon);
        }        
        
        dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);        
        
        if (lcdFontDataFields) {
            dc.drawText(115, 184, digitalUpright24, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        } else {
            dc.drawText(115, 183, Graphics.FONT_TINY, (bpm > 0 ? bpm.toString() : ""), Gfx.TEXT_JUSTIFY_RIGHT);
        }

        // Distance
        if (lcdFontDataFields) {
            dc.drawText(181, 184, digitalUpright24, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(184, 191, digitalUpright16, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(175, 183, Graphics.FONT_TINY, distance > 99.99 ? distance.format("%0.0f") : distance.format("%0.1f"), Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(178, 183, Graphics.FONT_TINY, distanceUnit == 0 ? "km" : "mi", Gfx.TEXT_JUSTIFY_LEFT);
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
                bottomFieldText       = (pressure.data.toDouble() / 100.0).format(lcdFontDataFields ? "%0.2f" : "%0.0f");
                bottomFieldUnitText   = "mb";
                bottomFieldUnitSpacer = lcdFontDataFields ? 10 : 5;
            }
        } else if (bottomField == ACTIVE_TIME_TODAY) {
            var actMinutes        = actinfo.activeMinutesDay.total;
            var activeHours       = (actMinutes / 60.0).toNumber();
            var activeMinutes     = (actMinutes % 60).toNumber();
            bottomFieldText       = Lang.format("$1$:$2$", [activeHours.format(showLeadingZero ? "%02d" : "%01d"), activeMinutes.format("%02d")]);
            bottomFieldUnitText   = "";
            bottomFieldUnitSpacer = 0;
        } else if (bottomField == ACTIVE_TIME_WEEK) {
            var actMinutes        = actinfo.activeMinutesWeek.total;
            var activeHours       = (actMinutes / 60.0).toNumber();
            var activeMinutes     = (actMinutes % 60).toNumber();
            bottomFieldText       = Lang.format("$1$:$2$", [activeHours.format(showLeadingZero ? "%02d" : "%01d"), activeMinutes.format("%02d")]);
            bottomFieldUnitText   = "";
            bottomFieldUnitSpacer = 0;
        } else if (bottomField == FLOORS) {
            var floorsClimbed     = actinfo.floorsClimbed;
            var floorsDescended   = actinfo.floorsDescended;
            bottomFieldText       = " " + floorsClimbed.toString() + "/-" + floorsDescended.toString();
            bottomFieldUnitText   = "";
            bottomFieldUnitSpacer = 0;
        } else {
            var metersClimbed     = actinfo.metersClimbed.format("%0d");
            var metersDescended   = actinfo.metersDescended.format("%0d");
            bottomFieldText       = metersClimbed.toString() + "/-" + metersDescended.toString();
            bottomFieldUnitText   = "";
            bottomFieldUnitSpacer = 0;
        }
        
        dc.setColor(fieldForegroundColor, Gfx.COLOR_TRANSPARENT);        
        
        if (lcdFontDataFields) {
            if (bottomFieldUnitText.length() == 0) {                
                dc.drawText(centerX, 213, digitalUpright20, bottomFieldText, Gfx.TEXT_JUSTIFY_CENTER);            
            } else {
                dc.drawText(149 - bottomFieldUnitSpacer, 213, digitalUpright20, bottomFieldText, Gfx.TEXT_JUSTIFY_RIGHT);
                dc.drawText(161, 217, digitalUpright16, bottomFieldUnitText, Gfx.TEXT_JUSTIFY_RIGHT);
            }
        } else {
            dc.drawText(centerX, 212, Graphics.FONT_TINY, bottomFieldText + bottomFieldUnitText, Gfx.TEXT_JUSTIFY_CENTER);
        }
                
        onPartialUpdate(dc);
    }
    
    function drawSeconds(dc) {
        clockTime = Sys.getClockTime();
        dc.setColor(upperBackgroundColor, Gfx.COLOR_TRANSPARENT);
        if (is24Hour) {
            if (lcdFont) {
                dc.fillRectangle(199, 99, 16, 12);
                dc.setClip(199, 99, 16, 12);
            } else {
                dc.fillRectangle(191, 93, 21, 17);
                dc.setClip(191, 93, 21, 17);
            }
            dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.drawText((lcdFont ? 199 : 191), (lcdFont ? 97 : 87), lcdFont ? digitalUpright16 : Graphics.FONT_TINY, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
        } else {
            if (lcdFont) {
                dc.fillRectangle(199, 78, 16, 12);
                dc.setClip(199, 78, 16, 12);
            } else {
                dc.fillRectangle(191, 74, 21, 17);
                dc.setClip(191, 74, 21, 17);
            }
            dc.setColor(upperForegroundColor, Gfx.COLOR_TRANSPARENT);
            dc.drawText((lcdFont ? 199 : 191), (lcdFont ? 75 : 68), lcdFont ? digitalUpright16 : Graphics.FONT_TINY, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);
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
            
    }
    
    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {        
        
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
                 
    }
}
