package org.mavlink.qgroundcontrol;

import android.content.Intent;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.os.Bundle;
import android.util.Log;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * NotificationListenerService that reads Herelink radio status from
 * org.cubepilot.herelinksettings notifications.
 *
 * Runs in a separate process (:herelink) to survive app crashes.
 * Broadcasts telemetry data to the main app process via Intent.
 */
public class HerelinkNotificationService extends NotificationListenerService {
    private static final String TAG = "HerelinkNotifService";
    private static final String HERELINK_PACKAGE = "org.cubepilot.herelinksettings";

    // Broadcast action for telemetry updates
    public static final String ACTION_TELEMETRY_UPDATE = "org.mavlink.qgroundcontrol.HERELINK_TELEMETRY";

    // Intent extra keys
    public static final String EXTRA_PAIR_STATE = "pair_state";
    public static final String EXTRA_CTRL_SIGNAL_MAIN = "ctrl_signal_main";
    public static final String EXTRA_CTRL_SIGNAL_SEC = "ctrl_signal_sec";
    public static final String EXTRA_AIR_SIGNAL_MAIN = "air_signal_main";
    public static final String EXTRA_AIR_SIGNAL_SEC = "air_signal_sec";
    public static final String EXTRA_UPLINK_RATE = "uplink_rate";
    public static final String EXTRA_UPLINK_BW = "uplink_bw";
    public static final String EXTRA_FLY_DISTANCE = "fly_distance";

    // Regex patterns for parsing notification text
    private static final Pattern PAIR_STATE_PATTERN = Pattern.compile("Pair state:\\s*(.+)");
    private static final Pattern CONTROLLER_SIGNAL_PATTERN = Pattern.compile("Controller signal strength:\\s*M:\\s*(-?\\d+)\\s*dbm,\\s*S:\\s*(-?\\d+)\\s*dbm");
    private static final Pattern AIR_SIGNAL_PATTERN = Pattern.compile("Air signal strength:\\s*M:\\s*(-?\\d+)\\s*dbm,\\s*S:\\s*(-?\\d+)\\s*dbm");
    private static final Pattern UPLINK_RATE_PATTERN = Pattern.compile("Uplink Rate:\\s*(\\d+)\\s*kbps");
    private static final Pattern UPLINK_BANDWIDTH_PATTERN = Pattern.compile("Uplink bandwidth:\\s*(\\d+)\\s*kbps");
    private static final Pattern FLY_DISTANCE_PATTERN = Pattern.compile("Fly Distance:\\s*(\\d+)\\s*m");

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "HerelinkNotificationService created (separate process)");
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "HerelinkNotificationService destroyed");
        super.onDestroy();
    }

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        Log.i(TAG, "NotificationListener connected");
        checkExistingNotifications();
    }

    private void checkExistingNotifications() {
        try {
            StatusBarNotification[] activeNotifications = getActiveNotifications();
            if (activeNotifications != null) {
                for (StatusBarNotification sbn : activeNotifications) {
                    if (HERELINK_PACKAGE.equals(sbn.getPackageName())) {
                        Log.i(TAG, "Found existing Herelink notification, processing");
                        onNotificationPosted(sbn);
                        break;
                    }
                }
            }
        } catch (Exception e) {
            Log.w(TAG, "Error checking existing notifications: " + e.getMessage());
        }
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        if (sbn == null || !HERELINK_PACKAGE.equals(sbn.getPackageName())) {
            return;
        }

        Bundle extras = sbn.getNotification().extras;
        if (extras == null) {
            return;
        }

        CharSequence bigText = extras.getCharSequence("android.bigText");
        if (bigText == null) {
            return;
        }

        String text = bigText.toString();
        broadcastTelemetry(text);
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        // Not needed
    }

    private void broadcastTelemetry(String text) {
        // Parse values
        String pairState = "Unknown";
        int controllerSignalMain = 0;
        int controllerSignalSecondary = 0;
        int airSignalMain = 0;
        int airSignalSecondary = 0;
        int uplinkRate = 0;
        int uplinkBandwidth = 0;
        int flyDistance = 0;

        Matcher matcher;

        matcher = PAIR_STATE_PATTERN.matcher(text);
        if (matcher.find()) {
            pairState = matcher.group(1).trim();
        }

        matcher = CONTROLLER_SIGNAL_PATTERN.matcher(text);
        if (matcher.find()) {
            try {
                controllerSignalMain = Integer.parseInt(matcher.group(1));
                controllerSignalSecondary = Integer.parseInt(matcher.group(2));
            } catch (NumberFormatException e) { }
        }

        matcher = AIR_SIGNAL_PATTERN.matcher(text);
        if (matcher.find()) {
            try {
                airSignalMain = Integer.parseInt(matcher.group(1));
                airSignalSecondary = Integer.parseInt(matcher.group(2));
            } catch (NumberFormatException e) { }
        }

        matcher = UPLINK_RATE_PATTERN.matcher(text);
        if (matcher.find()) {
            try {
                uplinkRate = Integer.parseInt(matcher.group(1));
            } catch (NumberFormatException e) { }
        }

        matcher = UPLINK_BANDWIDTH_PATTERN.matcher(text);
        if (matcher.find()) {
            try {
                uplinkBandwidth = Integer.parseInt(matcher.group(1));
            } catch (NumberFormatException e) { }
        }

        matcher = FLY_DISTANCE_PATTERN.matcher(text);
        if (matcher.find()) {
            try {
                flyDistance = Integer.parseInt(matcher.group(1));
            } catch (NumberFormatException e) { }
        }

        // Broadcast to main app process
        Intent intent = new Intent(ACTION_TELEMETRY_UPDATE);
        intent.setPackage(getPackageName());
        intent.putExtra(EXTRA_PAIR_STATE, pairState);
        intent.putExtra(EXTRA_CTRL_SIGNAL_MAIN, controllerSignalMain);
        intent.putExtra(EXTRA_CTRL_SIGNAL_SEC, controllerSignalSecondary);
        intent.putExtra(EXTRA_AIR_SIGNAL_MAIN, airSignalMain);
        intent.putExtra(EXTRA_AIR_SIGNAL_SEC, airSignalSecondary);
        intent.putExtra(EXTRA_UPLINK_RATE, uplinkRate);
        intent.putExtra(EXTRA_UPLINK_BW, uplinkBandwidth);
        intent.putExtra(EXTRA_FLY_DISTANCE, flyDistance);
        sendBroadcast(intent);
    }
}
