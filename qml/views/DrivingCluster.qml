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

    // ADAS Properties
    property bool adasActive:          true
    property real adasLeadDistance:    42.0
    property bool adasLeadVehicle:     true
    property string adasObstacleType:  "car"
    property string adasPassByMode:    "both"
    property bool adasPassByEnabled:   true
    property bool adasLeftTraffic:     true
    property bool adasRightTraffic:    true

    // Driving values: Start at 0 km/h with Gear P on launch
    property real speedValue:      0
    property real powerKw:         0.0
    property real batteryPercent:  72
    property real rangeKm:         428
    property real batteryTemp:     32.0
    property int speedLimit:       80
    property string currentGear:   "P"
    property int ambientTemp:      24
    property real tripKm:          256.8
    property real consumption:     18.2

    property bool emulatorOpen:    true

    // ═══════════════════════════════════════════════════════════════
    // TELLTALE ON/OFF TOGGLE SYSTEM (All OFF after bootup bulb-check)
    // ═══════════════════════════════════════════════════════════════
    property bool telltaleTurnLeft:      false
    property bool telltaleSeatbelt:      false
    property bool telltaleAirbag:        false
    property bool telltaleTraction:      false
    property bool telltaleParkBrake:     false
    property bool telltaleAbs:           false
    property bool telltaleCheckEngine:   false
    property bool telltaleBattery12v:    false
    property bool telltaleTpms:          false
    property bool telltaleEvPlug:        false

    property bool telltaleAutoHighBeam:  false
    property bool telltaleLowBeam:       false
    property bool telltaleHighBeam:      false
    property bool telltaleFogLamp:       false
    property bool telltaleBatteryTemp:   false
    property bool telltaleMasterWarning: false
    property bool telltaleDoorOpen:      false
    property bool telltaleTurnRight:     false

    property bool bulbCheckActive:    false
    property real startupPowerSweep:  0.0
    property real startupTempSweep:   32.0
    property real startupSpeedSweep:  0.0
    property bool isSelfTestRunning:  false

    onCurrentGearChanged: {
        if (currentGear === "P") {
            speedValue = 0;
            powerKw = 0;
            telltaleParkBrake = true;
        } else {
            telltaleParkBrake = false;
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
    // ACTIVE WARNING CARD NOTIFICATION SYSTEM
    // ═══════════════════════════════════════════════════════════════
    property string activeWarningCardSource: ""

    function showWarningCard(cardFileName, chimeType) {
        if (!cardFileName || cardFileName === "") {
            activeWarningCardSource = "";
            warningCardAnim.stop();
            warningCardBanner.opacity = (isForwardCollisionActive || isHighSpeedActive) ? 1.0 : 0.0;
            return;
        }
        activeWarningCardSource = "../../assets/warnings/" + cardFileName;
        if (typeof clusterAudio !== "undefined") {
            if (chimeType === "critical") {
                clusterAudio.playCriticalAlertChime();
            } else if (chimeType === "warning") {
                clusterAudio.playWarningAlertChime();
            } else {
                clusterAudio.playInfoAlertChime();
            }
        }

        // For persistent warnings (>120km/h or Forward Collision <13m), STAY permanently on screen!
        if (isHighSpeedActive || isForwardCollisionActive || cardFileName === "warning_speed_120.png" || cardFileName === "warning_forward_collision.png") {
            warningCardAnim.stop();
            warningCardBanner.opacity = 1.0;
            warningCardBanner.scale = 1.0;
        } else {
            warningCardAnim.restart();
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
        if (isForwardCollisionActive) {
            showWarningCard("warning_forward_collision.png", "critical");
        } else {
            if (activeWarningCardSource.indexOf("warning_forward_collision.png") !== -1) {
                showWarningCard("", "");
            }
        }
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
        if (isSelfTestRunning) return;

        // 80 km/h speed threshold crossing (Single chime + popup)
        if (speedValue > 80 && prevSpeedValue <= 80 && speedValue <= 120) {
            showWarningCard("warning_speed_80.png", "warning");
        }

        prevSpeedValue = speedValue;
    }

    onIsHighSpeedActiveChanged: {
        if (isHighSpeedActive) {
            showWarningCard("warning_speed_120.png", "critical");
        } else {
            if (activeWarningCardSource.indexOf("warning_speed_120.png") !== -1) {
                showWarningCard("", "");
            }
        }
    }

    onBatteryPercentChanged: {
        if (batteryPercent <= 12 && !isSelfTestRunning) {
            telltaleEvPlug = true;
            showWarningCard("warning_low_battery.png", "warning");
        }
    }

    onBatteryTempChanged: {
        if (batteryTemp >= 65 && !isSelfTestRunning) {
            telltaleBatteryTemp = true;
            showWarningCard("warning_battery_overheat.png", "critical");
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

        // Phase 4: AFTER bootup self-test completes, Scenery Background & ADAS Road smoothly fade in and come online
        ParallelAnimation {
            NumberAnimation { target: drivingCluster; property: "bgMasterOpacity"; from: 0.0; to: 0.85; duration: 1500; easing.type: Easing.InOutCubic }
            NumberAnimation { target: roadView;       property: "opacity";         from: 0.0; to: 1.0;  duration: 1500; easing.type: Easing.InOutCubic }
            NumberAnimation { target: roadView;       property: "scale";           from: 0.94; to: 1.0; duration: 1500; easing.type: Easing.OutBack }
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
        autoHighBeam:  drivingCluster.telltaleAutoHighBeam
        lowBeam:       drivingCluster.telltaleLowBeam
        highBeam:      drivingCluster.telltaleHighBeam
        fogLamp:       drivingCluster.telltaleFogLamp
        batteryTemp:   drivingCluster.telltaleBatteryTemp
        masterWarning: drivingCluster.telltaleMasterWarning
        doorOpen:      drivingCluster.telltaleDoorOpen
        turnRight:     drivingCluster.telltaleTurnRight
        opacity: 0
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
        temperature: drivingCluster.ambientTemp
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
        opacity: 0
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
        opacity: 0
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
        opacity: 0
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
        tripKm:         drivingCluster.tripKm
        consumption:    drivingCluster.consumption
        themeColor:     drivingCluster.themeColor
        opacity: 0
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
        opacity: 0
    }

    // ═══════════════════════════════════════════════════════════════
    // 9. FLOATING ECU EMULATOR TRIGGER BUTTON (Bottom-Right)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: emulatorTriggerBadge
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        width: 146
        height: 28
        radius: 14
        color: emulatorTriggerMouse.containsMouse ? "#0284C7" : "#1E293B"
        border.color: "#38BDF8"
        border.width: 1
        z: 90
        opacity: 0.88

        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: "⚙️"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "ECU EMULATOR"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.0
                font.family: "sans-serif"
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: emulatorTriggerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: drivingCluster.emulatorOpen = !drivingCluster.emulatorOpen
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
            mipmap: true
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
            mipmap: true
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
}
