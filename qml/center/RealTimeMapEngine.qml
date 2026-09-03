import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: mapEngineRoot
    width: 600
    height: 560
    clip: true

    // Target reference to the DrivingCluster for direct HUD sync
    property var clusterTarget: null
    readonly property bool isEvReady: (!clusterTarget) || (clusterTarget.isEvReady === true)

    onClusterTargetChanged: {
        if (typeof navigationController !== "undefined" && clusterTarget) {
            navigationController.isEvReady = clusterTarget.isEvReady;
        }
    }

    // Pin Placement Mode: "NONE", "SET_START", "SET_DEST"
    property string pinPlacementMode: "NONE"

    // Sync vehicle speed to cluster speedometer during auto-drive
    property bool syncSpeedToCluster: true

    // Quantized base tile coordinates to prevent request flooding
    property int currentBaseTileX: 0
    property int currentBaseTileY: 0
    property int currentTileZoom: 14

    function updateTileIndices() {
        if (typeof navigationController === "undefined") return;
        var zoom = navigationController.zoomLevel;
        var cLon = navigationController.centerLon;
        var cLat = navigationController.centerLat;

        var centerTX = Math.floor(lonToTileX(cLon, zoom));
        var centerTY = Math.floor(latToTileY(cLat, zoom));

        if (centerTX !== currentBaseTileX || centerTY !== currentBaseTileY || zoom !== currentTileZoom) {
            currentBaseTileX = centerTX;
            currentBaseTileY = centerTY;
            currentTileZoom = zoom;
        }
    }

    // ─── Mathematical Mercator Helpers for Slippy Tile Positioning ───
    function lonToTileX(lon, zoom) {
        return (lon + 180.0) / 360.0 * Math.pow(2.0, zoom);
    }

    function latToTileY(lat, zoom) {
        var latRad = lat * Math.PI / 180.0;
        return (1.0 - Math.log(Math.tan(latRad) + 1.0 / Math.cos(latRad)) / Math.PI) / 2.0 * Math.pow(2.0, zoom);
    }

    function tileXToLon(x, zoom) {
        return x / Math.pow(2.0, zoom) * 360.0 - 180.0;
    }

    function tileYToLat(y, zoom) {
        var n = Math.PI - 2.0 * Math.PI * y / Math.pow(2.0, zoom);
        return 180.0 / Math.PI * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
    }

    // Convert Geo Coordinate to Screen X/Y inside map viewport
    function geoToScreen(lat, lon) {
        var cLat = typeof navigationController !== "undefined" ? navigationController.centerLat : 12.9756;
        var cLon = typeof navigationController !== "undefined" ? navigationController.centerLon : 77.6094;
        var zoom = typeof navigationController !== "undefined" ? navigationController.zoomLevel : 14;

        var centerTileX = lonToTileX(cLon, zoom);
        var centerTileY = latToTileY(cLat, zoom);

        var pointTileX = lonToTileX(lon, zoom);
        var pointTileY = latToTileY(lat, zoom);

        var tileSize = 256;
        var screenX = mapViewport.width / 2.0 + (pointTileX - centerTileX) * tileSize;
        var screenY = mapViewport.height / 2.0 + (pointTileY - centerTileY) * tileSize;

        return { x: screenX, y: screenY };
    }

    // Convert Screen X/Y to Geo Coordinate
    function screenToGeo(screenX, screenY) {
        var cLat = typeof navigationController !== "undefined" ? navigationController.centerLat : 12.9756;
        var cLon = typeof navigationController !== "undefined" ? navigationController.centerLon : 77.6094;
        var zoom = typeof navigationController !== "undefined" ? navigationController.zoomLevel : 14;

        var centerTileX = lonToTileX(cLon, zoom);
        var centerTileY = latToTileY(cLat, zoom);

        var tileSize = 256;
        var tileX = centerTileX + (screenX - mapViewport.width / 2.0) / tileSize;
        var tileY = centerTileY + (screenY - mapViewport.height / 2.0) / tileSize;

        return {
            lat: tileYToLat(tileY, zoom),
            lon: tileXToLon(tileX, zoom)
        };
    }

    // ─── Real-Time Telemetry Bridge from C++ NavigationController to Cluster HUD ───
    Connections {
        target: typeof navigationController !== "undefined" ? navigationController : null

        function onNavDistanceChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.navDistance = navigationController.navDistance;
            }
        }

        function onNavManeuverChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.navManeuver = navigationController.navManeuver;
            }
        }

        function onNavStreetChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.navStreet = navigationController.navStreet;
            }
        }

        function onNavStateChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.navState = navigationController.navState;
            }
        }

        function onCompassHeadingChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.compassHeading = navigationController.compassHeading;
            }
        }

        function onGpsLostChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.gpsLost = navigationController.gpsLost;
            }
        }

        function onNavRemainingKmChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.navRemainingKm = navigationController.navRemainingKm;
            }
        }

        function onNavEtaChanged() {
            if (clusterTarget && typeof navigationController !== "undefined") {
                clusterTarget.navEta = navigationController.navEta;
                clusterTarget.navDuration = navigationController.navDuration;
            }
        }

        function onCurrentSimSpeedChanged() {
            if (clusterTarget && mapEngineRoot.syncSpeedToCluster && typeof navigationController !== "undefined") {
                if (navigationController.isAutoDriving && clusterTarget.currentGear === "P") {
                    clusterTarget.currentGear = "D";
                }
                clusterTarget.speedValue = Math.round(navigationController.currentSimSpeed);
                clusterTarget.powerKw = Math.round(navigationController.currentSimSpeed * 1.7 + 5);
            }
        }

        function onDestinationReached() {
            if (typeof clusterAudio !== "undefined" && clusterTarget && clusterTarget.opacity > 0.5) {
                clusterAudio.playWarningAlertChime();
            }
        }

        function onRoutePolylineChanged() {
            routeCanvas.requestPaint();
            mapEngineRoot.updateTileIndices();
        }

        function onCenterChanged() {
            routeCanvas.requestPaint();
            mapEngineRoot.updateTileIndices();
        }

        function onZoomLevelChanged() {
            routeCanvas.requestPaint();
            mapEngineRoot.updateTileIndices();
        }

        function onVehiclePositionChanged() {
            routeCanvas.requestPaint();
        }
    }

    Connections {
        target: clusterTarget
        function onEvPowerStateChanged() {
            if (typeof navigationController !== "undefined" && clusterTarget) {
                navigationController.isEvReady = clusterTarget.isEvReady;
                if (!clusterTarget.isEvReady && navigationController.isAutoDriving) {
                    navigationController.isAutoDriving = false;
                }
            }
        }
    }

    Component.onCompleted: {
        updateTileIndices();
        if (typeof navigationController !== "undefined" && clusterTarget) {
            navigationController.isEvReady = clusterTarget.isEvReady;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // UI LAYOUT
    // ═══════════════════════════════════════════════════════════════════════
    Column {
        anchors.fill: parent
        spacing: 8

        // 1. TOP HEADER & PRESET CITY STRIP
        Rectangle {
            width: parent.width
            height: 38
            color: "#0B132B"
            radius: 8
            border.color: "#1E293B"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: "🌐 Real-Time City Road Routes:"
                    color: "#94A3B8"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Repeater {
                    model: [
                        { id: "bangalore",     name: "Bengaluru" },
                        { id: "san_francisco", name: "SF Golden Gate" },
                        { id: "tokyo",         name: "Tokyo" },
                        { id: "london",        name: "London" },
                        { id: "nurburgring",   name: "Nürburgring" }
                    ]

                    Rectangle {
                        height: 24
                        width: presetText.implicitWidth + 14
                        radius: 4
                        color: (typeof navigationController !== "undefined" && navigationController.routeStatusMessage.indexOf(modelData.name) !== -1) ? "#0284C7" : "#1E293B"
                        border.color: (typeof navigationController !== "undefined" && navigationController.routeStatusMessage.indexOf(modelData.name) !== -1) ? "#38BDF8" : "#334155"

                        Text {
                            id: presetText
                            anchors.centerIn: parent
                            text: modelData.name
                            color: "#FFFFFF"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof navigationController !== "undefined") {
                                    navigationController.loadPreset(modelData.id);
                                }
                            }
                        }
                    }
                }
            }

            // Route Calculate / OSRM Refresh Button
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: 96
                radius: 4
                color: (typeof navigationController !== "undefined" && navigationController.isCalculatingRoute) ? "#64748B" : "#0D9488"
                border.color: "#2DD4BF"

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "🔄"; font.pixelSize: 10 }
                    Text { text: "OSRM Live"; color: "#FFFFFF"; font.pixelSize: 10; font.weight: Font.Bold }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof navigationController !== "undefined") {
                            navigationController.calculateRoute();
                        }
                    }
                }
            }
        }

        // 2. INTERACTIVE MAP VIEWPORT
        Rectangle {
            id: mapViewport
            width: parent.width
            height: 300
            radius: 8
            color: "#030712"
            clip: true
            border.color: (mapEngineRoot.pinPlacementMode !== "NONE") ? "#00E5FF" : "#1E293B"
            border.width: (mapEngineRoot.pinPlacementMode !== "NONE") ? 2 : 1

            // Dark Cartographic Background Grid & Radar Range Rings
            Canvas {
                id: mapGridCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "rgba(30, 41, 59, 0.4)";
                    ctx.lineWidth = 1;
                    for (var x = 0; x < width; x += 32) {
                        ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
                    }
                    for (var y = 0; y < height; y += 32) {
                        ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                    }

                    // Compass Crosshairs in Center
                    ctx.strokeStyle = "rgba(56, 189, 248, 0.25)";
                    ctx.beginPath();
                    ctx.moveTo(width / 2, 0); ctx.lineTo(width / 2, height);
                    ctx.moveTo(0, height / 2); ctx.lineTo(width, height / 2);
                    ctx.stroke();
                }
            }

            // Slippy Map Tiles (Debounced & Quantized Grid)
            Item {
                id: tileContainer
                anchors.fill: parent

                Repeater {
                    model: 12
                    delegate: Image {
                        property int colIndex: (index % 4) - 1
                        property int rowIndex: Math.floor(index / 4) - 1

                        property int targetTileX: mapEngineRoot.currentBaseTileX + colIndex
                        property int targetTileY: mapEngineRoot.currentBaseTileY + rowIndex
                        property int zoom: mapEngineRoot.currentTileZoom

                        property real cLon: typeof navigationController !== "undefined" ? navigationController.centerLon : 77.6094
                        property real cLat: typeof navigationController !== "undefined" ? navigationController.centerLat : 12.9756
                        property real exactCenterTX: mapEngineRoot.lonToTileX(cLon, zoom)
                        property real exactCenterTY: mapEngineRoot.latToTileY(cLat, zoom)

                        x: mapViewport.width / 2.0 + (targetTileX - exactCenterTX) * 256
                        y: mapViewport.height / 2.0 + (targetTileY - exactCenterTY) * 256
                        width: 256
                        height: 256

                        source: (targetTileX >= 0 && targetTileY >= 0) ?
                                "https://a.basemaps.cartocdn.com/rastertiles/dark_all/" + zoom + "/" + targetTileX + "/" + targetTileY + ".png" : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        opacity: status === Image.Ready ? 0.85 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }

            // Route Polyline Canvas Layer (C++ Real Road Geometry)
            Canvas {
                id: routeCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    if (typeof navigationController === "undefined" || !navigationController.routePolyline || navigationController.routePolyline.length === 0) return;

                    var pts = navigationController.routePolyline;
                    var p0 = mapEngineRoot.geoToScreen(pts[0].lat, pts[0].lon);

                    // 1. Glowing Outer Route Line (Cyan Bloom)
                    ctx.strokeStyle = "rgba(0, 229, 255, 0.30)";
                    ctx.lineWidth = 12;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(p0.x, p0.y);
                    for (var i = 1; i < pts.length; i++) {
                        var p = mapEngineRoot.geoToScreen(pts[i].lat, pts[i].lon);
                        ctx.lineTo(p.x, p.y);
                    }
                    ctx.stroke();

                    // 2. Active Core Route Line (Neon Cyan)
                    ctx.strokeStyle = "#00E5FF";
                    ctx.lineWidth = 4.5;
                    ctx.beginPath();
                    ctx.moveTo(p0.x, p0.y);
                    for (var j = 1; j < pts.length; j++) {
                        var pj = mapEngineRoot.geoToScreen(pts[j].lat, pts[j].lon);
                        ctx.lineTo(pj.x, pj.y);
                    }
                    ctx.stroke();

                    // 3. Traveled Path Dimmed Line (Green/Teal)
                    var traveledCount = Math.floor(navigationController.travelProgress * (pts.length - 1));
                    if (traveledCount > 0) {
                        ctx.strokeStyle = "#10B981";
                        ctx.lineWidth = 4.5;
                        ctx.beginPath();
                        ctx.moveTo(p0.x, p0.y);
                        for (var k = 1; k <= traveledCount; k++) {
                            var pk = mapEngineRoot.geoToScreen(pts[k].lat, pts[k].lon);
                            ctx.lineTo(pk.x, pk.y);
                        }
                        ctx.stroke();
                    }
                }
            }

            // Start Location Pin (Green A)
            Item {
                property real sLat: typeof navigationController !== "undefined" ? navigationController.startLat : 12.9756
                property real sLon: typeof navigationController !== "undefined" ? navigationController.startLon : 77.6094
                property var screenPos: mapEngineRoot.geoToScreen(sLat, sLon)
                x: screenPos.x - width / 2
                y: screenPos.y - height / 2
                width: 28
                height: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 11
                    color: "#10B981"
                    border.color: "#A7F3D0"
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "A"
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: "#022C22"
                    }
                }
            }

            // Destination Pin (Cyan Checkered B)
            Item {
                property real dLat: typeof navigationController !== "undefined" ? navigationController.destLat : 12.9352
                property real dLon: typeof navigationController !== "undefined" ? navigationController.destLon : 77.6946
                property var screenPos: mapEngineRoot.geoToScreen(dLat, dLon)
                x: screenPos.x - width / 2
                y: screenPos.y - height / 2
                width: 28
                height: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 11
                    color: "#06B6D4"
                    border.color: "#CFFAFE"
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "B"
                        font.pixelSize: 11
                        font.weight: Font.Black
                        color: "#083344"
                    }
                }
            }

            // Live Vehicle Marker (Luxury Automotive Chevron with Bearing Rotation)
            Item {
                id: vehicleMarker
                property real vLat: typeof navigationController !== "undefined" ? navigationController.vehicleLat : 12.9756
                property real vLon: typeof navigationController !== "undefined" ? navigationController.vehicleLon : 77.6094
                property var screenPos: mapEngineRoot.geoToScreen(vLat, vLon)
                x: screenPos.x - width / 2
                y: screenPos.y - height / 2
                width: 40
                height: 40

                Item {
                    anchors.fill: parent
                    rotation: typeof navigationController !== "undefined" ? navigationController.vehicleBearing : 90.0

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34; height: 34; radius: 17
                        color: "transparent"
                        border.color: "#38BDF8"
                        border.width: 1.5
                        opacity: 0.7
                    }

                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "#38BDF8";
                            ctx.shadowColor = "#00E5FF";
                            ctx.shadowBlur = 8;
                            ctx.beginPath();
                            ctx.moveTo(20, 5);
                            ctx.lineTo(31, 31);
                            ctx.lineTo(20, 24);
                            ctx.lineTo(9, 31);
                            ctx.closePath();
                            ctx.fill();

                            ctx.fillStyle = "#FFFFFF";
                            ctx.beginPath();
                            ctx.arc(20, 15, 2.5, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }
                }
            }

            // Interactive Map Mouse & Drag Controller
            MouseArea {
                id: mapMouseArea
                anchors.fill: parent
                drag.target: null
                hoverEnabled: true

                property real lastX: 0
                property real lastY: 0

                onPressed: function(mouse) {
                    lastX = mouse.x;
                    lastY = mouse.y;

                    if (typeof navigationController === "undefined") return;

                    if (mapEngineRoot.pinPlacementMode === "SET_START") {
                        var geoS = mapEngineRoot.screenToGeo(mouse.x, mouse.y);
                        navigationController.setPinLocation("SET_START", geoS.lat, geoS.lon);
                        mapEngineRoot.pinPlacementMode = "NONE";
                    } else if (mapEngineRoot.pinPlacementMode === "SET_DEST") {
                        var geoD = mapEngineRoot.screenToGeo(mouse.x, mouse.y);
                        navigationController.setPinLocation("SET_DEST", geoD.lat, geoD.lon);
                        mapEngineRoot.pinPlacementMode = "NONE";
                    }
                }

                onPositionChanged: function(mouse) {
                    if (pressed && mapEngineRoot.pinPlacementMode === "NONE" && typeof navigationController !== "undefined") {
                        var dx = mouse.x - lastX;
                        var dy = mouse.y - lastY;
                        lastX = mouse.x;
                        lastY = mouse.y;

                        var zoom = navigationController.zoomLevel;
                        var centerTX = mapEngineRoot.lonToTileX(navigationController.centerLon, zoom) - dx / 256.0;
                        var centerTY = mapEngineRoot.latToTileY(navigationController.centerLat, zoom) - dy / 256.0;

                        navigationController.centerLon = mapEngineRoot.tileXToLon(centerTX, zoom);
                        navigationController.centerLat = mapEngineRoot.tileYToLat(centerTY, zoom);
                        routeCanvas.requestPaint();
                    }
                }

                onWheel: function(wheel) {
                    if (typeof navigationController === "undefined") return;
                    if (wheel.angleDelta.y > 0 && navigationController.zoomLevel < 18) {
                        navigationController.zoomLevel += 1;
                    } else if (wheel.angleDelta.y < 0 && navigationController.zoomLevel > 3) {
                        navigationController.zoomLevel -= 1;
                    }
                    routeCanvas.requestPaint();
                }
            }

            // Pin Placement Overlay Banner
            Rectangle {
                visible: mapEngineRoot.pinPlacementMode !== "NONE"
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                height: 28
                width: 320
                radius: 14
                color: "#0284C7"
                border.color: "#38BDF8"

                Text {
                    anchors.centerIn: parent
                    text: (mapEngineRoot.pinPlacementMode === "SET_START") ? "📍 Click anywhere on the map to set START" : "🏁 Click anywhere on the map to set DESTINATION"
                    color: "#FFFFFF"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }

            // ─── 4-WAY D-PAD MAP PAN CONTROLLER (TOP-LEFT) ───
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 10
                width: 84
                height: 84
                radius: 42
                color: "#0F172A"
                border.color: "#334155"
                border.width: 1.2
                opacity: 0.9

                // UP (North)
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: "#1E293B"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: 4
                    Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: 10; color: "#38BDF8" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined") navigationController.panDirection("UP"); }
                    }
                }

                // DOWN (South)
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: "#1E293B"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                    Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: 10; color: "#38BDF8" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined") navigationController.panDirection("DOWN"); }
                    }
                }

                // LEFT (West)
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: "#1E293B"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 4
                    Text { anchors.centerIn: parent; text: "◀"; font.pixelSize: 10; color: "#38BDF8" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined") navigationController.panDirection("LEFT"); }
                    }
                }

                // RIGHT (East)
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: "#1E293B"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right; anchors.rightMargin: 4
                    Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 10; color: "#38BDF8" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined") navigationController.panDirection("RIGHT"); }
                    }
                }

                // Center Dot (Center on Vehicle)
                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: "#0284C7"
                    anchors.centerIn: parent
                    Text { anchors.centerIn: parent; text: "🎯"; font.pixelSize: 9 }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined") navigationController.centerOnVehicle(); }
                    }
                }
            }

            // Zoom & View Control Float Buttons (Bottom-Right)
            Column {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                spacing: 6

                // Center on Vehicle
                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: "#0F172A"; border.color: "#334155"
                    Text { anchors.centerIn: parent; text: "🎯"; font.pixelSize: 13 }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined") navigationController.centerOnVehicle(); }
                    }
                }

                // Fit Route
                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: "#0F172A"; border.color: "#334155"
                    Text { anchors.centerIn: parent; text: "🗺️"; font.pixelSize: 13 }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined") navigationController.fitRouteInView(); }
                    }
                }

                // Zoom In
                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: "#0F172A"; border.color: "#334155"
                    Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 18; font.weight: Font.Bold; color: "#FFFFFF" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined" && navigationController.zoomLevel < 18) navigationController.zoomLevel += 1; }
                    }
                }

                // Zoom Out
                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: "#0F172A"; border.color: "#334155"
                    Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 18; font.weight: Font.Bold; color: "#FFFFFF" }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (typeof navigationController !== "undefined" && navigationController.zoomLevel > 3) navigationController.zoomLevel -= 1; }
                    }
                }
            }
        }

        // 3. PIN SELECTOR & ORIGIN/DESTINATION CONTROL BAR
        Row {
            width: parent.width
            spacing: 8

            // Start Location Selector Button
            Rectangle {
                width: (parent.width - 16) / 3
                height: 32
                radius: 6
                color: (mapEngineRoot.pinPlacementMode === "SET_START") ? "#059669" : "#1E293B"
                border.color: (mapEngineRoot.pinPlacementMode === "SET_START") ? "#34D399" : "#334155"

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "🟢"; font.pixelSize: 11 }
                    Text {
                        text: (mapEngineRoot.pinPlacementMode === "SET_START") ? "Click Map to Drop" : "Set Start Pin"
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mapEngineRoot.pinPlacementMode = (mapEngineRoot.pinPlacementMode === "SET_START") ? "NONE" : "SET_START";
                    }
                }
            }

            // Destination Selector Button
            Rectangle {
                width: (parent.width - 16) / 3
                height: 32
                radius: 6
                color: (mapEngineRoot.pinPlacementMode === "SET_DEST") ? "#0284C7" : "#1E293B"
                border.color: (mapEngineRoot.pinPlacementMode === "SET_DEST") ? "#38BDF8" : "#334155"

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "🏁"; font.pixelSize: 11 }
                    Text {
                        text: (mapEngineRoot.pinPlacementMode === "SET_DEST") ? "Click Map to Drop" : "Set Dest Pin"
                        color: "#FFFFFF"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mapEngineRoot.pinPlacementMode = (mapEngineRoot.pinPlacementMode === "SET_DEST") ? "NONE" : "SET_DEST";
                    }
                }
            }

            // Swap Origin & Destination
            Rectangle {
                width: (parent.width - 16) / 3
                height: 32
                radius: 6
                color: "#1E293B"
                border.color: "#475569"

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "⇄"; font.pixelSize: 12; color: "#38BDF8" }
                    Text { text: "Swap Start/Dest"; color: "#E2E8F0"; font.pixelSize: 10; font.weight: Font.Bold }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof navigationController !== "undefined") {
                            navigationController.swapStartDest();
                        }
                    }
                }
            }
        }

        // 4. REAL-TIME TRAVEL & VEHICLE CONTROLLER
        Rectangle {
            width: parent.width
            height: !mapEngineRoot.isEvReady ? 150 : 124
            color: "#0F172A"
            radius: 8
            border.color: !mapEngineRoot.isEvReady ? "#EF4444" : "#1E293B"

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // EV Ready Lock Warning Banner
                Rectangle {
                    visible: !mapEngineRoot.isEvReady
                    width: parent.width
                    height: 20
                    radius: 4
                    color: "#450A0A"
                    border.color: "#EF4444"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "🔒"; font.pixelSize: 9 }
                        Text {
                            text: "DRIVE LOCKED — Switch power mode to EV READY (Tab 0) to travel on map"
                            color: "#FCA5A5"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }
                }

                // Top Line: Auto-Drive Controls, Multiplier & Manual Step Drive
                Row {
                    width: parent.width
                    spacing: 8

                    // Play / Pause Auto-Drive Button
                    Rectangle {
                        width: 130
                        height: 32
                        radius: 6
                        color: !mapEngineRoot.isEvReady ? "#334155" :
                               (typeof navigationController !== "undefined" && navigationController.isAutoDriving) ? "#DC2626" : "#059669"
                        border.color: !mapEngineRoot.isEvReady ? "#475569" :
                                      (typeof navigationController !== "undefined" && navigationController.isAutoDriving) ? "#F87171" : "#34D399"

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: !mapEngineRoot.isEvReady ? "🔒" :
                                      (typeof navigationController !== "undefined" && navigationController.isAutoDriving) ? "⏸️" : "▶️"
                                font.pixelSize: 12
                            }
                            Text {
                                text: !mapEngineRoot.isEvReady ? "NOT EV READY" :
                                      (typeof navigationController !== "undefined" && navigationController.isAutoDriving) ? "PAUSE TRAVEL" : "AUTO DRIVE"
                                color: !mapEngineRoot.isEvReady ? "#94A3B8" : "#FFFFFF"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: mapEngineRoot.isEvReady ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            onClicked: {
                                if (!mapEngineRoot.isEvReady) {
                                    if (typeof clusterAudio !== "undefined") {
                                        clusterAudio.playWarningAlertChime();
                                    }
                                    return;
                                }
                                if (typeof navigationController !== "undefined") {
                                    navigationController.toggleAutoDrive();
                                }
                            }
                        }
                    }

                    // Manual Drive Forward (Step)
                    Rectangle {
                        width: 70
                        height: 32
                        radius: 6
                        color: !mapEngineRoot.isEvReady ? "#1E293B" : "#1E293B"
                        border.color: !mapEngineRoot.isEvReady ? "#475569" : "#38BDF8"
                        opacity: mapEngineRoot.isEvReady ? 1.0 : 0.5

                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: mapEngineRoot.isEvReady ? "▲" : "🔒"
                                font.pixelSize: 11
                                color: mapEngineRoot.isEvReady ? "#38BDF8" : "#94A3B8"
                            }
                            Text {
                                text: mapEngineRoot.isEvReady ? "Drive" : "Lock"
                                color: mapEngineRoot.isEvReady ? "#E2E8F0" : "#64748B"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: mapEngineRoot.isEvReady ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                            onClicked: {
                                if (!mapEngineRoot.isEvReady) {
                                    if (typeof clusterAudio !== "undefined") {
                                        clusterAudio.playWarningAlertChime();
                                    }
                                    return;
                                }
                                if (typeof navigationController !== "undefined") {
                                    navigationController.manualDrive(1.0);
                                }
                            }
                        }
                    }

                    // Reset to Start Button
                    Rectangle {
                        width: 60
                        height: 32
                        radius: 6
                        color: "#1E293B"
                        border.color: "#475569"

                        Text { anchors.centerIn: parent; text: "⏮️ Reset"; color: "#E2E8F0"; font.pixelSize: 9; font.weight: Font.Bold }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof navigationController !== "undefined") {
                                    navigationController.resetTravel();
                                }
                            }
                        }
                    }

                    // Speed Multiplier (1x, 2x, 5x, 10x)
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: [1.0, 2.0, 5.0, 10.0]
                            Rectangle {
                                width: 32
                                height: 26
                                radius: 4
                                color: (typeof navigationController !== "undefined" && navigationController.speedMultiplier === modelData) ? "#0284C7" : "#1E293B"
                                border.color: (typeof navigationController !== "undefined" && navigationController.speedMultiplier === modelData) ? "#38BDF8" : "#334155"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "x"
                                    color: "#FFFFFF"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof navigationController !== "undefined") {
                                            navigationController.speedMultiplier = modelData;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 4 }

                    // GPS Lost Toggle
                    Rectangle {
                        width: 78
                        height: 28
                        radius: 5
                        color: (typeof navigationController !== "undefined" && navigationController.gpsLost) ? "#EF4444" : "#1E293B"
                        border.color: (typeof navigationController !== "undefined" && navigationController.gpsLost) ? "#F87171" : "#475569"

                        Text {
                            anchors.centerIn: parent
                            text: (typeof navigationController !== "undefined" && navigationController.gpsLost) ? "📡 NO GPS" : "📡 GPS OK"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof navigationController !== "undefined") {
                                    navigationController.gpsLost = !navigationController.gpsLost;
                                }
                            }
                        }
                    }
                }

                // Route Travel Scrubber Slider
                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Start"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#94A3B8"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Slider {
                        id: travelSlider
                        width: parent.width - 170
                        from: 0.0
                        to: 1.0
                        value: typeof navigationController !== "undefined" ? navigationController.travelProgress : 0.0
                        onMoved: {
                            if (typeof navigationController !== "undefined") {
                                navigationController.isAutoDriving = false;
                                navigationController.travelProgress = value;
                            }
                        }
                    }

                    Text {
                        text: (typeof navigationController !== "undefined" ? Math.round(navigationController.travelProgress * 100) : 0) + "% (" +
                              (typeof navigationController !== "undefined" ? navigationController.navRemainingKm : "0 km") + ")"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#00E5FF"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Live Navigation Status Bar (Mirrors Cluster Telemetry)
                Row {
                    width: parent.width
                    spacing: 12

                    Text {
                        text: "📍 " + (typeof navigationController !== "undefined" ? navigationController.navStreet : "Route Starting")
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                        elide: Text.ElideRight
                        width: 170
                    }

                    Text {
                        text: "Turn: " + (typeof navigationController !== "undefined" ? navigationController.navDistance : "0 m") +
                              " (" + (typeof navigationController !== "undefined" ? navigationController.navManeuver : "straight") + ")"
                        font.pixelSize: 10
                        color: "#38BDF8"
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Heading: " + (typeof navigationController !== "undefined" ? navigationController.compassHeading : "E") +
                              " (" + (typeof navigationController !== "undefined" ? Math.round(navigationController.vehicleBearing) : 0) + "°)"
                        font.pixelSize: 10
                        color: "#F59E0B"
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Speed: " + (typeof navigationController !== "undefined" ? Math.round(navigationController.currentSimSpeed) : 0) + " km/h"
                        font.pixelSize: 10
                        color: "#10B981"
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }
}
