import QtQuick
import QtQuick.Controls

Item {
    id: bottomInfoBar
    width: parent.width
    height: 40

    property real batteryPercent: 72.0
    property real rangeKm: 428.0
    property string gear: "D"
    property int altitudeM: 1250
    property string heading: "SW"
    property string themeColor: "#00e5ff"

    // ─── LEFT: Battery Status [🔋] 72% --- 428 km ───
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Battery outline + fill icon
        Item {
            width: 24
            height: 12
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.left: parent.left
                width: 21
                height: 12
                radius: 2.5
                color: "transparent"
                border.color: bottomInfoBar.themeColor
                border.width: 1.3

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: (parent.width - 4) * (bottomInfoBar.batteryPercent / 100.0)
                    height: parent.height - 4
                    radius: 1
                    color: bottomInfoBar.themeColor
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 5
                radius: 0.8
                color: bottomInfoBar.themeColor
            }
        }

        // 72%
        Text {
            text: Math.round(bottomInfoBar.batteryPercent) + "%"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.family: "sans-serif"
            color: "#FFFFFF"
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }

        // Segmented cyan dashes
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Repeater {
                model: 8
                Rectangle {
                    width: 6
                    height: 2.5
                    radius: 1
                    color: (index < Math.round(bottomInfoBar.batteryPercent / 12.5)) ? bottomInfoBar.themeColor : "#1E293B"
                }
            }
        }

        // 428 km
        Text {
            text: Math.round(bottomInfoBar.rangeKm) + " km"
            font.pixelSize: 13
            font.weight: Font.Normal
            font.letterSpacing: 0.5
            font.family: "sans-serif"
            color: "#94A3B8"
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }
    }

    // ─── CENTER: Gear Selector P R N D ───
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 24

        Repeater {
            model: ["P", "R", "N", "D"]
            Item {
                width: 18
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: gearText
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: 15
                    font.weight: (modelData === bottomInfoBar.gear) ? Font.Bold : Font.Normal
                    font.letterSpacing: 1.0
                    font.family: "sans-serif"
                    color: (modelData === bottomInfoBar.gear) ? bottomInfoBar.themeColor : "#475569"
                    renderType: Text.NativeRendering
                }

                // Cyan underline for selected gear
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 14
                    height: 2
                    radius: 1
                    color: bottomInfoBar.themeColor
                    visible: modelData === bottomInfoBar.gear
                }
            }
        }
    }

    // ─── RIGHT: Altitude & Compass Heading ───
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 40
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        // Mountain icon + 1250 m
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Canvas {
                width: 14; height: 12; anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    ctx.strokeStyle = "#94A3B8"; ctx.lineWidth = 1.2;
                    ctx.beginPath();
                    ctx.moveTo(1, 11); ctx.lineTo(6, 2); ctx.lineTo(10, 8); ctx.lineTo(13, 11);
                    ctx.stroke();
                }
            }

            Text {
                text: bottomInfoBar.altitudeM + " m"
                font.pixelSize: 13
                font.weight: Font.Normal
                font.letterSpacing: 0.5
                font.family: "Menlo, Monaco, monospace"
                color: "#94A3B8"
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }

        // Divider |
        Rectangle {
            width: 1
            height: 12
            color: "#2D3748"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Compass icon + SW
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Canvas {
                width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    ctx.strokeStyle = "#94A3B8"; ctx.lineWidth = 1.2;
                    ctx.beginPath(); ctx.arc(7, 7, 6, 0, Math.PI*2); ctx.stroke();
                    // Arrow
                    ctx.fillStyle = bottomInfoBar.themeColor;
                    ctx.beginPath(); ctx.moveTo(7, 3); ctx.lineTo(9, 7); ctx.lineTo(7, 6); ctx.lineTo(5, 7); ctx.closePath(); ctx.fill();
                }
            }

            Text {
                text: bottomInfoBar.heading
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
                font.family: "Inter, sans-serif"
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.NativeRendering
            }
        }
    }
}
