import QtQuick
import QtQuick.Controls

Item {
    id: statusBar
    width: parent.width
    height: 32

    property string currentTime: "10:42 AM"
    property string driveMode: "COMFORT"
    property int temperature: 24
    property string themeColor: "#00e5ff"
    property bool adasActive: false

    // ─── 1. EXTREME LEFT: Time ───
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        text: statusBar.currentTime
        font.pixelSize: 13
        font.weight: Font.Normal
        font.letterSpacing: 0.5
        font.family: "Menlo, Monaco, monospace"
        color: "#94A3B8"
        renderType: Text.NativeRendering
    }

    // ─── 2. MIDDLE: Drive Mode + ADAS Status ───
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: statusBar.driveMode
            font.pixelSize: 13
            font.weight: Font.Bold
            font.letterSpacing: 2.5
            font.capitalization: Font.AllUppercase
            font.family: "sans-serif"
            color: statusBar.themeColor
            renderType: Text.NativeRendering
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: statusBar.adasActive ? "DRIVER ASSIST" : "DRIVER ASSIST OFF"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            font.family: "sans-serif"
            color: statusBar.adasActive ? statusBar.themeColor : "#64748B"
            renderType: Text.NativeRendering
        }
    }

    // ─── 3. EXTREME RIGHT: Temperature (with Freezing Snowflake < 3°C) + GPS + LTE Info ───
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18

        // Ambient Temperature (with white snowflake freeze indicator < 3°C)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            // Freeze Logo (Pure White, active when temperature < 3°C)
            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                source: "../../assets/telltales/freeze_warning.svg"
                visible: statusBar.temperature < 3
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: statusBar.temperature + "°C"
                font.pixelSize: 13
                font.weight: Font.Normal
                font.letterSpacing: 0.5
                font.family: "Menlo, Monaco, monospace"
                color: (statusBar.temperature < 3) ? "#FFFFFF" : "#94A3B8"
                renderType: Text.NativeRendering
            }
        }

        // GPS Status
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "GPS"
            font.pixelSize: 12
            font.weight: Font.Medium
            font.letterSpacing: 1.0
            font.family: "sans-serif"
            color: "#94A3B8"
            renderType: Text.NativeRendering
        }

        // Cellular Signal LTE
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Text {
                text: "LTE"
                font.pixelSize: 12
                font.weight: Font.Medium
                font.letterSpacing: 0.5
                font.family: "sans-serif"
                color: "#94A3B8"
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2.5
                Repeater {
                    model: 4
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: 2.5
                        height: 3 + index * 3.0
                        radius: 0.5
                        color: index < 3 ? "#94A3B8" : "#334155"
                    }
                }
            }
        }
    }
}
