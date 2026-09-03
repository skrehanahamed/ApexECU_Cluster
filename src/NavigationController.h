#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <vector>

struct RouteStep {
    double lat{0.0};
    double lon{0.0};
    QString street;
    QString maneuver;
    double distance{0.0};
    double speedKmh{50.0};
};

struct RoutePoint {
    double lat{0.0};
    double lon{0.0};
    int stepIndex{0};
    QString street;
    QString maneuver;
    QString nextStreet;
    double targetSpeed{50.0};
    double bearing{0.0};
    double distToTurn{0.0};
};

class NavigationController : public QObject {
    Q_OBJECT

    // Core Navigation HUD Telemetry Properties
    Q_PROPERTY(bool navActive READ navActive WRITE setNavActive NOTIFY navActiveChanged)
    Q_PROPERTY(QString navState READ navState WRITE setNavState NOTIFY navStateChanged)
    Q_PROPERTY(QString navManeuver READ navManeuver NOTIFY navManeuverChanged)
    Q_PROPERTY(QString navDistance READ navDistance NOTIFY navDistanceChanged)
    Q_PROPERTY(QString navStreet READ navStreet NOTIFY navStreetChanged)
    Q_PROPERTY(QString navDuration READ navDuration NOTIFY navDurationChanged)
    Q_PROPERTY(QString navRemainingKm READ navRemainingKm NOTIFY navRemainingKmChanged)
    Q_PROPERTY(QString navEta READ navEta NOTIFY navEtaChanged)
    Q_PROPERTY(QString compassHeading READ compassHeading NOTIFY compassHeadingChanged)
    Q_PROPERTY(bool gpsLost READ gpsLost WRITE setGpsLost NOTIFY gpsLostChanged)

    // Map & Vehicle Telemetry Properties
    Q_PROPERTY(double vehicleLat READ vehicleLat NOTIFY vehiclePositionChanged)
    Q_PROPERTY(double vehicleLon READ vehicleLon NOTIFY vehiclePositionChanged)
    Q_PROPERTY(double vehicleBearing READ vehicleBearing NOTIFY vehicleBearingChanged)
    Q_PROPERTY(double currentSimSpeed READ currentSimSpeed NOTIFY currentSimSpeedChanged)
    Q_PROPERTY(double travelProgress READ travelProgress WRITE setTravelProgress NOTIFY travelProgressChanged)
    Q_PROPERTY(bool isAutoDriving READ isAutoDriving WRITE setIsAutoDriving NOTIFY isAutoDrivingChanged)
    Q_PROPERTY(double speedMultiplier READ speedMultiplier WRITE setSpeedMultiplier NOTIFY speedMultiplierChanged)
    Q_PROPERTY(bool isCalculatingRoute READ isCalculatingRoute NOTIFY isCalculatingRouteChanged)
    Q_PROPERTY(QString routeStatusMessage READ routeStatusMessage NOTIFY routeStatusMessageChanged)
    Q_PROPERTY(bool isEvReady READ isEvReady WRITE setIsEvReady NOTIFY isEvReadyChanged)

    // Origin & Destination Coordinates
    Q_PROPERTY(double startLat READ startLat WRITE setStartLat NOTIFY routePointsChanged)
    Q_PROPERTY(double startLon READ startLon WRITE setStartLon NOTIFY routePointsChanged)
    Q_PROPERTY(QString startName READ startName WRITE setStartName NOTIFY routePointsChanged)

    Q_PROPERTY(double destLat READ destLat WRITE setDestLat NOTIFY routePointsChanged)
    Q_PROPERTY(double destLon READ destLon WRITE setDestLon NOTIFY routePointsChanged)
    Q_PROPERTY(QString destName READ destName WRITE setDestName NOTIFY routePointsChanged)

    // Center Coordinate & Zoom for Map Viewport
    Q_PROPERTY(double centerLat READ centerLat WRITE setCenterLat NOTIFY centerChanged)
    Q_PROPERTY(double centerLon READ centerLon WRITE setCenterLon NOTIFY centerChanged)
    Q_PROPERTY(int zoomLevel READ zoomLevel WRITE setZoomLevel NOTIFY zoomLevelChanged)

    // Exported Route Polyline for Canvas Renderer
    Q_PROPERTY(QVariantList routePolyline READ routePolyline NOTIFY routePolylineChanged)

public:
    explicit NavigationController(QObject *parent = nullptr);
    ~NavigationController() override = default;

    // Property Getters
    bool navActive() const { return m_navActive; }
    QString navState() const { return m_navState; }
    QString navManeuver() const { return m_navManeuver; }
    QString navDistance() const { return m_navDistance; }
    QString navStreet() const { return m_navStreet; }
    QString navDuration() const { return m_navDuration; }
    QString navRemainingKm() const { return m_navRemainingKm; }
    QString navEta() const { return m_navEta; }
    QString compassHeading() const { return m_compassHeading; }
    bool gpsLost() const { return m_gpsLost; }

    double vehicleLat() const { return m_vehicleLat; }
    double vehicleLon() const { return m_vehicleLon; }
    double vehicleBearing() const { return m_vehicleBearing; }
    double currentSimSpeed() const { return m_currentSimSpeed; }
    double travelProgress() const { return m_travelProgress; }
    bool isAutoDriving() const { return m_isAutoDriving; }
    double speedMultiplier() const { return m_speedMultiplier; }
    bool isCalculatingRoute() const { return m_isCalculatingRoute; }
    QString routeStatusMessage() const { return m_routeStatusMessage; }
    bool isEvReady() const { return m_isEvReady; }

    double startLat() const { return m_startLat; }
    double startLon() const { return m_startLon; }
    QString startName() const { return m_startName; }

    double destLat() const { return m_destLat; }
    double destLon() const { return m_destLon; }
    QString destName() const { return m_destName; }

    double centerLat() const { return m_centerLat; }
    double centerLon() const { return m_centerLon; }
    int zoomLevel() const { return m_zoomLevel; }

    QVariantList routePolyline() const { return m_routePolyline; }

public slots:
    // Property Setters (Exposed as callable slots to QML)
    void setNavActive(bool active);
    void setNavState(const QString &state);
    void setGpsLost(bool lost);
    void setTravelProgress(double progress);
    void setIsAutoDriving(bool driving);
    void setSpeedMultiplier(double mult);
    void setIsEvReady(bool ready);
    void setStartLat(double lat);
    void setStartLon(double lon);
    void setStartName(const QString &name);
    void setDestLat(double lat);
    void setDestLon(double lon);
    void setDestName(const QString &name);
    void setCenterLat(double lat);
    void setCenterLon(double lon);
    void setZoomLevel(int zoom);

    // QML Invokable Methods
    void loadPreset(const QString &presetKey);
    void calculateRoute();
    void swapStartDest();
    void toggleAutoDrive();
    void resetTravel();
    void centerOnVehicle();
    void fitRouteInView();
    void setPinLocation(const QString &mode, double lat, double lon);
    void panDirection(const QString &dir); // "UP", "DOWN", "LEFT", "RIGHT"
    void manualDrive(double throttleDelta); // accelerate/decelerate or advance progress

signals:
    void navActiveChanged();
    void navStateChanged();
    void navManeuverChanged();
    void navDistanceChanged();
    void navStreetChanged();
    void navDurationChanged();
    void navRemainingKmChanged();
    void navEtaChanged();
    void compassHeadingChanged();
    void gpsLostChanged();

    void vehiclePositionChanged();
    void vehicleBearingChanged();
    void currentSimSpeedChanged();
    void travelProgressChanged();
    void isAutoDrivingChanged();
    void speedMultiplierChanged();
    void isCalculatingRouteChanged();
    void routeStatusMessageChanged();
    void isEvReadyChanged();
    void routePointsChanged();
    void centerChanged();
    void zoomLevelChanged();
    void routePolylineChanged();

    void destinationReached();

private slots:
    void onSimulationTick();
    void onOsrmReplyFinished(QNetworkReply *reply);

private:
    void buildInterpolatedRoute(const std::vector<RouteStep> &steps);
    void createProceduralRoute(double startLat, double startLon, double destLat, double destLon);
    void updateTelemetry(double progress);

    static double toRad(double deg);
    static double toDeg(double rad);
    static double computeDistanceM(double lat1, double lon1, double lat2, double lon2);
    static double computeBearingDeg(double lat1, double lon1, double lat2, double lon2);
    static QString bearingToCompass(double bearingDeg);
    static QString formatEtaTime(int minutesRemaining);

    // State Variables
    bool m_navActive{true};
    QString m_navState{"GUIDING"};
    QString m_navManeuver{"straight"};
    QString m_navDistance{"650 m"};
    QString m_navStreet{"Mahatma Gandhi Road"};
    QString m_navDuration{"14 min"};
    QString m_navRemainingKm{"8.4 km"};
    QString m_navEta{"10:45 AM"};
    QString m_compassHeading{"E"};
    bool m_gpsLost{false};
    bool m_isEvReady{true};

    double m_vehicleLat{12.9756};
    double m_vehicleLon{77.6094};
    double m_vehicleBearing{90.0};
    double m_currentSimSpeed{0.0};
    double m_travelProgress{0.0};
    bool m_isAutoDriving{false};
    double m_speedMultiplier{1.0};
    bool m_isCalculatingRoute{false};
    QString m_routeStatusMessage{"Route Ready"};

    double m_startLat{12.9756};
    double m_startLon{77.6094};
    QString m_startName{"MG Road Metro"};

    double m_destLat{12.9352};
    double m_destLon{77.6946};
    QString m_destName{"Outer Ring Rd Tech Park"};

    double m_centerLat{12.9554};
    double m_centerLon{77.6520};
    int m_zoomLevel{13};

    double m_totalDistanceM{8400.0};
    std::vector<RoutePoint> m_points;
    QVariantList m_routePolyline;

    QTimer m_simTimer;
    QNetworkAccessManager m_networkManager;
};
