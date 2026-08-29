#pragma once
#include <QObject>
#include <QProcess>
#include <QCoreApplication>
#include <QFile>

class ClusterAudio : public QObject {
    Q_OBJECT
public:
    explicit ClusterAudio(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void playStartupChime() {
        QString path = "/Users/reno/Projects/ApexECU_Cluster/assets/audio/cluster_startup_chime.wav";
        if (QFile::exists(path)) {
            QProcess::startDetached("afplay", QStringList() << path);
        }
    }

    Q_INVOKABLE void playModeShiftChime() {
        QString path = "/Users/reno/Projects/ApexECU_Cluster/assets/audio/mode_shift_chime.wav";
        if (QFile::exists(path)) {
            QProcess::startDetached("afplay", QStringList() << path);
        }
    }

    Q_INVOKABLE void playCriticalAlertChime() {
        QString path = "/Users/reno/Projects/ApexECU_Cluster/assets/audio/alert_chime_critical.wav";
        if (QFile::exists(path)) {
            QProcess::startDetached("afplay", QStringList() << path);
        }
    }

    Q_INVOKABLE void playWarningAlertChime() {
        QString path = "/Users/reno/Projects/ApexECU_Cluster/assets/audio/alert_chime_warning.wav";
        if (QFile::exists(path)) {
            QProcess::startDetached("afplay", QStringList() << path);
        }
    }

    Q_INVOKABLE void playInfoAlertChime() {
        QString path = "/Users/reno/Projects/ApexECU_Cluster/assets/audio/alert_chime_info.wav";
        if (QFile::exists(path)) {
            QProcess::startDetached("afplay", QStringList() << path);
        }
    }
    Q_INVOKABLE void playEngineRev() {
        QString path = "/Users/reno/Projects/ApexECU_Cluster/assets/audio/engine_rev_sound.wav";
        if (QFile::exists(path)) {
            QProcess::startDetached("afplay", QStringList() << path);
        }
    }
};
