import QtQuick
import QtQuick.Controls

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

    // Lead vehicle following distance & type (Controlled directly by ECU Emulator)
    property real leadDistanceMeters: 42.0
    property bool showLeadVehicle: true
    property string obstacleType: "car" // "car", "sedan", "hatchback", "motorcycle", "bicycle", "pedestrian"

    // Pass-by Simulation Mode: "both", "left", "right", "steady"
    property string passByMode: "both"
    property bool autoPassByEnabled: true
    property bool showRightVehicle: true

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
    property real leftPassByT: 0.20
    property bool leftCarVisible: true

    SequentialAnimation {
        id: leftPassByAnim
        loops: Animation.Infinite
        running: adasView.autoPassByEnabled && (adasView.passByMode === "left" || adasView.passByMode === "both")

        PropertyAction { target: adasView; property: "leftCarVisible"; value: true }
        NumberAnimation {
            target: adasView
            property: "leftPassByT"
            from: 0.06
            to: 0.88
            duration: 8600
            easing.type: Easing.InQuad
        }
        PropertyAction { target: adasView; property: "leftCarVisible"; value: false }
        PauseAnimation { duration: adasView.passByMode === "both" ? 6000 : 4000 }
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

        PauseAnimation { duration: adasView.passByMode === "both" ? 3500 : 0 }
        PropertyAction { target: adasView; property: "rightCarVisible"; value: true }
        NumberAnimation {
            target: adasView
            property: "rightPassByT"
            from: 0.06
            to: 0.88
            duration: 9200
            easing.type: Easing.InQuad
        }
        PropertyAction { target: adasView; property: "rightCarVisible"; value: false }
        PauseAnimation { duration: adasView.passByMode === "both" ? 4500 : 3500 }
    }

    property real steadyRightDistance: 38.0
    SequentialAnimation on steadyRightDistance {
        loops: Animation.Infinite
        running: adasView.passByMode === "steady"
        NumberAnimation { to: 46.0; duration: 5800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 32.0; duration: 5400; easing.type: Easing.InOutSine }
    }

    // Animated dashed lane scroll (STOPS strictly when speed == 0)
    property real laneOffset: 0.0
    NumberAnimation on laneOffset {
        from: 0.0
        to: 1.0
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
            // E. Short Glowing Red Proximity Lines On Road (When Traffic Near)
            // ─────────────────────────────────────────────────────────
            if (adasView.leftNear) {
                var pNearL1 = Math.pow(Math.max(0.08, adasView.leftPassByT * 0.85), 1.8);
                var pNearL2 = Math.pow(Math.min(0.96, adasView.leftPassByT * 1.15), 1.8);
                var ryL1 = horizonY + (roadBtmY - horizonY) * pNearL1;
                var ryL2 = horizonY + (roadBtmY - horizonY) * pNearL2;
                var rxL1 = adasView.getX(l2_Top, l2_Btm, pNearL1);
                var rxL2 = adasView.getX(l2_Top, l2_Btm, pNearL2);

                ctx.strokeStyle = "#EF4444";
                ctx.lineWidth = 3.5;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(rxL1, ryL1);
                ctx.lineTo(rxL2, ryL2);
                ctx.stroke();
            }

            if (adasView.rightNear) {
                var pNearR1 = Math.pow(Math.max(0.08, adasView.rightPassByT * 0.85), 1.8);
                var pNearR2 = Math.pow(Math.min(0.96, adasView.rightPassByT * 1.15), 1.8);
                var ryR1 = horizonY + (roadBtmY - horizonY) * pNearR1;
                var ryR2 = horizonY + (roadBtmY - horizonY) * pNearR2;
                var rxR1 = adasView.getX(l1_Top, l1_Btm, pNearR1);
                var rxR2 = adasView.getX(l1_Top, l1_Btm, pNearR2);

                ctx.strokeStyle = "#EF4444";
                ctx.lineWidth = 3.5;
                ctx.lineCap = "round";
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

        x: adasView.getX(laneCenterTop, laneCenterBtm, tCurve) - width * 0.5
        y: (adasView.horizonY + (adasView.roadBtmY - adasView.horizonY) * tCurve) - height * 0.5
        width:  20 + 52 * tCurve
        height: 20 + 52 * tCurve

        opacity: (tVal > 0.65) ? Math.max(0.0, (0.85 - tVal) / 0.20) : 0.95

        Image {
            anchors.fill: parent
            source: "../../assets/vehicles/obstruction_sedan.png"
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

        x: adasView.getX(laneCenterTop, laneCenterBtm, tCurve) - width * 0.5
        y: (adasView.horizonY + (adasView.roadBtmY - adasView.horizonY) * tCurve) - height * 0.5
        width:  16 + 40 * tCurve
        height: 18 + 46 * tCurve

        opacity: (tVal > 0.65) ? Math.max(0.0, (0.85 - tVal) / 0.20) : 0.96

        Image {
            anchors.fill: parent
            source: "../../assets/vehicles/obstruction_motorcycle.png"
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

        x: (adasView.getX(laneCenterTop, laneCenterBtm, tCurve) + adasView.leadLateralX * tCurve) - width * 0.5
        y: (adasView.horizonY + (adasView.roadBtmY - adasView.horizonY) * tCurve) - height * 0.5

        Image {
            anchors.fill: parent
            source: adasView.getObstacleSource(adasView.obstacleType)
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.98
        }

        // Clean Distance Line in Front of Lead Obstacle (No box/board)
        Item {
            visible: adasView.adasActive
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 4
            width: Math.max(parent.width * 1.1, 48)
            height: 18

            // Distance text cleanly displayed
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: distLine.top
                anchors.bottomMargin: 2
                text: adasView.effectiveLeadDistance.toFixed(1) + " m"
                font.pixelSize: 11
                font.weight: Font.Black
                font.letterSpacing: 0.5
                font.family: "sans-serif"
                color: adasView.getDistanceStatusColor(adasView.effectiveLeadDistance)
                renderType: Text.NativeRendering
            }

            // Glowing Line in Front of Car
            Rectangle {
                id: distLine
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 2.0
                radius: 1
                color: adasView.getDistanceStatusColor(adasView.effectiveLeadDistance)
            }
        }
    }

    readonly property bool leftNear:  adasView.adasActive && leftCarVisible  && (leftPassByT  >= 0.40 && leftPassByT  <= 0.88)
    readonly property bool rightNear: adasView.adasActive && rightCarVisible && (rightPassByT >= 0.40 && rightPassByT <= 0.88)

    property string currentGear: "P"

    // ═══════════════════════════════════════════════════════════════
    // 3. EGO VEHICLE MODEL (Subtle lateral sway when moving; still when stopped)
    // ═══════════════════════════════════════════════════════════════
    Item {
        id: egoContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (adasView.speed > 0) ? adasView.egoLateralX : 0.0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.17
        width: 96
        height: 106

        Image {
            id: egoVehicleModel
            anchors.fill: parent
            source: "../../assets/vehicles/apex_suv_adas_model.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.98
            smooth: true
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

    onLaneOffsetChanged: roadCanvas.requestPaint()
    onSpeedChanged:      roadCanvas.requestPaint()
    onLeftNearChanged:   roadCanvas.requestPaint()
    onRightNearChanged:  roadCanvas.requestPaint()
    onLeftPassByTChanged: { if (leftNear) roadCanvas.requestPaint(); }
    onRightPassByTChanged: { if (rightNear) roadCanvas.requestPaint(); }
    onCurrentGearChanged: { if (reverseCanvas.visible) reverseCanvas.requestPaint(); }
    Component.onCompleted: roadCanvas.requestPaint()
}
