import QtQuick
import QtQuick.Controls
import "../gauges"
import "../center"
import "../bars"

Item {
    id: drivingCluster
    anchors.fill: parent

    // ═══════════════════════════════════════════════════════════════
    // CLUSTER STATE & TELEMETRY
    // ═══════════════════════════════════════════════════════════════
    property int currentModeIndex: 0
    property var driveModes: ["COMFORT", "SPORT", "ECO", "OFF-ROAD"]
    property string currentMode: driveModes[currentModeIndex]
    property string themeColor: currentMode === "SPORT"    ? "#EF4444" :
                                currentMode === "ECO"      ? "#10B981" :
                                currentMode === "OFF-ROAD" ? "#F59E0B" :
                                "#00e5ff"

    // EV Power & Ignition State (ISO 26262 EV Power Management)
    property string evPowerState:      "READY" // "OFF", "ON", "ACCESSORY", "READY"
    readonly property bool isEvReady:   evPowerState === "READY"
    readonly property bool isAccessoryMode: (evPowerState === "ON" || evPowerState === "ACCESSORY")
    readonly property bool isIgnitionOn: (evPowerState === "ON" || evPowerState === "ACCESSORY" || evPowerState === "READY")
    property bool isGoodbyeActive: false

    SequentialAnimation {
        id: goodbyeSequenceAnim
        running: false

        // Step 1: Set goodbye active; meters, background scenery, status bars and ADAS cars vanish
        PropertyAction { target: drivingCluster; property: "isGoodbyeActive"; value: true }
        ParallelAnimation {
            NumberAnimation { target: roadView; property: "opacity"; to: 0.0; duration: 250; easing.type: Easing.OutQuad }
            NumberAnimation { target: drivingCluster; property: "bgMasterOpacity"; to: 0.0; duration: 350; easing.type: Easing.OutQuad }
            NumberAnimation { target: topStatusBar; property: "opacity"; to: 0.0; duration: 250; easing.type: Easing.OutQuad }
            NumberAnimation { target: bottomBar; property: "opacity"; to: 0.0; duration: 250; easing.type: Easing.OutQuad }
            NumberAnimation { target: topTelltales; property: "opacity"; to: 0.0; duration: 250; easing.type: Easing.OutQuad }
        }

        // Step 2: Hold for 2.4 seconds with the grand APEX Logo + THANK YOU screen
        PauseAnimation { duration: 2400 }

        // Step 3: End goodbye and smoothly transition to charging screen or sleep
        PropertyAction { target: drivingCluster; property: "isGoodbyeActive"; value: false }
    }

    function setEvPowerState(newState) {
        if (evPowerState === newState) return;
        var prevState = evPowerState;
        evPowerState = newState;

        if (newState === "OFF") {
            speedValue = 0;
            powerKw = 0;
            currentGear = "P";
            if (prevState === "READY" || prevState === "ON" || prevState === "ACCESSORY") {
                goodbyeSequenceAnim.restart();
            } else {
                roadView.opacity = 0.0;
                bgMasterOpacity = 0.0;
                topStatusBar.opacity = 0.0;
                bottomBar.opacity = 0.0;
                topTelltales.opacity = 0.0;
            }
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playWarningAlertChime();
            }
        } else if (newState === "ON" || newState === "ACCESSORY") {
            goodbyeSequenceAnim.stop();
            isGoodbyeActive = false;
            speedValue = 0;
            powerKw = 0;
            currentGear = "P";
            roadView.opacity = 1.0;
            bgMasterOpacity = 0.40;
            topStatusBar.opacity = 1.0;
            bottomBar.opacity = 1.0;
            topTelltales.opacity = 1.0;
            if (prevState === "OFF") {
                if (typeof clusterAudio !== "undefined") {
                    clusterAudio.playStartupChime();
                }
            }
        } else if (newState === "READY") {
            goodbyeSequenceAnim.stop();
            isGoodbyeActive = false;
            roadView.opacity = 1.0;
            bgMasterOpacity = 0.85;
            topStatusBar.opacity = 1.0;
            bottomBar.opacity = 1.0;
            topTelltales.opacity = 1.0;
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playInfoAlertChime();
            }
        }
        arbitrateWarnings();
    }

    // ADAS Properties (Active ONLY in EV READY Drive Mode 'D' when not charging)
    property bool adasUserEnabled:     true
    readonly property bool adasActive: adasUserEnabled && !anyDoorOpen && isEvReady && !isCharging && currentGear === "D"
    property real adasLeadDistance:    42.0
    property bool adasLeadVehicle:     true
    property string adasObstacleType:  "car"
    property string adasPassByMode:    "both"
    property bool adasPassByEnabled:   true
    property bool adasLeftTraffic:     true
    property bool adasRightTraffic:    true

    // ═══════════════════════════════════════════════════════════════
    // EV CHARGING SYSTEM (Active in ACC & EV Modes)
    // ═══════════════════════════════════════════════════════════════
    property bool isCharging:          false
    property real chargingRateKw:      150.0   // 7 kW to 350 kW
    property real chargingVoltageV:    800.0   // 800V Architecture
    readonly property real chargingCurrentA: Math.round((chargingRateKw * 1000) / chargingVoltageV)

    Timer {
        id: chargingCycleTimer
        interval: 500
        repeat: true
        running: drivingCluster.isCharging && drivingCluster.batteryPercent < 100
        onTriggered: {
            // Speed of charge directly scales with chargingRateKw
            var step = (drivingCluster.chargingRateKw / 150.0) * 0.25;
            drivingCluster.batteryPercent = Math.min(100.0, Math.round((drivingCluster.batteryPercent + step) * 10) / 10);
            drivingCluster.rangeKm = Math.round(drivingCluster.batteryPercent * 5.95);
        }
    }

    onIsChargingChanged: {
        if (isCharging) {
            speedValue = 0;
            powerKw = -Math.round(chargingRateKw);
            currentGear = "P";
            telltaleEvPlug = true;
            updateWarningState("warning_park_brake.png", false, "warning", false);
            updateWarningState("warning_park_assist_blocked.png", false, "warning", false);
            arbitrateWarnings();
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playInfoAlertChime();
            }
        } else {
            powerKw = 0;
            telltaleEvPlug = (batteryPercent < 15);
            arbitrateWarnings();
        }
    }

    // Driving values: Start at 0 km/h with Gear P on launch
    property real speedValue:      0
    property real powerKw:         0.0
    property real batteryPercent:  72
    property real rangeKm:         428
    property real batteryTemp:     32.0
    property int speedLimit:       80
    property string currentGear:   "P"
    property int ambientTemp:      24
    property string tripMode:      "TRIP A"
    property real tripAKm:         256.8
    property real tripBKm:         104.2
    property real odoKm:           12458.0
    property real tripKm:          tripMode === "TRIP A" ? tripAKm : (tripMode === "TRIP B" ? tripBKm : odoKm)
    property real consumption:     18.2

    property string compassHeading: "SW"
    property int elevationM:        1250
    property real terrainPitchDeg:  8.0
    property real terrainRollDeg:   -3.0

    property bool emulatorOpen:    true

    // ═══════════════════════════════════════════════════════════════
    // TPMS TIRE PRESSURE MONITORING SYSTEM (Indian Standard PSI: 33 PSI)
    // ═══════════════════════════════════════════════════════════════
    property bool tpmsOpen: false
    property real tpmsFlPsi: 33.0
    property real tpmsFrPsi: 33.0
    property real tpmsRlPsi: 33.0
    property real tpmsRrPsi: 33.0

    readonly property bool tpmsHasWarning: (tpmsFlPsi < 30 || tpmsFlPsi > 38 || tpmsFrPsi < 30 || tpmsFrPsi > 38 || tpmsRlPsi < 30 || tpmsRlPsi > 38 || tpmsRrPsi < 30 || tpmsRrPsi > 38 || tpmsFlPsi < 0 || tpmsFrPsi < 0 || tpmsRlPsi < 0 || tpmsRrPsi < 0)

    onTpmsHasWarningChanged: {
        updateWarningState("warning_tpms.png", tpmsHasWarning, "warning", false);
    }

    function toggleTpms() {
        tpmsOpen = !tpmsOpen;
    }

    property bool telltaleTurnLeft:      false
    property bool telltaleSeatbelt:      false
    property bool telltaleAirbag:        false
    property bool telltaleTraction:      false
    property bool telltaleParkBrake:     false
    property bool telltaleAbs:           false
    property bool telltaleCheckEngine:   false
    property bool telltaleBattery12v:    false
    property bool telltaleTpms:          tpmsHasWarning
    property bool telltaleEvPlug:        false

    property bool telltaleAutoHighBeam:  false
    property bool telltaleLowBeam:       false
    property bool telltaleHighBeam:      false
    property bool telltaleFogLamp:       false
    property bool telltaleBatteryTemp:   false
    property bool telltaleMasterWarning: false
    property bool telltaleDoorOpen:      anyDoorOpen
    property bool telltaleTurnRight:     false

    // ═══════════════════════════════════════════════════════════════
    // VEHICLE ACCESS & DOOR AJAR SAFETY SYSTEM
    // ═══════════════════════════════════════════════════════════════
    property bool doorFrontLeft:  false
    property bool doorFrontRight: false
    property bool doorRearLeft:   false
    property bool doorRearRight:  false
    property bool bonnetOpen:     false
    property bool trunkOpen:      false

    readonly property bool anyDoorOpen: doorFrontLeft || doorFrontRight || doorRearLeft || doorRearRight || bonnetOpen || trunkOpen

    onAnyDoorOpenChanged: {
        updateDoorSafetyState();
    }

    function updateDoorSafetyState() {
        if (anyDoorOpen) {
            if (currentGear === "D" || currentGear === "R") {
                updateWarningState("warning_door_open.png", true, "warning", false);
                doorAlarmChimeTimer.start();
            } else {
                doorAlarmChimeTimer.stop();
                updateWarningState("warning_door_open.png", false, "warning", false);
            }
        } else {
            doorAlarmChimeTimer.stop();
            updateWarningState("warning_door_open.png", false, "warning", false);
        }
    }

    Timer {
        id: doorAlarmChimeTimer
        interval: 900
        repeat: true
        running: false
        onTriggered: {
            if (typeof clusterAudio !== "undefined" && drivingCluster.opacity > 0.5) {
                clusterAudio.playWarningAlertChime();
            }
        }
    }

    property bool bulbCheckActive:    false
    property real startupPowerSweep:  0.0
    property real startupTempSweep:   32.0
    property real startupSpeedSweep:  0.0
    property bool isSelfTestRunning:  false

    // ═══════════════════════════════════════════════════════════════
    // NAVIGATION TELEMETRY
    // ═══════════════════════════════════════════════════════════════
    property bool navActive:          true
    property string navState:         "GUIDING" // "GUIDING", "RECALCULATING", "ARRIVED", "GPS_LOST"
    property string navManeuver:      "turn_right" // "turn_right", "turn_left", "slight_right", "slight_left", "sharp_right", "sharp_left", "u_turn", "straight", "roundabout"
    property string navDistance:      "350 m"
    property string navStreet:        "MG Road"
    property string navDuration:      "14 min"
    property string navRemainingKm:   "8.4 km"
    property string navEta:           computeNavEta(14)
    property bool gpsLost:            false

    function computeNavEta(durationMinutes) {
        var d = new Date(Date.now() + (durationMinutes || 14) * 60000);
        var hours = d.getHours();
        var minutes = d.getMinutes();
        var ampm = hours >= 12 ? "PM" : "AM";
        var h12 = hours % 12;
        if (h12 === 0) h12 = 12;
        var mStr = (minutes < 10 ? "0" : "") + minutes;
        var hStr = (h12 < 10 ? "0" : "") + h12;
        return hStr + ":" + mStr + " " + ampm;
    }

    onCurrentGearChanged: {
        updateDoorSafetyState();
        if (currentGear === "P") {
            speedValue = 0;
            powerKw = 0;
            telltaleParkBrake = true;
            if (!isSelfTestRunning && drivingCluster.opacity > 0.5 && !anyDoorOpen && !isCharging) {
                showWarningCard("warning_park_brake.png", "warning");
            }
        } else {
            telltaleParkBrake = false;
            updateWarningState("warning_park_brake.png", false, "warning", false);
            if (currentGear === "N") {
                speedValue = 0;
                powerKw = 0;
            }
        }
    }

    property string modeSplashIcon: "⚡"
    property string modeSplashText: "COMFORT CRUISING ACTIVE"

    function activateCluster() {
        if (typeof clusterAudio !== "undefined") {
            clusterAudio.playEngineRev();
        }
        roadView.opacity = 0.0;
        drivingCluster.bgMasterOpacity = 0.0;
        startupSelfTestAnim.restart();
    }

    function triggerModeChange(newIndex) {
        currentModeIndex = newIndex;
        var mode = driveModes[currentModeIndex];
        if (mode === "SPORT") {
            modeSplashIcon = "🏎️";
            modeSplashText = "PERFORMANCE DYNAMICS ACTIVE";
        } else if (mode === "ECO") {
            modeSplashIcon = "🌱";
            modeSplashText = "RANGE EFFICIENCY OPTIMIZED";
        } else if (mode === "OFF-ROAD") {
            modeSplashIcon = "🏔️";
            modeSplashText = "ALL-TERRAIN TRACTION ACTIVE";
        } else {
            modeSplashIcon = "⚡";
            modeSplashText = "COMFORT CRUISING ACTIVE";
        }
        if (typeof clusterAudio !== "undefined") {
            clusterAudio.playModeShiftChime();
        }
        modeSplashAnim.restart();
    }

    function toggleDriveMode() {
        triggerModeChange((currentModeIndex + 1) % driveModes.length);
    }

    // ═══════════════════════════════════════════════════════════════
    // TRIP COMPUTER & ODOMETER CONTROLS
    // ═══════════════════════════════════════════════════════════════
    function cycleTripMode() {
        if (tripMode === "TRIP A") {
            tripMode = "TRIP B";
        } else if (tripMode === "TRIP B") {
            tripMode = "ODO";
        } else {
            tripMode = "TRIP A";
        }
        if (typeof clusterAudio !== "undefined") {
            clusterAudio.playInfoAlertChime();
        }
    }

    function resetCurrentTrip() {
        if (tripMode === "TRIP A") {
            tripAKm = 0.0;
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playModeShiftChime();
            }
            return true;
        } else if (tripMode === "TRIP B") {
            tripBKm = 0.0;
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playModeShiftChime();
            }
            return true;
        }
        return false;
    }

    function resetTripA() {
        tripAKm = 0.0;
        if (typeof clusterAudio !== "undefined") {
            clusterAudio.playModeShiftChime();
        }
    }

    function resetTripB() {
        tripBKm = 0.0;
        if (typeof clusterAudio !== "undefined") {
            clusterAudio.playModeShiftChime();
        }
    }

    // Dynamic Odometer & Trip Accumulation Timer (Active when moving)
    Timer {
        id: odometerAccumulationTimer
        interval: 200
        repeat: true
        running: speedValue > 0 && (currentGear === "D" || currentGear === "R")
        onTriggered: {
            var deltaKm = (speedValue / 3600.0) * 0.2;
            tripAKm = (tripAKm + deltaKm >= 9999.0) ? (tripAKm + deltaKm - 9999.0) : (tripAKm + deltaKm);
            tripBKm = (tripBKm + deltaKm >= 9999.0) ? (tripBKm + deltaKm - 9999.0) : (tripBKm + deltaKm);
            odoKm = Math.min(999999.0, odoKm + deltaKm);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // AUTOMOTIVE WARNING ARBITRATION & PRIORITY HIERARCHY ENGINE
    // Rules:
    // 1. Only ONE warning card displayed on cluster at any time.
    // 2. Strict ISO 26262 Priority Hierarchy (P1 > P2 > P3 > P4).
    // 3. Higher priority immediately preempts lower priority cards.
    // 4. When higher priority clears, next highest active warning resumes.
    // ═══════════════════════════════════════════════════════════════

    readonly property var warningPriorityMap: ({
        // P1: Critical Immediate Hazard (Life / Crash Safety)
        "warning_forward_collision.png":    10,
        "warning_battery_overheat.png":      12,
        "warning_speed_120.png":             14,
        "warning_airbag.png":                16,
        "warning_hands_on_wheel.png":        18,

        // P2: Critical Vehicle Operation & Interlocks
        "warning_low_battery.png":           20,
        "warning_seatbelt.png":              22,
        "warning_door_open.png":             24,
        "warning_park_brake.png":            26,
        "warning_charging_port_open.png":    28,
        "warning_check_vehicle.png":         30,
        "warning_steering_assist.png":       32,

        // P3: Vehicle Dynamics, ESC & ADAS Warnings
        "warning_accessory_mode.png":        35,
        "warning_speed_80.png":              40,
        "warning_low_traction.png":          42,
        "warning_traction_off.png":          44,
        "warning_lka_unavailable.png":       46,
        "warning_park_assist_blocked.png":   48,
        "warning_tpms.png":                  50,

        // P4: Auxiliary / Status Informational
        "warning_hill_descent.png":          60,
        "warning_washer_fluid.png":          62,
        "warning_ready_to_drive.png":        64
    })

    function getWarningPriority(filename) {
        if (!filename) return 999;
        if (warningPriorityMap[filename] !== undefined) {
            return warningPriorityMap[filename];
        }
        return 50; // default moderate priority
    }

    property var activeWarningList: []
    property string activeWarningCardSource: ""
    property int currentActivePriority: 999

    Timer {
        id: dismissTimer
        interval: 3800
        repeat: false
        property string targetFile: ""
        onTriggered: {
            if (targetFile !== "") {
                drivingCluster.updateWarningState(targetFile, false, "", false);
                targetFile = "";
            }
        }
    }

    function updateWarningState(cardFileName, isActive, chimeType, persistent) {
        if (!cardFileName || cardFileName === "") return;
        var list = activeWarningList.slice();
        var idx = -1;
        for (var i = 0; i < list.length; i++) {
            if (list[i].file === cardFileName) {
                idx = i;
                break;
            }
        }

        if (isActive) {
            var prio = getWarningPriority(cardFileName);
            var item = {
                file: cardFileName,
                prio: prio,
                chime: chimeType || "warning",
                persistent: !!persistent,
                timestamp: Date.now()
            };
            if (idx >= 0) {
                list[idx] = item;
            } else {
                list.push(item);
            }
        } else {
            if (idx >= 0) {
                list.splice(idx, 1);
            }
        }
        activeWarningList = list;
        arbitrateWarnings();
    }

    function arbitrateWarnings() {
        if (isSelfTestRunning) return;

        // If goodbye sequence is running, hide warning cards
        if (isGoodbyeActive) {
            activeWarningCardSource = "";
            currentActivePriority = 999;
            warningCardAnim.stop();
            warningCardBanner.opacity = 0.0;
            return;
        }

        // In IGN OFF mode, no warning cards are shown
        if (evPowerState === "OFF") {
            activeWarningCardSource = "";
            currentActivePriority = 999;
            warningCardAnim.stop();
            warningCardBanner.opacity = 0.0;
            return;
        }

        // In IGN ON / Accessory mode, strictly show the Accessory Mode card
        if (isAccessoryMode) {
            var accSource = "../../assets/warnings/warning_accessory_mode.png";
            if (activeWarningCardSource !== accSource) {
                activeWarningCardSource = accSource;
                currentActivePriority = 1;
                warningCardAnim.stop();
                warningCardBanner.opacity = 1.0;
                warningCardBanner.scale = 1.0;
            }
            return;
        }

        if (!activeWarningList || activeWarningList.length === 0) {
            activeWarningCardSource = "";
            currentActivePriority = 999;
            warningCardAnim.stop();
            warningCardBanner.opacity = 0.0;
            return;
        }

        // Filter out accessory mode and parking-related cards when in EV READY / Charging
        var readyList = activeWarningList.filter(function(w) {
            if (w.file === "warning_accessory_mode.png") return false;
            if (isCharging && (w.file === "warning_park_brake.png" || w.file === "warning_park_assist_blocked.png")) return false;
            return true;
        });

        if (readyList.length === 0) {
            activeWarningCardSource = "";
            currentActivePriority = 999;
            warningCardAnim.stop();
            warningCardBanner.opacity = 0.0;
            return;
        }

        // Sort by priority ASC (lower number = higher priority), then newest timestamp DESC
        var sorted = readyList.slice().sort(function(a, b) {
            if (a.prio !== b.prio) return a.prio - b.prio;
            return b.timestamp - a.timestamp;
        });

        var topWarning = sorted[0];
        var newSource = "../../assets/warnings/" + topWarning.file;

        if (activeWarningCardSource !== newSource) {
            activeWarningCardSource = newSource;
            currentActivePriority = topWarning.prio;

            // Play appropriate audio chime
            if (typeof clusterAudio !== "undefined") {
                if (topWarning.chime === "critical") {
                    clusterAudio.playCriticalAlertChime();
                } else if (topWarning.chime === "warning") {
                    clusterAudio.playWarningAlertChime();
                } else {
                    clusterAudio.playInfoAlertChime();
                }
            }

            if (topWarning.persistent || topWarning.prio <= 15) {
                warningCardAnim.stop();
                warningCardBanner.opacity = 1.0;
                warningCardBanner.scale = 1.0;
            } else {
                warningCardAnim.restart();
            }
        }
    }

    function showWarningCard(cardFileName, chimeType) {
        if (!cardFileName || cardFileName === "") {
            activeWarningList = [];
            arbitrateWarnings();
            return;
        }

        if (evPowerState !== "READY") {
            // In Accessory / Off mode, suppress all pop-up driving warnings
            return;
        }

        var isPersistent = (cardFileName === "warning_speed_120.png" || cardFileName === "warning_forward_collision.png" || cardFileName === "warning_battery_overheat.png");
        updateWarningState(cardFileName, true, chimeType, isPersistent);

        if (!isPersistent) {
            dismissTimer.targetFile = cardFileName;
            dismissTimer.restart();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // FORWARD COLLISION SYSTEM (<13m with recurring critical chime)
    // ═══════════════════════════════════════════════════════════════
    property bool isForwardCollisionActive: adasActive && adasLeadVehicle && (adasLeadDistance <= 13.0) && !isSelfTestRunning

    Timer {
        id: collisionBeepTimer
        interval: 700
        repeat: true
        running: drivingCluster.isForwardCollisionActive
        onTriggered: {
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playCriticalAlertChime();
            }
        }
    }

    onIsForwardCollisionActiveChanged: {
        updateWarningState("warning_forward_collision.png", isForwardCollisionActive, "critical", true);
    }

    // ═══════════════════════════════════════════════════════════════
    // SPEED WARNING ALERTS (>80 km/h single chime, >120 km/h recurring 2s chime)
    // ═══════════════════════════════════════════════════════════════
    property int prevSpeedValue: 0
    property bool isHighSpeedActive: (speedValue > 120) && !isSelfTestRunning

    Timer {
        id: highSpeedBeepTimer
        interval: 2000
        repeat: true
        running: drivingCluster.isHighSpeedActive
        onTriggered: {
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playCriticalAlertChime();
            }
        }
    }

    onSpeedValueChanged: {
        if (evPowerState !== "READY" && speedValue > 0) {
            speedValue = 0;
            powerKw = 0;
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playWarningAlertChime();
            }
            return;
        }

        if (isSelfTestRunning) return;

        // 80 km/h speed threshold crossing (Single chime + popup)
        if (speedValue > 80 && prevSpeedValue <= 80 && speedValue <= 120) {
            showWarningCard("warning_speed_80.png", "warning");
        }

        prevSpeedValue = speedValue;
    }

    onIsHighSpeedActiveChanged: {
        updateWarningState("warning_speed_120.png", isHighSpeedActive, "critical", true);
    }

    onBatteryPercentChanged: {
        if (batteryPercent <= 12 && !isSelfTestRunning) {
            telltaleEvPlug = true;
            updateWarningState("warning_low_battery.png", true, "warning", false);
        } else if (batteryPercent > 15) {
            updateWarningState("warning_low_battery.png", false, "warning", false);
        }
    }

    onBatteryTempChanged: {
        if (batteryTemp >= 65 && !isSelfTestRunning) {
            telltaleBatteryTemp = true;
            updateWarningState("warning_battery_overheat.png", true, "critical", true);
        } else if (batteryTemp < 55) {
            updateWarningState("warning_battery_overheat.png", false, "critical", true);
        }
    }

    // Toggle all warnings for testing/demonstration
    function toggleAllWarnings() {
        var nextState = !telltaleSeatbelt;
        telltaleSeatbelt      = nextState;
        telltaleAirbag        = nextState;
        telltaleTraction      = nextState;
        telltaleParkBrake     = nextState;
        telltaleAbs           = nextState;
        telltaleCheckEngine   = nextState;
        telltaleBattery12v    = nextState;
        telltaleTpms          = nextState;
        telltaleEvPlug        = nextState;
        telltaleAutoHighBeam  = nextState;
        telltaleLowBeam       = nextState;
        telltaleHighBeam      = nextState;
        telltaleFogLamp       = nextState;
        telltaleBatteryTemp   = nextState;
        telltaleMasterWarning = nextState;
        telltaleDoorOpen      = nextState;
    }

    // ═══════════════════════════════════════════════════════════════
    // OEM AUTOMOTIVE SELF-TEST BOOTUP SEQUENCE (Right After Welcome)
    // ═══════════════════════════════════════════════════════════════
    SequentialAnimation {
        id: startupSelfTestAnim

        // Phase 1: Cluster UI elements fade in; all telltales turn ON in bulb-check; gauges sweep to MAX
        ParallelAnimation {
            PropertyAction { target: drivingCluster; property: "bulbCheckActive"; value: true }
            PropertyAction { target: drivingCluster; property: "isSelfTestRunning"; value: true }
            PropertyAction { target: roadView;       property: "opacity"; value: 0.0 }
            PropertyAction { target: drivingCluster; property: "bgMasterOpacity"; value: 0.0 }

            NumberAnimation { target: topTelltales;    property: "opacity"; from: 0; to: 1; duration: 400;  easing.type: Easing.OutCubic }
            NumberAnimation { target: topStatusBar;    property: "opacity"; from: 0; to: 1; duration: 500;  easing.type: Easing.OutCubic }
            NumberAnimation { target: bottomBar;       property: "opacity"; from: 0; to: 1; duration: 500;  easing.type: Easing.OutCubic }
            NumberAnimation { target: leftGauge;       property: "opacity"; from: 0; to: 1; duration: 600;  easing.type: Easing.OutCubic }
            NumberAnimation { target: rightGauge;      property: "opacity"; from: 0; to: 1; duration: 600;  easing.type: Easing.OutCubic }
            NumberAnimation { target: centerSpeed;     property: "opacity"; from: 0; to: 1; duration: 600;  easing.type: Easing.OutCubic }

            NumberAnimation {
                target: drivingCluster
                property: "startupPowerSweep"
                from: 0.0
                to: 300.0
                duration: 1400
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: drivingCluster
                property: "startupTempSweep"
                from: 0.0
                to: 85.0
                duration: 1400
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: drivingCluster
                property: "startupSpeedSweep"
                from: 0.0
                to: 188.0
                duration: 1300
                easing.type: Easing.OutCubic
            }
        }

        // Peak Hold during highest rev scream
        PauseAnimation { duration: 400 }

        // Phase 2: Needles sweep smoothly back to idle during overrun
        ParallelAnimation {
            NumberAnimation {
                target: drivingCluster
                property: "startupPowerSweep"
                from: 300.0
                to: 0.0
                duration: 1200
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: drivingCluster
                property: "startupTempSweep"
                from: 85.0
                to: 32.0
                duration: 1200
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: drivingCluster
                property: "startupSpeedSweep"
                from: 188.0
                to: 0.0
                duration: 1100
                easing.type: Easing.InOutCubic
            }
        }

        // Phase 3: Bulb Check completes -> ALL telltales turn OFF directly, Park Brake stays ON if in Gear P
        PropertyAction { target: drivingCluster; property: "bulbCheckActive"; value: false }
        PropertyAction { target: drivingCluster; property: "telltaleParkBrake"; value: (drivingCluster.currentGear === "P") }
        PropertyAction { target: drivingCluster; property: "isSelfTestRunning"; value: false }

        // Phase 4: AFTER bootup self-test completes, Scenery Background & ADAS Road smoothly fade in if EV Ready
        ParallelAnimation {
            NumberAnimation { target: drivingCluster; property: "bgMasterOpacity"; from: 0.0; to: (drivingCluster.isEvReady ? 0.85 : 0.40); duration: 1500; easing.type: Easing.InOutCubic }
            NumberAnimation { target: roadView;       property: "opacity";         from: 0.0; to: (drivingCluster.isIgnitionOn ? 1.0 : 0.0); duration: 1500; easing.type: Easing.InOutCubic }
            NumberAnimation { target: roadView;       property: "scale";           from: 0.94; to: 1.0; duration: 1500; easing.type: Easing.OutBack }
        }

        // Phase 5: After all loading completes, if the car is in Park (P), display the Parking Brake Warning Card
        ScriptAction {
            script: {
                if (drivingCluster.currentGear === "P") {
                    drivingCluster.showWarningCard("warning_park_brake.png", "warning");
                }
            }
        }
    }

    property string activeBackground:   "mountain" // "mountain", "city", "coastal"
    property bool autoCycleBackground:  false
    property real bgMasterOpacity:      0.0

    Timer {
        id: bgCycleTimer
        interval: 35000
        repeat: true
        running: drivingCluster.autoCycleBackground
        onTriggered: {
            var bgs = ["mountain", "city", "coastal"];
            var idx = bgs.indexOf(drivingCluster.activeBackground);
            drivingCluster.activeBackground = bgs[(idx + 1) % bgs.length];
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 1. MASTER MULTI-ENVIRONMENT SCENERY (Smooth Crossfade)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: "#030406"
    }

    // 1. Mountain Twilight Pass
    Image {
        id: mountainBg
        anchors.fill: parent
        source: "../../assets/wallpapers/cluster_mountain_horizon.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: (drivingCluster.activeBackground === "mountain") ? drivingCluster.bgMasterOpacity : 0.0
        smooth: true
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    }

    // 2. Cyberpunk City Night Skyline
    Image {
        id: cityBg
        anchors.fill: parent
        source: "../../assets/wallpapers/cluster_city_night.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: (drivingCluster.activeBackground === "city") ? drivingCluster.bgMasterOpacity : 0.0
        smooth: true
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    }

    // 3. Coastal Ocean Sunset
    Image {
        id: coastalBg
        anchors.fill: parent
        source: "../../assets/wallpapers/cluster_coastal_sunset.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: (drivingCluster.activeBackground === "coastal") ? drivingCluster.bgMasterOpacity : 0.0
        smooth: true
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutCubic } }
    }

    // Upper Sky Ambient Starfield Twinkle
    StarfieldSky {
        id: starfieldSky
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.42
        opacity: drivingCluster.bgMasterOpacity
    }

    // Subtle atmospheric vignette & side gauge contrast shields
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#CC030406" }
            GradientStop { position: 0.38; color: "#22030406" }
            GradientStop { position: 0.72; color: "#33030406" }
            GradientStop { position: 1.0; color: "#F0030406" }
        }
    }

    // Left gauge darkening shield
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.30
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#E0030406" }
            GradientStop { position: 0.75; color: "#90030406" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Right gauge darkening shield
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.30
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.25; color: "#90030406" }
            GradientStop { position: 1.0; color: "#E0030406" }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 2. TOP TELLTALE BAR (21 OEM Standard Telltales)
    // ═══════════════════════════════════════════════════════════════
    TelltaleBar {
        id: topTelltales
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        bulbCheckActive: drivingCluster.bulbCheckActive
        turnLeft:      drivingCluster.telltaleTurnLeft
        seatbelt:      drivingCluster.telltaleSeatbelt
        airbag:        drivingCluster.telltaleAirbag
        traction:      drivingCluster.telltaleTraction
        parkBrake:     drivingCluster.telltaleParkBrake
        abs:           drivingCluster.telltaleAbs
        checkEngine:   drivingCluster.telltaleCheckEngine
        battery12v:    drivingCluster.telltaleBattery12v
        tpms:          drivingCluster.telltaleTpms
        evPlug:        drivingCluster.telltaleEvPlug
        neutral:       (drivingCluster.currentGear === "N")
        autoHighBeam:  drivingCluster.telltaleAutoHighBeam
        lowBeam:       drivingCluster.telltaleLowBeam
        highBeam:      drivingCluster.telltaleHighBeam
        fogLamp:       drivingCluster.telltaleFogLamp
        batteryTemp:   drivingCluster.telltaleBatteryTemp
        masterWarning: drivingCluster.telltaleMasterWarning
        doorOpen:      drivingCluster.telltaleDoorOpen
        turnRight:     drivingCluster.telltaleTurnRight
        opacity: 0

        onTpmsClicked: drivingCluster.toggleTpms()
    }

    // ═══════════════════════════════════════════════════════════════
    // 3. TOP STATUS BAR (10:42 AM | COMFORT | ADAS PILOT | 24°C | GPS | LTE)
    // ═══════════════════════════════════════════════════════════════
    TopStatusBar {
        id: topStatusBar
        anchors.top: topTelltales.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        driveMode:   drivingCluster.currentMode
        themeColor:  drivingCluster.themeColor
        adasActive:  drivingCluster.adasActive
        isEvReady:   drivingCluster.isEvReady
        temperature: drivingCluster.ambientTemp
        gpsLost:     drivingCluster.gpsLost
        opacity: 0
    }

    // ═══════════════════════════════════════════════════════════════
    // 4. 3-LANE ADAS HIGHWAY ROAD VIEW
    // ═══════════════════════════════════════════════════════════════
    AdasRoadView {
        id: roadView
        anchors.fill: parent
        speed: drivingCluster.speedValue
        themeColor: drivingCluster.themeColor
        currentGear: drivingCluster.currentGear
        adasActive: drivingCluster.adasActive
        leadDistanceMeters: drivingCluster.adasLeadDistance
        showLeadVehicle: drivingCluster.adasLeadVehicle
        obstacleType: drivingCluster.adasObstacleType
        passByMode: drivingCluster.adasPassByMode
        showRightVehicle: drivingCluster.adasRightTraffic
        autoPassByEnabled: drivingCluster.adasPassByEnabled
        navActive: drivingCluster.navActive && drivingCluster.isEvReady
        navState: drivingCluster.navState
        navManeuver: drivingCluster.navManeuver
        navDistance: drivingCluster.navDistance
        navStreet: drivingCluster.navStreet
        navEta: drivingCluster.navEta
        navDuration: drivingCluster.navDuration
        navRemainingKm: drivingCluster.navRemainingKm
        gpsLost: drivingCluster.gpsLost
        doorFrontLeft:  drivingCluster.doorFrontLeft
        doorFrontRight: drivingCluster.doorFrontRight
        doorRearLeft:   drivingCluster.doorRearLeft
        doorRearRight:  drivingCluster.doorRearRight
        bonnetOpen:     drivingCluster.bonnetOpen
        trunkOpen:      drivingCluster.trunkOpen
        isAccessoryMode: drivingCluster.isAccessoryMode
        isCharging:     drivingCluster.isCharging
        chargingRateKw: drivingCluster.chargingRateKw
        batteryPercent: drivingCluster.batteryPercent
        opacity: (drivingCluster.isIgnitionOn && !drivingCluster.isSelfTestRunning && !drivingCluster.isGoodbyeActive) ? 1.0 : 0.0
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 5. LEFT POWER GAUGE (0-300 kW Power, Green REGEN Zone)
    // ═══════════════════════════════════════════════════════════════
    PowerGauge {
        id: leftGauge
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.top: topStatusBar.bottom
        anchors.topMargin: 10
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: 6
        width: parent.width * 0.28
        powerKw: drivingCluster.isSelfTestRunning ? drivingCluster.startupPowerSweep : drivingCluster.powerKw
        themeColor: drivingCluster.themeColor
        opacity: (drivingCluster.isGoodbyeActive || drivingCluster.evPowerState === "OFF") ? 0.0 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.InOutCubic }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 6. CENTER SPEED DISPLAY (0 km/h + 80 Speed Limit Sign)
    // ═══════════════════════════════════════════════════════════════
    CentralSpeed {
        id: centerSpeed
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: topStatusBar.bottom
        anchors.topMargin: 6
        width: parent.width * 0.38
        height: 210
        speedValue: Math.round(drivingCluster.isSelfTestRunning ? drivingCluster.startupSpeedSweep : drivingCluster.speedValue)
        driveMode:  drivingCluster.currentMode
        themeColor: drivingCluster.themeColor
        speedLimit: drivingCluster.speedLimit
        showSpeedLimit: !drivingCluster.isSelfTestRunning && (roadView.opacity > 0.5)
        opacity: (drivingCluster.isGoodbyeActive || drivingCluster.evPowerState === "OFF") ? 0.0 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.InOutCubic }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 7. RIGHT BATTERY TEMPERATURE GAUGE (32°C, OPTIMAL, TRIP A)
    // ═══════════════════════════════════════════════════════════════
    BatteryTempGauge {
        id: rightGauge
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: topStatusBar.bottom
        anchors.topMargin: 10
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: 6
        width: parent.width * 0.28
        batteryTemp:    drivingCluster.isSelfTestRunning ? drivingCluster.startupTempSweep : drivingCluster.batteryTemp
        tripMode:       drivingCluster.tripMode
        tripAKm:        drivingCluster.tripAKm
        tripBKm:        drivingCluster.tripBKm
        odoKm:          drivingCluster.odoKm
        tripKm:         drivingCluster.tripKm
        consumption:    drivingCluster.consumption
        themeColor:     drivingCluster.themeColor
        opacity: (drivingCluster.isGoodbyeActive || drivingCluster.evPowerState === "OFF") ? 0.0 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.InOutCubic }
        }

        onCycleTripRequested: drivingCluster.cycleTripMode()
        onResetTripRequested: drivingCluster.resetCurrentTrip()
    }

    // ═══════════════════════════════════════════════════════════════
    // 8. BOTTOM INFO BAR ([🔋] 72% --- 428 km | P R N D | 1250 m | SW)
    // ═══════════════════════════════════════════════════════════════
    BottomInfoBar {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        batteryPercent: drivingCluster.batteryPercent
        rangeKm:        drivingCluster.rangeKm
        gear:           drivingCluster.currentGear
        themeColor:     drivingCluster.themeColor
        driveMode:      drivingCluster.currentMode
        heading:        drivingCluster.compassHeading
        altitudeM:      drivingCluster.elevationM
        pitchDeg:       drivingCluster.terrainPitchDeg
        rollDeg:        drivingCluster.terrainRollDeg
        tpmsFl:         drivingCluster.tpmsFlPsi
        tpmsFr:         drivingCluster.tpmsFrPsi
        tpmsRl:         drivingCluster.tpmsRlPsi
        tpmsRr:         drivingCluster.tpmsRrPsi
        opacity: 0
    }

    // ═══════════════════════════════════════════════════════════════
    // 9. FLOATING ECU EMULATOR TRIGGER BUTTON (Bottom-Right)
    // ═══════════════════════════════════════════════════════════════
    // 9. COMPACT & DRAGGABLE ECU EMULATOR TRIGGER BUTTON
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: emulatorTriggerBadge
        x: parent.width - width - 18
        y: parent.height - height - 16
        width: 82
        height: 24
        radius: 12
        color: emulatorTriggerMouse.drag.active ? "#0284C7" : (emulatorTriggerMouse.containsMouse ? "#1E293B" : "#0F172A")
        border.color: emulatorTriggerMouse.containsMouse ? "#00E5FF" : "#38BDF8"
        border.width: 1
        z: 100
        opacity: emulatorTriggerMouse.drag.active ? 0.95 : (emulatorTriggerMouse.containsMouse ? 0.9 : 0.75)

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Row {
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: "⚙️"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "ECU"
                font.pixelSize: 9
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                font.family: "Inter"
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: emulatorTriggerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            drag.target: emulatorTriggerBadge
            drag.minimumX: 10
            drag.maximumX: drivingCluster.width - emulatorTriggerBadge.width - 10
            drag.minimumY: 10
            drag.maximumY: drivingCluster.height - emulatorTriggerBadge.height - 10

            property point pressPos: Qt.point(0, 0)
            property bool moved: false

            onPressed: function(mouse) {
                pressPos = Qt.point(mouse.x, mouse.y);
                moved = false;
            }

            onPositionChanged: function(mouse) {
                if (Math.abs(mouse.x - pressPos.x) > 3 || Math.abs(mouse.y - pressPos.y) > 3) {
                    moved = true;
                }
            }

            onClicked: function(mouse) {
                if (!moved) {
                    drivingCluster.emulatorOpen = !drivingCluster.emulatorOpen;
                }
            }
        }
    }

    property string activeModeCardSource: currentMode === "SPORT"    ? "../../assets/modes/mode_card_sport.png" :
                                          currentMode === "ECO"      ? "../../assets/modes/mode_card_eco.png" :
                                          currentMode === "OFF-ROAD" ? "../../assets/modes/mode_card_offroad.png" :
                                          "../../assets/modes/mode_card_comfort.png"

    // ═══════════════════════════════════════════════════════════════
    // 10. PURE DRIVE MODE CARD SPLASH (Pure Floating Card with Chime)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: modeSplashBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -20
        width: 175
        height: 275
        z: 95
        opacity: 0.0
        scale: 0.88

        Image {
            anchors.fill: parent
            source: drivingCluster.activeModeCardSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        SequentialAnimation {
            id: modeSplashAnim
            ParallelAnimation {
                NumberAnimation { target: modeSplashBanner; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { target: modeSplashBanner; property: "scale";   from: 0.86; to: 1.0; duration: 320; easing.type: Easing.OutBack }
            }
            PauseAnimation { duration: 1500 }
            ParallelAnimation {
                NumberAnimation { target: modeSplashBanner; property: "opacity"; to: 0.0; duration: 400; easing.type: Easing.InCubic }
                NumberAnimation { target: modeSplashBanner; property: "scale";   to: 1.06; duration: 400; easing.type: Easing.InCubic }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 11. PURE WARNING NOTIFICATION CARD (Slide-up Overlay with Chimes)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: warningCardBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: 12
        width: 390
        height: 110
        z: 96
        opacity: (drivingCluster.isForwardCollisionActive || drivingCluster.isHighSpeedActive) ? 1.0 : 0.0
        scale: (drivingCluster.isForwardCollisionActive || drivingCluster.isHighSpeedActive) ? 1.0 : 0.92

        Behavior on opacity {
            enabled: (drivingCluster.isForwardCollisionActive || drivingCluster.isHighSpeedActive)
            NumberAnimation { duration: 250 }
        }

        Image {
            anchors.fill: parent
            source: drivingCluster.activeWarningCardSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        SequentialAnimation {
            id: warningCardAnim
            running: false
            ParallelAnimation {
                NumberAnimation { target: warningCardBanner; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { target: warningCardBanner; property: "scale";   from: 0.90; to: 1.0; duration: 300; easing.type: Easing.OutBack }
            }
            PauseAnimation { duration: 3200 }
            ParallelAnimation {
                NumberAnimation {
                    target: warningCardBanner
                    property: "opacity"
                    to: (drivingCluster.isForwardCollisionActive || drivingCluster.isHighSpeedActive) ? 1.0 : 0.0
                    duration: 400
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: warningCardBanner
                    property: "scale"
                    to: (drivingCluster.isForwardCollisionActive || drivingCluster.isHighSpeedActive) ? 1.0 : 0.95
                    duration: 400
                    easing.type: Easing.InCubic
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 11. CENTRAL GOODBYE SCREEN (Grand APEX Logo + THANK YOU)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: goodbyeContainer
        anchors.fill: parent
        z: 92
        opacity: drivingCluster.isGoodbyeActive ? 1.0 : 0.0
        scale: drivingCluster.isGoodbyeActive ? 1.0 : 0.96
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 450; easing.type: Easing.OutBack }
        }

        // 1. Central Large APEX Wordmark (Covering prominent screen area like WelcomeScreen)
        Item {
            id: goodbyeWordmarkContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -30
            width: parent.width * 0.42
            height: width * 0.42

            Image {
                id: goodbyeWordmarkImage
                anchors.fill: parent
                source: "../../assets/branding/apex_wordmark.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        // 2. Dynamic QML Thank You Section (Mirroring the grand Welcome screen typography)
        Item {
            id: thankYouTextContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: goodbyeWordmarkContainer.bottom
            anchors.topMargin: -15
            width: 600
            height: 120

            // "THANK YOU" Heading
            Text {
                id: thankYouHeading
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: "THANK YOU"
                font.pixelSize: 18
                font.weight: Font.Light
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 15
                color: "#CBD5E1"
                renderType: Text.NativeRendering
            }

            // "HAVE A SAFE DRIVE." with Glowing Cyan Dot
            Row {
                id: goodbyeSubRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: thankYouHeading.bottom
                anchors.topMargin: 12
                spacing: 1

                Text {
                    text: "HAVE A SAFE DRIVE"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 18
                    color: "#F8FAFC"
                    renderType: Text.NativeRendering
                }

                // Glowing Cyan Period Dot
                Text {
                    text: "."
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: "#00e5ff"
                    renderType: Text.NativeRendering

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.4; duration: 1200; easing.type: Easing.InOutSine }
                    }
                }
            }

            // Delicate Cyan Indicator Line
            Rectangle {
                id: goodbyeIndicatorLine
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: goodbyeSubRow.bottom
                anchors.topMargin: 14
                width: 160
                height: 2
                radius: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.25; color: "#4000e5ff" }
                    GradientStop { position: 0.5; color: "#00e5ff" }
                    GradientStop { position: 0.75; color: "#4000e5ff" }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.35; duration: 1600; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 12. DEDICATED EV CHARGING SCREEN (Active ONLY in IGN OFF when charging)
    // ═══════════════════════════════════════════════════════════════
    ChargingScreen {
        id: standaloneChargingView
        anchors.fill: parent
        z: 98
        isCharging: drivingCluster.isCharging
        batteryPercent: drivingCluster.batteryPercent
        chargingRateKw: drivingCluster.chargingRateKw
        rangeKm: drivingCluster.rangeKm
        ambientTemp: drivingCluster.ambientTemp
        elevationM: drivingCluster.elevationM
        compassHeading: drivingCluster.compassHeading
        currentGear: drivingCluster.currentGear
        driveMode: drivingCluster.currentMode
        themeColor: drivingCluster.themeColor
        opacity: (drivingCluster.isCharging && !drivingCluster.isGoodbyeActive && drivingCluster.evPowerState === "OFF") ? 1.0 : 0.0
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation { duration: 600; easing.type: Easing.InOutCubic }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 13. EV SLEEP / IGNITION OFF (Gradual Fade to Pure Black when not charging)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: sleepStandbyOverlay
        anchors.fill: parent
        color: "#000000"
        z: 99
        opacity: (drivingCluster.evPowerState === "OFF" && !drivingCluster.isGoodbyeActive && !drivingCluster.isCharging) ? 1.0 : 0.0
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation { duration: 900; easing.type: Easing.InOutCubic }
        }
    }
}
