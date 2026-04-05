/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "HerelinkTelemetry.h"

#if defined(__android__)
#include <jni.h>
#endif

HerelinkTelemetry* HerelinkTelemetry::_instance = nullptr;

HerelinkTelemetry::HerelinkTelemetry(QObject *parent)
    : QObject(parent)
{
    _instance = this;
}

HerelinkTelemetry::~HerelinkTelemetry()
{
    if (_instance == this) {
        _instance = nullptr;
    }
}

HerelinkTelemetry* HerelinkTelemetry::instance()
{
    return _instance;
}

void HerelinkTelemetry::updateTelemetry(
    const QString& pairState,
    int controllerSignalMain,
    int controllerSignalSecondary,
    int airSignalMain,
    int airSignalSecondary,
    int uplinkRate,
    int uplinkBandwidth,
    int flyDistance)
{
    bool wasAvailable = _available;

    _pairState = pairState;
    _controllerSignalMain = controllerSignalMain;
    _controllerSignalSecondary = controllerSignalSecondary;
    _airSignalMain = airSignalMain;
    _airSignalSecondary = airSignalSecondary;
    _uplinkRate = uplinkRate;
    _uplinkBandwidth = uplinkBandwidth;
    _flyDistance = flyDistance;
    _available = true;

    emit telemetryChanged();

    if (!wasAvailable) {
        emit availableChanged();
    }
}

#if defined(__android__)
extern "C" {

/**
 * Called from QGCActivity when it receives a broadcast from HerelinkNotificationService.
 * The service runs in a separate process (:herelink) and communicates via Intent broadcasts.
 * This ensures the service survives app crashes without being disabled by Android.
 */
JNIEXPORT void JNICALL
Java_org_mavlink_qgroundcontrol_QGCActivity_nativeHerelinkTelemetryUpdate(
    JNIEnv *env,
    jclass clazz,
    jstring pairState,
    jint controllerSignalMain,
    jint controllerSignalSecondary,
    jint airSignalMain,
    jint airSignalSecondary,
    jint uplinkRate,
    jint uplinkBandwidth,
    jint flyDistance)
{
    Q_UNUSED(clazz)

    HerelinkTelemetry* instance = HerelinkTelemetry::instance();
    if (!instance) {
        return;
    }

    const char* pairStateStr = env->GetStringUTFChars(pairState, nullptr);
    if (!pairStateStr) {
        return;
    }
    QString pairStateQStr = QString::fromUtf8(pairStateStr);
    env->ReleaseStringUTFChars(pairState, pairStateStr);

    // Use Qt's thread-safe mechanism to update on the main thread
    QMetaObject::invokeMethod(instance, "updateTelemetry", Qt::QueuedConnection,
        Q_ARG(QString, pairStateQStr),
        Q_ARG(int, static_cast<int>(controllerSignalMain)),
        Q_ARG(int, static_cast<int>(controllerSignalSecondary)),
        Q_ARG(int, static_cast<int>(airSignalMain)),
        Q_ARG(int, static_cast<int>(airSignalSecondary)),
        Q_ARG(int, static_cast<int>(uplinkRate)),
        Q_ARG(int, static_cast<int>(uplinkBandwidth)),
        Q_ARG(int, static_cast<int>(flyDistance)));
}

} // extern "C"
#endif
