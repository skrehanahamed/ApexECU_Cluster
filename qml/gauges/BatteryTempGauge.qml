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

    // Trip & Odometer Telemetry
    property string tripMode: "TRIP A"    // "TRIP A", "TRIP B", or "ODO"
    property real tripAKm: 256.8
    property real tripBKm: 104.2
    property real odoKm: 12458.0

    signal cycleTripRequested()
    signal resetTripRequested()

    property string currentDisplayMode: tripMode
    property real holdProgress: 0.0
    property bool isHoldingReset: false

    function formattedDistance(mode) {
        if (mode === "TRIP A") {
            var valA = Math.min(9999.0, batteryTempGauge.tripAKm);
            return valA.toFixed(1) + " km";
        } else if (mode === "TRIP B") {
            var valB = Math.min(9999.0, batteryTempGauge.tripBKm);
            return valB.toFixed(1) + " km";
        } else {
            var valOdo = Math.min(999999, Math.round(batteryTempGauge.odoKm));
            return valOdo.toLocaleString() + " km";
        }
    }

    onTripModeChanged: {
        if (tripMode !== currentDisplayMode) {
            rollAnimation.restart();
        }
    }

    SequentialAnimation {
        id: rollAnimation
        // 1. Roll upwards out (tilts backward & moves up)
        ParallelAnimation {
            NumberAnimation { target: transY; property: "y"; to: -16; duration: 140; easing.type: Easing.InQuad }
            NumberAnimation { target: rot3D; property: "angle"; to: -70; duration: 140; easing.type: Easing.InQuad }
            NumberAnimation { target: rollItem; property: "opacity"; to: 0.0; duration: 120; easing.type: Easing.InQuad }
        }
        // 2. Swap text in hidden state and position at bottom
        ScriptAction {
            script: {
                batteryTempGauge.currentDisplayMode = batteryTempGauge.tripMode;
                transY.y = 16;
                rot3D.angle = 70;
            }
        }
        // 3. Roll upwards in from bottom to center
        ParallelAnimation {
            NumberAnimation { target: transY; property: "y"; to: 0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
            NumberAnimation { target: rot3D; property: "angle"; to: 0; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
            NumberAnimation { target: rollItem; property: "opacity"; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: resetFlashAnim
        ParallelAnimation {
            NumberAnimation { target: rollItem; property: "scale"; from: 1.0; to: 1.18; duration: 120; easing.type: Easing.OutQuad }
            ColorAnimation { target: tripKmLabel; property: "color"; to: batteryTempGauge.themeColor; duration: 120 }
        }
        ParallelAnimation {
            NumberAnimation { target: rollItem; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBounce }
            ColorAnimation { target: tripKmLabel; property: "color"; to: "#CBD5E1"; duration: 250 }
        }
    }

    Timer {
        id: holdResetTimer
        interval: 30
        repeat: true
        running: batteryTempGauge.isHoldingReset
        onTriggered: {
            if (batteryTempGauge.holdProgress < 1.0) {
                batteryTempGauge.holdProgress += 0.04; // ~750ms to trigger reset
                if (batteryTempGauge.holdProgress >= 1.0) {
                    batteryTempGauge.holdProgress = 1.0;
                    holdResetTimer.stop();
                    if (batteryTempGauge.tripMode !== "ODO") {
                        batteryTempGauge.resetTripRequested();
                        resetFlashAnim.restart();
                    }
                }
            }
        }
    }

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

                if (angle0 - activeEndAngle > 0.06) {
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.7)";
                    ctx.lineWidth   = 1.2;
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, activeEndAngle + 0.02, angle0 - 0.02, false);
                    ctx.stroke();
                }
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

            ctx.font = "11px Arial";
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

            ctx.font = "bold 10px Arial";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.fillStyle = "#64748B";
            ctx.fillText("COLD", iconCenterX - 10, iconCenterY);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // CENTER VALUE DISPLAY: BATTERY TEMP (32 °C) + TRIP COMPUTER
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
            font.weight: Font.DemiBold
            font.letterSpacing: 3.0
            font.capitalization: Font.AllUppercase
            font.family: "Inter"
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
                font.family: "Inter"
                color: "#FFFFFF"
                renderType: Text.NativeRendering
            }

            Text {
                anchors.top: numVal.top
                anchors.topMargin: 6
                text: "°C"
                font.pixelSize: 18
                font.weight: Font.Medium
                font.family: "Inter"
                color: "#94A3B8"
                renderType: Text.NativeRendering
            }
        }

        // Operating Status: OPTIMAL
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OPTIMAL  ·  20°–45°C"
            font.pixelSize: 10
            font.weight: Font.Medium
            font.letterSpacing: 1.2
            font.family: "Inter"
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

        // ═══════════════════════════════════════════════════════════
        // TRIP / ODO SECTION: PURE ORIGINAL DESIGN WITH UPWARD ROLL ANIMATION
        // ═══════════════════════════════════════════════════════════
        Item {
            id: tripContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: 160
            height: 24
            clip: true

            Item {
                id: rollItem
                anchors.fill: parent

                transform: [
                    Rotation {
                        id: rot3D
                        origin.x: rollItem.width / 2
                        origin.y: rollItem.height / 2
                        axis { x: 1; y: 0; z: 0 }
                        angle: 0
                    },
                    Translate {
                        id: transY
                        y: 0
                    }
                ]

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: tripModeLabel
                        text: batteryTempGauge.currentDisplayMode
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                        font.family: "Inter"
                        color: tripMouseArea.containsMouse ? batteryTempGauge.themeColor : "#94A3B8"
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        id: tripKmLabel
                        text: batteryTempGauge.formattedDistance(batteryTempGauge.currentDisplayMode)
                        font.pixelSize: 13
                        font.weight: Font.Normal
                        font.family: "Inter"
                        color: tripMouseArea.containsMouse ? "#FFFFFF" : "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Interactive Click & Hold-to-Reset Area
            MouseArea {
                id: tripMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onPressed: {
                    batteryTempGauge.holdProgress = 0.0;
                    batteryTempGauge.isHoldingReset = true;
                }

                onReleased: {
                    if (batteryTempGauge.isHoldingReset) {
                        batteryTempGauge.isHoldingReset = false;
                        if (batteryTempGauge.holdProgress < 1.0) {
                            // Short click: Switch TRIP A -> TRIP B -> ODO with upward rotation
                            batteryTempGauge.cycleTripRequested();
                        }
                        batteryTempGauge.holdProgress = 0.0;
                    }
                }

                onCanceled: {
                    batteryTempGauge.isHoldingReset = false;
                    batteryTempGauge.holdProgress = 0.0;
                }
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



