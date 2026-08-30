#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QFontDatabase>
#include "ClusterAudio.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("APEX SUV - Quiet Luxury Cluster");
    app.setOrganizationName("ApexAutomotive");

    // Register Inter Font from assets
    int fontId = QFontDatabase::addApplicationFont(QStringLiteral(":/qt/qml/ApexCluster/assets/fonts/Inter-VariableFont.ttf"));
    if (fontId != -1) {
        QStringList families = QFontDatabase::applicationFontFamilies(fontId);
        if (!families.isEmpty()) {
            app.setFont(QFont(families.first()));
        }
    }

    QSurfaceFormat format;
    format.setSamples(4);
    QSurfaceFormat::setDefaultFormat(format);

    ClusterAudio clusterAudio;
    // Play startup chime on launch
    clusterAudio.playStartupChime();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("clusterAudio", &clusterAudio);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("ApexCluster", "Main");

    if (engine.rootObjects().isEmpty()) {
        const QUrl url(QStringLiteral("qrc:/qt/qml/ApexCluster/qml/Main.qml"));
        engine.load(url);
    }

    return app.exec();
}
