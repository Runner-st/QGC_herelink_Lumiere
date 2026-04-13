/****************************************************************************
 *
 * Herelink screen recorder — captures the entire device display alongside
 * the GStreamer video stream recording.
 *
 ****************************************************************************/

#pragma once

#include <QObject>

#if defined(__android__)
#include <jni.h>
#endif

/// Singleton that bridges Qt/QML to the Android MediaProjection screen recording API.
/// On non-Android platforms all methods are no-ops so the same QML code compiles everywhere.
class AndroidScreenRecorder : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)

public:
    explicit AndroidScreenRecorder(QObject* parent = nullptr);

    static AndroidScreenRecorder* instance();

    bool recording() const { return _recording; }

    Q_INVOKABLE void startRecording();
    Q_INVOKABLE void stopRecording();

    /// Called once at app startup (from JNI_OnLoad / HerelinkCorePlugin) to register
    /// the native callback so Android can call back into C++.
    static void setNativeMethods();

signals:
    void recordingChanged();

public slots:
    void setRecordingStatus(bool recording);

private:
    static AndroidScreenRecorder* _instance;
    bool _recording = false;
};
