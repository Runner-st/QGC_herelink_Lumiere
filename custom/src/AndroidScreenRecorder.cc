/****************************************************************************
 *
 * Herelink screen recorder — captures the entire device display alongside
 * the GStreamer video stream recording.
 *
 ****************************************************************************/

#include "AndroidScreenRecorder.h"

#include <QDateTime>
#include <QMetaObject>

#include "QGCApplication.h"
#include "AppSettings.h"
#include "SettingsManager.h"

#if defined(__android__)
#include <jni.h>
#include <QtAndroid>
#include <QAndroidJniObject>
#include <QAndroidJniEnvironment>
#endif

AndroidScreenRecorder* AndroidScreenRecorder::_instance = nullptr;

static const char kQGCActivityClass[] = "org/mavlink/qgroundcontrol/QGCActivity";

AndroidScreenRecorder::AndroidScreenRecorder(QObject* parent)
    : QObject(parent)
{
    _instance = this;
}

AndroidScreenRecorder* AndroidScreenRecorder::instance()
{
    return _instance;
}

void AndroidScreenRecorder::startRecording()
{
#if defined(__android__)
    QString savePath = qgcApp()->toolbox()->settingsManager()->appSettings()->videoSavePath();
    if (savePath.isEmpty()) {
        qWarning() << "AndroidScreenRecorder: video save path is empty";
        return;
    }

    QString outputPath = savePath + "/"
        + QDateTime::currentDateTime().toString("yyyy-MM-dd_hh.mm.ss")
        + "_screen.mp4";

    QAndroidJniObject jOutputPath = QAndroidJniObject::fromString(outputPath);
    QAndroidJniObject::callStaticMethod<void>(
        kQGCActivityClass,
        "startScreenRecording",
        "(Ljava/lang/String;)V",
        jOutputPath.object<jstring>()
    );
#endif
}

void AndroidScreenRecorder::stopRecording()
{
#if defined(__android__)
    QAndroidJniObject::callStaticMethod<void>(
        kQGCActivityClass,
        "stopScreenRecording",
        "()V"
    );
#endif
}

void AndroidScreenRecorder::setRecordingStatus(bool recording)
{
    if (_recording != recording) {
        _recording = recording;
        emit recordingChanged();
    }
}

void AndroidScreenRecorder::setNativeMethods()
{
    // The JNI callback uses the Java_<class>_<method> naming convention so no
    // RegisterNatives call is required — the JVM resolves it automatically.
    // This function is kept as a hook in case future registration is needed.
}

// ---------------------------------------------------------------------------
// JNI callback — called from QGCActivity.nativeScreenRecordingStatusChanged()
// ---------------------------------------------------------------------------
#if defined(__android__)
extern "C" {

JNIEXPORT void JNICALL
Java_org_mavlink_qgroundcontrol_QGCActivity_nativeScreenRecordingStatusChanged(
    JNIEnv*  /*env*/,
    jclass   /*clazz*/,
    jboolean recording)
{
    AndroidScreenRecorder* inst = AndroidScreenRecorder::instance();
    if (!inst) {
        return;
    }
    // Marshal to the Qt main thread
    QMetaObject::invokeMethod(inst, "setRecordingStatus", Qt::QueuedConnection,
        Q_ARG(bool, static_cast<bool>(recording)));
}

} // extern "C"
#endif
