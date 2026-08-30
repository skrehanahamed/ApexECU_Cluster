import QtQuick
import QtQuick.Controls

Item {
    id: tpmsCard
    width: 210
    height: 180

    property real flBar: 2.4
    property real frBar: 2.4
    property real rlBar: 2.4
    property real rrBar: 2.4

    property bool isOpen: false
    property string themeColor: "#00E5FF"

    signal closeRequested()

    function getStatusColor(val) {
        if (isNaN(val) || val < 0) return "#64748B"; // Fault
        if (val < 1.6) return "#EF4444";             // Critical
        if (val < 2.2 || val > 2.8) return "#F59E0B"; // Low / Warning
        return "#10B981";                            // Normal
    }

    function formatVal(val) {
        if (isNaN(val) || val < 0) return "--";
        return val.toFixed(1);
    }

    readonly property bool hasCritical: (flBar >= 0 && flBar < 1.6) || (frBar >= 0 && frBar < 1.6) || (rlBar >= 0 && rlBar < 1.6) || (rrBar >= 0 && rrBar < 1.6)
    readonly property bool hasWarning:  (flBar >= 0 && (flBar < 2.2 || flBar > 2.8)) || (frBar >= 0 && (frBar < 2.2 || frBar > 2.8)) || (rlBar >= 0 && (rlBar < 2.2 || rlBar > 2.8)) || (rrBar >= 0 && (rrBar < 2.2 || rrBar > 2.8))
    readonly property bool hasFault:    (flBar < 0 || frBar < 0 || rlBar < 0 || rrBar < 0 || isNaN(flBar) || isNaN(frBar) || isNaN(rlBar) || isNaN(rrBar))

    readonly property string headerStatusText: hasCritical ? "CRITICAL PRESSURE" :
                                              (hasWarning  ? "LOW PRESSURE" :
                                              (hasFault    ? "SENSOR FAULT" : "ALL TIRES OPTIMAL"))

    readonly property string headerStatusColor: hasCritical ? "#EF4444" :
                                               (hasWarning  ? "#F59E0B" :
                                               (hasFault    ? "#94A3B8" : "#10B981"))

    opacity: isOpen ? 1.0 : 0.0
    scale:   isOpen ? 1.0 : 0.88
    visible: opacity > 0.001

    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { duration: 280; easing.type: Easing.OutBack  } }

    // Frosted Glassmorphism Background Card
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#E6080E17"
        border.color: tpmsCard.hasCritical ? Qt.rgba(0.93, 0.27, 0.27, 0.5) :
                      tpmsCard.hasWarning  ? Qt.rgba(0.96, 0.62, 0.04, 0.5) :
                      Qt.rgba(0.2, 0.3, 0.45, 0.35)
        border.width: 1.2

        // Top Accent Glow line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 1.2
            radius: 1
            color: tpmsCard.headerStatusColor
            opacity: 0.7
        }
    }

    // ─── Header: TPMS Title & Status ───
    Item {
        id: cardHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 22

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Image {
                width: 14
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                source: "../../assets/telltales/tpms_active.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                text: "TPMS"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                font.family: "Inter"
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }

            Rectangle {
                width: 3
                height: 3
                radius: 1.5
                color: "#475569"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: tpmsCard.headerStatusText
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 0.5
                font.family: "Inter"
                color: tpmsCard.headerStatusColor
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }

        // Close button (x)
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: closeMouse.containsMouse ? "#334155" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "×"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: closeMouse.containsMouse ? "#FFFFFF" : "#64748B"
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tpmsCard.closeRequested()
            }
        }
    }

    // ─── Center: Top-View Vehicle Image ───
    Item {
        id: vehicleArea
        anchors.top: cardHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 6

        Image {
            id: topViewCar
            anchors.centerIn: parent
            width: 66
            height: 120
            source: "../../assets/vehicles/tpms_chassis_topview.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.95
        }

        // ═══════════════════════════════════════════════════════════════
        // TIRE PRESSURE BADGES (FL, FR, RL, RR)
        // ═══════════════════════════════════════════════════════════════

        // 1. FRONT LEFT (FL)
        Item {
            id: flBadge
            x: 6
            y: 14
            width: 58
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Qt.rgba(0.06, 0.09, 0.14, 0.90)
                border.color: tpmsCard.getStatusColor(tpmsCard.flBar)
                border.width: (tpmsCard.flBar < 2.2 || tpmsCard.flBar > 2.8) ? 1.5 : 1.0

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        Text {
                            text: tpmsCard.formatVal(tpmsCard.flBar)
                            font.pixelSize: 13
                            font.weight: Font.Normal
                            font.family: "Inter"
                            color: (tpmsCard.flBar >= 2.2 && tpmsCard.flBar <= 2.8) ? "#FFFFFF" : tpmsCard.getStatusColor(tpmsCard.flBar)
                            renderType: Text.NativeRendering
                        }
                        Text {
                            text: "bar"
                            font.pixelSize: 8
                            font.weight: Font.Medium
                            font.family: "Inter"
                            color: "#94A3B8"
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "FRONT L"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        font.family: "Inter"
                        color: tpmsCard.getStatusColor(tpmsCard.flBar)
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Wheel indicator ring on FL wheel
            Rectangle {
                x: parent.width + 4
                y: 12
                width: 7
                height: 14
                radius: 2
                color: tpmsCard.getStatusColor(tpmsCard.flBar)
                opacity: 0.9
            }
        }

        // 2. FRONT RIGHT (FR)
        Item {
            id: frBadge
            x: parent.width - width - 6
            y: 14
            width: 58
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Qt.rgba(0.06, 0.09, 0.14, 0.90)
                border.color: tpmsCard.getStatusColor(tpmsCard.frBar)
                border.width: (tpmsCard.frBar < 2.2 || tpmsCard.frBar > 2.8) ? 1.5 : 1.0

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        Text {
                            text: tpmsCard.formatVal(tpmsCard.frBar)
                            font.pixelSize: 13
                            font.weight: Font.Normal
                            font.family: "Inter"
                            color: (tpmsCard.frBar >= 2.2 && tpmsCard.frBar <= 2.8) ? "#FFFFFF" : tpmsCard.getStatusColor(tpmsCard.frBar)
                            renderType: Text.NativeRendering
                        }
                        Text {
                            text: "bar"
                            font.pixelSize: 8
                            font.weight: Font.Medium
                            font.family: "Inter"
                            color: "#94A3B8"
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "FRONT R"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        font.family: "Inter"
                        color: tpmsCard.getStatusColor(tpmsCard.frBar)
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Wheel indicator ring on FR wheel
            Rectangle {
                x: -11
                y: 12
                width: 7
                height: 14
                radius: 2
                color: tpmsCard.getStatusColor(tpmsCard.frBar)
                opacity: 0.9
            }
        }

        // 3. REAR LEFT (RL)
        Item {
            id: rlBadge
            x: 6
            y: parent.height - height - 14
            width: 58
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Qt.rgba(0.06, 0.09, 0.14, 0.90)
                border.color: tpmsCard.getStatusColor(tpmsCard.rlBar)
                border.width: (tpmsCard.rlBar < 2.2 || tpmsCard.rlBar > 2.8) ? 1.5 : 1.0

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        Text {
                            text: tpmsCard.formatVal(tpmsCard.rlBar)
                            font.pixelSize: 13
                            font.weight: Font.Normal
                            font.family: "Inter"
                            color: (tpmsCard.rlBar >= 2.2 && tpmsCard.rlBar <= 2.8) ? "#FFFFFF" : tpmsCard.getStatusColor(tpmsCard.rlBar)
                            renderType: Text.NativeRendering
                        }
                        Text {
                            text: "bar"
                            font.pixelSize: 8
                            font.weight: Font.Medium
                            font.family: "Inter"
                            color: "#94A3B8"
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "REAR L"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        font.family: "Inter"
                        color: tpmsCard.getStatusColor(tpmsCard.rlBar)
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Wheel indicator ring on RL wheel
            Rectangle {
                x: parent.width + 4
                y: 12
                width: 7
                height: 14
                radius: 2
                color: tpmsCard.getStatusColor(tpmsCard.rlBar)
                opacity: 0.9
            }
        }

        // 4. REAR RIGHT (RR)
        Item {
            id: rrBadge
            x: parent.width - width - 6
            y: parent.height - height - 14
            width: 58
            height: 38

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: Qt.rgba(0.06, 0.09, 0.14, 0.90)
                border.color: tpmsCard.getStatusColor(tpmsCard.rrBar)
                border.width: (tpmsCard.rrBar < 2.2 || tpmsCard.rrBar > 2.8) ? 1.5 : 1.0

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        Text {
                            text: tpmsCard.formatVal(tpmsCard.rrBar)
                            font.pixelSize: 13
                            font.weight: Font.Normal
                            font.family: "Inter"
                            color: (tpmsCard.rrBar >= 2.2 && tpmsCard.rrBar <= 2.8) ? "#FFFFFF" : tpmsCard.getStatusColor(tpmsCard.rrBar)
                            renderType: Text.NativeRendering
                        }
                        Text {
                            text: "bar"
                            font.pixelSize: 8
                            font.weight: Font.Medium
                            font.family: "Inter"
                            color: "#94A3B8"
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "REAR R"
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                        font.family: "Inter"
                        color: tpmsCard.getStatusColor(tpmsCard.rrBar)
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Wheel indicator ring on RR wheel
            Rectangle {
                x: -11
                y: 12
                width: 7
                height: 14
                radius: 2
                color: tpmsCard.getStatusColor(tpmsCard.rrBar)
                opacity: 0.9
            }
        }
    }
}
