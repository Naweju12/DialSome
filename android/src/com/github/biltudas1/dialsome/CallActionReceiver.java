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
    }
}
