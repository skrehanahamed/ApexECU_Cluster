import QtQuick
import QtQuick.Controls

/****************************************************************************
** Component: StarfieldSky.qml
** Role: Ambient Twilight Star Twinkle & Subtle Shimmer Engine
** Features:
**   - Ambient twinkling stars across the upper sky (above mountain ridge)
**   - Varied star sizes (0.8px - 2.4px) with subtle cyan-ice white color hues
**   - Independent asynchronous twinkle phase cycles
**   - Occasional gentle slow shooting star shimmer
****************************************************************************/

Item {
    id: starfield
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: parent.height * 0.38
    clip: true

    // Continuous time driver for smooth twinkle phase calculation
    property real time: 0.0
    NumberAnimation on time {
        from: 0.0
        to: 1000.0
        duration: 500000
        loops: Animation.Infinite
        running: true
    }

    // Shooting star cycle timer
    Timer {
        id: shootingStarTimer
        interval: 12000
        repeat: true
        running: true
        onTriggered: {
            shootingStarAnim.restart()
        }
    }

    // Subtle occasional shooting star
    Item {
        id: shootingStar
        width: 60
        height: 2
        opacity: 0.0
        x: -100
        y: 35
        rotation: 18

        Rectangle {
            anchors.fill: parent
            radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.7; color: "#6600E5FF" }
                GradientStop { position: 1.0; color: "#FFFFFF" }
            }
        }

        SequentialAnimation {
            id: shootingStarAnim
            PropertyAction { target: shootingStar; property: "x"; value: starfield.width * 0.28 }
            PropertyAction { target: shootingStar; property: "y"; value: 24 }
            ParallelAnimation {
                NumberAnimation { target: shootingStar; property: "x"; to: starfield.width * 0.48; duration: 950; easing.type: Easing.OutQuad }
                NumberAnimation { target: shootingStar; property: "y"; to: 82; duration: 950; easing.type: Easing.OutQuad }
                SequentialAnimation {
                    NumberAnimation { target: shootingStar; property: "opacity"; from: 0.0; to: 0.75; duration: 250 }
                    PauseAnimation { duration: 350 }
                    NumberAnimation { target: shootingStar; property: "opacity"; from: 0.75; to: 0.0; duration: 350 }
                }
            }
        }
    }

    // Starfield Canvas for high-performance twinkling dots
    Canvas {
        id: starCanvas
        anchors.fill: parent
        antialiasing: true

        // Static seed data for ~60 stars distributed across upper sky
        property var stars: [
            // Left Sky
            { x: 0.06, y: 0.18, r: 1.2, speed: 2.2, phase: 0.4,  color: "#FFFFFF" },
            { x: 0.11, y: 0.32, r: 1.8, speed: 1.7, phase: 1.2,  color: "#E0F2FE" },
            { x: 0.15, y: 0.12, r: 0.9, speed: 3.1, phase: 2.5,  color: "#BAE6FD" },
            { x: 0.18, y: 0.45, r: 1.4, speed: 1.9, phase: 0.8,  color: "#FFFFFF" },
            { x: 0.22, y: 0.25, r: 2.2, speed: 1.4, phase: 3.1,  color: "#7DD3FC" },
            { x: 0.26, y: 0.15, r: 1.1, speed: 2.8, phase: 4.0,  color: "#FFFFFF" },
            { x: 0.29, y: 0.52, r: 1.5, speed: 2.0, phase: 1.7,  color: "#E0F2FE" },

            // Center Sky (above speed / mountains)
            { x: 0.34, y: 0.22, r: 1.6, speed: 1.5, phase: 2.1,  color: "#FFFFFF" },
            { x: 0.37, y: 0.40, r: 0.9, speed: 3.4, phase: 0.9,  color: "#38BDF8" },
            { x: 0.41, y: 0.14, r: 2.0, speed: 1.2, phase: 4.8,  color: "#FFFFFF" },
            { x: 0.44, y: 0.30, r: 1.3, speed: 2.4, phase: 3.3,  color: "#BAE6FD" },
            { x: 0.48, y: 0.10, r: 1.7, speed: 1.8, phase: 1.5,  color: "#FFFFFF" },
            { x: 0.52, y: 0.28, r: 1.0, speed: 3.0, phase: 5.2,  color: "#E0F2FE" },
            { x: 0.55, y: 0.16, r: 2.4, speed: 1.1, phase: 2.7,  color: "#FFFFFF" },
            { x: 0.58, y: 0.38, r: 1.2, speed: 2.6, phase: 0.3,  color: "#7DD3FC" },
            { x: 0.62, y: 0.20, r: 1.5, speed: 1.6, phase: 4.1,  color: "#FFFFFF" },
            { x: 0.66, y: 0.48, r: 0.8, speed: 3.5, phase: 1.9,  color: "#BAE6FD" },

            // Right Sky
            { x: 0.71, y: 0.15, r: 1.9, speed: 1.3, phase: 3.6,  color: "#FFFFFF" },
            { x: 0.74, y: 0.35, r: 1.1, speed: 2.7, phase: 0.6,  color: "#E0F2FE" },
            { x: 0.78, y: 0.22, r: 2.1, speed: 1.5, phase: 2.3,  color: "#FFFFFF" },
            { x: 0.82, y: 0.50, r: 1.0, speed: 3.2, phase: 4.4,  color: "#38BDF8" },
            { x: 0.86, y: 0.18, r: 1.6, speed: 2.1, phase: 1.1,  color: "#FFFFFF" },
            { x: 0.89, y: 0.38, r: 1.3, speed: 1.9, phase: 3.8,  color: "#BAE6FD" },
            { x: 0.94, y: 0.24, r: 1.7, speed: 1.6, phase: 2.9,  color: "#FFFFFF" },

            // Faint background clusters
            { x: 0.08, y: 0.55, r: 0.7, speed: 2.9, phase: 5.0,  color: "#FFFFFF" },
            { x: 0.14, y: 0.62, r: 0.8, speed: 2.1, phase: 3.2,  color: "#BAE6FD" },
            { x: 0.25, y: 0.68, r: 0.6, speed: 3.7, phase: 1.4,  color: "#FFFFFF" },
            { x: 0.39, y: 0.58, r: 0.8, speed: 2.5, phase: 4.6,  color: "#E0F2FE" },
            { x: 0.46, y: 0.64, r: 0.7, speed: 3.1, phase: 2.0,  color: "#FFFFFF" },
            { x: 0.60, y: 0.60, r: 0.8, speed: 2.3, phase: 0.7,  color: "#BAE6FD" },
            { x: 0.75, y: 0.66, r: 0.6, speed: 3.6, phase: 4.2,  color: "#FFFFFF" },
            { x: 0.84, y: 0.58, r: 0.8, speed: 2.8, phase: 1.8,  color: "#E0F2FE" },
            { x: 0.92, y: 0.65, r: 0.7, speed: 3.3, phase: 3.5,  color: "#FFFFFF" }
        ]

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var w = width;
            var h = height;
            var tSec = starfield.time * 0.002;

            for (var i = 0; i < stars.length; i++) {
                var s = stars[i];
                var sx = s.x * w;
                var sy = s.y * h;

                // Smooth sinusoidal twinkle alpha
                var alpha = 0.25 + 0.65 * (0.5 + 0.5 * Math.sin(tSec * s.speed + s.phase));

                // Star core
                ctx.fillStyle = s.color;
                ctx.globalAlpha = alpha;
                ctx.beginPath();
                ctx.arc(sx, sy, s.r, 0, Math.PI * 2);
                ctx.fill();

                // Soft outer glow on larger stars
                if (s.r > 1.5 && alpha > 0.6) {
                    ctx.globalAlpha = (alpha - 0.5) * 0.5;
                    ctx.beginPath();
                    ctx.arc(sx, sy, s.r * 2.2, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
            ctx.globalAlpha = 1.0;
        }
    }

    // Refresh render loop at 30 fps
    Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: starCanvas.requestPaint()
    }
}
