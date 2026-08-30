import QtQuick
import QtQuick.Controls

Item {
    id: bottomInfoBar
    width: parent.width
    height: 40

    property real batteryPercent: 72.0
    property real rangeKm: 428.0
    property string gear: "D"
    property int altitudeM: 1250
    property string heading: "SW"
    property string themeColor: "#00e5ff"
    property string driveMode: "COMFORT"
    property real pitchDeg: 8.0
    property real rollDeg: -3.0
    readonly property bool isOffRoad: driveMode === "OFF-ROAD"

    property real tpmsFl: 33.0
    property real tpmsFr: 33.0
    property real tpmsRl: 33.0
    property real tpmsRr: 33.0

    function getHeadingAngle(hdg) {
        if (typeof hdg === "number") return hdg;
        if (!hdg) return 225;
        switch (hdg.toString().toUpperCase()) {
            case "N": return 0;
            case "NNE": return 22.5;
            case "NE": return 45;
            case "ENE": return 67.5;
            case "E": return 90;
            case "ESE": return 112.5;
            case "SE": return 135;
            case "SSE": return 157.5;
            case "S": return 180;
            case "SSW": return 202.5;
            case "SW": return 225;
            case "WSW": return 247.5;
            case "W": return 270;
            case "WNW": return 292.5;
            case "NW": return 315;
            case "NNW": return 337.5;
            default: return 225;
        }
    }

    // ─── LEFT: Battery Status [🔋] 72% --- 428 km ───
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Battery outline + fill icon
        Item {
            width: 24
            height: 12
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.left: parent.left
                width: 21
                height: 12
                radius: 2.5
                color: "transparent"
                border.color: bottomInfoBar.themeColor
                border.width: 1.3

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: (parent.width - 4) * (bottomInfoBar.batteryPercent / 100.0)
                    height: parent.height - 4
                    radius: 1
                    color: bottomInfoBar.themeColor
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 5
                radius: 0.8
                color: bottomInfoBar.themeColor
            }
        }

        // 72%
        Text {
            text: Math.round(bottomInfoBar.batteryPercent) + "%"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.family: "Inter"
            color: "#FFFFFF"
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }

        // Segmented cyan dashes
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Repeater {
                model: 8
                Rectangle {
                    width: 6
                    height: 2.5
                    radius: 1
                    color: (index < Math.round(bottomInfoBar.batteryPercent / 12.5)) ? bottomInfoBar.themeColor : "#1E293B"
                }
            }
        }

        // 428 km
        Text {
            text: Math.round(bottomInfoBar.rangeKm) + " km"
            font.pixelSize: 13
            font.weight: Font.Normal
            font.letterSpacing: 0.5
            font.family: "Inter"
            color: "#94A3B8"
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }
    }

    // ─── CENTER: Gear Selector P R N D (Strictly in the Middle) ───
    Row {
        id: gearRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 24

        Repeater {
            model: ["P", "R", "N", "D"]
            Item {
                width: 18
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: gearText
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: 15
                    font.weight: (modelData === bottomInfoBar.gear) ? Font.Bold : Font.Normal
                    font.letterSpacing: 1.0
                    font.family: "Inter"
                    color: (modelData === bottomInfoBar.gear) ? bottomInfoBar.themeColor : "#475569"
                    renderType: Text.NativeRendering
                }

                // Cyan underline for selected gear
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 14
                    height: 2
                    radius: 1
                    color: bottomInfoBar.themeColor
                    visible: modelData === bottomInfoBar.gear
                }
            }
        }
    }

    // ─── TPMS: Thin, Light-Themed Tire Pressure Indicator (To the Side of P R N D) ───
    Item {
        id: miniTpms
        anchors.left: gearRow.right
        anchors.leftMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        width: 106
        height: 50

        // Light, bright readable colors (PSI thresholds: Normal 30-38, Low <30, Crit <22)
        function getTireColor(val) {
            if (isNaN(val) || val < 0) return "#94A3B8"; // Fault Light Gray
            if (val < 22) return "#F87171";              // Critical Light Coral Red
            if (val < 30 || val > 38) return "#FBBF24";  // Warning Bright Amber
            return "#F8FAFC";                            // Normal Bright Pure White
        }

        function getWheelSpotColor(val) {
            if (isNaN(val) || val < 0) return "#64748B";
            if (val < 22) return "#EF4444";              // Vivid Red
            if (val < 30 || val > 38) return "#F59E0B";  // Vivid Amber
            return "#00E5FF";                            // Luminous Cyan / Mint
        }

        function formatTire(val) {
            if (isNaN(val) || val < 0) return "--";
            return Math.round(val);
        }

        // X-Ray Transparent Chassis Vehicle with visible wheels
        Image {
            id: miniCarImg
            anchors.centerIn: parent
            width: 38
            height: 50
            source: "../../assets/vehicles/tpms_chassis_topview.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 1.0

            // 4 Ultra-Thin Glowing Tire Overlays tucked strictly inside the 4 tires
            // 1. Front-Left Tire (FL)
            Rectangle {
                x: 5.0
                y: 5.5
                width: 5.2
                height: 10.5
                radius: 2.6
                color: (bottomInfoBar.tpmsFl < 30 || bottomInfoBar.tpmsFl > 38) ? Qt.rgba(miniTpms.getWheelSpotColor(bottomInfoBar.tpmsFl) === "#EF4444" ? 0.9 : 0.9, 0.2, 0.2, 0.25) : "transparent"
                border.color: miniTpms.getWheelSpotColor(bottomInfoBar.tpmsFl)
                border.width: 0.75
                opacity: (bottomInfoBar.tpmsFl < 30 || bottomInfoBar.tpmsFl > 38) ? 0.95 : 0.55
            }

            // 2. Front-Right Tire (FR)
            Rectangle {
                x: parent.width - 10.2
                y: 5.5
                width: 5.2
                height: 10.5
                radius: 2.6
                color: (bottomInfoBar.tpmsFr < 30 || bottomInfoBar.tpmsFr > 38) ? Qt.rgba(miniTpms.getWheelSpotColor(bottomInfoBar.tpmsFr) === "#EF4444" ? 0.9 : 0.9, 0.2, 0.2, 0.25) : "transparent"
                border.color: miniTpms.getWheelSpotColor(bottomInfoBar.tpmsFr)
                border.width: 0.75
                opacity: (bottomInfoBar.tpmsFr < 30 || bottomInfoBar.tpmsFr > 38) ? 0.95 : 0.55
            }

            // 3. Rear-Left Tire (RL)
            Rectangle {
                x: 5.0
                y: parent.height - 16.0
                width: 5.2
                height: 10.5
                radius: 2.6
                color: (bottomInfoBar.tpmsRl < 30 || bottomInfoBar.tpmsRl > 38) ? Qt.rgba(miniTpms.getWheelSpotColor(bottomInfoBar.tpmsRl) === "#EF4444" ? 0.9 : 0.9, 0.2, 0.2, 0.25) : "transparent"
                border.color: miniTpms.getWheelSpotColor(bottomInfoBar.tpmsRl)
                border.width: 0.75
                opacity: (bottomInfoBar.tpmsRl < 30 || bottomInfoBar.tpmsRl > 38) ? 0.95 : 0.55
            }

            // 4. Rear-Right Tire (RR)
            Rectangle {
                x: parent.width - 10.2
                y: parent.height - 16.0
                width: 5.2
                height: 10.5
                radius: 2.6
                color: (bottomInfoBar.tpmsRr < 30 || bottomInfoBar.tpmsRr > 38) ? Qt.rgba(miniTpms.getWheelSpotColor(bottomInfoBar.tpmsRr) === "#EF4444" ? 0.9 : 0.9, 0.2, 0.2, 0.25) : "transparent"
                border.color: miniTpms.getWheelSpotColor(bottomInfoBar.tpmsRr)
                border.width: 0.75
                opacity: (bottomInfoBar.tpmsRr < 30 || bottomInfoBar.tpmsRr > 38) ? 0.95 : 0.55
            }
        }

        // 4 Crisp, legible pressure numbers alongside corresponding tires
        // Front-Left (FL)
        Text {
            anchors.right: miniCarImg.left
            anchors.rightMargin: 4
            anchors.verticalCenter: miniCarImg.top
            anchors.verticalCenterOffset: 11
            text: miniTpms.formatTire(bottomInfoBar.tpmsFl)
            font.pixelSize: 11
            font.weight: Font.Medium
            font.family: "Inter"
            color: miniTpms.getTireColor(bottomInfoBar.tpmsFl)
            renderType: Text.NativeRendering
        }

        // Front-Right (FR)
        Text {
            anchors.left: miniCarImg.right
            anchors.leftMargin: 4
            anchors.verticalCenter: miniCarImg.top
            anchors.verticalCenterOffset: 11
            text: miniTpms.formatTire(bottomInfoBar.tpmsFr)
            font.pixelSize: 11
            font.weight: Font.Medium
            font.family: "Inter"
            color: miniTpms.getTireColor(bottomInfoBar.tpmsFr)
            renderType: Text.NativeRendering
        }

        // Rear-Left (RL)
        Text {
            anchors.right: miniCarImg.left
            anchors.rightMargin: 4
            anchors.verticalCenter: miniCarImg.bottom
            anchors.verticalCenterOffset: -11
            text: miniTpms.formatTire(bottomInfoBar.tpmsRl)
            font.pixelSize: 11
            font.weight: Font.Medium
            font.family: "Inter"
            color: miniTpms.getTireColor(bottomInfoBar.tpmsRl)
            renderType: Text.NativeRendering
        }

        // Rear-Right (RR)
        Text {
            anchors.left: miniCarImg.right
            anchors.leftMargin: 4
            anchors.verticalCenter: miniCarImg.bottom
            anchors.verticalCenterOffset: -11
            text: miniTpms.formatTire(bottomInfoBar.tpmsRr)
            font.pixelSize: 11
            font.weight: Font.Medium
            font.family: "Inter"
            color: miniTpms.getTireColor(bottomInfoBar.tpmsRr)
            renderType: Text.NativeRendering
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // ─── RIGHT: Premium Compact Navigation & Terrain Module ───
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: navTerrainModule
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        height: 32

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 18

            // 1. COMPASS (High-Visibility Faceted Needle + Cardinal Dial + Heading)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // High-Legibility Compass Dial
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: "#0F172A"
                    border.color: "#334155"
                    border.width: 1.2
                    anchors.verticalCenter: parent.verticalCenter

                    // Subtle Cardinal Ticks (N, E, S, W)
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset();
                            var cx = 12, cy = 12;

                            // North Accent Dot
                            ctx.fillStyle = "#38BDF8";
                            ctx.beginPath(); ctx.arc(cx, 3.5, 1.2, 0, Math.PI * 2); ctx.fill();

                            // E, S, W Ticks
                            ctx.fillStyle = "#475569";
                            ctx.beginPath(); ctx.arc(cx + 8.5, cy, 1.0, 0, Math.PI * 2); ctx.fill();
                            ctx.beginPath(); ctx.arc(cx, cy + 8.5, 1.0, 0, Math.PI * 2); ctx.fill();
                            ctx.beginPath(); ctx.arc(cx - 8.5, cy, 1.0, 0, Math.PI * 2); ctx.fill();
                        }
                    }

                    // Rotating Precision 3D Faceted Compass Needle
                    Item {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        rotation: bottomInfoBar.getHeadingAngle(bottomInfoBar.heading)
                        Behavior on rotation { RotationAnimation { duration: 350; direction: RotationAnimation.Shortest } }

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset();
                                var cx = 10, cy = 10;

                                // 1. North Tip - Right Facet (Electric Cyan Glow)
                                ctx.fillStyle = "#00E5FF";
                                ctx.beginPath();
                                ctx.moveTo(cx, 2);
                                ctx.lineTo(cx + 3.8, cy);
                                ctx.lineTo(cx, cy - 2);
                                ctx.closePath();
                                ctx.fill();

                                // 2. North Tip - Left Facet (Light Sky Blue Highlight)
                                ctx.fillStyle = "#38BDF8";
                                ctx.beginPath();
                                ctx.moveTo(cx, 2);
                                ctx.lineTo(cx - 3.8, cy);
                                ctx.lineTo(cx, cy - 2);
                                ctx.closePath();
                                ctx.fill();

                                // 3. South Base - Right Facet (Muted Slate)
                                ctx.fillStyle = "#64748B";
                                ctx.beginPath();
                                ctx.moveTo(cx, 18);
                                ctx.lineTo(cx + 3.8, cy);
                                ctx.lineTo(cx, cy + 2);
                                ctx.closePath();
                                ctx.fill();

                                // 4. South Base - Left Facet (Dark Slate)
                                ctx.fillStyle = "#475569";
                                ctx.beginPath();
                                ctx.moveTo(cx, 18);
                                ctx.lineTo(cx - 3.8, cy);
                                ctx.lineTo(cx, cy + 2);
                                ctx.closePath();
                                ctx.fill();

                                // 5. Center Pivot Dot
                                ctx.fillStyle = "#0F172A";
                                ctx.strokeStyle = "#00E5FF";
                                ctx.lineWidth = 1.0;
                                ctx.beginPath();
                                ctx.arc(cx, cy, 2.2, 0, Math.PI * 2);
                                ctx.fill();
                                ctx.stroke();
                            }
                        }
                    }
                }

                // Heading text (e.g. SW) - Bold High Contrast
                Text {
                    text: bottomInfoBar.heading
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    font.family: "Inter"
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                    renderType: Text.NativeRendering
                }
            }

            // 2. ELEVATION (Mountain Icon + 1250 m + ELEVATION label)
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Row {
                    spacing: 5
                    anchors.left: parent.left

                    // Small geometric mountain icon
                    Canvas {
                        width: 12
                        height: 10
                        anchors.verticalCenter: parent.verticalCenter
                        onPaint: {
                            var ctx = getContext("2d"); ctx.reset();
                            ctx.strokeStyle = "#94A3B8"; ctx.lineWidth = 1.2;
                            ctx.lineCap = "round"; ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.moveTo(1, 9); ctx.lineTo(5, 2); ctx.lineTo(8, 7); ctx.lineTo(11, 9);
                            ctx.stroke();
                        }
                    }

                    Text {
                        text: bottomInfoBar.altitudeM + " m"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.4
                        font.family: "Inter"
                        color: "#F8FAFC"
                        renderType: Text.NativeRendering
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    text: "ELEVATION"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    font.family: "Inter"
                    color: "#64748B"
                    anchors.left: parent.left
                    renderType: Text.NativeRendering
                }
            }

            // 3. OFF-ROAD PITCH & ROLL EXPANSION (Only in OFF-ROAD mode, no vertical bar)
            Row {
                visible: bottomInfoBar.isOffRoad
                opacity: bottomInfoBar.isOffRoad ? 1.0 : 0.0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Behavior on opacity { NumberAnimation { duration: 250 } }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Row {
                        spacing: 5
                        Text {
                            text: "PITCH"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                            color: "#64748B"
                            font.family: "Inter"
                            width: 28
                        }
                        Text {
                            text: (bottomInfoBar.pitchDeg >= 0 ? "+" : "") + Math.round(bottomInfoBar.pitchDeg) + "°"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            font.family: "Inter"
                            color: "#38BDF8"
                        }
                    }

                    Row {
                        spacing: 5
                        Text {
                            text: "ROLL"
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                            color: "#64748B"
                            font.family: "Inter"
                            width: 28
                        }
                        Text {
                            text: (bottomInfoBar.rollDeg >= 0 ? "+" : "") + Math.round(bottomInfoBar.rollDeg) + "°"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            font.family: "Inter"
                            color: "#38BDF8"
                        }
                    }
                }
            }
        }
    }
}
