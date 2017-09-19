# Garmin Connect IQ fenix 5 watch face: Digital 5

![Overview](https://www.dropbox.com/s/9uc7ojnt97x7otv/Digital5Overview.png)

A simple digital watch face for the Garmin fenix 5x which shows the following data:
- date 
- time 
- time and date of your home time zone
- do not disturb
- notifications
- alarms
- steps
- steps needed to reach daily goal
- calories burned
- active calories burned (calcluated after Mifflin-St.Jeor Formula (1990))
- distance
- move bar
- last measured heart rate
- calculated heart rate zones ([calculated after a study at NTNU](http://www.ntnu.edu/cerg/hrmax-info))
- floors up/down
- meters up/down
- average calories burned the last 7 days
- active time of the last week
- active time of today
- sunrise and sunset ([calculated after Sunrise/Sunset Algorithm](http://williams.best.vwh.net/sunrise_sunset_algorithm.htm))
- weather

([Powered by Dark Sky](https://darksky.net/poweredby/))

The LCD background can be switched off and the heart rate zone could be visualized by colors.
On the left side it will show the daily step goal in a colored bar (is the bar green then the daily stepgoal is reached). On the right side it shows the burned calories where the bar is blue as long as you have not reached your daily base calorie consumption, it will turn green when the burned calories are higher than your daily base calorie consumption. Are the burned calories more than 2x the base calorie consumption the bar will turn pink. 
If you set your home time zone offset the watch face will show you time at your home place when you are on travel and currently in a different time zone.
The longer you don't move the more segments of the horizontal bar with 5 segments will turn red (move bar). 
Battery charge can also be shown in % and one could also show the battery charge in % only if it falls below 20%. In addition you could also
choose to show the battery charged colored (from green 100% to red < 20%)

If you don't want you can disable showing leading zeroes for hours and date.

In case your current heart rate exceeds the calculated max heart rate it will be shown by an exclamation mark in the heart icon.

If you don't like the LCD like font you can change it to a more normal font.

You can correct the shown altitude by defining an altitude offset.

You can correct the shown pressure by defining a pressure offset.

To change the settings you have to use the Garmin Express Application on your desktop or the Connect Application on your mobile phone.

The heart rate will appear after some time. In a watch face one can only access the last stored heart rate which means it always lags a bit behind the current heart rate.

Calories Bar:
Daily base calories are calculated using Mifflin-St.Jeor equation.
Bar segments are colored based on total calories burned.
All segments blue   = 1x base calories burned
All segments green  = 2x base calories burned
All segments pink   = 3x base calories burned

The sunrise/sunset is calculated by an algorithm found at http://williams.best.vwh.net/sunrise_sunset_algorithm.htm.
To be able to calculate the sunrise/sunset you have to put in the current location (latitude, longitude) and the current
timezone you are in. If you have daylight saving time in your current timezone please check the "Daylight saving time (current location)" checkbox.

ATTENTION:
Instead of giving negative reviews please file an issue at the [github issuetracker](https://github.com/HanSolo/digital5/issues) when you encounter problems.
By using the issue tracker you can describe your problem and I can try to reproduce and fix it, thanks.

To make use of the Weather feature you need your own Dark Sky API key,
to get one please follow the steps below:

1) Go to the [DarkSky website](https://darksky.net/dev/)

2) Create your own account and you'll see a 32 character key

3) This key you need to put in the watch face settings either on your phone or via Garmin Express.

4) Make sure you have the coordinates of your current location (latitude, longitude) put in the settings

At the moment the weather update is done every 15 minutes.

You can choose between daily or current weather information where the daily weather will show you an icon for
today and the min and max temperature for today. The current weather information will show you an icon for the 
current weather and the current temperature.
