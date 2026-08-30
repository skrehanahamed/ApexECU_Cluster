import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../bars"

Item {
    id: chargingScreen
    anchors.fill: parent

    // Telemetry properties from Cluster/ECU
    property bool isCharging: true
    property real batteryPercent: 68.0
    property real chargingRateKw: 72.0
    property real rangeKm: Math.round(batteryPercent * 5.95)
    property int ambientTemp: 24
    property int elevationM: 1250
    property string compassHeading: "SW"
    property string currentGear: "P"
    property int chargeLimitPercent: 90
    property string driveMode: "COMFORT"
    property string themeColor: "#00e5ff"

    // Dynamic calculated values
    readonly property int minutesRemaining: (batteryPercent >= chargeLimitPercent) ? 0 :
        Math.max(1, Math.round(((chargeLimitPercent - batteryPercent) * 0.85) / (Math.max(10, chargingRateKw) / 72.0)))
    readonly property real energyAddedKwh: Math.max(0, Math.round((batteryPercent * 0.28) * 10) / 10)

    // ═══════════════════════════════════════════════════════════════
    // FULL-SCREEN CINEMATIC CHARGING SCENERY (Mountains, Night Sky, SUV & Station)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: "#030712"

        Image {
            id: scenicChargingBg
            anchors.fill: parent
            source: "../../assets/wallpapers/cluster_charging_backdrop.png"
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }

        // Top and Bottom Ambient Vignette for Status Bar Readability
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.01, 0.03, 0.07, 0.80) }
                GradientStop { position: 0.22; color: Qt.rgba(0.01, 0.03, 0.07, 0.20) }
                GradientStop { position: 0.70; color: "transparent" }
                GradientStop { position: 0.88; color: Qt.rgba(0.0, 0.02, 0.05, 0.50) }
                GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.01, 0.04, 0.95) }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 1. UPPER SECTION: TELLTALE BAR ON TOP, STATUS BAR BELOW
    // ═══════════════════════════════════════════════════════════════
    TelltaleBar {
        id: topTelltales
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        z: 20
    }

    TopStatusBar {
        id: topStatusBar
        anchors.top: topTelltales.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        driveMode: "CHARGING"
        temperature: chargingScreen.ambientTemp
        themeColor: "#22C55E"
        adasActive: (chargingScreen.batteryPercent >= 100)
        z: 20
    }

    // ═══════════════════════════════════════════════════════════════
    // 2. LEFT FLOATING CARD: CHARGING POWER, TIME REMAINING, ENERGY
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: leftMetricCard
        anchors.left: parent.left
        anchors.leftMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 12
        width: 220
        height: 250
        radius: 16
        color: Qt.rgba(0.03, 0.06, 0.12, 0.65)
        border.color: Qt.rgba(0.18, 0.28, 0.40, 0.40)
        border.width: 1.0
        z: 10

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            // Section 1: Charging Power
            Column {
                spacing: 3
                Text {
                    text: "CHARGING POWER"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    font.family: "Inter"
                    color: "#94A3B8"
                }
                Row {
                    spacing: 8
                    Image {
                        source: "../../assets/telltales/charge_power_bolt.svg"
                        width: 18
                        height: 18
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Math.round(chargingScreen.chargingRateKw)
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.family: "Inter"
                        color: "#22C55E"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "kW"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: "Inter"
                        color: "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Section 2: Time Remaining
            Column {
                spacing: 3
                Text {
                    text: "TIME REMAINING"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    font.family: "Inter"
                    color: "#94A3B8"
                }
                Row {
                    spacing: 6
                    Text {
                        text: (chargingScreen.batteryPercent >= 100) ? "0" : chargingScreen.minutesRemaining
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.family: "Inter"
                        color: "#22C55E"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "min"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: "Inter"
                        color: "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Section 3: Energy Added
            Column {
                spacing: 3
                Text {
                    text: "ENERGY ADDED"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    font.family: "Inter"
                    color: "#94A3B8"
                }
                Row {
                    spacing: 6
                    Text {
                        text: chargingScreen.energyAddedKwh
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.family: "Inter"
                        color: "#22C55E"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "kWh"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: "Inter"
                        color: "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 3. CENTER LOWER: 68% + LARGE BATTERY PROGRESS BAR + LIMIT
    // ═══════════════════════════════════════════════════════════════
    Column {
        id: centerBatteryBarBlock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: 14
        spacing: 6
        z: 12

        // Large 68 % Text
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Text {
                text: Math.round(chargingScreen.batteryPercent)
                font.pixelSize: 34
                font.weight: Font.Bold
                font.family: "Inter"
                color: "#22C55E"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "%"
                font.pixelSize: 20
                font.weight: Font.DemiBold
                font.family: "Inter"
                color: "#22C55E"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Large Pill Progress Bar
        Rectangle {
            id: progressBarTrack
            width: 380
            height: 20
            radius: 10
            color: "#111827"
            border.color: Qt.rgba(0.2, 0.3, 0.4, 0.3)
            border.width: 1

            Rectangle {
                id: progressBarFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(parent.height, parent.width * (Math.min(100.0, chargingScreen.batteryPercent) / 100.0))
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#22C55E" }
                    GradientStop { position: 1.0; color: "#10B981" }
                }

                Behavior on width {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 4. RIGHT FLOATING CARD: CHARGE STATUS (Checks & Health)
    // ═══════════════════════════════════════════════════════════════
    Rectangle {
        id: rightStatusCard
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 12
        width: 220
        height: 250
        radius: 16
        color: Qt.rgba(0.03, 0.06, 0.12, 0.65)
        border.color: Qt.rgba(0.18, 0.28, 0.40, 0.40)
        border.width: 1.0
        z: 10

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            Text {
                text: "CHARGE STATUS"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                font.family: "Inter"
                color: "#94A3B8"
            }

            // Item 1: ⚡ Charging
            Row {
                spacing: 10
                Image {
                    source: "../../assets/telltales/status_charging_active.svg"
                    width: 22
                    height: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: (chargingScreen.batteryPercent >= 100) ? "Fully Charged" : "Charging Active"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: "Inter"
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Item 2: 🔌 Power Connected
            Row {
                spacing: 10
                Image {
                    source: "../../assets/telltales/status_power_connected.svg"
                    width: 22
                    height: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Power Connected"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: "Inter"
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Item 3: 🛡️ Battery Safe
            Row {
                spacing: 10
                Image {
                    source: "../../assets/telltales/status_battery_safe.svg"
                    width: 22
                    height: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Battery Safe"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: "Inter"
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Item 4: ✓ No Faults Detected
            Row {
                spacing: 10
                Image {
                    source: "../../assets/telltales/status_fault_free.svg"
                    width: 22
                    height: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "No Faults Detected"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: "Inter"
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // 5. LOWER SECTION: EXACT CLUSTER BOTTOM INFO BAR
    // ═══════════════════════════════════════════════════════════════
    BottomInfoBar {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 8
        batteryPercent: chargingScreen.batteryPercent
        rangeKm: chargingScreen.rangeKm
        gear: "P"
        altitudeM: chargingScreen.elevationM
        heading: chargingScreen.compassHeading
        themeColor: "#22C55E"
        driveMode: "CHARGE MODE"
        z: 20
    }
}
