import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/****************************************************************************
** Component: EcuEmulatorPanel.qml
** Role: Full Interactive ECU & Vehicle Telemetry Simulation Control Bench
** Segregated Architecture:
**   - Tab 0: 🚗 Dynamics (Speed, kW Demand/Regen, Transmission, Drive Modes, Speed Limit, Blinkers)
**   - Tab 1: 🚪 Doors & Access (6 Doors/Hatches, Open/Close All, Safety Interlocks)
**   - Tab 2: 🧭 Navigation & Terrain (Turn HUD, Streets, Compass, Elevation, Pitch/Roll)
**   - Tab 3: 🛡️ ADAS & Traffic (Lead Distance, Obstacle Types, Pass-By Modes, Scenery)
**   - Tab 4: 🔋 Battery & TPMS (HV SoC, Temp, Ambient, Trip/ODO, 4-Tire PSI)
**   - Tab 5: ⚠️ Telltales & Lighting (Headlamps, Fog, ISO Warning Icons Grid)
**   - Tab 6: 🚨 Cards & Presets (22 Critical Warning Cards, Scenarios, Random Sim)
****************************************************************************/

Rectangle {
    id: emulatorPanel
    color: "#0B111A"
    clip: true

    // Target telemetry bindings (wired to DrivingCluster)
    property var clusterTarget: null

    // Tab tracking
    property int currentTab: 0

    // ═══════════════════════════════════════════════════════════════
    // RANDOM / AUTONOMOUS LIFECYCLE SIMULATOR ENGINE
    // ═══════════════════════════════════════════════════════════════
    property bool chaosActive: false
    property string chaosStatusText: "Ready"
    property int chaosTickCount: 0

    Timer {
        id: chaosTimer
        interval: 2200
        repeat: true
        running: emulatorPanel.chaosActive
        onTriggered: {
            if (!clusterTarget) return;
            emulatorPanel.chaosTickCount++;
            emulatorPanel.runChaosCycle();
        }
    }

    function runChaosCycle() {
        if (!clusterTarget) return;

        var subsystems = ["speed_power", "gear_mode", "adas_traffic", "navigation", "telltales_lights", "battery_thermal", "tpms_warnings", "terrain_compass"];
        var chosen = subsystems[Math.floor(Math.random() * subsystems.length)];

        if (clusterTarget.speedValue > 0) {
            clusterTarget.tripAKm += 0.2;
            clusterTarget.tripBKm += 0.2;
            clusterTarget.odoKm += 0.2;
        }

        switch (chosen) {
        case "speed_power":
            var spdPick = Math.floor(Math.random() * 5);
            if (spdPick === 0) {
                clusterTarget.speedValue = 0;
                clusterTarget.powerKw = 0;
                emulatorPanel.chaosStatusText = "Dynamics: Vehicle stopped at red light";
            } else if (spdPick === 1) {
                if (clusterTarget.currentGear === "P" || clusterTarget.currentGear === "N") clusterTarget.currentGear = "D";
                clusterTarget.speedValue = Math.round(55 + Math.random() * 45);
                clusterTarget.powerKw = Math.round(110 + Math.random() * 120);
                emulatorPanel.chaosStatusText = "Dynamics: Accelerating · " + Math.round(clusterTarget.speedValue) + " km/h (" + Math.round(clusterTarget.powerKw) + " kW)";
            } else if (spdPick === 2) {
                if (clusterTarget.currentGear === "P" || clusterTarget.currentGear === "N") clusterTarget.currentGear = "D";
                clusterTarget.speedValue = Math.round(110 + Math.random() * 70);
                clusterTarget.powerKw = Math.round(35 + Math.random() * 40);
                emulatorPanel.chaosStatusText = "Dynamics: Highway cruise · " + Math.round(clusterTarget.speedValue) + " km/h";
            } else if (spdPick === 3) {
                clusterTarget.speedValue = Math.max(15, Math.round(clusterTarget.speedValue - 35));
                clusterTarget.powerKw = -Math.round(25 + Math.random() * 25);
                emulatorPanel.chaosStatusText = "Dynamics: Regen recovery · " + Math.round(clusterTarget.powerKw) + " kW";
            } else {
                if (clusterTarget.currentGear === "P" || clusterTarget.currentGear === "N") clusterTarget.currentGear = "D";
                clusterTarget.speedValue = Math.round(35 + Math.random() * 30);
                clusterTarget.powerKw = Math.round(15 + Math.random() * 25);
                emulatorPanel.chaosStatusText = "Dynamics: Urban traffic · " + Math.round(clusterTarget.speedValue) + " km/h";
            }
            break;

        case "gear_mode":
            var gmPick = Math.floor(Math.random() * 5);
            if (gmPick === 0) {
                clusterTarget.toggleDriveMode();
                emulatorPanel.chaosStatusText = "Drive Mode: Switched to " + clusterTarget.currentMode;
            } else if (gmPick === 1) {
                clusterTarget.currentGear = "R";
                clusterTarget.speedValue = 8;
                clusterTarget.powerKw = 10;
                emulatorPanel.chaosStatusText = "Gear: 'R' Reverse with Guidelines";
            } else if (gmPick === 2) {
                clusterTarget.currentGear = "P";
                clusterTarget.speedValue = 0;
                clusterTarget.powerKw = 0;
                emulatorPanel.chaosStatusText = "Gear: 'P' Parked";
            } else {
                clusterTarget.currentGear = "D";
                if (clusterTarget.speedValue === 0) clusterTarget.speedValue = 50;
                emulatorPanel.chaosStatusText = "Gear: 'D' Drive engaged";
            }
            break;

        case "adas_traffic":
            var obstacles = ["car", "sedan", "hatchback", "motorcycle", "bicycle", "pedestrian"];
            clusterTarget.adasObstacleType = obstacles[Math.floor(Math.random() * obstacles.length)];
            clusterTarget.adasLeadDistance = Math.round(12 + Math.random() * 55);
            clusterTarget.adasLeadVehicle = true;
            clusterTarget.adasRightTraffic = (Math.random() > 0.35);
            clusterTarget.adasPassByEnabled = true;
            emulatorPanel.chaosStatusText = "ADAS: Tracking " + clusterTarget.adasObstacleType + " at " + clusterTarget.adasLeadDistance + "m";
            break;

        case "navigation":
            clusterTarget.navActive = true;
            var navOptions = [
                { man: "turn_right", dist: "350 m", street: "MG Road", state: "GUIDING", gps: false, eta: "18:45", dur: "14 min", km: "8.4 km" },
                { man: "turn_left", dist: "150 m", street: "Outer Ring Road", state: "GUIDING", gps: false, eta: "18:42", dur: "11 min", km: "7.1 km" },
                { man: "slight_right", dist: "800 m", street: "Airport Flyover", state: "GUIDING", gps: false, eta: "18:55", dur: "24 min", km: "18.2 km" },
                { man: "straight", dist: "2.4 km", street: "NH-44 Express Highway", state: "GUIDING", gps: false, eta: "19:10", dur: "39 min", km: "42.5 km" },
                { man: "roundabout", dist: "200 m", street: "Central Circle", state: "GUIDING", gps: false, eta: "18:48", dur: "17 min", km: "10.0 km" },
                { man: "u_turn", dist: "50 m", street: "Service Lane", state: "GUIDING", gps: false, eta: "18:40", dur: "9 min", km: "4.2 km" },
                { man: "turn_right", dist: "--", street: "--", state: "RECALCULATING", gps: false, eta: "18:50", dur: "18 min", km: "11.2 km" },
                { man: "turn_right", dist: "--", street: "--", state: "ARRIVED", gps: false, eta: "18:45", dur: "0 min", km: "0.0 km" },
                { man: "turn_right", dist: "--", street: "--", state: "GPS_LOST", gps: true, eta: "18:45", dur: "14 min", km: "8.4 km" }
            ];
            var np = navOptions[Math.floor(Math.random() * navOptions.length)];
            clusterTarget.navManeuver = np.man;
            clusterTarget.navDistance = np.dist;
            clusterTarget.navStreet = np.street;
            clusterTarget.navState = np.state;
            clusterTarget.gpsLost = np.gps;
            clusterTarget.navEta = np.eta;
            clusterTarget.navDuration = np.dur;
            clusterTarget.navRemainingKm = np.km;
            emulatorPanel.chaosStatusText = "Navigation: " + np.state + " · " + (np.state === "GUIDING" ? np.dist + " " + np.man : np.state);
            break;

        case "telltales_lights":
            var lgtPick = Math.floor(Math.random() * 4);
            if (lgtPick === 0) {
                clusterTarget.telltaleTurnLeft = true;
                clusterTarget.telltaleTurnRight = false;
                emulatorPanel.chaosStatusText = "Lighting: Left Indicator Blinking";
            } else if (lgtPick === 1) {
                clusterTarget.telltaleTurnLeft = false;
                clusterTarget.telltaleTurnRight = true;
                emulatorPanel.chaosStatusText = "Lighting: Right Indicator Blinking";
            } else if (lgtPick === 2) {
                clusterTarget.telltaleTurnLeft = true;
                clusterTarget.telltaleTurnRight = true;
                emulatorPanel.chaosStatusText = "Lighting: Hazard Flashers Active";
            } else {
                clusterTarget.telltaleTurnLeft = false;
                clusterTarget.telltaleTurnRight = false;
                emulatorPanel.chaosStatusText = "Lighting: Beams Updated";
            }
            clusterTarget.telltaleLowBeam = (Math.random() > 0.4);
            clusterTarget.telltaleAutoHighBeam = (Math.random() > 0.6);
            clusterTarget.telltaleFogLamp = (Math.random() > 0.75);
            break;

        case "battery_thermal":
            var bPick = Math.floor(Math.random() * 3);
            if (bPick === 0) {
                clusterTarget.batteryPercent = Math.max(8, Math.round(clusterTarget.batteryPercent - 3));
                clusterTarget.rangeKm = Math.round(clusterTarget.batteryPercent * 5.95);
                clusterTarget.telltaleEvPlug = (clusterTarget.batteryPercent < 15);
                emulatorPanel.chaosStatusText = "Battery: " + clusterTarget.batteryPercent + "% (" + clusterTarget.rangeKm + " km)";
            } else if (bPick === 1) {
                clusterTarget.batteryTemp = Math.round(28 + Math.random() * 35);
                clusterTarget.telltaleBatteryTemp = (clusterTarget.batteryTemp > 55);
                clusterTarget.telltaleMasterWarning = (clusterTarget.batteryTemp > 55);
                emulatorPanel.chaosStatusText = "Thermal: Battery Core at " + clusterTarget.batteryTemp + "°C";
            } else {
                clusterTarget.batteryPercent = 75;
                clusterTarget.rangeKm = 446;
                clusterTarget.batteryTemp = 32;
                clusterTarget.telltaleBatteryTemp = false;
                clusterTarget.telltaleMasterWarning = false;
                clusterTarget.telltaleEvPlug = false;
                emulatorPanel.chaosStatusText = "Battery: Optimal (75%, 32°C)";
            }
            break;

        case "tpms_warnings":
            var tpmsPick = Math.floor(Math.random() * 3);
            if (tpmsPick === 0) {
                clusterTarget.tpmsRlPsi = 24.0;
                clusterTarget.tpmsFlPsi = 33.0;
                clusterTarget.tpmsFrPsi = 33.0;
                clusterTarget.tpmsRrPsi = 33.0;
                emulatorPanel.chaosStatusText = "TPMS: Low Pressure Alert (24.0 PSI RL)";
            } else if (tpmsPick === 1) {
                clusterTarget.tpmsFlPsi = 33.0;
                clusterTarget.tpmsFrPsi = 33.0;
                clusterTarget.tpmsRlPsi = 33.0;
                clusterTarget.tpmsRrPsi = 33.0;
                emulatorPanel.chaosStatusText = "TPMS: All 4 Tires Normal (33.0 PSI)";
            } else {
                var doorPick = Math.floor(Math.random() * 3);
                if (doorPick === 0) {
                    clusterTarget.doorFrontLeft = true;
                    emulatorPanel.chaosStatusText = "Access: Driver Door Opened";
                } else if (doorPick === 1) {
                    clusterTarget.trunkOpen = true;
                    emulatorPanel.chaosStatusText = "Access: Trunk Opened";
                } else {
                    clusterTarget.doorFrontLeft = false;
                    clusterTarget.doorFrontRight = false;
                    clusterTarget.doorRearLeft = false;
                    clusterTarget.doorRearRight = false;
                    clusterTarget.bonnetOpen = false;
                    clusterTarget.trunkOpen = false;
                    emulatorPanel.chaosStatusText = "Access: All Doors Closed";
                }
            }
            break;

        case "terrain_compass":
            var headings = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
            clusterTarget.compassHeading = headings[Math.floor(Math.random() * headings.length)];
            clusterTarget.elevationM = Math.round(950 + Math.random() * 850);
            if (clusterTarget.currentMode === "OFF-ROAD") {
                clusterTarget.terrainPitchDeg = Math.round(-12 + Math.random() * 24);
                clusterTarget.terrainRollDeg = Math.round(-8 + Math.random() * 16);
                emulatorPanel.chaosStatusText = "Terrain: " + clusterTarget.compassHeading + " · " + clusterTarget.elevationM + "m · P:" + clusterTarget.terrainPitchDeg + "°";
            } else {
                emulatorPanel.chaosStatusText = "Compass: " + clusterTarget.compassHeading + " · " + clusterTarget.elevationM + " m";
            }
            break;
        }
    }

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
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 10; height: 10; radius: 5
                color: emulatorPanel.chaosActive ? "#F59E0B" : "#10B981"
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
                }
            }

            Text {
                text: "ECU SIMULATOR ✥"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1.0
                font.family: "Inter"
                color: "#F8FAFC"
                anchors.verticalCenter: parent.verticalCenter
            }

            // Master Chaos Simulator Button
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 175
                height: 26
                radius: 6
                color: emulatorPanel.chaosActive ? "#B45309" : "#1E293B"
                border.color: emulatorPanel.chaosActive ? "#F59E0B" : "#475569"
                border.width: 1.2

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "🎲"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: emulatorPanel.chaosActive ? "RANDOM SIM: ACTIVE" : "🎲 RANDOM SIMULATOR"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.3
                        color: "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        emulatorPanel.chaosActive = !emulatorPanel.chaosActive;
                        if (emulatorPanel.chaosActive) {
                            emulatorPanel.runChaosCycle();
                        } else {
                            emulatorPanel.chaosStatusText = "Simulation Paused";
                        }
                    }
                }
            }
        }

        // Close Button (×)
        Rectangle {
            id: closeBtn
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

    // ═══════════════════════════════════════════════════════════════
    // SEPARATED 7-DOMAIN TAB NAVIGATION BAR
    // ═══════════════════════════════════════════════════════════════
    Row {
        id: tabBar
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 38
        spacing: 0

        Repeater {
            model: [
                { title: "🚗 Dynamics",     idx: 0 },
                { title: "🚪 Access",       idx: 1 },
                { title: "🧭 Nav/Terrain",  idx: 2 },
                { title: "🛡️ ADAS",        idx: 3 },
                { title: "🔋 Battery/TPMS", idx: 4 },
                { title: "⚠️ Telltales",    idx: 5 },
                { title: "🚨 Cards/Presets",idx: 6 }
            ]

            Rectangle {
                width: emulatorPanel.width / 7
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
                    font.pixelSize: 10
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
    // TAB 0: 🚗 DYNAMICS & POWERTRAIN
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

            // ═══════════════════════════════════════════════════════
            // EV POWER & IGNITION STATE (ISO 26262 EV Power Management)
            // ═══════════════════════════════════════════════════════
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    Text { text: "⚡ EV Power & Ignition State"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget && clusterTarget.evPowerState) ? clusterTarget.evPowerState : "READY"
                        font.pixelSize: 12; font.weight: Font.Bold
                        color: (!clusterTarget || clusterTarget.evPowerState === "READY") ? "#10B981" :
                               (clusterTarget.evPowerState === "ON") ? "#00e5ff" : "#EF4444"
                    }
                }

                Row {
                    spacing: 10
                    width: parent.width

                    Repeater {
                        model: [
                            { state: "OFF",   label: "🛑 IGN OFF",       desc: "HV Cut / Sleep", col: "#EF4444" },
                            { state: "ON",    label: "⚡ IGN ON (ACC)",   desc: "12V Active",     col: "#00e5ff" },
                            { state: "READY", label: "🟢 EV READY",       desc: "Drive Ready",    col: "#10B981" }
                        ]

                        Rectangle {
                            width: (parent.width - 20) / 3
                            height: 46
                            radius: 6
                            color: (clusterTarget && clusterTarget.evPowerState === modelData.state) ? Qt.rgba(0.08, 0.14, 0.22, 0.95) : "#161E2E"
                            border.color: (clusterTarget && clusterTarget.evPowerState === modelData.state) ? modelData.col : "#334155"
                            border.width: (clusterTarget && clusterTarget.evPowerState === modelData.state) ? 1.8 : 1.0

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    font.pixelSize: 11; font.weight: Font.Bold
                                    font.family: "Inter"
                                    color: (clusterTarget && clusterTarget.evPowerState === modelData.state) ? "#FFFFFF" : "#94A3B8"
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.desc
                                    font.pixelSize: 8; font.weight: Font.Medium
                                    font.family: "Inter"
                                    color: (clusterTarget && clusterTarget.evPowerState === modelData.state) ? modelData.col : "#64748B"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        clusterTarget.setEvPowerState(modelData.state);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════
            // EV CHARGING STATION SIMULATOR (Speed / Power kW Control)
            // ═══════════════════════════════════════════════════════
            Rectangle {
                width: parent.width
                height: 155
                radius: 8
                color: (clusterTarget && clusterTarget.isCharging) ? "#064E3B" : "#111C2A"
                border.color: (clusterTarget && clusterTarget.isCharging) ? "#10B981" : "#334155"
                border.width: (clusterTarget && clusterTarget.isCharging) ? 1.8 : 1.0

                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Header Row: Title + Plug In / Stop Button
                    Row {
                        width: parent.width

                        Row {
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "⚡"
                                font.pixelSize: 14
                                color: (clusterTarget && clusterTarget.isCharging) ? "#10B981" : "#38BDF8"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "EV Charging Simulator"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { Layout.fillWidth: true; width: 10 }

                        // Start / Stop Charging Toggle Button
                        Rectangle {
                            width: 140
                            height: 28
                            radius: 6
                            color: (clusterTarget && clusterTarget.isCharging) ? "#EF4444" : "#10B981"
                            border.color: (clusterTarget && clusterTarget.isCharging) ? "#F87171" : "#34D399"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: (clusterTarget && clusterTarget.isCharging) ? "🛑 STOP CHARGING" : "🔌 START CHARGE"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        clusterTarget.isCharging = !clusterTarget.isCharging;
                                    }
                                }
                            }
                        }
                    }

                    // Charging Speed / Power Slider
                    Column {
                        width: parent.width
                        spacing: 4

                        Row {
                            width: parent.width
                            Text {
                                text: "Charging Speed / Power"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: "#CBD5E1"
                            }
                            Item { Layout.fillWidth: true; width: 10 }
                            Text {
                                text: (clusterTarget ? Math.round(clusterTarget.chargingRateKw) : 150) + " kW  (" + (clusterTarget ? Math.round((clusterTarget.chargingRateKw * 1000) / 800) : 188) + " A)"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: (clusterTarget && clusterTarget.isCharging) ? "#10B981" : "#38BDF8"
                            }
                        }

                        Slider {
                            id: chargingSpeedSlider
                            width: parent.width
                            from: 7
                            to: 350
                            stepSize: 1
                            value: clusterTarget ? clusterTarget.chargingRateKw : 150
                            onMoved: {
                                if (clusterTarget) {
                                    clusterTarget.chargingRateKw = value;
                                }
                            }
                        }
                    }

                    // Quick Charging Speed Preset Buttons
                    Row {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: [
                                { kw: 7,   label: "7 kW AC" },
                                { kw: 50,  label: "50 kW DC" },
                                { kw: 150, label: "150 kW Fast" },
                                { kw: 350, label: "350 kW Ultra" }
                            ]

                            Rectangle {
                                width: (parent.width - 18) / 4
                                height: 24
                                radius: 4
                                color: (clusterTarget && Math.round(clusterTarget.chargingRateKw) === modelData.kw) ? "#0284C7" : "#1E293B"
                                border.color: (clusterTarget && Math.round(clusterTarget.chargingRateKw) === modelData.kw) ? "#38BDF8" : "#334155"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: (clusterTarget && Math.round(clusterTarget.chargingRateKw) === modelData.kw) ? "#FFFFFF" : "#94A3B8"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (clusterTarget) {
                                            clusterTarget.chargingRateKw = modelData.kw;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Speed Control Slider (Active only in EV READY Mode)
            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width
                    Text { text: "Vehicle Speed"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget && clusterTarget.evPowerState !== "READY") ? "0 km/h (LOCKED IN " + clusterTarget.evPowerState + ")" :
                              ((clusterTarget ? Math.round(clusterTarget.speedValue) : 87) + " km/h")
                        font.pixelSize: 13; font.weight: Font.Bold
                        color: (clusterTarget && clusterTarget.evPowerState !== "READY") ? "#EF4444" : "#00e5ff"
                    }
                }

                Slider {
                    id: speedSliderControl
                    width: parent.width
                    from: 0
                    to: 260
                    value: clusterTarget ? clusterTarget.speedValue : 87
                    stepSize: 1
                    onMoved: {
                        if (clusterTarget) {
                            if (clusterTarget.evPowerState !== "READY") {
                                clusterTarget.speedValue = 0;
                                value = 0;
                                if (typeof clusterAudio !== "undefined") {
                                    clusterAudio.playWarningAlertChime();
                                }
                                return;
                            }
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
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget && clusterTarget.evPowerState !== "READY") ? "0 kW (LOCKED)" :
                              ((clusterTarget ? Math.round(clusterTarget.powerKw) : 145) + " kW")
                        font.pixelSize: 13; font.weight: Font.Bold
                        color: (clusterTarget && clusterTarget.evPowerState !== "READY") ? "#EF4444" :
                               (clusterTarget && clusterTarget.powerKw < 0) ? "#10B981" : "#00e5ff"
                    }
                }

                Slider {
                    id: powerSliderControl
                    width: parent.width
                    from: -50
                    to: 300
                    value: clusterTarget ? clusterTarget.powerKw : 145
                    stepSize: 5
                    onMoved: {
                        if (clusterTarget) {
                            if (clusterTarget.evPowerState !== "READY") {
                                clusterTarget.powerKw = 0;
                                value = 0;
                                if (typeof clusterAudio !== "undefined") {
                                    clusterAudio.playWarningAlertChime();
                                }
                                return;
                            }
                            clusterTarget.powerKw = value;
                        }
                    }
                }
            }

            // Transmission Gear (P R N D)
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

            // Road Speed Limit Selector
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Road Speed Limit Sign"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }

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

            // Turn Indicators & Hazards
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Turn Indicators & Hazards"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }

                Row {
                    spacing: 10
                    width: parent.width

                    Rectangle {
                        width: (parent.width - 20) / 3; height: 34; radius: 6
                        color: (clusterTarget && clusterTarget.telltaleTurnLeft && !clusterTarget.telltaleTurnRight) ? "#059669" : "#1E293B"
                        border.color: "#10B981"
                        Text { anchors.centerIn: parent; text: "⬅ LEFT"; font.pixelSize: 12; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget.telltaleTurnLeft = !clusterTarget.telltaleTurnLeft;
                                    clusterTarget.telltaleTurnRight = false;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 20) / 3; height: 34; radius: 6
                        color: (clusterTarget && clusterTarget.telltaleTurnLeft && clusterTarget.telltaleTurnRight) ? "#DC2626" : "#1E293B"
                        border.color: "#EF4444"
                        Text { anchors.centerIn: parent; text: "⚠️ HAZARD"; font.pixelSize: 12; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    var on = !(clusterTarget.telltaleTurnLeft && clusterTarget.telltaleTurnRight);
                                    clusterTarget.telltaleTurnLeft = on;
                                    clusterTarget.telltaleTurnRight = on;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 20) / 3; height: 34; radius: 6
                        color: (clusterTarget && clusterTarget.telltaleTurnRight && !clusterTarget.telltaleTurnLeft) ? "#059669" : "#1E293B"
                        border.color: "#10B981"
                        Text { anchors.centerIn: parent; text: "RIGHT ➡️"; font.pixelSize: 12; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget.telltaleTurnRight = !clusterTarget.telltaleTurnRight;
                                    clusterTarget.telltaleTurnLeft = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 1: 🚪 DOORS & VEHICLE ACCESS
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
            spacing: 16

            // Header & Batch Action Buttons
            Row {
                width: parent.width
                Text { text: "Vehicle Access Points & Safety Interlocks"; font.pixelSize: 13; font.weight: Font.Bold; color: "#00e5ff"; anchors.verticalCenter: parent.verticalCenter }
                Item { Layout.fillWidth: true; width: 10 }

                Row {
                    spacing: 8
                    Rectangle {
                        width: 90; height: 28; radius: 5
                        color: "#991B1B"; border.color: "#EF4444"
                        Text { anchors.centerIn: parent; text: "🚨 Open All"; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget.doorFrontLeft = true;
                                    clusterTarget.doorFrontRight = true;
                                    clusterTarget.doorRearLeft = true;
                                    clusterTarget.doorRearRight = true;
                                    clusterTarget.bonnetOpen = true;
                                    clusterTarget.trunkOpen = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 90; height: 28; radius: 5
                        color: "#065F46"; border.color: "#10B981"
                        Text { anchors.centerIn: parent; text: "✅ Close All"; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget.doorFrontLeft = false;
                                    clusterTarget.doorFrontRight = false;
                                    clusterTarget.doorRearLeft = false;
                                    clusterTarget.doorRearRight = false;
                                    clusterTarget.bonnetOpen = false;
                                    clusterTarget.trunkOpen = false;
                                }
                            }
                        }
                    }
                }
            }

            // Grid of 6 Doors / Hatches
            Grid {
                columns: 2
                spacing: 10
                width: parent.width

                // 1. FL Door
                Rectangle {
                    width: (parent.width - 10) / 2; height: 50; radius: 8
                    color: (clusterTarget && clusterTarget.doorFrontLeft) ? "#450A0A" : "#161E2E"
                    border.color: (clusterTarget && clusterTarget.doorFrontLeft) ? "#EF4444" : "#334155"
                    border.width: 1.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🚗"; font.pixelSize: 16 }
                        Column {
                            Text { text: "Front-Left (Driver)"; font.pixelSize: 11; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorFrontLeft) ? "#FCA5A5" : "#CBD5E1" }
                            Text { text: (clusterTarget && clusterTarget.doorFrontLeft) ? "STATUS: OPEN" : "STATUS: CLOSED"; font.pixelSize: 10; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorFrontLeft) ? "#EF4444" : "#64748B" }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (clusterTarget) clusterTarget.doorFrontLeft = !clusterTarget.doorFrontLeft; }
                    }
                }

                // 2. FR Door
                Rectangle {
                    width: (parent.width - 10) / 2; height: 50; radius: 8
                    color: (clusterTarget && clusterTarget.doorFrontRight) ? "#450A0A" : "#161E2E"
                    border.color: (clusterTarget && clusterTarget.doorFrontRight) ? "#EF4444" : "#334155"
                    border.width: 1.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🚗"; font.pixelSize: 16 }
                        Column {
                            Text { text: "Front-Right (Pass)"; font.pixelSize: 11; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorFrontRight) ? "#FCA5A5" : "#CBD5E1" }
                            Text { text: (clusterTarget && clusterTarget.doorFrontRight) ? "STATUS: OPEN" : "STATUS: CLOSED"; font.pixelSize: 10; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorFrontRight) ? "#EF4444" : "#64748B" }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (clusterTarget) clusterTarget.doorFrontRight = !clusterTarget.doorFrontRight; }
                    }
                }

                // 3. RL Door
                Rectangle {
                    width: (parent.width - 10) / 2; height: 50; radius: 8
                    color: (clusterTarget && clusterTarget.doorRearLeft) ? "#450A0A" : "#161E2E"
                    border.color: (clusterTarget && clusterTarget.doorRearLeft) ? "#EF4444" : "#334155"
                    border.width: 1.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🚪"; font.pixelSize: 16 }
                        Column {
                            Text { text: "Rear-Left Door"; font.pixelSize: 11; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorRearLeft) ? "#FCA5A5" : "#CBD5E1" }
                            Text { text: (clusterTarget && clusterTarget.doorRearLeft) ? "STATUS: OPEN" : "STATUS: CLOSED"; font.pixelSize: 10; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorRearLeft) ? "#EF4444" : "#64748B" }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (clusterTarget) clusterTarget.doorRearLeft = !clusterTarget.doorRearLeft; }
                    }
                }

                // 4. RR Door
                Rectangle {
                    width: (parent.width - 10) / 2; height: 50; radius: 8
                    color: (clusterTarget && clusterTarget.doorRearRight) ? "#450A0A" : "#161E2E"
                    border.color: (clusterTarget && clusterTarget.doorRearRight) ? "#EF4444" : "#334155"
                    border.width: 1.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🚪"; font.pixelSize: 16 }
                        Column {
                            Text { text: "Rear-Right Door"; font.pixelSize: 11; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorRearRight) ? "#FCA5A5" : "#CBD5E1" }
                            Text { text: (clusterTarget && clusterTarget.doorRearRight) ? "STATUS: OPEN" : "STATUS: CLOSED"; font.pixelSize: 10; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.doorRearRight) ? "#EF4444" : "#64748B" }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (clusterTarget) clusterTarget.doorRearRight = !clusterTarget.doorRearRight; }
                    }
                }

                // 5. Bonnet / Hood
                Rectangle {
                    width: (parent.width - 10) / 2; height: 50; radius: 8
                    color: (clusterTarget && clusterTarget.bonnetOpen) ? "#450A0A" : "#161E2E"
                    border.color: (clusterTarget && clusterTarget.bonnetOpen) ? "#EF4444" : "#334155"
                    border.width: 1.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "🔧"; font.pixelSize: 16 }
                        Column {
                            Text { text: "Bonnet (Hood)"; font.pixelSize: 11; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.bonnetOpen) ? "#FCA5A5" : "#CBD5E1" }
                            Text { text: (clusterTarget && clusterTarget.bonnetOpen) ? "STATUS: OPEN" : "STATUS: CLOSED"; font.pixelSize: 10; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.bonnetOpen) ? "#EF4444" : "#64748B" }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (clusterTarget) clusterTarget.bonnetOpen = !clusterTarget.bonnetOpen; }
                    }
                }

                // 6. Trunk / Boot
                Rectangle {
                    width: (parent.width - 10) / 2; height: 50; radius: 8
                    color: (clusterTarget && clusterTarget.trunkOpen) ? "#450A0A" : "#161E2E"
                    border.color: (clusterTarget && clusterTarget.trunkOpen) ? "#EF4444" : "#334155"
                    border.width: 1.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "📦"; font.pixelSize: 16 }
                        Column {
                            Text { text: "Tailgate (Trunk)"; font.pixelSize: 11; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.trunkOpen) ? "#FCA5A5" : "#CBD5E1" }
                            Text { text: (clusterTarget && clusterTarget.trunkOpen) ? "STATUS: OPEN" : "STATUS: CLOSED"; font.pixelSize: 10; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.trunkOpen) ? "#EF4444" : "#64748B" }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (clusterTarget) clusterTarget.trunkOpen = !clusterTarget.trunkOpen; }
                    }
                }
            }

            // Safety System Interlock Status Box
            Rectangle {
                width: parent.width
                height: 80
                radius: 8
                color: "#161E2E"
                border.color: "#334155"

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    Text { text: "🛡️ Safety Interlocks & ADAS Suspension Logic"; font.pixelSize: 11; font.weight: Font.Bold; color: "#38BDF8" }
                    Text {
                        text: "• In P / N: Displays red blinking open graphics cleanly on the vehicle chassis.
• In D / R: Pops up Warning Card + continuous chime holds until all doors are closed.
• ADAS perception & driving assist silently suspended whenever any access point is open.";
                        font.pixelSize: 10
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 2: 🧭 NAVIGATION, COMPASS & TERRAIN
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab2View
        visible: emulatorPanel.currentTab === 2
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

            // Navigation Status & Mode
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    Text { text: "🧭 Turn-by-Turn Navigation State"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0"; anchors.verticalCenter: parent.verticalCenter }
                    Item { Layout.fillWidth: true; width: 10 }

                    Rectangle {
                        width: 100; height: 26; radius: 5
                        color: (clusterTarget && clusterTarget.navActive) ? "#0284C7" : "#334155"
                        Text { anchors.centerIn: parent; text: (clusterTarget && clusterTarget.navActive) ? "NAV: ACTIVE" : "NAV: OFF"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (clusterTarget) clusterTarget.navActive = !clusterTarget.navActive; }
                        }
                    }
                }

                // Nav State Selector (GUIDING, RECALCULATING, ARRIVED, GPS_LOST)
                Row {
                    spacing: 8
                    width: parent.width
                    Repeater {
                        model: [
                            { id: "GUIDING",       name: "🟢 Guiding" },
                            { id: "RECALCULATING", name: "🔄 Reroute" },
                            { id: "ARRIVED",       name: "🏁 Arrived" },
                            { id: "GPS_LOST",      name: "📡 GPS Lost" }
                        ]
                        Rectangle {
                            width: (parent.width - 24) / 4
                            height: 30
                            radius: 6
                            color: (clusterTarget && clusterTarget.navState === modelData.id) ? "#0284C7" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.navState === modelData.id) ? "#38BDF8" : "#475569"

                            Text { anchors.centerIn: parent; text: modelData.name; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        clusterTarget.navState = modelData.id;
                                        clusterTarget.gpsLost = (modelData.id === "GPS_LOST");
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Maneuver Direction Selector
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Next Turn Maneuver"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }

                Grid {
                    columns: 3
                    spacing: 8
                    width: parent.width

                    Repeater {
                        model: [
                            { id: "turn_right",   name: "➡️ Turn Right" },
                            { id: "turn_left",    name: "⬅️ Turn Left" },
                            { id: "slight_right", name: "↗️ Fork Right" },
                            { id: "straight",     name: "⬆️ Straight" },
                            { id: "roundabout",   name: "🔄 Roundabout" },
                            { id: "u_turn",       name: "↩️ U-Turn" }
                        ]

                        Rectangle {
                            width: (parent.width - 16) / 3
                            height: 32
                            radius: 6
                            color: (clusterTarget && clusterTarget.navManeuver === modelData.id) ? "#059669" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.navManeuver === modelData.id) ? "#34D399" : "#475569"

                            Text { anchors.centerIn: parent; text: modelData.name; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (clusterTarget) clusterTarget.navManeuver = modelData.id; }
                            }
                        }
                    }
                }
            }

            // Compass Heading Buttons (N to NW)
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Compass Heading (" + (clusterTarget ? clusterTarget.compassHeading : "SW") + ")"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }

                Row {
                    spacing: 6
                    width: parent.width
                    Repeater {
                        model: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
                        Rectangle {
                            width: (parent.width - 42) / 8
                            height: 30
                            radius: 5
                            color: (clusterTarget && clusterTarget.compassHeading === modelData) ? "#0284C7" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.compassHeading === modelData) ? "#00E5FF" : "#475569"

                            Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 11; font.weight: Font.Bold; color: (clusterTarget && clusterTarget.compassHeading === modelData) ? "#FFFFFF" : "#94A3B8" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (clusterTarget) clusterTarget.compassHeading = modelData; }
                            }
                        }
                    }
                }
            }

            // Elevation Slider (0 m to 3500 m)
            Column {
                width: parent.width
                spacing: 4

                Row {
                    width: parent.width
                    Text { text: "Elevation Altitude Above Sea Level"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget ? clusterTarget.elevationM : 1250) + " m"
                        font.pixelSize: 13; font.weight: Font.Bold; color: "#00e5ff"
                    }
                }

                Slider {
                    width: parent.width
                    from: 0
                    to: 3500
                    value: clusterTarget ? clusterTarget.elevationM : 1250
                    stepSize: 25
                    onMoved: { if (clusterTarget) clusterTarget.elevationM = Math.round(value); }
                }
            }

            // Off-Road Pitch & Roll Sliders
            Row {
                width: parent.width
                spacing: 14

                // Pitch
                Column {
                    width: (parent.width - 14) / 2
                    spacing: 4
                    Row {
                        width: parent.width
                        Text { text: "Pitch Angle"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }
                        Item { Layout.fillWidth: true; width: 10 }
                        Text {
                            text: (clusterTarget ? (clusterTarget.terrainPitchDeg >= 0 ? "+" : "") + Math.round(clusterTarget.terrainPitchDeg) : "+8") + "°"
                            font.pixelSize: 12; font.weight: Font.Bold; color: "#38BDF8"
                        }
                    }
                    Slider {
                        width: parent.width
                        from: -25; to: 25
                        value: clusterTarget ? clusterTarget.terrainPitchDeg : 8
                        stepSize: 1
                        onMoved: { if (clusterTarget) clusterTarget.terrainPitchDeg = value; }
                    }
                }

                // Roll
                Column {
                    width: (parent.width - 14) / 2
                    spacing: 4
                    Row {
                        width: parent.width
                        Text { text: "Roll Angle"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }
                        Item { Layout.fillWidth: true; width: 10 }
                        Text {
                            text: (clusterTarget ? (clusterTarget.terrainRollDeg >= 0 ? "+" : "") + Math.round(clusterTarget.terrainRollDeg) : "-3") + "°"
                            font.pixelSize: 12; font.weight: Font.Bold; color: "#38BDF8"
                        }
                    }
                    Slider {
                        width: parent.width
                        from: -25; to: 25
                        value: clusterTarget ? clusterTarget.terrainRollDeg : -3
                        stepSize: 1
                        onMoved: { if (clusterTarget) clusterTarget.terrainRollDeg = value; }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 3: 🛡️ ADAS PERCEPTION & HIGHWAY TRAFFIC
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
            spacing: 16

            Row {
                width: parent.width
                Text { text: "🛡️ ADAS Perception & Traffic Simulator"; font.pixelSize: 13; font.weight: Font.Bold; color: "#00e5ff"; anchors.verticalCenter: parent.verticalCenter }
                Item { Layout.fillWidth: true; width: 10 }
                Rectangle {
                    width: 110; height: 28; radius: 6
                    color: (clusterTarget && clusterTarget.adasUserEnabled) ? "#0284C7" : "#334155"
                    border.color: (clusterTarget && clusterTarget.adasUserEnabled) ? "#38BDF8" : "#475569"
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: (clusterTarget && clusterTarget.adasUserEnabled) ? "ASSIST: ON" : "ASSIST: OFF"
                        font.pixelSize: 11; font.weight: Font.Bold
                        color: "#FFFFFF"
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (clusterTarget) clusterTarget.adasUserEnabled = !clusterTarget.adasUserEnabled; }
                    }
                }
            }

            // Lead Vehicle Following Distance Slider
            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text { text: "Lead Vehicle Distance"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget && clusterTarget.adasLeadDistance !== undefined ? Number(clusterTarget.adasLeadDistance).toFixed(1) : "38.5") + " m"
                        font.pixelSize: 13; font.weight: Font.Bold; color: "#00e5ff"
                    }
                }
                Slider {
                    width: parent.width
                    from: 10; to: 90
                    value: (clusterTarget && clusterTarget.adasLeadDistance !== undefined) ? clusterTarget.adasLeadDistance : 38.5
                    stepSize: 0.5
                    onMoved: { if (clusterTarget) clusterTarget.adasLeadDistance = value; }
                }
            }

            // Front Obstruction Type Selector
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
                            width: (parent.width - 16) / 3; height: 32; radius: 6
                            color: (clusterTarget && clusterTarget.adasObstacleType === modelData.id) ? "#0284C7" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.adasObstacleType === modelData.id) ? "#38BDF8" : "#475569"

                            Text { anchors.centerIn: parent; text: modelData.name; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
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

            // Traffic Simulation Mode
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Traffic Pacing Mode"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }

                Row {
                    spacing: 8
                    width: parent.width
                    Repeater {
                        model: [
                            { id: "both",   name: "🔄 Both Lanes" },
                            { id: "left",   name: "⬅️ Left Pass" },
                            { id: "right",  name: "➡️ Right Pass" },
                            { id: "steady", name: "⏸️ Steady Pace" }
                        ]
                        Rectangle {
                            width: (parent.width - 24) / 4; height: 32; radius: 6
                            color: (clusterTarget && clusterTarget.adasPassByMode === modelData.id) ? "#059669" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.adasPassByMode === modelData.id) ? "#34D399" : "#475569"

                            Text { anchors.centerIn: parent; text: modelData.name; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
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

            // Cockpit Background Scenery
            Column {
                width: parent.width
                spacing: 6
                Text { text: "Cockpit Background Scenery"; font.pixelSize: 11; font.weight: Font.Bold; color: "#CBD5E1" }

                Row {
                    spacing: 8
                    width: parent.width

                    Repeater {
                        model: [
                            { id: "mountain", name: "🏔️ Mountain" },
                            { id: "city",     name: "🌃 City Skyline" },
                            { id: "coastal",  name: "🌅 Coastal Sunset" }
                        ]
                        Rectangle {
                            width: (parent.width - 16 - 120) / 3; height: 32; radius: 6
                            color: (clusterTarget && clusterTarget.activeBackground === modelData.id) ? "#7C3AED" : "#1E293B"
                            border.color: (clusterTarget && clusterTarget.activeBackground === modelData.id) ? "#A78BFA" : "#475569"

                            Text { anchors.centerIn: parent; text: modelData.name; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        clusterTarget.autoCycleBackground = false;
                                        clusterTarget.activeBackground = modelData.id;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 120; height: 32; radius: 6
                        color: (clusterTarget && clusterTarget.autoCycleBackground) ? "#D97706" : "#1E293B"
                        border.color: (clusterTarget && clusterTarget.autoCycleBackground) ? "#FBBF24" : "#475569"
                        Text { anchors.centerIn: parent; text: (clusterTarget && clusterTarget.autoCycleBackground) ? "🔄 Auto Cycle: ON" : "🔄 Auto Cycle"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (clusterTarget) clusterTarget.autoCycleBackground = !clusterTarget.autoCycleBackground; }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 4: 🔋 BATTERY, THERMAL & TPMS
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
            spacing: 16

            // Battery SoC Slider
            Column {
                width: parent.width
                spacing: 6
                Row {
                    width: parent.width
                    Text { text: "High-Voltage Battery SoC"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget ? Math.round(clusterTarget.batteryPercent) : 72) + " % (" + (clusterTarget ? Math.round(clusterTarget.rangeKm) : 428) + " km)"
                        font.pixelSize: 14; font.weight: Font.Bold; color: "#10B981"
                    }
                }
                Slider {
                    width: parent.width
                    from: 0; to: 100
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

            // Battery Temperature Slider
            Column {
                width: parent.width
                spacing: 6
                Row {
                    width: parent.width
                    Text { text: "Battery Pack Temperature"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget ? Math.round(clusterTarget.batteryTemp) : 32) + " °C"
                        font.pixelSize: 14; font.weight: Font.Bold
                        color: (clusterTarget && clusterTarget.batteryTemp > 55) ? "#EF4444" : "#00e5ff"
                    }
                }
                Slider {
                    width: parent.width
                    from: -10; to: 80
                    value: clusterTarget ? clusterTarget.batteryTemp : 32
                    stepSize: 1
                    onMoved: { if (clusterTarget) clusterTarget.batteryTemp = value; }
                }
            }

            // Ambient Outside Temperature Slider
            Column {
                width: parent.width
                spacing: 6
                Row {
                    width: parent.width
                    Text { text: "Ambient Outside Temperature"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }
                    Item { Layout.fillWidth: true; width: 10 }
                    Text {
                        text: (clusterTarget ? Math.round(clusterTarget.ambientTemp) : 24) + " °C"
                        font.pixelSize: 14; font.weight: Font.Bold
                        color: (clusterTarget && clusterTarget.ambientTemp < 3) ? "#38BDF8" : "#94A3B8"
                    }
                }
                Slider {
                    width: parent.width
                    from: -20; to: 50
                    value: clusterTarget ? clusterTarget.ambientTemp : 24
                    stepSize: 1
                    onMoved: { if (clusterTarget) clusterTarget.ambientTemp = value; }
                }
            }

            // 4-Wheel TPMS Pressures
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    Text { text: "🛞 4-Wheel TPMS Pressures (PSI)"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0"; anchors.verticalCenter: parent.verticalCenter }
                    Item { Layout.fillWidth: true; width: 10 }

                    Row {
                        spacing: 6
                        Rectangle {
                            width: 80; height: 24; radius: 4
                            color: "#065F46"; border.color: "#10B981"
                            Text { anchors.centerIn: parent; text: "Normal 33 PSI"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        clusterTarget.tpmsFlPsi = 33.0;
                                        clusterTarget.tpmsFrPsi = 33.0;
                                        clusterTarget.tpmsRlPsi = 33.0;
                                        clusterTarget.tpmsRrPsi = 33.0;
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: 95; height: 24; radius: 4
                            color: "#991B1B"; border.color: "#EF4444"
                            Text { anchors.centerIn: parent; text: "Low PSI Alert"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) {
                                        clusterTarget.tpmsRlPsi = 24.0;
                                    }
                                }
                            }
                        }
                    }
                }

                Grid {
                    columns: 2
                    spacing: 10
                    width: parent.width

                    // FL
                    Column {
                        width: (parent.width - 10) / 2
                        spacing: 2
                        Row {
                            width: parent.width
                            Text { text: "Front-Left"; font.pixelSize: 10; color: "#94A3B8" }
                            Item { Layout.fillWidth: true; width: 10 }
                            Text {
                                text: (clusterTarget && clusterTarget.tpmsFlPsi !== undefined ? Number(clusterTarget.tpmsFlPsi).toFixed(1) : "33.0") + " PSI"
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: (clusterTarget && clusterTarget.tpmsFlPsi !== undefined && clusterTarget.tpmsFlPsi < 28) ? "#EF4444" : "#10B981"
                            }
                        }
                        Slider {
                            width: parent.width
                            from: 20; to: 45
                            value: (clusterTarget && clusterTarget.tpmsFlPsi !== undefined) ? clusterTarget.tpmsFlPsi : 33.0
                            stepSize: 0.5
                            onMoved: { if (clusterTarget) clusterTarget.tpmsFlPsi = value; }
                        }
                    }

                    // FR
                    Column {
                        width: (parent.width - 10) / 2
                        spacing: 2
                        Row {
                            width: parent.width
                            Text { text: "Front-Right"; font.pixelSize: 10; color: "#94A3B8" }
                            Item { Layout.fillWidth: true; width: 10 }
                            Text {
                                text: (clusterTarget && clusterTarget.tpmsFrPsi !== undefined ? Number(clusterTarget.tpmsFrPsi).toFixed(1) : "33.0") + " PSI"
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: (clusterTarget && clusterTarget.tpmsFrPsi !== undefined && clusterTarget.tpmsFrPsi < 28) ? "#EF4444" : "#10B981"
                            }
                        }
                        Slider {
                            width: parent.width
                            from: 20; to: 45
                            value: (clusterTarget && clusterTarget.tpmsFrPsi !== undefined) ? clusterTarget.tpmsFrPsi : 33.0
                            stepSize: 0.5
                            onMoved: { if (clusterTarget) clusterTarget.tpmsFrPsi = value; }
                        }
                    }

                    // RL
                    Column {
                        width: (parent.width - 10) / 2
                        spacing: 2
                        Row {
                            width: parent.width
                            Text { text: "Rear-Left"; font.pixelSize: 10; color: "#94A3B8" }
                            Item { Layout.fillWidth: true; width: 10 }
                            Text {
                                text: (clusterTarget && clusterTarget.tpmsRlPsi !== undefined ? Number(clusterTarget.tpmsRlPsi).toFixed(1) : "33.0") + " PSI"
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: (clusterTarget && clusterTarget.tpmsRlPsi !== undefined && clusterTarget.tpmsRlPsi < 28) ? "#EF4444" : "#10B981"
                            }
                        }
                        Slider {
                            width: parent.width
                            from: 20; to: 45
                            value: (clusterTarget && clusterTarget.tpmsRlPsi !== undefined) ? clusterTarget.tpmsRlPsi : 33.0
                            stepSize: 0.5
                            onMoved: { if (clusterTarget) clusterTarget.tpmsRlPsi = value; }
                        }
                    }

                    // RR
                    Column {
                        width: (parent.width - 10) / 2
                        spacing: 2
                        Row {
                            width: parent.width
                            Text { text: "Rear-Right"; font.pixelSize: 10; color: "#94A3B8" }
                            Item { Layout.fillWidth: true; width: 10 }
                            Text {
                                text: (clusterTarget && clusterTarget.tpmsRrPsi !== undefined ? Number(clusterTarget.tpmsRrPsi).toFixed(1) : "33.0") + " PSI"
                                font.pixelSize: 11; font.weight: Font.Bold
                                color: (clusterTarget && clusterTarget.tpmsRrPsi !== undefined && clusterTarget.tpmsRrPsi < 28) ? "#EF4444" : "#10B981"
                            }
                        }
                        Slider {
                            width: parent.width
                            from: 20; to: 45
                            value: (clusterTarget && clusterTarget.tpmsRrPsi !== undefined) ? clusterTarget.tpmsRrPsi : 33.0
                            stepSize: 0.5
                            onMoved: { if (clusterTarget) clusterTarget.tpmsRrPsi = value; }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 5: ⚠️ ISO TELLTALES & LIGHTING
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab5View
        visible: emulatorPanel.currentTab === 5
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        contentWidth: availableWidth
        clip: true

        Column {
            width: parent.width
            spacing: 14

            Row {
                width: parent.width
                Text { text: "ISO 7000 Telltale Warning Alerts"; font.pixelSize: 13; font.weight: Font.Bold; color: "#00e5ff"; anchors.verticalCenter: parent.verticalCenter }
                Item { Layout.fillWidth: true; width: 10 }

                Row {
                    spacing: 6
                    Rectangle {
                        width: 90; height: 24; radius: 4; color: "#0284C7"
                        Text { anchors.centerIn: parent; text: "Activate All"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget.telltaleSeatbelt = true; clusterTarget.telltaleAirbag = true;
                                    clusterTarget.telltaleAbs = true; clusterTarget.telltaleTraction = true;
                                    clusterTarget.telltaleParkBrake = true; clusterTarget.telltaleBattery12v = true;
                                    clusterTarget.telltaleCheckEngine = true; clusterTarget.telltaleMasterWarning = true;
                                    clusterTarget.telltaleTpms = true; clusterTarget.telltaleLowBeam = true;
                                }
                            }
                        }
                    }
                    Rectangle {
                        width: 75; height: 24; radius: 4; color: "#334155"
                        Text { anchors.centerIn: parent; text: "Clear All"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) {
                                    clusterTarget.telltaleSeatbelt = false; clusterTarget.telltaleAirbag = false;
                                    clusterTarget.telltaleAbs = false; clusterTarget.telltaleTraction = false;
                                    clusterTarget.telltaleParkBrake = false; clusterTarget.telltaleBattery12v = false;
                                    clusterTarget.telltaleCheckEngine = false; clusterTarget.telltaleMasterWarning = false;
                                    clusterTarget.telltaleTpms = false; clusterTarget.telltaleLowBeam = false;
                                    clusterTarget.telltaleHighBeam = false; clusterTarget.telltaleAutoHighBeam = false;
                                    clusterTarget.telltaleFogLamp = false;
                                }
                            }
                        }
                    }
                }
            }

            Grid {
                columns: 2
                spacing: 8
                width: parent.width

                Repeater {
                    model: [
                        { name: "Seatbelt Warning",     prop: "telltaleSeatbelt",      file: "seatbelt_active.svg" },
                        { name: "Airbag Fault",          prop: "telltaleAirbag",        file: "airbag_active.svg" },
                        { name: "Anti-lock Braking ABS", prop: "telltaleAbs",           file: "abs_active.svg" },
                        { name: "Traction Control ESC",  prop: "telltaleTraction",      file: "traction_active.svg" },
                        { name: "Parking Brake (P)",     prop: "telltaleParkBrake",     file: "park_brake_active.svg" },
                        { name: "12V Low Voltage",       prop: "telltaleBattery12v",    file: "battery_12v_active.svg" },
                        { name: "Check Engine / EV",     prop: "telltaleCheckEngine",   file: "check_engine_active.svg" },
                        { name: "Master Warning ⚠️",      prop: "telltaleMasterWarning", file: "master_warning_active.svg" },
                        { name: "TPMS Low Pressure",     prop: "telltaleTpms",          file: "tpms_active.svg" },
                        { name: "Low Beam Headlights",   prop: "telltaleLowBeam",       file: "low_beam_active.svg" },
                        { name: "High Beam Lights",      prop: "telltaleHighBeam",      file: "high_beam_active.svg" },
                        { name: "Auto High Beam (AHB)",  prop: "telltaleAutoHighBeam",  file: "auto_high_beam_active.svg" },
                        { name: "Fog Lamps",             prop: "telltaleFogLamp",       file: "fog_lamp_active.svg" }
                    ]

                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 38
                        radius: 6
                        color: (clusterTarget && clusterTarget[modelData.prop]) ? "#1E293B" : "#161E2E"
                        border.color: (clusterTarget && clusterTarget[modelData.prop]) ? "#38BDF8" : "#334155"
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Image {
                                width: 18; height: 18
                                source: "../../assets/telltales/" + modelData.file
                                fillMode: Image.PreserveAspectFit
                                opacity: (clusterTarget && clusterTarget[modelData.prop]) ? 1.0 : 0.4
                            }

                            Text {
                                text: modelData.name
                                font.pixelSize: 11
                                font.weight: (clusterTarget && clusterTarget[modelData.prop]) ? Font.Bold : Font.Normal
                                color: (clusterTarget && clusterTarget[modelData.prop]) ? "#FFFFFF" : "#94A3B8"
                            }
                        }

                        // Toggle indicator dot
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10; height: 10; radius: 5
                            color: (clusterTarget && clusterTarget[modelData.prop]) ? "#10B981" : "#475569"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (clusterTarget) clusterTarget[modelData.prop] = !clusterTarget[modelData.prop];
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // TAB 6: 🚨 CARDS & SCENARIOS
    // ═══════════════════════════════════════════════════════════════
    ScrollView {
        id: tab6View
        visible: emulatorPanel.currentTab === 6
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

            // One-Touch Scenarios
            Column {
                width: parent.width
                spacing: 8
                Text { text: "⚡ One-Touch Scenario Presets"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0" }

                Grid {
                    columns: 2
                    spacing: 8
                    width: parent.width

                    Repeater {
                        model: [
                            {
                                title: "🚀 Autobahn Cruise",
                                desc: "185 km/h · Sport Mode · Low Beams",
                                action: function() {
                                    if (!clusterTarget) return;
                                    clusterTarget.speedValue = 185;
                                    clusterTarget.powerKw = 190;
                                    clusterTarget.currentGear = "D";
                                    clusterTarget.currentModeIndex = 1;
                                    clusterTarget.speedLimit = 120;
                                    clusterTarget.telltaleLowBeam = true;
                                }
                            },
                            {
                                title: "⚡ Max Regen Braking",
                                desc: "65 km/h · -45 kW Regen · ECO Mode",
                                action: function() {
                                    if (!clusterTarget) return;
                                    clusterTarget.speedValue = 65;
                                    clusterTarget.powerKw = -45;
                                    clusterTarget.currentGear = "D";
                                    clusterTarget.currentModeIndex = 2;
                                    clusterTarget.speedLimit = 50;
                                }
                            },
                            {
                                title: "🔥 Battery Overheat",
                                desc: "68°C · Master Warning Alert",
                                action: function() {
                                    if (!clusterTarget) return;
                                    clusterTarget.batteryTemp = 68;
                                    clusterTarget.telltaleBatteryTemp = true;
                                    clusterTarget.telltaleMasterWarning = true;
                                }
                            },
                            {
                                title: "🪫 Low Battery (12%)",
                                desc: "12% SoC · EV Plug Active",
                                action: function() {
                                    if (!clusterTarget) return;
                                    clusterTarget.batteryPercent = 12;
                                    clusterTarget.rangeKm = 71;
                                    clusterTarget.telltaleEvPlug = true;
                                }
                            }
                        ]

                        Rectangle {
                            width: (parent.width - 8) / 2; height: 50; radius: 6
                            color: "#161E2E"; border.color: "#334155"
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: modelData.title; font.pixelSize: 11; font.weight: Font.Bold; color: "#00e5ff" }
                                Text { text: modelData.desc; font.pixelSize: 9; color: "#94A3B8" }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.action()
                            }
                        }
                    }
                }
            }

            // Warning Cards
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    Text { text: "🚨 Pop-up Warning Cards (22 Cards)"; font.pixelSize: 12; font.weight: Font.Bold; color: "#E2E8F0"; anchors.verticalCenter: parent.verticalCenter }
                    Item { Layout.fillWidth: true; width: 10 }
                    Rectangle {
                        width: 120; height: 24; radius: 4; color: "#EF4444"
                        Text { anchors.centerIn: parent; text: "✕ DISMISS ACTIVE"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFFFFF" }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (clusterTarget) clusterTarget.showWarningCard("", ""); }
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
                            { name: "High Speed >120km/h",  file: "warning_speed_120.png",            chime: "critical", col: "#EF4444" },
                            { name: "Accessory Mode",       file: "warning_accessory_mode.png",       chime: "info",     col: "#38BDF8" }
                        ]

                        Rectangle {
                            width: (tab6View.width - 38) / 2; height: 60; radius: 6
                            color: "#161E2E"; border.color: modelData.col; border.width: 1.0; clip: true

                            Image {
                                anchors.fill: parent; anchors.margins: 4
                                source: "../../assets/warnings/" + modelData.file
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (clusterTarget) clusterTarget.showWarningCard(modelData.file, modelData.chime);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
