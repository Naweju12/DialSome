package com.github.biltudas1.dialsome;

import android.content.Intent;
import android.os.Bundle;
import org.qtproject.qt.android.bindings.QtActivity;

public class MainActivity extends QtActivity {

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
            String roomId = intent.getStringExtra("room_id");
            String email = intent.getStringExtra("caller_email");
            String name = intent.getStringExtra("caller_name");
            
            // Send the signal to C++ to join the call
            if (roomId != null && email != null) {
                acceptCallNative(roomId, email, name != null ? name : "Unknown");
            }
        }
    }

    // Declare the native C++ function
    private native void acceptCallNative(String roomId, String email, String name);
}