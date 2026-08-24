package org.mavlink.qgroundcontrol;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.MediaRecorder;
import android.media.projection.MediaProjection;
import android.os.Build;
import android.os.IBinder;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.WindowManager;

public class ScreenRecorderService extends Service {
    private static final String TAG        = "QGC_ScreenRecorder";
    private static final String CHANNEL_ID = "qgc_screen_recorder";
    public  static final String ACTION_STOP = "org.mavlink.qgroundcontrol.STOP_SCREEN_RECORD";
    private static final int    NOTIF_ID   = 1002;

    private MediaProjection _mediaProjection;
    private MediaRecorder   _mediaRecorder;
    private VirtualDisplay  _virtualDisplay;
    private String          _outputPath;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) {
            QGCActivity.qgcLogWarning("ScreenRecorderService: null intent in onStartCommand");
            stopSelf();
            return START_NOT_STICKY;
        }

        if (ACTION_STOP.equals(intent.getAction())) {
            QGCActivity.qgcLogDebug("ScreenRecorderService: received STOP action");
            stopRecording();
            stopSelf();
            return START_NOT_STICKY;
        }

        String outputPath = intent.getStringExtra("outputPath");
        if (outputPath == null) {
            QGCActivity.qgcLogWarning("ScreenRecorderService: missing outputPath extra");
            stopSelf();
            return START_NOT_STICKY;
        }

        // Consume the MediaProjection token from QGCActivity (same process, same classloader).
        _mediaProjection = QGCActivity.takePendingMediaProjection();
        if (_mediaProjection == null) {
            QGCActivity.qgcLogWarning("ScreenRecorderService: no pending MediaProjection available");
            QGCActivity.reportScreenRecordingStarted(false, "no MediaProjection token");
            stopSelf();
            return START_NOT_STICKY;
        }

        createNotificationChannel();
        Notification.Builder builder;
        if (Build.VERSION.SDK_INT >= 26) {
            builder = new Notification.Builder(this, CHANNEL_ID);
        } else {
            builder = new Notification.Builder(this);
        }
        Notification notif = builder
            .setContentTitle("Screen Recording Active")
            .setContentText("QGC is recording the device screen")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .build();
        startForeground(NOTIF_ID, notif);

        startRecording(outputPath);

        return START_NOT_STICKY;
    }

    private void startRecording(String outputPath) {
        _outputPath = outputPath;
        QGCActivity.qgcLogDebug("ScreenRecorderService: starting recording to " + outputPath);

        WindowManager wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        DisplayMetrics metrics = new DisplayMetrics();
        wm.getDefaultDisplay().getRealMetrics(metrics);

        int width   = metrics.widthPixels;
        int height  = metrics.heightPixels;
        int density = metrics.densityDpi;

        QGCActivity.qgcLogDebug("ScreenRecorderService: display " + width + "x" + height + " dpi=" + density);

        try {
            if (Build.VERSION.SDK_INT >= 31) {
                _mediaRecorder = new MediaRecorder(this);
            } else {
                _mediaRecorder = new MediaRecorder();
            }

            _mediaRecorder.setVideoSource(MediaRecorder.VideoSource.SURFACE);
            _mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
            _mediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
            _mediaRecorder.setVideoSize(width, height);
            _mediaRecorder.setVideoFrameRate(30);
            _mediaRecorder.setVideoEncodingBitRate(6_000_000);
            _mediaRecorder.setOutputFile(outputPath);
            _mediaRecorder.prepare();

            _virtualDisplay = _mediaProjection.createVirtualDisplay(
                "QGCScreenCapture",
                width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                _mediaRecorder.getSurface(),
                null, null
            );

            _mediaRecorder.start();

            QGCActivity.qgcLogDebug("ScreenRecorderService: recording started OK");
            QGCActivity.reportScreenRecordingStarted(true, null);

        } catch (Exception e) {
            String msg = e.getClass().getSimpleName() + ": " + e.getMessage();
            Log.e(TAG, "startRecording failed: " + msg);
            QGCActivity.qgcLogWarning("ScreenRecorderService: startRecording failed - " + msg);
            QGCActivity.reportScreenRecordingStarted(false, msg);
            releaseResources();
            stopForeground(true);
            stopSelf();
        }
    }

    private void stopRecording() {
        QGCActivity.qgcLogDebug("ScreenRecorderService: stopping recording");
        final String savedPath = _outputPath;
        try {
            if (_mediaRecorder != null) {
                _mediaRecorder.stop();
            }
        } catch (Exception e) {
            QGCActivity.qgcLogWarning("ScreenRecorderService: stop error - " + e.getMessage());
        }
        releaseResources();
        stopForeground(true);
        QGCActivity.nativeScreenRecordingStatusChanged(false);

        // Register the file with MediaStore (with a legacy-broadcast fallback) so it
        // appears in the Gallery immediately, on internal storage or SD card alike.
        if (savedPath != null) {
            QGCActivity.scanMediaFile(savedPath, "video/mp4");
            QGCActivity.qgcLogDebug("ScreenRecorderService: requested media scan for " + savedPath);
        }
    }

    private void releaseResources() {
        if (_mediaRecorder != null) {
            _mediaRecorder.release();
            _mediaRecorder = null;
        }
        if (_virtualDisplay != null) {
            _virtualDisplay.release();
            _virtualDisplay = null;
        }
        if (_mediaProjection != null) {
            _mediaProjection.stop();
            _mediaProjection = null;
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID, "Screen Recorder", NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("QGC screen recording service");
            NotificationManager nm = getSystemService(NotificationManager.class);
            nm.createNotificationChannel(channel);
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        releaseResources();
        super.onDestroy();
    }
}
