package com.example.lifepilot

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Flutter local notifications reschedules notification alarms. LifePilot
        // stores reminders locally so the Dart layer can reschedule native spoken
        // alarms on next launch after BOOT_COMPLETED/package replacement.
    }
}
