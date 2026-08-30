import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/****************************************************************************
** Component: AdasRoadView.qml
** Role: 3-Lane Highway ADAS Engine with Lateral Sway & Zero-Speed Handling
** Features:
**   - Ego Car: Gentle lateral lane-tracking sway (±2.0px) when moving; strictly still at speed 0
**   - Lead Car: Gentle lateral sway (±3.5px); drives away into distance when speed is 0
**   - Highway: Dashed lines scroll when moving, stop immediately when speed is 0
**   - Strict Isolation: ADAS objects never bleed into the bottom bar
**   - ECU Controlled Lead Distance & Obstacle Types
****************************************************************************/

Item {
    id: adasView
    anchors.fill: parent
    clip: true

    // Driving & ADAS telemetry properties
    property real speed: 0.0
    property string themeColor: "#00e5ff"
    property bool adasActive: true
    property bool isAccessoryMode: false
    property bool isCharging: false
    property real chargingRateKw: 150.0
    property real batteryPercent: 72.0

    // Lead vehicle following distance & type (Controlled directly by ECU Emulator)
    property real leadDistanceMeters: 42.0
    property bool showLeadVehicle: true
    property string obstacleType: "car" // "car", "sedan", "hatchback", "motorcycle", "bicycle", "pedestrian"

    // Pass-by Simulation Mode: "both", "left", "right", "steady"
    property string passByMode: "both"
    property bool autoPassByEnabled: true
    property bool showRightVehicle: true

    // Navigation Turn-by-Turn Telemetry (Lower ADAS HUD below Ego car)
    property bool navActive: true
    property string navState: "GUIDING" // "GUIDING", "RECALCULATING", "ARRIVED", "GPS_LOST"
    property string navManeuver: "turn_right" // "turn_right", "turn_left", "slight_right", "slight_left", "sharp_right", "sharp_left", "u_turn", "straight", "roundabout"
    property string navDistance: "350 m"
    property string navStreet: "MG Road"
    property string navEta: "18:45"
    property string navDuration: "14 min"
    property string navRemainingKm: "8.4 km"
    property bool gpsLost: false

    // Vehicle Door, Bonnet & Trunk Open Status
    property bool doorFrontLeft:  false
    property bool doorFrontRight: false
    property bool doorRearLeft:   false
    property bool doorRearRight:  false
    property bool bonnetOpen:     false
    property bool trunkOpen:      false
    readonly property bool anyDoorOpen: doorFrontLeft || doorFrontRight || doorRearLeft || doorRearRight || bonnetOpen || trunkOpen

    // ─────────────────────────────────────────────────────────────
    // 1. EGO VEHICLE ROAD DYNAMICS (Gentle lateral sway when moving)
    // ─────────────────────────────────────────────────────────────
    property real egoLateralX: 0.0
    SequentialAnimation on egoLateralX {
        loops: Animation.Infinite
        running: adasView.speed > 0
        NumberAnimation { to: 2.0; duration: 2600; easing.type: Easing.InOutSine }
        NumberAnimation { to: -2.0; duration: 2400; easing.type: Easing.InOutSine }
    }

    // ─────────────────────────────────────────────────────────────
    // 2. LEAD OBSTACLE DYNAMICS & DISTANCE MAPPING
    // ─────────────────────────────────────────────────────────────
    property real leadLateralX: 0.0
    SequentialAnimation on leadLateralX {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to: 3.5; duration: 3200; easing.type: Easing.InOutSine }
        NumberAnimation { to: -3.5; duration: 2900; easing.type: Easing.InOutSine }
    }

    // Direct distance control from ECU emulator even when speed == 0
    readonly property real effectiveLeadDistance: adasView.leadDistanceMeters

    Behavior on leadDistanceMeters {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuad }
    }

    // ─────────────────────────────────────────────────────────────
    // 3. LEFT LANE PASS-BY SIMULATION (Traffic continues moving)
    // ─────────────────────────────────────────────────────────────
    property string leftObstacleType: "sedan"
    property string rightObstacleType: "motorcycle"
    readonly property var randomVehicleTypes: ["sedan", "hatchback", "car", "motorcycle", "bicycle"]

    function getRandomVehicle() {
        return randomVehicleTypes[Math.floor(Math.random() * randomVehicleTypes.length)];
    }

    property real leftPassByT: 0.20
    property bool leftCarVisible: true

    SequentialAnimation {
        id: leftPassByAnim
        loops: Animation.Infinite
        running: adasView.autoPassByEnabled && (adasView.passByMode === "left" || adasView.passByMode === "both")

        ScriptAction {
            script: {
                var v = adasView.getRandomVehicle();
                adasView.leftObstacleType = v;
                leftNumberAnim.duration = (v === "bicycle") ? 11000 : ((v === "motorcycle") ? 7800 : 8600);
            }
        }
        PropertyAction { target: adasView; property: "leftCarVisible"; value: true }
        NumberAnimation {
            id: leftNumberAnim
            target: adasView
            property: "leftPassByT"
            from: 0.06
            to: 0.88
            duration: 8600
            easing.type: Easing.InQuad
        }
        PropertyAction { target: adasView; property: "leftCarVisible"; value: false }
        PauseAnimation { duration: adasView.passByMode === "both" ? 5000 : 3500 }
    }

    // ─────────────────────────────────────────────────────────────
    // 4. RIGHT LANE PASS-BY & PACING
    // ─────────────────────────────────────────────────────────────
    property real rightPassByT: 0.20
    property bool rightCarVisible: true

    SequentialAnimation {
        id: rightPassByAnim
        loops: Animation.Infinite
        running: adasView.autoPassByEnabled && (adasView.passByMode === "right" || adasView.passByMode === "both")

        PauseAnimation { duration: adasView.passByMode === "both" ? 3000 : 0 }
        ScriptAction {
            script: {
                var v = adasView.getRandomVehicle();
                adasView.rightObstacleType = v;
                rightNumberAnim.duration = (v === "bicycle") ? 11500 : ((v === "motorcycle") ? 7600 : 9000);
            }
        }
        PropertyAction { target: adasView; property: "rightCarVisible"; value: true }
        NumberAnimation {
            id: rightNumberAnim
            target: adasView
            property: "rightPassByT"
            from: 0.06
            to: 0.88
            duration: 8800
            easing.type: Easing.InQuad
        }
        PropertyAction { target: adasView; property: "rightCarVisible"; value: false }
        PauseAnimation { duration: adasView.passByMode === "both" ? 4500 : 3200 }
    }

    property real steadyRightDistance: 38.0
    SequentialAnimation on steadyRightDistance {
        loops: Animation.Infinite
        running: adasView.passByMode === "steady"
        NumberAnimation { to: 46.0; duration: 5800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 32.0; duration: 5400; easing.type: Easing.InOutSine }
    }

    // Animated dashed lane scroll (STOPS strictly when speed == 0; reverses in R)
    property real laneOffset: 0.0
    NumberAnimation on laneOffset {
        from: (adasView.currentGear === "R") ? 1.0 : 0.0
        to: (adasView.currentGear === "R") ? 0.0 : 1.0
        duration: Math.max(350, Math.min(2200, 110000 / Math.max(1, adasView.speed)))
        loops: Animation.Infinite
        running: adasView.speed > 0
    }

    // ═══════════════════════════════════════════════════════════════
    // PERSPECTIVE GEOMETRY (Isolated strictly above the bottom bar)
    // ═══════════════════════════════════════════════════════════════
    readonly property real horizonY: height * 0.520
    readonly property real vanishingX: width * 0.50
    readonly property real roadBtmY: height * 0.86
    readonly property real totalRoadHalfWidth: width * 0.34
    readonly property real laneWidthBtm: (totalRoadHalfWidth * 2) / 3
    readonly property real topHalfWidth: 16
    readonly property real topLaneWidth: (topHalfWidth * 2) / 3

    // Bottom Lane Boundaries
    readonly property real l3_Btm: vanishingX - totalRoadHalfWidth
    readonly property real l2_Btm: vanishingX - totalRoadHalfWidth + laneWidthBtm
    readonly property real l1_Btm: vanishingX + totalRoadHalfWidth - laneWidthBtm
    readonly property real l0_Btm: vanishingX + totalRoadHalfWidth

    // Top Vanishing Lane Boundaries
    readonly property real l3_Top: vanishingX - topHalfWidth
    readonly property real l2_Top: vanishingX - topHalfWidth + topLaneWidth
    readonly property real l1_Top: vanishingX + topHalfWidth - topLaneWidth
    readonly property real l0_Top: vanishingX + topHalfWidth

    function getX(topVal, btmVal, t) {
        return topVal + (btmVal - topVal) * t;
    }

    function getDistanceStatusColor(dist) {
        if (dist < 30.0) return "#F59E0B"; // Amber proximity alert
        if (dist > 42.0) return "#10B981"; // Safe Green
        return "#00e5ff";                  // Normal Cyan
    }

    function getObstacleSource(type) {
        switch (type) {
            case "car":        return "../../assets/vehicles/obstruction_car_lead.png";
            case "sedan":      return "../../assets/vehicles/obstruction_sedan.png";
            case "hatchback":  return "../../assets/vehicles/obstruction_hatchback.png";
            case "motorcycle": return "../../assets/vehicles/obstruction_motorcycle.png";
            case "bicycle":    return "../../assets/vehicles/obstruction_bicycle.png";
            case "pedestrian": return "../../assets/vehicles/obstruction_pedestrian.png";
            default:           return "../../assets/vehicles/obstruction_car_lead.png";
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 1. MASTER 3-LANE PERSPECTIVE ROAD CANVAS
    // ═══════════════════════════════════════════════════════════════
    Canvas {
        id: roadCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            // ─────────────────────────────────────────────────────────
            // A. Road Surface Asphalt Fill (3 Lanes)
            // ─────────────────────────────────────────────────────────
            var roadGrad = ctx.createLinearGradient(vanishingX, horizonY, vanishingX, roadBtmY);
            roadGrad.addColorStop(0.0, "rgba(5, 8, 14, 0.45)");
            roadGrad.addColorStop(0.3, "rgba(8, 13, 20, 0.70)");
            roadGrad.addColorStop(0.7, "rgba(10, 16, 26, 0.85)");
            roadGrad.addColorStop(1.0, "rgba(4, 6, 10, 0.95)");

            ctx.fillStyle = roadGrad;
            ctx.beginPath();
            ctx.moveTo(l3_Top, horizonY);
            ctx.lineTo(l0_Top, horizonY);
            ctx.lineTo(l0_Btm, roadBtmY);
            ctx.lineTo(l3_Btm, roadBtmY);
            ctx.closePath();
            ctx.fill();

            // ─────────────────────────────────────────────────────────
            // B. Active Lane Guidance Carpet (Ego Center Lane)
            // ─────────────────────────────────────────────────────────
            if (adasView.adasActive) {
                var carpetGrad = ctx.createLinearGradient(vanishingX, horizonY, vanishingX, roadBtmY);
                carpetGrad.addColorStop(0.0, "transparent");
                carpetGrad.addColorStop(0.35, "rgba(0, 229, 255, 0.04)");
                carpetGrad.addColorStop(0.70, "rgba(0, 229, 255, 0.12)");
                carpetGrad.addColorStop(1.0, "rgba(0, 229, 255, 0.22)");

                ctx.fillStyle = carpetGrad;
                ctx.beginPath();
                ctx.moveTo(l2_Top, horizonY);
                ctx.lineTo(l1_Top, horizonY);
                ctx.lineTo(l1_Btm, roadBtmY);
                ctx.lineTo(l2_Btm, roadBtmY);
                ctx.closePath();
                ctx.fill();
            }

            // ─────────────────────────────────────────────────────────
            // C. Outer Road Edge Boundary Lines
            // ─────────────────────────────────────────────────────────
            var leftEdgeGrad = ctx.createLinearGradient(l3_Top, horizonY, l3_Btm, roadBtmY);
            leftEdgeGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.10)");
            leftEdgeGrad.addColorStop(0.5, "rgba(255, 255, 255, 0.70)");
            leftEdgeGrad.addColorStop(1.0, "rgba(255, 255, 255, 0.90)");
            ctx.strokeStyle = leftEdgeGrad;
            ctx.lineWidth = 2.5;
            ctx.beginPath();
            ctx.moveTo(l3_Top, horizonY);
            ctx.lineTo(l3_Btm, roadBtmY);
            ctx.stroke();

            var rightEdgeGrad = ctx.createLinearGradient(l0_Top, horizonY, l0_Btm, roadBtmY);
            rightEdgeGrad.addColorStop(0.0, "rgba(255, 255, 255, 0.10)");
            rightEdgeGrad.addColorStop(0.5, "rgba(255, 255, 255, 0.70)");
            rightEdgeGrad.addColorStop(1.0, "rgba(255, 255, 255, 0.90)");
            ctx.strokeStyle = rightEdgeGrad;
            ctx.lineWidth = 2.5;
            ctx.beginPath();
            ctx.moveTo(l0_Top, horizonY);
            ctx.lineTo(l0_Btm, roadBtmY);
            ctx.stroke();

            // ─────────────────────────────────────────────────────────
            // D. Center Dashed Lane Markings (L2 and L1)
            // ─────────────────────────────────────────────────────────
            var totalDashes = 8;
            for (var i = 0; i < totalDashes; i++) {
                var p = (i + adasView.laneOffset) / totalDashes;
                var t1 = Math.pow(p, 2.2);
                var t2 = Math.pow(Math.min(1.0, p + 0.06), 2.2);

                var y1 = horizonY + (roadBtmY - horizonY) * t1;
                var y2 = horizonY + (roadBtmY - horizonY) * t2;

                var dashWidth = 1.2 + t1 * 2.5;
                var alpha = (0.10 + t1 * 0.85).toFixed(3);

                var x1_L2 = getX(l2_Top, l2_Btm, t1);
                var x2_L2 = getX(l2_Top, l2_Btm, t2);

                ctx.strokeStyle = adasView.adasActive ? ("rgba(0, 229, 255, " + alpha + ")") : ("rgba(240, 245, 250, " + alpha + ")");
                ctx.lineWidth = dashWidth;
                ctx.beginPath();
                ctx.moveTo(x1_L2, y1);
                ctx.lineTo(x2_L2, y2);
                ctx.stroke();

                var x1_L1 = getX(l1_Top, l1_Btm, t1);
                var x2_L1 = getX(l1_Top, l1_Btm, t2);

                ctx.strokeStyle = adasView.adasActive ? ("rgba(0, 229, 255, " + alpha + ")") : ("rgba(240, 245, 250, " + alpha + ")");
                ctx.lineWidth = dashWidth;
                ctx.beginPath();
                ctx.moveTo(x1_L1, y1);
                ctx.lineTo(x2_L1, y2);
                ctx.stroke();
            }

            // ─────────────────────────────────────────────────────────
            // E. Sleek Short Glowing Red Proximity Follow Line On Road (When Traffic Passing)
            // ─────────────────────────────────────────────────────────
            if (adasView.leftNear) {
                var tCurveL = Math.pow(adasView.leftPassByT, 1.8);
                var pNearL1 = Math.max(0.06, tCurveL - 0.040);
                var pNearL2 = Math.min(0.96, tCurveL + 0.040);
                var ryL1 = horizonY + (roadBtmY - horizonY) * pNearL1;
                var ryL2 = horizonY + (roadBtmY - horizonY) * pNearL2;
                var rxL1 = adasView.getX(l2_Top, l2_Btm, pNearL1);
                var rxL2 = adasView.getX(l2_Top, l2_Btm, pNearL2);

                // Outer soft red glow
                ctx.strokeStyle = "rgba(239, 68, 68, 0.45)";
                ctx.lineWidth = 6.0;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(rxL1, ryL1);
                ctx.lineTo(rxL2, ryL2);
                ctx.stroke();

                // Inner sharp red line
                ctx.strokeStyle = "#EF4444";
                ctx.lineWidth = 3.0;
                ctx.beginPath();
                ctx.moveTo(rxL1, ryL1);
                ctx.lineTo(rxL2, ryL2);
                ctx.stroke();
            }

            if (adasView.rightNear) {
                var tCurveR = Math.pow(adasView.passByMode === "steady" ? 0.35 : adasView.rightPassByT, 1.8);
                var pNearR1 = Math.max(0.06, tCurveR - 0.040);
                var pNearR2 = Math.min(0.96, tCurveR + 0.040);
                var ryR1 = horizonY + (roadBtmY - horizonY) * pNearR1;
                var ryR2 = horizonY + (roadBtmY - horizonY) * pNearR2;
                var rxR1 = adasView.getX(l1_Top, l1_Btm, pNearR1);
                var rxR2 = adasView.getX(l1_Top, l1_Btm, pNearR2);

                // Outer soft red glow
                ctx.strokeStyle = "rgba(239, 68, 68, 0.45)";
                ctx.lineWidth = 6.0;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(rxR1, ryR1);
                ctx.lineTo(rxR2, ryR2);
                ctx.stroke();

                // Inner sharp red line
                ctx.strokeStyle = "#EF4444";
                ctx.lineWidth = 3.0;
                ctx.beginPath();
                ctx.moveTo(rxR1, ryR1);
                ctx.lineTo(rxR2, ryR2);
                ctx.stroke();
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 2. DYNAMIC OBSTACLE & TRAFFIC VEHICLES
    // ═══════════════════════════════════════════════════════════════

    // ─────────────────────────────────────────────────────────────
    // A. LEFT LANE VEHICLE (Proper Pass-By Overtaking Simulation)
    // ─────────────────────────────────────────────────────────────
    Item {
        id: leftCarItem
        visible: adasView.adasActive && adasView.leftCarVisible && (adasView.passByMode === "left" || adasView.passByMode === "both" || adasView.passByMode === "steady")
        property real tVal: (adasView.passByMode === "steady") ? 0.35 : adasView.leftPassByT
        property real tCurve: Math.pow(tVal, 1.8)
        property real laneCenterBtm: (adasView.l3_Btm + adasView.l2_Btm) * 0.5
        property real laneCenterTop: (adasView.l3_Top + adasView.l2_Top) * 0.5

        property bool isTwoWheeler: adasView.leftObstacleType === "motorcycle" || adasView.leftObstacleType === "bicycle"
        x: adasView.getX(laneCenterTop, laneCenterBtm, tCurve) - width * 0.5
        y: (adasView.horizonY + (adasView.roadBtmY - adasView.horizonY) * tCurve) - height * 0.5
        width:  isTwoWheeler ? (12 + 28 * tCurve) : (22 + 54 * tCurve)
        height: isTwoWheeler ? (22 + 56 * tCurve) : (22 + 54 * tCurve)

        opacity: (tVal > 0.65) ? Math.max(0.0, (0.85 - tVal) / 0.20) : 0.95

        Image {
            anchors.fill: parent
            source: adasView.getObstacleSource(adasView.leftObstacleType)
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    // ─────────────────────────────────────────────────────────────
    // B. RIGHT LANE VEHICLE (Pass-By Overtaking or Steady Pacing)
    // ─────────────────────────────────────────────────────────────
    Item {
        id: rightCarItem
        visible: adasView.adasActive && adasView.showRightVehicle && ((adasView.passByMode === "steady") || (adasView.rightCarVisible && (adasView.passByMode === "right" || adasView.passByMode === "both")))
        property real tVal: (adasView.passByMode === "steady") ? Math.max(0.12, Math.min(0.68, 1.0 - (adasView.steadyRightDistance / 90.0))) : adasView.rightPassByT
        property real tCurve: Math.pow(tVal, 1.8)
        property real laneCenterBtm: (adasView.l1_Btm + adasView.l0_Btm) * 0.5
        property real laneCenterTop: (adasView.l1_Top + adasView.l0_Top) * 0.5

        property bool isTwoWheeler: adasView.rightObstacleType === "motorcycle" || adasView.rightObstacleType === "bicycle"
        x: adasView.getX(laneCenterTop, laneCenterBtm, tCurve) - width * 0.5
        y: (adasView.horizonY + (adasView.roadBtmY - adasView.horizonY) * tCurve) - height * 0.5
        width:  isTwoWheeler ? (12 + 28 * tCurve) : (22 + 54 * tCurve)
        height: isTwoWheeler ? (22 + 56 * tCurve) : (22 + 54 * tCurve)

        opacity: (tVal > 0.65) ? Math.max(0.0, (0.85 - tVal) / 0.20) : 0.96

        Image {
            anchors.fill: parent
            source: adasView.getObstacleSource(adasView.rightObstacleType)
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    // ─────────────────────────────────────────────────────────────
    // C. CENTER LEAD OBSTACLE (Controlled by ECU Emulator & Lateral Sway)
    // ─────────────────────────────────────────────────────────────
    Item {
        id: leadCarItem
        visible: adasView.adasActive && adasView.showLeadVehicle

        // Detection range from 80m (horizon entry) down to 10m (safe bumper distance)
        property real dist: Math.max(10.0, Math.min(80.0, adasView.effectiveLeadDistance))
        property real t: 0.12 + 0.30 * ((80.0 - dist) / 70.0)
        property real tCurve: Math.pow(t, 2.0)

        property real laneCenterBtm: (adasView.l2_Btm + adasView.l1_Btm) * 0.5
        property real laneCenterTop: (adasView.l2_Top + adasView.l1_Top) * 0.5

        readonly property bool isPerson: (adasView.obstacleType === "pedestrian" || adasView.obstacleType === "bicycle")
        readonly property bool isMoto:   (adasView.obstacleType === "motorcycle")

        width:  isPerson ? (14 + 50 * t) : (isMoto ? (16 + 60 * t) : (22 + 80 * t))
        height: isPerson ? (24 + 80 * t) : (isMoto ? (22 + 70 * t) : (22 + 76 * t))

        property real navShift: (adasView.navActive && adasView.currentGear !== "R") ? (12.0 * tCurve) : 0.0

        x: (adasView.getX(laneCenterTop, laneCenterBtm, tCurve) + adasView.leadLateralX * tCurve) - width * 0.5
        y: ((adasView.horizonY + (adasView.roadBtmY - adasView.horizonY) * tCurve) - height * 0.5) - navShift

        Behavior on y {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Image {
            anchors.fill: parent
            source: adasView.getObstacleSource(adasView.obstacleType)
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.98
        }

        // Clean Distance Line in Front of Lead Obstacle (Scales down smoothly with perspective & navigation)
        Item {
            id: leadDistContainer
            visible: adasView.adasActive
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 2 + 3 * leadCarItem.t
            width: Math.max(parent.width * 0.95, 30 + 20 * leadCarItem.t)
            height: 16
            scale: (adasView.navActive && adasView.currentGear !== "R") ? Math.max(0.72, 0.78 + 0.35 * leadCarItem.t) : Math.max(0.85, 0.88 + 0.30 * leadCarItem.t)
            transformOrigin: Item.Bottom

            Behavior on scale {
                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
            }

            // Distance text cleanly displayed (Scaled down proportionally)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: distLine.top
                anchors.bottomMargin: 1.5
                text: adasView.effectiveLeadDistance.toFixed(1) + " m"
                font.pixelSize: (adasView.navActive && adasView.currentGear !== "R") ? 9 : 10
                font.weight: Font.Black
                font.letterSpacing: 0.3
                font.family: "Inter"
                color: adasView.getDistanceStatusColor(adasView.effectiveLeadDistance)
                renderType: Text.NativeRendering
            }

            // Glowing Line in Front of Car (Thinner & narrower when forward)
            Rectangle {
                id: distLine
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * ((adasView.navActive && adasView.currentGear !== "R") ? 0.85 : 1.0)
                height: (adasView.navActive && adasView.currentGear !== "R") ? 1.4 : 1.8
                radius: 1
                color: adasView.getDistanceStatusColor(adasView.effectiveLeadDistance)

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }

    readonly property bool leftNear:  adasView.adasActive && leftCarVisible  && (leftPassByT  >= 0.15 && leftPassByT  <= 0.88)
    readonly property bool rightNear: adasView.adasActive && (adasView.passByMode === "steady" ? (showRightVehicle && steadyRightDistance <= 55) : (rightCarVisible && rightPassByT >= 0.15 && rightPassByT <= 0.88))

    property string currentGear: "P"

    // ═══════════════════════════════════════════════════════════════
    // 3. EGO VEHICLE MODEL (Subtle lateral sway when moving; still when stopped)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: egoContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (adasView.speed > 0) ? adasView.egoLateralX : 0.0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: adasView.isAccessoryMode ? (parent.height * 0.24) :
                              ((parent.height * 0.17) + ((adasView.navActive && adasView.currentGear !== "R") ? 12 : 0))
        scale: adasView.isAccessoryMode ? 1.06 : 1.0
        width: 96
        height: 106

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
        }

        Image {
            id: egoVehicleModel
            anchors.fill: parent
            source: "../../assets/vehicles/apex_suv_adas_model.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.98
            smooth: true
        }

        // ═══════════════════════════════════════════════════════════
        // BLINKING TRANSPARENT RED OPEN OVERLAYS (Doors, Hood, Trunk)
        // ═══════════════════════════════════════════════════════════
        Item {
            id: doorBlinkLayer
            anchors.fill: parent
            z: 88

            // Continuous Warning Blink / Pulse Animation
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: adasView.anyDoorOpen
                NumberAnimation { to: 1.0; duration: 380; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.18; duration: 380; easing.type: Easing.InOutSine }
            }

            // 1. Front-Left Door (Red Overlay)
            Image {
                anchors.fill: parent
                source: "../../assets/vehicles/door_front_left.png"
                fillMode: Image.PreserveAspectFit
                visible: adasView.doorFrontLeft
                smooth: true
            }

            // 2. Front-Right Door (Red Overlay)
            Image {
                anchors.fill: parent
                source: "../../assets/vehicles/door_front_right.png"
                fillMode: Image.PreserveAspectFit
                visible: adasView.doorFrontRight
                smooth: true
            }

            // 3. Rear-Left Door (Red Overlay)
            Image {
                anchors.fill: parent
                source: "../../assets/vehicles/door_rear_left.png"
                fillMode: Image.PreserveAspectFit
                visible: adasView.doorRearLeft
                smooth: true
            }

            // 4. Rear-Right Door (Red Overlay)
            Image {
                anchors.fill: parent
                source: "../../assets/vehicles/door_rear_right.png"
                fillMode: Image.PreserveAspectFit
                visible: adasView.doorRearRight
                smooth: true
            }

            // 5. Bonnet / Hood (Red Overlay)
            Image {
                anchors.fill: parent
                source: "../../assets/vehicles/bonnet_open_red.png"
                fillMode: Image.PreserveAspectFit
                visible: adasView.bonnetOpen
                smooth: true
            }

            // 6. Trunk / Boot (Red Overlay)
            Image {
                anchors.fill: parent
                source: "../../assets/vehicles/trunk_open_red.png"
                fillMode: Image.PreserveAspectFit
                visible: adasView.trunkOpen
                smooth: true
            }
        }

        // ═══════════════════════════════════════════════════════════
        // EV CHARGING ENERGY AURA & CHARGE PORT GLOW
        // ═══════════════════════════════════════════════════════════
        // Rear-Left Charging Port Indicator (Attached directly to the car's charge flap)
        Item {
            id: chargePortGlow
            visible: adasView.isCharging
            x: 6
            y: parent.height * 0.52
            width: 22
            height: 22
            z: 90

            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 9
                color: Qt.rgba(0.06, 0.72, 0.51, 0.35)
                border.color: "#10B981"
                border.width: 1.0

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: adasView.isCharging
                    NumberAnimation { to: 1.35; duration: 650; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.95; duration: 650; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: adasView.isCharging
                    NumberAnimation { to: 1.0; duration: 650; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.InOutSine }
                }
            }

            Image {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: "../../assets/telltales/ev_charge_modern.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        // Pulsing Energy Waves Around Vehicle
        Item {
            id: chargingAuraRings
            anchors.centerIn: parent
            width: parent.width * 1.5
            height: parent.height * 1.5
            visible: adasView.isCharging
            opacity: adasView.isCharging ? 1.0 : 0.0
            z: -1

            Behavior on opacity { NumberAnimation { duration: 400 } }

            // Inner Ring
            Rectangle {
                anchors.centerIn: parent
                width: 130
                height: 130
                radius: 65
                color: "transparent"
                border.color: "#10B981"
                border.width: 2.0

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: adasView.isCharging
                    NumberAnimation { from: 0.8; to: 1.25; duration: 1600; easing.type: Easing.OutSine }
                }
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: adasView.isCharging
                    NumberAnimation { from: 0.85; to: 0.0; duration: 1600; easing.type: Easing.OutSine }
                }
            }

            // Outer Ring
            Rectangle {
                anchors.centerIn: parent
                width: 175
                height: 175
                radius: 88
                color: "transparent"
                border.color: "#00E5FF"
                border.width: 1.5

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: adasView.isCharging
                    NumberAnimation { from: 0.7; to: 1.35; duration: 2200; easing.type: Easing.OutSine }
                }
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: adasView.isCharging
                    NumberAnimation { from: 0.75; to: 0.0; duration: 2200; easing.type: Easing.OutSine }
                }
            }
        }

        // Reversing Radar Guidelines Overlay (Active only when in Reverse 'R')
        Item {
            id: reverseGuidelines
            visible: adasView.currentGear === "R"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: -8
            width: 140
            height: 60
            z: 80

            Canvas {
                id: reverseCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var w = width;
                    var h = height;

                    // Dynamic Reverse Distance Arcs
                    // Red Stop Zone (0.5m)
                    ctx.strokeStyle = "#EF4444";
                    ctx.lineWidth = 2.5;
                    ctx.beginPath();
                    ctx.moveTo(w * 0.28, h * 0.25);
                    ctx.lineTo(w * 0.72, h * 0.25);
                    ctx.stroke();

                    // Yellow Caution Zone (1.5m)
                    ctx.strokeStyle = "#F59E0B";
                    ctx.lineWidth = 2.0;
                    ctx.beginPath();
                    ctx.moveTo(w * 0.18, h * 0.55);
                    ctx.lineTo(w * 0.82, h * 0.55);
                    ctx.stroke();

                    // Dynamic Guideline Side Tracks
                    ctx.strokeStyle = "#38BDF8";
                    ctx.lineWidth = 2.0;
                    ctx.setLineDash([4, 4]);
                    // Left track
                    ctx.beginPath();
                    ctx.moveTo(w * 0.32, 0);
                    ctx.lineTo(w * 0.12, h * 0.90);
                    ctx.stroke();
                    // Right track
                    ctx.beginPath();
                    ctx.moveTo(w * 0.68, 0);
                    ctx.lineTo(w * 0.88, h * 0.90);
                    ctx.stroke();
                }
            }
        }
    }

    function getNavIcon(state, maneuver) {
        if (adasView.gpsLost || state === "GPS_LOST") return "../../assets/navigation/gps_lost.svg";
        if (state === "ARRIVED") return "../../assets/navigation/destination_reached.svg";
        if (state === "RECALCULATING") return "../../assets/navigation/recalculation.svg";
        if (maneuver === "turn_left") return "../../assets/navigation/turn_left.svg";
        if (maneuver === "slight_right" || maneuver === "slight_left" || maneuver === "fork") return "../../assets/navigation/turn_fork.svg";
        if (maneuver === "straight") return "../../assets/navigation/straight.svg";
        if (maneuver === "roundabout") return "../../assets/navigation/roundabout.svg";
        if (maneuver === "u_turn") return "../../assets/navigation/u_turn.svg";
        return "../../assets/navigation/turn_right.svg";
    }

    // ═══════════════════════════════════════════════════════════════
    // 4. COMPACT BORDERLESS NAVIGATION HUD (Positioned directly below Ego Car)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: navHudContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: egoContainer.bottom
        anchors.topMargin: -2
        width: 340
        height: 42
        visible: adasView.navActive && adasView.currentGear !== "R" && !adasView.isAccessoryMode && !adasView.isCharging
        opacity: (adasView.navActive && adasView.currentGear !== "R" && !adasView.isAccessoryMode && !adasView.isCharging) ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 300 } }

        Row {
            anchors.centerIn: parent
            spacing: 12

            // High-Resolution Navigation & Status Icon (Fixed & Upright)
            Item {
                width: 26
                height: 26
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: navIconImg
                    anchors.fill: parent
                    source: adasView.getNavIcon(adasView.navState, adasView.navManeuver)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            // Navigation Text Details (Distance, Next Road / Status, ETA)
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2.0

                // Top Line: [Distance] [Street] or Status
                Row {
                    spacing: 6
                    anchors.left: parent.left

                    Text {
                        text: (adasView.gpsLost || adasView.navState === "GPS_LOST") ? "GPS Signal Lost" :
                              (adasView.navState === "RECALCULATING") ? "Recalculating..." :
                              (adasView.navState === "ARRIVED") ? "Destination Reached" :
                              adasView.navDistance
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.letterSpacing: 0.4
                        font.family: "Inter"
                        color: (adasView.gpsLost || adasView.navState === "GPS_LOST") ? "#EF4444" :
                               (adasView.navState === "RECALCULATING") ? "#38BDF8" :
                               (adasView.navState === "ARRIVED") ? "#10B981" :
                               "#FFFFFF"
                        renderType: Text.NativeRendering
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: (adasView.navState !== "RECALCULATING" && adasView.navState !== "ARRIVED" && !adasView.gpsLost && adasView.navState !== "GPS_LOST")
                        text: adasView.navStreet
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.3
                        font.family: "Inter"
                        color: "#CBD5E1"
                        renderType: Text.NativeRendering
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Sub Line: ETA / Finding fastest alternative... / Trip complete
                Text {
                    anchors.left: parent.left
                    text: (adasView.gpsLost || adasView.navState === "GPS_LOST") ? "Searching for signal..." :
                          (adasView.navState === "RECALCULATING") ? "Finding fastest alternative..." :
                          (adasView.navState === "ARRIVED") ? "Trip Complete" :
                          "ETA " + adasView.navEta + "  ·  " + adasView.navDuration + "  ·  " + adasView.navRemainingKm
                    font.pixelSize: 10
                    font.weight: Font.Normal
                    font.letterSpacing: 0.3
                    font.family: "Inter"
                    color: (adasView.gpsLost || adasView.navState === "GPS_LOST") ? "#F87171" :
                           (adasView.navState === "RECALCULATING") ? "#7DD3FC" :
                           (adasView.navState === "ARRIVED") ? "#6EE7B7" :
                           "#94A3B8"
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    // Subtle Glowing Horizon Divider at the end of ADAS Road View
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.12
        width: parent.width * 0.44
        height: 1.5
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0.898, 1.0, 0.45) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 5. HIGH-TECH EV CHARGING HUD (Active during Charging)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: chargingHudBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: egoContainer.top
        anchors.bottomMargin: 14
        width: 320
        height: 64
        z: 95
        visible: opacity > 0.0
        opacity: adasView.isCharging ? 1.0 : 0.0
        scale: adasView.isCharging ? 1.0 : 0.90

        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 6

            // Header: Modern SVG icon + Charging Status & kW
            Item {
                width: parent.width
                height: 18

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    // Modern EV Charging SVG Icon
                    Image {
                        source: "../../assets/telltales/ev_charge_modern.svg"
                        width: 17
                        height: 17
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: adasView.isCharging && adasView.batteryPercent < 100
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: (adasView.batteryPercent >= 100) ? "CHARGING COMPLETE" :
                              (adasView.chargingRateKw >= 150 ? "DC ULTRA-FAST CHARGE" : (adasView.chargingRateKw >= 50 ? "DC FAST CHARGE" : "AC CHARGING"))
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                        font.family: "Inter"
                        color: (adasView.batteryPercent >= 100) ? "#10B981" : "#F8FAFC"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (adasView.batteryPercent >= 100) ? "100% READY" : (Math.round(adasView.chargingRateKw) + " kW")
                    font.pixelSize: 12
                    font.weight: Font.Black
                    font.family: "Inter"
                    color: "#10B981"
                }
            }

            // Progress Bar (Filling Gradient with Cyan/Green Glow)
            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: "#1E293B"

                Rectangle {
                    width: parent.width * Math.min(1.0, Math.max(0.02, adasView.batteryPercent / 100.0))
                    height: parent.height
                    radius: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00E5FF" }
                        GradientStop { position: 1.0; color: "#10B981" }
                    }

                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }

            // Subtitle: % SoC · +km Range · Time remaining / Complete
            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(adasView.batteryPercent) + "% SoC"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.family: "Inter"
                    color: "#38BDF8"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: (adasView.batteryPercent >= 100) ? "" : ("+" + Math.round(adasView.batteryPercent * 5.95) + " km Range")
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    font.family: "Inter"
                    color: "#CBD5E1"
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (adasView.batteryPercent >= 100) ? "Complete" : (Math.max(1, Math.round((100 - adasView.batteryPercent) / (Math.max(1, adasView.chargingRateKw) / 150.0 * 2.2))) + " min to full")
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.family: "Inter"
                    color: "#10B981"
                }
            }
        }
    }

    onLaneOffsetChanged: roadCanvas.requestPaint()
    onSpeedChanged:      roadCanvas.requestPaint()
    onLeftNearChanged:   roadCanvas.requestPaint()
    onRightNearChanged:  roadCanvas.requestPaint()
    onIsAccessoryModeChanged: roadCanvas.requestPaint()
    onLeftPassByTChanged: { if (leftNear) roadCanvas.requestPaint(); }
    onRightPassByTChanged: { if (rightNear) roadCanvas.requestPaint(); }
    onCurrentGearChanged: { if (reverseCanvas.visible) reverseCanvas.requestPaint(); }
    Component.onCompleted: roadCanvas.requestPaint()
}
