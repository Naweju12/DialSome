package com.github.biltudas1.dialsome;

import android.content.Intent;
import android.os.Bundle;
import android.os.Build;
import android.view.WindowManager;
import android.app.NotificationManager;
import android.content.Context;
import org.qtproject.qt.android.bindings.QtActivity;

public class MainActivity extends QtActivity {

    private static final int INCOMING_CALL_NOTIF_ID = 1001;
    
    private static MainActivity instance;
    private static boolean isQtReady = false;
    private Intent cachedIntent = null;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        instance = this; // Save instance reference

        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true);
            setTurnScreenOn(true);
        } else {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                                 WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
        }

        // Cache the intent instead of executing it immediately
        cachedIntent = getIntent();
    }

    @Override
    public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (isQtReady) {
            handleCallIntent(intent); // Execute immediately if Qt is running
        } else {
            cachedIntent = intent;
        }
    }

    public static void notifyQtReady() {
        isQtReady = true;
        if (instance != null && instance.cachedIntent != null) {
            instance.runOnUiThread(() -> {
                instance.handleCallIntent(instance.cachedIntent);
                instance.cachedIntent = null; // Clear after handling
            });
        }
    }

    public static void clearCallNotification(Context context) {
        if (context != null) {
            NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                nm.cancel(INCOMING_CALL_NOTIF_ID); // 1001
            }
        }
    }

    private void handleCallIntent(Intent intent) {
        if (intent != null && intent.getAction() != null) {
            String action = intent.getAction();
            String roomId = intent.getStringExtra("room_id");
            String email = intent.getStringExtra("caller_email");
            String name = intent.getStringExtra("caller_name");

            if ("ACCEPT_CALL".equals(action)) {
                NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
                if (nm != null) nm.cancel(INCOMING_CALL_NOTIF_ID);

                if (roomId != null && email != null) {
                    acceptCallNative(roomId, email, name != null ? name : "Unknown");
                }
            } else if ("SHOW_INCOMING_CALL".equals(action)) {
                if (roomId != null && email != null) {
                    showIncomingCallNative(roomId, email, name != null ? name : "Unknown");
                }
            }
        }
    }

    private native void acceptCallNative(String roomId, String email, String name);
    private native void showIncomingCallNative(String roomId, String email, String name);
}
