import QtQuick
import QtQuick.Controls

Item {
    id: centralSpeed
    width: 440
    height: 260

    property int speedValue: 87
    property string driveMode: "COMFORT"
    property string themeColor: "#00e5ff"
    property int speedLimit: 80
    property bool showSpeedLimit: true

    Column {
        id: speedMainColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 6
        spacing: 0

        // APEX Logo Emblem (Prominent, Sharp & Separated from Top Bar)
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "../../assets/branding/apex_logo_tight.png"
            width: 135
            height: 52
            fillMode: Image.PreserveAspectFit
            opacity: 0.98
            smooth: true
        }

        // Central Speed Readout Container (Speedometer in exact dead-center)
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: speedText.implicitWidth
            height: speedText.implicitHeight

            // Speed Limit Sign (Positioned to the left side of the speedometer)
            Column {
                anchors.right: parent.left
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -2
                spacing: 3
                opacity: centralSpeed.showSpeedLimit ? 1.0 : 0.0
                scale: centralSpeed.showSpeedLimit ? 1.0 : 0.60

                Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }
                Behavior on scale   { NumberAnimation { duration: 700; easing.type: Easing.OutBack } }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: "#FFFFFF"
                    border.color: "#EF4444"
                    border.width: 3.5

                    Text {
                        anchors.centerIn: parent
                        text: centralSpeed.speedLimit.toString()
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        font.family: "sans-serif"
                        color: "#000000"
                        renderType: Text.NativeRendering
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "LIMIT"
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    font.family: "sans-serif"
                    color: "#94A3B8"
                    renderType: Text.NativeRendering
                }
            }

            // Speed Digits (Dead Center on Cluster)
            Text {
                id: speedText
                anchors.centerIn: parent
                text: Math.round(centralSpeed.speedValue).toString()
                font.pixelSize: 105
                font.weight: Font.Normal
                font.letterSpacing: -1.0
                font.family: "Menlo, Monaco, monospace"
                color: "#FFFFFF"
                renderType: Text.NativeRendering
            }
        }

        // Unit: km/h
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "km/h"
            font.pixelSize: 16
            font.weight: Font.Normal
            font.letterSpacing: 1.5
            font.family: "sans-serif"
            color: "#94A3B8"
            renderType: Text.NativeRendering
        }
    }

    Behavior on speedValue {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
}
