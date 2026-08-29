import QtQuick
import QtQuick.Window
import QtQuick.Controls
import "views"
import "center"

Window {
    id: rootWindow
    width: 1440
    height: 640
    minimumWidth: 1200
    minimumHeight: 540
    visible: true
    title: "APEX SUV — Digital Instrument Cluster"
    color: "#030406"

    Rectangle {
        id: clusterRoot
        anchors.fill: parent
        color: "#030406"
        clip: true
        focus: true

        function transitionToCluster() {
            clusterTransitionAnim.start();
        }

        function restartMasterBoot() {
            clusterTransitionAnim.stop();
            if (typeof clusterAudio !== "undefined") {
                clusterAudio.playStartupChime();
            }
            drivingCluster.opacity = 0.0;
            drivingCluster.scale = 0.98;
            welcomeScreen.opacity = 1.0;
            welcomeScreen.scale = 1.0;
            welcomeScreen.restartSequence();
            welcomeTransitionTimer.restart();
        }

        // Master Background
        Rectangle {
            anchors.fill: parent
            color: "#030406"
        }

        // 1. Welcome Screen (Active for startup sequence)
        WelcomeScreen {
            id: welcomeScreen
            anchors.fill: parent
            opacity: 1.0
            visible: opacity > 0.0
            onRequestStart: {
                welcomeTransitionTimer.stop();
                clusterRoot.transitionToCluster();
            }
        }

        // 2. Active Driving Instrument Cluster
        DrivingCluster {
            id: drivingCluster
            anchors.fill: parent
            opacity: 0.0
            scale: 0.98
            visible: opacity > 0.0
        }

        // Master Transition Timer: 3.5 seconds (Synchronized with pure luxury startup chime)
        Timer {
            id: welcomeTransitionTimer
            interval: 3500
            running: true
            repeat: false
            onTriggered: {
                clusterRoot.transitionToCluster();
            }
        }

        // Smooth Cinematic Transition
        ParallelAnimation {
            id: clusterTransitionAnim

            NumberAnimation {
                target: welcomeScreen
                property: "opacity"
                to: 0.0
                duration: 800
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: welcomeScreen
                property: "scale"
                to: 1.03
                duration: 800
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: drivingCluster
                property: "opacity"
                to: 1.0
                duration: 900
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: drivingCluster
                property: "scale"
                to: 1.0
                duration: 900
                easing.type: Easing.OutCubic
            }
            ScriptAction {
                script: {
                    drivingCluster.activateCluster();
                }
            }
        }

        // Keyboard controls
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Space) {
                // Spacebar: Complete Full System Reboot
                clusterRoot.restartMasterBoot();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_C) {
                // Return / Enter / C: Skip directly into Cluster Bootup
                welcomeTransitionTimer.stop();
                clusterRoot.transitionToCluster();
                event.accepted = true;
            } else if (event.key === Qt.Key_D) {
                drivingCluster.toggleDriveMode();
                event.accepted = true;
            } else if (event.key === Qt.Key_T) {
                drivingCluster.toggleAllWarnings();
                event.accepted = true;
            } else if (event.key === Qt.Key_E || event.key === Qt.Key_Tab) {
                drivingCluster.emulatorOpen = !drivingCluster.emulatorOpen;
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                drivingCluster.telltaleTurnLeft = !drivingCluster.telltaleTurnLeft;
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                drivingCluster.telltaleTurnRight = !drivingCluster.telltaleTurnRight;
                event.accepted = true;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 3. DEDICATED ECU EMULATOR & VEHICLE CONTROL WINDOW
    // ═══════════════════════════════════════════════════════════════
    Window {
        id: emulatorWindow
        title: "APEX ECU Telemetry & Simulator Control"
        width: 580
        height: 640
        minimumWidth: 480
        minimumHeight: 520
        visible: drivingCluster.emulatorOpen
        color: "#0B111A"
        x: rootWindow.x + rootWindow.width + 16
        y: rootWindow.y

        onClosing: function(close) {
            drivingCluster.emulatorOpen = false;
        }

        EcuEmulatorPanel {
            anchors.fill: parent
            clusterTarget: drivingCluster
        }
    }
}
