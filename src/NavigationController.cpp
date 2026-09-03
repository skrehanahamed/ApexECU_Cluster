#include "NavigationController.h"
#include <cmath>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QUrl>
#include <QUrlQuery>
#include <algorithm>

constexpr double R_EARTH = 6371000.0;
constexpr double PI_VAL = 3.14159265358979323846;

NavigationController::NavigationController(QObject *parent)
    : QObject(parent)
{
    connect(&m_simTimer, &QTimer::timeout, this, &NavigationController::onSimulationTick);
    connect(&m_networkManager, &QNetworkAccessManager::finished, this, &NavigationController::onOsrmReplyFinished);

    // 33ms timer loop (~30 FPS vehicle travel clock)
    m_simTimer.setInterval(33);

    // Initialize with Bengaluru default route
    loadPreset("bangalore");
}

double NavigationController::toRad(double deg) {
    return deg * PI_VAL / 180.0;
}

double NavigationController::toDeg(double rad) {
    return rad * 180.0 / PI_VAL;
}

double NavigationController::computeDistanceM(double lat1, double lon1, double lat2, double lon2) {
    double phi1 = toRad(lat1);
    double phi2 = toRad(lat2);
    double deltaPhi = toRad(lat2 - lat1);
    double deltaLambda = toRad(lon2 - lon1);

    double a = std::sin(deltaPhi / 2.0) * std::sin(deltaPhi / 2.0) +
               std::cos(phi1) * std::cos(phi2) *
               std::sin(deltaLambda / 2.0) * std::sin(deltaLambda / 2.0);
    double c = 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));
    return R_EARTH * c;
}

double NavigationController::computeBearingDeg(double lat1, double lon1, double lat2, double lon2) {
    double phi1 = toRad(lat1);
    double phi2 = toRad(lat2);
    double deltaLambda = toRad(lon2 - lon1);

    double y = std::sin(deltaLambda) * std::cos(phi2);
    double x = std::cos(phi1) * std::sin(phi2) -
               std::sin(phi1) * std::cos(phi2) * std::cos(deltaLambda);
    double brng = toDeg(std::atan2(y, x));
    return std::fmod(brng + 360.0, 360.0);
}

QString NavigationController::bearingToCompass(double bearingDeg) {
    static const QStringList cardinals = {
        "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
        "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"
    };
    int index = static_cast<int>(std::round(bearingDeg / 22.5)) % 16;
    if (index < 0 || index >= cardinals.size()) return "N";
    return cardinals[index];
}

QString NavigationController::formatEtaTime(int minutesRemaining) {
    QDateTime current = QDateTime::currentDateTime();
    QDateTime eta = current.addSecs(minutesRemaining * 60);
    return eta.toString("hh:mm AP");
}

void NavigationController::setNavActive(bool active) {
    if (m_navActive != active) {
        m_navActive = active;
        emit navActiveChanged();
    }
}

void NavigationController::setNavState(const QString &state) {
    if (m_navState != state) {
        m_navState = state;
        emit navStateChanged();
    }
}

void NavigationController::setGpsLost(bool lost) {
    if (m_gpsLost != lost) {
        m_gpsLost = lost;
        emit gpsLostChanged();
        if (lost) {
            setNavState("GPS_LOST");
            m_currentSimSpeed = 0.0;
            emit currentSimSpeedChanged();
        } else {
            setNavState(m_travelProgress >= 0.99 ? "ARRIVED" : "GUIDING");
            updateTelemetry(m_travelProgress);
        }
    }
}

void NavigationController::setTravelProgress(double progress) {
    progress = std::clamp(progress, 0.0, 1.0);
    if (std::abs(m_travelProgress - progress) > 0.0001) {
        m_travelProgress = progress;
        emit travelProgressChanged();
        updateTelemetry(progress);
    }
}

void NavigationController::setIsEvReady(bool ready) {
    if (m_isEvReady != ready) {
        m_isEvReady = ready;
        emit isEvReadyChanged();
        if (!ready) {
            if (m_isAutoDriving) {
                setIsAutoDriving(false);
            }
            m_currentSimSpeed = 0.0;
            emit currentSimSpeedChanged();
        }
    }
}

void NavigationController::setIsAutoDriving(bool driving) {
    if (driving && !m_isEvReady) {
        return; // Auto-drive ONLY allowed when EV power state is READY
    }

    if (m_isAutoDriving != driving) {
        m_isAutoDriving = driving;
        emit isAutoDrivingChanged();
        if (driving) {
            if (m_travelProgress >= 0.99) {
                setTravelProgress(0.0);
            }
            m_simTimer.start();
        } else {
            m_simTimer.stop();
            m_currentSimSpeed = 0.0;
            emit currentSimSpeedChanged();
        }
    }
}

void NavigationController::setSpeedMultiplier(double mult) {
    if (mult > 0.0 && m_speedMultiplier != mult) {
        m_speedMultiplier = mult;
        emit speedMultiplierChanged();
    }
}

void NavigationController::setStartLat(double lat) {
    m_startLat = lat;
    emit routePointsChanged();
}

void NavigationController::setStartLon(double lon) {
    m_startLon = lon;
    emit routePointsChanged();
}

void NavigationController::setStartName(const QString &name) {
    m_startName = name;
    emit routePointsChanged();
}

void NavigationController::setDestLat(double lat) {
    m_destLat = lat;
    emit routePointsChanged();
}

void NavigationController::setDestLon(double lon) {
    m_destLon = lon;
    emit routePointsChanged();
}

void NavigationController::setDestName(const QString &name) {
    m_destName = name;
    emit routePointsChanged();
}

void NavigationController::setCenterLat(double lat) {
    if (m_centerLat != lat) {
        m_centerLat = lat;
        emit centerChanged();
    }
}

void NavigationController::setCenterLon(double lon) {
    if (m_centerLon != lon) {
        m_centerLon = lon;
        emit centerChanged();
    }
}

void NavigationController::setZoomLevel(int zoom) {
    zoom = std::clamp(zoom, 3, 18);
    if (m_zoomLevel != zoom) {
        m_zoomLevel = zoom;
        emit zoomLevelChanged();
    }
}

void NavigationController::panDirection(const QString &dir) {
    // Step pan in screen/geo coordinates based on zoom level
    double delta = 0.008 * std::pow(2.0, 14.0 - m_zoomLevel);
    if (dir == "UP" || dir == "NORTH") {
        setCenterLat(m_centerLat + delta);
    } else if (dir == "DOWN" || dir == "SOUTH") {
        setCenterLat(m_centerLat - delta);
    } else if (dir == "LEFT" || dir == "WEST") {
        setCenterLon(m_centerLon - delta);
    } else if (dir == "RIGHT" || dir == "EAST") {
        setCenterLon(m_centerLon + delta);
    }
}

void NavigationController::manualDrive(double throttleDelta) {
    if (!m_isEvReady) return; // Manual drive ONLY allowed in EV READY mode

    setIsAutoDriving(false);
    if (m_points.empty() || m_totalDistanceM <= 0.0) return;

    // Advance vehicle progress along the real road path
    double stepDistM = (throttleDelta >= 0 ? 30.0 : -30.0) * std::abs(throttleDelta);
    double deltaProg = stepDistM / m_totalDistanceM;
    double newProg = std::clamp(m_travelProgress + deltaProg, 0.0, 1.0);

    m_currentSimSpeed = std::abs(throttleDelta) * 55.0;
    emit currentSimSpeedChanged();

    setTravelProgress(newProg);
}

void NavigationController::loadPreset(const QString &presetKey) {
    setIsAutoDriving(false);

    std::vector<RouteStep> steps;

    if (presetKey == "san_francisco") {
        m_startLat = 37.8199; m_startLon = -122.4783; m_startName = "Golden Gate Vista Point";
        m_destLat = 37.7891;  m_destLon = -122.4014;  m_destName = "Market St Financial Dist";
        m_routeStatusMessage = "San Francisco: Golden Gate ➔ Downtown";
        steps = {
            {37.8199, -122.4783, "US-101 S Golden Gate Bridge", "straight", 2700, 75},
            {37.8020, -122.4660, "US-101 S Toll Plaza", "straight", 800, 60},
            {37.8010, -122.4550, "Presidio Parkway", "slight_right", 1200, 65},
            {37.8030, -122.4380, "Marina Boulevard", "turn_right", 1100, 45},
            {37.8000, -122.4380, "Lombard Street (US-101)", "straight", 1600, 45},
            {37.8005, -122.4230, "Van Ness Avenue", "turn_right", 1400, 40},
            {37.7890, -122.4225, "Bush Street", "turn_left", 1600, 35},
            {37.7905, -122.4035, "Montgomery & Market St", "turn_right", 600, 25}
        };
    } else if (presetKey == "tokyo") {
        m_startLat = 35.6595; m_startLon = 139.7005; m_startName = "Shibuya Scramble";
        m_destLat = 35.6628;  m_destLon = 139.7292;  m_destName = "Roppongi Hills Mori Tower";
        m_routeStatusMessage = "Tokyo: Shibuya Crossing ➔ Roppongi Hills";
        steps = {
            {35.6595, 139.7005, "Shibuya Crossing / Meiji-dori", "straight", 400, 35},
            {35.6610, 139.7030, "Miyamasuzaka Slope", "straight", 500, 40},
            {35.6630, 139.7085, "Aoyama-dori Route 246", "turn_left", 1650, 50},
            {35.6655, 139.7150, "Omotesando Intersection", "straight", 800, 45},
            {35.6700, 139.7240, "Gaien-Higashi-dori", "turn_right", 1200, 45},
            {35.6660, 139.7265, "Nogizaka Crossing", "straight", 600, 40},
            {35.6640, 139.7280, "Roppongi Keyakizaka Dori", "slight_left", 850, 35}
        };
    } else if (presetKey == "london") {
        m_startLat = 51.5033; m_startLon = -0.1517; m_startName = "Hyde Park Corner";
        m_destLat = 51.5055;  m_destLon = -0.0754;  m_destName = "Tower Bridge Approach";
        m_routeStatusMessage = "London: Hyde Park Corner ➔ Tower Bridge";
        steps = {
            {51.5033, -0.1517, "Piccadilly A4", "straight", 1200, 35},
            {51.5100, -0.1340, "Piccadilly Circus Roundabout", "roundabout", 350, 25},
            {51.5080, -0.1280, "Trafalgar Square / Strand", "turn_right", 600, 30},
            {51.5115, -0.1180, "The Strand A4", "straight", 1200, 35},
            {51.5135, -0.1060, "Fleet Street & Ludgate Hill", "straight", 1100, 35},
            {51.5125, -0.0900, "Cannon Street / Eastcheap", "straight", 1000, 40},
            {51.5080, -0.0780, "Tower Bridge Road A100", "turn_right", 800, 30}
        };
    } else if (presetKey == "nurburgring") {
        m_startLat = 50.3341; m_startLon = 6.9427; m_startName = "Tiergarten Grandstand";
        m_destLat = 50.3325;  m_destLon = 6.9405;  m_destName = "Döttinger Höhe Finish";
        m_routeStatusMessage = "Germany: Nürburgring Nordschleife Lap";
        steps = {
            {50.3341, 6.9427, "Hatzenbach S-Curve", "straight", 1400, 95},
            {50.3410, 6.9510, "Flugplatz Fast Crest", "turn_left", 1200, 140},
            {50.3480, 6.9580, "Schwedenkreuz Sweeper", "turn_right", 1600, 160},
            {50.3550, 6.9630, "Aremberg Hairpin", "turn_right", 900, 80},
            {50.3620, 6.9690, "Fuchsröhre High-Speed Compression", "straight", 1500, 150},
            {50.3680, 6.9700, "Adenauer Forst Chicane", "turn_left", 1100, 75},
            {50.3660, 6.9790, "Metzgesfeld & Kallenhard", "turn_right", 1400, 90},
            {50.3640, 6.9830, "Wehrseifen 180° Corner", "turn_left", 800, 60},
            {50.3620, 6.9850, "Karussell Banked Concrete", "roundabout", 1200, 85},
            {50.3550, 6.9820, "Hohe Acht & Wippermann", "turn_left", 1400, 100},
            {50.3480, 6.9780, "Brünnchen & Pflanzgarten", "turn_right", 1700, 125},
            {50.3400, 6.9650, "Döttinger Höhe Main Straight", "straight", 3800, 190}
        };
    } else { // Bengaluru default (Realistic road course)
        m_startLat = 12.9756; m_startLon = 77.6094; m_startName = "MG Road Metro Station";
        m_destLat = 12.9352;  m_destLon = 77.6946;  m_destName = "Embassy TechVillage Ring Rd";
        m_routeStatusMessage = "Bengaluru: MG Road ➔ Tech Park";
        steps = {
            {12.9756, 77.6094, "Mahatma Gandhi Road", "straight", 800, 45},
            {12.9725, 77.6160, "Trinity Circle Roundabout", "roundabout", 450, 30},
            {12.9690, 77.6150, "Victoria Road", "turn_right", 900, 35},
            {12.9648, 77.6105, "Richmond Road Flyover", "slight_right", 1400, 60},
            {12.9550, 77.6250, "Hosur Main Highway", "turn_right", 2400, 70},
            {12.9460, 77.6350, "Koramangala 80ft Boulevard", "turn_left", 1600, 45},
            {12.9380, 77.6480, "Sony World Junction", "turn_right", 1200, 40},
            {12.9340, 77.6600, "Inner Ring Road Express", "slight_left", 2600, 75},
            {12.9310, 77.6720, "Outer Ring Road Corridor", "straight", 2400, 75},
            {12.9345, 77.6910, "Embassy Tech Village Campus Rd", "turn_left", 600, 30}
        };
    }

    emit routePointsChanged();
    emit routeStatusMessageChanged();

    buildInterpolatedRoute(steps);
    setTravelProgress(0.0);
    fitRouteInView();
}

void NavigationController::calculateRoute() {
    setIsAutoDriving(false);
    m_isCalculatingRoute = true;
    m_routeStatusMessage = "Fetching Live OSRM Road Route...";
    emit isCalculatingRouteChanged();
    emit routeStatusMessageChanged();

    QString urlStr = QString("https://router.project-osrm.org/route/v1/driving/%1,%2;%3,%4?overview=full&geometries=geojson&steps=true")
                         .arg(m_startLon, 0, 'f', 6)
                         .arg(m_startLat, 0, 'f', 6)
                         .arg(m_destLon, 0, 'f', 6)
                         .arg(m_destLat, 0, 'f', 6);

    QUrl url(urlStr);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "ApexSUV-Cluster/1.0");
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    m_networkManager.get(request);
}

void NavigationController::onOsrmReplyFinished(QNetworkReply *reply) {
    m_isCalculatingRoute = false;
    emit isCalculatingRouteChanged();

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseBytes = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(responseBytes);
        if (!doc.isNull() && doc.isObject()) {
            QJsonObject rootObj = doc.object();
            if (rootObj.value("code").toString() == "Ok" && rootObj.contains("routes")) {
                QJsonArray routes = rootObj.value("routes").toArray();
                if (!routes.isEmpty()) {
                    QJsonObject routeObj = routes.first().toObject();

                    // 1. Extract Full Detailed Road Geometry Coordinates
                    QJsonObject geomObj = routeObj.value("geometry").toObject();
                    QJsonArray geomCoords = geomObj.value("coordinates").toArray();

                    // 2. Extract Turn-by-Turn Maneuver Steps
                    QJsonArray legs = routeObj.value("legs").toArray();
                    std::vector<RouteStep> parsedSteps;

                    if (!legs.isEmpty()) {
                        QJsonArray stepsJson = legs.first().toObject().value("steps").toArray();
                        for (const auto &stepVal : stepsJson) {
                            QJsonObject s = stepVal.toObject();
                            QJsonObject man = s.value("maneuver").toObject();
                            QString manType = man.value("type").toString();
                            QString manMod = man.value("modifier").toString();
                            QJsonArray loc = man.value("location").toArray();

                            QString mappedManeuver = "straight";
                            if (manType == "arrive") mappedManeuver = "destination_reached";
                            else if (manType == "roundabout" || manType == "rotary") mappedManeuver = "roundabout";
                            else if (manMod.contains("u-turn", Qt::CaseInsensitive)) mappedManeuver = "u_turn";
                            else if (manMod.contains("left", Qt::CaseInsensitive) && !manMod.contains("slight", Qt::CaseInsensitive)) mappedManeuver = "turn_left";
                            else if (manMod.contains("right", Qt::CaseInsensitive) && !manMod.contains("slight", Qt::CaseInsensitive)) mappedManeuver = "turn_right";
                            else if (manMod.contains("slight left", Qt::CaseInsensitive)) mappedManeuver = "slight_left";
                            else if (manMod.contains("slight right", Qt::CaseInsensitive)) mappedManeuver = "slight_right";
                            else if (manType == "fork") mappedManeuver = "turn_fork";

                            double stepLat = loc.size() >= 2 ? loc[1].toDouble() : m_startLat;
                            double stepLon = loc.size() >= 2 ? loc[0].toDouble() : m_startLon;
                            QString streetName = s.value("name").toString();
                            if (streetName.trimmed().isEmpty()) streetName = "Connecting Roadway";
                            double distM = s.value("distance").toDouble(500.0);

                            parsedSteps.push_back({
                                stepLat,
                                stepLon,
                                streetName,
                                mappedManeuver,
                                distM,
                                (distM > 1000.0 ? 70.0 : 45.0)
                            });
                        }
                    }

                    // Build full high-resolution road points from geometry if available
                    if (geomCoords.size() >= 2) {
                        m_points.clear();
                        m_routePolyline.clear();
                        m_totalDistanceM = 0.0;

                        std::vector<std::pair<double, double>> rawCoords;
                        for (const auto &cVal : geomCoords) {
                            QJsonArray cArr = cVal.toArray();
                            if (cArr.size() >= 2) {
                                rawCoords.push_back({cArr[1].toDouble(), cArr[0].toDouble()});
                            }
                        }

                        for (size_t i = 0; i < rawCoords.size(); ++i) {
                            double lat = rawCoords[i].first;
                            double lon = rawCoords[i].second;

                            double segDist = 0.0;
                            double bearing = 0.0;
                            if (i + 1 < rawCoords.size()) {
                                segDist = computeDistanceM(lat, lon, rawCoords[i+1].first, rawCoords[i+1].second);
                                bearing = computeBearingDeg(lat, lon, rawCoords[i+1].first, rawCoords[i+1].second);
                                m_totalDistanceM += segDist;
                            } else if (!m_points.empty()) {
                                bearing = m_points.back().bearing;
                            }

                            // Match with nearest step instruction
                            QString street = "Road";
                            QString maneuver = "straight";
                            QString nextStreet = "Destination";
                            double speedKmh = 50.0;

                            if (!parsedSteps.empty()) {
                                size_t stepIdx = std::min(parsedSteps.size() - 1, static_cast<size_t>((static_cast<double>(i) / rawCoords.size()) * parsedSteps.size()));
                                street = parsedSteps[stepIdx].street;
                                maneuver = parsedSteps[stepIdx].maneuver;
                                speedKmh = parsedSteps[stepIdx].speedKmh;
                                if (stepIdx + 1 < parsedSteps.size()) {
                                    nextStreet = parsedSteps[stepIdx + 1].street;
                                }
                            }

                            m_points.push_back({
                                lat,
                                lon,
                                static_cast<int>(i),
                                street,
                                maneuver,
                                nextStreet,
                                speedKmh,
                                bearing,
                                segDist
                            });

                            QVariantMap ptMap;
                            ptMap["lat"] = lat;
                            ptMap["lon"] = lon;
                            m_routePolyline.append(ptMap);
                        }

                        emit routePolylineChanged();
                        m_routeStatusMessage = "OSRM Live Road Active (" + QString::number(rawCoords.size()) + " road waypoints)";
                        emit routeStatusMessageChanged();
                        setTravelProgress(0.0);
                        fitRouteInView();
                        reply->deleteLater();
                        return;
                    } else if (parsedSteps.size() >= 2) {
                        m_routeStatusMessage = "OSRM Live Route Active";
                        emit routeStatusMessageChanged();
                        buildInterpolatedRoute(parsedSteps);
                        setTravelProgress(0.0);
                        fitRouteInView();
                        reply->deleteLater();
                        return;
                    }
                }
            }
        }
    }

    // Network error or rate-limit fallback: use rich procedural road generator
    m_routeStatusMessage = "Road Route Active (Offline Fallback)";
    emit routeStatusMessageChanged();
    createProceduralRoute(m_startLat, m_startLon, m_destLat, m_destLon);
    setTravelProgress(0.0);
    fitRouteInView();
    reply->deleteLater();
}

void NavigationController::createProceduralRoute(double startLat, double startLon, double destLat, double destLon) {
    double totalDist = computeDistanceM(startLat, startLon, destLat, destLon);
    double mainBearing = computeBearingDeg(startLat, startLon, destLat, destLon);

    static const QStringList streetNames = {
        "Metropolitan Expressway", "Central Boulevard", "Commerce Parkway",
        "Grand Avenue", "Riverfront Corridor", "Skyline Flyover", "Destination Access Rd"
    };
    static const QStringList maneuvers = {
        "straight", "turn_right", "slight_left", "turn_left", "roundabout", "slight_right", "straight"
    };

    int numSegments = 6;
    std::vector<RouteStep> steps;

    for (int i = 0; i <= numSegments; ++i) {
        double frac = static_cast<double>(i) / numSegments;
        double curveOffset = (i > 0 && i < numSegments) ? std::sin(frac * PI_VAL) * 0.003 : 0.0;
        double pLat = startLat + (destLat - startLat) * frac + curveOffset * std::cos(toRad(mainBearing + 90.0));
        double pLon = startLon + (destLon - startLon) * frac + curveOffset * std::sin(toRad(mainBearing + 90.0));

        steps.push_back({
            pLat,
            pLon,
            streetNames[i % streetNames.size()],
            (i == numSegments ? "straight" : maneuvers[i % maneuvers.size()]),
            totalDist / numSegments,
            (i == 0 || i == numSegments) ? 35.0 : (i % 2 == 0 ? 70.0 : 50.0)
        });
    }

    buildInterpolatedRoute(steps);
}

void NavigationController::buildInterpolatedRoute(const std::vector<RouteStep> &steps) {
    m_points.clear();
    m_routePolyline.clear();
    m_totalDistanceM = 0.0;

    if (steps.empty()) return;

    for (size_t i = 0; i < steps.size(); ++i) {
        const auto &curr = steps[i];
        bool hasNext = (i + 1 < steps.size());

        if (hasNext) {
            const auto &next = steps[i + 1];
            double segDist = computeDistanceM(curr.lat, curr.lon, next.lat, next.lon);
            int numSubsteps = std::max(12, std::min(80, static_cast<int>(std::round(segDist / 35.0))));

            for (int s = 0; s < numSubsteps; ++s) {
                double fraction = static_cast<double>(s) / numSubsteps;
                double lat = curr.lat + (next.lat - curr.lat) * fraction;
                double lon = curr.lon + (next.lon - curr.lon) * fraction;
                double bearing = computeBearingDeg(curr.lat, curr.lon, next.lat, next.lon);

                m_points.push_back({
                    lat,
                    lon,
                    static_cast<int>(i),
                    curr.street,
                    next.maneuver,
                    next.street,
                    curr.speedKmh,
                    bearing,
                    segDist * (1.0 - fraction)
                });

                QVariantMap ptMap;
                ptMap["lat"] = lat;
                ptMap["lon"] = lon;
                m_routePolyline.append(ptMap);
            }
            m_totalDistanceM += segDist;
        } else {
            double lastBearing = m_points.empty() ? 0.0 : m_points.back().bearing;
            m_points.push_back({
                curr.lat,
                curr.lon,
                static_cast<int>(i),
                curr.street,
                "straight",
                "Destination",
                40.0,
                lastBearing,
                0.0
            });

            QVariantMap ptMap;
            ptMap["lat"] = curr.lat;
            ptMap["lon"] = curr.lon;
            m_routePolyline.append(ptMap);
        }
    }

    emit routePolylineChanged();
}

void NavigationController::updateTelemetry(double progress) {
    if (m_points.empty()) return;

    size_t totalPts = m_points.size();
    double rawIdx = progress * (totalPts - 1);
    size_t idx = std::clamp(static_cast<size_t>(std::floor(rawIdx)), size_t{0}, totalPts - 1);
    size_t nextIdx = std::min(totalPts - 1, idx + 1);
    double subFrac = rawIdx - idx;

    const auto &p1 = m_points[idx];
    const auto &p2 = m_points[nextIdx];

    m_vehicleLat = p1.lat + (p2.lat - p1.lat) * subFrac;
    m_vehicleLon = p1.lon + (p2.lon - p1.lon) * subFrac;
    m_vehicleBearing = p1.bearing;
    m_compassHeading = bearingToCompass(m_vehicleBearing);

    double remainingDistM = (1.0 - progress) * m_totalDistanceM;
    m_navRemainingKm = QString::number(remainingDistM / 1000.0, 'f', 1) + " km";

    double distToTurn = p1.distToTurn > 0 ? p1.distToTurn : (remainingDistM * 0.2);
    if (distToTurn < 1000.0) {
        m_navDistance = QString::number(static_cast<int>(std::round(distToTurn))) + " m";
    } else {
        m_navDistance = QString::number(distToTurn / 1000.0, 'f', 1) + " km";
    }
    if (distToTurn < 25.0 && progress < 0.98) {
        m_navDistance = "Now";
    }

    int remainingMinutes = std::max(1, static_cast<int>(std::round(remainingDistM / 750.0)));
    m_navDuration = QString::number(remainingMinutes) + " min";
    m_navEta = formatEtaTime(remainingMinutes);

    bool isArrived = (progress >= 0.995);
    if (m_gpsLost) {
        m_navState = "GPS_LOST";
        m_currentSimSpeed = 0.0;
    } else if (isArrived) {
        m_navState = "ARRIVED";
        m_navManeuver = "straight";
        m_navDistance = "0 m";
        m_navStreet = "Arrived at Destination";
        m_currentSimSpeed = 0.0;
    } else {
        m_navState = "GUIDING";
        m_navManeuver = p1.maneuver.isEmpty() ? "straight" : p1.maneuver;
        m_navStreet = p1.nextStreet.isEmpty() ? p1.street : p1.nextStreet;
        m_currentSimSpeed = m_isAutoDriving ? p1.targetSpeed : m_currentSimSpeed;
        if (distToTurn < 50.0 && m_isAutoDriving) {
            m_currentSimSpeed = std::max(20.0, m_currentSimSpeed * 0.6);
        }
    }

    emit vehiclePositionChanged();
    emit vehicleBearingChanged();
    emit compassHeadingChanged();
    emit navRemainingKmChanged();
    emit navDistanceChanged();
    emit navDurationChanged();
    emit navEtaChanged();
    emit navStateChanged();
    emit navManeuverChanged();
    emit navStreetChanged();
    emit currentSimSpeedChanged();
}

void NavigationController::onSimulationTick() {
    if (!m_isEvReady) {
        setIsAutoDriving(false);
        return;
    }

    if (!m_isAutoDriving || m_points.empty() || m_totalDistanceM <= 0.0 || m_gpsLost) return;

    double currentKmh = m_currentSimSpeed > 0.0 ? m_currentSimSpeed : 50.0;
    double mps = (currentKmh * 1000.0 / 3600.0) * m_speedMultiplier;
    double dt = m_simTimer.interval() / 1000.0;
    double deltaM = mps * dt;
    double deltaProg = deltaM / m_totalDistanceM;

    double nextProg = m_travelProgress + deltaProg;
    if (nextProg >= 1.0) {
        m_travelProgress = 1.0;
        setIsAutoDriving(false);
        updateTelemetry(1.0);
        emit destinationReached();
    } else {
        m_travelProgress = nextProg;
        emit travelProgressChanged();
        updateTelemetry(nextProg);
    }
}

void NavigationController::swapStartDest() {
    std::swap(m_startLat, m_destLat);
    std::swap(m_startLon, m_destLon);
    std::swap(m_startName, m_destName);
    emit routePointsChanged();
    calculateRoute();
}

void NavigationController::toggleAutoDrive() {
    setIsAutoDriving(!m_isAutoDriving);
}

void NavigationController::resetTravel() {
    setIsAutoDriving(false);
    setTravelProgress(0.0);
}

void NavigationController::centerOnVehicle() {
    setCenterLat(m_vehicleLat);
    setCenterLon(m_vehicleLon);
}

void NavigationController::fitRouteInView() {
    setCenterLat((m_startLat + m_destLat) / 2.0);
    setCenterLon((m_startLon + m_destLon) / 2.0);
    double dist = computeDistanceM(m_startLat, m_startLon, m_destLat, m_destLon);
    if (dist > 30000.0) setZoomLevel(11);
    else if (dist > 15000.0) setZoomLevel(12);
    else if (dist > 7000.0) setZoomLevel(13);
    else if (dist > 3000.0) setZoomLevel(14);
    else setZoomLevel(15);
}

void NavigationController::setPinLocation(const QString &mode, double lat, double lon) {
    if (mode == "SET_START") {
        m_startLat = lat;
        m_startLon = lon;
        m_startName = QString("Custom Start (%1, %2)").arg(lat, 0, 'f', 3).arg(lon, 0, 'f', 3);
        emit routePointsChanged();
        calculateRoute();
    } else if (mode == "SET_DEST") {
        m_destLat = lat;
        m_destLon = lon;
        m_destName = QString("Custom Dest (%1, %2)").arg(lat, 0, 'f', 3).arg(lon, 0, 'f', 3);
        emit routePointsChanged();
        calculateRoute();
    }
}
