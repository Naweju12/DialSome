package com.github.biltudas1.dialsome;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

public class AndroidUtils {
    /**
     * Shows a native Android Toast message.
     * This must be called from the UI thread.
     */
    public static void showToast(Activity activity, String message) {
        if (activity == null) return;
        
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(activity, message, Toast.LENGTH_SHORT).show();
            }
        });
    }

    public static String getIncomingRoomId(Context context) {
        if (context instanceof android.app.Activity) {
            android.app.Activity activity = (android.app.Activity) context;
            android.content.Intent intent = activity.getIntent();
            if (intent != null && intent.hasExtra("incoming_room_id")) {
                return intent.getStringExtra("incoming_room_id");
            }
        }
        return "";
    }

    public static String getIncomingRoomName(Context context) {
        if (context instanceof android.app.Activity) {
            android.app.Activity activity = (android.app.Activity) context;
            android.content.Intent intent = activity.getIntent();
            if (intent != null && intent.hasExtra("incoming_room_name")) {
                return intent.getStringExtra("incoming_room_name");
            }
        }
        return "";
    }

    public static String getIncomingCallerEmail(Context context) {
        if (context instanceof android.app.Activity) {
            android.app.Activity activity = (android.app.Activity) context;
            android.content.Intent intent = activity.getIntent();
            if (intent != null && intent.hasExtra("incoming_caller")) {
                return intent.getStringExtra("incoming_caller");
            }
        }
        return "";
    }
}