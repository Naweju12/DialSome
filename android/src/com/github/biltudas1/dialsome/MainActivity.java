package com.github.biltudas1.dialsome;

import android.content.Intent;
import android.os.Bundle;
import android.app.NotificationManager;
import android.content.Context;
import org.qtproject.qt.android.bindings.QtActivity;

public class MainActivity extends QtActivity {

    private static final int INCOMING_CALL_NOTIF_ID = 1001;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handleCallIntent(getIntent());
    }

    @Override
    public void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleCallIntent(intent);
    }

    private void handleCallIntent(Intent intent) {
        if (intent != null && "ACCEPT_CALL".equals(intent.getAction())) {
            
            // 1. KILL THE RINGTONE AND NOTIFICATION INSTANTLY
            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                nm.cancel(INCOMING_CALL_NOTIF_ID);
            }

            // 2. Extract Data
            String roomId = intent.getStringExtra("room_id");
            String email = intent.getStringExtra("caller_email");
            String name = intent.getStringExtra("caller_name");
            
            // 3. Send the signal to C++ to join the call
            if (roomId != null && email != null) {
                acceptCallNative(roomId, email, name != null ? name : "Unknown");
            }
        }
    }

    // Declare the native C++ function
    private native void acceptCallNative(String roomId, String email, String name);
}