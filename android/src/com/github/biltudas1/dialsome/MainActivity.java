package com.github.biltudas1.dialsome;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import org.qtproject.qt.android.bindings.QtActivity;

public class MainActivity extends QtActivity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent != null && "ACCEPT_CALL".equals(intent.getAction())) {
            // 1. Clear the ringing notification (using your existing ID 1001)
            NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                nm.cancel(1001); 
            }

            // 2. Extract call details
            String roomId = intent.getStringExtra("room_id");
            String email = intent.getStringExtra("caller_email");
            String roomName = intent.getStringExtra("caller_name");

            // 3. Send to C++ via your existing JNI function
            try {
                MyFirebaseMessagingService fcm = new MyFirebaseMessagingService();
                fcm.onCallMessageReceive(roomId, email, roomName);
            } catch (UnsatisfiedLinkError e) {
                // Ignore if C++ isn't ready yet
            }

            // 4. Clear the intent action so it doesn't trigger again on screen rotation
            intent.setAction("");
        }
    }
}