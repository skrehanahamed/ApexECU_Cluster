# APEX SUV — Next-Gen EV Digital Instrument Cluster & ECU Simulator

[![Qt 6.11](https://img.shields.io/badge/Qt-6.11+-41CD52.svg?logo=qt&logoColor=white)](https://www.qt.io/)
[![C++20](https://img.shields.io/badge/C++-20-00599C.svg?logo=cplusplus&logoColor=white)](https://isocpp.org/)
[![CMake](https://img.shields.io/badge/CMake-3.20+-064F8C.svg?logo=cmake&logoColor=white)](https://cmake.org/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](https://github.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A high-fidelity, luxury **Automotive Digital Instrument Cluster** and interactive **ECU Telemetry Simulator** built with **Qt 6 (QML / Qt Quick)** and **Modern C++**. Features a live perspective 3-lane Highway Driver Assist (ADAS) highway view, authentic high-performance electric vehicle audio soundscape, dynamic multi-environment scenery backgrounds, and a full 21-card OEM automotive warning system.

---

## Preview & Media Showcase

### Application Demo Video


https://github.com/user-attachments/assets/64170b31-a5b3-4ab9-87de-2bc2024274be



### User Interface Screenshots

| Digital Instrument Cluster | Dual-Window ECU Simulator |
|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/dcce0c7c-6ab5-4de0-836a-6457eeafa08a" width="100%" alt="APEX Digital Instrument Cluster" /> | <img src="https://github.com/user-attachments/assets/c876664f-8a61-4271-b163-61c7874a2c2a" width="100%" alt="ECU Telemetry Simulator" /> |

| Driver Assist (ADAS) 3D Highway View | 21-Card OEM Warning System |
|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/c52de7f4-bf2d-482d-9084-630b2226b2c2" width="100%" alt="Driver Assist 3D Highway View" /> | <img src="https://github.com/user-attachments/assets/d80348f8-a05c-4f26-a82c-440ffebcd8a9" width="100%" alt="21-Card OEM Warning System" /> |

---

## Key Features

### 1. Cinematic Bootup & Acoustic Engine
* **Pure Acoustic Crystal Chime**: Luxury E-Major 9th crystal chime with sub-bass frequency sweep on vehicle wake-up.
* **Electric Performance SUV Motor Soundscape**: High-voltage dual-inverter pre-charge, dual-motor stator torque surge (150 Hz to 1,850 Hz), 12-pole magnetic harmonics, and regenerative deceleration to idle power hum.
* **OEM Gauge Needle Sweeps**: Synchronized startup sweep of Power (0 to 300 kW), Speedometer (0 to 188 km/h), and Battery Temperature (0 to 85°C).
* **Full Spacebar Reboot**: Pressing `Space` at any time instantly reboots the entire system with zero-state resets.

### 2. 3-Lane Highway Driver Assist (ADAS) System
* **Perspective 3D Road Rendering**: Real-time curved road canvas with scrolling dashed lane dividers and lateral ego-vehicle sway.
* **Lead Vehicle Radar & Following Distance**: Real-time target tracking (10m–80m) with HUD distance meter and dynamic obstacle support (Sports Car, Sedan, Hatchback, Motorcycle, Bicycle, Pedestrian).
* **Multi-Lane Traffic Simulation**: Natural left-lane and right-lane overtaking pass-by vehicles with proximity collision detection.
* **Driver Assist Master Toggle**: When disabled, all traffic obstacles and distance HUDs are hidden, and collision warnings are suppressed. Top status shows `DRIVER ASSIST OFF`.
* **Forward Collision Warning**: Triggers persistent visual alert and repeating critical audio alert when lead obstacle is less than 13 meters.

### 3. Complete 21-Card OEM Automotive Warning System
* **Official APEX Warning Cards**: 21 cards covering Brake System, ABS, Motor Overtemp, Battery Fault, High Speed, Low Voltage, Tire Pressure, ADAS Lane Departure, and more.
* **Speed Warning Alerts**:
  * Above 80 km/h: Single warning chime + 2.5s popup card.
  * Above 120 km/h: Persistent dangerous speed card + repeating 2-second chime until speed drops to 120 km/h or below.
* **Ambient Freezing Warning**: White vector snowflake icon automatically illuminates before the temperature readout when ambient temperature drops below 3°C (e.g. `2°C`, `-4°C`).

### 4. Dual-Window ECU Simulator Window
* **Speed, Power & Battery Controls**: Interactive sliders for vehicle speed (0–240 km/h), power output (-50 kW regen to 300 kW boost), battery charge (0–100%), and ambient temperature (-10°C to 45°C).
* **Gear Selector**: P (Park), R (Reverse with parking guidelines), N (Neutral), D (Drive).
* **Drive Modes**: `COMFORT` (Cyan), `SPORT` (Crimson Red), `ECO` (Emerald Green), `OFF-ROAD` (Amber Gold).
* **Scenery Backgrounds**: Mountain Horizon, Cyberpunk City Night, Coastal Sunset.

---

## System Architecture

```mermaid
flowchart TB
    subgraph CoreEngine["C++ Core Engine & Platform Layer"]
        MainCPP["main.cpp<br/>(QGuiApplication & QQmlApplicationEngine)"]
        AudioEngine["ClusterAudio.h<br/>(Asynchronous Audio Engine)"]
    end

    subgraph ECUController["ECU Telemetry & Simulator Window"]
        EcuPanel["EcuEmulatorPanel.qml<br/>• Speed & Power Telemetry<br/>• Gear & Drive Mode Select<br/>• Driver Assist (ADAS) Controls<br/>• 21-Card Warning Injector<br/>• Ambient Temperature Slider"]
    end

    subgraph MasterQML["Main Cluster Presentation Layer (Main.qml)"]
        Welcome["WelcomeScreen.qml<br/>• Vehicle Silhouette<br/>• APEX Wordmark Illuminator<br/>• Startup Chime Trigger"]
        ClusterView["DrivingCluster.qml<br/>(Master State Machine)"]
    end

    subgraph ClusterComponents["Digital Cluster Components"]
        TopBar["TopStatusBar.qml<br/>• Clock & Drive Mode<br/>• Driver Assist (ON/OFF)<br/>• Ambient Temp & Freeze Icon"]
        CenterSpeed["CentralSpeed.qml<br/>• Dead-Centered Speed<br/>• Side Speed Limit Sign<br/>• APEX Emblem"]
        Road3D["AdasRoadView.qml<br/>• Perspective 3D Road<br/>• Radar Target Tracking<br/>• Pass-By Traffic Sim<br/>• Collision Distance Meter"]
        PowerGauge["PowerGauge.qml<br/>• 0-300 kW Power<br/>• Regenerative Arc"]
        TempGauge["BatteryTempGauge.qml<br/>• Pack Thermal Health<br/>• Trip Computer"]
        Telltales["TelltaleBar.qml<br/>• 21 ISO Telltales<br/>• Bulb-Check Self-Test"]
        BottomBar["BottomInfoBar.qml<br/>• Battery SOC & Range<br/>• Gear PRND Selector<br/>• Horizon Line Divider"]
    end

    subgraph AssetDeck["Asset & Media Deck"]
        AudioWav["assets/audio/<br/>• Crystal Chime<br/>• Electric SUV Rev<br/>• Critical / Warning Beeps"]
        WarningCards["assets/warnings/<br/>• 21 APEX Alert Cards"]
        VectorSVG["assets/telltales/<br/>• 34 ISO SVG Telltales<br/>• Freeze Snowflake Icon"]
        Vehicles["assets/vehicles/<br/>• SUV Model & Traffic"]
        Wallpapers["assets/wallpapers/<br/>• 3 Scenic Environments"]
    end

    MainCPP -->|Injects Context Property| AudioEngine
    MainCPP -->|Loads QML Trees| MasterQML
    MainCPP -->|Spawns Secondary Window| ECUController

    EcuPanel <-->|Bi-directional Telemetry Binding| ClusterView

    MasterQML -->|Coordinates State| Welcome
    MasterQML -->|Bootup Transition| ClusterView

    ClusterView --> TopBar
    ClusterView --> CenterSpeed
    ClusterView --> Road3D
    ClusterView --> PowerGauge
    ClusterView --> TempGauge
    ClusterView --> Telltales
    ClusterView --> BottomBar

    AudioEngine -.-> AudioWav
    ClusterView -.-> WarningCards
    Telltales -.-> VectorSVG
    Road3D -.-> Vehicles
    ClusterView -.-> Wallpapers
```

---

## Bootup & Spacebar Reboot Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Driver as User / Driver
    participant Main as Main.qml
    participant Audio as ClusterAudio
    participant Welcome as WelcomeScreen
    participant Cluster as DrivingCluster
    participant Gauges as Gauges & Telltales
    participant ADAS as Driver Assist (ADAS)

    Driver->>Main: Press [Space] or Launch App
    Main->>Main: Full Zero-State Reset
    Main->>Audio: playStartupChime() (Crystal Bell Signature)
    Main->>Welcome: restartSequence() (Vehicle Silhouette -> APEX Wordmark -> Ready)
    
    Note over Main,Welcome: 3.5s Welcome Duration (or instant skip on Enter/Click)

    Main->>Cluster: clusterTransitionAnim (Fade in Cluster UI)
    Main->>Audio: playEngineRev() (Electric Performance SUV Surge)
    Cluster->>Gauges: startupSelfTestAnim (Power 300kW, Speed 188km/h, Temp 85°C Sweep)
    Cluster->>Gauges: Bulb Check (All 21 Telltales ON)
    
    Note over Gauges: Gauges peak-hold and smoothly sweep back to 0
    
    Cluster->>Gauges: Bulb Check Complete (Telltales OFF, Park Brake ON)
    Cluster->>ADAS: Road View & Multi-Environment Scenery gracefully fade in (opacity -> 1.0)
    Cluster->>Cluster: Speed Limit Badge (80) pops into view on side
    Note over ADAS,Cluster: System Ready & Driver Assist Active
```

---

## Keyboard Shortcuts

| Key | Action |
|:---|:---|
| <kbd>Space</kbd> | **Full System Reboot** (Replays Welcome sequence, chimes & sweeps) |
| <kbd>Return</kbd> / <kbd>Enter</kbd> / <kbd>C</kbd> | **Fast-forward** from Welcome Screen directly to Cluster |
| <kbd>D</kbd> | Cycle **Drive Mode** (COMFORT -> SPORT -> ECO -> OFF-ROAD) |
| <kbd>E</kbd> / <kbd>Tab</kbd> | Open / Close **ECU Emulator Panel** |
| <kbd>T</kbd> | Cycle Bulb Check / All Telltale Warning Lights |
| <kbd>Left</kbd> / <kbd>Right</kbd> | Toggle **Left / Right Turn Signal** |

---

## Repository Structure

```
ApexECU_Cluster/
├── CMakeLists.txt              # CMake build configuration with Qt 6 integration
├── Makefile                    # Portable developer convenience commands
├── .gitignore                  # Production Git ignore rules
├── README.md                   # Project documentation
│
├── src/                        # C++ Backend
│   ├── main.cpp                # Application entrypoint & QML engine setup
│   └── ClusterAudio.h          # Non-blocking audio playback engine
│
├── qml/                        # QML / Qt Quick Frontend
│   ├── Main.qml                # Master root container & boot transitions
│   ├── bars/                   # Status & Telltale Bars
│   │   ├── TopStatusBar.qml    # Time, Drive Mode, Driver Assist status & Freeze temp
│   │   ├── BottomInfoBar.qml   # Battery, Range, Gear & Trip telemetry
│   │   └── TelltaleBar.qml     # 21 ISO standard automotive telltales
│   ├── center/                 # Central Gauge Readouts
│   │   ├── CentralSpeed.qml    # Dead-centered speed & side-floating speed limit sign
│   │   └── EcuEmulatorPanel.qml# Dual-window real-time ECU Telemetry Controller
│   ├── gauges/                 # Circular & Arc Gauges
│   │   ├── PowerGauge.qml      # 0-300 kW power / regenerative braking arc
│   │   └── BatteryTempGauge.qml# Battery pack thermal health gauge
│   └── views/                  # Master Viewports
│       ├── WelcomeScreen.qml   # Luxury vehicle silhouette & emblem wake-up
│       ├── DrivingCluster.qml  # Main driving cluster UI & self-test coordinator
│       ├── AdasRoadView.qml    # 3-Lane perspective Driver Assist highway engine
│       └── StarfieldSky.qml    # Ambient celestial background layer
│
└── assets/                     # Organized Asset Tree
    ├── audio/                  # Startup chimes, electric motor sounds & alerts
    ├── branding/               # APEX wordmarks and vehicle emblems
    ├── modes/                  # Drive mode character cards
    ├── telltales/              # 34 ISO telltale SVGs & freeze warning icon
    ├── vehicles/               # APEX SUV top-down models & traffic obstructions
    ├── wallpapers/             # High-resolution scenic environment backgrounds
    └── warnings/               # 21 APEX warning banner cards
```

---

## Build & Run Instructions

### Prerequisites
* **Qt 6.5+** (tested on Qt 6.11) with `QtQuick`, `QtQuick.Controls`
* **CMake 3.20+**
* **C++20** compatible compiler (Clang / GCC / MSVC)
* **Ninja** build system (recommended)

### Quick Start (using Makefile)
```bash
# Clone the repository
git clone https://github.com/skrehanahamed/ApexECU_Cluster.git
cd ApexECU_Cluster

# Build the project
make build

# Launch the Application (Opens Cluster + ECU Emulator)
make run
```

### Manual CMake Build
```bash
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x.x/macos -GNinja
cmake --build .
./ApexCluster
```

---

## Author & Acknowledgments

* **SK Rehan Ahamed** — [@skrehanahamed](https://github.com/skrehanahamed)

### AI Collaborators & Engineering Credits
Created by **SK Rehan Ahamed** in creative collaboration with **Antigravity**, **Gemini**, and **ChatGPT**.

---

## License
Distributed under the MIT License. See `LICENSE` for more information.

<br/>

<p align="center">
  <sub>Crafted with modern C++ and Qt 6 Quick for automotive digital instrument cluster systems.</sub>
</p>
