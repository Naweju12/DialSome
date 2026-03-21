package com.github.biltudas1.dialsome;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;

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
            if (intent != null && intent.hasExtra("room_id")) {
                return intent.getStringExtra("room_id");
            }
        }
        return "";
    }

    public static String getIncomingRoomName(Context context) {
        if (context instanceof android.app.Activity) {
            android.app.Activity activity = (android.app.Activity) context;
            android.content.Intent intent = activity.getIntent();
            if (intent != null && intent.hasExtra("caller_name")) {
                return intent.getStringExtra("caller_name");
            }
        }
        return "";
    }

    public static String getIncomingCallerEmail(Context context) {
        if (context instanceof android.app.Activity) {
            android.app.Activity activity = (android.app.Activity) context;
            android.content.Intent intent = activity.getIntent();
            if (intent != null && intent.hasExtra("caller_email")) {
                return intent.getStringExtra("caller_email");
            }
        }
        return "";
    }

    public static void requestIgnoreBatteryOptimizations(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            // Check if the app is already exempted
            if (pm != null && !pm.isIgnoringBatteryOptimizations(context.getPackageName())) {
                // If not exempted, open the dialog to ask the user
                Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setData(Uri.parse("package:" + context.getPackageName()));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(intent);
            }
        }
    }
}
