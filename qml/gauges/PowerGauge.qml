import QtQuick
import QtQuick.Controls

Item {
    id: powerGauge
    width: parent.width * 0.28
    height: parent.height

    property real powerKw: 0.0            // Instantaneous motor power (0 – 300 kW)
    property real maxPowerKw: 300.0       // Maximum motor output (300 kW)
    property real regenValue: 0.0         // Regen braking level (0 - 50 kW)
    property bool regenActive: false
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

            var centerX = w * 0.96;
            var centerY = h * 0.50;
            var radius  = Math.min(w * 0.82, h * 0.44);

            var angle0   = Math.PI * 0.81;   // 0 kW (bottom-left)
            var angle300 = Math.PI * 1.19;   // 300 kW (top-left)
            var totalSweep = angle300 - angle0;

            var activeFraction = Math.max(0.0, Math.min(1.0, powerGauge.powerKw / powerGauge.maxPowerKw));
            var activeEndAngle = angle0 + totalSweep * activeFraction;

            // 1. Background Groove
            ctx.strokeStyle = "#101824";
            ctx.lineWidth   = 5.5;
            ctx.lineCap     = "round";
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, angle0, angle300, false);
            ctx.stroke();

            ctx.strokeStyle = "rgba(255, 255, 255, 0.03)";
            ctx.lineWidth   = 1.0;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius + 2.5, angle0, angle300, false);
            ctx.stroke();

            // 2. Inactive Upper Arc
            if (activeFraction < 1.0) {
                ctx.strokeStyle = "rgba(45, 60, 78, 0.55)";
                ctx.lineWidth   = 4.5;
                ctx.lineCap     = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, activeEndAngle, angle300, false);
                ctx.stroke();
            }

            // 3. REGEN Braking Zone
            var regenFrac      = 0.16;
            var regenDivAngle  = angle0 + totalSweep * regenFrac;

            var cInR  = radius - 8;
            var cOutR = radius + 6;
            ctx.strokeStyle = "#475569";
            ctx.lineWidth   = 1.6;
            ctx.beginPath();
            ctx.moveTo(centerX + cInR  * Math.cos(regenDivAngle), centerY + cInR  * Math.sin(regenDivAngle));
            ctx.lineTo(centerX + cOutR * Math.cos(regenDivAngle), centerY + cOutR * Math.sin(regenDivAngle));
            ctx.stroke();

            if (powerGauge.regenActive || powerGauge.regenValue > 0) {
                ctx.strokeStyle = "rgba(0, 229, 255, 0.65)";
                ctx.lineWidth   = 4.5;
                ctx.lineCap     = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, angle0, regenDivAngle, false);
                ctx.stroke();
            }

            // 4. Active Power Arc
            if (activeFraction > 0.005) {
                ctx.strokeStyle = "rgba(0, 229, 255, 0.16)";
                ctx.lineWidth   = 13.0;
                ctx.lineCap     = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, angle0, activeEndAngle, false);
                ctx.stroke();

                var pGrad = ctx.createLinearGradient(
                    centerX + radius * Math.cos(angle0),
                    centerY + radius * Math.sin(angle0),
                    centerX + radius * Math.cos(activeEndAngle),
                    centerY + radius * Math.sin(activeEndAngle)
                );
                pGrad.addColorStop(0.0, powerGauge.themeColor);
                pGrad.addColorStop(1.0, powerGauge.themeColor);

                ctx.strokeStyle = pGrad;
                ctx.lineWidth   = 4.8;
                ctx.lineCap     = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, angle0, activeEndAngle, false);
                ctx.stroke();

                if (activeEndAngle > angle0 + 0.06) {
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.7)";
                    ctx.lineWidth   = 1.2;
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, angle0 + 0.02, activeEndAngle - 0.02, false);
                    ctx.stroke();
                }

                // 5. Active Bead Indicator
                var tipX = centerX + radius * Math.cos(activeEndAngle);
                var tipY = centerY + radius * Math.sin(activeEndAngle);

                var tipGlow = ctx.createRadialGradient(tipX, tipY, 0, tipX, tipY, 13);
                tipGlow.addColorStop(0.0, powerGauge.themeColor);
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
            }

            // 6. Bottom REGEN Label
            ctx.font = "bold 10px Arial";
            ctx.textBaseline = "middle";
            var rAngle = angle0 + totalSweep * 0.07;
            var rX = centerX + (radius - 18) * Math.cos(rAngle);
            var rY = centerY + (radius - 18) * Math.sin(rAngle);
            ctx.fillStyle = powerGauge.regenActive ? powerGauge.themeColor : "#64748B";
            ctx.textAlign = "left";
            ctx.fillText("REGEN", rX, rY);

            // 7. Scale Ticks & Numbers (0, 100, 200, 300 kW)
            var ticks = [
                { val: "300", frac: 1.00 },
                { val: "200", frac: 0.67 },
                { val: "100", frac: 0.33 },
                { val: "0",   frac: 0.00 }
            ];

            ctx.font = "11px Arial";
            ctx.textAlign = "left";

            for (var i = 0; i < ticks.length; i++) {
                var tFrac  = ticks[i].frac;
                var tAngle = angle0 + totalSweep * tFrac;

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
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // CENTER VALUE DISPLAY: POWER OUTPUT (kW)
    // ═══════════════════════════════════════════════════════════════
    Column {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "POWER"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.letterSpacing: 4.0
            font.capitalization: Font.AllUppercase
            font.family: "Inter"
            color: "#94A3B8"
            renderType: Text.NativeRendering
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Text {
                id: numVal
                text: Math.round(powerGauge.powerKw).toString()
                font.pixelSize: 54
                font.weight: Font.Normal
                font.letterSpacing: 1.0
                font.family: "Inter"
                color: "#FFFFFF"
                renderType: Text.NativeRendering
            }

            Text {
                anchors.bottom: numVal.bottom
                anchors.bottomMargin: 8
                text: "kW"
                font.pixelSize: 17
                font.weight: Font.Medium
                font.family: "Inter"
                color: "#94A3B8"
                renderType: Text.NativeRendering
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "DUAL MOTOR"
            font.pixelSize: 10
            font.weight: Font.Medium
            font.letterSpacing: 1.5
            font.family: "Inter"
            color: "#64748B"
            renderType: Text.NativeRendering
        }
    }

    Behavior on powerKw {
        NumberAnimation { duration: 600; easing.type: Easing.InOutCubic }
    }
    Behavior on regenValue {
        NumberAnimation { duration: 500; easing.type: Easing.InOutCubic }
    }

    onPowerKwChanged:     gaugeCanvas.requestPaint()
    onRegenValueChanged:  gaugeCanvas.requestPaint()
    onRegenActiveChanged: gaugeCanvas.requestPaint()
    onThemeColorChanged:  gaugeCanvas.requestPaint()
    Component.onCompleted: gaugeCanvas.requestPaint()
}
