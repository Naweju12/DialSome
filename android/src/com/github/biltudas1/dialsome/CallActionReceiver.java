package com.github.biltudas1.dialsome;

import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class CallActionReceiver extends BroadcastReceiver {
    private static final String TAG = "CallActionReceiver";
    private static final int INCOMING_CALL_NOTIF_ID = 1001;

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) return;

        String action = intent.getAction();
        NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        if ("ACCEPT_CALL".equals(action)) {
            // 1. Cancel the ringing notification
            nm.cancel(INCOMING_CALL_NOTIF_ID);

            String roomId = intent.getStringExtra("room_id");
            String email = intent.getStringExtra("caller_email");
            String roomName = intent.getStringExtra("caller_name");

            // 2. Bring the app to the foreground
            Intent launchIntent = new Intent(context, org.qtproject.qt.android.bindings.QtActivity.class);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            launchIntent.putExtra("incoming_room_id", roomId);
            launchIntent.putExtra("incoming_caller", email);
            launchIntent.putExtra("incoming_room_name", roomName);
            context.startActivity(launchIntent);

            // 3. Tell C++ to join the call
            try {
                // We instantiate the service just to access the JNI methods without breaking your C++ signatures
                MyFirebaseMessagingService fcm = new MyFirebaseMessagingService();
                fcm.onCallMessageReceive(roomId, email, roomName);
            } catch (UnsatisfiedLinkError e) {
                Log.d(TAG, "C++ is currently dead, state will be restored when Activity launches.");
            }

        } else if ("REJECT_CALL".equals(action)) {
            // Cancel notification
            nm.cancel(INCOMING_CALL_NOTIF_ID);

            // Tell C++ to end/reject the call silently in the background
            try {
                MyFirebaseMessagingService fcm = new MyFirebaseMessagingService();
                fcm.onCallMessageEnd(intent.getStringExtra("caller_email"));
            } catch (UnsatisfiedLinkError e) {
                Log.d(TAG, "Unable to end call, C++ is dead");
            }
        }
    }
}
