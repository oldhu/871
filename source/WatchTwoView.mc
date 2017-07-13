using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;

using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.System;

class WatchTwoView extends Ui.WatchFace {

    var logo;
    var logoRect;
    var timeTop;
    var timeFont;
    var dateTop;

    var batteryTop;
    var heartImage;
    var batteryImage;

    var fontSmall = Gfx.FONT_TINY;

    var isRectangle = false;

    var altColor = 0x8B0012;
    var fillColor = 0x8B0012;

	var WEEK_DAYS = ["", "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
	var MONTH = ["", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));

        self.logoRect = [
            Ui.loadResource(Rez.Strings.LogoLeft).toNumber(),
            Ui.loadResource(Rez.Strings.LogoTop).toNumber(),
            Ui.loadResource(Rez.Strings.LogoWidth).toNumber(),
            Ui.loadResource(Rez.Strings.LogoHeight).toNumber()            
        ];
        self.timeTop = Ui.loadResource(Rez.Strings.TimeTop).toNumber();
        self.timeFont = Ui.loadResource(Rez.Fonts.Font);
        self.dateTop = Ui.loadResource(Rez.Strings.DateTop).toNumber();

        self.batteryTop = Ui.loadResource(Rez.Strings.BatteryTop).toNumber();
        self.heartImage = Ui.loadResource(Rez.Drawables.Heart);
        self.batteryImage = Ui.loadResource(Rez.Drawables.Battery);

        var mySettings = System.getDeviceSettings();
        self.isRectangle = (mySettings.screenShape == System.SCREEN_SHAPE_RECTANGLE);

        if (self.isRectangle) {
            self.timeFont = Gfx.FONT_SYSTEM_NUMBER_THAI_HOT;
		}
		
    }

    function initialize() {
        WatchFace.initialize();
    }

    function onShow() {
    }

    function getDateString() {
        if (App.getApp().getProperty("UseLocalizedDateFormat")) {
            var today = Gregorian.info(Time.now(), Time.FORMAT_LONG);
            var dateString = Lang.format("$1$ $2$, $3$", [today.month, today.day, today.day_of_week]);
            return dateString;
        } else {
            var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var dateString = Lang.format("$1$/$2$, $3$", [self.MONTH[today.month], today.day, self.WEEK_DAYS[today.day_of_week]]);
            return dateString;
        }
    }

    function drawTime(dc) {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        var hours = today.hour;    
        var hoursFormatString = "%d";
        if (!Sys.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (App.getApp().getProperty("UseMilitaryFormat")) {
                hoursFormatString = "%02d";
            }
        }

        // time
        var hourStr = hours.format(hoursFormatString);
        var minStr = today.min.format("%02d");

        var hourStrDim = dc.getTextDimensions(hourStr, self.timeFont);
        var minStrDim = dc.getTextDimensions(minStr, self.timeFont);
        
        var left = (dc.getWidth() - hourStrDim[0] - minStrDim[0]) / 2;
        var top = self.timeTop;
        dc.drawText(left, top -  hourStrDim[1] / 2, self.timeFont, hourStr, Gfx.TEXT_JUSTIFY_LEFT);
        left = left + hourStrDim[0];
        dc.setColor(self.altColor, Graphics.COLOR_BLACK);
        dc.drawText(left, top -  minStrDim[1] / 2, self.timeFont, minStr, Gfx.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    }

    function drawDate(dc) {
   		var dateString = self.getDateString();
   		var top = self.dateTop;
   		dc.drawText(dc.getWidth() / 2, top, self.fontSmall, dateString, Gfx.TEXT_JUSTIFY_CENTER);
    }

    function drawLogo(dc) {
        if (App.getApp().getProperty("UseChineseLogo")) {
            self.logo = Ui.loadResource(Rez.Drawables.Logo2);
        } else {
            self.logo = Ui.loadResource(Rez.Drawables.Logo);            
        }

        var info = ActivityMonitor.getInfo();
        var logoWidth = self.logoRect[2];
        var logoHeight = self.logoRect[3];
        var progressWidth = (logoWidth * info.steps / info.stepGoal).toNumber();
        if (progressWidth > logoWidth) {
            progressWidth = logoWidth;
        }

        var left = self.logoRect[0];
        var top = self.logoRect[1];
        dc.fillRectangle(left, top, logoWidth, logoHeight);
        dc.setColor(self.fillColor, Graphics.COLOR_BLACK);
        dc.fillRectangle(left, top, progressWidth, logoHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawBitmap(left, top, self.logo); 
    }

    function drawBatteryAndHR(dc) {
        var sysStats = System.getSystemStats();
        var battString = Lang.format("$1$", [sysStats.battery.toNumber()]);
        var battStrDim = dc.getTextDimensions(battString, self.fontSmall);

        var imageSize = 24;
        var imageTextGap = 5;
        var imageTop = self.batteryTop - imageSize / 2;
        var batteryTotalWidth = imageSize + imageTextGap + battStrDim[0];
        var batteryLeft = (dc.getWidth() - batteryTotalWidth) / 2;

        var totalWidth = batteryTotalWidth;

        var hrString = "";
        var hrLeft = 0;
        var hrStrDim = [0,0];
        if (ActivityMonitor has :getHeartRateHistory) {
            var hrIterator = ActivityMonitor.getHeartRateHistory(1, true);
            var latest = hrIterator.next();
            if (latest != null && latest.heartRate != null && latest.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                hrString = Lang.format("$1$", [latest.heartRate]);
                hrStrDim = dc.getTextDimensions(hrString, self.fontSmall);
                var hrTotalWidth = imageSize + imageTextGap + hrStrDim[0];
                var totalWidth = batteryTotalWidth + imageTextGap * 2 + hrTotalWidth;

                batteryLeft = (dc.getWidth() - totalWidth) / 2;
                hrLeft = batteryLeft + batteryTotalWidth + imageTextGap * 2;
            }
        }

        var batteryMeterLeft = batteryLeft + 3;
        var batteryMeterTop = imageTop + 8;
        var batteryMeterWidth = (17 * sysStats.battery / 100).toNumber();
        var batteryMeterHeight = 9;

        dc.drawBitmap(batteryLeft, imageTop, self.batteryImage);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        if (sysStats.battery < 31) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        }    
        if (sysStats.battery < 16) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        }    
        dc.fillRectangle(batteryMeterLeft, batteryMeterTop, batteryMeterWidth, batteryMeterHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        dc.drawText(batteryLeft + imageSize + imageTextGap, self.batteryTop - battStrDim[1] / 2, self.fontSmall, battString, Gfx.TEXT_JUSTIFY_LEFT);
        if (hrLeft > 0) {
            dc.drawBitmap(hrLeft, imageTop, self.heartImage);
            dc.drawText(hrLeft + imageSize + imageTextGap, self.batteryTop - hrStrDim[1] / 2, self.fontSmall, hrString, Gfx.TEXT_JUSTIFY_LEFT);
        }
    }

    function drawDateAndBattery(dc) {
   		var dateString = self.getDateString();
        var dateStrDim = dc.getTextDimensions(dateString, self.fontSmall);

        var sysStats = System.getSystemStats();
        var battString = Lang.format("$1$", [sysStats.battery.toNumber()]);
        var battStrDim = dc.getTextDimensions(battString, self.fontSmall);

        var imageSize = 24;
        var imageTextGap = 5;
        var imageTop = self.dateTop;
        var batteryTotalWidth = imageSize + imageTextGap + battStrDim[0];

        var totalWidth = batteryTotalWidth + imageTextGap * 2 + dateStrDim[0];
        var batteryLeft = (dc.getWidth() - totalWidth) / 2;

        var batteryMeterLeft = batteryLeft + 3;
        var batteryMeterTop = imageTop + 8;
        var batteryMeterWidth = (17 * sysStats.battery / 100).toNumber();
        var batteryMeterHeight = 9;

        dc.drawBitmap(batteryLeft, imageTop, self.batteryImage);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        if (sysStats.battery < 31) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        }    
        if (sysStats.battery < 16) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        }    
        dc.fillRectangle(batteryMeterLeft, batteryMeterTop, batteryMeterWidth, batteryMeterHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(batteryLeft + imageSize + imageTextGap, imageTop + imageSize / 2 - battStrDim[1] / 2, self.fontSmall, battString, Gfx.TEXT_JUSTIFY_LEFT);
        

        var dateLeft = batteryLeft + batteryTotalWidth + imageTextGap * 2;
        dc.drawText(dateLeft, imageTop + imageSize / 2 - dateStrDim[1] / 2, self.fontSmall, dateString, Gfx.TEXT_JUSTIFY_LEFT);
    }

    // Update the view
    function onUpdate(dc) {
        self.altColor = App.getApp().getProperty("ClockAltColor");
        self.fillColor = App.getApp().getProperty("LogoFillColor");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        drawTime(dc);
        if (self.isRectangle) {
            drawDateAndBattery(dc);
        } else {
            drawDate(dc);
            drawBatteryAndHR(dc);
        }
        drawLogo(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}
