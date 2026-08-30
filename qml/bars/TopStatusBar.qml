import QtQuick
import QtQuick.Controls

Item {
    id: statusBar
    width: parent.width
    height: 32

    property string currentTime: ""
    property string driveMode: "COMFORT"
    property int temperature: 24
    property string themeColor: "#00e5ff"
    property bool adasActive: false
    property bool gpsLost: false
    property bool isEvReady: true

    function updateSystemTime() {
        var d = new Date();
        var hours = d.getHours();
        var minutes = d.getMinutes();
        var ampm = hours >= 12 ? "PM" : "AM";
        var h12 = hours % 12;
        if (h12 === 0) h12 = 12;
        var mStr = (minutes < 10 ? "0" : "") + minutes;
        var hStr = (h12 < 10 ? "0" : "") + h12;
        statusBar.currentTime = hStr + ":" + mStr + " " + ampm;
    }

    Timer {
        id: systemClockTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: statusBar.updateSystemTime()
    }

    Component.onCompleted: {
        updateSystemTime();
    }

    // ─── 1. EXTREME LEFT: Time (Synchronized with System Clock) ───
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        text: statusBar.currentTime
        font.pixelSize: 13
        font.weight: Font.Medium
        font.letterSpacing: 0.5
        font.family: "Inter"
        color: "#94A3B8"
        renderType: Text.NativeRendering
    }

    // ─── 2. MIDDLE: Drive Mode + ADAS Status (or CHARGING) ───
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 20

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: statusBar.driveMode
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.letterSpacing: 2.5
            font.capitalization: Font.AllUppercase
            font.family: "Inter"
            color: statusBar.themeColor
            renderType: Text.NativeRendering
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (statusBar.driveMode === "CHARGING") ? (statusBar.adasActive ? "COMPLETE" : "ACTIVE") : (statusBar.adasActive ? "DRIVER ASSIST" : "DRIVER ASSIST OFF")
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            font.family: "Inter"
            color: (statusBar.driveMode === "CHARGING" || statusBar.adasActive) ? statusBar.themeColor : "#64748B"
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
                font.weight: Font.Medium
                font.letterSpacing: 0.5
                font.family: "Inter"
                color: (statusBar.temperature < 3) ? "#FFFFFF" : "#94A3B8"
                renderType: Text.NativeRendering
            }
        }

        // GPS Status (with strike-through slash when signal is lost)
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: gpsText.implicitWidth + 2
            height: gpsText.implicitHeight

            Text {
                id: gpsText
                anchors.centerIn: parent
                text: "GPS"
                font.pixelSize: 12
                font.weight: Font.Medium
                font.letterSpacing: 1.0
                font.family: "Inter"
                color: statusBar.gpsLost ? "#EF4444" : "#94A3B8"
                renderType: Text.NativeRendering
                opacity: statusBar.gpsLost ? 0.75 : 1.0

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            // Clean diagonal red slash mark through GPS text
            Canvas {
                id: gpsSlashCanvas
                anchors.fill: parent
                visible: statusBar.gpsLost
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    ctx.strokeStyle = "#EF4444";
                    ctx.lineWidth = 1.6;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.moveTo(1, height - 1);
                    ctx.lineTo(width - 1, 1);
                    ctx.stroke();
                }
                Connections {
                    target: statusBar
                    function onGpsLostChanged() { gpsSlashCanvas.requestPaint(); }
                }
            }
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
                font.family: "Inter"
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
