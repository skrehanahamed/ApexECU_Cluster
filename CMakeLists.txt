cmake_minimum_required(VERSION 3.20)

project(ApexECU_Cluster LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Gui Core)

qt_standard_project_setup(REQUIRES 6.5)

qt_policy(SET QTP0004 NEW)

qt_add_executable(ApexCluster
    src/main.cpp
    src/ClusterAudio.h
)

set_target_properties(ApexCluster PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "APEX SUV Cluster"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.apex.cluster"
)

qt_add_qml_module(ApexCluster
    URI ApexCluster
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/views/WelcomeScreen.qml
        qml/views/DrivingCluster.qml
        qml/views/AdasRoadView.qml
        qml/views/StarfieldSky.qml
        qml/gauges/PowerGauge.qml
        qml/gauges/BatteryTempGauge.qml
        qml/center/CentralSpeed.qml
        qml/center/EcuEmulatorPanel.qml
        qml/bars/TelltaleBar.qml
        qml/bars/TopStatusBar.qml
        qml/bars/BottomInfoBar.qml
    RESOURCES
        assets/wallpapers/cluster_mountain_horizon.jpg
        assets/wallpapers/cluster_city_night.jpg
        assets/wallpapers/cluster_coastal_sunset.jpg
        assets/modes/mode_card_eco.png
        assets/modes/mode_card_comfort.png
        assets/modes/mode_card_sport.png
        assets/modes/mode_card_offroad.png
        assets/warnings/warning_seatbelt.png
        assets/warnings/warning_park_brake.png
        assets/warnings/warning_door_open.png
        assets/warnings/warning_tpms.png
        assets/warnings/warning_low_battery.png
        assets/warnings/warning_washer_fluid.png
        assets/warnings/warning_check_vehicle.png
        assets/warnings/warning_traction_off.png
        assets/warnings/warning_lka_unavailable.png
        assets/warnings/warning_airbag.png
        assets/warnings/warning_park_assist_blocked.png
        assets/warnings/warning_hands_on_wheel.png
        assets/warnings/warning_battery_overheat.png
        assets/warnings/warning_charging_port_open.png
        assets/warnings/warning_hill_descent.png
        assets/warnings/warning_ready_to_drive.png
        assets/warnings/warning_forward_collision.png
        assets/warnings/warning_low_traction.png
        assets/warnings/warning_steering_assist.png
        assets/warnings/warning_speed_80.png
        assets/warnings/warning_speed_120.png
        assets/vehicles/car_silhouette.png
        assets/vehicles/apex_suv_adas_model.png
        assets/vehicles/obstruction_car_lead.png
        assets/vehicles/obstruction_sedan.png
        assets/vehicles/obstruction_hatchback.png
        assets/vehicles/obstruction_pedestrian.png
        assets/vehicles/obstruction_bicycle.png
        assets/vehicles/obstruction_motorcycle.png
        assets/branding/apex_wordmark.png
        assets/branding/apex_logo_tight.png
        assets/telltales/seatbelt_active.svg
        assets/telltales/seatbelt_inactive.svg
        assets/telltales/airbag_active.svg
        assets/telltales/airbag_inactive.svg
        assets/telltales/traction_active.svg
        assets/telltales/traction_inactive.svg
        assets/telltales/park_brake_active.svg
        assets/telltales/park_brake_inactive.svg
        assets/telltales/abs_active.svg
        assets/telltales/abs_inactive.svg
        assets/telltales/check_engine_active.svg
        assets/telltales/check_engine_inactive.svg
        assets/telltales/battery_12v_active.svg
        assets/telltales/battery_12v_inactive.svg
        assets/telltales/tpms_active.svg
        assets/telltales/tpms_inactive.svg
        assets/telltales/ev_plug_active.svg
        assets/telltales/ev_plug_inactive.svg
        assets/telltales/auto_high_beam_active.svg
        assets/telltales/auto_high_beam_inactive.svg
        assets/telltales/low_beam_active.svg
        assets/telltales/low_beam_inactive.svg
        assets/telltales/high_beam_active.svg
        assets/telltales/high_beam_inactive.svg
        assets/telltales/fog_lamp_active.svg
        assets/telltales/fog_lamp_inactive.svg
        assets/telltales/battery_temp_active.svg
        assets/telltales/battery_temp_inactive.svg
        assets/telltales/master_warning_active.svg
        assets/telltales/master_warning_inactive.svg
        assets/telltales/door_open_active.svg
        assets/telltales/door_open_inactive.svg
        assets/telltales/freeze_warning.svg
)

target_link_libraries(ApexCluster
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS ApexCluster
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
