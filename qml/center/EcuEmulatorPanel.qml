import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/****************************************************************************
** Component: EcuEmulatorPanel.qml
** Role: Full Interactive ECU & Vehicle Telemetry Simulation Control Bench
** Features:
**   - Real-time sliders for Speed, Power (kW), Battery SoC (%), Battery Temp (°C)
**   - Gear selector (P R N D) & Drive Mode selector (COMFORT, SPORT, ECO, OFF-ROAD)
**   - 18 Individual Toggle Switches for all ISO 7000 Telltale Warning Alerts
**   - Turn Indicators & Hazard Flasher controls
**   - One-touch Scenario Presets (Self-Test, Clean Cruise, Sport Track, Overheat)
****************************************************************************/

Rectangle {
    id: emulatorPanel
    color: "#0B111A"
    clip: true

    // Target telemetry bindings (wired to DrivingCluster)
    property var clusterTarget: null

    // Tab tracking
    property int currentTab: 0 // 0: Dynamics, 1: Battery & Thermal, 2: Telltales, 3: Presets

    // Header Bar
    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 46
        color: "#161E2E"

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Rectangle {
                width: 10; height: 10; radius: 5
                color: "#10B981"
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                }
            }

            Text {
                text: "APEX ECU TELEMETRY SIMULATOR ✥"
                font.pixelSize: 12
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                font.family: "sans-serif"
                color: "#F8FAFC"
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 58
                height: 17
                radius: 4
                color: "#0284C7"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "DRAG ME"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }
            }
        }

        // Close Button (×)
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 26; height: 26; radius: 13
            color: closeMouse.containsMouse ? "#EF4444" : "#1E293B"
            z: 10

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: "#FFFFFF"
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (clusterTarget) {
                        clusterTarget.emulatorOpen = false;
                    } else {
                        emulatorPanel.visible = false;
                    }
                }
            }
        }
    }

    // Tab Navigation Bar
    Row {
        id: tabBar
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 38
        spacing: 0

        Repeater {
            model: [
                { title: "🚗 Dynamics",       idx: 0 },
                { title: "🔋 Battery",        idx: 1 },
                { title: "⚠️ Telltales",      idx: 2 },
                { title: "🚨 Warning Cards",  idx: 4 },
                { title: "⚡ Scenarios",      idx: 3 }
            ]

            Rectangle {
                width: emulatorPanel.width / 5
                height: 38
                color: emulatorPanel.currentTab === modelData.idx ? "#1E293B" : "#0F172A"
                border.color: "#1E293B"
                border.width: 0.5

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    color: emulatorPanel.currentTab === modelData.idx ? "#00e5ff" : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData.title
                    font.pixelSize: 11
                    font.weight: emulatorPanel.currentTab === modelData.idx ? Font.Bold : Font.Normal
                    color: emulatorPanel.currentTab === modelData.idx ? "#00e5ff" : "#94A3B8"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: emulatorPanel.currentTab = modelData.idx
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 0: DRIVING DYNAMICS & POWERTRAIN
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab0View
        visible: emulatorPanel.currentTab === 0
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 16

            // Speed Control Slider
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Text { text: "Vehicle Speed"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { Layout.fillWidth: true; width: parent.width - 180 }
                    Text {
                        text: (clusterTarget ? Math.round(clusterTarget.speedValue) : 87) + " km/h"
                        font.pixelSize: 14; font.weight: Font.Bold; color: "#00e5ff"
                    }
                }

                Slider {
                    width: parent.width
                    from: 0
                    to: 260
                    value: clusterTarget ? clusterTarget.speedValue : 87
                    stepSize: 1
                    onMoved: {
                        if (clusterTarget) {
                            if (value > 0 && (clusterTarget.currentGear === "P" || clusterTarget.currentGear === "N")) {
                                clusterTarget.currentGear = "D";
                            }
                            clusterTarget.speedValue = value;
                        }
                    }
                }
            }

            // Power Output Slider (-50 kW Regen to +300 kW Full Throttle)
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Text { text: "Powertrain Demand (kW / Regen)"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { width: parent.width - 270 }
                    Text {
                        text: (clusterTarget ? Math.round(clusterTarget.powerKw) : 145) + " kW"
                        font.pixelSize: 14; font.weight: Font.Bold
                        color: (clusterTarget && clusterTarget.powerKw < 0) ? "#10B981" : "#00e5ff"
                    }
                }

                Slider {
                    width: parent.width
                    from: -50
                    to: 300
                    value: clusterTarget ? clusterTarget.powerKw : 145
                    stepSize: 5
                    onMoved: { if (clusterTarget) clusterTarget.powerKw = value; }
                }
            }

            // Gear Selector Buttons (P R N D)
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Transmission Gear"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }

                Row {
                    spacing: 12
                    Repeater {
                        model: ["P", "R", "N", "D"]
                        Rectangle {
                            width: 60; height: 34; radius: 6
                            color: (clusterTarget && clusterTarget.currentGear === modelData) ? "#0284C7" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.currentGear === modelData) ? "#38BDF8" : "#334155"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: 14; font.weight: Font.Bold
                                color: (clusterTarget && clusterTarget.currentGear === modelData) ? "#FFFFFF" : "#94A3B8"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { if (clusterTarget) clusterTarget.currentGear = modelData; }
                            }
                        }
                    }
                }
            }

            // Drive Modes (COMFORT, SPORT, ECO, OFF-ROAD)
            Column {
                width: parent.width
                spacing: 8
                Text { text: "Drive Mode Vehicle Character"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }

                Row {
                    spacing: 12
                    width: parent.width
                    Repeater {
                        model: [
                            { name: "COMFORT",  col: "#00e5ff", img: "../../assets/modes/mode_card_comfort.png" },
                            { name: "SPORT",    col: "#EF4444", img: "../../assets/modes/mode_card_sport.png" },
                            { name: "ECO",      col: "#10B981", img: "../../assets/modes/mode_card_eco.png" },
                            { name: "OFF-ROAD", col: "#F59E0B", img: "../../assets/modes/mode_card_offroad.png" }
                        ]
                        Item {
                            width: (parent.width - 36) / 4
                            height: 140

                            Image {
                                anchors.fill: parent
                                source: modelData.img
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                opacity: (clusterTarget && clusterTarget.currentMode === modelData.name) ? 1.0 : 0.40
                                scale: (clusterTarget && clusterTarget.currentMode === modelData.name) ? 1.04 : 0.95

                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        for (var i = 0; i < clusterTarget.driveModes.length; i++) {
                                            if (clusterTarget.driveModes[i] === modelData.name) {
                                                clusterTarget.triggerModeChange(i);
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Speed Limit Sign Selector
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Road Speed Limit"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }

                Row {
                    spacing: 10
                    Repeater {
                        model: [30, 50, 80, 100, 120]
                        Rectangle {
                            width: 44; height: 32; radius: 6
                            color: (clusterTarget && clusterTarget.speedLimit === modelData) ? "#DC2626" : "#1E293B"
                            border.color: "#475569"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.toString()
                                font.pixelSize: 13; font.weight: Font.Bold
                                color: "#FFFFFF"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { if (clusterTarget) clusterTarget.speedLimit = modelData; }
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // DRIVER ASSIST (ADAS) SYSTEM & TRACTION RADAR
            // ═══════════════════════════════════════════════════════════════
            Rectangle { width: parent.width; height: 1; color: "#334155" }

            Column {
                width: parent.width
                spacing: 10

                Row {
                    width: parent.width
                    Text { text: "🛡️ DRIVER ASSIST SYSTEM"; font.pixelSize: 13; font.weight: Font.Bold; color: "#00e5ff" }
                    Item { width: parent.width - 270 }
                    Rectangle {
                        width: 110; height: 28; radius: 6
                        color: (clusterTarget && clusterTarget.adasActive) ? "#0284C7" : "#334155"
                        border.color: (clusterTarget && clusterTarget.adasActive) ? "#38BDF8" : "#475569"
                        border.width: 1.5

                        Text {
                            anchors.centerIn: parent
                            text: (clusterTarget && clusterTarget.adasActive) ? "ASSIST: ON" : "ASSIST: OFF"
                            font.pixelSize: 11; font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (clusterTarget) clusterTarget.adasActive = !clusterTarget.adasActive; }
                        }
                    }
                }

                // Lead Vehicle Distance Slider
                Column {
                    width: parent.width
                    spacing: 4
                    Row {
                        width: parent.width
                        Text { text: "Lead Vehicle Following Distance"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }
                        Item { width: parent.width - 260 }
                        Text {
                            text: (clusterTarget ? clusterTarget.adasLeadDistance.toFixed(1) : "38.5") + " m"
                            font.pixelSize: 12; font.weight: Font.Bold
                            color: "#00e5ff"
                        }
                    }
                    Slider {
                        width: parent.width
                        from: 10
                        to: 90
                        value: clusterTarget ? clusterTarget.adasLeadDistance : 38.5
                        stepSize: 0.5
                        onMoved: { if (clusterTarget) clusterTarget.adasLeadDistance = value; }
                    }
                }

                // Obstruction Type Selector (Car, Sedan, Hatchback, Motorcycle, Bicycle, Pedestrian)
                Column {
                    width: parent.width
                    spacing: 6

                    Text { text: "Front Obstruction Type"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }

                    Grid {
                        columns: 3
                        spacing: 8
                        width: parent.width

                        Repeater {
                            model: [
                                { id: "car",        name: "🚘 Sports Car" },
                                { id: "sedan",      name: "🚗 Sedan" },
                                { id: "hatchback",  name: "🚙 Hatchback" },
                                { id: "motorcycle", name: "🏍️ Motorcycle" },
                                { id: "bicycle",    name: "🚴 Bicycle" },
                                { id: "pedestrian", name: "🚶 Pedestrian" }
                            ]

                            Rectangle {
                                width: (parent.width - 16) / 3
                                height: 32
                                radius: 6
                                color: (clusterTarget && clusterTarget.adasObstacleType === modelData.id) ? "#0284C7" : "#1E293B"
                                border.color: (clusterTarget && clusterTarget.adasObstacleType === modelData.id) ? "#38BDF8" : "#475569"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (clusterTarget) {
                                            clusterTarget.adasObstacleType = modelData.id;
                                            clusterTarget.adasLeadVehicle = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Pass-By & Cruising Mode Selector
                Column {
                    width: parent.width
                    spacing: 6

                    Text { text: "Highway Traffic Simulation Mode"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }

                    Row {
                        spacing: 8
                        width: parent.width

                        Repeater {
                            model: [
                                { id: "both",   name: "🔄 Both Lanes Pass" },
                                { id: "left",   name: "⬅️ Left Pass-By" },
                                { id: "right",  name: "➡️ Right Pass-By" },
                                { id: "steady", name: "⏸️ Steady Pacing" }
                            ]

                            Rectangle {
                                width: (parent.width - 24) / 4
                                height: 32
                                radius: 6
                                color: (clusterTarget && clusterTarget.adasPassByMode === modelData.id) ? "#059669" : "#1E293B"
                                border.color: (clusterTarget && clusterTarget.adasPassByMode === modelData.id) ? "#34D399" : "#475569"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (clusterTarget) {
                                            clusterTarget.adasPassByMode = modelData.id;
                                            clusterTarget.adasPassByEnabled = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Environment Scenery Selector
                Column {
                    width: parent.width
                    spacing: 6

                    Text { text: "Cockpit Environment Scenery"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }

                    Row {
                        spacing: 8
                        width: parent.width

                        Repeater {
                            model: [
                                { id: "mountain", name: "🏔️ Mountain Pass" },
                                { id: "city",     name: "🌃 City Skyline" },
                                { id: "coastal",  name: "🌅 Coastal Sunset" }
                            ]

                            Rectangle {
                                width: (parent.width - 16 - 120) / 3
                                height: 32
                                radius: 6
                                color: (clusterTarget && clusterTarget.activeBackground === modelData.id) ? "#7C3AED" : "#1E293B"
                                border.color: (clusterTarget && clusterTarget.activeBackground === modelData.id) ? "#A78BFA" : "#475569"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (clusterTarget) {
                                            clusterTarget.autoCycleBackground = false;
                                            clusterTarget.activeBackground = modelData.id;
                                        }
                                    }
                                }
                            }
                        }

                        // Auto-Cycle Dynamic Map Button
                        Rectangle {
                            width: 120
                            height: 32
                            radius: 6
                            color: (clusterTarget && clusterTarget.autoCycleBackground) ? "#D97706" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.autoCycleBackground) ? "#FBBF24" : "#475569"

                            Text {
                                anchors.centerIn: parent
                                text: (clusterTarget && clusterTarget.autoCycleBackground) ? "🔄 Auto Cycle: ON" : "🔄 Auto Cycle"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        clusterTarget.autoCycleBackground = !clusterTarget.autoCycleBackground;
                                    }
                                }
                            }
                        }
                    }
                }

                // Traffic Simulation Toggles
                Row {
                    spacing: 12

                    Rectangle {
                        width: 140; height: 32; radius: 6
                        color: (clusterTarget && clusterTarget.adasLeadVehicle) ? "#0369A1" : "#1E293B"
                        border.color: (clusterTarget && clusterTarget.adasLeadVehicle) ? "#38BDF8" : "#475569"
                        Text {
                            anchors.centerIn: parent
                            text: (clusterTarget && clusterTarget.adasLeadVehicle) ? "🎯 Front Obstacle: ON" : "🎯 Front Obstacle: OFF"
                            font.pixelSize: 11; font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (clusterTarget) clusterTarget.adasLeadVehicle = !clusterTarget.adasLeadVehicle; }
                        }
                    }

                    Rectangle {
                        width: 140; height: 32; radius: 6
                        color: (clusterTarget && clusterTarget.adasRightTraffic) ? "#1E40AF" : "#1E293B"
                        border.color: (clusterTarget && clusterTarget.adasRightTraffic) ? "#60A5FA" : "#475569"
                        Text {
                            anchors.centerIn: parent
                            text: (clusterTarget && clusterTarget.adasRightTraffic) ? "🏍️ Right Lane: ON" : "🏍️ Right Lane: OFF"
                            font.pixelSize: 11; font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (clusterTarget) clusterTarget.adasRightTraffic = !clusterTarget.adasRightTraffic; }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 1: BATTERY & THERMAL
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab1View
        visible: emulatorPanel.currentTab === 1
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 18

            // Battery State of Charge (%)
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Text { text: "High-Voltage Battery SoC"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { width: parent.width - 240 }
                    Text {
                        text: (clusterTarget ? Math.round(clusterTarget.batteryPercent) : 72) + " % (" + (clusterTarget ? Math.round(clusterTarget.rangeKm) : 428) + " km)"
                        font.pixelSize: 14; font.weight: Font.Bold; color: "#10B981"
                    }
                }

                Slider {
                    width: parent.width
                    from: 0
                    to: 100
                    value: clusterTarget ? clusterTarget.batteryPercent : 72
                    stepSize: 1
                    onMoved: {
                        if (clusterTarget) {
                            clusterTarget.batteryPercent = value;
                            clusterTarget.rangeKm = Math.round(value * 5.95);
                        }
                    }
                }
            }

            // Battery Temperature (0°C to 80°C)
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Text { text: "Battery Pack Temperature (°C)"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { width: parent.width - 250 }
                    Text {
                        text: (clusterTarget ? Math.round(clusterTarget.batteryTemp) : 32) + " °C"
                        font.pixelSize: 14; font.weight: Font.Bold
                        color: (clusterTarget && clusterTarget.batteryTemp > 55) ? "#EF4444" : "#00e5ff"
                    }
                }

                Slider {
                    width: parent.width
                    from: 0
                    to: 80
                    value: clusterTarget ? clusterTarget.batteryTemp : 32
                    stepSize: 1
                    onMoved: { if (clusterTarget) clusterTarget.batteryTemp = value; }
                }
            }

            // Ambient Outside Temp (-10°C to 45°C)
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Text { text: "Ambient Temperature (°C)"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { width: parent.width - 230 }
                    Text {
                        text: (clusterTarget ? clusterTarget.ambientTemp : 24) + " °C"
                        font.pixelSize: 14; font.weight: Font.Bold; color: "#E2E8F0"
                    }
                }

                Slider {
                    width: parent.width
                    from: -10
                    to: 45
                    value: clusterTarget ? clusterTarget.ambientTemp : 24
                    stepSize: 1
                    onMoved: { if (clusterTarget) clusterTarget.ambientTemp = Math.round(value); }
                }
            }

            // Trip Computer Distance
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Text { text: "Trip A Distance (km)"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { width: parent.width - 200 }
                    Text {
                        text: (clusterTarget ? clusterTarget.tripKm.toFixed(1) : "256.8") + " km"
                        font.pixelSize: 14; font.weight: Font.Bold; color: "#CBD5E1"
                    }
                }

                Slider {
                    width: parent.width
                    from: 0
                    to: 999
                    value: clusterTarget ? clusterTarget.tripKm : 256.8
                    stepSize: 0.5
                    onMoved: { if (clusterTarget) clusterTarget.tripKm = value; }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 2: ALL 18 TELLTALES (INDIVIDUAL SWITCHES)
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab2View
        visible: emulatorPanel.currentTab === 2
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 12

            // Quick Master Controls
            Row {
                spacing: 10
                Rectangle {
                    width: 140; height: 30; radius: 6
                    color: "#059669"
                    Text { anchors.centerIn: parent; text: "✓ ALL TELLTALES ON"; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (clusterTarget) {
                                clusterTarget.telltaleSeatbelt = true; clusterTarget.telltaleAirbag = true;
                                clusterTarget.telltaleTraction = true; clusterTarget.telltaleParkBrake = true;
                                clusterTarget.telltaleAbs = true; clusterTarget.telltaleCheckEngine = true;
                                clusterTarget.telltaleBattery12v = true;
                                clusterTarget.telltaleTpms = true; clusterTarget.telltaleEvPlug = true;
                                clusterTarget.telltaleAutoHighBeam = true; clusterTarget.telltaleLowBeam = true;
                                clusterTarget.telltaleHighBeam = true; clusterTarget.telltaleFogLamp = true;
                                clusterTarget.telltaleBatteryTemp = true; clusterTarget.telltaleMasterWarning = true;
                                clusterTarget.telltaleDoorOpen = true;
                            }
                        }
                    }
                }

                Rectangle {
                    width: 140; height: 30; radius: 6
                    color: "#DC2626"
                    Text { anchors.centerIn: parent; text: "✕ ALL TELLTALES OFF"; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (clusterTarget) {
                                clusterTarget.telltaleSeatbelt = false; clusterTarget.telltaleAirbag = false;
                                clusterTarget.telltaleTraction = false; clusterTarget.telltaleParkBrake = false;
                                clusterTarget.telltaleAbs = false; clusterTarget.telltaleCheckEngine = false;
                                clusterTarget.telltaleBattery12v = false;
                                clusterTarget.telltaleTpms = false; clusterTarget.telltaleEvPlug = false;
                                clusterTarget.telltaleAutoHighBeam = false; clusterTarget.telltaleLowBeam = false;
                                clusterTarget.telltaleHighBeam = false; clusterTarget.telltaleFogLamp = false;
                                clusterTarget.telltaleBatteryTemp = false; clusterTarget.telltaleMasterWarning = false;
                                clusterTarget.telltaleDoorOpen = false;
                            }
                        }
                    }
                }

                Rectangle {
                    width: 120; height: 30; radius: 6
                    color: clusterTarget && (clusterTarget.telltaleTurnLeft && clusterTarget.telltaleTurnRight) ? "#D97706" : "#1E293B"
                    border.color: "#D97706"
                    Text { anchors.centerIn: parent; text: "⚠️ HAZARDS"; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (clusterTarget) {
                                var hz = !(clusterTarget.telltaleTurnLeft && clusterTarget.telltaleTurnRight);
                                clusterTarget.telltaleTurnLeft = hz;
                                clusterTarget.telltaleTurnRight = hz;
                            }
                        }
                    }
                }
            }

            // Grid of all 18 Telltale Switches
            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                Repeater {
                    model: [
                        { name: "Seatbelt (Red)",           prop: "telltaleSeatbelt",      icon: "seatbelt_active.svg" },
                        { name: "Airbag (Red)",             prop: "telltaleAirbag",        icon: "airbag_active.svg" },
                        { name: "Traction Control (Amber)", prop: "telltaleTraction",      icon: "traction_active.svg" },
                        { name: "Park Brake (P) (Red)",     prop: "telltaleParkBrake",     icon: "park_brake_active.svg" },
                        { name: "ABS Warning (Amber)",      prop: "telltaleAbs",           icon: "abs_active.svg" },
                        { name: "Check Engine (Amber)",     prop: "telltaleCheckEngine",   icon: "check_engine_active.svg" },
                        { name: "12V Battery (Red)",        prop: "telltaleBattery12v",    icon: "battery_12v_active.svg" },
                        { name: "TPMS Tire Press (Amber)",  prop: "telltaleTpms",          icon: "tpms_active.svg" },
                        { name: "EV Plug Port (Amber)",     prop: "telltaleEvPlug",        icon: "ev_plug_active.svg" },
                        { name: "Auto High Beam (Green)",   prop: "telltaleAutoHighBeam",  icon: "auto_high_beam_active.svg" },
                        { name: "Low Beam (Green)",         prop: "telltaleLowBeam",       icon: "low_beam_active.svg" },
                        { name: "High Beam (Blue)",         prop: "telltaleHighBeam",      icon: "high_beam_active.svg" },
                        { name: "Fog Lamps (Green)",        prop: "telltaleFogLamp",       icon: "fog_lamp_active.svg" },
                        { name: "Battery Overheat (Red)",   prop: "telltaleBatteryTemp",   icon: "battery_temp_active.svg" },
                        { name: "Master Warning (Amber)",   prop: "telltaleMasterWarning", icon: "master_warning_active.svg" },
                        { name: "Door Ajar (Red)",          prop: "telltaleDoorOpen",      icon: "door_open_active.svg" }
                    ]

                    Rectangle {
                        width: (emulatorPanel.width - 48) / 2
                        height: 38
                        radius: 6
                        color: (clusterTarget && clusterTarget[modelData.prop]) ? "#1E293B" : "#0B111A"
                        border.color: (clusterTarget && clusterTarget[modelData.prop]) ? "#0284C7" : "#1E293B"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Image {
                                width: 18; height: 18
                                source: "../../assets/telltales/" + modelData.icon
                                fillMode: Image.PreserveAspectFit
                                opacity: (clusterTarget && clusterTarget[modelData.prop]) ? 1.0 : 0.3
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.name
                                font.pixelSize: 11
                                font.weight: (clusterTarget && clusterTarget[modelData.prop]) ? Font.Bold : Font.Normal
                                color: (clusterTarget && clusterTarget[modelData.prop]) ? "#F8FAFC" : "#64748B"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Toggle Indicator
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32; height: 18; radius: 9
                            color: (clusterTarget && clusterTarget[modelData.prop]) ? "#10B981" : "#334155"

                            Rectangle {
                                width: 14; height: 14; radius: 7
                                color: "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: (clusterTarget && clusterTarget[modelData.prop]) ? parent.right : undefined
                                anchors.left: !(clusterTarget && clusterTarget[modelData.prop]) ? parent.left : undefined
                                anchors.margins: 2
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget[modelData.prop] = !clusterTarget[modelData.prop];
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 3: ONE-TOUCH SCENARIO PRESETS
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab3View
        visible: emulatorPanel.currentTab === 3
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 12

            Repeater {
                model: [
                    {
                        title: "🚀 Autobahn High-Speed Cruise",
                        desc: "185 km/h · 190 kW demand · Sport Mode · Low Beams On · Clean Telltales",
                        action: function() {
                            if (!clusterTarget) return;
                            clusterTarget.speedValue = 185;
                            clusterTarget.powerKw = 190;
                            clusterTarget.currentGear = "D";
                            clusterTarget.currentModeIndex = 1; // SPORT
                            clusterTarget.speedLimit = 120;
                            clusterTarget.telltaleLowBeam = true;
                            clusterTarget.telltaleHighBeam = false;
                            clusterTarget.telltaleSeatbelt = false;
                            clusterTarget.telltaleAirbag = false;
                            clusterTarget.telltaleBattery12v = false;
                            clusterTarget.telltaleTpms = false;
                            clusterTarget.telltaleBatteryTemp = false;
                            clusterTarget.telltaleDoorOpen = false;
                        }
                    },
                    {
                        title: "⚡ Maximum Regen Braking",
                        desc: "65 km/h · -45 kW Energy Recovery (Green zone) · ECO Mode",
                        action: function() {
                            if (!clusterTarget) return;
                            clusterTarget.speedValue = 65;
                            clusterTarget.powerKw = -45;
                            clusterTarget.currentGear = "D";
                            clusterTarget.currentModeIndex = 2; // ECO
                            clusterTarget.speedLimit = 50;
                        }
                    },
                    {
                        title: "🔥 Battery Thermal Overheat Alert",
                        desc: "Battery temp spikes to 68°C · Red Overheat Telltale + Master Warning Active",
                        action: function() {
                            if (!clusterTarget) return;
                            clusterTarget.batteryTemp = 68;
                            clusterTarget.telltaleBatteryTemp = true;
                            clusterTarget.telltaleMasterWarning = true;
                        }
                    },
                    {
                        title: "🪫 Low Battery State of Charge (12%)",
                        desc: "Battery at 12% · 71 km range · EV Plug indicator active",
                        action: function() {
                            if (!clusterTarget) return;
                            clusterTarget.batteryPercent = 12;
                            clusterTarget.rangeKm = 71;
                            clusterTarget.telltaleEvPlug = true;
                        }
                    },
                    {
                        title: "🛠️ Cluster Boot Self-Test Flash",
                        desc: "All 18 Telltales flashing in synchronized test mode",
                        action: function() {
                            if (!clusterTarget) return;
                            clusterTarget.activateCluster();
                        }
                    }
                ]

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: 8
                    color: "#161E2E"
                    border.color: "#334155"

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: modelData.title
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: "#00e5ff"
                        }
                        Text {
                            text: modelData.desc
                            font.pixelSize: 10
                            color: "#94A3B8"
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 80; height: 28; radius: 5
                        color: "#0284C7"

                        Text {
                            anchors.centerIn: parent
                            text: "APPLY"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.action()
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 4: INTERACTIVE WARNING CARDS SIMULATOR
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab4View
        visible: emulatorPanel.currentTab === 4
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 12

            Row {
                width: parent.width
                Text { text: "Simulate Warning Cards on Cluster"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                Item { Layout.fillWidth: true; width: parent.width - 340 }

                // Clear/Dismiss button
                Rectangle {
                    width: 140
                    height: 26
                    radius: 5
                    color: "#EF4444"

                    Text {
                        anchors.centerIn: parent
                        text: "✕ DISMISS ACTIVE"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (clusterTarget) clusterTarget.showWarningCard("", "");
                        }
                    }
                }
            }

            Grid {
                columns: 2
                spacing: 10
                width: parent.width

                Repeater {
                    model: [
                        { name: "Forward Collision",    file: "warning_forward_collision.png",    chime: "critical", col: "#EF4444" },
                        { name: "Low Battery (<12%)",   file: "warning_low_battery.png",          chime: "warning",  col: "#EF4444" },
                        { name: "Fasten Seatbelt",      file: "warning_seatbelt.png",             chime: "warning",  col: "#EF4444" },
                        { name: "Parking Brake",        file: "warning_park_brake.png",           chime: "info",     col: "#EF4444" },
                        { name: "Door Open",            file: "warning_door_open.png",            chime: "info",     col: "#EF4444" },
                        { name: "Low Tire Pressure",    file: "warning_tpms.png",                 chime: "warning",  col: "#F59E0B" },
                        { name: "Low Washer Fluid",     file: "warning_washer_fluid.png",         chime: "info",     col: "#38BDF8" },
                        { name: "Check Vehicle Service",file: "warning_check_vehicle.png",        chime: "warning",  col: "#F59E0B" },
                        { name: "Traction Control Off", file: "warning_traction_off.png",         chime: "info",     col: "#F59E0B" },
                        { name: "Lane Keep Assist Off", file: "warning_lka_unavailable.png",      chime: "warning",  col: "#F59E0B" },
                        { name: "Airbag System Fault",  file: "warning_airbag.png",               chime: "critical", col: "#EF4444" },
                        { name: "Park Assist Blocked",  file: "warning_park_assist_blocked.png",  chime: "warning",  col: "#F59E0B" },
                        { name: "Keep Hands On Wheel",  file: "warning_hands_on_wheel.png",       chime: "warning",  col: "#F59E0B" },
                        { name: "High Battery Temp",    file: "warning_battery_overheat.png",     chime: "critical", col: "#EF4444" },
                        { name: "Charging Port Open",   file: "warning_charging_port_open.png",   chime: "warning",  col: "#EF4444" },
                        { name: "Hill Descent Control", file: "warning_hill_descent.png",         chime: "info",     col: "#10B981" },
                        { name: "Ready to Drive",       file: "warning_ready_to_drive.png",       chime: "info",     col: "#10B981" },
                        { name: "Low Traction Slippery",file: "warning_low_traction.png",         chime: "warning",  col: "#F59E0B" },
                        { name: "Steering Assist Fault",file: "warning_steering_assist.png",      chime: "critical", col: "#EF4444" },
                        { name: "Speed Exceeded 80km/h",file: "warning_speed_80.png",             chime: "warning",  col: "#F59E0B" },
                        { name: "High Speed >120km/h",  file: "warning_speed_120.png",            chime: "critical", col: "#EF4444" }
                    ]

                    Rectangle {
                        width: (tab4View.width - 38) / 2
                        height: 76
                        radius: 8
                        color: "#161E2E"
                        border.color: modelData.col
                        border.width: 1.0
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: "../../assets/warnings/" + modelData.file
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget.showWarningCard(modelData.file, modelData.chime);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
