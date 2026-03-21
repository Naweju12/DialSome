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

        Intent serviceIntent = new Intent(context, CallForegroundService.class);
        context.stopService(serviceIntent);

        // Only handle REJECT_CALL here
        if ("REJECT_CALL".equals(action)) {
            Log.d(TAG, "Call rejected from notification.");
            
            // 1. Cancel notification
            nm.cancel(INCOMING_CALL_NOTIF_ID);

            // 2. Tell C++ to end the call silently
            try {
                MyFirebaseMessagingService fcm = new MyFirebaseMessagingService();
                fcm.onCallMessageEnd(intent.getStringExtra("caller_email"));
            } catch (UnsatisfiedLinkError e) {
                Log.d(TAG, "Unable to end call, C++ is dead");
            }
        }
        else if ("ACCEPT_CALL".equals(action)) {
            Log.d(TAG, "Call accepted from notification.");
            nm.cancel(INCOMING_CALL_NOTIF_ID);

            // Launch the main app Activity
            Intent launchIntent = new Intent(context, MainActivity.class);
            // These flags ensure the app comes to the foreground properly
            launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            launchIntent.setAction("ACCEPT_CALL");
            
            // Pass the call details to the Activity
            launchIntent.putExtra("room_id", intent.getStringExtra("room_id"));
            launchIntent.putExtra("caller_email", intent.getStringExtra("caller_email"));
            launchIntent.putExtra("caller_name", intent.getStringExtra("caller_name"));
            
            context.startActivity(launchIntent);
        }
    }
}
