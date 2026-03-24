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

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Allow the app UI to wake the screen and display over the lock screen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true);
            setTurnScreenOn(true);
        } else {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                                 WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
        }

        handleCallIntent(getIntent());
    }

    @Override
    public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleCallIntent(intent);
    }

    private void handleCallIntent(Intent intent) {
        if (intent != null && intent.getAction() != null) {
            String action = intent.getAction();
            String roomId = intent.getStringExtra("room_id");
            String email = intent.getStringExtra("caller_email");
            String name = intent.getStringExtra("caller_name");

            if ("ACCEPT_CALL".equals(action)) {
                // User pressed accept on the notification drop-down
                NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
                if (nm != null) nm.cancel(INCOMING_CALL_NOTIF_ID);

                if (roomId != null && email != null) {
                    acceptCallNative(roomId, email, name != null ? name : "Unknown");
                }
            } else if ("SHOW_INCOMING_CALL".equals(action)) {
                // The lock screen was bypassed. Tell C++ to show the IncomingCallPage.qml
                if (roomId != null && email != null) {
                    showIncomingCallNative(roomId, email, name != null ? name : "Unknown");
                }
            }
        }
    }

    // Declare the native C++ function
    private native void acceptCallNative(String roomId, String email, String name);
    private native void showIncomingCallNative(String roomId, String email, String name);
}