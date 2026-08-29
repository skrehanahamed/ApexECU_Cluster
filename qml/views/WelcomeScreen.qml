import QtQuick
import QtQuick.Controls

Item {
    id: welcomeView
    anchors.fill: parent

    // =========================================================================
    // X and Y Position Offsets (Adjust these values to move elements)
    // Positive (+) moves RIGHT or DOWN, Negative (-) moves LEFT or UP
    // =========================================================================
    property real logoOffsetX: 0     // <-- Change Logo X position here (e.g. +50 for right, -50 for left)
    property real logoOffsetY: 70    // <-- Change Logo Y position here
    
    property real textOffsetX: 0     // <-- Change Text X position here (e.g. +50 for right, -50 for left)
    property real textOffsetY: -15   // <-- Change Text Y position relative to logo

    signal requestStart()

    function restartSequence() {
        masterTimeline.stop();
        vehicleSilhouette.opacity = 0.0;
        wordmarkContainer.opacity = 0.0;
        wordmarkContainer.scale = 0.98;
        welcomeContainer.opacity = 0.0;
        masterTimeline.start();
    }

    // 1. Luxury Vehicle Silhouette Layer
    Image {
        id: vehicleSilhouette
        anchors.fill: parent
        source: "../../assets/vehicles/car_silhouette.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        opacity: 0.0
    }

    // 2. Central APEX Wordmark
    Item {
        id: wordmarkContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: welcomeView.logoOffsetX // Controlled by logoOffsetX above
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: welcomeView.logoOffsetY   // Controlled by logoOffsetY above
        width: parent.width * 0.42
        height: width * 0.42
        opacity: 0.0
        scale: 0.98

        Image {
            id: wordmarkImage
            anchors.fill: parent
            source: "../../assets/branding/apex_wordmark.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
    }

    // 3. Dynamic QML Welcome & Ready to Ride Section
    Item {
        id: welcomeContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: welcomeView.textOffsetX // Controlled by textOffsetX above
        anchors.top: wordmarkContainer.bottom
        anchors.topMargin: welcomeView.textOffsetY              // Controlled by textOffsetY above
        width: 600
        height: 120
        opacity: 0.0

        // "WELCOME" Heading
        Text {
            id: welcomeText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: "WELCOME"
            font.pixelSize: 18
            font.weight: Font.Light
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 15
            color: "#CBD5E1"
            renderType: Text.NativeRendering
        }

        // "READY TO DRIVE." with Glowing Cyan Dot
        Row {
            id: readyRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: welcomeText.bottom
            anchors.topMargin: 12
            spacing: 1

            Text {
                text: "READY TO DRIVE"
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
            id: indicatorLine
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: readyRow.bottom
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

    // =========================================================================
    // Master Startup Timeline (0.0s - 2.6s)
    // =========================================================================
    SequentialAnimation {
        id: masterTimeline
        running: true

        PropertyAction { target: vehicleSilhouette; property: "opacity"; value: 0.0 }
        PropertyAction { target: wordmarkContainer; property: "opacity"; value: 0.0 }
        PropertyAction { target: wordmarkContainer; property: "scale";   value: 0.98 }
        PropertyAction { target: welcomeContainer; property: "opacity"; value: 0.0 }

        // 0.0 - 0.3s: Pure Dark Start
        PauseAnimation { duration: 250 }

        // 0.3 - 1.3s: Vehicle Silhouette Softly Materializes
        ParallelAnimation {
            NumberAnimation { target: vehicleSilhouette; property: "opacity"; from: 0.0; to: 1.0; duration: 1000; easing.type: Easing.OutCubic }
        }

        // 1.0 - 1.8s: APEX Wordmark Illuminates
        ParallelAnimation {
            NumberAnimation { target: wordmarkContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 800; easing.type: Easing.OutCubic }
            NumberAnimation { target: wordmarkContainer; property: "scale"; from: 0.98; to: 1.0; duration: 800; easing.type: Easing.OutCubic }
        }

        // 1.6 - 2.4s: Welcome & Ready to Ride Reveal
        ParallelAnimation {
            NumberAnimation { target: welcomeContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 800; easing.type: Easing.OutCubic }
        }
    }

    // Click Area to immediately start bootup sequence
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: welcomeView.requestStart()
    }
}
