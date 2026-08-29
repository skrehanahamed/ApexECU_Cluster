import QtQuick
import QtQuick.Controls

/****************************************************************************
** Component: BatteryTempGauge.qml
** Role: Right-hand Instrument Gauge
** Features:
**   - Outer curved arc measuring Battery Temperature (0°C to 80°C)
**   - Lower thermal thermometer icon with COLD baseline marker
**   - Central readout showing BATTERY TEMP in °C (32°C)
**   - Operating thermal window indicator (OPTIMAL · 20°–45°C)
**   - Secondary trip computer readout (TRIP A · 256.8 km)
****************************************************************************/

Item {
    id: batteryTempGauge
    width: parent.width * 0.28
    height: parent.height

    // Battery Thermal Telemetry (Curved Arc Meter)
    property real batteryTemp: 32.0       // Current battery temp in °C
    property real minTemp: 0.0            // 0 °C (COLD)
    property real maxTemp: 80.0           // 80 °C (HOT)
    property real tripKm: 256.8
    property real consumption: 18.2
    property string themeColor: "#00e5ff"

    Canvas {
        id: gaugeCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var w = width;
            var h = height;

            var centerX = w * 0.04;
            var centerY = h * 0.50;
            var radius  = Math.min(w * 0.82, h * 0.44);

            var angle0   =  Math.PI * 0.19;   // 0°C (bottom-right)
            var angleMax = -Math.PI * 0.19;   // 80°C (top-right)
            var totalSweep = angle0 - angleMax;

            var activeFraction = Math.max(0.0, Math.min(1.0, (batteryTempGauge.batteryTemp - batteryTempGauge.minTemp) / (batteryTempGauge.maxTemp - batteryTempGauge.minTemp)));
            var activeEndAngle = angle0 - totalSweep * activeFraction;

            // 1. Background Groove
            ctx.strokeStyle = "#101824";
            ctx.lineWidth   = 5.5;
            ctx.lineCap     = "round";
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, angleMax, angle0, false);
            ctx.stroke();

            ctx.strokeStyle = "rgba(255, 255, 255, 0.03)";
            ctx.lineWidth   = 1.0;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius + 2.5, angleMax, angle0, false);
            ctx.stroke();

            // 2. Inactive Upper Arc
            if (activeFraction < 1.0) {
                ctx.strokeStyle = "rgba(45, 60, 78, 0.55)";
                ctx.lineWidth   = 4.5;
                ctx.lineCap     = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, angleMax, activeEndAngle, false);
                ctx.stroke();
            }

            // 3. Active Temperature Arc
            if (activeFraction > 0.02) {
                ctx.strokeStyle = "rgba(0, 229, 255, 0.16)";
                ctx.lineWidth   = 13.0;
                ctx.lineCap     = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, activeEndAngle, angle0, false);
                ctx.stroke();

                var pGrad = ctx.createLinearGradient(
                    centerX + radius * Math.cos(angle0),
                    centerY + radius * Math.sin(angle0),
                    centerX + radius * Math.cos(activeEndAngle),
                    centerY + radius * Math.sin(activeEndAngle)
                );
                pGrad.addColorStop(0.0, batteryTempGauge.themeColor);
                pGrad.addColorStop(1.0, batteryTempGauge.themeColor);

                ctx.strokeStyle = pGrad;
                ctx.lineWidth   = 4.8;
                ctx.lineCap     = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, activeEndAngle, angle0, false);
                ctx.stroke();

                ctx.strokeStyle = "rgba(255, 255, 255, 0.7)";
                ctx.lineWidth   = 1.2;
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, activeEndAngle + 0.02, angle0 - 0.02, false);
                ctx.stroke();
            }

            // 4. Tip Indicator Dot
            var tipX = centerX + radius * Math.cos(activeEndAngle);
            var tipY = centerY + radius * Math.sin(activeEndAngle);

            var tipGlow = ctx.createRadialGradient(tipX, tipY, 0, tipX, tipY, 13);
            tipGlow.addColorStop(0.0, batteryTempGauge.themeColor);
            tipGlow.addColorStop(0.4, "transparent");
            tipGlow.addColorStop(1.0, "transparent");
            ctx.fillStyle = tipGlow;
            ctx.beginPath();
            ctx.arc(tipX, tipY, 13, 0, Math.PI * 2);
            ctx.fill();

            ctx.fillStyle = "#FFFFFF";
            ctx.beginPath();
            ctx.arc(tipX, tipY, 3.0, 0, Math.PI * 2);
            ctx.fill();

            // 5. Scale Ticks & Numbers (0°, 20°, 40°, 60°, 80°)
            var ticks = [
                { val: "80°", frac: 1.00 },
                { val: "60°", frac: 0.75 },
                { val: "40°", frac: 0.50 },
                { val: "20°", frac: 0.25 },
                { val: "0°",  frac: 0.00 }
            ];

            ctx.font = "11px sans-serif";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";

            for (var i = 0; i < ticks.length; i++) {
                var tFrac  = ticks[i].frac;
                var tAngle = angle0 - totalSweep * tFrac;

                var tickInR  = radius - 8;
                var tickOutR = radius + 2;
                var labelR   = radius - 18;

                var x1 = centerX + tickOutR * Math.cos(tAngle);
                var y1 = centerY + tickOutR * Math.sin(tAngle);
                var x2 = centerX + tickInR  * Math.cos(tAngle);
                var y2 = centerY + tickInR  * Math.sin(tAngle);

                ctx.strokeStyle = "#334155";
                ctx.lineWidth   = 1.2;
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();

                var lx = centerX + labelR * Math.cos(tAngle);
                var ly = centerY + labelR * Math.sin(tAngle);
                ctx.fillStyle = (tFrac <= activeFraction) ? "#CBD5E1" : "#475569";
                ctx.fillText(ticks[i].val, lx, ly);
            }

            // 6. Lower Zone: Thermometer Vector Icon + COLD
            var lowerAngle = angle0 + 0.10;
            var iconCenterX = centerX + (radius - 20) * Math.cos(lowerAngle);
            var iconCenterY = centerY + (radius - 20) * Math.sin(lowerAngle) + 4;

            ctx.save();
            ctx.translate(iconCenterX, iconCenterY);

            ctx.strokeStyle = "#64748B";
            ctx.lineWidth = 1.3;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(-2, -7); ctx.lineTo(-2, 1);
            ctx.arc(0, 4, 3.2, Math.PI * 0.7, Math.PI * 0.3, false);
            ctx.lineTo(2, -7);
            ctx.arc(0, -7, 2, 0, Math.PI, true);
            ctx.stroke();

            ctx.fillStyle = batteryTempGauge.themeColor;
            ctx.beginPath(); ctx.arc(0, 4, 2.0, 0, Math.PI * 2); ctx.fill();

            ctx.strokeStyle = batteryTempGauge.themeColor;
            ctx.lineWidth = 1.2;
            ctx.beginPath(); ctx.moveTo(0, -3); ctx.lineTo(0, 3); ctx.stroke();

            ctx.strokeStyle = "#475569";
            ctx.lineWidth = 1.0;
            ctx.beginPath();
            ctx.moveTo(3.5, -4); ctx.lineTo(5.5, -4);
            ctx.moveTo(3.5, -1); ctx.lineTo(5.5, -1);
            ctx.stroke();

            ctx.restore();

            ctx.font = "bold 10px sans-serif";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillStyle = "#64748B";
            ctx.fillText("COLD", iconCenterX - 10, iconCenterY);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // CENTER VALUE DISPLAY: BATTERY TEMP (32 °C) + TRIP STATS
    // ═══════════════════════════════════════════════════════════════
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        // Title row: BATTERY TEMP
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "BATTERY TEMP"
            font.pixelSize: 12
            font.weight: Font.Medium
            font.letterSpacing: 3.0
            font.capitalization: Font.AllUppercase
            font.family: "sans-serif"
            color: "#94A3B8"
            renderType: Text.NativeRendering
        }

        // Temperature number: 32 °C
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3

            Text {
                id: numVal
                text: Math.round(batteryTempGauge.batteryTemp).toString()
                font.pixelSize: 54
                font.weight: Font.Normal
                font.letterSpacing: 1.0
                font.family: "Menlo, Monaco, monospace"
                color: "#FFFFFF"
                renderType: Text.NativeRendering
            }

            Text {
                anchors.top: numVal.top
                anchors.topMargin: 6
                text: "°C"
                font.pixelSize: 18
                font.weight: Font.Normal
                font.family: "sans-serif"
                color: "#94A3B8"
                renderType: Text.NativeRendering
            }
        }

        // Operating Status: OPTIMAL
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OPTIMAL  ·  20°–45°C"
            font.pixelSize: 10
            font.weight: Font.Normal
            font.letterSpacing: 1.2
            font.family: "sans-serif"
            color: "#64748B"
            renderType: Text.NativeRendering
        }

        // Subtle divider line
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 130
            height: 1
            color: "#1E293B"
            anchors.topMargin: 2
            anchors.bottomMargin: 2
        }

        // Trip section
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Text {
                text: "TRIP A"
                font.pixelSize: 10
                font.weight: Font.Medium
                font.letterSpacing: 1.5
                font.family: "sans-serif"
                color: "#94A3B8"
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }

            Text {
                text: batteryTempGauge.tripKm.toFixed(1) + " km"
                font.pixelSize: 13
                font.weight: Font.Normal
                font.family: "Menlo, Monaco, monospace"
                color: "#CBD5E1"
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }
    }

    Behavior on batteryTemp {
        NumberAnimation { duration: 800; easing.type: Easing.InOutCubic }
    }

    onBatteryTempChanged:    gaugeCanvas.requestPaint()
    onThemeColorChanged:     gaugeCanvas.requestPaint()
    Component.onCompleted:   gaugeCanvas.requestPaint()
}
