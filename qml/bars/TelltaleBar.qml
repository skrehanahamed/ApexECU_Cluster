import QtQuick
import QtQuick.Controls

/****************************************************************************
** Component: TelltaleBar.qml
** Role: Top ISO 7000 / ISO 2575 Automotive Warning Indicator Bar
** Features:
**   - Bulb-Check Self-Test on Cluster Startup (All warning icons light up)
**   - Previous Sharp Clean Vector Turn Arrows (Left & Right Canvas Vector)
**   - Official ISO 7000 Active/Inactive SVG Vector Icons
**   - 100% Vibrant OEM Colors (Red, Amber, Green, Blue)
**   - Uniform Muted Slate for Inactive States (#475569)
****************************************************************************/

Item {
    id: telltaleBar
    width: parent.width
    height: 38

    // ═══════════════════════════════════════════════════════════════
    // TELLTALE STATES (ON / OFF TOGGLEABLE VIA ECU EMULATOR)
    // ═══════════════════════════════════════════════════════════════
    property bool bulbCheckActive: false

    property bool turnLeft:      false
    property bool seatbelt:      true   // Red
    property bool airbag:        true   // Red
    property bool traction:      true   // Amber
    property bool parkBrake:     true   // Red
    property bool abs:           true   // Amber
    property bool checkEngine:   true   // Amber
    property bool battery12v:    true   // Red
    property bool tpms:          true   // Amber
    property bool evPlug:        true   // Amber

    property bool autoHighBeam:  true   // Green
    property bool lowBeam:       true   // Green
    property bool highBeam:      true   // Blue
    property bool fogLamp:       true   // Green
    property bool batteryTemp:   true   // Red
    property bool masterWarning: true   // Amber
    property bool doorOpen:      true   // Red
    property bool turnRight:     false

    // Blinker Timer only for Left/Right Turn Signals & Hazards
    Timer {
        id: blinkTimer
        interval: 450
        repeat: true
        running: telltaleBar.turnLeft || telltaleBar.turnRight
        property bool stateOn: true
        onTriggered: stateOn = !stateOn
    }

    Row {
        id: iconsRow
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        spacing: (parent.width - 56 - 96 - 18 * 20) / 19

        // 0. APEX Wordmark
        Image {
            width: 112
            height: 22
            anchors.verticalCenter: parent.verticalCenter
            source: "../../assets/branding/apex_wordmark.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.98
            smooth: true
        }

        // 1. LEFT TURN SIGNAL (Sharp Clean Vector Arrow)
        Canvas {
            id: leftArrowCanvas
            width: 18; height: 16; anchors.verticalCenter: parent.verticalCenter
            opacity: (telltaleBar.turnLeft || telltaleBar.bulbCheckActive) ? (blinkTimer.stateOn ? 1.0 : 0.20) : 0.25
            onPaint: {
                var ctx = getContext("2d"); ctx.reset();
                ctx.fillStyle = (telltaleBar.turnLeft || telltaleBar.bulbCheckActive) ? "#10B981" : "#475569";
                ctx.beginPath();
                ctx.moveTo(14, 2); ctx.lineTo(6, 2); ctx.lineTo(6, 0); ctx.lineTo(0, 8);
                ctx.lineTo(6, 16); ctx.lineTo(6, 14); ctx.lineTo(14, 14); ctx.closePath();
                ctx.fill();
            }
            Connections {
                target: telltaleBar
                function onTurnLeftChanged() { leftArrowCanvas.requestPaint(); }
                function onBulbCheckActiveChanged() { leftArrowCanvas.requestPaint(); }
            }
            Connections {
                target: blinkTimer
                function onStateOnChanged() { if (telltaleBar.turnLeft) leftArrowCanvas.requestPaint(); }
            }
        }

        // 2. SEATBELT (Red)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.seatbelt || telltaleBar.bulbCheckActive) ? "../../assets/telltales/seatbelt_active.svg" : "../../assets/telltales/seatbelt_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.seatbelt || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 3. AIRBAG (Red SRS)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.airbag || telltaleBar.bulbCheckActive) ? "../../assets/telltales/airbag_active.svg" : "../../assets/telltales/airbag_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.airbag || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 4. TRACTION CONTROL (Amber)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.traction || telltaleBar.bulbCheckActive) ? "../../assets/telltales/traction_active.svg" : "../../assets/telltales/traction_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.traction || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 5. PARKING BRAKE (P) (Red)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.parkBrake || telltaleBar.bulbCheckActive) ? "../../assets/telltales/park_brake_active.svg" : "../../assets/telltales/park_brake_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.parkBrake || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 6. ABS (Amber)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.abs || telltaleBar.bulbCheckActive) ? "../../assets/telltales/abs_active.svg" : "../../assets/telltales/abs_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.abs || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 7. CHECK ENGINE / EV MOTOR (Amber)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.checkEngine || telltaleBar.bulbCheckActive) ? "../../assets/telltales/check_engine_active.svg" : "../../assets/telltales/check_engine_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.checkEngine || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 8. 12V BATTERY (Red)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.battery12v || telltaleBar.bulbCheckActive) ? "../../assets/telltales/battery_12v_active.svg" : "../../assets/telltales/battery_12v_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.battery12v || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 9. TPMS TIRE PRESSURE (Amber)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.tpms || telltaleBar.bulbCheckActive) ? "../../assets/telltales/tpms_active.svg" : "../../assets/telltales/tpms_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.tpms || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 10. EV CHARGE PLUG (Amber)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.evPlug || telltaleBar.bulbCheckActive) ? "../../assets/telltales/ev_plug_active.svg" : "../../assets/telltales/ev_plug_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.evPlug || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // Divider |
        Rectangle { width: 1; height: 16; color: "#334155"; anchors.verticalCenter: parent.verticalCenter }

        // 11. AUTO HIGH BEAM (A) (Green)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.autoHighBeam || telltaleBar.bulbCheckActive) ? "../../assets/telltales/auto_high_beam_active.svg" : "../../assets/telltales/auto_high_beam_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.autoHighBeam || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 12. LOW BEAM HEADLIGHTS (Green)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.lowBeam || telltaleBar.bulbCheckActive) ? "../../assets/telltales/low_beam_active.svg" : "../../assets/telltales/low_beam_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.lowBeam || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 13. HIGH BEAM HEADLIGHTS (Blue)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.highBeam || telltaleBar.bulbCheckActive) ? "../../assets/telltales/high_beam_active.svg" : "../../assets/telltales/high_beam_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.highBeam || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 14. FOG LAMPS (Green)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.fogLamp || telltaleBar.bulbCheckActive) ? "../../assets/telltales/fog_lamp_active.svg" : "../../assets/telltales/fog_lamp_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.fogLamp || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 15. BATTERY OVERHEAT TEMP (Red)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.batteryTemp || telltaleBar.bulbCheckActive) ? "../../assets/telltales/battery_temp_active.svg" : "../../assets/telltales/battery_temp_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.batteryTemp || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 16. MASTER WARNING (Amber)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.masterWarning || telltaleBar.bulbCheckActive) ? "../../assets/telltales/master_warning_active.svg" : "../../assets/telltales/master_warning_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.masterWarning || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 17. DOOR OPEN / AJAR (Red)
        Image {
            width: 19; height: 19; anchors.verticalCenter: parent.verticalCenter
            source: (telltaleBar.doorOpen || telltaleBar.bulbCheckActive) ? "../../assets/telltales/door_open_active.svg" : "../../assets/telltales/door_open_inactive.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: (telltaleBar.doorOpen || telltaleBar.bulbCheckActive) ? 1.0 : 0.25
        }

        // 18. RIGHT TURN SIGNAL (Sharp Clean Vector Arrow)
        Canvas {
            id: rightArrowCanvas
            width: 18; height: 16; anchors.verticalCenter: parent.verticalCenter
            opacity: (telltaleBar.turnRight || telltaleBar.bulbCheckActive) ? (blinkTimer.stateOn ? 1.0 : 0.20) : 0.25
            onPaint: {
                var ctx = getContext("2d"); ctx.reset();
                ctx.fillStyle = (telltaleBar.turnRight || telltaleBar.bulbCheckActive) ? "#10B981" : "#475569";
                ctx.beginPath();
                ctx.moveTo(4, 2); ctx.lineTo(12, 2); ctx.lineTo(12, 0); ctx.lineTo(18, 8);
                ctx.lineTo(12, 16); ctx.lineTo(12, 14); ctx.lineTo(4, 14); ctx.closePath();
                ctx.fill();
            }
            Connections {
                target: telltaleBar
                function onTurnRightChanged() { rightArrowCanvas.requestPaint(); }
                function onBulbCheckActiveChanged() { rightArrowCanvas.requestPaint(); }
            }
            Connections {
                target: blinkTimer
                function onStateOnChanged() { if (telltaleBar.turnRight) rightArrowCanvas.requestPaint(); }
            }
        }
    }
}
