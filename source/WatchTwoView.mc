using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;

using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;

var IMAGE_SIZE = 24;
var IMAGE_TEXT_GAP = 5;

class WatchTwoView extends Ui.WatchFace {

    var logo;
    var logoRect;
    var timeTop;
    var timeFont;
    var dateTop;

    var batteryTop;
    var heartImage;
    var batteryImage;
    var bluetoothImage;
    var noBluetoothImage;

    var fontSmall = Gfx.FONT_TINY;

    var isFR920XT = false;

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
        self.dateTop = Ui.loadResource(Rez.Strings.DateTop).toNumber();
        self.batteryTop = Ui.loadResource(Rez.Strings.BatteryTop).toNumber();

        self.heartImage = Ui.loadResource(Rez.Drawables.Heart);
        self.batteryImage = Ui.loadResource(Rez.Drawables.Battery);
        self.bluetoothImage = Ui.loadResource(Rez.Drawables.Bluetooth);
        self.noBluetoothImage = Ui.loadResource(Rez.Drawables.NoBluetooth);

        if (Rez.Strings has :Device && Ui.loadResource(Rez.Strings.Device).equals("fr920xt")) {
            self.isFR920XT = true;
            self.timeFont = Gfx.FONT_SYSTEM_NUMBER_THAI_HOT; // 920xt cannot use custom font
        } else {
            self.timeFont = Ui.loadResource(Rez.Fonts.Font);            
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

    function getHourString(today) {
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

        return hours.format(hoursFormatString);
    }

    function selectLogo() {
        if (App.getApp().getProperty("UseChineseLogo")) {
            self.logo = Ui.loadResource(Rez.Drawables.Logo2);
        } else {
            self.logo = Ui.loadResource(Rez.Drawables.Logo);            
        }
    }

    function drawTime(dc) {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var hourMinGap = 0;

        if (self.isFR920XT) {
            hourMinGap = 5;
        }

        // time
        var hourStr = self.getHourString(today);
        var minStr = today.min.format("%02d");

        var hourStrDim = dc.getTextDimensions(hourStr, self.timeFont);
        var minStrDim = dc.getTextDimensions(minStr, self.timeFont);
        
        var left = (dc.getWidth() - hourStrDim[0] - minStrDim[0] - hourMinGap) / 2;
        var top = self.timeTop;
        dc.drawText(left, top -  hourStrDim[1] / 2, self.timeFont, hourStr, Gfx.TEXT_JUSTIFY_LEFT);
        left = left + hourStrDim[0] + hourMinGap;
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
        self.selectLogo();

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

    function getHeartRate() {
        if (ActivityMonitor has :getHeartRateHistory) {
            var hrIterator = ActivityMonitor.getHeartRateHistory(1, true);
            var latest = hrIterator.next();
            if (latest != null && latest.heartRate != null && latest.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return latest.heartRate.toString();
            }  
        }
        return null;     
    }

    function getBluetoothImage() {
        if (Sys.getDeviceSettings().phoneConnected) {
            return self.bluetoothImage;
        } else {
            return self.noBluetoothImage;
        }
    }

    function drawBatteryMeter(dc, batteryLeft, imageTop) {
        dc.drawBitmap(batteryLeft, imageTop, self.batteryImage);

        var sysStats = Sys.getSystemStats();
        var batteryMeterLeft = batteryLeft + 3;
        var batteryMeterTop = imageTop + 8;
        var batteryMeterWidth = (17 * sysStats.battery / 100).toNumber();
        var batteryMeterHeight = 9;

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        if (sysStats.battery < 31) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
        }    
        if (sysStats.battery < 16) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        }    
        dc.fillRectangle(batteryMeterLeft, batteryMeterTop, batteryMeterWidth, batteryMeterHeight);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);        
    }

    function drawIconLine(dc) {
        var totalWidth = 0;
        var batteryTotalWidth = 0;
        var heartRateTotalWidth = 0;
        var bluetoothTotalWidth = 0;

        var imageTop = self.batteryTop - IMAGE_SIZE / 2;

        var battString = Sys.getSystemStats().battery.toNumber().toString();
        var battStrDim = dc.getTextDimensions(battString, self.fontSmall);
        batteryTotalWidth = IMAGE_SIZE + IMAGE_TEXT_GAP + battStrDim[0];

        totalWidth += batteryTotalWidth;

        var hrString = self.getHeartRate();
        var hrStrDim = [0, 0];
        if (hrString != null) {
            hrStrDim = dc.getTextDimensions(hrString, self.fontSmall);
            heartRateTotalWidth = IMAGE_SIZE + IMAGE_TEXT_GAP + hrStrDim[0];
            totalWidth += IMAGE_TEXT_GAP * 2 + heartRateTotalWidth;            
        }

        if (App.getApp().getProperty("ShowPhoneConnectivity")) {
            bluetoothTotalWidth = IMAGE_SIZE;
            totalWidth += bluetoothTotalWidth + IMAGE_TEXT_GAP * 2;
        }

        var left = (dc.getWidth() - totalWidth) / 2;

        self.drawBatteryMeter(dc, left, imageTop);
        dc.drawText(left + IMAGE_SIZE + IMAGE_TEXT_GAP, self.batteryTop - battStrDim[1] / 2, self.fontSmall, battString, Gfx.TEXT_JUSTIFY_LEFT);
        left += batteryTotalWidth;

        if (heartRateTotalWidth > 0) {
            left += IMAGE_TEXT_GAP * 2;
            dc.drawBitmap(left, imageTop, self.heartImage);
            dc.drawText(left + IMAGE_SIZE + IMAGE_TEXT_GAP, self.batteryTop - hrStrDim[1] / 2, self.fontSmall, hrString, Gfx.TEXT_JUSTIFY_LEFT);
            left += heartRateTotalWidth;
        }

        if (bluetoothTotalWidth > 0) {
            left += IMAGE_TEXT_GAP * 2;
            dc.drawBitmap(left, imageTop, self.getBluetoothImage());
        }
    }

    function draw920TopLine(dc) {
   		var dateString = self.getDateString();
        var dateStrDim = dc.getTextDimensions(dateString, self.fontSmall);

        var battString = Sys.getSystemStats().battery.toNumber().toString();
        var battStrDim = dc.getTextDimensions(battString, self.fontSmall);

        var imageTop = self.dateTop;
        var batteryTotalWidth = IMAGE_SIZE + IMAGE_TEXT_GAP + battStrDim[0];

        var totalWidth = batteryTotalWidth + IMAGE_TEXT_GAP * 2 + dateStrDim[0];

        if (App.getApp().getProperty("ShowPhoneConnectivity")) {
            totalWidth += IMAGE_SIZE + IMAGE_TEXT_GAP * 2;
        }

        var left = (dc.getWidth() - totalWidth) / 2;

        self.drawBatteryMeter(dc, left, imageTop);
        dc.drawText(left + IMAGE_SIZE + IMAGE_TEXT_GAP, imageTop + IMAGE_SIZE / 2 - battStrDim[1] / 2, self.fontSmall, battString, Gfx.TEXT_JUSTIFY_LEFT);
        left += batteryTotalWidth + IMAGE_TEXT_GAP * 2;
        
        dc.drawText(left, imageTop + IMAGE_SIZE / 2 - dateStrDim[1] / 2, self.fontSmall, dateString, Gfx.TEXT_JUSTIFY_LEFT);
        left += dateStrDim[0];

        if (App.getApp().getProperty("ShowPhoneConnectivity")) {
            left += IMAGE_TEXT_GAP * 2;
            dc.drawBitmap(left, imageTop, self.getBluetoothImage());
        }

    }

    // Update the view
    function onUpdate(dc) {
        self.altColor = App.getApp().getProperty("ClockAltColor");
        self.fillColor = App.getApp().getProperty("LogoFillColor");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        
        drawTime(dc);
        if (self.isFR920XT) {
            draw920TopLine(dc);
        } else {
            drawDate(dc);
            drawIconLine(dc);
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
