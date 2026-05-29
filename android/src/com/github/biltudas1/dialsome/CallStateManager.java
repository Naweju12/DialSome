package com.github.biltudas1.dialsome;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class CallStateManager {
    // Tracks if the user has accepted the ongoing call
    public static boolean isCallActive = false;
    public static boolean isIncomingCallRinging = false;
    public static boolean isAppRunning = false;

    // Blocked users set — populated from C++ via JNI on startup and on change
    public static final Set<String> blockedUsers =
        Collections.synchronizedSet(new HashSet<>());

    public static boolean isBlocked(String email) {
        if (email == null) return false;
        String lower = email.trim().toLowerCase();
        synchronized (blockedUsers) {
            for (String blocked : blockedUsers) {
                if (blocked.equalsIgnoreCase(lower)) return true;
            }
        }
        return false;
    }
}
